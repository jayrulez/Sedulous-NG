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
    public Vector4 LightDirection;  // xyz = direction, w = intensity
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
	        float4 AmbientColor;    // w = unused
	        float4 LightDirection;  // xyz = direction, w = intensity
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
	        float3 L = normalize(-LightDirection.xyz);
	        float3 V = normalize(-input.WorldPos); // Approximate view direction

	        // Ambient
	        float3 ambient = AmbientColor.rgb * DiffuseColor.rgb;

	        // Diffuse (Lambert)
	        float NdotL = max(dot(N, L), 0.0);
	        float3 diffuse = DiffuseColor.rgb * NdotL * LightDirection.w;

	        // Specular (Blinn-Phong)
	        float3 H = normalize(L + V);
	        float NdotH = max(dot(N, H), 0.0);
	        float shininess = SpecularColor.w;
	        float specPower = pow(NdotH, shininess);
	        float3 specular = SpecularColor.rgb * specPower * LightDirection.w;

	        // Combine
	        float3 finalColor = (ambient + diffuse) * texColor.rgb * input.Color.rgb + specular;

	        return float4(finalColor, texColor.a * input.Color.a * DiffuseColor.a);
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
}