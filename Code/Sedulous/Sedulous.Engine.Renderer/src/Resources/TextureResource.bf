using System;
using Sedulous.Resources;
using Sedulous.Imaging;
using Sedulous.Mathematics;

namespace Sedulous.Engine.Renderer;

class TextureResource : Resource
{
    public enum Filter
    {
        Nearest,
        Linear,
        NearestMipmapNearest,
        LinearMipmapNearest,
        NearestMipmapLinear,
        LinearMipmapLinear
    }

    public enum WrapMode
    {
        Repeat,
        ClampToEdge,
        ClampToBorder,
        MirroredRepeat
    }

    private Image mImage;
    private bool mOwnsImage;
    
    // Texture-specific settings
    public Filter MinFilter { get; set; } = .Linear;
    public Filter MagFilter { get; set; } = .Linear;
    public WrapMode WrapU { get; set; } = .Repeat;
    public WrapMode WrapV { get; set; } = .Repeat;
    public WrapMode WrapW { get; set; } = .Repeat;  // For 3D textures in future
    
    // Mipmap settings
    public bool GenerateMipmaps { get; set; } = false;
    public uint32 MipLevels { get; private set; } = 1;
    
    // Anisotropic filtering
    public float Anisotropy { get; set; } = 1.0f;
    
    // Border color for ClampToBorder mode
    public Color BorderColor { get; set; } = .Black;
    
    // Access to underlying image
    public Image Image => mImage;
    
    public this(Image image, bool ownsImage = false)
    {
        Id = Guid.Create();
        mImage = image;
        mOwnsImage = ownsImage;
        
        // Calculate max possible mip levels if mipmaps are requested
        if (GenerateMipmaps && image != null)
        {
            MipLevels = CalculateMaxMipLevels(image.Width, image.Height);
        }
    }
    
    public ~this()
    {
        if (mOwnsImage && mImage != null)
        {
            delete mImage;
        }
    }
    
    // Calculate maximum number of mip levels for given dimensions
    private static uint32 CalculateMaxMipLevels(uint32 width, uint32 height)
    {
        uint32 maxDimension = Math.Max(width, height);
        uint32 levels = 1;
        
        while (maxDimension > 1)
        {
            maxDimension >>= 1;
            levels++;
        }
        
        return levels;
    }
    
    // Factory method: Create from file (placeholder for future)
    public static Result<TextureResource> LoadFromFile(StringView path)
    {
        // TODO: Implement when image loading is added
        return .Err;
    }
    
    // Factory method: Create default white texture
    public static TextureResource CreateWhite(uint32 size = 4)
    {
        var image = Image.CreateSolidColor(size, size, .White);
        return new TextureResource(image, true);
    }
    
    // Factory method: Create default black texture
    public static TextureResource CreateBlack(uint32 size = 4)
    {
        var image = Image.CreateSolidColor(size, size, .Black);
        return new TextureResource(image, true);
    }
    
    // Factory method: Create default normal map (flat normal pointing up)
    public static TextureResource CreateDefaultNormal(uint32 size = 4)
    {
        // Normal maps store normals as (R=X, G=Y, B=Z) mapped from [-1,1] to [0,255]
        // Default normal is (0, 0, 1) which maps to (128, 128, 255)
        var image = Image.CreateSolidColor(size, size, .(128, 128, 255, 255));
        return new TextureResource(image, true);
    }
    
    // Factory method: Create checkerboard texture
    public static TextureResource CreateCheckerboard(uint32 size = 256, uint32 checkSize = 32)
    {
        var image = Image.CreateCheckerboard(size, .White, .Black, checkSize);
        return new TextureResource(image, true);
    }
    
    // Factory method: Create gradient texture
    public static TextureResource CreateGradient(uint32 width, uint32 height, Color topColor, Color bottomColor)
    {
        var image = Image.CreateGradient(width, height, topColor, bottomColor);
        return new TextureResource(image, true);
    }
    
    // Update texture settings for common use cases
    public void SetupForUI()
    {
        MinFilter = .Linear;
        MagFilter = .Linear;
        WrapU = .ClampToEdge;
        WrapV = .ClampToEdge;
        GenerateMipmaps = false;
    }
    
    public void SetupForSprite()
    {
        MinFilter = .Nearest;
        MagFilter = .Nearest;
        WrapU = .ClampToEdge;
        WrapV = .ClampToEdge;
        GenerateMipmaps = false;
    }
    
    public void SetupFor3D()
    {
        MinFilter = .LinearMipmapLinear;
        MagFilter = .Linear;
        WrapU = .Repeat;
        WrapV = .Repeat;
        GenerateMipmaps = true;
        Anisotropy = 16.0f;
    }
    
    public void SetupForSkybox()
    {
        MinFilter = .Linear;
        MagFilter = .Linear;
        WrapU = .ClampToEdge;
        WrapV = .ClampToEdge;
        WrapW = .ClampToEdge;
        GenerateMipmaps = false;
    }
}