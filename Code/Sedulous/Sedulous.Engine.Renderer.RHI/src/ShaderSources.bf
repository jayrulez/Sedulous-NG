using System;
namespace Sedulous.Engine.Renderer.RHI;

static class ShaderSources
{
	public const String UnlitShadersVS = """
	    // Constant buffers
	    cbuffer PerFrame : register(b0)
	    {
	        float4x4 ViewMatrix;
	        float4x4 ProjectionMatrix;
	        float4x4 ViewProjectionMatrix;
	    }
	    cbuffer PerObject : register(b1)
	    {
	        float4x4 WorldMatrix;
	        float4x4 WorldInverseTranspose;  // For transforming normals
	    }
	    // Vertex input structure
	    struct VSInput
	    {
	        float3 Position : POSITION;
	        float3 Normal : NORMAL;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	        float4 Tangent : TANGENT;  // xyz = tangent direction, w = handedness
	    };
	    // Vertex output structure
	    struct VSOutput
	    {
	        float4 Position : SV_POSITION;
	        float3 WorldPos : POSITION;
	        float3 Normal : NORMAL;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	        float3 Tangent : TANGENT;
	        float3 Bitangent : BITANGENT;
	    };
	    VSOutput VS(VSInput input)
	    {
	        VSOutput output;
	        
	        // Transform position to world space
	        float4 worldPos = mul(float4(input.Position, 1.0), WorldMatrix);
	        output.WorldPos = worldPos.xyz;
	        
	        // Transform position to clip space
	        output.Position = mul(worldPos, ViewProjectionMatrix);
	        
	        // Transform normal to world space
	        output.Normal = normalize(mul(input.Normal, (float3x3)WorldInverseTranspose));
	        
	        // Pass through texture coordinates and vertex color
	        output.TexCoord = input.TexCoord;
	        output.Color = input.Color;
	        
	        // Transform tangent to world space
	        output.Tangent = normalize(mul(input.Tangent.xyz, (float3x3)WorldMatrix));
	        
	        // Calculate bitangent using cross product and handedness
	        output.Bitangent = cross(output.Normal, output.Tangent) * input.Tangent.w;
	        
	        return output;
	    }
	    """;

	public const String UnlitShadersPS = """
	    struct PSInput
	    {
	        float4 Position : SV_POSITION;
	        float3 WorldPos : POSITION;
	        float3 Normal : NORMAL;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	        float3 Tangent : TANGENT;
	        float3 Bitangent : BITANGENT;
	    };
	    float4 PS(PSInput input) : SV_TARGET
	    {
	        // Just return the vertex color
	        return input.Color;
	    }
	    """;
}