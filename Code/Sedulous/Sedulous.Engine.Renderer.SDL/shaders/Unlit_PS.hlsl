cbuffer MaterialBuffer : register(b0)
{
    float4 AlbedoColor;
    float Metallic;
    float Roughness;
    float NormalStrength;
    float EmissiveStrength;
    float3 EmissiveColor;
};

Texture2D AlbedoTexture : register(t0);
SamplerState AlbedoSampler : register(s0);

struct PixelInput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR;
};

float4 main(PixelInput input) : SV_Target
{
    // Sample albedo texture
    float4 albedoSample = AlbedoTexture.Sample(AlbedoSampler, input.TexCoord);
    float4 albedo = albedoSample * AlbedoColor * input.Color;
    
    // Add emissive
    float3 finalColor = albedo.rgb + EmissiveColor * EmissiveStrength;
    
    return float4(finalColor, albedo.a);
}