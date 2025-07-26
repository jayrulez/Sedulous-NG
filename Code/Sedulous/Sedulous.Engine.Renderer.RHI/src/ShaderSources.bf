using System;
namespace Sedulous.Engine.Renderer.RHI;

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
	        uint Color : COLOR; // converted automatically
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
	    struct PSInput
	    {
	        float4 Position : SV_POSITION;
	        float2 TexCoord : TEXCOORD0;
	        float4 Color : COLOR;
	    };
	    float4 PS(PSInput input) : SV_TARGET
	    {
	        // Just return the vertex color
	        return input.Color;
	    }
	    """;
}