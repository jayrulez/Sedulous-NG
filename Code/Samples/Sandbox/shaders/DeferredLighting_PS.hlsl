#include "ShaderBindings.hlsl"

struct PixelInput
{
    float4 Position : SV_POSITION;
    float2 TexCoord : TEXCOORD0;
};

Texture2D GBuffer_Albedo    : TEX_SLOT(0);
Texture2D GBuffer_Normals   : TEX_SLOT(1);
Texture2D GBuffer_Roughness : TEX_SLOT(2);
Texture2D GBuffer_Metallic  : TEX_SLOT(3);
Texture2D GBuffer_AO        : TEX_SLOT(4);
Texture2D DepthMap          : TEX_SLOT(5);
SamplerState TextureSampler : SAMPLER_SLOT(0);

cbuffer LightBuffer : CB_SLOT(1)
{
    float3 LightDirection;
    float  LightIntensity;
};

cbuffer CameraBuffer : CB_SLOT(2)
{
    float4x4 ViewMatrix;
    float4x4 ProjectionMatrix;
};

float4 main(PixelInput input) : SV_Target
{
    float3 albedo = GBuffer_Albedo.Sample(TextureSampler, input.TexCoord).rgb;
    float3 normal = normalize(GBuffer_Normals.Sample(TextureSampler, input.TexCoord).rgb * 2.0 - 1.0);
    float roughness = GBuffer_Roughness.Sample(TextureSampler, input.TexCoord).r;
    float metallic = GBuffer_Metallic.Sample(TextureSampler, input.TexCoord).r;
    float ao = GBuffer_AO.Sample(TextureSampler, input.TexCoord).r;

    float3 lightColor = float3(1.0, 1.0, 1.0);
    float3 lightDir = normalize(-LightDirection);

    float NdotL = max(dot(normal, lightDir), 0.0);
    float3 lighting = (albedo * lightColor * LightIntensity) * NdotL;

    return float4(lighting, 1.0);
}
