using System;
using Sedulous.Platform.Core;
using Sedulous.Mathematics;
using Sedulous.Foundation.Logging.Debug;
using Sedulous.Foundation.Logging.Abstractions;
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

class Program
{
	public static void Main(params String[] args)
	{
		ILogger logger = scope DebugLogger(.Trace);

		var windowSystem = scope SDL3WindowSystem("Sandbox", 1280, 720);
		var app = scope Application(logger, windowSystem);

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
				// Setup input actions
				/*var actionManager = inputSubsystem.ActionManager;
				var keyboard = inputSubsystem.GetKeyboard();
				var mouse = inputSubsystem.GetMouse();

				actionManager.RegisterAction("MoveForward", new KeyAction(keyboard, .W));
				actionManager.RegisterAction("MoveBack", new KeyAction(keyboard, .S));
				actionManager.RegisterAction("MoveLeft", new KeyAction(keyboard, .A));
				actionManager.RegisterAction("MoveRight", new KeyAction(keyboard, .D));
				actionManager.RegisterAction("Jump", new KeyAction(keyboard, .Space));
				actionManager.RegisterAction("Fire", new MouseButtonAction(mouse, .Left));*/

				// Create a scene
				var scene = engine.SceneGraphSystem.CreateScene("Main Scene").Value;
				engine.SceneGraphSystem.SetActiveScene(scene);

				// Create player entity
				//var player = scene.CreateEntity("Player");
				//var mesh = player.AddComponent<MeshRenderer>();
				//mesh.Mesh = ResourceHandle<Mesh>(MeshPrimitives.CreateCube());
				//mesh.Material = ResourceHandle<Material>(new Material());
				//player.AddComponent<InputComponent>();

				// Setup camera
				/*var cameraEntity = scene.CreateEntity("Camera");
				var camera = cameraEntity.AddComponent<Camera>();
				camera.FieldOfView = 75.0f;
				cameraEntity.Transform.Position = Vector3(0, 5, -10);*/

				// Create camera
				var cameraEntity = scene.CreateEntity("Camera");
				cameraEntity.Transform.Position = Vector3(0, 0, -5);
				cameraEntity.Transform.LookAt(Vector3.Zero, Vector3.Up); // Look at origin
				var camera = cameraEntity.AddComponent<Camera>();
				camera.FieldOfView = 75.0f;

				// Create light
				var lightEntity = scene.CreateEntity("Light");
				lightEntity.Transform.Rotation = Quaternion.RotationYawPitchRoll(0, Math.DegreesToRadians(-45), 0);
				var light = lightEntity.AddComponent<Light>();
				light.Type = .Directional;
				light.Color = Vector3(1, 0.95f, 0.8f);
				light.Intensity = 1.0f;

				// Create objects
				for (int i = 0; i < 1; i++)
				{
					var cube = scene.CreateEntity(scope $"Cube{i}");
					cube.Transform.Position = Vector3(i * 2 - 4, i, 0);
					cube.Transform.Scale = Vector3(1, 1, 1);
					var renderer = cube.AddComponent<MeshRenderer>();
					renderer.Color = Vector4(
						(float)i / 4.0f, // Red gradient
						0.5f, // Green
						1.0f - (float)i / 4.0f, // Blue gradient
						1.0f // Alpha
						);
					renderer.UseLighting = true;
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
						mesh.SetColor(v, Color(renderer.Color).ToPackedRGBA());
					}
					renderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(mesh, true));
				}
			},
			shuttingDownCallback: scope (engine) => { }
			);
	}
}