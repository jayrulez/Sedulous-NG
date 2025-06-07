using System;
using System.IO;
using Sedulous.Mathematics;
using System.Collections;

namespace Sedulous.Imaging;

// Abstract base class for image loaders
public abstract class ImageLoader
{
    public enum LoadResult
    {
        Success,
        FileNotFound,
        UnsupportedFormat,
        CorruptedData,
        OutOfMemory,
        InvalidDimensions,
        UnknownError
    }
    
    public struct LoadInfo
    {
        public uint32 Width;
        public uint32 Height;
        public Image.PixelFormat Format;
        public uint8[] Data;
        public LoadResult Result;
        public String ErrorMessage;
        
        public this()
        {
            Width = 0;
            Height = 0;
            Format = .RGBA8;
            Data = null;
            Result = .UnknownError;
            ErrorMessage = null;
        }
        
        // Manual cleanup method since structs can't have destructors
        public void Dispose() mut
        {
            delete Data;
            delete ErrorMessage;
            Data = null;
            ErrorMessage = null;
        }
    }
    
    // Load image from file path
    public abstract Result<LoadInfo> LoadFromFile(StringView filePath);
    
    // Load image from memory buffer
    public abstract Result<LoadInfo> LoadFromMemory(Span<uint8> data);
    
    // Check if this loader supports the file extension
    public abstract bool SupportsExtension(StringView @extension);
    
    // Get supported file extensions
    public abstract void GetSupportedExtensions(List<String> outExtensions);
    
    // Helper method to create Image from LoadInfo
    public static Result<Image> CreateImageFromLoadInfo(LoadInfo loadInfo)
    {
        if (loadInfo.Result != .Success || loadInfo.Data == null)
            return .Err;
            
        var image = new Image(loadInfo.Width, loadInfo.Height, loadInfo.Format, loadInfo.Data);
        return image;
    }
}