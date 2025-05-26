cbuffer CameraBuffer : register(b0)
{
    float4x4 ViewMatrix;
    float4x4 ProjectionMatrix;
    float4x4 ViewProjectionMatrix;
    float3 CameraPosition;
    float3 CameraForward;
};

cbuffer ObjectBuffer : register(b1)
{
    float4x4 WorldMatrix;
};

struct VertexInput
{
    float3 Position : POSITION;
    float3 Normal : NORMAL;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR;
};

struct VertexOutput
{
    float4 Position : SV_Position;
    float3 WorldPosition : POSITION1;
    float3 Normal : NORMAL;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR;
};

VertexOutput main(VertexInput input)
{
    VertexOutput output;
    
    // Transform to world space
    float4 worldPos = mul(float4(input.Position, 1.0), WorldMatrix);
    output.WorldPosition = worldPos.xyz;
    
    // Transform to clip space
    output.Position = mul(worldPos, ViewProjectionMatrix);
    
    // Transform normal to world space
    output.Normal = normalize(mul(input.Normal, (float3x3)WorldMatrix));
    
    // Pass through texture coordinates and color
    output.TexCoord = input.TexCoord;
    output.Color = input.Color;
    
    return output;
}