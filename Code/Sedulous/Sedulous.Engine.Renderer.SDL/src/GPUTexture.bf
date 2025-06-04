using SDL3Native;
using System;
using Sedulous.Imaging;

namespace Sedulous.Engine.Renderer.SDL;

class GPUTexture
{
    public SDL_GPUTexture* Texture;
    public SDL_GPUSampler* Sampler;
    
    private SDL_GPUDevice* mDevice;
    
    public this(SDL_GPUDevice* device, TextureResource textureResource)
    {
        mDevice = device;
        if (textureResource.Image != null)
        {
            CreateTexture(device, textureResource.Image, textureResource.GenerateMipmaps);
            CreateSampler(device, textureResource);
        }
        else
        {
            SDL_Log("TextureResource has null Image");
        }
    }
    
    // Convenience constructor for just an image with default settings
    public this(SDL_GPUDevice* device, Image image)
    {
        mDevice = device;
        CreateTexture(device, image, false);
        CreateDefaultSampler(device);
    }
    
    public ~this()
    {
        if (mDevice != null)
        {
            if (Texture != null)
                SDL_ReleaseGPUTexture(mDevice, Texture);
            if (Sampler != null)
                SDL_ReleaseGPUSampler(mDevice, Sampler);
        }
    }
    
    private void CreateTexture(SDL_GPUDevice* device, Image image, bool generateMipmaps)
    {
        var textureDesc = SDL_GPUTextureCreateInfo()
        {
            type = .SDL_GPU_TEXTURETYPE_2D,
            format = ConvertPixelFormat(image.Format),
            width = image.Width,
            height = image.Height,
            layer_count_or_depth = 1,
            num_levels = generateMipmaps ? CalculateMipLevels(image.Width, image.Height) : 1,
            sample_count = .SDL_GPU_SAMPLECOUNT_1,
            usage = .SDL_GPU_TEXTUREUSAGE_SAMPLER,
            props = 0
        };
        
        Texture = SDL_CreateGPUTexture(device, &textureDesc);
        
        if (Texture == null)
        {
            SDL_Log("Failed to create GPU texture: %s", SDL_GetError());
            return;
        }
        
        // Upload texture data
        UploadTextureData(device, image, generateMipmaps);
    }
    
    private void UploadTextureData(SDL_GPUDevice* device, Image image, bool generateMipmaps)
    {
        // Calculate data size
        uint32 dataSize = image.DataSize;
        
        // Create transfer buffer
        var transferBuffer = SDL_CreateGPUTransferBuffer(device, scope .() 
        {
            usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD,
            size = dataSize
        });
        
        if (transferBuffer == null)
        {
            SDL_Log("Failed to create transfer buffer for texture upload");
            return;
        }
        
        defer SDL_ReleaseGPUTransferBuffer(device, transferBuffer);
        
        // Map and copy data
        var transfer = SDL_MapGPUTransferBuffer(device, transferBuffer, false);
        if (transfer != null)
        {
            Internal.MemCpy(transfer, image.Data.Ptr, dataSize);
            SDL_UnmapGPUTransferBuffer(device, transferBuffer);
            
            // Upload to GPU
            var commandBuffer = SDL_AcquireGPUCommandBuffer(device);
            if (commandBuffer != null)
            {
                var copyPass = SDL_BeginGPUCopyPass(commandBuffer);
                
                // Calculate bytes per pixel for pixel row calculation
                var bytesPerPixel = (uint32)Image.GetBytesPerPixel(image.Format);
                var pixelsPerRow = image.Width;
                var rowsPerLayer = image.Height;
                
                // For formats with padding, we might need to adjust pixels per row
                // This handles pitch/stride correctly
                if (bytesPerPixel > 0)
                {
                    pixelsPerRow = dataSize / (bytesPerPixel * image.Height);
                }
                
                var textureTransferInfo = SDL_GPUTextureTransferInfo()
                {
                    transfer_buffer = transferBuffer,
                    offset = 0,
                    pixels_per_row = pixelsPerRow,
                    rows_per_layer = rowsPerLayer
                };
                
                var textureRegion = SDL_GPUTextureRegion()
                {
                    texture = Texture,
                    mip_level = 0,
                    layer = 0,
                    x = 0,
                    y = 0,
                    z = 0,
                    w = image.Width,
                    h = image.Height,
                    d = 1
                };
                
                SDL_UploadToGPUTexture(copyPass, &textureTransferInfo, &textureRegion, false);
                
                SDL_EndGPUCopyPass(copyPass);
                SDL_SubmitGPUCommandBuffer(commandBuffer);
                
                // TODO: Generate mipmaps if requested
                // This would require either:
                // 1. Pre-generating mipmap data on CPU
                // 2. Using GPU compute shaders to generate
                // 3. Using SDL_GPU blit operations to downsample
            }
        }
    }
    
    private void CreateSampler(SDL_GPUDevice* device, TextureResource textureResource)
    {
        var samplerDesc = SDL_GPUSamplerCreateInfo()
        {
            min_filter = ConvertFilter(textureResource.MinFilter),
            mag_filter = ConvertFilter(textureResource.MagFilter),
            mipmap_mode = ConvertMipmapMode(textureResource.MinFilter),
            address_mode_u = ConvertWrapMode(textureResource.WrapU),
            address_mode_v = ConvertWrapMode(textureResource.WrapV),
            address_mode_w = ConvertWrapMode(textureResource.WrapW),
            mip_lod_bias = 0.0f,
            max_anisotropy = textureResource.Anisotropy,
            compare_op = .SDL_GPU_COMPAREOP_NEVER,
            min_lod = 0.0f,
            max_lod = 1000.0f,
            enable_compare = false,
            enable_anisotropy = textureResource.Anisotropy > 1.0f
        };
        
        Sampler = SDL_CreateGPUSampler(device, &samplerDesc);
        
        if (Sampler == null)
        {
            SDL_Log("Failed to create GPU sampler: %s", SDL_GetError());
        }
    }
    
    private void CreateDefaultSampler(SDL_GPUDevice* device)
    {
        var samplerDesc = SDL_GPUSamplerCreateInfo()
        {
            min_filter = .SDL_GPU_FILTER_LINEAR,
            mag_filter = .SDL_GPU_FILTER_LINEAR,
            mipmap_mode = .SDL_GPU_SAMPLERMIPMAPMODE_LINEAR,
            address_mode_u = .SDL_GPU_SAMPLERADDRESSMODE_REPEAT,
            address_mode_v = .SDL_GPU_SAMPLERADDRESSMODE_REPEAT,
            address_mode_w = .SDL_GPU_SAMPLERADDRESSMODE_REPEAT,
            mip_lod_bias = 0.0f,
            max_anisotropy = 1.0f,
            compare_op = .SDL_GPU_COMPAREOP_NEVER,
            min_lod = 0.0f,
            max_lod = 1000.0f,
            enable_compare = false,
            enable_anisotropy = false
        };
        
        Sampler = SDL_CreateGPUSampler(device, &samplerDesc);
    }
    
    private static SDL_GPUTextureFormat ConvertPixelFormat(Image.PixelFormat format)
    {
        switch (format)
        {
        case .R8: return .SDL_GPU_TEXTUREFORMAT_R8_UNORM;
        case .RG8: return .SDL_GPU_TEXTUREFORMAT_R8G8_UNORM;
        case .RGB8: return .SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM; // No RGB8 in SDL_GPU, use RGBA8
        case .RGBA8: return .SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
        case .BGR8: return .SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM; // Assuming BGR8 maps to BGRA8
        case .BGRA8: return .SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM;
        case .R16F: return .SDL_GPU_TEXTUREFORMAT_R16_FLOAT;
        case .RG16F: return .SDL_GPU_TEXTUREFORMAT_R16G16_FLOAT;
        case .RGB16F: return .SDL_GPU_TEXTUREFORMAT_R16G16B16A16_FLOAT; // No RGB16F, use RGBA16F
        case .RGBA16F: return .SDL_GPU_TEXTUREFORMAT_R16G16B16A16_FLOAT;
        case .R32F: return .SDL_GPU_TEXTUREFORMAT_R32_FLOAT;
        case .RG32F: return .SDL_GPU_TEXTUREFORMAT_R32G32_FLOAT;
        case .RGB32F: return .SDL_GPU_TEXTUREFORMAT_R32G32B32A32_FLOAT; // No RGB32F, use RGBA32F
        case .RGBA32F: return .SDL_GPU_TEXTUREFORMAT_R32G32B32A32_FLOAT;
        default: return .SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
        }
    }
    
    private static SDL_GPUFilter ConvertFilter(TextureResource.Filter filter)
    {
        switch (filter)
        {
        case .Nearest, .NearestMipmapNearest, .NearestMipmapLinear:
            return .SDL_GPU_FILTER_NEAREST;
        case .Linear, .LinearMipmapNearest, .LinearMipmapLinear:
            return .SDL_GPU_FILTER_LINEAR;
        default:
            return .SDL_GPU_FILTER_LINEAR;
        }
    }
    
    private static SDL_GPUSamplerMipmapMode ConvertMipmapMode(TextureResource.Filter filter)
    {
        switch (filter)
        {
        case .NearestMipmapNearest, .LinearMipmapNearest:
            return .SDL_GPU_SAMPLERMIPMAPMODE_NEAREST;
        case .NearestMipmapLinear, .LinearMipmapLinear:
            return .SDL_GPU_SAMPLERMIPMAPMODE_LINEAR;
        default:
            return .SDL_GPU_SAMPLERMIPMAPMODE_NEAREST;
        }
    }
    
    private static SDL_GPUSamplerAddressMode ConvertWrapMode(TextureResource.WrapMode wrap)
    {
        switch (wrap)
        {
        case .Repeat: return .SDL_GPU_SAMPLERADDRESSMODE_REPEAT;
        case .ClampToEdge: return .SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE;
        case .ClampToBorder: return .SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE; // SDL_GPU doesn't have border
        case .MirroredRepeat: return .SDL_GPU_SAMPLERADDRESSMODE_MIRRORED_REPEAT;
        default: return .SDL_GPU_SAMPLERADDRESSMODE_REPEAT;
        }
    }
    
    private static uint32 CalculateMipLevels(uint32 width, uint32 height)
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
}