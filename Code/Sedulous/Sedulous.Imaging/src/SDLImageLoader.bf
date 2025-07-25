using System.Collections;
using System;
using SDL3_image;
using SDL3Native;
namespace Sedulous.Imaging;

class SDLImageLoader : ImageLoader
{
	private static List<StringView> sSupportedExtensions = new .() { ".png", ".jpg" } ~ delete _;

	private static Image.PixelFormat SDLSurfaceFormatToPixelFormat(SDL_PixelFormat sdlFormat)
	{
		switch (sdlFormat)
		{
		case .SDL_PIXELFORMAT_RGB24:
			return .RGB8;
		case .SDL_PIXELFORMAT_BGR24:
			return .BGR8;
		case .SDL_PIXELFORMAT_RGBA8888,
			.SDL_PIXELFORMAT_RGBA32:
			return .RGBA8;
		case .SDL_PIXELFORMAT_BGRA8888,
			.SDL_PIXELFORMAT_BGRA32:
			return .BGRA8;
		/*case .SDL_PIXELFORMAT_ABGR8888,
			 .SDL_PIXELFORMAT_ABGR32:
			return .RGBA8;  // Note: ABGR will need swizzling to RGBA
		case .SDL_PIXELFORMAT_ARGB8888,
			 .SDL_PIXELFORMAT_ARGB32:
			return .BGRA8;  // Note: ARGB will need swizzling to BGRA*/
		case .SDL_PIXELFORMAT_RGB48_FLOAT:
			return .RGB16F;
		case .SDL_PIXELFORMAT_BGR48_FLOAT:
			return .RGB16F; // Note: BGR will need swizzling
		case .SDL_PIXELFORMAT_RGBA64_FLOAT:
			return .RGBA16F;
		case .SDL_PIXELFORMAT_BGRA64_FLOAT:
			return .RGBA16F; // Note: BGRA will need swizzling
		case .SDL_PIXELFORMAT_ABGR64_FLOAT:
			return .RGBA16F; // Note: ABGR will need swizzling
		case .SDL_PIXELFORMAT_ARGB64_FLOAT:
			return .RGBA16F; // Note: ARGB will need swizzling
		case .SDL_PIXELFORMAT_RGB96_FLOAT:
			return .RGB32F;
		case .SDL_PIXELFORMAT_BGR96_FLOAT:
			return .RGB32F; // Note: BGR will need swizzling
		case .SDL_PIXELFORMAT_RGBA128_FLOAT:
			return .RGBA32F;
		case .SDL_PIXELFORMAT_BGRA128_FLOAT:
			return .RGBA32F; // Note: BGRA will need swizzling
		case .SDL_PIXELFORMAT_ABGR128_FLOAT:
			return .RGBA32F; // Note: ABGR will need swizzling
		case .SDL_PIXELFORMAT_ARGB128_FLOAT:
			return .RGBA32F; // Note: ARGB will need swizzling
		default:
			// For unsupported formats, default to RGBA8
			return .RGBA8;
		}
	}

	public override System.Result<LoadInfo, LoadResult> LoadFromFile(System.StringView filePath)
	{
		SDL_Surface* surface = SDL3_image.IMG_Load(filePath.Ptr);
		if (surface == null)
		{
			return .Err(.FileNotFound);
		}
		defer SDL_DestroySurface(surface);

		uint8[] pixelData = new .[surface.pitch * surface.h];
		Internal.MemCpy(pixelData.Ptr, surface.pixels, pixelData.Count);

		return .Ok(.()
			{
				Width = (uint32)surface.w,
				Height = (uint32)surface.h,
				Format = SDLSurfaceFormatToPixelFormat(surface.format),
				Data = pixelData
			});
	}

	public override System.Result<LoadInfo, LoadResult> LoadFromMemory(System.Span<uint8> data)
	{
		SDL_IOStream* stream = SDL_IOFromMem(data.Ptr, (uint)data.Length);
		SDL_Surface* surface = SDL3_image.IMG_Load_IO(stream, true);
		if (surface == null)
		{
			return .Err(.UnsupportedFormat);
		}
		defer SDL_DestroySurface(surface);

		uint8[] pixelData = new .[surface.pitch * surface.h];
		Internal.MemCpy(pixelData.Ptr, surface.pixels, pixelData.Count);

		return .Ok(.()
			{
				Width = (uint32)surface.w,
				Height = (uint32)surface.h,
				Format = SDLSurfaceFormatToPixelFormat(surface.format),
				Data = pixelData
			});
	}

	public override bool SupportsExtension(System.StringView @extension)
	{
		return sSupportedExtensions.Contains(@extension);
	}

	public override void GetSupportedExtensions(System.Collections.List<StringView> outExtensions)
	{
		outExtensions.AddRange(sSupportedExtensions);
	}
}