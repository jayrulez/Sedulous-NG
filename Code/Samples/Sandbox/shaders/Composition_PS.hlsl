#include "ShaderBindings.hlsl"

struct PixelInput
{
    float4 Position : SV_POSITION;
    float2 TexCoord : TEXCOORD0;
};

Texture2D LightingBuffer : TEX_SLOT(0);
SamplerState TextureSampler : SAMPLER_SLOT(0);

float4 main(PixelInput input) : SV_Target
{
    return LightingBuffer.Sample(TextureSampler, input.TexCoord);
}
