using Sedulous.Engine.Core;
using System;
using System.Collections;
using Sedulous.SceneGraph;
using Sedulous.Platform.Core;
using Sedulous.Engine.Renderer.GPU;
using Sedulous.RHI;
using Sedulous.Mathematics;
using Sedulous.RHI.VertexFormats;
//using Sedulous.Engine.Renderer.RHI.Shaders;
namespace Sedulous.Engine.Renderer.RHI;

using internal Sedulous.Engine.Renderer.RHI;

/*// Extension to integrate shader system into renderer
extension RHIRendererSubsystem
{
    private ShaderCache mShaderCache ~ delete _;
    
    // Initialize shader system
    private void InitializeShaderSystem()
    {
        mShaderCache = new ShaderCache(mGraphicsContext, mGraphicsContext.Logger);
        
        // Register built-in shader templates
        RegisterBuiltInShaders();
        
        // Warmup cache with common variants
        WarmupShaderCache();
    }
    
    private void RegisterBuiltInShaders()
    {
        // Register standard shader
        {
            var standardTemplate = new ShaderTemplate("Standard", "Assets/Shaders/Standard.hlsl");
            standardTemplate.SupportedFeatures = 
                .Skinning | .Instancing | .VertexColor | 
                .NormalMapping | .ParallaxMapping | 
                .AlphaTest | .AlphaBlend | 
                .ReceiveShadows | .Fog | 
                .Emission | .DetailTexture | .Reflection;
            
            standardTemplate.BaseDefines["LIGHT_MODEL"] = "PBR";
            
            mShaderCache.RegisterTemplate(standardTemplate);
        }
        
        // Register unlit shader
        {
            var unlitTemplate = new ShaderTemplate("Unlit", "Assets/Shaders/Unlit.hlsl");
            unlitTemplate.SupportedFeatures = 
                .Instancing | .VertexColor | 
                .AlphaTest | .AlphaBlend | .Fog;
            
            mShaderCache.RegisterTemplate(unlitTemplate);
        }
        
        // Register sprite shader
        {
            var spriteTemplate = new ShaderTemplate("Sprite", "Assets/Shaders/Sprite.hlsl");
            spriteTemplate.SupportedFeatures = 
                .Instancing | .AlphaBlend;
            
            mShaderCache.RegisterTemplate(spriteTemplate);
        }
        
        // Register particle shader
        {
            var particleTemplate = new ShaderTemplate("Particle", "Assets/Shaders/Particle.hlsl");
            particleTemplate.SupportedFeatures = 
                .AlphaBlend | .Fog;
            
            mShaderCache.RegisterTemplate(particleTemplate);
        }
        
        // Register shadow map shader
        {
            var shadowTemplate = new ShaderTemplate("ShadowMap", "Assets/Shaders/ShadowMap.hlsl");
            shadowTemplate.SupportedFeatures = 
                .Skinning | .Instancing | .AlphaTest;
            
            mShaderCache.RegisterTemplate(shadowTemplate);
        }
    }
    
    private void WarmupShaderCache()
    {
        var commonVariants = scope List<ShaderVariantKey>();
        
        // Standard shader variants
        commonVariants.Add(.("Standard", .None, 1)); // Basic
        commonVariants.Add(.("Standard", .NormalMapping, 1)); // With normal mapping
        commonVariants.Add(.("Standard", .NormalMapping | .ReceiveShadows, 4)); // Full featured
        
        // Unlit variants
        commonVariants.Add(.("Unlit", .None, 0));
        commonVariants.Add(.("Unlit", .AlphaBlend, 0));
        
        // Skinned variants
        commonVariants.Add(.("Standard", .Skinning | .NormalMapping, 1));
        
        // Shadow map variants
        commonVariants.Add(.("ShadowMap", .None, 0));
        commonVariants.Add(.("ShadowMap", .Skinning, 0));
        
        mShaderCache.WarmupCache(commonVariants);
    }
    
    // Get a shader variant for material
    public Result<ShaderVariant> GetShaderVariant(Material material, RenderContext context)
    {
        // Determine features based on material
        ShaderFeatures features = .None;
        
        // Check material properties
        if (material.Blending == .AlphaBlend)
            features |= .AlphaBlend;
        else if (material.Blending == .AlphaTest)
            features |= .AlphaTest;
            
        // Check textures
        if (material is PhongMaterial)
        {
            let phong = material as PhongMaterial;
            if (phong.NormalTexture.IsValid)
                features |= .NormalMapping;
        }
        else if (material is PBRMaterial)
        {
            let pbr = material as PBRMaterial;
            if (pbr.NormalTexture.IsValid)
                features |= .NormalMapping;
            if (pbr.EmissiveTexture.IsValid || pbr.EmissiveIntensity > 0)
                features |= .Emission;
        }
        
        // Check render context
        if (context.ReceiveShadows)
            features |= .ReceiveShadows;
        if (context.UseFog)
            features |= .Fog;
            
        // Build variant key
        var key = ShaderVariantKey
        {
            ShaderName = material.ShaderName,
            Features = features,
            LightCount = (uint32)context.LightCount
        };
        
        return mShaderCache.GetOrCompileVariant(key);
    }
    
    // Create pipeline state from shader variant
    public GraphicsPipelineState CreatePipelineFromVariant(
        ShaderVariant variant, 
        FrameBuffer targetFrameBuffer,
        Material material,
        LayoutDescription vertexLayout,
        ResourceLayout[] resourceLayouts)
    {
        var pipelineDesc = GraphicsPipelineDescription
        {
            Shaders = .()
            {
                VertexShader = variant.VertexShader,
                PixelShader = variant.PixelShader,
                GeometryShader = variant.GeometryShader,
                HullShader = variant.HullShader,
                DomainShader = variant.DomainShader
            },
            
            RenderStates = CreateRenderStates(material),
            InputLayouts = scope InputLayouts(){
				LayoutElements = scope List<LayoutDescription>()
					{
						vertexLayout
					}
			},
            ResourceLayouts = resourceLayouts,
            PrimitiveTopology = .TriangleList,
            Outputs = .CreateFromFrameBuffer(targetFrameBuffer)
        };
        
        return mGraphicsContext.Factory.CreateGraphicsPipeline(pipelineDesc);
    }
    
    private RenderStateDescription CreateRenderStates(Material material)
    {
        var states = RenderStateDescription.Default;
        
        // Rasterizer state
        switch (material.Culling)
        {
        case .None:
            states.RasterizerState.CullMode = .None;
            break;
        case .Front:
            states.RasterizerState.CullMode = .Front;
            break;
        case .Back:
            states.RasterizerState.CullMode = .Back;
            break;
        }
        
        // Depth state
        states.DepthStencilState.DepthEnable = material.DepthTest;
        states.DepthStencilState.DepthWriteMask = material.DepthWrite;
        states.DepthStencilState.DepthFunction = material.DepthTest ? .LessEqual : .Always;
        states.DepthStencilState.StencilEnable = false;
        states.DepthStencilState.StencilReadMask = 0xFF;
        states.DepthStencilState.StencilWriteMask = 0xFF;
        states.DepthStencilState.FrontFace = DepthStencilOperationDescription()
        {
            StencilFailOperation = .Keep,
            StencilDepthFailOperation = .Keep,
            StencilPassOperation = .Keep,
            StencilFunction = .Always
        };
        states.DepthStencilState.BackFace = states.DepthStencilState.FrontFace;
        
        // Blend state
        switch (material.Blending)
        {
        case .Opaque:
            states.BlendState.RenderTarget0.BlendEnable = false;
            states.BlendState.RenderTarget0.ColorWriteChannels = .All;
            break;
            
        case .AlphaTest:
            // Alpha test doesn't use blending, it discards pixels in the shader
            states.BlendState.RenderTarget0.BlendEnable = false;
            states.BlendState.RenderTarget0.ColorWriteChannels = .All;
            break;
            
        case .AlphaBlend:
            states.BlendState.RenderTarget0.BlendEnable = true;
            states.BlendState.RenderTarget0.SourceBlendColor = .SourceAlpha;
            states.BlendState.RenderTarget0.DestinationBlendColor = .InverseSourceAlpha;
            states.BlendState.RenderTarget0.BlendOperationColor = .Add;
            states.BlendState.RenderTarget0.SourceBlendAlpha = .One;
            states.BlendState.RenderTarget0.DestinationBlendAlpha = .InverseSourceAlpha;
            states.BlendState.RenderTarget0.BlendOperationAlpha = .Add;
            states.BlendState.RenderTarget0.ColorWriteChannels = .All;
            break;
            
        case .Additive:
            states.BlendState.RenderTarget0.BlendEnable = true;
            states.BlendState.RenderTarget0.SourceBlendColor = .One;
            states.BlendState.RenderTarget0.DestinationBlendColor = .One;
            states.BlendState.RenderTarget0.BlendOperationColor = .Add;
            states.BlendState.RenderTarget0.SourceBlendAlpha = .One;
            states.BlendState.RenderTarget0.DestinationBlendAlpha = .One;
            states.BlendState.RenderTarget0.BlendOperationAlpha = .Add;
            states.BlendState.RenderTarget0.ColorWriteChannels = .All;
            break;
            
        case .Multiply:
            states.BlendState.RenderTarget0.BlendEnable = true;
            states.BlendState.RenderTarget0.SourceBlendColor = .DestinationColor;
            states.BlendState.RenderTarget0.DestinationBlendColor = .Zero;
            states.BlendState.RenderTarget0.BlendOperationColor = .Add;
            states.BlendState.RenderTarget0.SourceBlendAlpha = .Zero;
            states.BlendState.RenderTarget0.DestinationBlendAlpha = .One;
            states.BlendState.RenderTarget0.BlendOperationAlpha = .Add;
            states.BlendState.RenderTarget0.ColorWriteChannels = .All;
            break;
        }
        
        return states;
    }
}

// Render context passed to shader variant selection
struct RenderContext
{
    public bool ReceiveShadows;
    public bool UseFog;
    public int32 LightCount;
    public bool IsDepthPass;
    public bool IsShadowPass;
}*/