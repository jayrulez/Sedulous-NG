struct VertexOutput
{
    float4 Position : SV_Position;
    float2 TexCoord : TEXCOORD;
};

VertexOutput main(uint vertexID : SV_VertexID)
{
    VertexOutput output;
    
    float2 uv = float2((vertexID << 1) & 2, vertexID & 2);
    output.Position = float4(uv * 2.0 - 1.0, 0.0, 1.0);
    output.TexCoord = uv;

    return output;
}
