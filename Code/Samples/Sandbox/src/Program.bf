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
using Sedulous.SceneGraph;
using Sedulous.Utilities;
using System.Collections;
namespace Sandbox;

public class RotateComponent : Component
{
	private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<Self>();
	public override ComponentTypeId TypeId => sTypeId;
}

public class ControllerComponent : Component
{
	private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<Self>();
	public override ComponentTypeId TypeId => sTypeId;

	public float MoveSpeed { get; set; } = 5.0f; // Units per second
}

public class AppSceneModule : SceneModule
{
	public override StringView Name => nameof(AppSceneModule);
	private readonly AppSubsystem mSubsystem;
	public this(AppSubsystem subsystem)
	{
		mSubsystem = subsystem;
	}
	protected override void RegisterComponentInterests()
	{
		RegisterComponentInterest<RotateComponent>();
		RegisterComponentInterest<ControllerComponent>();
	}
	protected override bool ShouldTrackEntity(Entity entity)
	{
		return entity.HasComponent<RotateComponent>() || entity.HasComponent<ControllerComponent>();
	}
	protected override void OnUpdate(Time time)
	{
		for (var entity in TrackedEntities)
		{
			if (entity.HasComponent<RotateComponent>() && entity.HasComponent<MeshRenderer>())
			{
				entity.Transform.Rotation = Quaternion.CreateFromRotationMatrix(Matrix.CreateRotationY((float)time.TotalTime.TotalMilliseconds * 0.001f));
			}
			if (entity.HasComponent<ControllerComponent>())
			{
				if (((Engine)mSubsystem.Engine).GetSubsystem<InputSubsystem>() case .Ok(var input))
				{
					var kb = input.GetKeyboard();
					var controller = entity.GetComponent<ControllerComponent>();
					var moveSpeed = controller.MoveSpeed * (float)time.ElapsedTime.TotalSeconds;
					var position = entity.Transform.Position;

					if (kb.IsKeyDown(.KeypadD4))
					{
						position.X -= moveSpeed;
					}
					if (kb.IsKeyDown(.KeypadD6))
					{
						position.X += moveSpeed;
					}
					if (kb.IsKeyDown(.KeypadD8))
					{
						position.Y += moveSpeed;
					}
					if (kb.IsKeyDown(.KeypadD2))
					{
						position.Y -= moveSpeed;
					}

					entity.Transform.Position = position;
				}
			}
		}
	}
}

class AppSubsystem : Subsystem
{
	public override StringView Name => nameof(AppSubsystem);

	private AppSceneModule mModule;

	protected override void CreateSceneModules(Scene scene, List<SceneModule> modules)
	{
		modules.Add(mModule = new AppSceneModule(this));
	}
	protected override void DestroySceneModules(Scene scene)
	{
		delete mModule;
	}
}

class SandboxApplication : Application
{
	private IEngine.RegisteredUpdateFunctionInfo? mUpdateFunctionRegistration;

	// Camera rotation tracking
	private float mCameraYaw = 0.0f;
	private float mCameraPitch = 0.0f;
	private bool mFirstMouseMove = true;
	private Vector2 mLastMousePos = .Zero;

	private AppSubsystem mAppSubsystem;

	public this(ILogger logger, WindowSystem windowSystem) : base(logger, windowSystem)
	{
	}

	protected override void OnEngineInitializing(EngineInitializer initializer)
	{
		initializer.AddSubsystem(mAppSubsystem = new AppSubsystem());
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
		cameraEntity.Transform.Position = Vector3(0, 0, -8);
		cameraEntity.Transform.LookAt(Vector3.Zero); // Look at origin
		var camera = cameraEntity.AddComponent<Camera>();
		camera.FieldOfView = 75.0f;
		{
			// Since camera starts looking at origin from (0, 5, -8)
			// Calculate initial yaw and pitch
			var lookDir = Vector3.Normalize(Vector3.Zero - cameraEntity.Transform.Position);
			mCameraYaw = Math.Atan2(-lookDir.X, -lookDir.Z);
			mCameraPitch = Math.Asin(lookDir.Y);
		}

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
			geometry.AddComponent<RotateComponent>();
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

		var plane = scene.CreateEntity("Plane");
		plane.Transform.Position = Vector3(0, -0.5f, 0);
		plane.Transform.Scale = Vector3(1, 1, 1);
		var renderer = plane.AddComponent<MeshRenderer>();
		renderer.Color = Color.Green;
		//renderer.UseLighting = true;
		Mesh mesh = Mesh.CreatePlane();

		for (int32 v = 0; v < mesh.Vertices.VertexCount; v++)
		{
			mesh.SetColor(v, renderer.Color.PackedValue);
		}
		renderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(mesh, true));
		{
			// Create a sprite entity
			var spriteEntity = scene.CreateEntity("TestSprite");
			spriteEntity.Transform.Position = Vector3(-6, 6, 0);

			spriteEntity.AddComponent<ControllerComponent>();

			var spriteRenderer = spriteEntity.AddComponent<SpriteRenderer>();
			spriteRenderer.Texture = engine.ResourceSystem.AddResource(
				TextureResource.CreateCheckerboard(256, 32)
				);
			spriteRenderer.Color = Color(1.0f, 1f, 1f, 1.0f);
			spriteRenderer.Size = Vector2(2, 2); // 2x2 world units
			spriteRenderer.Billboard = .AxisAligned;
		}


		base.OnEngineInitialized(engine);
	}

	protected override void OnEngineShuttingDown(Engine engine)
	{
	}

	protected override void OnEngineShutDown(Engine engine)
	{
		delete mAppSubsystem;

		if (mUpdateFunctionRegistration != null)
		{
			delete mUpdateFunctionRegistration.Value.Function;
		}
	}

	private void OnUpdate(IEngine.UpdateInfo info)
	{
		var scene = info.Engine.SceneGraphSystem.ActiveScenes[0];

		// Camera movement
		var cameraEntity = scene.FindEntity("Camera");
		if (cameraEntity != null)
		{
			var inputSubsystem = ((Engine)info.Engine).GetSubsystem<InputSubsystem>().Value;
			var keyboard = inputSubsystem.GetKeyboard();
			var mouse = inputSubsystem.GetMouse();

			// Movement speed
			float moveSpeed = 5.0f * (float)info.Time.ElapsedTime.TotalSeconds;
			float mouseSensitivity = 0.002f; // Much lower value for smoother control
			float panSpeed = moveSpeed * 2.0f; // Panning is usually faster
			
			// Speed multiplier with shift
			if (keyboard.IsKeyDown(.LeftShift) || keyboard.IsKeyDown(.RightShift))
			{
				moveSpeed *= 3.0f;
				panSpeed *= 3.0f;
			}

			var transform = cameraEntity.Transform;
			var position = transform.Position;

			// Get camera direction vectors
			var forward = transform.Forward;
			var right = transform.Right;
			var up = transform.Up;

			// WASD movement (relative to camera orientation)
			if (keyboard.IsKeyDown(.W))
			{
				position += forward * moveSpeed;
			}
			if (keyboard.IsKeyDown(.S))
			{
				position -= forward * moveSpeed;
			}
			if (keyboard.IsKeyDown(.A))
			{
				position -= right * moveSpeed;
			}
			if (keyboard.IsKeyDown(.D))
			{
				position += right * moveSpeed;
			}

			// Q/E for up/down movement
			if (keyboard.IsKeyDown(.Q))
			{
				position.Y -= moveSpeed;
			}
			if (keyboard.IsKeyDown(.E))
			{
				position.Y += moveSpeed;
			}

			// Orbit around origin (Alt + Left mouse button)
			if (mouse.IsButtonDown(.Left) && keyboard.IsKeyDown(.LeftAlt))
			{
				var mouseDelta = mouse.PositionDelta;

				// Calculate the orbit rotation angle based on horizontal mouse movement
				float orbitSpeed = mouseSensitivity * 2.0f;
				float orbitAngle = -mouseDelta.X * orbitSpeed;

				// Create rotation around world Y axis
				var orbitRotation = Quaternion.CreateFromAxisAngle(Vector3.Up, orbitAngle);

				// Transform camera position around origin
				var toOrigin = position - Vector3.Zero; // Vector from origin to camera
				var rotatedPosition = Vector3.Transform(toOrigin, orbitRotation);
				position = rotatedPosition;

				// Also rotate the camera to keep looking at origin
				mCameraYaw += orbitAngle;
				var yawRotation = Quaternion.CreateFromAxisAngle(Vector3.Up, mCameraYaw);
				var pitchRotation = Quaternion.CreateFromAxisAngle(Vector3.UnitX, mCameraPitch);
				transform.Rotation = yawRotation * pitchRotation;
			}
			// Mouse look (right mouse button)
			else if (mouse.IsButtonDown(.Right))
			{
				var currentMousePos = mouse.Position;

				if (mFirstMouseMove)
				{
					mLastMousePos = currentMousePos;
					mFirstMouseMove = false;
				}

				// Calculate delta manually for more control
				var mouseDelta = currentMousePos - mLastMousePos;
				mLastMousePos = currentMousePos;

				// Update rotation angles
				mCameraYaw += mouseDelta.X * mouseSensitivity;
				mCameraPitch += mouseDelta.Y * mouseSensitivity;

				// Clamp pitch to prevent camera flipping
				mCameraPitch = Math.Clamp(mCameraPitch, -Math.PI_f * 0.49f, Math.PI_f * 0.49f);

				// Build rotation from yaw and pitch
				var yawRotation = Quaternion.CreateFromAxisAngle(Vector3.Up, mCameraYaw);
				var pitchRotation = Quaternion.CreateFromAxisAngle(Vector3.UnitX, mCameraPitch);

				// Apply rotations: first yaw (global Y), then pitch (local X)
				transform.Rotation = yawRotation * pitchRotation;
			}
			else
			{
				mFirstMouseMove = true;
			}

			// Mouse panning (middle mouse button)
			if (mouse.IsButtonDown(.Middle))
			{
				var mouseDelta = mouse.PositionDelta;

				// Pan horizontally and vertically relative to camera orientation
				position += right * mouseDelta.X * panSpeed * 0.01f; // Removed negative sign
				position += up * mouseDelta.Y * panSpeed * 0.01f;
			}

			// Mouse wheel zoom
			var wheelDelta = mouse.WheelDeltaY;
			if (Math.Abs(wheelDelta) > 0.001f)
			{
				// Move forward/backward based on wheel
				position += forward * wheelDelta * moveSpeed * 2.0f;
			}

			// Arrow keys for camera rotation (optional, can be removed if only using mouse)
			float keyRotateSpeed = 2.0f * (float)info.Time.ElapsedTime.TotalSeconds;

			if (keyboard.IsKeyDown(.Left))
			{
				mCameraYaw += keyRotateSpeed;
			}
			if (keyboard.IsKeyDown(.Right))
			{
				mCameraYaw -= keyRotateSpeed;
			}
			if (keyboard.IsKeyDown(.Up))
			{
				mCameraPitch += keyRotateSpeed;
				mCameraPitch = Math.Min(mCameraPitch, Math.PI_f * 0.49f);
			}
			if (keyboard.IsKeyDown(.Down))
			{
				mCameraPitch -= keyRotateSpeed;
				mCameraPitch = Math.Max(mCameraPitch, -Math.PI_f * 0.49f);
			}

			// Apply arrow key rotations if any were pressed
			if (keyboard.IsKeyDown(.Left) || keyboard.IsKeyDown(.Right) ||
				keyboard.IsKeyDown(.Up) || keyboard.IsKeyDown(.Down))
			{
				var yawRotation = Quaternion.CreateFromAxisAngle(Vector3.Up, mCameraYaw);
				var pitchRotation = Quaternion.CreateFromAxisAngle(Vector3.UnitX, mCameraPitch);
				transform.Rotation = yawRotation * pitchRotation;
			}

			// Update position and mark dirty
			transform.Position = position;
		}
	}
}

class Program
{
	public static void Main(params String[] args)
	{
		ILogger logger = scope DebugLogger(.Trace);

		var windowSystem = scope SDL3WindowSystem("Sandbox", 1920, 1080);
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