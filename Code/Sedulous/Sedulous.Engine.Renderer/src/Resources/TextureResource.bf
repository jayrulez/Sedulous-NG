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
    
    // ========== BASIC TEXTURE FACTORY METHODS ==========

	public static TextureResource CreateSolidColor(uint32 width, uint32 height, Color color)
	{
	    var image = Image.CreateSolidColor(width, height, color);
	    return new TextureResource(image, true);
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
    
    // ========== NORMAL MAP FACTORY METHODS ==========
    
    // Factory method: Create flat normal map (baseline for testing)
    public static TextureResource CreateFlatNormalMap(uint32 size = 256)
    {
        var image = Image.CreateFlatNormalMap(size, size);
        var texture = new TextureResource(image, true);
        texture.SetupForNormalMap();
        return texture;
    }
    
    // Factory method: Create wave pattern normal map
    public static TextureResource CreateWaveNormalMap(uint32 size = 256, 
                                                     float waveFrequencyX = 8.0f, 
                                                     float waveFrequencyY = 6.0f,
                                                     float amplitude = 0.3f)
    {
        var image = Image.CreateWaveNormalMap(size, size, waveFrequencyX, waveFrequencyY, amplitude);
        var texture = new TextureResource(image, true);
        texture.SetupForNormalMap();
        return texture;
    }
    
    // Factory method: Create brick pattern normal map
    public static TextureResource CreateBrickNormalMap(uint32 size = 256,
                                                      uint32 bricksX = 8, 
                                                      uint32 bricksY = 4,
                                                      float mortarDepth = 0.3f)
    {
        var image = Image.CreateBrickNormalMap(size, size, bricksX, bricksY, mortarDepth);
        var texture = new TextureResource(image, true);
        texture.SetupForNormalMap();
        return texture;
    }
    
    // Factory method: Create circular bump normal map
    public static TextureResource CreateCircularBumpNormalMap(uint32 size = 256,
                                                             float bumpHeight = 0.5f, 
                                                             float falloff = 2.0f)
    {
        var image = Image.CreateCircularBumpNormalMap(size, size, bumpHeight, falloff);
        var texture = new TextureResource(image, true);
        texture.SetupForNormalMap();
        return texture;
    }
    
    // Factory method: Create noise-based normal map
    public static TextureResource CreateNoiseNormalMap(uint32 size = 256,
                                                      float scale = 0.1f, 
                                                      float amplitude = 0.2f,
                                                      int32 seed = 12345)
    {
        var image = Image.CreateNoiseNormalMap(size, size, scale, amplitude, seed);
        var texture = new TextureResource(image, true);
        texture.SetupForNormalMap();
        return texture;
    }
    
    // Factory method: Create test pattern normal map (debugging)
    public static TextureResource CreateTestPatternNormalMap(uint32 size = 256)
    {
        var image = Image.CreateTestPatternNormalMap(size, size);
        var texture = new TextureResource(image, true);
        texture.SetupForNormalMap();
        return texture;
    }
    
    // ========== TEXTURE SETUP METHODS ==========
    
    // Setup texture settings for UI textures
    public void SetupForUI()
    {
        MinFilter = .Linear;
        MagFilter = .Linear;
        WrapU = .ClampToEdge;
        WrapV = .ClampToEdge;
        GenerateMipmaps = false;
        Anisotropy = 1.0f;
    }
    
    // Setup texture settings for pixel art sprites
    public void SetupForSprite()
    {
        MinFilter = .Nearest;
        MagFilter = .Nearest;
        WrapU = .ClampToEdge;
        WrapV = .ClampToEdge;
        GenerateMipmaps = false;
        Anisotropy = 1.0f;
    }
    
    // Setup texture settings for 3D world textures
    public void SetupFor3D()
    {
        MinFilter = .LinearMipmapLinear;
        MagFilter = .Linear;
        WrapU = .Repeat;
        WrapV = .Repeat;
        GenerateMipmaps = true;
        Anisotropy = 16.0f;
    }
    
    // Setup texture settings for skybox textures
    public void SetupForSkybox()
    {
        MinFilter = .Linear;
        MagFilter = .Linear;
        WrapU = .ClampToEdge;
        WrapV = .ClampToEdge;
        WrapW = .ClampToEdge;
        GenerateMipmaps = false;
        Anisotropy = 1.0f;
    }
    
    // Setup texture settings specifically for normal maps
    public void SetupForNormalMap()
    {
        MinFilter = .LinearMipmapLinear;
        MagFilter = .Linear;
        WrapU = .Repeat;
        WrapV = .Repeat;
        GenerateMipmaps = true; // Normal maps benefit from mipmaps
        Anisotropy = 16.0f; // High anisotropy for better detail at oblique angles
    }
    
    // Setup texture settings for height maps / displacement
    public void SetupForHeightMap()
    {
        MinFilter = .Linear;
        MagFilter = .Linear;
        WrapU = .Repeat;
        WrapV = .Repeat;
        GenerateMipmaps = false; // Height maps usually don't need mipmaps
        Anisotropy = 1.0f;
    }
    
    // Setup texture settings for environment maps
    public void SetupForEnvironmentMap()
    {
        MinFilter = .LinearMipmapLinear;
        MagFilter = .Linear;
        WrapU = .ClampToEdge;
        WrapV = .ClampToEdge;
        WrapW = .ClampToEdge;
        GenerateMipmaps = true;
        Anisotropy = 8.0f;
    }
}