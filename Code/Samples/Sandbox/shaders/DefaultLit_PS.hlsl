cbuffer MaterialBuffer : register(b0)
{
    float4 AlbedoColor;
    float Metallic;
    float Roughness;
    float NormalStrength;
    float EmissiveStrength;
    float3 EmissiveColor;
};

cbuffer LightBuffer : register(b1)
{
    float3 LightDirection;
    float3 LightColor;
    float LightIntensity;
};

Texture2D AlbedoTexture : register(t0);
SamplerState AlbedoSampler : register(s0);

struct PixelInput
{
    float4 Position : SV_Position;
    float3 WorldPosition : POSITION1;
    float3 Normal : NORMAL;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR;
};

float4 main(PixelInput input) : SV_Target
{
    // Sample albedo texture
    float4 albedoSample = AlbedoTexture.Sample(AlbedoSampler, input.TexCoord);
    float4 albedo = albedoSample * AlbedoColor * input.Color;
    
    // Simple directional lighting
    float3 normal = normalize(input.Normal);
    float3 lightDir = normalize(-LightDirection);
    float dotNL = max(dot(normal, lightDir), 0.0);
    
    // Basic diffuse lighting
    float3 diffuse = albedo.rgb * LightColor * LightIntensity * dotNL;
    
    // Add ambient
    float3 ambient = albedo.rgb * 0.1;
    
    float3 finalColor = diffuse + ambient + EmissiveColor * EmissiveStrength;
    
    return float4(finalColor, albedo.a);
}