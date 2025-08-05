// Shadow map shader - for rendering depth to shadow maps

// ==================== CONSTANT BUFFERS ====================

cbuffer LightData : register(b0)
{
    float4x4 LightViewProjectionMatrix;
    float NearPlane;
    float FarPlane;
    float2 _LightPadding;
}

cbuffer PerObjectData : register(b1)
{
    float4x4 WorldMatrix;
}

#ifdef USE_SKINNING
cbuffer SkinningData : register(b2)
{
    float4x4 BoneMatrices[128];
}
#endif

// ==================== VERTEX SHADER ====================

struct VSInput
{
    float3 Position : POSITION;
    
    #ifdef USE_ALPHA_TEST
    float2 TexCoord : TEXCOORD0;
    #endif
    
    #ifdef USE_SKINNING
    uint4 BoneIndices : BLENDINDICES;
    float4 BoneWeights : BLENDWEIGHT;
    #endif
    
    #ifdef USE_INSTANCING
    float4x4 InstanceMatrix : INSTANCE_MATRIX;
    uint InstanceID : SV_InstanceID;
    #endif
};

struct VSOutput
{
    float4 Position : SV_POSITION;
    float Depth : TEXCOORD0;
    
    #ifdef USE_ALPHA_TEST
    float2 TexCoord : TEXCOORD1;
    #endif
};

VSOutput VS(VSInput input)
{
    VSOutput output;
    
    // Apply skinning if enabled
    float4 position = float4(input.Position, 1.0);
    
    #ifdef USE_SKINNING
    float4x4 skinMatrix = 
        BoneMatrices[input.BoneIndices.x] * input.BoneWeights.x +
        BoneMatrices[input.BoneIndices.y] * input.BoneWeights.y +
        BoneMatrices[input.BoneIndices.z] * input.BoneWeights.z +
        BoneMatrices[input.BoneIndices.w] * input.BoneWeights.w;
    
    position = mul(position, skinMatrix);
    #endif
    
    // Apply instancing if enabled
    #ifdef USE_INSTANCING
    float4x4 worldMatrix = input.InstanceMatrix;
    #else
    float4x4 worldMatrix = WorldMatrix;
    #endif
    
    // Transform to world space
    float4 worldPos = mul(position, worldMatrix);
    
    // Transform to light's clip space
    output.Position = mul(worldPos, LightViewProjectionMatrix);
    
    // Store linear depth for better precision
    output.Depth = output.Position.z / output.Position.w;
    
    #ifdef USE_ALPHA_TEST
    output.TexCoord = input.TexCoord;
    #endif
    
    return output;
}

// ==================== PIXEL SHADER ====================

#ifdef USE_ALPHA_TEST
cbuffer MaterialData : register(b0, space1)
{
    float AlphaCutoff;
    float3 _MaterialPadding;
}

Texture2D AlphaTexture : register(t0, space1);
SamplerState AlphaSampler : register(s0, space1);
#endif

struct PSOutput
{
    float Depth : SV_DEPTH;
};

PSOutput PS(VSOutput input)
{
    PSOutput output;
    
    #ifdef USE_ALPHA_TEST
    // Sample alpha texture for alpha testing
    float alpha = AlphaTexture.Sample(AlphaSampler, input.TexCoord).a;
    if (alpha < AlphaCutoff)
        discard;
    #endif
    
    // For standard shadow maps, we can just use the hardware depth
    // The depth is automatically written to the depth buffer
    output.Depth = input.Position.z;
    
    // For VSM (Variance Shadow Maps), we would output depth and depth²
    // For ESM (Exponential Shadow Maps), we would output exp(depth * k)
    
    return output;
}

// ==================== GEOMETRY SHADER (Optional - for cube map shadows) ====================

#ifdef USE_CUBE_SHADOWS

cbuffer CubeShadowData : register(b3)
{
    float4x4 LightViewMatrices[6]; // One for each cube face
}

struct GSOutput
{
    float4 Position : SV_POSITION;
    float Depth : TEXCOORD0;
    uint RTIndex : SV_RenderTargetArrayIndex;
};

[maxvertexcount(18)] // 6 faces * 3 vertices
void GS(triangle VSOutput input[3], inout TriangleStream<GSOutput> output)
{
    // For each cube face
    for (uint face = 0; face < 6; face++)
    {
        GSOutput vertex;
        vertex.RTIndex = face;
        
        // Transform each vertex to the current cube face
        for (uint i = 0; i < 3; i++)
        {
            float4 worldPos = float4(input[i].Position.xyz, 1.0);
            vertex.Position = mul(worldPos, LightViewMatrices[face]);
            vertex.Position = mul(vertex.Position, ProjectionMatrix);
            vertex.Depth = length(worldPos.xyz - LightPosition) / FarPlane;
            output.Append(vertex);
        }
        
        output.RestartStrip();
    }
}

#endif