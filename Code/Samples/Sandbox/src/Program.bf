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
	public static void Main(params String[] args)
	{
		ILogger logger = scope DebugLogger(.Trace);

		var windowSystem = scope SDL3WindowSystem("Sample", 1280, 720);

		var window = windowSystem.PrimaryWindow;

		var engine = scope Engine( /*null,*/logger);

		var engineInitializer = scope EngineInitializer();

		var renderer = scope SDLRendererSubsystem((SDL3Window)window);
		engineInitializer.AddSubsystem(renderer);
		engineInitializer.AddSubsystem(scope OpenALAudioSubsystem());
		engineInitializer.AddSubsystem(scope NavigationSubsystem());
		engineInitializer.AddSubsystem(scope PhysicsSubsystem());

		if (engine.Initialize(engineInitializer) case .Err)
		{
			logger.LogError("Engine initialization failed.");
			return;
		}

		{
		// Create and set up the camera
			var camera = scope:: Camera();
			camera.Position = Vector3(0, 4, -15);
			camera.Forward = Vector3(0, 0, 1);

			renderer.Camera = camera;
		}

		windowSystem.StartMainLoop();
		while (windowSystem.IsRunning)
		{
			windowSystem.RunOneFrame(scope => engine.Update);
		}
		windowSystem.StopMainLoop();

		defer engine.Shutdown();
	}
}