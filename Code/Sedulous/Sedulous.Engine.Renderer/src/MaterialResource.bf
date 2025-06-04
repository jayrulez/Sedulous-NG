using System;
using Sedulous.Resources;
using Sedulous.Mathematics;
using Sedulous.Utilities;

namespace Sedulous.Engine.Renderer;

class MaterialResource : Resource
{
    private Material mMaterial;
    private bool mOwnsMaterial;
    
    public Material Material => mMaterial;
    
    public this(Material material, bool ownsMaterial = false)
    {
        Id = Guid.Create();
        mMaterial = material;
        mOwnsMaterial = ownsMaterial;
    }
    
    public ~this()
    {
        if (mOwnsMaterial && mMaterial != null)
        {
            delete mMaterial;
        }
    }
    
    // Factory methods for common materials
    public static MaterialResource CreateDefaultLit()
    {
        return new MaterialResource(new PhongMaterial(), true);
    }
    
    public static MaterialResource CreateUnlit(Color color = .White)
    {
        var material = new UnlitMaterial();
        material.Color = color;
        return new MaterialResource(material, true);
    }
    
    public static MaterialResource CreatePBR()
    {
        return new MaterialResource(new PBRMaterial(), true);
    }
}