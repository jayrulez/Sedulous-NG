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
using Sedulous.Runtime;
using Sedulous.Engine.Input;
using Sedulous.Engine.Core.Resources;
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
				var player = scene.CreateEntity("Player");
				var mesh = player.AddComponent<MeshRenderer>();
				mesh.Mesh = ResourceHandle<Mesh>(MeshPrimitives.CreateCube());
				//player.AddComponent<InputComponent>();

				// Setup camera
				var cameraEntity = scene.CreateEntity("Camera");
				var camera = cameraEntity.AddComponent<Camera>();
				camera.FOV = 75.0f;
				cameraEntity.Transform.Position = Vector3(0, 5, -10);
			},
			shuttingDownCallback: scope (engine) => { }
			);
	}
}