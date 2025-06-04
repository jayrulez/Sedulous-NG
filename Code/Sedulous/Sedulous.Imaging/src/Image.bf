using System;
using Sedulous.Mathematics;

namespace Sedulous.Imaging;

public class Image
{
    public enum PixelFormat
    {
        // 8-bit formats
        R8,           // 1 byte per pixel
        RG8,          // 2 bytes per pixel  
        RGB8,         // 3 bytes per pixel
        RGBA8,        // 4 bytes per pixel
        
        // 16-bit float formats
        R16F,         // 2 bytes per pixel
        RG16F,        // 4 bytes per pixel
        RGB16F,       // 6 bytes per pixel
        RGBA16F,      // 8 bytes per pixel
        
        // 32-bit float formats
        R32F,         // 4 bytes per pixel
        RG32F,        // 8 bytes per pixel
        RGB32F,       // 12 bytes per pixel
        RGBA32F,      // 16 bytes per pixel
        
        // Special formats
        BGR8,         // 3 bytes per pixel (common in some file formats)
        BGRA8,        // 4 bytes per pixel (common in Windows)
    }

    private uint8[] mData ~ delete _;
    private uint32 mWidth;
    private uint32 mHeight;
    private PixelFormat mFormat;
    
    public uint32 Width => mWidth;
    public uint32 Height => mHeight;
    public PixelFormat Format => mFormat;
    public Span<uint8> Data => mData;
    public uint32 PixelCount => mWidth * mHeight;
    public uint32 DataSize => PixelCount * (uint32)GetBytesPerPixel(mFormat);
    
    public this(uint32 width, uint32 height, PixelFormat format, uint8[] data = null)
    {
        mWidth = width;
        mHeight = height;
        mFormat = format;
        
        var dataSize = DataSize;
        mData = new uint8[dataSize];
        
        if (data != null && data.Count >= dataSize)
        {
            data[0..<dataSize].CopyTo(mData);
        }
        else
        {
            Clear();
        }
    }
    
    public this(Image other)
    {
        mWidth = other.mWidth;
        mHeight = other.mHeight;
        mFormat = other.mFormat;
        
        mData = new uint8[other.mData.Count];
        other.mData.CopyTo(mData);
    }
    
    // Clear image to default values
    public void Clear(Color? color = null)
    {
        if (color == null)
        {
            // Default: transparent black for RGBA, white for RGB, black for single channel
            switch (mFormat)
            {
            case .RGBA8, .RGBA16F, .RGBA32F, .BGRA8:
                FillColor(.(0, 0, 0, 0));
            case .RGB8, .RGB16F, .RGB32F, .BGR8:
                FillColor(.(255, 255, 255, 255));
            default:
                Internal.MemSet(mData.Ptr, 0, mData.Count);
            }
        }
        else
        {
            FillColor(color.Value);
        }
    }
    
    // Fill entire image with a color
    public void FillColor(Color color)
    {
        switch (mFormat)
        {
        case .R8:
            uint8 gray = (uint8)((color.R + color.G + color.B) / 3);
            Internal.MemSet(mData.Ptr, gray, mData.Count);
            
        case .RG8:
            for (int i = 0; i < mData.Count; i += 2)
            {
                mData[i] = color.R;
                mData[i + 1] = color.G;
            }
            
        case .RGB8:
            for (int i = 0; i < mData.Count; i += 3)
            {
                mData[i] = color.R;
                mData[i + 1] = color.G;
                mData[i + 2] = color.B;
            }
            
        case .RGBA8:
            for (int i = 0; i < mData.Count; i += 4)
            {
                mData[i] = color.R;
                mData[i + 1] = color.G;
                mData[i + 2] = color.B;
                mData[i + 3] = color.A;
            }
            
        case .BGR8:
            for (int i = 0; i < mData.Count; i += 3)
            {
                mData[i] = color.B;
                mData[i + 1] = color.G;
                mData[i + 2] = color.R;
            }
            
        case .BGRA8:
            for (int i = 0; i < mData.Count; i += 4)
            {
                mData[i] = color.B;
                mData[i + 1] = color.G;
                mData[i + 2] = color.R;
                mData[i + 3] = color.A;
            }
            
        default:
            // For float formats, convert color to float
            var floatColor = color.ToVector4();
            FillColorFloat(floatColor);
        }
    }
    
    private void FillColorFloat(Vector4 color)
    {
        switch (mFormat)
        {
        case .R32F:
            float gray = (color.X + color.Y + color.Z) / 3.0f;
            var floatData = (float*)mData.Ptr;
            for (int i = 0; i < PixelCount; i++)
                floatData[i] = gray;
                
        case .RGBA32F:
            var vec4Data = (Vector4*)mData.Ptr;
            for (int i = 0; i < PixelCount; i++)
                vec4Data[i] = color;
                
        // Add other float format cases as needed
        default:
            break;
        }
    }
    
    // Get pixel color at coordinates
    public Color GetPixel(uint32 x, uint32 y)
    {
        if (x >= mWidth || y >= mHeight)
            return .Black;
            
        var offset = GetPixelOffset(x, y);
        
        switch (mFormat)
        {
        case .R8:
            uint8 gray = mData[offset];
            return .(gray, gray, gray, 255);
            
        case .RGB8:
            return .(mData[offset], mData[offset + 1], mData[offset + 2], 255);
            
        case .RGBA8:
            return .(mData[offset], mData[offset + 1], mData[offset + 2], mData[offset + 3]);
            
        case .BGR8:
            return .(mData[offset + 2], mData[offset + 1], mData[offset], 255);
            
        case .BGRA8:
            return .(mData[offset + 2], mData[offset + 1], mData[offset], mData[offset + 3]);
            
        default:
            // Handle float formats
            return GetPixelFloat(x, y);
        }
    }
    
    private Color GetPixelFloat(uint32 x, uint32 y)
    {
        var offset = GetPixelOffset(x, y);
        
        switch (mFormat)
        {
        case .R32F:
            float gray = *((float*)&mData[offset]);
            uint8 grayByte = (uint8)(Math.Clamp(gray * 255.0f, 0, 255));
            return .(grayByte, grayByte, grayByte, 255);
            
        case .RGBA32F:
            var color = *((Vector4*)&mData[offset]);
            return .(
                (uint8)(Math.Clamp(color.X * 255.0f, 0, 255)),
                (uint8)(Math.Clamp(color.Y * 255.0f, 0, 255)),
                (uint8)(Math.Clamp(color.Z * 255.0f, 0, 255)),
                (uint8)(Math.Clamp(color.W * 255.0f, 0, 255))
            );
            
        default:
            return .Black;
        }
    }
    
    // Set pixel color at coordinates
    public void SetPixel(uint32 x, uint32 y, Color color)
    {
        if (x >= mWidth || y >= mHeight)
            return;
            
        var offset = GetPixelOffset(x, y);
        
        switch (mFormat)
        {
        case .R8:
            mData[offset] = (uint8)((color.R + color.G + color.B) / 3);
            
        case .RGB8:
            mData[offset] = color.R;
            mData[offset + 1] = color.G;
            mData[offset + 2] = color.B;
            
        case .RGBA8:
            mData[offset] = color.R;
            mData[offset + 1] = color.G;
            mData[offset + 2] = color.B;
            mData[offset + 3] = color.A;
            
        case .BGR8:
            mData[offset] = color.B;
            mData[offset + 1] = color.G;
            mData[offset + 2] = color.R;
            
        case .BGRA8:
            mData[offset] = color.B;
            mData[offset + 1] = color.G;
            mData[offset + 2] = color.R;
            mData[offset + 3] = color.A;
            
        default:
            SetPixelFloat(x, y, color.ToVector4());
        }
    }
    
    private void SetPixelFloat(uint32 x, uint32 y, Vector4 color)
    {
        var offset = GetPixelOffset(x, y);
        
        switch (mFormat)
        {
        case .R32F:
            float gray = (color.X + color.Y + color.Z) / 3.0f;
            *((float*)&mData[offset]) = gray;
            
        case .RGBA32F:
            *((Vector4*)&mData[offset]) = color;
            
        default:
            break;
        }
    }
    
    // Flip image vertically
    public void FlipVertical()
    {
        var rowSize = mWidth * (uint32)GetBytesPerPixel(mFormat);
        var tempRow = scope uint8[rowSize];
        
        for (uint32 y = 0; y < mHeight / 2; y++)
        {
            var topRow = y * rowSize;
            var bottomRow = (mHeight - 1 - y) * rowSize;
            
            // Swap rows
            Internal.MemCpy(tempRow.Ptr, &mData[topRow], rowSize);
            Internal.MemCpy(&mData[topRow], &mData[bottomRow], rowSize);
            Internal.MemCpy(&mData[bottomRow], tempRow.Ptr, rowSize);
        }
    }
    
    // Flip image horizontally
    public void FlipHorizontal()
    {
        var bytesPerPixel = GetBytesPerPixel(mFormat);
        var tempPixel = scope uint8[bytesPerPixel];
        
        for (uint32 y = 0; y < mHeight; y++)
        {
            for (uint32 x = 0; x < mWidth / 2; x++)
            {
                var leftOffset = GetPixelOffset(x, y);
                var rightOffset = GetPixelOffset(mWidth - 1 - x, y);
                
                // Swap pixels
                Internal.MemCpy(tempPixel.Ptr, &mData[leftOffset], bytesPerPixel);
                Internal.MemCpy(&mData[leftOffset], &mData[rightOffset], bytesPerPixel);
                Internal.MemCpy(&mData[rightOffset], tempPixel.Ptr, bytesPerPixel);
            }
        }
    }
    
    // Create a copy with different format
    public Result<Image> ConvertFormat(PixelFormat newFormat)
    {
        if (newFormat == mFormat)
            return new Image(this);
            
        var newImage = new Image(mWidth, mHeight, newFormat);
        
        // Convert pixel by pixel (simple implementation)
        for (uint32 y = 0; y < mHeight; y++)
        {
            for (uint32 x = 0; x < mWidth; x++)
            {
                var color = GetPixel(x, y);
                newImage.SetPixel(x, y, color);
            }
        }
        
        return newImage;
    }
    
    // Factory method: Create solid color image
    public static Image CreateSolidColor(uint32 width, uint32 height, Color color, PixelFormat format = .RGBA8)
    {
        var image = new Image(width, height, format);
        image.FillColor(color);
        return image;
    }
    
    // Factory method: Create checkerboard pattern
    public static Image CreateCheckerboard(uint32 size = 256, Color color1 = .White, Color color2 = .Black, 
                                         uint32 checkSize = 32, PixelFormat format = .RGBA8)
    {
        var image = new Image(size, size, format);
        
        for (uint32 y = 0; y < size; y++)
        {
            for (uint32 x = 0; x < size; x++)
            {
                bool isColor1 = ((x / checkSize) + (y / checkSize)) % 2 == 0;
                image.SetPixel(x, y, isColor1 ? color1 : color2);
            }
        }
        
        return image;
    }
    
    // Factory method: Create gradient
    public static Image CreateGradient(uint32 width, uint32 height, Color topColor, Color bottomColor, 
                                     PixelFormat format = .RGBA8)
    {
        var image = new Image(width, height, format);
        
        for (uint32 y = 0; y < height; y++)
        {
            float t = (float)y / (float)(height - 1);
            
            Color color = .(
                (uint8)Math.Lerp(topColor.R, bottomColor.R, t),
                (uint8)Math.Lerp(topColor.G, bottomColor.G, t),
                (uint8)Math.Lerp(topColor.B, bottomColor.B, t),
                (uint8)Math.Lerp(topColor.A, bottomColor.A, t)
            );
            
            for (uint32 x = 0; x < width; x++)
            {
                image.SetPixel(x, y, color);
            }
        }
        
        return image;
    }
    
    // Helper: Get bytes per pixel for format
    public static int GetBytesPerPixel(PixelFormat format)
    {
        switch (format)
        {
        case .R8: return 1;
        case .RG8: return 2;
        case .RGB8, .BGR8: return 3;
        case .RGBA8, .BGRA8: return 4;
        case .R16F: return 2;
        case .RG16F: return 4;
        case .RGB16F: return 6;
        case .RGBA16F: return 8;
        case .R32F: return 4;
        case .RG32F: return 8;
        case .RGB32F: return 12;
        case .RGBA32F: return 16;
        default: return 4;
        }
    }
    
    // Helper: Get pixel offset in data array
    private int GetPixelOffset(uint32 x, uint32 y)
    {
        return (int)((y * mWidth + x) * GetBytesPerPixel(mFormat));
    }
    
    // Helper: Check if format has alpha channel
    public bool HasAlpha()
    {
        switch (mFormat)
        {
        case .RGBA8, .BGRA8, .RGBA16F, .RGBA32F:
            return true;
        default:
            return false;
        }
    }
    
    // Helper: Get channel count
    public int GetChannelCount()
    {
        switch (mFormat)
        {
        case .R8, .R16F, .R32F: return 1;
        case .RG8, .RG16F, .RG32F: return 2;
        case .RGB8, .BGR8, .RGB16F, .RGB32F: return 3;
        case .RGBA8, .BGRA8, .RGBA16F, .RGBA32F: return 4;
        default: return 0;
        }
    }
}