using System;
using Sedulous.Resources;
using Sedulous.Foundation.Mathematics;
namespace Sedulous.Engine.Renderer;

class MaterialResource : Resource
{
	[CRepr]
    public struct MaterialProperties
    {
        public Vector4 AlbedoColor;
        public float Metallic;
        public float Roughness;
        public float NormalStrength;
        public float EmissiveStrength;
        public Vector3 EmissiveColor;
    }

    private MaterialProperties mProperties;
    private ResourceHandle<TextureResource> mAlbedoTexture;
    private ResourceHandle<TextureResource> mNormalTexture;
    private ResourceHandle<TextureResource> mMetallicRoughnessTexture;
    private ResourceHandle<TextureResource> mEmissiveTexture;
    private String mShaderName = new .() ~ delete _;

    public ref MaterialProperties Properties
    {
        get => ref mProperties;
        set => mProperties = value;
    }

    public ResourceHandle<TextureResource> AlbedoTexture
    {
        get => mAlbedoTexture;
        set => mAlbedoTexture = value;
    }

    public ResourceHandle<TextureResource> NormalTexture
    {
        get => mNormalTexture;
        set => mNormalTexture = value;
    }

    public ResourceHandle<TextureResource> MetallicRoughnessTexture
    {
        get => mMetallicRoughnessTexture;
        set => mMetallicRoughnessTexture = value;
    }

    public ResourceHandle<TextureResource> EmissiveTexture
    {
        get => mEmissiveTexture;
        set => mEmissiveTexture = value;
    }

    public StringView ShaderName => mShaderName;

    public this(StringView shaderName = "DefaultLit")
    {
        Id = Guid.Create();
        mShaderName.Set(shaderName);

        // Set default material properties
        mProperties = .{
            AlbedoColor = Vector4(1, 1, 1, 1),
            Metallic = 0.0f,
            Roughness = 0.5f,
            NormalStrength = 1.0f,
            EmissiveStrength = 0.0f,
            EmissiveColor = Vector3.Zero
        };
    }

    public ~this()
    {
        mAlbedoTexture.Release();
        mNormalTexture.Release();
        mMetallicRoughnessTexture.Release();
        mEmissiveTexture.Release();
    }

    public void SetShader(StringView shaderName)
    {
        mShaderName.Set(shaderName);
    }
}