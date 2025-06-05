using Sedulous.Engine.Core;
using SDL3_shadercross;
using System.Collections;
using System;
using System.IO;
using SDL3Native;
using Sedulous.Mathematics;
using Sedulous.Platform.Core;
using Sedulous.Platform.SDL3;
using Sedulous.SceneGraph;
using Sedulous.Geometry;

namespace Sedulous.Engine.Renderer.SDL;

using internal Sedulous.Engine.Renderer.SDL;

// Uniform buffer structures must match shader exactly and follow HLSL alignment rules
static
{
	public const int MAX_LIGHTS = 16;
}

[CRepr, Packed]
struct LitVertexUniforms
{
	public Matrix MVPMatrix; // 64 bytes (4x float4)
	public Matrix ModelMatrix; // 64 bytes (4x float4)
	public Matrix NormalMatrix; // 64 bytes (4x float4)
	// Total: 192 bytes (multiple of 16)
}

[CRepr, Packed]
struct LightData
{
	public Vector4 PositionType; // xyz = position, w = type (0=dir, 1=point, 2=spot)
	public Vector4 DirectionRange; // xyz = direction, w = range
	public Vector4 ColorIntensity; // xyz = color, w = intensity
	public Vector4 SpotAngles; // x = inner angle cos, y = outer angle cos, z = shadow bias, w = shadow normal bias
	public Matrix ShadowMatrix; // Light space matrix for shadow mapping (64 bytes)
	// Total: 128 bytes per light
}

[CRepr, Packed]
struct LitFragmentUniforms
{
	// Material properties
	public Vector4 MaterialColor; // 16 bytes - diffuse color
	public Vector4 SpecularColorShininess; // 16 bytes - xyz = specular color, w = shininess
	public Vector4 AmbientColor; // 16 bytes - ambient color
	public Vector4 CameraPos; // 16 bytes - xyz = position, w = padding
	
	// Light array
	public LightData[MAX_LIGHTS] Lights; // 128 * 16 = 2048 bytes
	public Vector4 LightCount; // 16 bytes - x = active light count, yzw = padding
	
	// Total: 2112 bytes (multiple of 16)
}

[CRepr, Packed]
struct UnlitVertexUniforms
{
	public Matrix MVPMatrix; // 64 bytes (4x float4)
	public Matrix ModelMatrix; // 64 bytes (4x float4)
	// Total: 128 bytes (multiple of 16)
}

[CRepr, Packed]
struct UnlitFragmentUniforms
{
	public Vector4 MaterialColor; // 16 bytes
	// Total: 16 bytes (multiple of 16)
}

[CRepr, Packed]
struct SpriteVertexUniforms
{
	public Matrix MVPMatrix; // 64 bytes (4x float4)
	public Vector4 UVOffsetScale; // 16 bytes - xy = offset, zw = scale
	// Total: 80 bytes (multiple of 16)
}

[CRepr, Packed]
struct SpriteFragmentUniforms
{
	public Vector4 TintColor; // 16 bytes - rgba tint color
	// Total: 16 bytes (multiple of 16)
}

[CRepr, Packed]
struct PBRVertexUniforms
{
	public Matrix MVPMatrix; // 64 bytes (4x float4)
	public Matrix ModelMatrix; // 64 bytes (4x float4)
	public Matrix NormalMatrix; // 64 bytes (4x float4)
	// Total: 192 bytes (multiple of 16)
}

[CRepr, Packed]
struct PBRFragmentUniforms
{
	// Material properties
	public Vector4 AlbedoColor; // 16 bytes - base color
	public Vector4 EmissiveColor; // 16 bytes - xyz = emissive, w = intensity
	public Vector4 MetallicRoughnessAO; // 16 bytes - x = metallic, y = roughness, z = AO, w = padding
	public Vector4 CameraPos; // 16 bytes - xyz = position, w = padding
	
	// Light array
	public LightData[MAX_LIGHTS] Lights; // 128 * 16 = 2048 bytes
	public Vector4 LightCount; // 16 bytes - x = active light count, yzw = padding
	
	// Total: 2112 bytes (multiple of 16)
}

[CRepr, Packed]
struct ShadowVertexUniforms
{
	public Matrix LightSpaceMatrix; // 64 bytes (4x float4)
	// Total: 64 bytes (multiple of 16)
}

class SDLRendererSubsystem : Subsystem
{
	public override StringView Name => "SDLRenderer";

	internal SDL_GPUDevice* mDevice;
	internal SDL3Window mPrimaryWindow;

	internal SDL_GPUShaderFormat ShaderFormat = .SDL_GPU_SHADERFORMAT_SPIRV; // Set appropriately

	private IEngine.RegisteredUpdateFunctionInfo? mUpdateFunctionRegistration;
	private IEngine.RegisteredUpdateFunctionInfo? mRenderFunctionRegistration;

	private readonly MeshResourceManager mMeshResourceManager = new .() ~ delete _;
	private readonly TextureResourceManager mTextureResourceManager = new .() ~ delete _;
	private readonly MaterialResourceManager mMaterialResourceManager = new .() ~ delete _;

	private List<RenderModule> mRenderModules = new .() ~ delete _;

	// Pipelines
	private SDL_GPUGraphicsPipeline* mLitPipeline;
	private SDL_GPUGraphicsPipeline* mUnlitPipeline;
	private SDL_GPUGraphicsPipeline* mPBRPipeline;
	private SDL_GPUGraphicsPipeline* mSpritePipeline;
	private SDL_GPUGraphicsPipeline* mShadowPipeline;
	private SDL_GPUShader* mLitVertexShader;
	private SDL_GPUShader* mLitFragmentShader;
	private SDL_GPUShader* mUnlitVertexShader;
	private SDL_GPUShader* mUnlitFragmentShader;
	private SDL_GPUShader* mPBRVertexShader;
	private SDL_GPUShader* mPBRFragmentShader;
	private SDL_GPUShader* mSpriteVertexShader;
	private SDL_GPUShader* mSpriteFragmentShader;
	private SDL_GPUShader* mShadowVertexShader;
	private SDL_GPUShader* mShadowFragmentShader;

	// Default textures
	private GPUResourceHandle<GPUTexture> mDefaultWhiteTexture;
	private GPUResourceHandle<GPUTexture> mDefaultBlackTexture;
	private GPUResourceHandle<GPUTexture> mDefaultNormalTexture;
	private SDL_GPUTexture* mDefaultShadowTexture;

	// Default Samplers
	private SDL_GPUSampler* mDefaultDepthSampler;

	private SDL_GPUSampler* mDefaultShadowSampler;

	public uint32 Width => mPrimaryWindow.Width;
	public uint32 Height => mPrimaryWindow.Height;

	public this(SDL3Window primaryWindow)
	{
		mPrimaryWindow = primaryWindow;
	}

	protected override Result<void> OnInitializing(IEngine engine)
	{
		mUpdateFunctionRegistration = engine.RegisterUpdateFunction(.()
			{
				Priority = 1,
				Stage = .VariableUpdate,
				Function = new => OnUpdate
			});

		mRenderFunctionRegistration = engine.RegisterUpdateFunction(.()
			{
				Priority = -100,
				Stage = .PostUpdate,
				Function = new => OnRender
			});

		engine.ResourceSystem.AddResourceManager(mMeshResourceManager);
		engine.ResourceSystem.AddResourceManager(mTextureResourceManager);
		engine.ResourceSystem.AddResourceManager(mMaterialResourceManager);

		// Initialize SDL GPU device
		mDevice = SDL_CreateGPUDevice(
			.SDL_GPU_SHADERFORMAT_SPIRV | .SDL_GPU_SHADERFORMAT_DXIL | .SDL_GPU_SHADERFORMAT_MSL,
			true, null);

		if (!SDL_ClaimWindowForGPUDevice(mDevice, (SDL_Window*)mPrimaryWindow.GetNativePointer("SDL")))
		{
			SDL_Log("GPUClaimWindow failed");
			return .Err;
		}

		GetGPUShaderFormat();

		// Create basic resources
		CreateShaders();
		CreatePipelines();
		CreateDefaultTextures();

		return base.OnInitializing(engine);
	}

	protected override void OnUnitializing(IEngine engine)
	{
		// Cleanup
		mDefaultWhiteTexture.Release();
		mDefaultBlackTexture.Release();
		mDefaultNormalTexture.Release();

		if (mDefaultDepthSampler != null)
		{
			SDL_ReleaseGPUSampler(mDevice, mDefaultDepthSampler);
		}

		if (mDefaultShadowTexture != null)
		{
		    SDL_ReleaseGPUTexture(mDevice, mDefaultShadowTexture);
		}
		if (mDefaultShadowSampler != null)
		{
		    SDL_ReleaseGPUSampler(mDevice, mDefaultShadowSampler);
		}

		SDL_ReleaseGPUGraphicsPipeline(mDevice, mLitPipeline);
		SDL_ReleaseGPUGraphicsPipeline(mDevice, mUnlitPipeline);
		SDL_ReleaseGPUGraphicsPipeline(mDevice, mPBRPipeline);
		SDL_ReleaseGPUGraphicsPipeline(mDevice, mSpritePipeline);
		SDL_ReleaseGPUGraphicsPipeline(mDevice, mShadowPipeline);
		SDL_ReleaseGPUShader(mDevice, mLitVertexShader);
		SDL_ReleaseGPUShader(mDevice, mLitFragmentShader);
		SDL_ReleaseGPUShader(mDevice, mUnlitVertexShader);
		SDL_ReleaseGPUShader(mDevice, mUnlitFragmentShader);
		SDL_ReleaseGPUShader(mDevice, mPBRVertexShader);
		SDL_ReleaseGPUShader(mDevice, mPBRFragmentShader);
		SDL_ReleaseGPUShader(mDevice, mSpriteVertexShader);
		SDL_ReleaseGPUShader(mDevice, mSpriteFragmentShader);
		SDL_ReleaseGPUShader(mDevice, mShadowVertexShader);
		SDL_ReleaseGPUShader(mDevice, mShadowFragmentShader);

		SDL_ReleaseWindowFromGPUDevice(mDevice, (SDL_Window*)mPrimaryWindow.GetNativePointer("SDL"));

		SDL_DestroyGPUDevice(mDevice);

		engine.ResourceSystem.RemoveResourceManager(mMeshResourceManager);
		engine.ResourceSystem.RemoveResourceManager(mTextureResourceManager);
		engine.ResourceSystem.RemoveResourceManager(mMaterialResourceManager);

		if (mUpdateFunctionRegistration.HasValue)
		{
			engine.UnregisterUpdateFunction(mUpdateFunctionRegistration.Value);
			delete mUpdateFunctionRegistration.Value.Function;
			mUpdateFunctionRegistration = null;
		}

		if (mRenderFunctionRegistration.HasValue)
		{
			engine.UnregisterUpdateFunction(mRenderFunctionRegistration.Value);
			delete mRenderFunctionRegistration.Value.Function;
			mRenderFunctionRegistration = null;
		}

		base.OnUnitializing(engine);
	}

	protected override void CreateSceneModules(Scene scene, List<SceneModule> modules)
	{
		var renderModule = new RenderModule(this);
		modules.Add(renderModule);
		mRenderModules.Add(renderModule);
	}

	protected override void DestroySceneModules(Scene scene)
	{
		for (int i = mRenderModules.Count - 1; i >= 0; i--)
		{
			if (mRenderModules[i].Scene == scene)
			{
				delete mRenderModules[i];
				mRenderModules.RemoveAt(i);
			}
		}
	}

	private void CreateShaders()
	{
		// SDL GPU binding model for DXIL/DXBC:
		// Vertex shaders: uniforms in space1
		// Fragment shaders: uniforms in space3
		
		// Lit vertex shader - uniforms in space1
		String litVertexShaderSource = """
			cbuffer UBO : register(b0, space1)
			{
			    float4x4 MVPMatrix;
			    float4x4 ModelMatrix;
			    float4x4 NormalMatrix;
			};
		
			struct VSInput
			{
			    float3 Position : TEXCOORD0;
			    float3 Normal : TEXCOORD1;
			    float2 TexCoord : TEXCOORD2;
			    uint Color : TEXCOORD3;
			};
		
			struct VSOutput
			{
			    float4 Position : SV_POSITION;
			    float2 TexCoord : TEXCOORD0;
			    float4 Color : TEXCOORD1;
			    float3 Normal : TEXCOORD2;
			    float3 WorldPos : TEXCOORD3;
			};
		
			float4 UnpackColor(uint packedColor)
			{
			   float4 color;
			   color.r = float((packedColor >> 0) & 0xFF) / 255.0;
			   color.g = float((packedColor >> 8) & 0xFF) / 255.0;
			   color.b = float((packedColor >> 16) & 0xFF) / 255.0;
			   color.a = float((packedColor >> 24) & 0xFF) / 255.0;
			   return color;
			}
		
		
			VSOutput main(VSInput input)
			{
			    VSOutput output;
			    output.Position = mul(MVPMatrix, float4(input.Position, 1.0));
			    output.TexCoord = input.TexCoord;
			    output.Color = UnpackColor(input.Color);
			    output.Normal = normalize(mul((float3x3)NormalMatrix, input.Normal));
			    output.WorldPos = mul(ModelMatrix, float4(input.Position, 1.0)).xyz;
			    return output;
			}
		""";

		// Lit fragment shader with shadows - uniforms in space3, textures in space2
		String litFragmentShaderSource = """
		static const int MAX_LIGHTS = 16;
		
		struct LightData
		{
		    float4 PositionType;     // xyz = position, w = type (0=dir, 1=point, 2=spot)
		    float4 DirectionRange;   // xyz = direction, w = range
		    float4 ColorIntensity;   // xyz = color, w = intensity
		    float4 SpotAngles;       // x = inner angle cos, y = outer angle cos, z = shadow bias, w = shadow normal bias
		    float4x4 ShadowMatrix;   // Light space matrix for shadow mapping
		};
		
		cbuffer UniformBlock : register(b0, space3)
		{
		    float4 MaterialColor;         // diffuse color
		    float4 SpecularColorShininess; // xyz = specular color, w = shininess
		    float4 AmbientColor;          // ambient color
		    float4 CameraPos;            // xyz = position, w = padding
		    LightData Lights[MAX_LIGHTS];
		    float4 LightCount;           // x = active light count
		};
		
		Texture2D DiffuseTexture : register(t0, space2);
		SamplerState DiffuseSampler : register(s0, space2);
		
		// Shadow maps
		//Texture2D ShadowMaps[MAX_LIGHTS] : register(t0, space2);
		//SamplerComparisonState ShadowSamplers[MAX_LIGHTS] : register(s0, space2);
		
		struct PSInput
		{
		    float4 Position : SV_Position;
		    float2 TexCoord : TEXCOORD0;
		    float4 Color : TEXCOORD1;
		    float3 Normal : TEXCOORD2;
		    float3 WorldPos : TEXCOORD3;
		};
		
		float CalculateShadow(int lightIndex, float3 worldPos, float3 normal, float3 lightDir)
		{
			/*
		    // Transform world position to light space
		    float4 lightSpacePos = mul(Lights[lightIndex].ShadowMatrix, float4(worldPos, 1.0));
		    
		    // Perform perspective divide
		    float3 projCoords = lightSpacePos.xyz / lightSpacePos.w;
		    
		    // Transform to [0,1] range
		    projCoords.x = projCoords.x * 0.5 + 0.5;
		    projCoords.y = projCoords.y * 0.5 + 0.5;
		    
		    // Check if position is outside light frustum
		    if (projCoords.z > 1.0 || projCoords.z < 0.0 ||
		        projCoords.x > 1.0 || projCoords.x < 0.0 ||
		        projCoords.y > 1.0 || projCoords.y < 0.0)
		        return 1.0;
		    
		    // Calculate bias
		    float bias = Lights[lightIndex].SpotAngles.z;
		    float normalBias = Lights[lightIndex].SpotAngles.w;
		    
		    // Slope-based bias
		    float slopeBias = bias * tan(acos(saturate(dot(normal, -lightDir))));
		    bias = max(bias, slopeBias);
		    
		    // PCF filtering
		    float shadow = 0.0;
		    float2 texelSize = 1.0 / 2048.0; // Assuming 2048x2048 shadow map
		    
		    for (int x = -1; x <= 1; ++x)
		    {
		        for (int y = -1; y <= 1; ++y)
		        {
		            float2 offset = float2(x, y) * texelSize;
		            shadow += ShadowMaps[lightIndex].SampleCmpLevelZero(
		                ShadowSamplers[lightIndex], 
		                projCoords.xy + offset, 
		                projCoords.z - bias
		            );
		        }
		    }
		    shadow /= 9.0;
		    
		    return shadow;
			*/
			return 1.0;
		}
		
		float3 CalculateDirectionalLight(LightData light, float3 normal, float3 viewDir, float3 materialColor, float3 specularColor, float shininess, float3 worldPos, int lightIndex)
		{
		    float3 lightDir = normalize(light.DirectionRange.xyz);
		    float3 lightColor = light.ColorIntensity.xyz;
		    float lightIntensity = light.ColorIntensity.w;
		    
		    // Diffuse
		    float NdotL = max(dot(normal, -lightDir), 0.0);
		    float3 diffuse = NdotL * lightColor * lightIntensity;
		    
		    // Specular
		    float3 halfVector = normalize(viewDir - lightDir);
		    float NdotH = max(dot(normal, halfVector), 0.0);
		    float specularIntensity = pow(NdotH, shininess);
		    float3 specular = specularIntensity * specularColor * lightColor * lightIntensity;
		    
		    // Calculate shadow
		    float shadow = CalculateShadow(lightIndex, worldPos, normal, lightDir);
		    
		    return shadow * (diffuse * materialColor + specular);
		}
		
		float3 CalculatePointLight(LightData light, float3 normal, float3 worldPos, float3 viewDir, float3 materialColor, float3 specularColor, float shininess, int lightIndex)
		{
		    float3 lightPos = light.PositionType.xyz;
		    float3 lightColor = light.ColorIntensity.xyz;
		    float lightIntensity = light.ColorIntensity.w;
		    float range = light.DirectionRange.w;
		    
		    // Light direction from surface to light
		    float3 lightDir = lightPos - worldPos;
		    float distance = length(lightDir);
		    lightDir = normalize(lightDir);
		    
		    // Range-based attenuation
		    float attenuation = 1.0 - saturate(distance / range);
		    attenuation *= attenuation; // Square for smoother falloff
		    
		    // Diffuse
		    float NdotL = max(dot(normal, lightDir), 0.0);
		    float3 diffuse = NdotL * lightColor * lightIntensity * attenuation;
		    
		    // Specular
		    float3 halfVector = normalize(viewDir + lightDir);
		    float NdotH = max(dot(normal, halfVector), 0.0);
		    float specularIntensity = pow(NdotH, shininess);
		    float3 specular = specularIntensity * specularColor * lightColor * lightIntensity * attenuation;
		    
		    return diffuse * materialColor + specular;
		}
		
		float3 CalculateSpotLight(LightData light, float3 normal, float3 worldPos, float3 viewDir, float3 materialColor, float3 specularColor, float shininess, int lightIndex)
		{
		    float3 lightPos = light.PositionType.xyz;
		    float3 spotDir = normalize(light.DirectionRange.xyz);
		    float3 lightColor = light.ColorIntensity.xyz;
		    float lightIntensity = light.ColorIntensity.w;
		    float range = light.DirectionRange.w;
		    float innerCos = light.SpotAngles.x;
		    float outerCos = light.SpotAngles.y;
		    
		    // Light direction from surface to light
		    float3 lightDir = lightPos - worldPos;
		    float distance = length(lightDir);
		    lightDir = normalize(lightDir);
		    
		    // Spot cone calculation
		    float cosAngle = dot(-lightDir, spotDir);
		    float spotEffect = smoothstep(outerCos, innerCos, cosAngle);
		    
		    // Range-based attenuation
		    float attenuation = 1.0 - saturate(distance / range);
		    attenuation *= attenuation; // Square for smoother falloff
		    attenuation *= spotEffect;
		    
		    // Diffuse
		    float NdotL = max(dot(normal, lightDir), 0.0);
		    float3 diffuse = NdotL * lightColor * lightIntensity * attenuation;
		    
		    // Specular
		    float3 halfVector = normalize(viewDir + lightDir);
		    float NdotH = max(dot(normal, halfVector), 0.0);
		    float specularIntensity = pow(NdotH, shininess);
		    float3 specular = specularIntensity * specularColor * lightColor * lightIntensity * attenuation;
		    
		    // Calculate shadow
		    float shadow = CalculateShadow(lightIndex, worldPos, normal, -lightDir);
		    
		    return shadow * (diffuse * materialColor + specular);
		}
		
		float4 main(PSInput input) : SV_Target
		{
		    // Sample diffuse texture
		    float4 diffuseTexColor = DiffuseTexture.Sample(DiffuseSampler, input.TexCoord);
		    
		    // Normalize the normal
		    float3 normal = normalize(input.Normal);
		    
		    // Calculate view direction
		    float3 viewDir = normalize(CameraPos.xyz - input.WorldPos);
		    
		    // Extract material parameters
		    float3 materialColor = MaterialColor.rgb * input.Color.rgb * diffuseTexColor.rgb;
		    float3 specularColor = SpecularColorShininess.xyz;
		    float shininess = SpecularColorShininess.w;
		    
		    // Start with ambient
		    float3 finalColor = AmbientColor.rgb * materialColor;
		    
		    // Accumulate lighting from all active lights
		    int lightCount = (int)LightCount.x;
		    for (int i = 0; i < lightCount; i++)
		    {
		        float lightType = Lights[i].PositionType.w;
		        
		        if (lightType < 0.5) // Directional light
		        {
		            finalColor += CalculateDirectionalLight(Lights[i], normal, viewDir, materialColor, specularColor, shininess, input.WorldPos, i);
		        }
		        else if (lightType < 1.5) // Point light
		        {
		            finalColor += CalculatePointLight(Lights[i], normal, input.WorldPos, viewDir, materialColor, specularColor, shininess, i);
		        }
		        else // Spot light
		        {
		            finalColor += CalculateSpotLight(Lights[i], normal, input.WorldPos, viewDir, materialColor, specularColor, shininess, i);
		        }
		    }
		    
		    return float4(finalColor, MaterialColor.a * input.Color.a * diffuseTexColor.a);
		}
		""";

		// Unlit vertex shader - uniforms in space1
		String unlitVertexShaderSource = """
		cbuffer UniformBlock : register(b0, space1)
		{
			float4x4 MVPMatrix;
			float4x4 ModelMatrix;
		};
		
		struct VSInput
		{
			float3 Position : TEXCOORD0;
			float3 Normal : TEXCOORD1;
			float2 TexCoord : TEXCOORD2;
			uint Color : TEXCOORD3;
		};
		
		struct VSOutput
		{
			float4 Position : SV_Position;
			float2 TexCoord : TEXCOORD0;
			float4 Color : TEXCOORD1;
		};
		
		float4 UnpackColor(uint packedColor)
		{
			float4 color;
			color.r = float((packedColor >> 0) & 0xFF) / 255.0;
			color.g = float((packedColor >> 8) & 0xFF) / 255.0;
			color.b = float((packedColor >> 16) & 0xFF) / 255.0;
			color.a = float((packedColor >> 24) & 0xFF) / 255.0;
			return color;
		}
		
		VSOutput main(VSInput input)
		{
			VSOutput output;
			output.Position = mul(MVPMatrix, float4(input.Position, 1.0));
			output.TexCoord = input.TexCoord;
			output.Color = UnpackColor(input.Color);
			return output;
		}
		""";

		// Unlit fragment shader - uniforms in space3, textures in space2
		String unlitFragmentShaderSource = """
		cbuffer UniformBlock : register(b0, space3)
		{
			float4 MaterialColor;
		};
		
		Texture2D MainTexture : register(t0, space2);
		SamplerState MainSampler : register(s0, space2);
		
		struct PSInput
		{
			float4 Position : SV_Position;
			float2 TexCoord : TEXCOORD0;
			float4 Color : TEXCOORD1;
		};
		
		float4 main(PSInput input) : SV_Target
		{
			// Sample texture if available, otherwise use white
			float4 texColor = MainTexture.Sample(MainSampler, input.TexCoord);
			
			// Combine material color, vertex color, and texture
			return MaterialColor * input.Color * texColor;
		}
		""";

		// PBR vertex shader - same as lit vertex shader
		String pbrVertexShaderSource = """
			cbuffer UBO : register(b0, space1)
			{
			    float4x4 MVPMatrix;
			    float4x4 ModelMatrix;
			    float4x4 NormalMatrix;
			};
		
			struct VSInput
			{
			    float3 Position : TEXCOORD0;
			    float3 Normal : TEXCOORD1;
			    float2 TexCoord : TEXCOORD2;
			    uint Color : TEXCOORD3;
			};
		
			struct VSOutput
			{
			    float4 Position : SV_POSITION;
			    float2 TexCoord : TEXCOORD0;
			    float4 Color : TEXCOORD1;
			    float3 Normal : TEXCOORD2;
			    float3 WorldPos : TEXCOORD3;
			};
		
			float4 UnpackColor(uint packedColor)
			{
			   float4 color;
			   color.r = float((packedColor >> 0) & 0xFF) / 255.0;
			   color.g = float((packedColor >> 8) & 0xFF) / 255.0;
			   color.b = float((packedColor >> 16) & 0xFF) / 255.0;
			   color.a = float((packedColor >> 24) & 0xFF) / 255.0;
			   return color;
			}
		
			VSOutput main(VSInput input)
			{
			    VSOutput output;
			    output.Position = mul(MVPMatrix, float4(input.Position, 1.0));
			    output.TexCoord = input.TexCoord;
			    output.Color = UnpackColor(input.Color);
			    output.Normal = normalize(mul((float3x3)NormalMatrix, input.Normal));
			    output.WorldPos = mul(ModelMatrix, float4(input.Position, 1.0)).xyz;
			    return output;
			}
		""";

		// PBR fragment shader with shadows - physically based rendering
		String pbrFragmentShaderSource = """
			static const int MAX_LIGHTS = 16;
			static const float PI = 3.14159265359;
			
			struct LightData
			{
			    float4 PositionType;     // xyz = position, w = type (0=dir, 1=point, 2=spot)
			    float4 DirectionRange;   // xyz = direction, w = range
			    float4 ColorIntensity;   // xyz = color, w = intensity
			    float4 SpotAngles;       // x = inner angle cos, y = outer angle cos, z = shadow bias, w = shadow normal bias
			    float4x4 ShadowMatrix;   // Light space matrix for shadow mapping
			};
			
			cbuffer UniformBlock : register(b0, space3)
			{
			    float4 AlbedoColor;
			    float4 EmissiveColor; // xyz = color, w = intensity
			    float4 MetallicRoughnessAO; // x = metallic, y = roughness, z = AO
			    float4 CameraPos;
			    LightData Lights[MAX_LIGHTS];
			    float4 LightCount; // x = active light count
			};
			
			Texture2D AlbedoTexture : register(t0, space2);
			SamplerState AlbedoSampler : register(s0, space2);
			Texture2D NormalTexture : register(t1, space2);
			SamplerState NormalSampler : register(s1, space2);
			Texture2D MetallicRoughnessTexture : register(t2, space2);
			SamplerState MetallicRoughnessSampler : register(s2, space2);
			
			// Shadow maps
			Texture2D ShadowMaps[MAX_LIGHTS] : register(t3, space2);
			SamplerComparisonState ShadowSamplers[MAX_LIGHTS] : register(s3, space2);
			
			struct PSInput
			{
			    float4 Position : SV_Position;
			    float2 TexCoord : TEXCOORD0;
			    float4 Color : TEXCOORD1;
			    float3 Normal : TEXCOORD2;
			    float3 WorldPos : TEXCOORD3;
			};
			
			// Normal Distribution Function (GGX/Trowbridge-Reitz)
			float DistributionGGX(float3 N, float3 H, float roughness)
			{
			    float a = roughness * roughness;
			    float a2 = a * a;
			    float NdotH = max(dot(N, H), 0.0);
			    float NdotH2 = NdotH * NdotH;
			    
			    float num = a2;
			    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
			    denom = PI * denom * denom;
			    
			    return num / denom;
			}
			
			// Geometry Function (Smith's method)
			float GeometrySchlickGGX(float NdotV, float roughness)
			{
			    float r = (roughness + 1.0);
			    float k = (r * r) / 8.0;
			    
			    float num = NdotV;
			    float denom = NdotV * (1.0 - k) + k;
			    
			    return num / denom;
			}
			
			float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
			{
			    float NdotV = max(dot(N, V), 0.0);
			    float NdotL = max(dot(N, L), 0.0);
			    float ggx2 = GeometrySchlickGGX(NdotV, roughness);
			    float ggx1 = GeometrySchlickGGX(NdotL, roughness);
			    
			    return ggx1 * ggx2;
			}
			
			// Fresnel Equation (Schlick approximation)
			float3 FresnelSchlick(float cosTheta, float3 F0)
			{
			    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
			}
			
			float CalculateShadow(int lightIndex, float3 worldPos, float3 normal, float3 lightDir)
			{
			    // Transform world position to light space
			    float4 lightSpacePos = mul(Lights[lightIndex].ShadowMatrix, float4(worldPos, 1.0));
			    
			    // Perform perspective divide
			    float3 projCoords = lightSpacePos.xyz / lightSpacePos.w;
			    
			    // Transform to [0,1] range
			    projCoords.x = projCoords.x * 0.5 + 0.5;
			    projCoords.y = projCoords.y * 0.5 + 0.5;
			    
			    // Check if position is outside light frustum
			    if (projCoords.z > 1.0 || projCoords.z < 0.0 ||
			        projCoords.x > 1.0 || projCoords.x < 0.0 ||
			        projCoords.y > 1.0 || projCoords.y < 0.0)
			        return 1.0;
			    
			    // Calculate bias
			    float bias = Lights[lightIndex].SpotAngles.z;
			    float normalBias = Lights[lightIndex].SpotAngles.w;
			    
			    // Slope-based bias
			    float slopeBias = bias * tan(acos(saturate(dot(normal, -lightDir))));
			    bias = max(bias, slopeBias);
			    
			    // PCF filtering
			    float shadow = 0.0;
			    float2 texelSize = 1.0 / 2048.0; // Assuming 2048x2048 shadow map
			    
			    for (int x = -1; x <= 1; ++x)
			    {
			        for (int y = -1; y <= 1; ++y)
			        {
			            float2 offset = float2(x, y) * texelSize;
			            shadow += ShadowMaps[lightIndex].SampleCmpLevelZero(
			                ShadowSamplers[lightIndex], 
			                projCoords.xy + offset, 
			                projCoords.z - bias
			            );
			        }
			    }
			    shadow /= 9.0;
			    
			    return shadow;
			}
			
			float3 CalculatePBRLight(float3 L, float3 V, float3 N, float3 albedo, float metallic, float roughness, float3 lightColor, float attenuation)
			{
			    float3 H = normalize(V + L);
			    
			    // Calculate F0 (base reflectivity)
			    float3 F0 = float3(0.04, 0.04, 0.04); // Default for dielectrics
			    F0 = lerp(F0, albedo, metallic);
			    
			    // Cook-Torrance BRDF
			    float NDF = DistributionGGX(N, H, roughness);
			    float G = GeometrySmith(N, V, L, roughness);
			    float3 F = FresnelSchlick(max(dot(H, V), 0.0), F0);
			    
			    float3 kS = F;
			    float3 kD = float3(1.0, 1.0, 1.0) - kS;
			    kD *= 1.0 - metallic; // Metals have no diffuse
			    
			    float NdotL = max(dot(N, L), 0.0);
			    
			    float3 numerator = NDF * G * F;
			    float denominator = 4.0 * max(dot(N, V), 0.0) * NdotL + 0.0001;
			    float3 specular = numerator / denominator;
			    
			    // Final lighting calculation
			    return (kD * albedo / PI + specular) * lightColor * NdotL * attenuation;
			}
			
			float4 main(PSInput input) : SV_Target
			{
			    // Sample textures
			    float4 albedoSample = AlbedoTexture.Sample(AlbedoSampler, input.TexCoord);
			    float3 albedo = pow(albedoSample.rgb * AlbedoColor.rgb * input.Color.rgb, 2.2); // Convert to linear space
			    
			    float3 normal = normalize(input.Normal);
			    // TODO: Normal mapping support
			    
			    float metallic = MetallicRoughnessAO.x;
			    float roughness = MetallicRoughnessAO.y;
			    float ao = MetallicRoughnessAO.z;
			    
			    // Sample metallic/roughness texture if available
			    float3 mrSample = MetallicRoughnessTexture.Sample(MetallicRoughnessSampler, input.TexCoord).rgb;
			    metallic *= mrSample.b; // Often packed as: R=AO, G=Roughness, B=Metallic
			    roughness *= mrSample.g;
			    
			    float3 V = normalize(CameraPos.xyz - input.WorldPos);
			    
			    // Accumulate lighting from all lights
			    float3 Lo = float3(0.0, 0.0, 0.0);
			    int lightCount = (int)LightCount.x;
			    
			    for (int i = 0; i < lightCount; i++)
			    {
			        float lightType = Lights[i].PositionType.w;
			        float3 lightColor = Lights[i].ColorIntensity.xyz * Lights[i].ColorIntensity.w;
			        float3 L;
			        float attenuation = 1.0;
			        float shadow = 1.0;
			        
			        if (lightType < 0.5) // Directional light
			        {
			            L = normalize(-Lights[i].DirectionRange.xyz);
			            shadow = CalculateShadow(i, input.WorldPos, normal, L);
			        }
			        else if (lightType < 1.5) // Point light
			        {
			            float3 lightPos = Lights[i].PositionType.xyz;
			            float range = Lights[i].DirectionRange.w;
			            
			            L = lightPos - input.WorldPos;
			            float distance = length(L);
			            L = normalize(L);
			            
			            // Range-based attenuation
			            attenuation = 1.0 - saturate(distance / range);
			            attenuation *= attenuation;
			        }
			        else // Spot light
			        {
			            float3 lightPos = Lights[i].PositionType.xyz;
			            float3 spotDir = normalize(Lights[i].DirectionRange.xyz);
			            float range = Lights[i].DirectionRange.w;
			            float innerCos = Lights[i].SpotAngles.x;
			            float outerCos = Lights[i].SpotAngles.y;
			            
			            L = lightPos - input.WorldPos;
			            float distance = length(L);
			            L = normalize(L);
			            
			            // Spot cone calculation
			            float cosAngle = dot(-L, spotDir);
			            float spotEffect = smoothstep(outerCos, innerCos, cosAngle);
			            
			            // Range-based attenuation
			            attenuation = 1.0 - saturate(distance / range);
			            attenuation *= attenuation;
			            attenuation *= spotEffect;
			            
			            shadow = CalculateShadow(i, input.WorldPos, normal, -L);
			        }
			        
			        Lo += shadow * CalculatePBRLight(L, V, normal, albedo, metallic, roughness, lightColor, attenuation);
			    }
			    
			    // Ambient lighting (simplified - should use IBL)
			    float3 ambient = float3(0.03, 0.03, 0.03) * albedo * ao;
			    
			    // Emissive
			    float3 emissive = EmissiveColor.rgb * EmissiveColor.w;
			    
			    float3 color = ambient + Lo + emissive;
			    
			    // Tone mapping and gamma correction
			    color = color / (color + float3(1.0, 1.0, 1.0)); // Reinhard tone mapping
			    color = pow(color, 1.0/2.2); // Gamma correction
			    
			    return float4(color, albedoSample.a * AlbedoColor.a);
			}
		""";

		// Sprite vertex shader - uniforms in space1
		String spriteVertexShaderSource = """
			cbuffer UBO : register(b0, space1)
			{
			    float4x4 MVPMatrix;
			    float4 UVOffsetScale; // xy = offset, zw = scale
			};
		
			struct VSInput
			{
			    float3 Position : TEXCOORD0;
			    float3 Normal : TEXCOORD1;
			    float2 TexCoord : TEXCOORD2;
			    uint Color : TEXCOORD3;
			};
		
			struct VSOutput
			{
			    float4 Position : SV_POSITION;
			    float2 TexCoord : TEXCOORD0;
			    float4 Color : TEXCOORD1;
			};
		
			float4 UnpackColor(uint packedColor)
			{
			   float4 color;
			   color.r = float((packedColor >> 0) & 0xFF) / 255.0;
			   color.g = float((packedColor >> 8) & 0xFF) / 255.0;
			   color.b = float((packedColor >> 16) & 0xFF) / 255.0;
			   color.a = float((packedColor >> 24) & 0xFF) / 255.0;
			   return color;
			}
		
			VSOutput main(VSInput input)
			{
			    VSOutput output;
			    output.Position = mul(MVPMatrix, float4(input.Position, 1.0));
			    
			    // Apply UV offset and scale for sprite sheet support
			    output.TexCoord = input.TexCoord * UVOffsetScale.zw + UVOffsetScale.xy;
			    
			    output.Color = UnpackColor(input.Color);
			    return output;
			}
		""";

		// Sprite fragment shader - uniforms in space3, textures in space2
		String spriteFragmentShaderSource = """
			cbuffer UniformBlock : register(b0, space3)
			{
			    float4 TintColor;
			};
			
			Texture2D SpriteTexture : register(t0, space2);
			SamplerState SpriteSampler : register(s0, space2);
			
			struct PSInput
			{
			    float4 Position : SV_Position;
			    float2 TexCoord : TEXCOORD0;
			    float4 Color : TEXCOORD1;
			};
			
			float4 main(PSInput input) : SV_Target
			{
			    float4 texColor = SpriteTexture.Sample(SpriteSampler, input.TexCoord);
			    
			    // Combine texture color with vertex color and tint
			    float4 finalColor = texColor * input.Color * TintColor;
			    
			    // Alpha test for pixel-perfect sprites
			    if (finalColor.a < 0.01)
			        discard;
			        
			    return finalColor;
			}
		""";

		// Shadow map vertex shader - only needs to transform vertices
		String shadowVertexShaderSource = """
		    cbuffer UBO : register(b0, space1)
		    {
		        float4x4 LightSpaceMatrix;
		    };
		
		    struct VSInput
		    {
		        float3 Position : TEXCOORD0;
		        float3 Normal : TEXCOORD1;
		        float2 TexCoord : TEXCOORD2;
		        uint Color : TEXCOORD3;
		    };
		
		    struct VSOutput
		    {
		        float4 Position : SV_POSITION;
		    };
		
		    VSOutput main(VSInput input)
		    {
		        VSOutput output;
		        output.Position = mul(LightSpaceMatrix, float4(input.Position, 1.0));
		        return output;
		    }
		""";

		// Shadow map fragment shader - only writes depth
		String shadowFragmentShaderSource = """
		    void main()
		    {
		        // Depth is written automatically
		    }
		""";

		// Compile all shaders
		var litVsCode = scope List<uint8>();
		var litPsCode = scope List<uint8>();
		var unlitVsCode = scope List<uint8>();
		var unlitPsCode = scope List<uint8>();
		var pbrVsCode = scope List<uint8>();
		var pbrPsCode = scope List<uint8>();
		var spriteVsCode = scope List<uint8>();
		var spritePsCode = scope List<uint8>();
		var shadowVsCode = scope List<uint8>();
		var shadowPsCode = scope List<uint8>();

		CompileShaderFromSource(litVertexShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_VERTEX, "main", litVsCode);
		CompileShaderFromSource(litFragmentShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT, "main", litPsCode);
		CompileShaderFromSource(unlitVertexShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_VERTEX, "main", unlitVsCode);
		CompileShaderFromSource(unlitFragmentShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT, "main", unlitPsCode);
		CompileShaderFromSource(pbrVertexShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_VERTEX, "main", pbrVsCode);
		CompileShaderFromSource(pbrFragmentShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT, "main", pbrPsCode);
		CompileShaderFromSource(spriteVertexShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_VERTEX, "main", spriteVsCode);
		CompileShaderFromSource(spriteFragmentShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT, "main", spritePsCode);
		CompileShaderFromSource(shadowVertexShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_VERTEX, "main", shadowVsCode);
		CompileShaderFromSource(shadowFragmentShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT, "main", shadowPsCode);

		// Create shader objects
		var litVsDesc = SDL_GPUShaderCreateInfo()
			{
				code = litVsCode.Ptr,
				code_size = (uint32)litVsCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_VERTEX,
				num_samplers = 0,
				num_uniform_buffers = 1, // We have 1 uniform buffer
				num_storage_buffers = 0,
				num_storage_textures = 0
			};
		mLitVertexShader = SDL_CreateGPUShader(mDevice, &litVsDesc);

		// Lit fragment shader descriptor - needs to account for shadow maps
		var litPsDesc = SDL_GPUShaderCreateInfo()
			{
				code = litPsCode.Ptr,
				code_size = (uint32)litPsCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_FRAGMENT,
				num_samplers = 1 + MAX_LIGHTS, // 1 diffuse + MAX_LIGHTS shadow maps
				num_uniform_buffers = 1,
				num_storage_buffers = 0,
				num_storage_textures = 0
			};
		mLitFragmentShader = SDL_CreateGPUShader(mDevice, &litPsDesc);

		var unlitVsDesc = SDL_GPUShaderCreateInfo()
			{
				code = unlitVsCode.Ptr,
				code_size = (uint32)unlitVsCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_VERTEX,
				num_samplers = 0,
				num_uniform_buffers = 1, // We have 1 uniform buffer
				num_storage_buffers = 0,
				num_storage_textures = 0
			};
		mUnlitVertexShader = SDL_CreateGPUShader(mDevice, &unlitVsDesc);

		var unlitPsDesc = SDL_GPUShaderCreateInfo()
			{
				code = unlitPsCode.Ptr,
				code_size = (uint32)unlitPsCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_FRAGMENT,
				num_samplers = 1, // We have 1 texture sampler
				num_uniform_buffers = 1, // We have 1 uniform buffer
				num_storage_buffers = 0,
				num_storage_textures = 0
			};
		mUnlitFragmentShader = SDL_CreateGPUShader(mDevice, &unlitPsDesc);

		// Create PBR shaders
		var pbrVsDesc = SDL_GPUShaderCreateInfo()
			{
				code = pbrVsCode.Ptr,
				code_size = (uint32)pbrVsCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_VERTEX,
				num_samplers = 0,
				num_uniform_buffers = 1, // We have 1 uniform buffer
				num_storage_buffers = 0,
				num_storage_textures = 0
			};
		mPBRVertexShader = SDL_CreateGPUShader(mDevice, &pbrVsDesc);

		// PBR fragment shader descriptor
		var pbrPsDesc = SDL_GPUShaderCreateInfo()
			{
				code = pbrPsCode.Ptr,
				code_size = (uint32)pbrPsCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_FRAGMENT,
				num_samplers = 3 + MAX_LIGHTS, // 3 PBR textures + MAX_LIGHTS shadow maps
				num_uniform_buffers = 1,
				num_storage_buffers = 0,
				num_storage_textures = 0
			};
		mPBRFragmentShader = SDL_CreateGPUShader(mDevice, &pbrPsDesc);

		// Create sprite shaders
		var spriteVsDesc = SDL_GPUShaderCreateInfo()
			{
				code = spriteVsCode.Ptr,
				code_size = (uint32)spriteVsCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_VERTEX,
				num_samplers = 0,
				num_uniform_buffers = 1, // We have 1 uniform buffer
				num_storage_buffers = 0,
				num_storage_textures = 0
			};
		mSpriteVertexShader = SDL_CreateGPUShader(mDevice, &spriteVsDesc);

		var spritePsDesc = SDL_GPUShaderCreateInfo()
			{
				code = spritePsCode.Ptr,
				code_size = (uint32)spritePsCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_FRAGMENT,
				num_samplers = 1, // We have 1 sampler for the sprite texture
				num_uniform_buffers = 1, // We have 1 uniform buffer
				num_storage_buffers = 0,
				num_storage_textures = 0
			};
		mSpriteFragmentShader = SDL_CreateGPUShader(mDevice, &spritePsDesc);

		// Create shadow shaders
		var shadowVsDesc = SDL_GPUShaderCreateInfo()
			{
				code = shadowVsCode.Ptr,
				code_size = (uint32)shadowVsCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_VERTEX,
				num_samplers = 0,
				num_uniform_buffers = 1, // We have 1 uniform buffer
				num_storage_buffers = 0,
				num_storage_textures = 0
			};
		mShadowVertexShader = SDL_CreateGPUShader(mDevice, &shadowVsDesc);

		var shadowPsDesc = SDL_GPUShaderCreateInfo()
			{
				code = shadowPsCode.Ptr,
				code_size = (uint32)shadowPsCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_FRAGMENT,
				num_samplers = 0,
				num_uniform_buffers = 0,
				num_storage_buffers = 0,
				num_storage_textures = 0
			};
		mShadowFragmentShader = SDL_CreateGPUShader(mDevice, &shadowPsDesc);
	}

	private void CreatePipelines()
	{
		// Query the swapchain format
		SDL_GPUTextureFormat swapchainFormat = SDL_GetGPUSwapchainTextureFormat(mDevice, (SDL_Window*)mPrimaryWindow.GetNativePointer("SDL"));

		// Define vertex attributes
		var vertexAttributes = SDL_GPUVertexAttribute[4](
			. { location = 0, buffer_slot = 0, format = .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, offset = 0 }, // Position
			. { location = 1, buffer_slot = 0, format = .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, offset = 12 }, // Normal
			. { location = 2, buffer_slot = 0, format = .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, offset = 24 }, // TexCoord
			. { location = 3, buffer_slot = 0, format = .SDL_GPU_VERTEXELEMENTFORMAT_UINT, offset = 32 } // Color
			);

		var vertexBufferDesc = SDL_GPUVertexBufferDescription()
			{
				slot = 0,
				pitch = sizeof(Vector3) + sizeof(Vector3) + sizeof(Vector2) + sizeof(uint32),
				input_rate = .SDL_GPU_VERTEXINPUTRATE_VERTEX,
				instance_step_rate = 0
			};

		var vertexInputState = SDL_GPUVertexInputState()
			{
				vertex_buffer_descriptions = &vertexBufferDesc,
				num_vertex_buffers = 1,
				vertex_attributes = &vertexAttributes[0],
				num_vertex_attributes = 4
			};

		SDL_GPUColorTargetBlendState blendState = .()
			{
				src_color_blendfactor = .SDL_GPU_BLENDFACTOR_SRC_ALPHA,
				dst_color_blendfactor = .SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
				color_blend_op = .SDL_GPU_BLENDOP_ADD,
				src_alpha_blendfactor = .SDL_GPU_BLENDFACTOR_ONE,
				dst_alpha_blendfactor = .SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
				alpha_blend_op = .SDL_GPU_BLENDOP_ADD,
				color_write_mask = .SDL_GPU_COLORCOMPONENT_R | .SDL_GPU_COLORCOMPONENT_G |
					.SDL_GPU_COLORCOMPONENT_B | .SDL_GPU_COLORCOMPONENT_A,
				enable_blend = true,
				enable_color_write_mask = false
			};

		var colorTargetDesc = SDL_GPUColorTargetDescription()
			{
				format = swapchainFormat,
				blend_state = blendState
			};

		var targetInfo = SDL_GPUGraphicsPipelineTargetInfo()
			{
				color_target_descriptions = &colorTargetDesc,
				num_color_targets = 1,
				depth_stencil_format = .SDL_GPU_TEXTUREFORMAT_D32_FLOAT,
				has_depth_stencil_target = true
			};

		SDL_GPURasterizerState rasterState = .()
			{
				fill_mode = .SDL_GPU_FILLMODE_FILL,
				cull_mode = .SDL_GPU_CULLMODE_BACK,
				front_face = .SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE,
				depth_bias_constant_factor = 0,
				depth_bias_clamp = 0,
				depth_bias_slope_factor = 0,
				enable_depth_bias = false,
				enable_depth_clip = true
			};

		SDL_GPUDepthStencilState depthStencilState = .()
			{
				compare_op = .SDL_GPU_COMPAREOP_LESS,
				back_stencil_state = .(),
				front_stencil_state = .(),
				compare_mask = 0,
				write_mask = 0,
				enable_depth_test = true,
				enable_depth_write = true,
				enable_stencil_test = false
			};

		var pipelineDesc = SDL_GPUGraphicsPipelineCreateInfo()
			{
				vertex_shader = mLitVertexShader,
				fragment_shader = mLitFragmentShader,
				vertex_input_state = vertexInputState,
				primitive_type = .SDL_GPU_PRIMITIVETYPE_TRIANGLELIST,
				rasterizer_state = rasterState,
				multisample_state = .
					{
						sample_count = .SDL_GPU_SAMPLECOUNT_1,
						sample_mask = 0,
						enable_mask = false
					},
				depth_stencil_state = depthStencilState,
				target_info = targetInfo,
				props = 0
			};

		mLitPipeline = SDL_CreateGPUGraphicsPipeline(mDevice, &pipelineDesc);

	   // Create unlit pipeline
	   // Reset to default states for unlit
		pipelineDesc.vertex_shader = mUnlitVertexShader;
		pipelineDesc.fragment_shader = mUnlitFragmentShader;
		pipelineDesc.rasterizer_state = rasterState;
		pipelineDesc.depth_stencil_state = depthStencilState;
		pipelineDesc.target_info = targetInfo;

		mUnlitPipeline = SDL_CreateGPUGraphicsPipeline(mDevice, &pipelineDesc);

	   // Create sprite pipeline
	   // Sprite pipeline uses alpha blending and no depth write
		colorTargetDesc.blend_state = SDL_GPUColorTargetBlendState()
			{
				src_color_blendfactor = .SDL_GPU_BLENDFACTOR_SRC_ALPHA,
				dst_color_blendfactor = .SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
				color_blend_op = .SDL_GPU_BLENDOP_ADD,
				src_alpha_blendfactor = .SDL_GPU_BLENDFACTOR_ONE,
				dst_alpha_blendfactor = .SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
				alpha_blend_op = .SDL_GPU_BLENDOP_ADD,
				color_write_mask = .SDL_GPU_COLORCOMPONENT_R | .SDL_GPU_COLORCOMPONENT_G |
					.SDL_GPU_COLORCOMPONENT_B | .SDL_GPU_COLORCOMPONENT_A,
				enable_blend = true,
				enable_color_write_mask = false
			};

		targetInfo.color_target_descriptions = &colorTargetDesc;

	   // Sprites test depth but don't write to it
		depthStencilState.enable_depth_write = false;

	   // No backface culling for sprites (they might be flipped)
		rasterState.cull_mode = .SDL_GPU_CULLMODE_NONE;

		pipelineDesc.vertex_shader = mSpriteVertexShader;
		pipelineDesc.fragment_shader = mSpriteFragmentShader;
		pipelineDesc.rasterizer_state = rasterState;
		pipelineDesc.depth_stencil_state = depthStencilState;
		pipelineDesc.target_info = targetInfo;

		mSpritePipeline = SDL_CreateGPUGraphicsPipeline(mDevice, &pipelineDesc);

	   // Create PBR pipeline
	   // Reset to default states for PBR
		colorTargetDesc.blend_state = blendState; // Use the original blend state
		targetInfo.color_target_descriptions = &colorTargetDesc;

		depthStencilState.enable_depth_write = true;
		depthStencilState.enable_depth_test = true;
		rasterState.cull_mode = .SDL_GPU_CULLMODE_BACK;

		pipelineDesc.vertex_shader = mPBRVertexShader;
		pipelineDesc.fragment_shader = mPBRFragmentShader;
		pipelineDesc.rasterizer_state = rasterState;
		pipelineDesc.depth_stencil_state = depthStencilState;
		pipelineDesc.target_info = targetInfo;

		mPBRPipeline = SDL_CreateGPUGraphicsPipeline(mDevice, &pipelineDesc);

	   // Create shadow map pipeline
		SDL_GPUColorTargetDescription emptyColorTarget = .();
		var shadowTargetInfo = SDL_GPUGraphicsPipelineTargetInfo()
			{
				color_target_descriptions = &emptyColorTarget,
				num_color_targets = 0, // No color output
				depth_stencil_format = .SDL_GPU_TEXTUREFORMAT_D32_FLOAT,
				has_depth_stencil_target = true
			};

	   // Shadow pipeline uses same vertex format but different shaders
		pipelineDesc.vertex_shader = mShadowVertexShader;
		pipelineDesc.fragment_shader = mShadowFragmentShader;
		pipelineDesc.rasterizer_state = rasterState;
		pipelineDesc.rasterizer_state.cull_mode = .SDL_GPU_CULLMODE_FRONT; // Front face culling for shadows
		pipelineDesc.depth_stencil_state = depthStencilState;
		pipelineDesc.target_info = shadowTargetInfo;

		mShadowPipeline = SDL_CreateGPUGraphicsPipeline(mDevice, &pipelineDesc);
	}

	private void OnUpdate(IEngine.UpdateInfo info)
	{
		// Nothing to update for now
	}

	private void OnRender(IEngine.UpdateInfo info)
	{
		for (var module in mRenderModules)
		{
			module.RenderFrame();
		}
	}

	public SDL_GPUGraphicsPipeline* GetPipeline(bool lit)
	{
		return lit ? mLitPipeline : mUnlitPipeline;
	}

	public SDL_GPUGraphicsPipeline* GetPBRPipeline()
	{
		return mPBRPipeline;
	}

	public SDL_GPUGraphicsPipeline* GetSpritePipeline()
	{
		return mSpritePipeline;
	}

	public SDL_GPUGraphicsPipeline* GetShadowPipeline()
	{
		return mShadowPipeline;
	}

	private void CompileShaderFromSource(String source, SDL_ShaderCross_ShaderStage stage,
		String entrypoint, List<uint8> byteCode)
	{
		SDL_ShaderCross_HLSL_Info hlslInfo = .()
			{
				source = source.CStr(),
				entrypoint = entrypoint.CStr(),
				shader_stage = stage,
				enable_debug = false
			};

		uint spirvByteCodeSize = 0;
		void* spirvByteCode = SDL_ShaderCross_CompileSPIRVFromHLSL(&hlslInfo, &spirvByteCodeSize);
		if (spirvByteCode == null)
		{
			Runtime.FatalError(scope $"Shader compilation failed: {StringView(SDL_GetError())}");
		}

		byteCode.AddRange(Span<uint8>((uint8*)spirvByteCode, (int)spirvByteCodeSize));
	}

	private void GetGPUShaderFormat()
	{
		SDL_GPUShaderFormat backendFormats = SDL_GetGPUShaderFormats(mDevice);
		ShaderFormat = .SDL_GPU_SHADERFORMAT_INVALID;

		if (backendFormats & .SDL_GPU_SHADERFORMAT_SPIRV != 0)
		{
			ShaderFormat = .SDL_GPU_SHADERFORMAT_SPIRV;
		} else if (backendFormats & .SDL_GPU_SHADERFORMAT_MSL != 0)
		{
			ShaderFormat = .SDL_GPU_SHADERFORMAT_MSL;
		} else if (backendFormats & .SDL_GPU_SHADERFORMAT_DXIL != 0)
		{
			ShaderFormat = .SDL_GPU_SHADERFORMAT_DXIL;
		} else
		{
			SDL_Log("%s", "Unrecognized backend shader format!");
			return;
		}
	}

	private void CreateDefaultTextures()
	{
		// Create 1x1 white texture
		{
			var whiteImage = scope Sedulous.Imaging.Image(1, 1, .RGBA8);
			whiteImage.SetPixel(0, 0, .White);
			mDefaultWhiteTexture = GPUResourceHandle<GPUTexture>(new GPUTexture("DefaultWhite", mDevice, whiteImage));
		}

		// Create 1x1 black texture
		{
			var blackImage = scope Sedulous.Imaging.Image(1, 1, .RGBA8);
			blackImage.SetPixel(0, 0, .Black);
			mDefaultBlackTexture = GPUResourceHandle<GPUTexture>(new GPUTexture("DefaultBlack", mDevice, blackImage));
		}

		// Create 1x1 default normal texture (pointing up)
		{
			var normalImage = scope Sedulous.Imaging.Image(1, 1, .RGBA8);
			normalImage.SetPixel(0, 0, Color(128, 128, 255, 255)); // Normal pointing up
			mDefaultNormalTexture = GPUResourceHandle<GPUTexture>(new GPUTexture("DefaultNormal", mDevice, normalImage));
		}

		// Create default depth sampler for unused shadow map slots
		var depthSamplerDesc = SDL_GPUSamplerCreateInfo()
			{
				min_filter = .SDL_GPU_FILTER_LINEAR,
				mag_filter = .SDL_GPU_FILTER_LINEAR,
				mipmap_mode = .SDL_GPU_SAMPLERMIPMAPMODE_NEAREST,
				address_mode_u = .SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE,
				address_mode_v = .SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE,
				address_mode_w = .SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE,
				compare_op = .SDL_GPU_COMPAREOP_LESS_OR_EQUAL,
				enable_compare = true,
				enable_anisotropy = false
			};

		mDefaultDepthSampler = SDL_CreateGPUSampler(mDevice, &depthSamplerDesc);

		// Create a 1x1 white depth texture for unused shadow map slots
		var shadowTextureDesc = SDL_GPUTextureCreateInfo()
		{
		    type = .SDL_GPU_TEXTURETYPE_2D,
		    format = .SDL_GPU_TEXTUREFORMAT_D32_FLOAT,
		    width = 1,
		    height = 1,
		    layer_count_or_depth = 1,
		    num_levels = 1,
		    sample_count = .SDL_GPU_SAMPLECOUNT_1,
		    usage = .SDL_GPU_TEXTUREUSAGE_SAMPLER, // Only for sampling, not as render target
		    props = 0
		};
		mDefaultShadowTexture = SDL_CreateGPUTexture(mDevice, &shadowTextureDesc);

		// Upload white (1.0) depth value
		var transferBuffer = SDL_CreateGPUTransferBuffer(mDevice, scope .()
		{
		    usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD,
		    size = sizeof(float)
		});

		if (transferBuffer != null)
		{
		    defer SDL_ReleaseGPUTransferBuffer(mDevice, transferBuffer);
		    
		    var data = SDL_MapGPUTransferBuffer(mDevice, transferBuffer, false);
		    if (data != null)
		    {
		        *((float*)data) = 1.0f; // Max depth
		        SDL_UnmapGPUTransferBuffer(mDevice, transferBuffer);
		        
		        var commandBuffer = SDL_AcquireGPUCommandBuffer(mDevice);
		        if (commandBuffer != null)
		        {
		            var copyPass = SDL_BeginGPUCopyPass(commandBuffer);
		            
		            var textureTransferInfo = SDL_GPUTextureTransferInfo()
		            {
		                transfer_buffer = transferBuffer,
		                offset = 0,
		                pixels_per_row = 1,
		                rows_per_layer = 1
		            };
		            
		            var textureRegion = SDL_GPUTextureRegion()
		            {
		                texture = mDefaultShadowTexture,
		                mip_level = 0,
		                layer = 0,
		                x = 0,
		                y = 0,
		                z = 0,
		                w = 1,
		                h = 1,
		                d = 1
		            };
		            
		            SDL_UploadToGPUTexture(copyPass, &textureTransferInfo, &textureRegion, false);
		            SDL_EndGPUCopyPass(copyPass);
		            SDL_SubmitGPUCommandBuffer(commandBuffer);
		        }
		    }
		}

		// Create shadow sampler
		var shadowSamplerDesc = SDL_GPUSamplerCreateInfo()
		{
		    min_filter = .SDL_GPU_FILTER_LINEAR,
		    mag_filter = .SDL_GPU_FILTER_LINEAR,
		    mipmap_mode = .SDL_GPU_SAMPLERMIPMAPMODE_NEAREST,
		    address_mode_u = .SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE,
		    address_mode_v = .SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE,
		    address_mode_w = .SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE,
		    compare_op = .SDL_GPU_COMPAREOP_LESS_OR_EQUAL,
		    enable_compare = true,
		    enable_anisotropy = false
		};

		mDefaultShadowSampler = SDL_CreateGPUSampler(mDevice, &shadowSamplerDesc);
	}

	public GPUResourceHandle<GPUTexture> GetDefaultWhiteTexture() => mDefaultWhiteTexture;
	public GPUResourceHandle<GPUTexture> GetDefaultBlackTexture() => mDefaultBlackTexture;
	public GPUResourceHandle<GPUTexture> GetDefaultNormalTexture() => mDefaultNormalTexture;
	public SDL_GPUSampler* GetDefaultDepthSampler() => mDefaultDepthSampler;
	public SDL_GPUTexture* GetDefaultShadowTexture() => mDefaultShadowTexture;
	public SDL_GPUSampler* GetDefaultShadowSampler() => mDefaultShadowSampler;
}