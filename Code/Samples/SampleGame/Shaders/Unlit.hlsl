// Unlit shader - no lighting calculations, just texture and color

// ==================== CONSTANT BUFFERS ====================

cbuffer PerFrameData : register(b0)
{
    float4x4 ViewMatrix;
    float4x4 ProjectionMatrix;
    float4x4 ViewProjectionMatrix;
    float3 CameraPosition;
    float Time;
}

cbuffer PerObjectData : register(b1)
{
    float4x4 WorldMatrix;
    float4x4 WorldViewProjectionMatrix;
}

cbuffer MaterialData : register(b0, space1)
{
    float4 TintColor;
    float AlphaCutoff;
    float3 _Padding;
}

// ==================== TEXTURES ====================

Texture2D MainTexture : register(t0, space1);
SamplerState MainSampler : register(s0, space1);

// ==================== VERTEX SHADER ====================

struct VSInput
{
    float3 Position : POSITION;
    float3 Normal : NORMAL;
    float2 TexCoord : TEXCOORD0;
    #ifdef USE_VERTEX_COLOR
    float4 Color : COLOR;
    #endif
    float3 Tangent : TANGENT;
    
    #ifdef USE_INSTANCING
    float4x4 InstanceMatrix : INSTANCE_MATRIX;
    uint InstanceID : SV_InstanceID;
    #endif
};

struct VSOutput
{
    float4 Position : SV_POSITION;
    float2 TexCoord : TEXCOORD0;
    #ifdef USE_VERTEX_COLOR
    float4 Color : COLOR;
    #endif
    #ifdef USE_FOG
    float FogFactor : TEXCOORD1;
    #endif
};

VSOutput VS(VSInput input)
{
    VSOutput output;
    
    // Apply instancing if enabled
    #ifdef USE_INSTANCING
    float4x4 worldMatrix = input.InstanceMatrix;
    #else
    float4x4 worldMatrix = WorldMatrix;
    #endif
    
    // Transform position
    float4 worldPos = mul(float4(input.Position, 1.0), worldMatrix);
    output.Position = mul(worldPos, ViewProjectionMatrix);
    
    // Pass through texture coordinates
    output.TexCoord = input.TexCoord;
    
    #ifdef USE_VERTEX_COLOR
    output.Color = input.Color;
    #endif
    
    #ifdef USE_FOG
    // Calculate linear fog
    float fogDistance = length(worldPos.xyz - CameraPosition);
    output.FogFactor = saturate((fogDistance - 100.0) / 900.0); // Fog from 100 to 1000 units
    #endif
    
    return output;
}

// ==================== PIXEL SHADER ====================

struct PSOutput
{
    float4 Color : SV_TARGET0;
};

PSOutput PS(VSOutput input)
{
    PSOutput output;
    
    // Sample texture
    float4 texColor = MainTexture.Sample(MainSampler, input.TexCoord);
    
    // Apply tint color
    float4 finalColor = texColor * TintColor;
    
    #ifdef USE_VERTEX_COLOR
    finalColor *= input.Color;
    #endif
    
    #ifdef USE_ALPHA_TEST
    if (finalColor.a < AlphaCutoff)
        discard;
    #endif
    
    #ifdef USE_FOG
    // Apply fog
    float3 fogColor = float3(0.7, 0.7, 0.8);
    finalColor.rgb = lerp(finalColor.rgb, fogColor, input.FogFactor);
    #endif
    
    output.Color = finalColor;
    return output;
}