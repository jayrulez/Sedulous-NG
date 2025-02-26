using Sedulous.Platform.Core;
using SDL3Native;
using System;
namespace Sedulous.Platform.SDL3;

class SDL3Window : Window
{
	private readonly SDL_Window* mSDLWindow;
	private readonly uint32 mSDLWindowId;

	public uint32 Id => mSDLWindowId;

	private uint32 mWidth;
	private uint32 mHeight;

	public override uint32 Width => mWidth;

	public override uint32 Height => mHeight;

	public override StringView Title
	{
		get
		{
			return StringView(SDL_GetWindowTitle(null));
		}

		set
		{
			SDL_SetWindowTitle(null, value.Ptr);
		}
	}

	public this(StringView title, uint32 width, uint32 height)
		: base()
	{
		mWidth = width;
		mHeight = height;

		SDL_WindowFlags flags = .SDL_WINDOW_RESIZABLE;

		mSDLWindow = SDL_CreateWindow(title.Ptr, (int32)mWidth, (int32)mHeight, flags);
		if (mSDLWindow == null)
		{
			Runtime.FatalError("SDL window creation failed.");
		}

		mSDLWindowId = SDL_GetWindowID(mSDLWindow);

		String videoDriver = scope .(SDL_GetCurrentVideoDriver());
		switch (videoDriver) {
		case "windows":
			SurfaceInfo = .()
				{
					Type = .Win32,
					Win32 = .()
						{
							Hwnd = SDL_GetPointerProperty(SDL_GetWindowProperties(mSDLWindow), SDL_PROP_WINDOW_WIN32_HWND_POINTER, null)
						}
				};
			break;

		case "x11":
			SurfaceInfo = .()
				{
					Type = .X11,
					X11 = .()
						{
							Display = SDL_GetPointerProperty(SDL_GetWindowProperties(mSDLWindow), SDL_PROP_WINDOW_X11_DISPLAY_POINTER, null),
							Window = (uint64)(int)SDL_GetPointerProperty(SDL_GetWindowProperties(mSDLWindow), SDL_PROP_WINDOW_X11_WINDOW_NUMBER, null)
						}
				};
			break;

		case "wayland":
			SurfaceInfo = .()
				{
					Type = .Wayland,
					Wayland = .()
						{
							Display = SDL_GetPointerProperty(SDL_GetWindowProperties(mSDLWindow), SDL_PROP_WINDOW_WAYLAND_DISPLAY_POINTER, null),
							Surface = SDL_GetPointerProperty(SDL_GetWindowProperties(mSDLWindow), SDL_PROP_WINDOW_WAYLAND_SURFACE_POINTER, null)
						}
				};
			break;

		case "android":
			SurfaceInfo = .()
				{
					Type = .Android,
					Android = .()
						{
							Window = SDL_GetPointerProperty(SDL_GetWindowProperties(mSDLWindow), SDL_PROP_WINDOW_ANDROID_WINDOW_POINTER, null),
							Surface = SDL_GetPointerProperty(SDL_GetWindowProperties(mSDLWindow), SDL_PROP_WINDOW_ANDROID_SURFACE_POINTER, null)
						}
				};
			break;

			// todo: support these platforms
		case "cocoa",
			"ios": fallthrough;
		default:
			Runtime.FatalError("Subsystem not currently supported.");
		}
	}

	public ~this()
	{
		SDL_DestroyWindow(mSDLWindow);
	}

	public override void* GetNativePointer(String name)
	{
		switch (name) {
		case "SDL":
			return mSDLWindow;

		default: return null;
		}
	}

	internal bool HandleEvent(SDL_WindowEvent ev)
	{
		if (ev.windowID != mSDLWindowId)
		{
			return false;
		}

		switch (ev.type)
		{
		case .SDL_EVENT_WINDOW_RESIZED:
			mWidth = (uint32)ev.data1;
			mHeight = (uint32)ev.data2;
			OnResized.Invoke(mWidth, mHeight);
			return true;

		default: return false;
		}
	}
}