using System;
using System.Collections;
using System.IO;
namespace Sedulous.Engine.Renderer.RHI.Shaders;

// Base shader template that generates variants
class ShaderTemplate
{
    public String Name = new .() ~ delete _;
    public String SourcePath = new .() ~ delete _; // Path to .hlsl file
    
    // Entry points
    public String VertexEntry = new .("VS") ~ delete _;
    public String PixelEntry = new .("PS") ~ delete _;
    public String GeometryEntry = new .() ~ delete _;
    public String HullEntry = new .() ~ delete _;
    public String DomainEntry = new .() ~ delete _;
    
    // Features this shader supports
    public ShaderFeatures SupportedFeatures;
    
    // Base defines that are always included
    public Dictionary<String, String> BaseDefines = new .() ~ DeleteDictionaryAndKeysAndValues!(_);
    
    // Per-feature defines
    public Dictionary<ShaderFeatures, List<String>> FeatureDefines = new .() ~ DeleteDictionaryAndValues!(_);
    
    // Cached source code
    private String mCachedSource = new .() ~ delete _;
    private DateTime mLastModified;
    
    public this(StringView name, StringView sourcePath)
    {
        Name.Set(name);
        SourcePath.Set(sourcePath);
        SetupFeatureDefines();
    }
    
    private void SetupFeatureDefines()
    {
        // Setup common feature defines
        FeatureDefines[.Skinning] = new .() {"USE_SKINNING"};
        FeatureDefines[.Instancing] = new .() {"USE_INSTANCING"};
        FeatureDefines[.VertexColor] = new .() {"USE_VERTEX_COLOR"};
        FeatureDefines[.NormalMapping] = new .() {"USE_NORMAL_MAPPING"};
        FeatureDefines[.ParallaxMapping] = new .() {"USE_PARALLAX_MAPPING"};
        FeatureDefines[.AlphaTest] = new .() {"USE_ALPHA_TEST"};
        FeatureDefines[.AlphaBlend] = new .() {"USE_ALPHA_BLEND"};
        FeatureDefines[.ReceiveShadows] = new .() {"RECEIVE_SHADOWS"};
        FeatureDefines[.Fog] = new .() {"USE_FOG"};
        FeatureDefines[.Emission] = new .() {"USE_EMISSION"};
        FeatureDefines[.DetailTexture] = new .() {"USE_DETAIL_TEXTURE"};
        FeatureDefines[.Reflection] = new .() {"USE_REFLECTION"};
    }
    
    // Load or reload source from disk
    public Result<void> LoadSource()
    {
        if (!File.Exists(SourcePath))
            return .Err;
            
        let info = File.GetLastWriteTime(SourcePath);
        if (info case .Ok(let lastModified))
        {
            if (lastModified != mLastModified || mCachedSource.IsEmpty)
            {
                if (File.ReadAllText(SourcePath, mCachedSource) case .Err)
                    return .Err;
                mLastModified = lastModified;
            }
        }
        
        return .Ok;
    }
    
    // Generate shader source with specific features enabled
    public void GenerateSource(ShaderFeatures features, uint32 lightCount, String outSource)
    {
        outSource.Clear();
        
        // Add header with defines
        outSource.Append("// Auto-generated shader variant\n");
        outSource.Append("// Features: ");
        outSource.AppendF("{}\n", features);
        outSource.Append("\n");
        
        // Add base defines
        for (var (key, value) in BaseDefines)
        {
            outSource.AppendF("#define {} {}\n", key, value);
        }
        
        // Add feature-specific defines
        for (var feature in Enum.GetValues<ShaderFeatures>())
        {
            if (features.HasFlag(feature) && FeatureDefines.ContainsKey(feature))
            {
                for (var define in FeatureDefines[feature])
                {
                    outSource.AppendF("#define {}\n", define);
                }
            }
        }
        
        // Add light count for forward rendering
        if (lightCount > 0)
        {
            outSource.AppendF("#define MAX_LIGHTS {}\n", lightCount);
        }
        
        outSource.Append("\n");
        
        // Add the actual shader source
        outSource.Append(mCachedSource);
    }
    
    // Check if this template supports the requested features
    public bool SupportsFeatures(ShaderFeatures features)
    {
        return (features & ~SupportedFeatures) == 0;
    }
}