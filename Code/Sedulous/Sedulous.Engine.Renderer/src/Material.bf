using System;
using System.Collections;
using Sedulous.Mathematics;
using Sedulous.Resources;

namespace Sedulous.Engine.Renderer;

// Base material class
public abstract class Material
{
    public enum BlendMode
    {
        Opaque,         // No blending
        AlphaBlend,     // Standard transparency
		AlphaTest,
        Additive,       // Additive blending
        Multiply        // Multiply blending
    }
    
    public enum CullMode
    {
        None,           // No culling
        Front,          // Cull front faces
        Back            // Cull back faces
    }
    
    // Common material properties
    public BlendMode Blending { get; set; } = .Opaque;
    public CullMode Culling { get; set; } = .Back;
    public bool DepthWrite { get; set; } = true;
    public bool DepthTest { get; set; } = true;
    public float RenderOrder { get; set; } = 0; // For sorting transparent objects
    
    // Shader name this material uses
    public abstract StringView ShaderName { get; }
    
    // Get the size of uniform data this material needs
    public abstract int GetUniformDataSize();
    
    // Fill uniform data buffer with material properties
    public abstract void FillUniformData(Span<uint8> buffer);
    
    // Get texture resources used by this material
    public abstract void GetTextureResources(List<ResourceHandle<TextureResource>> textures);
}

// Standard lit material (Phong shading)
// Lighting comes from scene DirectionalLight components
public class PhongMaterial : Material
{
    // Material properties
    public Color DiffuseColor { get; set; } = .White;
    public Color SpecularColor { get; set; } = Color(0.5f, 0.5f, 0.5f, 1.0f);
    public float Shininess { get; set; } = 32.0f;
    public Color AmbientColor { get; set; } = Color(1.0f, 1.0f, 1.0f, 1.0f); // Material's ambient tint (multiplied with scene ambient)

    // Textures
    public ResourceHandle<TextureResource> DiffuseTexture { get; set; } ~ _.Release();
    public ResourceHandle<TextureResource> NormalTexture { get; set; } ~ _.Release();
    public ResourceHandle<TextureResource> SpecularTexture { get; set; } ~ _.Release();

    public override StringView ShaderName => "Phong";

    public override int GetUniformDataSize()
    {
        // PhongFragmentUniforms: 4 Vector4s = 64 bytes
        return sizeof(Vector4) * 4;
    }

    public override void FillUniformData(Span<uint8> buffer)
    {
        // Fill PhongFragmentUniforms struct layout:
        // Vector4 DiffuseColor;    // w = unused
        // Vector4 SpecularColor;   // w = shininess
        // Vector4 AmbientColor;    // w = unused (material ambient tint)
        // Vector4 Padding;         // Reserved

        var ptr = buffer.Ptr;

        // DiffuseColor
        var diffuse = DiffuseColor.ToVector4();
        Internal.MemCpy(ptr, &diffuse, sizeof(Vector4));
        ptr += sizeof(Vector4);

        // SpecularColor with shininess in w
        var specVec = SpecularColor.ToVector4();
        var specular = Vector4(specVec.X, specVec.Y, specVec.Z, Shininess);
        Internal.MemCpy(ptr, &specular, sizeof(Vector4));
        ptr += sizeof(Vector4);

        // AmbientColor (material ambient tint)
        var ambient = AmbientColor.ToVector4();
        Internal.MemCpy(ptr, &ambient, sizeof(Vector4));
        ptr += sizeof(Vector4);

        // Padding
        var padding = Vector4.Zero;
        Internal.MemCpy(ptr, &padding, sizeof(Vector4));
    }

    public override void GetTextureResources(List<ResourceHandle<TextureResource>> textures)
    {
        textures.Clear();
        if (DiffuseTexture.IsValid) textures.Add(DiffuseTexture);
        if (NormalTexture.IsValid) textures.Add(NormalTexture);
        if (SpecularTexture.IsValid) textures.Add(SpecularTexture);
    }
}

// Unlit material (no lighting calculations)
public class UnlitMaterial : Material
{
    public Color Color { get; set; } = .White;
    public ResourceHandle<TextureResource> MainTexture { get; set; } ~ _.Release();
    
    public override StringView ShaderName => "Unlit";
    
    public override int GetUniformDataSize()
    {
        return sizeof(Vector4) + sizeof(Vector4); // Just color
    }
    
    public override void FillUniformData(Span<uint8> buffer)
    {
        // Fill with color data
        var colorVec = Color.ToVector4();
        Internal.MemCpy(buffer.Ptr, &colorVec, sizeof(Vector4));
    }
    
    public override void GetTextureResources(List<ResourceHandle<TextureResource>> textures)
    {
        textures.Clear();
        if (MainTexture.IsValid) textures.Add(MainTexture);
    }
}

// PBR material (future implementation)
public class PBRMaterial : Material
{
    public Color AlbedoColor { get; set; } = .White;
    public float Metallic { get; set; } = 0.0f;
    public float Roughness { get; set; } = 0.5f;
    public float AmbientOcclusion { get; set; } = 1.0f;
    public Color EmissiveColor { get; set; } = .Black;
    public float EmissiveIntensity { get; set; } = 0.0f;
    
    // PBR textures
    public ResourceHandle<TextureResource> AlbedoTexture { get; set; } ~ _.Release();
    public ResourceHandle<TextureResource> NormalTexture { get; set; } ~ _.Release();
    public ResourceHandle<TextureResource> MetallicRoughnessTexture { get; set; } ~ _.Release();
    public ResourceHandle<TextureResource> AmbientOcclusionTexture { get; set; } ~ _.Release();
    public ResourceHandle<TextureResource> EmissiveTexture { get; set; } ~ _.Release();
    
    public override StringView ShaderName => "PBR";
    
    public override int GetUniformDataSize()
    {
        return sizeof(Vector4) * 2 + sizeof(float) * 4; // Colors + scalar values
    }
    
    public override void FillUniformData(Span<uint8> buffer)
    {
        // Fill PBR uniform data
    }
    
    public override void GetTextureResources(List<ResourceHandle<TextureResource>> textures)
    {
        textures.Clear();
        if (AlbedoTexture.IsValid) textures.Add(AlbedoTexture);
        if (NormalTexture.IsValid) textures.Add(NormalTexture);
        if (MetallicRoughnessTexture.IsValid) textures.Add(MetallicRoughnessTexture);
        if (AmbientOcclusionTexture.IsValid) textures.Add(AmbientOcclusionTexture);
        if (EmissiveTexture.IsValid) textures.Add(EmissiveTexture);
    }
}