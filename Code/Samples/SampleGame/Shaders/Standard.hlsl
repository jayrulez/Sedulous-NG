// Standard uber shader that supports multiple lighting models
// Features are enabled via defines

// ==================== CONSTANT BUFFERS ====================

cbuffer PerFrameData : register(b0)
{
    float4x4 ViewMatrix;
    float4x4 ProjectionMatrix;
    float4x4 ViewProjectionMatrix;
    float3 CameraPosition;
    float Time;
    float3 AmbientLight;
    float _PerFramePad1;
}

cbuffer PerObjectData : register(b1)
{
    float4x4 WorldMatrix;
    float4x4 WorldViewProjectionMatrix;
    float4x4 NormalMatrix; // For non-uniform scaling
}

#ifdef USE_SKINNING
cbuffer SkinningData : register(b2)
{
    float4x4 BoneMatrices[128];
}
#endif

cbuffer MaterialData : register(b0, space1)
{
    float4 BaseColor;
    float4 EmissiveColor;
    float Metallic;
    float Roughness;
    float AmbientOcclusion;
    float AlphaCutoff;
    float NormalScale;
    float ParallaxScale;
    float _MaterialPad0;
    float _MaterialPad1;
}

#ifdef MAX_LIGHTS
struct LightData
{
    float3 Position;
    float Range;
    float3 Direction;
    float SpotAngle;
    float3 Color;
    float Intensity;
    uint Type; // 0=Directional, 1=Point, 2=Spot
    uint CastsShadows;
    float _LightPad0;
    float _LightPad1;
};

cbuffer LightingData : register(b3)
{
    LightData Lights[MAX_LIGHTS];
    uint LightCount;
    uint _LightingPad0;
    uint _LightingPad1;
    uint _LightingPad2;
}
#endif

// ==================== TEXTURES ====================

Texture2D BaseColorTexture : register(t0, space1);
SamplerState BaseColorSampler : register(s0, space1);

#ifdef USE_NORMAL_MAPPING
Texture2D NormalTexture : register(t1, space1);
SamplerState NormalSampler : register(s1, space1);
#endif

Texture2D MetallicRoughnessTexture : register(t2, space1);
SamplerState MetallicRoughnessSampler : register(s2, space1);

#ifdef USE_EMISSION
Texture2D EmissiveTexture : register(t3, space1);
SamplerState EmissiveSampler : register(s3, space1);
#endif

#ifdef USE_DETAIL_TEXTURE
Texture2D DetailTexture : register(t4, space1);
SamplerState DetailSampler : register(s4, space1);
#endif

#ifdef RECEIVE_SHADOWS
Texture2DArray ShadowMap : register(t5);
SamplerComparisonState ShadowSampler : register(s5);
#endif

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
    float3 WorldPos : WORLDPOS;
    float3 Normal : NORMAL;
    float2 TexCoord : TEXCOORD0;
    #ifdef USE_VERTEX_COLOR
    float4 Color : COLOR;
    #endif
    
    #ifdef USE_NORMAL_MAPPING
    float3 Tangent : TANGENT;
    float3 Bitangent : BITANGENT;
    #endif
    
    #ifdef USE_PARALLAX_MAPPING
    float3 TangentViewPos : TEXCOORD1;
    float3 TangentFragPos : TEXCOORD2;
    #endif
};

VSOutput VS(VSInput input)
{
    VSOutput output;
    
    // Apply skinning if enabled
    float4 position = float4(input.Position, 1.0);
    float3 normal = input.Normal;
    #ifdef USE_NORMAL_MAPPING
    float3 tangent = input.Tangent;
    #endif
    
    #ifdef USE_SKINNING
    float4x4 skinMatrix = 
        BoneMatrices[input.BoneIndices.x] * input.BoneWeights.x +
        BoneMatrices[input.BoneIndices.y] * input.BoneWeights.y +
        BoneMatrices[input.BoneIndices.z] * input.BoneWeights.z +
        BoneMatrices[input.BoneIndices.w] * input.BoneWeights.w;
    
    position = mul(position, skinMatrix);
    normal = mul(normal, (float3x3)skinMatrix);
    #ifdef USE_NORMAL_MAPPING
    tangent = mul(tangent, (float3x3)skinMatrix);
    #endif
    #endif
    
    // Apply instancing if enabled
    #ifdef USE_INSTANCING
    float4x4 worldMatrix = input.InstanceMatrix;
    #else
    float4x4 worldMatrix = WorldMatrix;
    #endif
    
    // Transform to world space
    output.WorldPos = mul(position, worldMatrix).xyz;
    output.Normal = normalize(mul(normal, (float3x3)NormalMatrix));
    
    // Transform to clip space
    output.Position = mul(float4(output.WorldPos, 1.0), ViewProjectionMatrix);
    
    // Pass through texture coordinates
    output.TexCoord = input.TexCoord;
    
    #ifdef USE_VERTEX_COLOR
    output.Color = input.Color;
    #endif
    
    #ifdef USE_NORMAL_MAPPING
    output.Tangent = normalize(mul(tangent, (float3x3)worldMatrix));
    output.Bitangent = cross(output.Normal, output.Tangent);
    #endif
    
    #ifdef USE_PARALLAX_MAPPING
    float3x3 TBN = transpose(float3x3(output.Tangent, output.Bitangent, output.Normal));
    output.TangentViewPos = mul(CameraPosition, TBN);
    output.TangentFragPos = mul(output.WorldPos, TBN);
    #endif
    
    return output;
}

// ==================== PIXEL SHADER ====================

struct PSOutput
{
    float4 Color : SV_TARGET0;
};

// Helper functions
float3 GetNormal(VSOutput input)
{
    #ifdef USE_NORMAL_MAPPING
    float3 normalMap = NormalTexture.Sample(NormalSampler, input.TexCoord).xyz;
    normalMap = normalMap * 2.0 - 1.0;
    normalMap.xy *= NormalScale;
    
    float3x3 TBN = float3x3(
        normalize(input.Tangent),
        normalize(input.Bitangent),
        normalize(input.Normal)
    );
    
    return normalize(mul(normalMap, TBN));
    #else
    return normalize(input.Normal);
    #endif
}

float2 GetParallaxOffset(VSOutput input)
{
    #ifdef USE_PARALLAX_MAPPING
    float3 viewDir = normalize(input.TangentViewPos - input.TangentFragPos);
    float height = 1.0 - NormalTexture.Sample(NormalSampler, input.TexCoord).a;
    return viewDir.xy * (height * ParallaxScale) / viewDir.z;
    #else
    return float2(0, 0);
    #endif
}

// PBR calculations
float DistributionGGX(float3 N, float3 H, float roughness)
{
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH * NdotH;
    
    float num = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = 3.14159265359 * denom * denom;
    
    return num / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r * r) / 8.0;
    
    float num = NdotV;
    float denom = NdotV * (1.0 - k) + k;
    
    return num / denom;
}

float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2 = GeometrySchlickGGX(NdotV, roughness);
    float ggx1 = GeometrySchlickGGX(NdotL, roughness);
    
    return ggx1 * ggx2;
}

float3 FresnelSchlick(float cosTheta, float3 F0)
{
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

PSOutput PS(VSOutput input)
{
    PSOutput output;
    
    // Get parallax offset
    float2 texCoord = input.TexCoord + GetParallaxOffset(input);
    
    // Sample textures
    float4 baseColor = BaseColorTexture.Sample(BaseColorSampler, texCoord) * BaseColor;
    
    #ifdef USE_VERTEX_COLOR
    baseColor *= input.Color;
    #endif
    
    #ifdef USE_ALPHA_TEST
    if (baseColor.a < AlphaCutoff)
        discard;
    #endif
    
    // Get material properties
    float2 metallicRoughness = MetallicRoughnessTexture.Sample(MetallicRoughnessSampler, texCoord).bg;
    float metallic = metallicRoughness.x * Metallic;
    float roughness = metallicRoughness.y * Roughness;
    float ao = AmbientOcclusion;
    
    // Get normal
    float3 N = GetNormal(input);
    float3 V = normalize(CameraPosition - input.WorldPos);
    
    // Calculate F0 (base reflectivity)
    float3 F0 = float3(0.04, 0.04, 0.04);
    F0 = lerp(F0, baseColor.rgb, metallic);
    
    // Initialize lighting accumulation
    float3 Lo = float3(0.0, 0.0, 0.0);
    
    #ifdef MAX_LIGHTS
    // Process each light
    for (uint i = 0; i < LightCount; i++)
    {
        LightData light = Lights[i];
        
        // Calculate light direction and attenuation
        float3 L;
        float attenuation = 1.0;
        
        if (light.Type == 0) // Directional
        {
            L = normalize(-light.Direction);
        }
        else // Point or Spot
        {
            L = normalize(light.Position - input.WorldPos);
            float distance = length(light.Position - input.WorldPos);
            attenuation = 1.0 / (distance * distance);
            attenuation *= saturate(1.0 - (distance / light.Range));
            
            if (light.Type == 2) // Spot
            {
                float theta = dot(L, normalize(-light.Direction));
                float epsilon = cos(light.SpotAngle * 0.5) - cos(light.SpotAngle * 0.5 * 1.2);
                float spotAttenuation = clamp((theta - cos(light.SpotAngle * 0.5 * 1.2)) / epsilon, 0.0, 1.0);
                attenuation *= spotAttenuation;
            }
        }
        
        // Skip if no contribution
        if (attenuation <= 0.0)
            continue;
        
        // Calculate radiance
        float3 H = normalize(V + L);
        float3 radiance = light.Color * light.Intensity * attenuation;
        
        // Cook-Torrance BRDF
        float NDF = DistributionGGX(N, H, roughness);
        float G = GeometrySmith(N, V, L, roughness);
        float3 F = FresnelSchlick(max(dot(H, V), 0.0), F0);
        
        float3 kS = F;
        float3 kD = float3(1.0, 1.0, 1.0) - kS;
        kD *= 1.0 - metallic;
        
        float3 numerator = NDF * G * F;
        float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001;
        float3 specular = numerator / denominator;
        
        // Add to outgoing radiance Lo
        float NdotL = max(dot(N, L), 0.0);
        Lo += (kD * baseColor.rgb / 3.14159265359 + specular) * radiance * NdotL;
    }
    #endif
    
    // Ambient lighting
    float3 ambient = AmbientLight * baseColor.rgb * ao;
    
    // Emission
    float3 emission = EmissiveColor.rgb;
    #ifdef USE_EMISSION
    emission *= EmissiveTexture.Sample(EmissiveSampler, texCoord).rgb;
    #endif
    
    // Final color
    float3 color = ambient + Lo + emission;
    
    // Tone mapping and gamma correction
    color = color / (color + float3(1.0, 1.0, 1.0));
    color = pow(color, float3(1.0/2.2, 1.0/2.2, 1.0/2.2));
    
    output.Color = float4(color, baseColor.a);
    
    #ifdef USE_FOG
    // Simple linear fog
    float fogDistance = length(input.WorldPos - CameraPosition);
    float fogFactor = saturate((fogDistance - 100.0) / 900.0); // Fog from 100 to 1000 units
    output.Color.rgb = lerp(output.Color.rgb, float3(0.7, 0.7, 0.8), fogFactor);
    #endif
    
    return output;
}