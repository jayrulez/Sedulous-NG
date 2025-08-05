using System;
using System.Collections;
using Sedulous.Foundation.Core;
using Sedulous.RHI;

namespace Sedulous.Engine.Renderer.RHI.Shaders;

// Defines features that can be enabled/disabled in shaders
[Flags]
enum ShaderFeatures : uint32
{
    None = 0,
    
    // Vertex features
    Skinning = 1 << 0,
    Instancing = 1 << 1,
    VertexColor = 1 << 2,
    
    // Fragment features
    NormalMapping = 1 << 3,
    ParallaxMapping = 1 << 4,
    AlphaTest = 1 << 5,
    AlphaBlend = 1 << 6,
    
    // Lighting features
    ReceiveShadows = 1 << 7,
    CastShadows = 1 << 8,
    Fog = 1 << 9,
    
    // Material features
    Emission = 1 << 10,
    DetailTexture = 1 << 11,
    Reflection = 1 << 12,
    
    // Advanced features
    Tessellation = 1 << 13,
    GeometryShader = 1 << 14,
    
    // Rendering techniques
    DeferredShading = 1 << 15,
    ForwardPlus = 1 << 16,
}

// Represents a unique shader variant
struct ShaderVariantKey : IHashable
{
    public StringView ShaderName;
    public ShaderFeatures Features;
    public uint32 LightCount; // For forward rendering

	public this(StringView shaderName, ShaderFeatures features, uint32 lightCount)
	{
		this.ShaderName = shaderName;
		this.Features = features;
		this.LightCount = lightCount;
	}
    
    public int GetHashCode()
    {
        var hash = ShaderName.GetHashCode();
        hash = hash * 31 + Features.Underlying.GetHashCode();
        hash = hash * 31 + LightCount.GetHashCode();
        return hash;
    }
    
    public bool Equals(Object other)
    {
        if (other is ShaderVariantKey)
        {
            let otherKey = (ShaderVariantKey)other;
            return ShaderName == otherKey.ShaderName && 
                   Features == otherKey.Features &&
                   LightCount == otherKey.LightCount;
        }
        return false;
    }
}

// Compiled shader variant
class ShaderVariant
{
    public ShaderVariantKey Key;
    public Shader VertexShader;
    public Shader PixelShader;
    public Shader GeometryShader; // Optional
    public Shader HullShader; // Optional
    public Shader DomainShader; // Optional
    
    // Metadata about the variant
    public List<String> DefinesList = new .() ~ DeleteContainerAndItems!(_);
    public DateTime CompileTime;
    public uint32 VertexShaderSize;
    public uint32 PixelShaderSize;
    
    public ~this()
    {
        // Shaders are destroyed by the graphics context
    }
}