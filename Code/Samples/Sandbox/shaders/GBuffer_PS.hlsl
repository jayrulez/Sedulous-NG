struct VertexOutput
{
    float4 Position : SV_POSITION;
    float3 WorldPos : TEXCOORD1;
    float3 Normal   : TEXCOORD2;
    float2 TexCoord : TEXCOORD3;
};

// Texture bindings
Texture2D AlbedoMap    : register(t0, space0);
Texture2D NormalMap    : register(t1, space0);
Texture2D RoughnessMap : register(t2, space0);
Texture2D MetallicMap  : register(t3, space0);
Texture2D AOMap        : register(t4, space0);
SamplerState TextureSampler : register(s0, space0);

struct GBufferOutput
{
    float4 Albedo    : SV_Target0;
    float4 Normal    : SV_Target1;
    float4 Roughness : SV_Target2;
    float4 Metallic  : SV_Target3;
    float4 AO        : SV_Target4;
};

GBufferOutput main(VertexOutput input)
{
    GBufferOutput output;

    // Sample Albedo, default to white if texture is not bound
    float4 albedoSample = AlbedoMap.Sample(TextureSampler, input.TexCoord);
    float3 albedo = (albedoSample.a == 0.0) ? float3(1.0, 1.0, 1.0) : albedoSample.rgb;

    // Sample Normal Map (Convert from [0,1] to [-1,1] range)
    float3 normal = NormalMap.Sample(TextureSampler, input.TexCoord).rgb * 2.0 - 1.0;
    normal = normalize(normal);

    // Sample Material Properties
    float roughness = RoughnessMap.Sample(TextureSampler, input.TexCoord).r;
    float metallic = MetallicMap.Sample(TextureSampler, input.TexCoord).r;
    float ao = AOMap.Sample(TextureSampler, input.TexCoord).r;

    // Fill GBuffer Outputs
    output.Albedo = float4(albedo, 1.0);
    output.Normal = float4(normal, 1.0);
    output.Roughness = float4(roughness, 0, 0, 1);
    output.Metallic = float4(metallic, 0, 0, 1);
    output.AO = float4(ao, 0, 0, 1);

    return output;
}
