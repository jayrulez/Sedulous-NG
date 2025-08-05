using Sedulous.Mathematics;
using System;
using Sedulous.Engine.Renderer.RHI.Shaders;
using System.Collections;
using Sedulous.RHI;
namespace Sedulous.Engine.Renderer.RHI;

// Defines a type of material (PBR, Phong, Unlit, etc.)
class MaterialTemplate
{
    public String Name = new .() ~ delete _;
    public String Description = new .() ~ delete _;
    
    // Shader configuration
    public String ShaderName = new .() ~ delete _;
    public ShaderFeatures RequiredFeatures;
    public ShaderFeatures OptionalFeatures;
    
    // Parameters
    public List<MaterialParameterGroup> ParameterGroups = new .() ~ DeleteContainerAndItems!(_);
    public Dictionary<StringView, MaterialParameter> ParameterLookup = new .() ~ delete _;
    
    // Constant buffer layout
    public uint32 ConstantBufferSize;
    public List<LayoutElementDescription> ResourceLayoutElements = new .() ~ delete _;
    
    // Render state defaults
    public Material.BlendMode DefaultBlendMode = .Opaque;
    public Material.CullMode DefaultCullMode = .Back;
    public bool DefaultDepthWrite = true;
    public bool DefaultDepthTest = true;
    
    // Validation
    public delegate Result<void> ValidateFunction(MaterialInstance);
    public ValidateFunction Validate ~ delete _;
    
    public this(StringView name)
    {
        Name.Set(name);
    }
    
    // Add a parameter to the template
    public MaterialParameter AddParameter(StringView groupName, MaterialParameter param)
    {
        // Find or create group
        MaterialParameterGroup group = null;
        for (var g in ParameterGroups)
        {
            if (g.Name == groupName)
            {
                group = g;
                break;
            }
        }
        
        if (group == null)
        {
            group = new MaterialParameterGroup(groupName);
            ParameterGroups.Add(group);
        }
        
        group.Parameters.Add(param);
        ParameterLookup[param.Name] = param;
        
        return param;
    }
    
    // Calculate constant buffer layout
    public void CalculateLayout()
    {
        uint32 currentOffset = 0;
        List<MaterialParameter> cbufferParams = scope .();
        List<MaterialParameter> textureParams = scope .();
        
        // Separate parameters by type
        for (var group in ParameterGroups)
        {
            for (var param in group.Parameters)
            {
                if (param.IsTexture())
                    textureParams.Add(param);
                else
                    cbufferParams.Add(param);
            }
        }
        
        // Layout constant buffer parameters (with proper alignment)
        for (var param in cbufferParams)
        {
            // Align offset based on type
            uint32 alignment = GetAlignment(param.Type);
            currentOffset = AlignUp(currentOffset, alignment);
            
            param.Offset = currentOffset;
            currentOffset += param.Size;
        }
        
        ConstantBufferSize = AlignUp(currentOffset, 16); // Constant buffers must be 16-byte aligned
        
        // Assign texture slots
        uint32 textureSlot = 0;
        for (var param in textureParams)
        {
            param.TextureSlot = textureSlot++;
        }
        
        // Build resource layout
        ResourceLayoutElements.Clear();
        
        // Constant buffer (if needed)
        if (ConstantBufferSize > 0)
        {
            ResourceLayoutElements.Add(
                LayoutElementDescription(0, .ConstantBuffer, .Pixel, false, ConstantBufferSize)
            );
        }
        
        // Textures and samplers
        for (var param in textureParams)
        {
            ResourceLayoutElements.Add(
                LayoutElementDescription(param.TextureSlot, .Texture, .Pixel)
            );
            ResourceLayoutElements.Add(
                LayoutElementDescription(param.TextureSlot, .Sampler, .Pixel)
            );
        }
    }
    
    private static uint32 GetAlignment(MaterialParameterType type)
    {
        switch (type)
        {
        case .Float, .Int, .Bool: return 4;
        case .Float2: return 8;
        case .Float3: return 16; // Vectors are 16-byte aligned in HLSL
        case .Float4, .Color: return 16;
        case .Matrix: return 16;
        default: return 4;
        }
    }
    
    private static uint32 AlignUp(uint32 value, uint32 alignment)
    {
        return ((value + alignment - 1) / alignment) * alignment;
    }
    
    // Create a material instance from this template
    public MaterialInstance CreateInstance()
    {
        return new MaterialInstance(this);
    }
}

// Factory for creating standard material templates
static class MaterialTemplateFactory
{
    public static MaterialTemplate CreatePBRTemplate()
    {
        var template = new MaterialTemplate("PBR");
        template.Description.Set("Physically Based Rendering material");
        template.ShaderName.Set("Standard");
        template.RequiredFeatures = .None;
        template.OptionalFeatures = .NormalMapping | .ParallaxMapping | .Emission | .AlphaTest | .AlphaBlend;
        
        // Base parameters
        var baseGroup = "Base";
        template.AddParameter(baseGroup, new .("BaseColor", .Color)
            {
                DefaultValue = Variant.Create(Color.White.ToVector4()),
                SemanticHint = "BaseColor",
                DisplayName = "Base Color"
            });
        
        template.AddParameter(baseGroup, new .("BaseColorTexture", .Texture2D)
            {
                SemanticHint = "BaseColor",
                DisplayName = "Base Color Map"
            });
        
        template.AddParameter(baseGroup, new .("AlphaCutoff", .Float)
            {
                DefaultValue = Variant.Create(0.5f),
                MinValue = 0.0f,
                MaxValue = 1.0f,
                DisplayName = "Alpha Cutoff"
            });
        
        // Metallic/Roughness
        var surfaceGroup = "Surface";
        template.AddParameter(surfaceGroup, new .("Metallic", .Float)
            {
                DefaultValue = Variant.Create(0.0f),
                MinValue = 0.0f,
                MaxValue = 1.0f,
                DisplayName = "Metallic"
            });
        
        template.AddParameter(surfaceGroup, new .("Roughness", .Float)
            {
                DefaultValue = Variant.Create(0.5f),
                MinValue = 0.0f,
                MaxValue = 1.0f,
                DisplayName = "Roughness"
            });
        
        template.AddParameter(surfaceGroup, new .("MetallicRoughnessTexture", .Texture2D)
            {
                SemanticHint = "MetallicRoughness",
                DisplayName = "Metallic/Roughness Map",
                Tooltip = "B: Metallic, G: Roughness"
            });
        
        // Normal mapping
        var normalGroup = "Normal";
        template.AddParameter(normalGroup, new .("NormalTexture", .Texture2D)
            {
                SemanticHint = "Normal",
                DisplayName = "Normal Map"
            });
        
        template.AddParameter(normalGroup, new .("NormalScale", .Float)
            {
                DefaultValue = Variant.Create(1.0f),
                MinValue = 0.0f,
                MaxValue = 2.0f,
                DisplayName = "Normal Intensity"
            });
        
        // Emission
        var emissionGroup = "Emission";
        template.AddParameter(emissionGroup, new .("EmissiveColor", .Color)
            {
                DefaultValue = Variant.Create(Color.Black.ToVector4()),
                SemanticHint = "Emission",
                DisplayName = "Emissive Color"
            });
        
        template.AddParameter(emissionGroup, new .("EmissiveTexture", .Texture2D)
            {
                SemanticHint = "Emission",
                DisplayName = "Emissive Map"
            });
        
        // Ambient Occlusion
        template.AddParameter(surfaceGroup, new .("AmbientOcclusion", .Float)
            {
                DefaultValue = Variant.Create(1.0f),
                MinValue = 0.0f,
                MaxValue = 1.0f,
                DisplayName = "Ambient Occlusion"
            });
        
        template.AddParameter(surfaceGroup, new .("AmbientOcclusionTexture", .Texture2D)
            {
                SemanticHint = "AmbientOcclusion",
                DisplayName = "AO Map"
            });
        
        // Parallax
        var parallaxGroup = "Parallax";
        template.AddParameter(parallaxGroup, new .("ParallaxScale", .Float)
            {
                DefaultValue = Variant.Create(0.05f),
                MinValue = 0.0f,
                MaxValue = 0.1f,
                DisplayName = "Parallax Scale"
            });
        
        template.CalculateLayout();
        
        // Validation
        template.Validate = new (instance) =>
        {
            // Check that metallic and roughness are in valid range
            if (let metallic = instance.GetFloat("Metallic"))
            {
                if (metallic < 0.0f || metallic > 1.0f)
                    return .Err;
            }
            
            if (let roughness = instance.GetFloat("Roughness"))
            {
                if (roughness < 0.0f || roughness > 1.0f)
                    return .Err;
            }
            
            return .Ok;
        };
        
        return template;
    }
    
    public static MaterialTemplate CreatePhongTemplate()
    {
        var template = new MaterialTemplate("Phong");
        template.Description.Set("Classic Phong shading model");
        template.ShaderName.Set("Standard"); // Can use same shader with different defines
        template.RequiredFeatures = .None; // Will use different lighting calculation
        template.OptionalFeatures = .NormalMapping | .AlphaTest | .AlphaBlend;
        
        // Base parameters
        var baseGroup = "Base";
        template.AddParameter(baseGroup, new .("DiffuseColor", .Color)
            {
                DefaultValue = Variant.Create(Color.White.ToVector4()),
                DisplayName = "Diffuse Color"
            });
        
        template.AddParameter(baseGroup, new .("DiffuseTexture", .Texture2D)
            {
                DisplayName = "Diffuse Map"
            });
        
        // Specular
        var specularGroup = "Specular";
        template.AddParameter(specularGroup, new .("SpecularColor", .Color)
            {
                DefaultValue = Variant.Create(Vector4(0.5f, 0.5f, 0.5f, 1.0f)),
                DisplayName = "Specular Color"
            });
        
        template.AddParameter(specularGroup, new .("SpecularTexture", .Texture2D)
            {
                DisplayName = "Specular Map"
            });
        
        template.AddParameter(specularGroup, new .("Shininess", .Float)
            {
                DefaultValue = Variant.Create(32.0f),
                MinValue = 1.0f,
                MaxValue = 128.0f,
                DisplayName = "Shininess"
            });
        
        // Ambient
        template.AddParameter(baseGroup, new .("AmbientColor", .Color)
            {
                DefaultValue = Variant.Create(Vector4(0.2f, 0.2f, 0.2f, 1.0f)),
                DisplayName = "Ambient Color"
            });
        
        // Normal mapping
        var normalGroup = "Normal";
        template.AddParameter(normalGroup, new .("NormalTexture", .Texture2D)
            {
                DisplayName = "Normal Map"
            });
        
        template.AddParameter(normalGroup, new .("NormalScale", .Float)
            {
                DefaultValue = Variant.Create(1.0f),
                MinValue = 0.0f,
                MaxValue = 2.0f,
                DisplayName = "Normal Intensity"
            });
        
        template.CalculateLayout();
        
        return template;
    }
    
    public static MaterialTemplate CreateUnlitTemplate()
    {
        var template = new MaterialTemplate("Unlit");
        template.Description.Set("Unlit material with no lighting calculations");
        template.ShaderName.Set("Unlit");
        template.RequiredFeatures = .None;
        template.OptionalFeatures = .AlphaTest | .AlphaBlend | .VertexColor;
        
        var baseGroup = "Base";
        template.AddParameter(baseGroup, new .("TintColor", .Color)
            {
                DefaultValue = Variant.Create(Color.White.ToVector4()),
                DisplayName = "Tint Color"
            });
        
        template.AddParameter(baseGroup, new .("MainTexture", .Texture2D)
            {
                DisplayName = "Texture"
            });
        
        template.AddParameter(baseGroup, new .("AlphaCutoff", .Float)
            {
                DefaultValue = Variant.Create(0.5f),
                MinValue = 0.0f,
                MaxValue = 1.0f,
                DisplayName = "Alpha Cutoff"
            });
        
        template.CalculateLayout();
        
        return template;
    }
    
    public static MaterialTemplate CreateSpriteTemplate()
    {
        var template = new MaterialTemplate("Sprite");
        template.Description.Set("2D sprite material");
        template.ShaderName.Set("Sprite");
        template.RequiredFeatures = .None;
        template.OptionalFeatures = .Instancing;
        template.DefaultBlendMode = .AlphaBlend;
        template.DefaultDepthWrite = false;
        
        var baseGroup = "Base";
        template.AddParameter(baseGroup, new .("TintColor", .Color)
            {
                DefaultValue = Variant.Create(Color.White.ToVector4()),
                DisplayName = "Tint"
            });
        
        template.AddParameter(baseGroup, new .("SpriteTexture", .Texture2D)
            {
                DisplayName = "Sprite"
            });
        
        template.CalculateLayout();
        
        return template;
    }
    
    public static MaterialTemplate CreateParticleTemplate()
    {
        var template = new MaterialTemplate("Particle");
        template.Description.Set("GPU particle material");
        template.ShaderName.Set("Particle");
        template.RequiredFeatures = .None;
        template.OptionalFeatures = .AlphaBlend | .Fog;
        template.DefaultBlendMode = .AlphaBlend;
        template.DefaultDepthWrite = false;
        
        var baseGroup = "Base";
        template.AddParameter(baseGroup, new .("StartColor", .Color)
            {
                DefaultValue = Variant.Create(Color.White.ToVector4()),
                DisplayName = "Start Color"
            });
        
        template.AddParameter(baseGroup, new .("EndColor", .Color)
            {
                DefaultValue = Variant.Create(Vector4(1, 1, 1, 0)),
                DisplayName = "End Color"
            });
        
        template.AddParameter(baseGroup, new .("ParticleTexture", .Texture2D)
            {
                DisplayName = "Particle Texture"
            });
        
        template.AddParameter(baseGroup, new .("AtlasTexture", .Texture2D)
            {
                DisplayName = "Atlas Texture",
                Tooltip = "For animated particles"
            });
        
        template.CalculateLayout();
        
        return template;
    }
}