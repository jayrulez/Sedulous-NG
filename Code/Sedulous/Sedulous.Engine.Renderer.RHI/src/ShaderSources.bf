using System;
using Sedulous.Mathematics;
namespace Sedulous.Engine.Renderer.RHI;

[CRepr, Packed]
struct UnlitVertexUniforms
{
	public Matrix MVPMatrix; // 64 bytes (4x float4)
	public Matrix ModelMatrix; // 64 bytes (4x float4)
	// Total: 128 bytes (multiple of 16)
}

[CRepr, Packed, Align(16)]
struct UnlitFragmentUniforms
{
    public Vector4 MaterialTint;
    public Vector4 MaterialProperties; // metallic, roughness, emissive, unused
}

[CRepr, Packed, Align(16)]
struct PhongFragmentUniforms
{
    public Vector4 DiffuseColor;    // w = unused
    public Vector4 SpecularColor;   // w = shininess
    public Vector4 AmbientColor;    // w = unused
    public Vector4 Padding;         // Reserved for future use
}

[CRepr, Packed, Align(16)]
struct LightingUniforms
{
    public Vector4 DirectionalLightDir;   // xyz = direction (normalized), w = unused
    public Vector4 DirectionalLightColor; // xyz = color, w = intensity
    public Vector4 AmbientLight;          // xyz = ambient color, w = unused
    public Vector4 CameraPosition;        // xyz = camera world position, w = unused
}

[CRepr, Packed, Align(16)]
struct PBRFragmentUniforms
{
    public Vector4 AlbedoColor;      // xyz = albedo, w = alpha
    public Vector4 EmissiveColor;    // xyz = emissive, w = intensity
    public float Metallic;
    public float Roughness;
    public float AmbientOcclusion;
    public float Padding;
}

[CRepr, Packed, Align(16)]
struct DebugLineVertex
{
    public Vector3 Position;
    public Color Color;
}

[CRepr, Packed, Align(16)]
struct DebugUniforms
{
    public Matrix ViewProjection;
}

[CRepr, Packed, Align(16)]
struct HiZParams
{
    public uint32 OutputSizeX;
    public uint32 OutputSizeY;
    public uint32 InputSizeX;
    public uint32 InputSizeY;
}

// ============================================
// GPU-Driven Culling Structures
// ============================================

/// Per-object data for GPU culling (96 bytes)
/// Uploaded each frame for all potentially visible objects
[CRepr, Packed, Align(16)]
struct GPUObjectData
{
    public Matrix WorldMatrix;     // 64 bytes
    public Vector4 BoundsMin;      // 16 bytes (xyz = min, w = meshIndex as float)
    public Vector4 BoundsMax;      // 16 bytes (xyz = max, w = materialIndex as float)
}

/// Per-mesh info for indirect draw (16 bytes)
/// Static data, updated only when meshes are loaded/unloaded
[CRepr, Packed, Align(16)]
struct GPUMeshInfo
{
    public uint32 IndexCount;
    public uint32 FirstIndex;
    public int32 BaseVertex;
    public uint32 Padding;
}

/// Culling uniforms passed to GPU culling compute shader
[CRepr, Packed, Align(16)]
struct GPUCullingUniforms
{
    public Matrix ViewProjection;
    public Vector4[6] FrustumPlanes;  // 6 frustum planes (xyz = normal, w = distance)
    public uint32 ObjectCount;
    public uint32 HiZWidth;
    public uint32 HiZHeight;
    public uint32 Padding;
}

/// Frame-level uniforms for instanced rendering (used with GPU-driven culling)
[CRepr, Packed, Align(16)]
struct InstancedFrameUniforms
{
    public Matrix ViewProjection;
}

// ============================================
// Sprite Rendering Structures
// ============================================

/// Sprite vertex (simple unit quad vertex) - 12 bytes
[CRepr, Packed]
struct SpriteVertex
{
    public Vector3 Position;   // 12 bytes (unit quad: 0-1 range)
}

/// Sprite per-object uniforms (includes all sprite parameters)
[CRepr, Packed, Align(16)]
struct SpriteVertexUniforms
{
    public Matrix MVPMatrix;   // 64 bytes
    public Vector4 SpriteParams;  // xy = size, zw = pivot (16 bytes)
    public Vector4 UVBounds;      // xy = uvMin, zw = uvMax (16 bytes)
    public Vector4 TintColor;     // rgba tint color (16 bytes)
    // Total: 112 bytes, aligned to 16
}

/// Sprite material uniforms (just for texture binding, color moved to vertex uniforms)
[CRepr, Packed, Align(16)]
struct SpriteFragmentUniforms
{
    public Vector4 Padding;  // 16 bytes (unused, kept for resource layout compatibility)
}

// ============================================
// Picking Structures
// ============================================

/// Picking uniform buffer - contains MVP matrix and entity ID
[CRepr, Packed, Align(16)]
struct PickingUniforms
{
    public Matrix MVPMatrix;     // 64 bytes
    public uint32 EntityId;      // 4 bytes (truncated from uint64, sufficient for < 4 billion entities)
    public uint32 Padding0;      // 4 bytes
    public uint32 Padding1;      // 4 bytes
    public uint32 Padding2;      // 4 bytes
    // Total: 80 bytes (aligned to 16)
}

static
{
	public const int MAX_BONES = 128;
}

[CRepr, Packed]
struct BoneMatricesUniforms
{
	public Matrix[MAX_BONES] Bones;
}

static class ShaderSources
{
	public const String UnlitShadersVS = """
	    // Constant buffers
	    cbuffer UniformBlock : register(b0)
	    {
	        float4x4 MVPMatrix;
	        float4x4 ModelMatrix;
	    }
	    // Vertex input structure
	    struct VSInput
	    {
	        float3 Position : POSITION;
	        float3 Normal : NORMAL;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR; // converted automatically
	        float3 Tangent : TANGENT; 
	    };
	    // Vertex output structure
	    struct VSOutput
	    {
	        float4 Position : SV_POSITION;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
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
	    VSOutput VS(VSInput input)
	    {
	    	VSOutput output;
	    	output.Position = mul(float4(input.Position, 1.0), MVPMatrix);
	    	output.TexCoord = input.TexCoord;
	    	output.Color = input.Color;//UnpackColor(input.Color);
	    	return output;
	    }
	    """;

	public const String UnlitShadersPS = """
	    cbuffer MaterialBlock : register(b0, space1)  // Material properties
	    {
	        float4 MaterialTint;
	        float4 MaterialProperties; // x=metallic, y=roughness, z=emissive, w=unused
	    }

	    Texture2D DiffuseTexture : register(t0, space1);
	    SamplerState LinearSampler : register(s0, space1);
	    struct PSInput
	    {
	        float4 Position : SV_POSITION;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	    };
	    float4 PS(PSInput input) : SV_TARGET
	    {
	        // Sample texture
	        float4 texColor = DiffuseTexture.Sample(LinearSampler, input.TexCoord);

	        //return input.Color;
	        // Combine vertex color, texture, and material tint
	        //return input.Color * MaterialTint;
	        return texColor * input.Color * MaterialTint;
	        //return MaterialTint;
	        //return float4(input.TexCoord.x, input.TexCoord.y, 0.0, 1.0);
	        //uint2 texSize;
	        //DiffuseTexture.GetDimensions(texSize.x, texSize.y);
	        //return float4(1.0, 0.0, 0.0, 1.0);

	        //texColor = DiffuseTexture.Sample(LinearSampler, float2(0.5, 0.5));
	        //return texColor;
	        // Clamp UVs to valid range and show if they were out of bounds
	        //float2 uv = clamp(input.TexCoord, 0.0, 1.0);
	        //float4 texColor = DiffuseTexture.Sample(LinearSampler, uv);

	        // Add red if UVs were out of range
	        //if (any(input.TexCoord != uv))
	        //    return float4(1.0, 0.0, 0.0, 1.0); // Red = bad UVs

	        //return texColor;
	    }
	    """;

	// ============================================
	// Phong Shaders (basic lighting)
	// ============================================

	public const String PhongShadersVS = """
	    cbuffer UniformBlock : register(b0)
	    {
	        float4x4 MVPMatrix;
	        float4x4 ModelMatrix;
	    }

	    struct VSInput
	    {
	        float3 Position : POSITION;
	        float3 Normal : NORMAL;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	        float3 Tangent : TANGENT;
	    };

	    struct VSOutput
	    {
	        float4 Position : SV_POSITION;
	        float3 WorldPos : TEXCOORD0;
	        float3 WorldNormal : TEXCOORD1;
	        float2 TexCoord : TEXCOORD2;
	        float4 Color : COLOR;
	    };

	    VSOutput VS(VSInput input)
	    {
	        VSOutput output;
	        output.Position = mul(float4(input.Position, 1.0), MVPMatrix);
	        output.WorldPos = mul(float4(input.Position, 1.0), ModelMatrix).xyz;
	        output.WorldNormal = normalize(mul(float4(input.Normal, 0.0), ModelMatrix).xyz);
	        output.TexCoord = input.TexCoord;
	        output.Color = input.Color;
	        return output;
	    }
	    """;

	public const String PhongShadersPS = """
	    cbuffer MaterialBlock : register(b0, space1)
	    {
	        float4 DiffuseColor;    // w = unused
	        float4 SpecularColor;   // w = shininess
	        float4 AmbientColor;    // w = unused (material ambient tint)
	        float4 Padding;         // Reserved
	    }

	    cbuffer LightingBlock : register(b0, space2)
	    {
	        float4 DirectionalLightDir;   // xyz = direction (normalized), w = unused
	        float4 DirectionalLightColor; // xyz = color, w = intensity
	        float4 SceneAmbientLight;     // xyz = ambient color, w = unused
	        float4 CameraPosition;        // xyz = camera world position, w = unused
	    }

	    Texture2D DiffuseTexture : register(t0, space1);
	    SamplerState LinearSampler : register(s0, space1);

	    struct PSInput
	    {
	        float4 Position : SV_POSITION;
	        float3 WorldPos : TEXCOORD0;
	        float3 WorldNormal : TEXCOORD1;
	        float2 TexCoord : TEXCOORD2;
	        float4 Color : COLOR;
	    };

	    float4 PS(PSInput input) : SV_TARGET
	    {
	        // Sample diffuse texture
	        float4 texColor = DiffuseTexture.Sample(LinearSampler, input.TexCoord);

	        // Normalize inputs
	        float3 N = normalize(input.WorldNormal);
	        float3 L = normalize(-DirectionalLightDir.xyz);
	        float3 V = normalize(CameraPosition.xyz - input.WorldPos);

	        // Ambient (scene ambient * material ambient tint)
	        float3 ambient = SceneAmbientLight.rgb * AmbientColor.rgb * DiffuseColor.rgb;

	        // Diffuse (Lambert)
	        float NdotL = max(dot(N, L), 0.0);
	        float lightIntensity = DirectionalLightColor.w;
	        float3 diffuse = DiffuseColor.rgb * DirectionalLightColor.rgb * NdotL * lightIntensity;

	        // Specular (Blinn-Phong)
	        float3 H = normalize(L + V);
	        float NdotH = max(dot(N, H), 0.0);
	        float shininess = SpecularColor.w;
	        float specPower = pow(NdotH, shininess);
	        float3 specular = SpecularColor.rgb * DirectionalLightColor.rgb * specPower * lightIntensity;

	        // Combine
	        float3 finalColor = (ambient + diffuse) * texColor.rgb * input.Color.rgb + specular;

	        return float4(finalColor, texColor.a * input.Color.a * DiffuseColor.a);
	    }
	    """;

	// ============================================
	// PBR Shaders (Physically-Based Rendering)
	// ============================================

	// PBR uses same vertex shader as Phong (outputs world pos, normal, tangent)
	public const String PBRShadersVS = """
	    cbuffer UniformBlock : register(b0)
	    {
	        float4x4 MVPMatrix;
	        float4x4 ModelMatrix;
	    }

	    struct VSInput
	    {
	        float3 Position : POSITION;
	        float3 Normal : NORMAL;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	        float3 Tangent : TANGENT;
	    };

	    struct VSOutput
	    {
	        float4 Position : SV_POSITION;
	        float3 WorldPos : TEXCOORD0;
	        float3 WorldNormal : TEXCOORD1;
	        float2 TexCoord : TEXCOORD2;
	        float4 Color : COLOR;
	        float3 WorldTangent : TEXCOORD3;
	    };

	    VSOutput VS(VSInput input)
	    {
	        VSOutput output;
	        output.Position = mul(float4(input.Position, 1.0), MVPMatrix);
	        output.WorldPos = mul(float4(input.Position, 1.0), ModelMatrix).xyz;
	        output.WorldNormal = normalize(mul(float4(input.Normal, 0.0), ModelMatrix).xyz);
	        output.WorldTangent = normalize(mul(float4(input.Tangent, 0.0), ModelMatrix).xyz);
	        output.TexCoord = input.TexCoord;
	        output.Color = input.Color;
	        return output;
	    }
	    """;

	public const String PBRShadersPS = """
	    static const float PI = 3.14159265359;

	    cbuffer MaterialBlock : register(b0, space1)
	    {
	        float4 AlbedoColor;      // xyz = albedo, w = alpha
	        float4 EmissiveColor;    // xyz = emissive, w = intensity
	        float Metallic;
	        float Roughness;
	        float AmbientOcclusion;
	        float Padding;
	    }

	    cbuffer LightingBlock : register(b0, space2)
	    {
	        float4 DirectionalLightDir;   // xyz = direction (normalized), w = unused
	        float4 DirectionalLightColor; // xyz = color, w = intensity
	        float4 SceneAmbientLight;     // xyz = ambient color, w = unused
	        float4 CameraPosition;        // xyz = camera world position, w = unused
	    }

	    Texture2D AlbedoTexture : register(t0, space1);
	    Texture2D NormalTexture : register(t1, space1);
	    Texture2D MetallicRoughnessTexture : register(t2, space1);
	    Texture2D AOTexture : register(t3, space1);
	    Texture2D EmissiveTexture : register(t4, space1);
	    SamplerState LinearSampler : register(s0, space1);

	    struct PSInput
	    {
	        float4 Position : SV_POSITION;
	        float3 WorldPos : TEXCOORD0;
	        float3 WorldNormal : TEXCOORD1;
	        float2 TexCoord : TEXCOORD2;
	        float4 Color : COLOR;
	        float3 WorldTangent : TEXCOORD3;
	    };

	    // GGX/Trowbridge-Reitz normal distribution function
	    float DistributionGGX(float3 N, float3 H, float roughness)
	    {
	        float a = roughness * roughness;
	        float a2 = a * a;
	        float NdotH = max(dot(N, H), 0.0);
	        float NdotH2 = NdotH * NdotH;

	        float denom = (NdotH2 * (a2 - 1.0) + 1.0);
	        denom = PI * denom * denom;

	        return a2 / max(denom, 0.0001);
	    }

	    // Schlick-GGX geometry function
	    float GeometrySchlickGGX(float NdotV, float roughness)
	    {
	        float r = roughness + 1.0;
	        float k = (r * r) / 8.0;
	        return NdotV / (NdotV * (1.0 - k) + k);
	    }

	    // Smith's geometry function
	    float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
	    {
	        float NdotV = max(dot(N, V), 0.0);
	        float NdotL = max(dot(N, L), 0.0);
	        float ggx1 = GeometrySchlickGGX(NdotV, roughness);
	        float ggx2 = GeometrySchlickGGX(NdotL, roughness);
	        return ggx1 * ggx2;
	    }

	    // Fresnel-Schlick approximation
	    float3 FresnelSchlick(float cosTheta, float3 F0)
	    {
	        return F0 + (1.0 - F0) * pow(saturate(1.0 - cosTheta), 5.0);
	    }

	    float4 PS(PSInput input) : SV_TARGET
	    {
	        // Sample textures
	        float4 albedoTex = AlbedoTexture.Sample(LinearSampler, input.TexCoord);
	        float4 mrTex = MetallicRoughnessTexture.Sample(LinearSampler, input.TexCoord);
	        float aoTex = AOTexture.Sample(LinearSampler, input.TexCoord).r;
	        float4 emissiveTex = EmissiveTexture.Sample(LinearSampler, input.TexCoord);

	        // Combine material properties with textures
	        float3 albedo = AlbedoColor.rgb * albedoTex.rgb * input.Color.rgb;
	        float metallic = Metallic * mrTex.b;     // Blue channel = metallic
	        float roughness = Roughness * mrTex.g;   // Green channel = roughness
	        roughness = max(roughness, 0.04);        // Prevent divide by zero
	        float ao = AmbientOcclusion * aoTex;

	        // Normal (use vertex normal for now, normal mapping can be added later)
	        float3 N = normalize(input.WorldNormal);
	        float3 V = normalize(CameraPosition.xyz - input.WorldPos);
	        float3 L = normalize(-DirectionalLightDir.xyz);
	        float3 H = normalize(V + L);

	        // Calculate reflectance at normal incidence (F0)
	        // Dielectrics use 0.04, metals use albedo color
	        float3 F0 = lerp(float3(0.04, 0.04, 0.04), albedo, metallic);

	        // Cook-Torrance BRDF
	        float NDF = DistributionGGX(N, H, roughness);
	        float G = GeometrySmith(N, V, L, roughness);
	        float3 F = FresnelSchlick(max(dot(H, V), 0.0), F0);

	        // Specular contribution
	        float3 numerator = NDF * G * F;
	        float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001;
	        float3 specular = numerator / denominator;

	        // Energy conservation: diffuse and specular can't exceed 1.0
	        float3 kS = F;  // Specular contribution
	        float3 kD = (1.0 - kS) * (1.0 - metallic);  // Diffuse (metals have no diffuse)

	        // Outgoing radiance
	        float NdotL = max(dot(N, L), 0.0);
	        float lightIntensity = DirectionalLightColor.w;
	        float3 radiance = DirectionalLightColor.rgb * lightIntensity;

	        // Direct lighting
	        float3 Lo = (kD * albedo / PI + specular) * radiance * NdotL;

	        // Ambient lighting (simple approximation)
	        float3 ambient = SceneAmbientLight.rgb * albedo * ao;

	        // Emissive
	        float3 emissive = EmissiveColor.rgb * EmissiveColor.w * emissiveTex.rgb;

	        // Final color
	        float3 color = ambient + Lo + emissive;

	        // HDR tone mapping (Reinhard)
	        color = color / (color + 1.0);

	        // Gamma correction
	        color = pow(color, float3(1.0/2.2, 1.0/2.2, 1.0/2.2));

	        return float4(color, AlbedoColor.a * albedoTex.a * input.Color.a);
	    }
	    """;

	// ============================================
	// Skinned PBR Shaders
	// ============================================

	public const String SkinnedPBRShadersVS = """
	    #define MAX_BONES 128

	    cbuffer UniformBlock : register(b0, space0)
	    {
	        float4x4 MVPMatrix;
	        float4x4 ModelMatrix;
	    }

	    cbuffer BoneMatrices : register(b0, space2)
	    {
	        float4x4 Bones[MAX_BONES];
	    }

	    struct VSInput
	    {
	        float3 Position : POSITION;
	        float3 Normal : NORMAL;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	        float3 Tangent : TANGENT;
	        uint4 Joints : BLENDINDICES;
	        float4 Weights : BLENDWEIGHT;
	    };

	    struct VSOutput
	    {
	        float4 Position : SV_POSITION;
	        float3 WorldPos : TEXCOORD0;
	        float3 WorldNormal : TEXCOORD1;
	        float2 TexCoord : TEXCOORD2;
	        float4 Color : COLOR;
	        float3 WorldTangent : TEXCOORD3;
	    };

	    VSOutput VS(VSInput input)
	    {
	        VSOutput output;

	        // Compute skinned position and normal
	        float4x4 skinMatrix =
	            Bones[input.Joints.x] * input.Weights.x +
	            Bones[input.Joints.y] * input.Weights.y +
	            Bones[input.Joints.z] * input.Weights.z +
	            Bones[input.Joints.w] * input.Weights.w;

	        float4 skinnedPos = mul(float4(input.Position, 1.0), skinMatrix);
	        float3 skinnedNormal = mul(float4(input.Normal, 0.0), skinMatrix).xyz;
	        float3 skinnedTangent = mul(float4(input.Tangent, 0.0), skinMatrix).xyz;

	        output.Position = mul(skinnedPos, MVPMatrix);
	        output.WorldPos = mul(skinnedPos, ModelMatrix).xyz;
	        output.WorldNormal = normalize(mul(float4(skinnedNormal, 0.0), ModelMatrix).xyz);
	        output.WorldTangent = normalize(mul(float4(skinnedTangent, 0.0), ModelMatrix).xyz);
	        output.TexCoord = input.TexCoord;
	        output.Color = input.Color;
	        return output;
	    }
	    """;

	// Skinned PBR pixel shader (lighting in space3 since space2 is bones)
	public const String SkinnedPBRShadersPS = """
	    static const float PI = 3.14159265359;

	    cbuffer MaterialBlock : register(b0, space1)
	    {
	        float4 AlbedoColor;      // xyz = albedo, w = alpha
	        float4 EmissiveColor;    // xyz = emissive, w = intensity
	        float Metallic;
	        float Roughness;
	        float AmbientOcclusion;
	        float Padding;
	    }

	    cbuffer LightingBlock : register(b0, space3)
	    {
	        float4 DirectionalLightDir;   // xyz = direction (normalized), w = unused
	        float4 DirectionalLightColor; // xyz = color, w = intensity
	        float4 SceneAmbientLight;     // xyz = ambient color, w = unused
	        float4 CameraPosition;        // xyz = camera world position, w = unused
	    }

	    Texture2D AlbedoTexture : register(t0, space1);
	    Texture2D NormalTexture : register(t1, space1);
	    Texture2D MetallicRoughnessTexture : register(t2, space1);
	    Texture2D AOTexture : register(t3, space1);
	    Texture2D EmissiveTexture : register(t4, space1);
	    SamplerState LinearSampler : register(s0, space1);

	    struct PSInput
	    {
	        float4 Position : SV_POSITION;
	        float3 WorldPos : TEXCOORD0;
	        float3 WorldNormal : TEXCOORD1;
	        float2 TexCoord : TEXCOORD2;
	        float4 Color : COLOR;
	        float3 WorldTangent : TEXCOORD3;
	    };

	    float DistributionGGX(float3 N, float3 H, float roughness)
	    {
	        float a = roughness * roughness;
	        float a2 = a * a;
	        float NdotH = max(dot(N, H), 0.0);
	        float NdotH2 = NdotH * NdotH;
	        float denom = (NdotH2 * (a2 - 1.0) + 1.0);
	        denom = PI * denom * denom;
	        return a2 / max(denom, 0.0001);
	    }

	    float GeometrySchlickGGX(float NdotV, float roughness)
	    {
	        float r = roughness + 1.0;
	        float k = (r * r) / 8.0;
	        return NdotV / (NdotV * (1.0 - k) + k);
	    }

	    float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
	    {
	        float NdotV = max(dot(N, V), 0.0);
	        float NdotL = max(dot(N, L), 0.0);
	        return GeometrySchlickGGX(NdotV, roughness) * GeometrySchlickGGX(NdotL, roughness);
	    }

	    float3 FresnelSchlick(float cosTheta, float3 F0)
	    {
	        return F0 + (1.0 - F0) * pow(saturate(1.0 - cosTheta), 5.0);
	    }

	    float4 PS(PSInput input) : SV_TARGET
	    {
	        float4 albedoTex = AlbedoTexture.Sample(LinearSampler, input.TexCoord);
	        float4 mrTex = MetallicRoughnessTexture.Sample(LinearSampler, input.TexCoord);
	        float aoTex = AOTexture.Sample(LinearSampler, input.TexCoord).r;
	        float4 emissiveTex = EmissiveTexture.Sample(LinearSampler, input.TexCoord);

	        float3 albedo = AlbedoColor.rgb * albedoTex.rgb * input.Color.rgb;
	        float metallic = Metallic * mrTex.b;
	        float roughness = max(Roughness * mrTex.g, 0.04);
	        float ao = AmbientOcclusion * aoTex;

	        float3 N = normalize(input.WorldNormal);
	        float3 V = normalize(CameraPosition.xyz - input.WorldPos);
	        float3 L = normalize(-DirectionalLightDir.xyz);
	        float3 H = normalize(V + L);

	        float3 F0 = lerp(float3(0.04, 0.04, 0.04), albedo, metallic);

	        float NDF = DistributionGGX(N, H, roughness);
	        float G = GeometrySmith(N, V, L, roughness);
	        float3 F = FresnelSchlick(max(dot(H, V), 0.0), F0);

	        float3 numerator = NDF * G * F;
	        float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001;
	        float3 specular = numerator / denominator;

	        float3 kS = F;
	        float3 kD = (1.0 - kS) * (1.0 - metallic);

	        float NdotL = max(dot(N, L), 0.0);
	        float lightIntensity = DirectionalLightColor.w;
	        float3 radiance = DirectionalLightColor.rgb * lightIntensity;

	        float3 Lo = (kD * albedo / PI + specular) * radiance * NdotL;
	        float3 ambient = SceneAmbientLight.rgb * albedo * ao;
	        float3 emissive = EmissiveColor.rgb * EmissiveColor.w * emissiveTex.rgb;

	        float3 color = ambient + Lo + emissive;
	        color = color / (color + 1.0);
	        color = pow(color, float3(1.0/2.2, 1.0/2.2, 1.0/2.2));

	        return float4(color, AlbedoColor.a * albedoTex.a * input.Color.a);
	    }
	    """;

	// ============================================
	// Skinned Shaders
	// ============================================

	public const String SkinnedUnlitShadersVS = """
	    #define MAX_BONES 128

	    // Constant buffers - using register spaces to map to Vulkan descriptor sets
	    // space0 -> Set 0 (per-object uniforms)
	    // space2 -> Set 2 (bone matrices)
	    cbuffer UniformBlock : register(b0, space0)
	    {
	        float4x4 MVPMatrix;
	        float4x4 ModelMatrix;
	    }

	    cbuffer BoneMatrices : register(b0, space2)
	    {
	        float4x4 Bones[MAX_BONES];
	    }

	    // Vertex input structure for skinned mesh
	    struct VSInput
	    {
	        float3 Position : POSITION;
	        float3 Normal : NORMAL;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	        float3 Tangent : TANGENT;
	        uint4 Joints : BLENDINDICES;    // Bone indices (4 bones max)
	        float4 Weights : BLENDWEIGHT;   // Bone weights
	    };

	    // Vertex output structure
	    struct VSOutput
	    {
	        float4 Position : SV_POSITION;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	    };

	    VSOutput VS(VSInput input)
	    {
	        VSOutput output;

	        // Compute skinned position by blending bone transforms
	        float4x4 skinMatrix =
	            Bones[input.Joints.x] * input.Weights.x +
	            Bones[input.Joints.y] * input.Weights.y +
	            Bones[input.Joints.z] * input.Weights.z +
	            Bones[input.Joints.w] * input.Weights.w;

	        float4 skinnedPos = mul(float4(input.Position, 1.0), skinMatrix);
	        output.Position = mul(skinnedPos, MVPMatrix);
	        output.TexCoord = input.TexCoord;
	        output.Color = input.Color;
	        return output;
	    }
	    """;

	// ============================================
	// Skinned Phong Shaders (skinning + lighting)
	// ============================================

	public const String SkinnedPhongShadersVS = """
	    #define MAX_BONES 128

	    cbuffer UniformBlock : register(b0, space0)
	    {
	        float4x4 MVPMatrix;
	        float4x4 ModelMatrix;
	    }

	    cbuffer BoneMatrices : register(b0, space2)
	    {
	        float4x4 Bones[MAX_BONES];
	    }

	    struct VSInput
	    {
	        float3 Position : POSITION;
	        float3 Normal : NORMAL;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	        float3 Tangent : TANGENT;
	        uint4 Joints : BLENDINDICES;
	        float4 Weights : BLENDWEIGHT;
	    };

	    struct VSOutput
	    {
	        float4 Position : SV_POSITION;
	        float3 WorldPos : TEXCOORD0;
	        float3 WorldNormal : TEXCOORD1;
	        float2 TexCoord : TEXCOORD2;
	        float4 Color : COLOR;
	    };

	    VSOutput VS(VSInput input)
	    {
	        VSOutput output;

	        // Compute skinned position and normal by blending bone transforms
	        float4x4 skinMatrix =
	            Bones[input.Joints.x] * input.Weights.x +
	            Bones[input.Joints.y] * input.Weights.y +
	            Bones[input.Joints.z] * input.Weights.z +
	            Bones[input.Joints.w] * input.Weights.w;

	        float4 skinnedPos = mul(float4(input.Position, 1.0), skinMatrix);
	        float3 skinnedNormal = mul(float4(input.Normal, 0.0), skinMatrix).xyz;

	        output.Position = mul(skinnedPos, MVPMatrix);
	        output.WorldPos = mul(skinnedPos, ModelMatrix).xyz;
	        output.WorldNormal = normalize(mul(float4(skinnedNormal, 0.0), ModelMatrix).xyz);
	        output.TexCoord = input.TexCoord;
	        output.Color = input.Color;
	        return output;
	    }
	    """;

	// Skinned Phong pixel shader (lighting in space3 since space2 is bones)
	public const String SkinnedPhongShadersPS = """
	    cbuffer MaterialBlock : register(b0, space1)
	    {
	        float4 DiffuseColor;    // w = unused
	        float4 SpecularColor;   // w = shininess
	        float4 AmbientColor;    // w = unused (material ambient tint)
	        float4 Padding;         // Reserved
	    }

	    cbuffer LightingBlock : register(b0, space3)
	    {
	        float4 DirectionalLightDir;   // xyz = direction (normalized), w = unused
	        float4 DirectionalLightColor; // xyz = color, w = intensity
	        float4 SceneAmbientLight;     // xyz = ambient color, w = unused
	        float4 CameraPosition;        // xyz = camera world position, w = unused
	    }

	    Texture2D DiffuseTexture : register(t0, space1);
	    SamplerState LinearSampler : register(s0, space1);

	    struct PSInput
	    {
	        float4 Position : SV_POSITION;
	        float3 WorldPos : TEXCOORD0;
	        float3 WorldNormal : TEXCOORD1;
	        float2 TexCoord : TEXCOORD2;
	        float4 Color : COLOR;
	    };

	    float4 PS(PSInput input) : SV_TARGET
	    {
	        // Sample diffuse texture
	        float4 texColor = DiffuseTexture.Sample(LinearSampler, input.TexCoord);

	        // Normalize inputs
	        float3 N = normalize(input.WorldNormal);
	        float3 L = normalize(-DirectionalLightDir.xyz);
	        float3 V = normalize(CameraPosition.xyz - input.WorldPos);

	        // Ambient (scene ambient * material ambient tint)
	        float3 ambient = SceneAmbientLight.rgb * AmbientColor.rgb * DiffuseColor.rgb;

	        // Diffuse (Lambert)
	        float NdotL = max(dot(N, L), 0.0);
	        float lightIntensity = DirectionalLightColor.w;
	        float3 diffuse = DiffuseColor.rgb * DirectionalLightColor.rgb * NdotL * lightIntensity;

	        // Specular (Blinn-Phong)
	        float3 H = normalize(L + V);
	        float NdotH = max(dot(N, H), 0.0);
	        float shininess = SpecularColor.w;
	        float specPower = pow(NdotH, shininess);
	        float3 specular = SpecularColor.rgb * DirectionalLightColor.rgb * specPower * lightIntensity;

	        // Combine
	        float3 finalColor = (ambient + diffuse) * texColor.rgb * input.Color.rgb + specular;

	        return float4(finalColor, texColor.a * input.Color.a * DiffuseColor.a);
	    }
	    """;

	// ============================================
	// Debug Line Shaders
	// ============================================

	public const String DebugLineVS = """
	    cbuffer DebugUniforms : register(b0, space0)
	    {
	        float4x4 ViewProjection;
	    }

	    struct VSInput
	    {
	        float3 Position : POSITION;
	        float4 Color : COLOR;
	    };

	    struct VSOutput
	    {
	        float4 Position : SV_POSITION;
	        float4 Color : COLOR;
	    };

	    VSOutput VS(VSInput input)
	    {
	        VSOutput output;
	        output.Position = mul(float4(input.Position, 1.0), ViewProjection);
	        output.Color = input.Color;
	        return output;
	    }
	    """;

	public const String DebugLinePS = """
	    struct PSInput
	    {
	        float4 Position : SV_POSITION;
	        float4 Color : COLOR;
	    };

	    float4 PS(PSInput input) : SV_TARGET
	    {
	        return input.Color;
	    }
	    """;

	// ============================================
	// Depth-Only Shaders (for depth prepass)
	// ============================================

	public const String DepthOnlyVS = """
	    cbuffer UniformBlock : register(b0)
	    {
	        float4x4 MVPMatrix;
	        float4x4 ModelMatrix;
	    }

	    struct VSInput
	    {
	        float3 Position : POSITION;
	        float3 Normal : NORMAL;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	        float3 Tangent : TANGENT;
	    };

	    struct VSOutput
	    {
	        float4 Position : SV_POSITION;
	    };

	    VSOutput VS(VSInput input)
	    {
	        VSOutput output;
	        output.Position = mul(float4(input.Position, 1.0), MVPMatrix);
	        return output;
	    }
	    """;

	public const String SkinnedDepthOnlyVS = """
	    #define MAX_BONES 128

	    cbuffer UniformBlock : register(b0, space0)
	    {
	        float4x4 MVPMatrix;
	        float4x4 ModelMatrix;
	    }

	    cbuffer BoneMatrices : register(b0, space2)
	    {
	        float4x4 Bones[MAX_BONES];
	    }

	    struct VSInput
	    {
	        float3 Position : POSITION;
	        float3 Normal : NORMAL;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	        float3 Tangent : TANGENT;
	        uint4 Joints : BLENDINDICES;
	        float4 Weights : BLENDWEIGHT;
	    };

	    struct VSOutput
	    {
	        float4 Position : SV_POSITION;
	    };

	    VSOutput VS(VSInput input)
	    {
	        VSOutput output;

	        // Compute skinned position by blending bone transforms
	        float4x4 skinMatrix =
	            Bones[input.Joints.x] * input.Weights.x +
	            Bones[input.Joints.y] * input.Weights.y +
	            Bones[input.Joints.z] * input.Weights.z +
	            Bones[input.Joints.w] * input.Weights.w;

	        float4 skinnedPos = mul(float4(input.Position, 1.0), skinMatrix);
	        output.Position = mul(skinnedPos, MVPMatrix);
	        return output;
	    }
	    """;

	// ============================================
	// Hi-Z Occlusion Culling Shaders
	// ============================================

	public const String HiZDownsampleCS = """
	    // Hi-Z downsample compute shader
	    // Takes depth texture and produces max of NxN region for hierarchical testing
	    // Single-pass downsample from full resolution to fixed Hi-Z size

	    Texture2D<float> InputDepth : register(t0);
	    RWTexture2D<float> OutputDepth : register(u0);

	    cbuffer HiZParams : register(b0)
	    {
	        uint2 OutputSize;    // Hi-Z texture size (e.g., 64x64)
	        uint2 InputSize;     // Depth buffer size
	    }

	    [numthreads(8, 8, 1)]
	    void CS(uint3 dispatchThreadId : SV_DispatchThreadID)
	    {
	        if (dispatchThreadId.x >= OutputSize.x || dispatchThreadId.y >= OutputSize.y)
	            return;

	        // Calculate the region of the input to sample
	        // Each output pixel covers (InputSize / OutputSize) input pixels
	        uint2 regionStart = (dispatchThreadId.xy * InputSize) / OutputSize;
	        uint2 regionEnd = ((dispatchThreadId.xy + 1) * InputSize) / OutputSize;

	        // Find max depth in the region (furthest from camera)
	        float maxDepth = 0.0;
	        for (uint y = regionStart.y; y < regionEnd.y; y++)
	        {
	            for (uint x = regionStart.x; x < regionEnd.x; x++)
	            {
	                float d = InputDepth[uint2(x, y)];
	                maxDepth = max(maxDepth, d);
	            }
	        }

	        OutputDepth[dispatchThreadId.xy] = maxDepth;
	    }
	    """;

	// ============================================
	// GPU-Driven Culling Compute Shader
	// ============================================

	public const String GPUCullingCS = """
	    // GPU-driven occlusion culling compute shader
	    // Tests objects against frustum and Hi-Z depth, outputs indirect draw args

	    // Per-object data (96 bytes)
	    struct ObjectData
	    {
	        float4x4 WorldMatrix;
	        float4 BoundsMin;    // xyz = min, w = meshIndex
	        float4 BoundsMax;    // xyz = max, w = materialIndex
	    };

	    // Per-mesh info (16 bytes)
	    struct MeshInfo
	    {
	        uint IndexCount;
	        uint FirstIndex;
	        int BaseVertex;
	        uint Padding;
	    };

	    // Indirect draw arguments (20 bytes)
	    struct IndirectDrawArgs
	    {
	        uint IndexCountPerInstance;
	        uint InstanceCount;
	        uint StartIndexLocation;
	        int BaseVertexLocation;
	        uint StartInstanceLocation;
	    };

	    // Input buffers
	    StructuredBuffer<ObjectData> Objects : register(t0);
	    StructuredBuffer<MeshInfo> Meshes : register(t1);
	    Texture2D<float> HiZTexture : register(t2);
	    SamplerState HiZSampler : register(s0);

	    // Output buffers
	    RWStructuredBuffer<IndirectDrawArgs> IndirectArgs : register(u0);
	    RWStructuredBuffer<uint> VisibleIndices : register(u1);
	    RWByteAddressBuffer DrawCount : register(u2);

	    cbuffer CullingUniforms : register(b0)
	    {
	        float4x4 ViewProjection;
	        float4 FrustumPlanes[6];  // xyz = normal, w = distance
	        uint ObjectCount;
	        uint HiZWidth;
	        uint HiZHeight;
	        uint Padding;
	    };

	    // Test AABB against frustum planes
	    bool FrustumTest(float3 boundsMin, float3 boundsMax)
	    {
	        for (int i = 0; i < 6; i++)
	        {
	            float4 plane = FrustumPlanes[i];
	            // Find the corner most aligned with plane normal (p-vertex)
	            float3 p = float3(
	                plane.x > 0 ? boundsMax.x : boundsMin.x,
	                plane.y > 0 ? boundsMax.y : boundsMin.y,
	                plane.z > 0 ? boundsMax.z : boundsMin.z
	            );
	            // If p-vertex is behind plane, AABB is completely outside
	            if (dot(plane.xyz, p) + plane.w < 0)
	                return false;
	        }
	        return true;
	    }

	    // Test AABB against Hi-Z depth buffer
	    bool HiZTest(float3 boundsMin, float3 boundsMax, float4x4 worldMatrix)
	    {
	        // Transform AABB corners to clip space
	        float3 corners[8];
	        corners[0] = float3(boundsMin.x, boundsMin.y, boundsMin.z);
	        corners[1] = float3(boundsMax.x, boundsMin.y, boundsMin.z);
	        corners[2] = float3(boundsMin.x, boundsMax.y, boundsMin.z);
	        corners[3] = float3(boundsMax.x, boundsMax.y, boundsMin.z);
	        corners[4] = float3(boundsMin.x, boundsMin.y, boundsMax.z);
	        corners[5] = float3(boundsMax.x, boundsMin.y, boundsMax.z);
	        corners[6] = float3(boundsMin.x, boundsMax.y, boundsMax.z);
	        corners[7] = float3(boundsMax.x, boundsMax.y, boundsMax.z);

	        float minScreenX = 1.0, maxScreenX = 0.0;
	        float minScreenY = 1.0, maxScreenY = 0.0;
	        float minZ = 1.0;

	        for (int i = 0; i < 8; i++)
	        {
	            // Transform to world space, then to clip space
	            float4 worldPos = mul(float4(corners[i], 1.0), worldMatrix);
	            float4 clipPos = mul(worldPos, ViewProjection);

	            // Behind camera - assume visible (conservative)
	            if (clipPos.w <= 0.001)
	                return true;

	            // Perspective divide to NDC
	            float3 ndc = clipPos.xyz / clipPos.w;

	            // Convert to screen space [0, 1]
	            float screenX = ndc.x * 0.5 + 0.5;
	            float screenY = -ndc.y * 0.5 + 0.5;  // Flip Y

	            minScreenX = min(minScreenX, screenX);
	            maxScreenX = max(maxScreenX, screenX);
	            minScreenY = min(minScreenY, screenY);
	            maxScreenY = max(maxScreenY, screenY);
	            minZ = min(minZ, ndc.z);  // Nearest depth
	        }

	        // Clamp to screen bounds
	        minScreenX = saturate(minScreenX);
	        maxScreenX = saturate(maxScreenX);
	        minScreenY = saturate(minScreenY);
	        maxScreenY = saturate(maxScreenY);

	        // Off-screen check
	        if (minScreenX >= maxScreenX || minScreenY >= maxScreenY)
	            return false;

	        // Calculate Hi-Z texel coordinates
	        uint x0 = uint(minScreenX * float(HiZWidth - 1));
	        uint x1 = uint(maxScreenX * float(HiZWidth - 1));
	        uint y0 = uint(minScreenY * float(HiZHeight - 1));
	        uint y1 = uint(maxScreenY * float(HiZHeight - 1));

	        // Clamp to valid range
	        x0 = min(x0, HiZWidth - 1);
	        x1 = min(x1, HiZWidth - 1);
	        y0 = min(y0, HiZHeight - 1);
	        y1 = min(y1, HiZHeight - 1);

	        // Sample Hi-Z texture - find max depth in covered region
	        float maxHiZDepth = 0.0;
	        for (uint y = y0; y <= y1; y++)
	        {
	            for (uint x = x0; x <= x1; x++)
	            {
	                float d = HiZTexture[uint2(x, y)];
	                maxHiZDepth = max(maxHiZDepth, d);
	            }
	        }

	        // Object is occluded if its nearest point is further than max Hi-Z depth
	        bool isOccluded = minZ > maxHiZDepth;
	        return !isOccluded;
	    }

	    [numthreads(64, 1, 1)]
	    void CS(uint3 dispatchId : SV_DispatchThreadID)
	    {
	        uint objectIndex = dispatchId.x;
	        if (objectIndex >= ObjectCount)
	            return;

	        ObjectData obj = Objects[objectIndex];
	        float3 boundsMin = obj.BoundsMin.xyz;
	        float3 boundsMax = obj.BoundsMax.xyz;

	        // Frustum culling
	        if (!FrustumTest(boundsMin, boundsMax))
	            return;

	        // Hi-Z occlusion culling
	        if (!HiZTest(boundsMin, boundsMax, obj.WorldMatrix))
	            return;

	        // Object is visible - atomically reserve a slot
	        uint visibleIndex;
	        DrawCount.InterlockedAdd(0, 1, visibleIndex);

	        // Get mesh info and write indirect draw args
	        uint meshIndex = asuint(obj.BoundsMin.w);
	        MeshInfo mesh = Meshes[meshIndex];

	        IndirectDrawArgs args;
	        args.IndexCountPerInstance = mesh.IndexCount;
	        args.InstanceCount = 1;
	        args.StartIndexLocation = mesh.FirstIndex;
	        args.BaseVertexLocation = mesh.BaseVertex;
	        args.StartInstanceLocation = visibleIndex;  // Used as instance ID

	        IndirectArgs[visibleIndex] = args;

	        // Store object index for vertex shader lookup
	        VisibleIndices[visibleIndex] = objectIndex;
	    }
	    """;

	// ============================================
	// Instanced Vertex Shaders (for GPU-driven rendering)
	// These shaders look up per-object data from StructuredBuffers using SV_InstanceID
	// ============================================

	public const String InstancedUnlitVS = """
	    // Per-object data from GPU buffer
	    struct ObjectData
	    {
	        float4x4 WorldMatrix;
	        float4 BoundsMin;    // xyz = min, w = meshIndex
	        float4 BoundsMax;    // xyz = max, w = materialIndex
	    };

	    // Frame-level constant buffer
	    cbuffer FrameUniforms : register(b0, space0)
	    {
	        float4x4 ViewProjection;
	    }

	    // Per-object data and visibility buffers
	    StructuredBuffer<ObjectData> Objects : register(t0, space2);
	    StructuredBuffer<uint> VisibleIndices : register(t1, space2);

	    struct VSInput
	    {
	        float3 Position : POSITION;
	        float3 Normal : NORMAL;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	        float3 Tangent : TANGENT;
	    };

	    struct VSOutput
	    {
	        float4 Position : SV_POSITION;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	    };

	    VSOutput VS(VSInput input, uint instanceId : SV_InstanceID)
	    {
	        VSOutput output;

	        // Look up object data using visible index
	        uint objectIndex = VisibleIndices[instanceId];
	        ObjectData obj = Objects[objectIndex];

	        // Compute MVP matrix
	        float4x4 mvp = mul(obj.WorldMatrix, ViewProjection);

	        output.Position = mul(float4(input.Position, 1.0), mvp);
	        output.TexCoord = input.TexCoord;
	        output.Color = input.Color;
	        return output;
	    }
	    """;

	public const String InstancedPhongVS = """
	    // Per-object data from GPU buffer
	    struct ObjectData
	    {
	        float4x4 WorldMatrix;
	        float4 BoundsMin;    // xyz = min, w = meshIndex
	        float4 BoundsMax;    // xyz = max, w = materialIndex
	    };

	    // Frame-level constant buffer
	    cbuffer FrameUniforms : register(b0, space0)
	    {
	        float4x4 ViewProjection;
	    }

	    // Per-object data and visibility buffers
	    StructuredBuffer<ObjectData> Objects : register(t0, space2);
	    StructuredBuffer<uint> VisibleIndices : register(t1, space2);

	    struct VSInput
	    {
	        float3 Position : POSITION;
	        float3 Normal : NORMAL;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	        float3 Tangent : TANGENT;
	    };

	    struct VSOutput
	    {
	        float4 Position : SV_POSITION;
	        float3 WorldPos : TEXCOORD0;
	        float3 WorldNormal : TEXCOORD1;
	        float2 TexCoord : TEXCOORD2;
	        float4 Color : COLOR;
	    };

	    VSOutput VS(VSInput input, uint instanceId : SV_InstanceID)
	    {
	        VSOutput output;

	        // Look up object data using visible index
	        uint objectIndex = VisibleIndices[instanceId];
	        ObjectData obj = Objects[objectIndex];

	        // Compute MVP matrix
	        float4x4 mvp = mul(obj.WorldMatrix, ViewProjection);

	        output.Position = mul(float4(input.Position, 1.0), mvp);
	        output.WorldPos = mul(float4(input.Position, 1.0), obj.WorldMatrix).xyz;
	        output.WorldNormal = normalize(mul(float4(input.Normal, 0.0), obj.WorldMatrix).xyz);
	        output.TexCoord = input.TexCoord;
	        output.Color = input.Color;
	        return output;
	    }
	    """;

	public const String InstancedPBRVS = """
	    // Per-object data from GPU buffer
	    struct ObjectData
	    {
	        float4x4 WorldMatrix;
	        float4 BoundsMin;    // xyz = min, w = meshIndex
	        float4 BoundsMax;    // xyz = max, w = materialIndex
	    };

	    // Frame-level constant buffer
	    cbuffer FrameUniforms : register(b0, space0)
	    {
	        float4x4 ViewProjection;
	    }

	    // Per-object data and visibility buffers
	    StructuredBuffer<ObjectData> Objects : register(t0, space2);
	    StructuredBuffer<uint> VisibleIndices : register(t1, space2);

	    struct VSInput
	    {
	        float3 Position : POSITION;
	        float3 Normal : NORMAL;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	        float3 Tangent : TANGENT;
	    };

	    struct VSOutput
	    {
	        float4 Position : SV_POSITION;
	        float3 WorldPos : TEXCOORD0;
	        float3 WorldNormal : TEXCOORD1;
	        float2 TexCoord : TEXCOORD2;
	        float4 Color : COLOR;
	        float3 WorldTangent : TEXCOORD3;
	    };

	    VSOutput VS(VSInput input, uint instanceId : SV_InstanceID)
	    {
	        VSOutput output;

	        // Look up object data using visible index
	        uint objectIndex = VisibleIndices[instanceId];
	        ObjectData obj = Objects[objectIndex];

	        // Compute MVP matrix
	        float4x4 mvp = mul(obj.WorldMatrix, ViewProjection);

	        output.Position = mul(float4(input.Position, 1.0), mvp);
	        output.WorldPos = mul(float4(input.Position, 1.0), obj.WorldMatrix).xyz;
	        output.WorldNormal = normalize(mul(float4(input.Normal, 0.0), obj.WorldMatrix).xyz);
	        output.WorldTangent = normalize(mul(float4(input.Tangent, 0.0), obj.WorldMatrix).xyz);
	        output.TexCoord = input.TexCoord;
	        output.Color = input.Color;
	        return output;
	    }
	    """;

	public const String InstancedDepthOnlyVS = """
	    // Per-object data from GPU buffer
	    struct ObjectData
	    {
	        float4x4 WorldMatrix;
	        float4 BoundsMin;    // xyz = min, w = meshIndex
	        float4 BoundsMax;    // xyz = max, w = materialIndex
	    };

	    // Frame-level constant buffer
	    cbuffer FrameUniforms : register(b0, space0)
	    {
	        float4x4 ViewProjection;
	    }

	    // Per-object data and visibility buffers
	    StructuredBuffer<ObjectData> Objects : register(t0, space2);
	    StructuredBuffer<uint> VisibleIndices : register(t1, space2);

	    struct VSInput
	    {
	        float3 Position : POSITION;
	        float3 Normal : NORMAL;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	        float3 Tangent : TANGENT;
	    };

	    struct VSOutput
	    {
	        float4 Position : SV_POSITION;
	    };

	    VSOutput VS(VSInput input, uint instanceId : SV_InstanceID)
	    {
	        VSOutput output;

	        // Look up object data using visible index
	        uint objectIndex = VisibleIndices[instanceId];
	        ObjectData obj = Objects[objectIndex];

	        // Compute MVP matrix
	        float4x4 mvp = mul(obj.WorldMatrix, ViewProjection);

	        output.Position = mul(float4(input.Position, 1.0), mvp);
	        return output;
	    }
	    """;

	// ============================================
	// Sprite Shaders
	// ============================================

	public const String SpriteShadersVS = """
	    // Per-sprite constant buffer
	    cbuffer SpriteUniforms : register(b0)
	    {
	        float4x4 MVPMatrix;
	        float4 SpriteParams;  // xy = size, zw = pivot
	        float4 UVBounds;      // xy = uvMin, zw = uvMax
	        float4 TintColor;     // rgba tint
	    }

	    struct VSInput
	    {
	        float3 Position : POSITION;  // Unit quad: (0,0), (1,0), (1,1), (0,1)
	    };

	    struct VSOutput
	    {
	        float4 Position : SV_POSITION;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	    };

	    VSOutput VS(VSInput input)
	    {
	        VSOutput output;

	        // Extract sprite parameters
	        float2 size = SpriteParams.xy;
	        float2 pivot = SpriteParams.zw;
	        float2 uvMin = UVBounds.xy;
	        float2 uvMax = UVBounds.zw;

	        // Transform unit quad position by size and pivot
	        // Unit quad is 0-1, pivot is 0-1, size is world units
	        float2 localPos = (input.Position.xy - pivot) * size;
	        float3 worldPos = float3(localPos, 0.0);

	        output.Position = mul(float4(worldPos, 1.0), MVPMatrix);

	        // Interpolate UVs from unit quad position
	        output.TexCoord = lerp(uvMin, uvMax, input.Position.xy);

	        // Pass tint color to pixel shader
	        output.Color = TintColor;

	        return output;
	    }
	    """;

	public const String SpriteShadersPS = """
	    // Sprite texture (material buffer kept for layout compatibility but unused)
	    Texture2D SpriteTexture : register(t0, space1);
	    SamplerState SpriteSampler : register(s0, space1);

	    struct PSInput
	    {
	        float4 Position : SV_POSITION;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;  // Tint color from vertex shader
	    };

	    float4 PS(PSInput input) : SV_TARGET0
	    {
	        // Sample texture
	        float4 texColor = SpriteTexture.Sample(SpriteSampler, input.TexCoord);

	        // Combine texture * tint color (from vertex shader)
	        float4 finalColor = texColor * input.Color;

	        // Alpha test - discard fully transparent pixels
	        if (finalColor.a < 0.01)
	            discard;

	        return finalColor;
	    }
	    """;

	// ============================================
	// Picking Shaders (GPU-based object picking)
	// ============================================

	/// Picking vertex shader - transforms vertices and passes entity ID to pixel shader
	public const String PickingShadersVS = """
	    cbuffer PickingUniforms : register(b0)
	    {
	        float4x4 MVPMatrix;
	        uint EntityId;
	        uint3 Padding;
	    }

	    struct VSInput
	    {
	        float3 Position : POSITION;
	        float3 Normal : NORMAL;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	        float3 Tangent : TANGENT;
	    };

	    struct VSOutput
	    {
	        float4 Position : SV_POSITION;
	        nointerpolation uint EntityId : ENTITY_ID;
	    };

	    VSOutput VS(VSInput input)
	    {
	        VSOutput output;
	        output.Position = mul(float4(input.Position, 1.0), MVPMatrix);
	        output.EntityId = EntityId;
	        return output;
	    }
	    """;

	/// Picking pixel shader - outputs entity ID as R32_UInt
	public const String PickingShadersPS = """
	    struct PSInput
	    {
	        float4 Position : SV_POSITION;
	        nointerpolation uint EntityId : ENTITY_ID;
	    };

	    uint PS(PSInput input) : SV_TARGET
	    {
	        return input.EntityId;
	    }
	    """;

	/// Skinned picking vertex shader - for skinned meshes
	public const String SkinnedPickingShadersVS = """
	    #define MAX_BONES 128

	    cbuffer PickingUniforms : register(b0, space0)
	    {
	        float4x4 MVPMatrix;
	        uint EntityId;
	        uint3 Padding;
	    }

	    cbuffer BoneMatrices : register(b0, space1)
	    {
	        float4x4 Bones[MAX_BONES];
	    }

	    struct VSInput
	    {
	        float3 Position : POSITION;
	        float3 Normal : NORMAL;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	        float3 Tangent : TANGENT;
	        uint4 Joints : BLENDINDICES;
	        float4 Weights : BLENDWEIGHT;
	    };

	    struct VSOutput
	    {
	        float4 Position : SV_POSITION;
	        nointerpolation uint EntityId : ENTITY_ID;
	    };

	    VSOutput VS(VSInput input)
	    {
	        VSOutput output;

	        // Compute skinned position by blending bone transforms
	        float4x4 skinMatrix =
	            Bones[input.Joints.x] * input.Weights.x +
	            Bones[input.Joints.y] * input.Weights.y +
	            Bones[input.Joints.z] * input.Weights.z +
	            Bones[input.Joints.w] * input.Weights.w;

	        float4 skinnedPos = mul(float4(input.Position, 1.0), skinMatrix);
	        output.Position = mul(skinnedPos, MVPMatrix);
	        output.EntityId = EntityId;
	        return output;
	    }
	    """;

	/// Sprite picking vertex shader - for billboarded sprites
	public const String SpritePickingShadersVS = """
	    cbuffer PickingUniforms : register(b0)
	    {
	        float4x4 MVPMatrix;
	        uint EntityId;
	        uint3 Padding;
	    }

	    cbuffer SpriteParams : register(b1)
	    {
	        float4 SpriteSize;  // xy = size, zw = pivot
	    }

	    struct VSInput
	    {
	        float3 Position : POSITION;
	    };

	    struct VSOutput
	    {
	        float4 Position : SV_POSITION;
	        nointerpolation uint EntityId : ENTITY_ID;
	    };

	    VSOutput VS(VSInput input)
	    {
	        VSOutput output;

	        // Extract sprite parameters
	        float2 size = SpriteSize.xy;
	        float2 pivot = SpriteSize.zw;

	        // Transform unit quad position by size and pivot
	        float2 localPos = (input.Position.xy - pivot) * size;
	        float3 worldPos = float3(localPos, 0.0);

	        output.Position = mul(float4(worldPos, 1.0), MVPMatrix);
	        output.EntityId = EntityId;
	        return output;
	    }
	    """;
}