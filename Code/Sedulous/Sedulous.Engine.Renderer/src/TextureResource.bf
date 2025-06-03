using System;
using Sedulous.Resources;
using Sedulous.Utilities;
namespace Sedulous.Engine.Renderer;

class TextureResource : Resource
{
    public enum TextureFormat
    {
        R8,
        RG8,
        RGB8,
        RGBA8,
        R16F,
        RG16F,
        RGB16F,
        RGBA16F,
        R32F,
        RG32F,
        RGB32F,
        RGBA32F,
        Depth24Stencil8
    }

    public enum TextureFilter
    {
        Nearest,
        Linear,
        NearestMipmapNearest,
        LinearMipmapNearest,
        NearestMipmapLinear,
        LinearMipmapLinear
    }

    public enum TextureWrap
    {
        Repeat,
        ClampToEdge,
        ClampToBorder,
        MirroredRepeat
    }

    private uint8[] mData;
    private uint32 mWidth;
    private uint32 mHeight;
    private TextureFormat mFormat;
    private uint32 mMipLevels;

    public uint32 Width => mWidth;
    public uint32 Height => mHeight;
    public TextureFormat Format => mFormat;
    public uint32 MipLevels => mMipLevels;
    public Span<uint8> Data => mData;

    public TextureFilter MinFilter { get; set; } = .Linear;
    public TextureFilter MagFilter { get; set; } = .Linear;
    public TextureWrap WrapU { get; set; } = .Repeat;
    public TextureWrap WrapV { get; set; } = .Repeat;

    public this(uint32 width, uint32 height, TextureFormat format, uint8[] data = null)
    {
        Id = Guid.Create();
        mWidth = width;
        mHeight = height;
        mFormat = format;
        mMipLevels = 1;

        var bytesPerPixel = GetBytesPerPixel(format);
        var dataSize = width * height * bytesPerPixel;

        if (data != null && data.Count >= dataSize)
        {
            mData = new uint8[dataSize];
            data[0..<dataSize].CopyTo(mData);
        }
        else
        {
            mData = new uint8[dataSize];
            // Initialize to default values based on format
            InitializeDefaultData();
        }
    }

    public ~this()
    {
        delete mData;
    }

    private void InitializeDefaultData()
    {
        switch (mFormat)
        {
        case .RGBA8:
            // Initialize to white (255, 255, 255, 255)
            for (int i = 0; i < mData.Count; i += 4)
            {
                mData[i] = 255;     // R
                mData[i + 1] = 255; // G
                mData[i + 2] = 255; // B
                mData[i + 3] = 255; // A
            }
        case .RGB8:
            // Initialize to white (255, 255, 255)
            for (int i = 0; i < mData.Count; i += 3)
            {
                mData[i] = 255;     // R
                mData[i + 1] = 255; // G
                mData[i + 2] = 255; // B
            }
        default:
            // Initialize to zero for other formats
            Internal.MemSet(mData.Ptr, 0, mData.Count);
        }
    }

    private static uint32 GetBytesPerPixel(TextureFormat format)
    {
        switch (format)
        {
        case .R8: return 1;
        case .RG8: return 2;
        case .RGB8: return 3;
        case .RGBA8: return 4;
        case .R16F: return 2;
        case .RG16F: return 4;
        case .RGB16F: return 6;
        case .RGBA16F: return 8;
        case .R32F: return 4;
        case .RG32F: return 8;
        case .RGB32F: return 12;
        case .RGBA32F: return 16;
        case .Depth24Stencil8: return 4;
        default: return 4;
        }
    }
}