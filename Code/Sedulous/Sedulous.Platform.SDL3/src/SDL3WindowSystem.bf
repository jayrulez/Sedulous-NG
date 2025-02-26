using Sedulous.Platform.Core;
using System.Diagnostics;
using SDL3Native;
using System;
using System.Collections;
namespace Sedulous.Platform.SDL3;

using internal Sedulous.Platform.SDL3;

class SDL3WindowSystem : WindowSystem
{
	private static bool sSDLInitialized = false;

	public static bool SDLInitialized => sSDLInitialized;

	static this()
	{
		if (!SDL_Init(.SDL_INIT_EVENTS | .SDL_INIT_VIDEO | .SDL_INIT_AUDIO | .SDL_INIT_GAMEPAD))
		{
			Runtime.FatalError(scope $"SDL initialization failed: {SDL_GetError()}");
		}
		sSDLInitialized = true;
	}

	static ~this()
	{
		if (sSDLInitialized)
		{
			SDL_Quit();
		}
	}

	private readonly List<SDL3Window> mWindows = new .() ~ delete _;

	private readonly SDL3Window mPrimaryWindow;

	public override Window PrimaryWindow => mPrimaryWindow;

	private readonly Stopwatch mTimer = new .() ~ delete _;

	private bool mIsRunning = false;

	public override bool IsRunning => mIsRunning;

	private static bool SDLEventFilter(void* userData, SDL_Event* event)
	{
		if (userData == null || event == null)
		{
			return true;
		}

		SDL3WindowSystem windowSystem = (SDL3WindowSystem)Internal.UnsafeCastToObject(userData);
		if (windowSystem == null)
		{
			return true;
		}

		switch ((SDL_EventType)event.type)
		{
		case .SDL_EVENT_TERMINATING:
			return false;

		case .SDL_EVENT_WILL_ENTER_BACKGROUND:
			return false;

		case .SDL_EVENT_DID_ENTER_BACKGROUND:
			//windowSystem.Suspend();
			return false;

		case .SDL_EVENT_WILL_ENTER_FOREGROUND:
			return false;

		case .SDL_EVENT_DID_ENTER_FOREGROUND:
			//windowSystem.Resume();
			return false;

		case .SDL_EVENT_LOW_MEMORY:
			return false;

		default: return true;
		}
	}

	public this(StringView windowTitle, uint32 windowWidth, uint32 windowHeight)
	{
		mPrimaryWindow = new SDL3Window(windowTitle, windowWidth, windowHeight);
		mWindows.Add(mPrimaryWindow);
	}

	public ~this()
	{
		delete mPrimaryWindow;
	}

	public override void StartMainLoop()
	{
		mIsRunning = true;

		SDL_SetEventFilter( => SDLEventFilter, Internal.UnsafeCastToPtr(this));

		mTimer.Start();

		SDL_PumpEvents();
	}

	public override void StopMainLoop()
	{
		mTimer.Stop();

		SDL_SetEventFilter(null, null);

		mIsRunning = false;
	}

	public override void RunOneFrame(FrameCallback callback)
	{
		// todo: reset input devices

		SDL_Event ev = .();

		while (SDL_PollEvent(&ev))
		{
			switch ((SDL_EventType)ev.type) {
			case .SDL_EVENT_QUIT:
				mIsRunning = false;
				break;

			default:
				if (ev.type >= (uint32)SDL_EventType.SDL_EVENT_WINDOW_FIRST && ev.type <= (uint32)SDL_EventType.SDL_EVENT_WINDOW_LAST)
				{
					var window = GetWindowById(ev.window.windowID);
					window?.HandleEvent(ev.window);
				} else
				{

					// todo: handle input event
					/*if (mInputSystem.HandleEvent(ev))
					{
					}*/
				}
				break;
			}
		}

		var elapsedTicks = mTimer.Elapsed.Ticks;
		mTimer.Restart();

		callback?.Invoke(elapsedTicks);

		// todo: update input
	}

	private SDL3Window GetWindowById(uint32 windowId)
	{
		for(var window in mWindows)
		{
			if(window.Id == windowId)
			{
				return window;
			}
		}
		return null;
	}
}