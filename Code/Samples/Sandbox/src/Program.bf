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
namespace Sandbox;

public class RotateComponent : Component
{
    private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<Self>();
    public override ComponentTypeId TypeId => sTypeId;
}

public class AppSceneModule : SceneModule
{
	public override StringView Name => nameof(AppSceneModule);
	

	protected override void RegisterComponentInterests()
	{
		RegisterComponentInterest<RotateComponent>();
	}

	protected override bool ShouldTrackEntity(Entity entity)
	{
		return entity.HasComponent<RotateComponent>();
	}

	protected override void OnUpdate(Time time)
	{
		for(var entity in TrackedEntities)
		{
			if(entity.HasComponent<MeshRenderer>())
			{
				entity.Transform.Rotation = Quaternion.CreateFromRotationMatrix(Matrix.CreateRotationY((float)time.TotalTime.TotalMilliseconds * 0.001f));
				entity.Transform.MarkDirty();
			}
		}
	}
}

class SandboxApplication : Application
{
	private IEngine.RegisteredUpdateFunctionInfo? mUpdateFunctionRegistration;

	// Camera rotation tracking
	private float mCameraYaw = 0.0f;
	private float mCameraPitch = 0.0f;

	public this(ILogger logger, WindowSystem windowSystem) : base(logger, windowSystem)
	{
	}

	private void OnUpdate(IEngine.UpdateInfo info)
	{
		var scene = info.Engine.SceneGraphSystem.ActiveScenes[0];
		
		// Camera movement
		var cameraEntity = scene.FindEntity("Camera");
		if(cameraEntity != null)
		{
			var inputSubsystem = ((Engine)info.Engine).GetSubsystem<InputSubsystem>().Value;
			var keyboard = inputSubsystem.GetKeyboard();
			var mouse = inputSubsystem.GetMouse();
			
			// Movement speed
			float moveSpeed = 5.0f * (float)info.Time.ElapsedTime.TotalSeconds;
			float rotateSpeed = 2.0f * (float)info.Time.ElapsedTime.TotalSeconds;
			
			var transform = cameraEntity.Transform;
			var position = transform.Position;
			
			// Get camera direction vectors
			var forward = transform.Forward;
			var right = transform.Right;
			
			// WASD movement (relative to camera orientation)
			if(keyboard.IsKeyDown(.W))
			{
				// Move forward
				position += forward * moveSpeed;
			}
			if(keyboard.IsKeyDown(.S))
			{
				// Move backward
				position -= forward * moveSpeed;
			}
			if(keyboard.IsKeyDown(.A))
			{
				// Move left
				position -= right * moveSpeed;
			}
			if(keyboard.IsKeyDown(.D))
			{
				// Move right
				position += right * moveSpeed;
			}
			
			// Q/E for up/down movement
			if(keyboard.IsKeyDown(.Q))
			{
				// Move down
				position.Y -= moveSpeed;
			}
			if(keyboard.IsKeyDown(.E))
			{
				// Move up
				position.Y += moveSpeed;
			}
			
			// Mouse look (if right mouse button is held)
			if(mouse.IsButtonDown(.Right))
			{
				// Get mouse delta
				var mouseDelta = mouse.PositionDelta;
				
				// Calculate rotation angles
				float yaw = -mouseDelta.X * rotateSpeed * 0.5f;   // Horizontal rotation
				float pitch = -mouseDelta.Y * rotateSpeed * 0.5f; // Vertical rotation
				
				// Get current rotation as Euler angles
				// This is a simplified approach - for production code you'd want to track euler angles separately
				var currentRotation = transform.Rotation;
				
				// Apply yaw (Y-axis rotation)
				var yawRotation = Quaternion.CreateFromAxisAngle(Vector3.Up, yaw);
				
				// Apply pitch (X-axis rotation) - but use the camera's local right axis
				var pitchRotation = Quaternion.CreateFromAxisAngle(right, pitch);
				
				// Combine rotations: first yaw (global), then pitch (local)
				transform.Rotation = yawRotation * currentRotation * pitchRotation;
			}
			
			// Alternative: Arrow keys for camera rotation
			if(keyboard.IsKeyDown(.Left))
			{
				// Rotate left
				transform.Rotation = Quaternion.CreateFromAxisAngle(Vector3.Up, rotateSpeed) * transform.Rotation;
			}
			if(keyboard.IsKeyDown(.Right))
			{
				// Rotate right
				transform.Rotation = Quaternion.CreateFromAxisAngle(Vector3.Up, -rotateSpeed) * transform.Rotation;
			}
			if(keyboard.IsKeyDown(.Up))
			{
				// Rotate up
				var r = transform.Right;
				transform.Rotation = transform.Rotation * Quaternion.CreateFromAxisAngle(r, rotateSpeed);
			}
			if(keyboard.IsKeyDown(.Down))
			{
				// Rotate down
				var r = transform.Right;
				transform.Rotation = transform.Rotation * Quaternion.CreateFromAxisAngle(r, -rotateSpeed);
			}
			
			// Update position and mark dirty
			transform.Position = position;
			transform.MarkDirty();
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
		cameraEntity.Transform.Position = Vector3(0, 0, -8);
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
		
		var plane = scene.CreateEntity("Plane");
		plane.Transform.Position = Vector3(0, -1, 0);
		plane.Transform.Scale = Vector3(1, 1, 1);
		plane.Transform.MarkDirty();
		var renderer = plane.AddComponent<MeshRenderer>();
		renderer.Color = Color.Green;
		//renderer.UseLighting = true;
		Mesh mesh = Mesh.CreatePlane();

		for (int32 v = 0; v < mesh.Vertices.VertexCount; v++)
		{
			mesh.SetColor(v, renderer.Color.PackedValue);
		}
		renderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(mesh, true));

		/*{
			// Create debug objects to verify coordinate system
			// Create a red cube at +X (should be on the right)
			var rightCube = scene.CreateEntity("RightCube");
			rightCube.Transform.Position = Vector3(3, 0, 0);  // +X direction
			rightCube.Transform.Scale = Vector3(0.5f, 0.5f, 0.5f);
			var rightRenderer = rightCube.AddComponent<MeshRenderer>();
			rightRenderer.Color = Color(1.0f, 0.0f, 0.0f, 1.0f); // Red
			var rightMesh = Mesh.CreateCube();
			for (int32 v = 0; v < rightMesh.Vertices.VertexCount; v++)
			{
			    rightMesh.SetColor(v, rightRenderer.Color.PackedValue);
			}
			rightRenderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(rightMesh, true));

			// Create a green cube at -X (should be on the left)
			var leftCube = scene.CreateEntity("LeftCube");
			leftCube.Transform.Position = Vector3(-3, 0, 0);  // -X direction
			leftCube.Transform.Scale = Vector3(0.5f, 0.5f, 0.5f);
			var leftRenderer = leftCube.AddComponent<MeshRenderer>();
			leftRenderer.Color = Color(0.0f, 1.0f, 0.0f, 1.0f); // Green
			var leftMesh = Mesh.CreateCube();
			for (int32 v = 0; v < leftMesh.Vertices.VertexCount; v++)
			{
			    leftMesh.SetColor(v, leftRenderer.Color.PackedValue);
			}
			leftRenderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(leftMesh, true));

			// Create a blue cube at +Z (should be backward/away from camera in right-handed system)
			var backCube = scene.CreateEntity("BackCube");
			backCube.Transform.Position = Vector3(0, 0, 3);  // +Z direction
			backCube.Transform.Scale = Vector3(0.5f, 0.5f, 0.5f);
			var backRenderer = backCube.AddComponent<MeshRenderer>();
			backRenderer.Color = Color(0.0f, 0.0f, 1.0f, 1.0f); // Blue
			var backMesh = Mesh.CreateCube();
			for (int32 v = 0; v < backMesh.Vertices.VertexCount; v++)
			{
			    backMesh.SetColor(v, backRenderer.Color.PackedValue);
			}
			backRenderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(backMesh, true));

			// Create a yellow cube at -Z (should be forward/toward camera in right-handed system)
			var frontCube = scene.CreateEntity("FrontCube");
			frontCube.Transform.Position = Vector3(0, 0, -3);  // -Z direction
			frontCube.Transform.Scale = Vector3(0.5f, 0.5f, 0.5f);
			var frontRenderer = frontCube.AddComponent<MeshRenderer>();
			frontRenderer.Color = Color(1.0f, 1.0f, 0.0f, 1.0f); // Yellow
			var frontMesh = Mesh.CreateCube();
			for (int32 v = 0; v < frontMesh.Vertices.VertexCount; v++)
			{
			    frontMesh.SetColor(v, frontRenderer.Color.PackedValue);
			}
			frontRenderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(frontMesh, true));

			engine.Logger.LogInformation("Debug cubes created:");
			engine.Logger.LogInformation("- Red cube at +X (3,0,0) - should be on RIGHT");
			engine.Logger.LogInformation("- Green cube at -X (-3,0,0) - should be on LEFT");
			engine.Logger.LogInformation("- Blue cube at +Z (0,0,3) - should be BEHIND center");
			engine.Logger.LogInformation("- Yellow cube at -Z (0,0,-3) - should be in FRONT of center");
		}*/

		base.OnEngineInitialized(engine);
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