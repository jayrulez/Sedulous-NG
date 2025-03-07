using System;
using Sedulous.Platform.Core;
using Sedulous.Foundation.Mathematics;
using Sedulous.Foundation.Logging.Debug;
using Sedulous.Foundation.Logging.Abstractions;
using Sedulous.Engine.Core;
using Sedulous.Engine.Renderer.SDL;
using Sedulous.Engine.Audio.OpenAL;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Physics;
using Sedulous.Platform.SDL3;
using Sedulous.Engine.Renderer;
namespace Sandbox;

class Program
{
	class EngineHost : IEngineHost
	{
		private readonly Engine mEngine;

		public IEngine Engine => mEngine;

		public bool IsRunning => mWindowSystem.IsRunning;

		private bool mIsSuspended = false;

		public bool IsSuspended => mIsSuspended;

		public bool SupportsMultipleThreads => true;

		private readonly SDL3WindowSystem mWindowSystem;

		public WindowSystem WindowSystem => mWindowSystem;

		private readonly ILogger mLogger;

		public this(ILogger logger, StringView windowTitle, uint32 windowWidth, uint32 windowHeight)
		{
			mLogger = logger;

			mWindowSystem = new SDL3WindowSystem(windowTitle, windowWidth, windowHeight);

			mEngine = new .(this, mLogger);
		}

		public ~this()
		{
			delete mEngine;

			delete mWindowSystem;
		}

		public void Exit()
		{
			mWindowSystem.RequestExit();
		}

		public void Run(EngineInitializingCallback initializingCallback = null,
			EngineInitializedCallback initializedCallback = null,
			EngineShuttingDownCallback shuttingDownCallback = null)
		{
			EngineInitializer engineInitializer = new .();

			if (initializingCallback != null)
			{
				initializingCallback(engineInitializer);
			}

			if (mEngine.Initialize(engineInitializer) case .Err)
			{
				mLogger?.LogError("Engine initialization failed.");
				return;
			}

			if (initializedCallback != null)
			{
				initializedCallback(mEngine);
			}

			mWindowSystem.StartMainLoop();
			while (mWindowSystem.IsRunning)
			{
				mWindowSystem.RunOneFrame(scope => mEngine.Update);
			}
			mWindowSystem.StopMainLoop();


			if (shuttingDownCallback != null)
			{
				shuttingDownCallback(mEngine);
			}

			mEngine.Shutdown();
			delete engineInitializer;
		}
	}

	public static void Main(params String[] args)
	{
		ILogger logger = scope DebugLogger(.Trace);

		var host = scope EngineHost(logger, "Sandbox", 1280, 720);

		var renderer = scope SDLRendererSubsystem((SDL3Window)host.WindowSystem.PrimaryWindow);
		var audioSubsystem = scope OpenALAudioSubsystem();
		var navigationSubsystem = scope NavigationSubsystem();
		var physicsSubsystem = scope PhysicsSubsystem();

		host.Run(
			initializingCallback: scope (initializer) =>
			{
				initializer.AddSubsystem(renderer);
				initializer.AddSubsystem(audioSubsystem);
				initializer.AddSubsystem(navigationSubsystem);
				initializer.AddSubsystem(physicsSubsystem);
				return .Ok;
			},
			initializedCallback: scope (engine) =>
			{

				// Create and set up the camera
				var camera = scope:: Camera();
				camera.Position = Vector3(0, 4, -15);
				camera.Forward = Vector3(0, 0, 1);

				//renderer.Camera = camera;
			},
			shuttingDownCallback: scope (engine) => { }
			);
	}
}