using System;
using Sedulous.Mathematics;
using System.Collections;
namespace Sedulous.Engine.Renderer.RHI;

// Types of parameters a material can have
enum MaterialParameterType : uint8
{
    Float,
    Float2,
    Float3,
    Float4,
    Int,
    Bool,
    Matrix,
    Texture2D,
    TextureCube,
    Texture3D,
    Color
}

// Describes a single material parameter
class MaterialParameter
{
    public String Name = new .() ~ delete _;
    public MaterialParameterType Type;
    public uint32 Offset; // Offset in constant buffer
    public uint32 Size; // Size in bytes
    public uint32 TextureSlot; // For texture parameters
    public String SemanticHint = new .() ~ delete _; // "BaseColor", "Normal", etc.
    
    // Default value
    public Variant DefaultValue ~ _.Dispose();
    
    // UI hints
    public float MinValue = 0.0f;
    public float MaxValue = 1.0f;
    public String DisplayName = new .() ~ delete _;
    public String Tooltip = new .() ~ delete _;
    public bool Hidden = false;
    
    public this(StringView name, MaterialParameterType type)
    {
        Name.Set(name);
        Type = type;
        Size = GetTypeSize(type);
        SetDefaultValue();
    }
    
    private void SetDefaultValue()
    {
        switch (Type)
        {
        case .Float:
            DefaultValue = Variant.Create(0.0f);
        case .Float2:
            DefaultValue = Variant.Create(Vector2.Zero);
        case .Float3:
            DefaultValue = Variant.Create(Vector3.Zero);
        case .Float4, .Color:
            DefaultValue = Variant.Create(Vector4.One);
        case .Int:
            DefaultValue = Variant.Create(0);
        case .Bool:
            DefaultValue = Variant.Create(false);
        case .Matrix:
            DefaultValue = Variant.Create(Matrix.Identity);
        default:
            DefaultValue = Variant.Create<Object>(null);
        }
    }
    
    public static uint32 GetTypeSize(MaterialParameterType type)
    {
        switch (type)
        {
        case .Float: return 4;
        case .Float2: return 8;
        case .Float3: return 12;
        case .Float4, .Color: return 16;
        case .Int: return 4;
        case .Bool: return 4; // Padded to 4 bytes in constant buffers
        case .Matrix: return 64;
        case .Texture2D, .TextureCube, .Texture3D: return 0; // Not in constant buffer
        }
    }
    
    public bool IsTexture()
    {
        return Type == .Texture2D || Type == .TextureCube || Type == .Texture3D;
    }
}

// Groups parameters for organization
class MaterialParameterGroup
{
    public String Name = new .() ~ delete _;
    public List<MaterialParameter> Parameters = new .() ~ DeleteContainerAndItems!(_);
    public bool Expanded = true; // For UI
    
    public this(StringView name)
    {
        Name.Set(name);
    }
}