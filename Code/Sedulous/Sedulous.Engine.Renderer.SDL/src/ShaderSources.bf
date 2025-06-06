using System;
namespace Sedulous.Engine.Renderer.SDL;

class ShaderSources
{
	// SDL GPU binding model for DXIL/DXBC:
		// Vertex shaders: uniforms in space1
		// Fragment shaders: uniforms in space3
	// see https://wiki.libsdl.org/SDL3/SDL_CreateGPUShader
	
	// Lit vertex shader - uniforms in space1
	public const String LitVertex = """
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
	public const String LitFragment = """
		static const int MAX_LIGHTS = 16;
		
		struct LightData
		{
		    float4 PositionType;     // xyz = position, w = type (0=dir, 1=point, 2=spot)
		    float4 DirectionRange;   // xyz = direction, w = range
		    float4 ColorIntensity;   // xyz = color, w = intensity
		    float4 SpotAngles;       // x = inner angle cos, y = outer angle cos, z = constant atten, w = linear atten
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
		Texture2D NormalTexture : register(t1, space2);
		SamplerState NormalSampler : register(s1, space2);
		
		struct PSInput
		{
		    float4 Position : SV_Position;
		    float2 TexCoord : TEXCOORD0;
		    float4 Color : TEXCOORD1;
		    float3 Normal : TEXCOORD2;
		    float3 WorldPos : TEXCOORD3;
		};
		
		// Calculate TBN matrix for normal mapping
		float3x3 CalculateTBN(float3 normal, float3 worldPos, float2 texCoord)
		{
		    // Calculate derivatives of world position with respect to UV
		    float3 dp1 = ddx(worldPos);
		    float3 dp2 = ddy(worldPos);
		    float2 duv1 = ddx(texCoord);
		    float2 duv2 = ddy(texCoord);
		    
		    // Calculate tangent and bitangent
		    float3 tangent = normalize(duv2.y * dp1 - duv1.y * dp2);
		    float3 bitangent = normalize(duv1.x * dp2 - duv2.x * dp1);
		    
		    // Ensure orthogonality
		    tangent = normalize(tangent - dot(tangent, normal) * normal);
		    bitangent = cross(normal, tangent);
		    
		    return float3x3(tangent, bitangent, normal);
		}
		
		// Unpack normal from normal map
		float3 UnpackNormal(float3 normalMapSample)
		{
		    // Convert from [0,1] to [-1,1]
		    float3 normal;
		    normal.xy = normalMapSample.xy * 2.0 - 1.0;
		    normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
		    return normalize(normal);
		}
		
		float3 CalculateDirectionalLight(LightData light, float3 normal, float3 viewDir, float3 materialColor, float3 specularColor, float shininess)
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
		    
		    return diffuse * materialColor + specular;
		}
		
		float3 CalculatePointLight(LightData light, float3 normal, float3 worldPos, float3 viewDir, float3 materialColor, float3 specularColor, float shininess)
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
		
		float3 CalculateSpotLight(LightData light, float3 normal, float3 worldPos, float3 viewDir, float3 materialColor, float3 specularColor, float shininess)
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
		    
		    return diffuse * materialColor + specular;
		}
		
		float4 main(PSInput input) : SV_Target
		{
		    // Sample diffuse texture
		    float4 diffuseTexColor = DiffuseTexture.Sample(DiffuseSampler, input.TexCoord);
		    
		    // Get base normal
		    float3 normal = normalize(input.Normal);
		    
		    // Apply normal mapping
		    float3 normalMapSample = NormalTexture.Sample(NormalSampler, input.TexCoord).rgb;
		    
		    // Check if we have a valid normal map (not the default normal color)
		    // Default normal map color is (0.5, 0.5, 1.0) which is (128, 128, 255) in RGB
		    if (length(normalMapSample - float3(0.5, 0.5, 1.0)) > 0.01)
		    {
		        // Unpack the normal from tangent space
		        float3 tangentNormal = UnpackNormal(normalMapSample);
		        
		        // Calculate TBN matrix
		        float3x3 TBN = CalculateTBN(normal, input.WorldPos, input.TexCoord);
		        
		        // Transform normal from tangent space to world space
		        normal = normalize(mul(tangentNormal, TBN));
		    }
		    
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
		            finalColor += CalculateDirectionalLight(Lights[i], normal, viewDir, materialColor, specularColor, shininess);
		        }
		        else if (lightType < 1.5) // Point light
		        {
		            finalColor += CalculatePointLight(Lights[i], normal, input.WorldPos, viewDir, materialColor, specularColor, shininess);
		        }
		        else // Spot light
		        {
		            finalColor += CalculateSpotLight(Lights[i], normal, input.WorldPos, viewDir, materialColor, specularColor, shininess);
		        }
		    }
		    
		    return float4(finalColor, MaterialColor.a * input.Color.a * diffuseTexColor.a);
		}
		""";
	
	// Unlit vertex shader - uniforms in space1
	public const String UnlitVertex = """
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
	public const String UnlitFragment = """
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
	public const String PBRVertex = """
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
	
	// PBR fragment shader - physically based rendering
	public const String PBRFragment = """
			static const int MAX_LIGHTS = 16;
			static const float PI = 3.14159265359;
			
			struct LightData
			{
			    float4 PositionType;     // xyz = position, w = type (0=dir, 1=point, 2=spot)
			    float4 DirectionRange;   // xyz = direction, w = range
			    float4 ColorIntensity;   // xyz = color, w = intensity
			    float4 SpotAngles;       // x = inner angle cos, y = outer angle cos, z = constant atten, w = linear atten
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
			
			// Calculate TBN matrix for normal mapping
			float3x3 CalculateTBN(float3 normal, float3 worldPos, float2 texCoord)
			{
			    // Calculate derivatives of world position with respect to UV
			    float3 dp1 = ddx(worldPos);
			    float3 dp2 = ddy(worldPos);
			    float2 duv1 = ddx(texCoord);
			    float2 duv2 = ddy(texCoord);
			    
			    // Calculate tangent and bitangent
			    float3 tangent = normalize(duv2.y * dp1 - duv1.y * dp2);
			    float3 bitangent = normalize(duv1.x * dp2 - duv2.x * dp1);
			    
			    // Ensure orthogonality
			    tangent = normalize(tangent - dot(tangent, normal) * normal);
			    bitangent = cross(normal, tangent);
			    
			    return float3x3(tangent, bitangent, normal);
			}
			
			// Unpack normal from normal map
			float3 UnpackNormal(float3 normalMapSample)
			{
			    // Convert from [0,1] to [-1,1]
			    float3 normal;
			    normal.xy = normalMapSample.xy * 2.0 - 1.0;
			    normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
			    return normalize(normal);
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
			    
			    // Get base normal
			    float3 normal = normalize(input.Normal);
			    
			    // Apply normal mapping
			    float3 normalMapSample = NormalTexture.Sample(NormalSampler, input.TexCoord).rgb;
			    
			    // Check if we have a valid normal map (not the default normal color)
			    // Default normal map color is (0.5, 0.5, 1.0) which is (128, 128, 255) in RGB
			    if (length(normalMapSample - float3(0.5, 0.5, 1.0)) > 0.01)
			    {
			        // Unpack the normal from tangent space
			        float3 tangentNormal = UnpackNormal(normalMapSample);
			        
			        // Calculate TBN matrix
			        float3x3 TBN = CalculateTBN(normal, input.WorldPos, input.TexCoord);
			        
			        // Transform normal from tangent space to world space
			        normal = normalize(mul(tangentNormal, TBN));
			    }
			    
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
			        
			        if (lightType < 0.5) // Directional light
			        {
			            L = normalize(-Lights[i].DirectionRange.xyz);
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
			        }
			        
			        Lo += CalculatePBRLight(L, V, normal, albedo, metallic, roughness, lightColor, attenuation);
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
	public const String SpriteVertex = """
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
	public const String SpriteFragment = """
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
}