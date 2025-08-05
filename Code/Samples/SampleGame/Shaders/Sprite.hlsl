// Sprite shader - optimized for 2D sprites with instancing support

// ==================== CONSTANT BUFFERS ====================

cbuffer PerFrameData : register(b0)
{
    float4x4 ViewProjectionMatrix;
    float2 ScreenSize;
    float Time;
    float _Padding;
}

cbuffer MaterialData : register(b0, space1)
{
    float4 TintColor;
}

// ==================== TEXTURES ====================

Texture2D SpriteTexture : register(t0, space1);
SamplerState SpriteSampler : register(s0, space1);

// ==================== VERTEX SHADER ====================

struct VSInput
{
    float3 Position : POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR;
    
    #ifdef USE_INSTANCING
    // Per-instance data
    float4 PositionScale : INSTANCE_POS_SCALE; // xy = position, zw = scale
    float4 UVRect : INSTANCE_UV_RECT; // xy = uv offset, zw = uv scale
    float Rotation : INSTANCE_ROTATION;
    float4 InstanceColor : INSTANCE_COLOR;
    uint InstanceID : SV_InstanceID;
    #endif
};

struct VSOutput
{
    float4 Position : SV_POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR;
};

VSOutput VS(VSInput input)
{
    VSOutput output;
    
    #ifdef USE_INSTANCING
    // Apply instance transform
    float2 pos = input.Position.xy;
    
    // Apply rotation
    float cosR = cos(input.Rotation);
    float sinR = sin(input.Rotation);
    float2x2 rotMatrix = float2x2(cosR, -sinR, sinR, cosR);
    pos = mul(pos, rotMatrix);
    
    // Apply scale and position
    pos = pos * input.PositionScale.zw + input.PositionScale.xy;
    
    // Transform to screen space (assuming orthographic projection)
    output.Position = mul(float4(pos, 0.0, 1.0), ViewProjectionMatrix);
    
    // Transform UVs
    output.TexCoord = input.TexCoord * input.UVRect.zw + input.UVRect.xy;
    
    // Combine colors
    output.Color = input.Color * input.InstanceColor;
    #else
    // Simple transform without instancing
    output.Position = mul(float4(input.Position, 1.0), ViewProjectionMatrix);
    output.TexCoord = input.TexCoord;
    output.Color = input.Color;
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
    
    // Sample sprite texture
    float4 texColor = SpriteTexture.Sample(SpriteSampler, input.TexCoord);
    
    // Apply color tinting
    output.Color = texColor * input.Color * TintColor;
    
    // Premultiplied alpha is often used for sprites
    #ifdef USE_PREMULTIPLIED_ALPHA
    output.Color.rgb *= output.Color.a;
    #endif
    
    return output;
}