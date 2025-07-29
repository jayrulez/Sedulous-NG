using System;
using Sedulous.Logging.Abstractions;
using Sedulous.Logging.Debug;
using Sedulous.Platform.SDL3;
using Sedulous.Engine.Renderer.RHI;
using Sedulous.Engine.Input;
using Sedulous.Engine.Audio.OpenAL;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Physics;
using Sedulous.RHI.Vulkan;
using Sedulous.Runtime;
using Sedulous.Engine.Core;
using Sedulous.Platform.Core;
using Sedulous.Mathematics;
using Sedulous.Engine.Renderer;
namespace SampleGame;

class SandboxGame : Application
{
	private IEngine.RegisteredUpdateFunctionInfo? mUpdateFunctionRegistration;

	public this(ILogger logger, WindowSystem windowSystem)
		: base(logger, windowSystem)
	{
	}

	protected override void OnEngineInitializing(EngineInitializer initializer)
	{
	}

	protected override void OnEngineInitialized(Engine engine)
	{
		mUpdateFunctionRegistration = engine.RegisterUpdateFunction(.()
			{
				Priority = 0,
				Stage = .VariableUpdate,
				Function = new => OnUpdate
			});


		CreateScenes(engine);

		base.OnEngineInitialized(engine);
	}

	protected override void OnEngineShuttingDown(Engine engine)
	{
	}

	protected override void OnEngineShutDown(Engine engine)
	{
		if (mUpdateFunctionRegistration != null)
		{
			delete mUpdateFunctionRegistration.Value.Function;
		}
	}

	private void OnUpdate(IEngine.UpdateInfo info)
	{
	}

	private void CreateScenes(Engine engine)
	{

		// Create a scene
		var scene = engine.SceneGraphSystem.CreateScene("Main Scene").Value;
		engine.SceneGraphSystem.SetActiveScene(scene);

		// Create camera
		var cameraEntity = scene.CreateEntity("Camera");
		cameraEntity.Transform.Position = Vector3(0, 0, -8);
		cameraEntity.Transform.LookAt(Vector3.Zero); // Look at origin
		var camera = cameraEntity.AddComponent<Camera>();
		camera.FieldOfView = 75.0f;
	}
}

class Program
{
	public static void Main(params String[] args)
	{
		ILogger logger = scope DebugLogger(.Trace);

		var windowSystem = scope SDL3WindowSystem("Sandbox", 1366, 768);
		var app = scope SandboxGame(logger, windowSystem);

		var graphicsContext = scope VKGraphicsContext(logger);
		defer graphicsContext.Dispose();
		var renderer = scope RHIRendererSubsystem((SDL3Window)windowSystem.PrimaryWindow, graphicsContext);
		var inputSubsystem = scope InputSubsystem(windowSystem.InputSystem);
		var audioSubsystem = scope OpenALAudioSubsystem();
		var navigationSubsystem = scope NavigationSubsystem();
		var physicsSubsystem = scope PhysicsSubsystem();

		app.Run(
			initializingCallback: scope (initializer) =>
			{
				initializer.AddSubsystem(inputSubsystem);
				initializer.AddSubsystem(renderer);
				initializer.AddSubsystem(audioSubsystem);
				initializer.AddSubsystem(navigationSubsystem);
				initializer.AddSubsystem(physicsSubsystem);
				return .Ok;
			},
			initializedCallback: scope (engine) =>
			{
				// Can do something here when engine is initialized
			},
			shuttingDownCallback: scope (engine) =>
			{
				// Can do something here when engine is shutting down
			}
			);
	}
}