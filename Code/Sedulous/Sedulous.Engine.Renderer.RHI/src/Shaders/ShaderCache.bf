/*using Sedulous.RHI;
using Sedulous.Logging.Abstractions;
using System.Collections;
using System;
namespace Sedulous.Engine.Renderer.RHI.Shaders;

using internal Sedulous.Engine.Renderer.RHI;

// Manages shader compilation and caching
class ShaderCache
{
    private GraphicsContext mGraphicsContext;
    private ILogger mLogger;
    
    // Shader templates
    private Dictionary<StringView, ShaderTemplate> mTemplates = new .() ~ delete _;
    
    // Compiled variants
    private Dictionary<ShaderVariantKey, ShaderVariant> mVariants = new .() ~ DeleteDictionaryAndValues!(_);
    
    // Compilation queue for async compilation
    private List<ShaderVariantKey> mCompilationQueue = new .() ~ delete _;
    
    // Statistics
    public int TotalVariants => mVariants.Count;
    public int TemplateCount => mTemplates.Count;
    
    public this(GraphicsContext context, ILogger logger)
    {
        mGraphicsContext = context;
        mLogger = logger;
    }
    
    // Register a shader template
    public Result<void> RegisterTemplate(ShaderTemplate template)
    {
        if (mTemplates.ContainsKey(template.Name))
        {
            mLogger.LogWarning("Shader template '{}' already registered", template.Name);
            return .Err;
        }
        
        // Load the source
        if (template.LoadSource() case .Err)
        {
            mLogger.LogError("Failed to load shader source: {}", template.SourcePath);
            return .Err;
        }
        
        mTemplates[template.Name] = template;
        mLogger.LogInformation("Registered shader template: {}", template.Name);
        return .Ok;
    }
    
    // Get or compile a shader variant
    public Result<ShaderVariant> GetOrCompileVariant(ShaderVariantKey key)
    {
        // Check if already compiled
        if (mVariants.TryGetValue(key, let variant))
            return .Ok(variant);
            
        // Find the template
        if (!mTemplates.TryGetValue(key.ShaderName, let template))
        {
            mLogger.LogError("Shader template '{}' not found", key.ShaderName);
            return .Err;
        }
        
        // Check if features are supported
        if (!template.SupportsFeatures(key.Features))
        {
            mLogger.LogError("Shader '{}' doesn't support features: {}", key.ShaderName, key.Features);
            return .Err;
        }
        
        // Compile the variant
        return CompileVariant(template, key);
    }
    
    // Compile a specific variant
    private Result<ShaderVariant> CompileVariant(ShaderTemplate template, ShaderVariantKey key)
    {
        mLogger.LogInformation("Compiling shader variant: {} with features {}", key.ShaderName, key.Features);
        
        let variant = new ShaderVariant();
        variant.Key = key;
        variant.CompileTime = DateTime.Now;
        
        // Generate source with defines
        String source = scope .();
        template.GenerateSource(key.Features, key.LightCount, source);
        
        // Add defines to variant metadata
        for (var (define, value) in template.BaseDefines)
        {
            variant.DefinesList.Add(new String(define));
        }
        
        // Compile vertex shader
        if (!template.VertexEntry.IsEmpty)
        {
            var result = CompileStage(source, template.VertexEntry, .Vertex);
            if (result case .Ok(let shader))
            {
                variant.VertexShader = shader;
            }
            else
            {
                delete variant;
                return .Err;
            }
        }
        
        // Compile pixel shader
        if (!template.PixelEntry.IsEmpty)
        {
            var result = CompileStage(source, template.PixelEntry, .Pixel);
            if (result case .Ok(let shader))
            {
                variant.PixelShader = shader;
            }
            else
            {
                // Clean up vertex shader
                if (variant.VertexShader != null)
                    mGraphicsContext.Factory.DestroyShader(ref variant.VertexShader);
                delete variant;
                return .Err;
            }
        }
        
        // Compile optional stages
        if (key.Features.HasFlag(.GeometryShader) && !template.GeometryEntry.IsEmpty)
        {
            var result = CompileStage(source, template.GeometryEntry, .Geometry);
            if (result case .Ok(let shader))
                variant.GeometryShader = shader;
        }
        
        if (key.Features.HasFlag(.Tessellation))
        {
            if (!template.HullEntry.IsEmpty)
            {
                var result = CompileStage(source, template.HullEntry, .Hull);
                if (result case .Ok(let shader))
                    variant.HullShader = shader;
            }
            
            if (!template.DomainEntry.IsEmpty)
            {
                var result = CompileStage(source, template.DomainEntry, .Domain);
                if (result case .Ok(let shader))
                    variant.DomainShader = shader;
            }
        }
        
        // Cache the variant
        mVariants[key] = variant;
        
        mLogger.LogInformation("Successfully compiled shader variant (VS: {} bytes, PS: {} bytes)", 
            variant.VertexShaderSize, variant.PixelShaderSize);
        
        return .Ok(variant);
    }
    
    // Compile a single shader stage
    private Result<Shader> CompileStage(StringView source, StringView entryPoint, ShaderStages stage)
    {
        var byteCode = scope List<uint8>();
        
        // Use the extension method from RHIRendererSubsystemExtensions
        ShaderManager.CompileShaderFromSource(
            mGraphicsContext, 
            scope String(source), 
            stage, 
            scope String(entryPoint), 
            byteCode
        );
        
        if (byteCode.Count == 0)
        {
            mLogger.LogError("Failed to compile {} shader stage: {}", stage, entryPoint);
            return .Err;
        }
        
        // Create shader object
        var shaderBytes = scope uint8[byteCode.Count];
        byteCode.CopyTo(shaderBytes);
        
        var shaderDesc = ShaderDescription(stage, scope String(entryPoint), shaderBytes);
        var shader = mGraphicsContext.Factory.CreateShader(shaderDesc);
        
        if (shader == null)
        {
            mLogger.LogError("Failed to create {} shader object", stage);
            return .Err;
        }
        
        return .Ok(shader);
    }
    
    // Precompile common variants
    public void WarmupCache(List<ShaderVariantKey> commonVariants)
    {
        mLogger.LogInformation("Warming up shader cache with {} variants", commonVariants.Count);
        
        for (var key in commonVariants)
        {
            GetOrCompileVariant(key);
        }
    }
    
    // Clean up unused variants
    public void PruneCache(TimeSpan maxAge)
    {
        var now = DateTime.Now;
        var toRemove = scope List<ShaderVariantKey>();
        
        for (var (key, variant) in mVariants)
        {
            if (now - variant.CompileTime > maxAge)
            {
                toRemove.Add(key);
            }
        }
        
        for (var key in toRemove)
        {
            if (mVariants.TryGetValue(key, let variant))
            {
                DestroyVariant(variant);
                mVariants.Remove(key);
            }
        }
        
        if (toRemove.Count > 0)
        {
            mLogger.LogInformation("Pruned {} old shader variants", toRemove.Count);
        }
    }
    
    // Destroy a variant
    private void DestroyVariant(ShaderVariant variant)
    {
        if (variant.VertexShader != null)
            mGraphicsContext.Factory.DestroyShader(ref variant.VertexShader);
        if (variant.PixelShader != null)
            mGraphicsContext.Factory.DestroyShader(ref variant.PixelShader);
        if (variant.GeometryShader != null)
            mGraphicsContext.Factory.DestroyShader(ref variant.GeometryShader);
        if (variant.HullShader != null)
            mGraphicsContext.Factory.DestroyShader(ref variant.HullShader);
        if (variant.DomainShader != null)
            mGraphicsContext.Factory.DestroyShader(ref variant.DomainShader);
            
        delete variant;
    }
    
    // Clear all cached variants
    public void ClearCache()
    {
        for (var (key, variant) in mVariants)
        {
            DestroyVariant(variant);
        }
        mVariants.Clear();
        
        mLogger.LogInformation("Cleared shader cache");
    }
}*/