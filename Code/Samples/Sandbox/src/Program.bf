using System;
using Sedulous.Platform.Core;
using Sedulous.Mathematics;
using Sedulous.Logging.Debug;
using Sedulous.Logging.Abstractions;
using Sedulous.Engine.Core;
using Sedulous.Engine.Renderer.SDL;
using Sedulous.Engine.Audio.OpenAL;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Physics;
using Sedulous.Platform.SDL3;
using Sedulous.Engine.Renderer;
using Sedulous.Runtime;
using Sedulous.Engine.Input;
using Sedulous.Resources;
using Sedulous.Geometry;
namespace Sandbox;

class SandboxApplication : Application
{
	private IEngine.RegisteredUpdateFunctionInfo? mUpdateFunctionRegistration;

	public this(ILogger logger, WindowSystem windowSystem) : base(logger, windowSystem)
	{
	}

	private void OnUpdate(IEngine.UpdateInfo info)
	{
		var scene = info.Engine.SceneGraphSystem.ActiveScenes[0];

		for(var entity in scene.Entities)
		{
			if(entity.HasComponent<MeshRenderer>())
			{
				//entity.Transform.Rotation = Quaternion.CreateFromRotationMatrix(Matrix.CreateRotationY((float)info.Time.TotalTime.TotalMilliseconds * 0.001f));
				//entity.Transform.MarkDirty();
			}
		}
	}

	protected override void OnEngineShuttingDown(Engine engine)
	{
		if (mUpdateFunctionRegistration != null)
		{
			delete mUpdateFunctionRegistration.Value.Function;
		}
	}

	protected override void OnEngineInitialized(Engine engine)
	{
		mUpdateFunctionRegistration = engine.RegisterUpdateFunction(.()
			{
				Priority = 0,
				Stage = .VariableUpdate,
				Function = new => OnUpdate
			});

		// Setup input actions
		if (engine.GetSubsystem<InputSubsystem>() case .Ok(var inputSubsystem))
		{
			var actionManager = inputSubsystem.ActionManager;
			var keyboard = inputSubsystem.GetKeyboard();
			var mouse = inputSubsystem.GetMouse();

			actionManager.RegisterAction("MoveForward", new KeyAction(keyboard, .W));
			actionManager.RegisterAction("MoveBack", new KeyAction(keyboard, .S));
			actionManager.RegisterAction("MoveLeft", new KeyAction(keyboard, .A));
			actionManager.RegisterAction("MoveRight", new KeyAction(keyboard, .D));
			actionManager.RegisterAction("Jump", new KeyAction(keyboard, .Space));
			actionManager.RegisterAction("Fire", new MouseButtonAction(mouse, .Left));
		} else
		{
			Logger.LogInformation(scope $"'{nameof(InputSubsystem)}' was not registered.");
		}

		// Create a scene
		var scene = engine.SceneGraphSystem.CreateScene("Main Scene").Value;
		engine.SceneGraphSystem.SetActiveScene(scene);

		// Create camera
		var cameraEntity = scene.CreateEntity("Camera");
		cameraEntity.Transform.Position = Vector3(0, 1, -5);
		cameraEntity.Transform.LookAt(Vector3.Zero); // Look at origin
		cameraEntity.Transform.MarkDirty();
		var camera = cameraEntity.AddComponent<Camera>();
		camera.FieldOfView = 75.0f;

		// Create light
		var lightEntity = scene.CreateEntity("Light");
		lightEntity.Transform.Rotation = Quaternion.CreateFromYawPitchRoll(0, Math.DegreesToRadians(-45), 0);
		var light = lightEntity.AddComponent<Light>();
		light.Type = .Directional;
		light.Color = Vector3(1, 0.95f, 0.8f);
		light.Intensity = 1.0f;

		// Create objects
		for (int i = 0; i < 5; i++)
		{
			var geometry = scene.CreateEntity(scope $"Geometry{i}");
			geometry.Transform.Position = Vector3(i * 2 - 4, 0, 0);
			geometry.Transform.Scale = Vector3(1, 1, 1);
			geometry.Transform.MarkDirty();
			var renderer = geometry.AddComponent<MeshRenderer>();
			renderer.Color = .(
				(float)i / 4.0f, // Red gradient
				0.5f, // Green
				1.0f - (float)i / 4.0f, // Blue gradient
				1.0f // Alpha
				);
			//renderer.UseLighting = true;
			Mesh mesh = null;

			if (i == 0)
				mesh = Mesh.CreateCube();
			else if (i == 1)
				mesh = Mesh.CreateSphere();
			else if (i == 2)
				mesh = Mesh.CreateCylinder();
			else if (i == 3)
				mesh = Mesh.CreateCone();
			else if (i == 4)
				mesh = Mesh.CreateTorus();
			else
				mesh = Mesh.CreatePlane();

			for (int32 v = 0; v < mesh.Vertices.VertexCount; v++)
			{
				mesh.SetColor(v, renderer.Color.PackedValue);
			}
			renderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(mesh, true));
		}

		base.OnEngineInitialized(engine);
	}
}

class Program
{
	public static void Main(params String[] args)
	{
		ILogger logger = scope DebugLogger(.Trace);

		var windowSystem = scope SDL3WindowSystem("Sandbox", 1280, 720);
		var app = scope SandboxApplication(logger, windowSystem);

		var renderer = scope SDLRendererSubsystem((SDL3Window)windowSystem.PrimaryWindow);
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