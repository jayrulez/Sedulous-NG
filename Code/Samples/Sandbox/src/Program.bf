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

	// Light control
	private Entity mSunLightEntity;
	private DirectionalLight mSunLight;
	private float mSunYaw = 0.0f;
	private float mSunPitch = Math.DegreesToRadians(-45.0f);

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

		// Create main directional light (sun)
		mSunLightEntity = scene.CreateEntity("SunLight");
		mSunLightEntity.Transform.Rotation = Quaternion.CreateFromYawPitchRoll(mSunYaw, mSunPitch, 0);
		mSunLight = mSunLightEntity.AddComponent<DirectionalLight>();
		mSunLight.Color = Vector3(1.0f, 0.95f, 0.8f); // Warm white
		mSunLight.Intensity = 0.8f; // Reduced from 1.0 since we'll have multiple lights

		// Create point light 1 (red) - positioned to the left
		var pointLight1Entity = scene.CreateEntity("PointLight1");
		pointLight1Entity.Transform.Position = Vector3(-5, 2, -2);
		var pointLight1 = pointLight1Entity.AddComponent<PointLight>();
		pointLight1.Color = Vector3(1.0f, 0.2f, 0.2f); // Red
		pointLight1.Intensity = 2.0f;
		pointLight1.Range = 10.0f;

		// Create point light 2 (green) - positioned to the right
		var pointLight2Entity = scene.CreateEntity("PointLight2");
		pointLight2Entity.Transform.Position = Vector3(5, 2, -2);
		var pointLight2 = pointLight2Entity.AddComponent<PointLight>();
		pointLight2.Color = Vector3(0.2f, 1.0f, 0.2f); // Green
		pointLight2.Intensity = 2.0f;
		pointLight2.Range = 10.0f;

		// Create point light 3 (blue) - positioned behind
		var pointLight3Entity = scene.CreateEntity("PointLight3");
		pointLight3Entity.Transform.Position = Vector3(0, 2, 5);
		var pointLight3 = pointLight3Entity.AddComponent<PointLight>();
		pointLight3.Color = Vector3(0.2f, 0.2f, 1.0f); // Blue
		pointLight3.Intensity = 2.0f;
		pointLight3.Range = 10.0f;

		// Create spot light (white) - pointing down from above
		var spotLightEntity = scene.CreateEntity("SpotLight");
		spotLightEntity.Transform.Position = Vector3(0, 5, 0);
		spotLightEntity.Transform.LookAt(Vector3.Zero); // Point down at origin
		var spotLight = spotLightEntity.AddComponent<SpotLight>();
		spotLight.Color = Vector3(1.0f, 1.0f, 0.8f); // Slightly warm white
		spotLight.Intensity = 3.0f;
		spotLight.Range = 15.0f;
		spotLight.InnerConeAngle = 25.0f;
		spotLight.OuterConeAngle = 35.0f;

		// Add a dedicated white point light for testing PBR materials
		// Position it in front and slightly above the PBR objects (cylinder and cone)
		var pbrTestLightEntity = scene.CreateEntity("PBRTestLight");
		pbrTestLightEntity.Transform.Position = Vector3(1, 2, -4); // Front of the PBR objects
		var pbrTestLight = pbrTestLightEntity.AddComponent<PointLight>();
		pbrTestLight.Color = Vector3(1.0f, 1.0f, 1.0f); // Pure white
		pbrTestLight.Intensity = 3.0f;
		pbrTestLight.Range = 8.0f;

		// Add visual representation for the PBR test light
		var pbrLightVisual = scene.CreateEntity("PBRTestLightVisual");
		pbrLightVisual.Transform.Position = pbrTestLightEntity.Transform.Position;
		pbrLightVisual.Transform.Scale = Vector3(0.15f, 0.15f, 0.15f);
		var pbrLightRenderer = pbrLightVisual.AddComponent<MeshRenderer>();
		pbrLightRenderer.Color = Color.White;
		var pbrLightMat = new UnlitMaterial();
		pbrLightMat.Color = Color.White;
		pbrLightRenderer.Material = engine.ResourceSystem.AddResource(new MaterialResource(pbrLightMat, true));
		var pbrLightMesh = Mesh.CreateSphere(0.5f, 16, 16);
		for (int32 v = 0; v < pbrLightMesh.Vertices.VertexCount; v++)
		{
			pbrLightMesh.SetColor(v, pbrLightRenderer.Color.PackedValue);
		}
		pbrLightRenderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(pbrLightMesh, true));

		// Optional: Add visual representations for the point lights
		// These are small emissive spheres to show where the lights are
		for (int i = 1; i <= 3; i++)
		{
			var lightVisual = scene.CreateEntity(scope $"LightVisual{i}");
			var lightEntity = scene.FindEntity(scope $"PointLight{i}");
			if (lightEntity != null)
			{
				lightVisual.Transform.Position = lightEntity.Transform.Position;
				lightVisual.Transform.Scale = Vector3(0.2f, 0.2f, 0.2f);
				
				var renderer = lightVisual.AddComponent<MeshRenderer>();
				renderer.Color = Color.White;
				
				// Create unlit material with the light's color
				var unlitMat = new UnlitMaterial();
				var lightComp = lightEntity.GetComponent<PointLight>();
				unlitMat.Color = Color(
					lightComp.Color.X,
					lightComp.Color.Y,
					lightComp.Color.Z,
					1.0f
				);
				
				renderer.Material = engine.ResourceSystem.AddResource(new MaterialResource(unlitMat, true));
				
				var mesh = Mesh.CreateSphere(0.5f, 16, 16);
				for (int32 v = 0; v < mesh.Vertices.VertexCount; v++)
				{
					mesh.SetColor(v, renderer.Color.PackedValue);
				}
				renderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(mesh, true));
			}
		}

		// Create objects
		for (int i = 0; i < 5; i++)
		{
			var geometry = scene.CreateEntity(scope $"Geometry{i}");
			geometry.Transform.Position = Vector3(i * 2 - 4, 0, 0);
			geometry.Transform.Scale = Vector3(1, 1, 1);
			geometry.AddComponent<RotateComponent>();
			var renderer = geometry.AddComponent<MeshRenderer>();
			renderer.Color = Color.White;
			Mesh mesh = null;
			Material material = null;

			String materialType = "Phong";

			if (i == 0)
			{
				mesh = Mesh.CreateCube();
				materialType = "Phong";
			} else if (i == 1)
			{
				mesh = Mesh.CreateSphere();
				materialType = "Phong";
			} else if (i == 2)
			{
				mesh = Mesh.CreateCylinder();
				materialType = "PBR";
			} else if (i == 3)
			{
				mesh = Mesh.CreateCone();
				materialType = "PBR";
			} else if (i == 4)
			{
				mesh = Mesh.CreateTorus();
				materialType = "Unlit";
			} else
			{
				mesh = Mesh.CreatePlane();
				materialType = "Unlit";
			}

			for (int32 v = 0; v < mesh.Vertices.VertexCount; v++)
			{
				mesh.SetColor(v, renderer.Color.PackedValue);
			}

			if (materialType == "Phong")
			{
				var shinyMat = new PhongMaterial();
				shinyMat.DiffuseColor = Color(0.8f, 0.8f, 0.8f, 1.0f); // Light gray to show light colors
				shinyMat.SpecularColor = Color(1.0f, 1.0f, 1.0f, 1.0f);
				shinyMat.Shininess = 128.0f;
				shinyMat.AmbientColor = Color(0.1f, 0.1f, 0.1f, 1.0f);

				material = shinyMat;
			}

			if (materialType == "PBR")
			{
				// Shiny green metal
				var metalMat = new PBRMaterial();
				metalMat.AlbedoColor = Color(0.1f, 0.8f, 0.2f, 1.0f); // Green
				metalMat.Metallic = 0.5f;
				metalMat.Roughness = 0.3f; // Very glossy (was 0.1f)
				metalMat.EmissiveColor = Color.Green;

				material = metalMat;
			}

			if (materialType == "Unlit")
			{
				var unlit = new UnlitMaterial();
				unlit.Color = Color(0.5f, 0.5f, 1.0f, 1.0f); // Light blue
				material = unlit;
			}

			renderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(mesh, true));
			renderer.Material = engine.ResourceSystem.AddResource(new MaterialResource(material, true));
		}

		// Create floor plane
		var plane = scene.CreateEntity("Floor");
		plane.Transform.Position = Vector3(0, -1.5f, 0);
		plane.Transform.Scale = Vector3(10, 1, 10);
		var planeRenderer = plane.AddComponent<MeshRenderer>();
		planeRenderer.Color = Color.White;

		// Use a neutral gray material for the floor to show light colors
		var floorMat = new PhongMaterial();
		floorMat.DiffuseColor = Color(0.7f, 0.7f, 0.7f, 1.0f);
		floorMat.SpecularColor = Color(0.3f, 0.3f, 0.3f, 1.0f);
		floorMat.Shininess = 32.0f;
		floorMat.AmbientColor = Color(0.05f, 0.05f, 0.05f, 1.0f);

		planeRenderer.Material = engine.ResourceSystem.AddResource(new MaterialResource(floorMat, true));
		var planeMesh = Mesh.CreatePlane();

		for (int32 v = 0; v < planeMesh.Vertices.VertexCount; v++)
		{
			planeMesh.SetColor(v, planeRenderer.Color.PackedValue);
		}
		planeRenderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(planeMesh, true));

		// Create a sprite entity
		var spriteEntity = scene.CreateEntity("TestSprite");
		spriteEntity.Transform.Position = Vector3(-6, 6, 0);

		spriteEntity.AddComponent<ControllerComponent>();

		var spriteRenderer = spriteEntity.AddComponent<SpriteRenderer>();
		spriteRenderer.Texture = engine.ResourceSystem.AddResource(TextureResource.CreateCheckerboard(256, 32));
		spriteRenderer.Color = .White;
		spriteRenderer.Size = Vector2(2, 2); // 2x2 world units
		spriteRenderer.Billboard = .AxisAligned;

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
			var inputSubsystem = ((Engine)info.Engine).GetSubsystem<InputSubsystem>().Value;
		var cameraEntity = scene.FindEntity("Camera");
		if (cameraEntity != null)
		{
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

		// Light controls
		if (mSunLightEntity != null && mSunLight != null)
		{
			var keyboard = inputSubsystem.GetKeyboard();
			bool lightChanged = false;

			// Rotate sun with I/K (horizontal) and U/O (vertical)
			float lightRotateSpeed = 2.0f * (float)info.Time.ElapsedTime.TotalSeconds;
			if (keyboard.IsKeyDown(.I))
			{
				mSunPitch -= lightRotateSpeed;
				mSunPitch = Math.Clamp(mSunPitch, -Math.PI_f * 0.49f, Math.PI_f * 0.49f);
				lightChanged = true;
			}
			if (keyboard.IsKeyDown(.K))
			{
				mSunPitch += lightRotateSpeed;
				mSunPitch = Math.Clamp(mSunPitch, -Math.PI_f * 0.49f, Math.PI_f * 0.49f);
				lightChanged = true;
			}
			if (keyboard.IsKeyDown(.J))
			{
				mSunYaw -= lightRotateSpeed;
				lightChanged = true;
			}
			if (keyboard.IsKeyDown(.L))
			{
				mSunYaw += lightRotateSpeed;
				lightChanged = true;
			}

			// Adjust intensity with Y/H
			float intensitySpeed = 1.0f * (float)info.Time.ElapsedTime.TotalSeconds;
			if (keyboard.IsKeyDown(.Y))
			{
				mSunLight.Intensity = Math.Min(mSunLight.Intensity + intensitySpeed, 3.0f);
				lightChanged = true;
			}
			if (keyboard.IsKeyDown(.H))
			{
				mSunLight.Intensity = Math.Max(mSunLight.Intensity - intensitySpeed, 0.0f);
				lightChanged = true;
			}

			// Adjust color temperature with T/G
			float colorSpeed = 1.0f * (float)info.Time.ElapsedTime.TotalSeconds;
			if (keyboard.IsKeyDown(.T))
			{
				// Make warmer (more orange)
				mSunLight.Color.X = Math.Min(mSunLight.Color.X + colorSpeed * 0.5f, 1.0f);
				mSunLight.Color.Y = Math.Max(mSunLight.Color.Y - colorSpeed * 0.2f, 0.7f);
				mSunLight.Color.Z = Math.Max(mSunLight.Color.Z - colorSpeed * 0.5f, 0.4f);
				lightChanged = true;
			}
			if (keyboard.IsKeyDown(.G))
			{
				// Make cooler (more blue)
				mSunLight.Color.X = Math.Max(mSunLight.Color.X - colorSpeed * 0.5f, 0.8f);
				mSunLight.Color.Y = Math.Min(mSunLight.Color.Y + colorSpeed * 0.2f, 1.0f);
				mSunLight.Color.Z = Math.Min(mSunLight.Color.Z + colorSpeed * 0.5f, 1.0f);
				lightChanged = true;
			}

			// Reset light with R
			if (keyboard.IsKeyDown(.R))
			{
				mSunYaw = 0.0f;
				mSunPitch = Math.DegreesToRadians(-45.0f);
				mSunLight.Color = Vector3(1.0f, 0.95f, 0.8f);
				mSunLight.Intensity = 0.8f;
				lightChanged = true;
			}

			// Apply rotation changes
			if (lightChanged)
			{
				mSunLightEntity.Transform.Rotation = Quaternion.CreateFromYawPitchRoll(mSunYaw, mSunPitch, 0);
			}

			// Display current values with F1
			if (keyboard.IsKeyPressed(.F1))
			{
				Console.WriteLine("=== Directional Light Settings ===");
				Console.WriteLine("Rotation: Yaw={0:F2}°, Pitch={1:F2}°", 
					Math.RadiansToDegrees(mSunYaw), 
					Math.RadiansToDegrees(mSunPitch));
				Console.WriteLine("Color: R={0:F2}, G={1:F2}, B={2:F2}", 
					mSunLight.Color.X, 
					mSunLight.Color.Y, 
					mSunLight.Color.Z);
				Console.WriteLine("Intensity: {0:F2}", mSunLight.Intensity);
				Console.WriteLine("Controls:");
				Console.WriteLine("  J/L - Rotate horizontally");
				Console.WriteLine("  I/K - Rotate vertically");
				Console.WriteLine("  Y/H - Increase/Decrease intensity");
				Console.WriteLine("  T/G - Warmer/Cooler color");
				Console.WriteLine("  R   - Reset to default");
				Console.WriteLine("  F1  - Show this help");
			}
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