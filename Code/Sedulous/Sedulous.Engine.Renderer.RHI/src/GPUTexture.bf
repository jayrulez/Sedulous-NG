using System;
using Sedulous.Imaging;
using Sedulous.Engine.Renderer.GPU;
using Sedulous.RHI;

namespace Sedulous.Engine.Renderer.RHI;

class GPUTexture : GPUResource
{
	public Texture Texture;

	private GraphicsContext mGraphicsContext;

	public this(StringView name, GraphicsContext context, TextureResource textureResource)
		: base(name)
	{
		mGraphicsContext = context;
		if (textureResource.Image != null)
		{
			CreateTexture(textureResource.Image, textureResource.GenerateMipmaps);
		}
		else
		{
			mGraphicsContext.Logger.LogError("TextureResource has null Image");
		}
	}

	// Convenience constructor for just an image with default settings
	public this(StringView name, GraphicsContext context, Image image)
		: base(name)
	{
		mGraphicsContext = context;
		CreateTexture(image, false);
	}

	public ~this()
	{
		if (mGraphicsContext != null)
		{
			if (Texture != null)
			{
				mGraphicsContext.Factory.DestroyTexture(ref Texture);
				Texture = null;
			}
		}
	}

	private void CreateTexture(Image image, bool generateMipmaps)
	{
		var textureDesc = TextureDescription.CreateTexture2DDescription(image.Width, image.Height, ConvertPixelFormat(image.Format));

		uint32 bytesPerPixel = (uint32)Image.GetBytesPerPixel(image.Format);
		uint32 rowPitch = image.Width * bytesPerPixel;
		uint32 slicePitch = rowPitch * image.Height;

		DataBox data = DataBox(image.Data.Ptr, rowPitch, slicePitch);

		Texture = mGraphicsContext.Factory.CreateTexture(scope DataBox[](data), textureDesc);

		if (Texture == null)
		{
			mGraphicsContext.Logger.LogError("Failed to create GPU texture");
			return;
		}
	}

	private static PixelFormat ConvertPixelFormat(Image.PixelFormat format)
	{
		switch (format)
		{
		case .R8: return .R8_UNorm;
		case .RG8: return .R8G8_UNorm;
		case .RGB8: return .R8G8B8A8_UNorm; // No RGB8 in SDL_GPU, use RGBA8
		case .RGBA8: return .R8G8B8A8_UNorm;
		case .BGR8: return .B8G8R8A8_UNorm; // Assuming BGR8 maps to BGRA8
		case .BGRA8: return .B8G8R8A8_UNorm;
		case .R16F: return .R16_Float;
		case .RG16F: return .R16G16_Float;
		case .RGB16F: return .R16G16B16A16_Float; // No RGB16F, use RGBA16F
		case .RGBA16F: return .R16G16B16A16_Float;
		case .R32F: return .R32_Float;
		case .RG32F: return .R32G32_Float;
		case .RGB32F: return .R32G32B32_Float;
		case .RGBA32F: return .R32G32B32A32_Float;
		default: return .R8G8B8A8_UNorm;
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