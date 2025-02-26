struct VertexInput
{
    float3 Position : POSITION;
    float3 Normal   : NORMAL;
    float2 TexCoord : TEXCOORD;
};

struct VertexOutput
{
    float4 Position : SV_POSITION;
    float3 WorldPos : TEXCOORD1;
    float3 Normal   : TEXCOORD2;
    float2 TexCoord : TEXCOORD3;
};

cbuffer CameraBuffer : register(b0, space0)
{
    float4x4 ViewMatrix;
    float4x4 ProjectionMatrix;
};

/*
cbuffer ObjectBuffer : register(b1, space0)
{
    float4x4 ModelMatrix; // New: To transform local to world space
};
*/

// Hard-coded transform (example: scale by 1.0 and translate slightly)
static const float4x4 ModelMatrix =
{
    1.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0,
    0.5, 0.0, 0.0, 1.0  // Translation by (0.5, 0.0, 0.0)
};

VertexOutput main(VertexInput input)
{
    VertexOutput output;
    
    float4 worldPos = mul(ModelMatrix, float4(input.Position, 1.0)); // Local → World
    output.WorldPos = worldPos.xyz;
    output.Normal = normalize(mul((float3x3)ModelMatrix, input.Normal)); // Normal → World
    output.TexCoord = input.TexCoord;
    
    output.Position = mul(ProjectionMatrix, mul(ViewMatrix, worldPos)); // MVP transform
    
    return output;
}
