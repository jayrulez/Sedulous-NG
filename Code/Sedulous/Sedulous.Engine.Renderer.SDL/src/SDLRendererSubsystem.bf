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
[CRepr, Packed]
struct LitVertexUniforms
{
	public Matrix MVPMatrix; // 64 bytes (4x float4)
	public Matrix ModelMatrix; // 64 bytes (4x float4)
	public Matrix NormalMatrix; // 64 bytes (4x float4)
	// Total: 192 bytes (multiple of 16)
}

[CRepr, Packed]
struct LitFragmentUniforms
{
	public Vector4 LightDirAndIntensity; // 16 bytes - xyz = direction, w = intensity
	public Vector4 LightColorPad; // 16 bytes - xyz = color, w = padding
	public Vector4 MaterialColor; // 16 bytes - diffuse color
	public Vector4 CameraPosAndPad; // 16 bytes - xyz = position, w = padding
	public Vector4 SpecularColorShininess; // 16 bytes - xyz = specular color, w = shininess
	public Vector4 AmbientColor; // 16 bytes - ambient color
	// Total: 96 bytes (multiple of 16)
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
	private SDL_GPUGraphicsPipeline* mSpritePipeline;
	private SDL_GPUShader* mLitVertexShader;
	private SDL_GPUShader* mLitFragmentShader;
	private SDL_GPUShader* mUnlitVertexShader;
	private SDL_GPUShader* mUnlitFragmentShader;
	private SDL_GPUShader* mSpriteVertexShader;
	private SDL_GPUShader* mSpriteFragmentShader;

	// Default textures
	private GPUResourceHandle<GPUTexture> mDefaultWhiteTexture;
	private GPUResourceHandle<GPUTexture> mDefaultBlackTexture;
	private GPUResourceHandle<GPUTexture> mDefaultNormalTexture;

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

		SDL_ReleaseGPUGraphicsPipeline(mDevice, mLitPipeline);
		SDL_ReleaseGPUGraphicsPipeline(mDevice, mUnlitPipeline);
		SDL_ReleaseGPUGraphicsPipeline(mDevice, mSpritePipeline);
		SDL_ReleaseGPUShader(mDevice, mLitVertexShader);
		SDL_ReleaseGPUShader(mDevice, mLitFragmentShader);
		SDL_ReleaseGPUShader(mDevice, mUnlitVertexShader);
		SDL_ReleaseGPUShader(mDevice, mUnlitFragmentShader);
		SDL_ReleaseGPUShader(mDevice, mSpriteVertexShader);
		SDL_ReleaseGPUShader(mDevice, mSpriteFragmentShader);

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

		// Lit fragment shader - uniforms in space3, textures in space2
		String litFragmentShaderSource = """
		cbuffer UniformBlock : register(b0, space3)
		{
		    float4 LightDirAndIntensity;  // xyz = direction, w = intensity
		    float4 LightColorPad;         // xyz = color, w = padding
		    float4 MaterialColor;         // diffuse color
		    float4 CameraPosAndPad;       // xyz = position, w = padding
		    float4 SpecularColorShininess; // xyz = specular color, w = shininess
		    float4 AmbientColor;          // ambient color
		};
		
		Texture2D DiffuseTexture : register(t0, space2);
		SamplerState DiffuseSampler : register(s0, space2);
		
		struct PSInput
		{
		    float4 Position : SV_Position;
		    float2 TexCoord : TEXCOORD0;
		    float4 Color : TEXCOORD1;
		    float3 Normal : TEXCOORD2;
		    float3 WorldPos : TEXCOORD3;
		};
		
		float4 main(PSInput input) : SV_Target
		{
		    // Extract light parameters
		    float3 lightDir = normalize(LightDirAndIntensity.xyz);
		    float lightIntensity = LightDirAndIntensity.w;
		    float3 lightColor = LightColorPad.xyz;
		    
		    // Extract material parameters
		    float3 cameraPos = CameraPosAndPad.xyz;
		    float3 specularColor = SpecularColorShininess.xyz;
		    float shininess = SpecularColorShininess.w;
		    
		    // Sample diffuse texture
		    float4 diffuseTexColor = DiffuseTexture.Sample(DiffuseSampler, input.TexCoord);
		    
		    // Normalize the normal
		    float3 normal = normalize(input.Normal);
		    
		    // Calculate diffuse lighting
		    float NdotL = max(dot(normal, -lightDir), 0.0);
		    float3 diffuse = NdotL * lightColor * lightIntensity;
		    
		    // Calculate view direction and specular
		    float3 viewDir = normalize(cameraPos - input.WorldPos);
		    float3 halfVector = normalize(viewDir - lightDir);
		    float NdotH = max(dot(normal, halfVector), 0.0);
		    float specularIntensity = pow(NdotH, shininess);
		    float3 specular = specularIntensity * specularColor * lightColor * lightIntensity;
		    
		    // Combine lighting with material color and texture
		    float3 materialColor = MaterialColor.rgb * input.Color.rgb * diffuseTexColor.rgb;
		    float3 finalColor = AmbientColor.rgb * materialColor + diffuse * materialColor + specular;
		    
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

		// Compile all shaders
		var litVsCode = scope List<uint8>();
		var litPsCode = scope List<uint8>();
		var unlitVsCode = scope List<uint8>();
		var unlitPsCode = scope List<uint8>();
		var spriteVsCode = scope List<uint8>();
		var spritePsCode = scope List<uint8>();

		CompileShaderFromSource(litVertexShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_VERTEX, "main", litVsCode);
		CompileShaderFromSource(litFragmentShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT, "main", litPsCode);
		CompileShaderFromSource(unlitVertexShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_VERTEX, "main", unlitVsCode);
		CompileShaderFromSource(unlitFragmentShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT, "main", unlitPsCode);
		CompileShaderFromSource(spriteVertexShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_VERTEX, "main", spriteVsCode);
		CompileShaderFromSource(spriteFragmentShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT, "main", spritePsCode);

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

		var litPsDesc = SDL_GPUShaderCreateInfo()
			{
				code = litPsCode.Ptr,
				code_size = (uint32)litPsCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_FRAGMENT,
				num_samplers = 1, // We have 1 texture sampler
				num_uniform_buffers = 1, // We have 1 uniform buffer
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
			num_uniform_buffers = 1,  // We have 1 uniform buffer
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
			num_samplers = 1,  // We have 1 texture sampler
			num_uniform_buffers = 1,  // We have 1 uniform buffer
			num_storage_buffers = 0,
			num_storage_textures = 0
		};
		mUnlitFragmentShader = SDL_CreateGPUShader(mDevice, &unlitPsDesc);

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

	public SDL_GPUGraphicsPipeline* GetSpritePipeline()
	{
		return mSpritePipeline;
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
	}

	public GPUResourceHandle<GPUTexture> GetDefaultWhiteTexture() => mDefaultWhiteTexture;
	public GPUResourceHandle<GPUTexture> GetDefaultBlackTexture() => mDefaultBlackTexture;
	public GPUResourceHandle<GPUTexture> GetDefaultNormalTexture() => mDefaultNormalTexture;
}