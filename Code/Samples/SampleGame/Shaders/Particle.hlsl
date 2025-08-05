// Particle shader - for GPU particle systems

// ==================== CONSTANT BUFFERS ====================

cbuffer PerFrameData : register(b0)
{
    float4x4 ViewMatrix;
    float4x4 ProjectionMatrix;
    float4x4 ViewProjectionMatrix;
    float3 CameraPosition;
    float Time;
    float3 CameraRight;
    float DeltaTime;
    float3 CameraUp;
    float _Padding;
}

cbuffer ParticleSystemData : register(b1)
{
    float3 EmitterPosition;
    float EmitterRadius;
    float3 Gravity;
    float ParticleLifetime;
    float StartSize;
    float EndSize;
    float2 _ParticlePadding;
}

cbuffer MaterialData : register(b0, space1)
{
    float4 StartColor;
    float4 EndColor;
}

// ==================== TEXTURES ====================

Texture2D ParticleTexture : register(t0, space1);
SamplerState ParticleSampler : register(s0, space1);

// Texture atlas for animated particles
Texture2D AtlasTexture : register(t1, space1);

// ==================== VERTEX SHADER ====================

struct Particle
{
    float3 Position;
    float3 Velocity;
    float Life; // 0-1 normalized
    float Rotation;
    float RotationSpeed;
    float Size;
    uint RandomSeed;
};

StructuredBuffer<Particle> ParticleBuffer : register(t0);

struct VSInput
{
    uint VertexID : SV_VertexID;
    uint InstanceID : SV_InstanceID;
};

struct VSOutput
{
    float4 Position : SV_POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Color : COLOR;
    float Life : TEXCOORD1;
};

VSOutput VS(VSInput input)
{
    VSOutput output;
    
    // Get particle data
    Particle particle = ParticleBuffer[input.InstanceID];
    
    // Skip dead particles
    if (particle.Life <= 0.0)
    {
        output.Position = float4(0, 0, 0, 0);
        output.TexCoord = float2(0, 0);
        output.Color = float4(0, 0, 0, 0);
        output.Life = 0;
        return output;
    }
    
    // Generate billboard quad
    float2 quadVertices[4] = {
        float2(-0.5, -0.5),
        float2( 0.5, -0.5),
        float2(-0.5,  0.5),
        float2( 0.5,  0.5)
    };
    
    float2 quadUVs[4] = {
        float2(0, 1),
        float2(1, 1),
        float2(0, 0),
        float2(1, 0)
    };
    
    uint vertexIndex = input.VertexID % 4;
    float2 quadPos = quadVertices[vertexIndex];
    output.TexCoord = quadUVs[vertexIndex];
    
    // Apply rotation
    float cosR = cos(particle.Rotation);
    float sinR = sin(particle.Rotation);
    float2x2 rotMatrix = float2x2(cosR, -sinR, sinR, cosR);
    quadPos = mul(quadPos, rotMatrix);
    
    // Calculate size based on lifetime
    float size = lerp(StartSize, EndSize, 1.0 - particle.Life);
    size *= particle.Size;
    
    // Billboard the particle
    float3 worldPos = particle.Position;
    worldPos += CameraRight * quadPos.x * size;
    worldPos += CameraUp * quadPos.y * size;
    
    // Transform to clip space
    output.Position = mul(float4(worldPos, 1.0), ViewProjectionMatrix);
    
    // Calculate color based on lifetime
    output.Color = lerp(EndColor, StartColor, particle.Life);
    output.Life = particle.Life;
    
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
    
    // Skip dead particles
    if (input.Life <= 0.0)
        discard;
    
    // Sample particle texture
    float4 texColor = ParticleTexture.Sample(ParticleSampler, input.TexCoord);
    
    // Apply particle color
    output.Color = texColor * input.Color;
    
    // Soft particles (if depth buffer is available)
    #ifdef USE_SOFT_PARTICLES
    // Would need depth buffer access here
    // float sceneDepth = SceneDepthTexture.Sample(PointSampler, screenUV);
    // float particleDepth = input.Position.z;
    // float fade = saturate((sceneDepth - particleDepth) * SoftParticleDistance);
    // output.Color.a *= fade;
    #endif
    
    #ifdef USE_FOG
    float fogDistance = length(input.Position.xyz);
    float fogFactor = saturate((fogDistance - 100.0) / 900.0);
    output.Color.rgb = lerp(output.Color.rgb, float3(0.7, 0.7, 0.8), fogFactor * 0.5); // Lighter fog for particles
    #endif
    
    return output;
}