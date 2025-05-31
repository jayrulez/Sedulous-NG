using SDL3Native;
using System;
namespace Sedulous.Engine.Renderer.SDL;

class GPUTexture
{
    public SDL_GPUTexture* Texture;
    public SDL_GPUSampler* Sampler;
    
    public this(SDL_GPUDevice* device, TextureResource texture)
    {
        CreateTexture(device, texture);
        CreateSampler(device, texture);
    }
    
    public ~this()
    {
        // Note: Should be cleaned up by renderer on shutdown
    }
    
    private void CreateTexture(SDL_GPUDevice* device, TextureResource texture)
    {
        var textureDesc = SDL_GPUTextureCreateInfo()
        {
            type = .SDL_GPU_TEXTURETYPE_2D,
            format = ConvertTextureFormat(texture.Format),
            width = texture.Width,
            height = texture.Height,
            layer_count_or_depth = 1,
            num_levels = texture.MipLevels,
            usage = .SDL_GPU_TEXTUREUSAGE_SAMPLER
        };
        
        Texture = SDL_CreateGPUTexture(device, &textureDesc);
        
        // Upload texture data
        if (texture.Data.Length > 0)
        {
            var transferBuffer = SDL_CreateGPUTransferBuffer(device, scope .() {usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD, size = (uint32)texture.Data.Length});
            var transfer = SDL_MapGPUTransferBuffer(device, transferBuffer, false);
            
            if (transfer != null)
            {
                Internal.MemCpy(transfer, texture.Data.Ptr, texture.Data.Length);
                SDL_UnmapGPUTransferBuffer(device, transferBuffer);
                
                // Copy to texture
                var commandBuffer = SDL_AcquireGPUCommandBuffer(device);
                var copyPass = SDL_BeginGPUCopyPass(commandBuffer);
                
                var textureTransferInfo = SDL_GPUTextureTransferInfo()
                {
                    transfer_buffer = transferBuffer,
                    offset = 0,
                    pixels_per_row = texture.Width,
                    rows_per_layer = texture.Height
                };
                
                var textureRegion = SDL_GPUTextureRegion()
                {
                    texture = Texture,
                    mip_level = 0,
                    layer = 0,
                    x = 0,
                    y = 0,
                    z = 0,
                    w = texture.Width,
                    h = texture.Height,
                    d = 1
                };
                
                SDL_UploadToGPUTexture(copyPass, &textureTransferInfo, &textureRegion, false);
                SDL_EndGPUCopyPass(copyPass);
                SDL_SubmitGPUCommandBuffer(commandBuffer);
                
                SDL_ReleaseGPUTransferBuffer(device, transferBuffer);
            }
        }
    }
    
    private void CreateSampler(SDL_GPUDevice* device, TextureResource texture)
    {
        var samplerDesc = SDL_GPUSamplerCreateInfo()
        {
            min_filter = ConvertTextureFilter(texture.MinFilter),
            mag_filter = ConvertTextureFilter(texture.MagFilter),
            address_mode_u = ConvertTextureWrap(texture.WrapU),
            address_mode_v = ConvertTextureWrap(texture.WrapV),
            address_mode_w = .SDL_GPU_SAMPLERADDRESSMODE_REPEAT,
            mip_lod_bias = 0.0f,
            max_anisotropy = 1.0f
        };
        
        Sampler = SDL_CreateGPUSampler(device, &samplerDesc);
    }
    
    private static SDL_GPUTextureFormat ConvertTextureFormat(TextureResource.TextureFormat format)
    {
        switch (format)
        {
        case .R8: return .SDL_GPU_TEXTUREFORMAT_R8_UNORM;
        case .RG8: return .SDL_GPU_TEXTUREFORMAT_R8G8_UNORM;
        //case .RGB8: return .SDL_GPU_TEXTUREFORMAT_R8G8B8_UNORM;
        case .RGBA8: return .SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
        case .R16F: return .SDL_GPU_TEXTUREFORMAT_R16_FLOAT;
        case .RG16F: return .SDL_GPU_TEXTUREFORMAT_R16G16_FLOAT;
        case .RGBA16F: return .SDL_GPU_TEXTUREFORMAT_R16G16B16A16_FLOAT;
        case .R32F: return .SDL_GPU_TEXTUREFORMAT_R32_FLOAT;
        case .RG32F: return .SDL_GPU_TEXTUREFORMAT_R32G32_FLOAT;
        case .RGBA32F: return .SDL_GPU_TEXTUREFORMAT_R32G32B32A32_FLOAT;
        default: return .SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
        }
    }
    
    private static SDL_GPUFilter ConvertTextureFilter(TextureResource.TextureFilter filter)
    {
        switch (filter)
        {
        case .Nearest: return .SDL_GPU_FILTER_NEAREST;
        case .Linear: return .SDL_GPU_FILTER_LINEAR;
        default: return .SDL_GPU_FILTER_LINEAR;
        }
    }
    
    private static SDL_GPUSamplerAddressMode ConvertTextureWrap(TextureResource.TextureWrap wrap)
    {
        switch (wrap)
        {
        case .Repeat: return .SDL_GPU_SAMPLERADDRESSMODE_REPEAT;
        case .ClampToEdge: return .SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE;
        case .MirroredRepeat: return .SDL_GPU_SAMPLERADDRESSMODE_MIRRORED_REPEAT;
        default: return .SDL_GPU_SAMPLERADDRESSMODE_REPEAT;
        }
    }
}