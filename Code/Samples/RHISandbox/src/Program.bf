using System;
using Sedulous.Platform.Core;
using Sedulous.Mathematics;
using Sedulous.Logging.Debug;
using Sedulous.Logging.Abstractions;
using Sedulous.Engine.Core;
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
using System.Diagnostics;
using Sedulous.Imaging;
using Sedulous.Engine.Renderer.RHI;
using Sedulous.RHI.Vulkan;
using Sedulous.Model;
using Sedulous.Model.Formats.GLTF;
using System.IO;

namespace RHISandbox;

typealias GeometryMesh = Sedulous.Geometry.Mesh;

public class RotateComponent : Component
{
	//private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<Self>();
	//public override ComponentTypeId TypeId => sTypeId;
}

public class ControllerComponent : Component
{
	//private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<Self>();
	//public override ComponentTypeId TypeId => sTypeId;

	public float MoveSpeed { get; set; } = 5.0f; // Units per second
}

public class AppSceneModule : SceneModule
{
	public override StringView Name => nameof(AppSceneModule);
	private readonly AppSubsystem mSubsystem;

	private EntityQuery mRotatingQuery;
	private EntityQuery mControllerQuery;

	public this(AppSubsystem subsystem)
	{
		mSubsystem = subsystem;

		mRotatingQuery = CreateQuery().With<RotateComponent>();
		mControllerQuery = CreateQuery().With<ControllerComponent>();
	}

	public ~this()
	{
		DestroyQuery(mRotatingQuery);
		DestroyQuery(mControllerQuery);
	}

	protected override void OnUpdate(Time time)
	{
		for (var entity in mRotatingQuery.GetEntities(Scene, .. scope .()))
		{
			if (entity.HasComponent<RotateComponent>() && entity.HasComponent<MeshRenderer>())
			{
				entity.Transform.Rotation = Quaternion.CreateFromRotationMatrix(Matrix.CreateRotationY((float)time.TotalTime.TotalMilliseconds * 0.001f));
			}
		}

		for (var entity in mControllerQuery.GetEntities(Scene, .. scope .()))
		{
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

		// Create objects
		for (int i = 0; i < 5; i++)
		{
			var geometry = scene.CreateEntity(scope $"Geometry{i}");
			geometry.Transform.Position = Vector3(i * 2 - 4, 0, 0);
			geometry.Transform.Scale = Vector3(1, 1, 1);
			geometry.AddComponent<RotateComponent>();
			var renderer = geometry.AddComponent<MeshRenderer>();
			renderer.Color = Color.White;

			GeometryMesh mesh = null;
			TextureResource texture = null;
			switch (i)
			{
			case 0:
				mesh = GeometryMesh.CreateCube();
				texture = TextureResource.CreateCheckerboard();
				break;
			case 1:
				mesh = GeometryMesh.CreateSphere();
				texture = TextureResource.CreateGradient(256, 256, .Red, .Green);
				break;
			case 2:
				mesh = GeometryMesh.CreateCylinder();
				texture = TextureResource.CreateGradient(256, 256, .Red, .Yellow);
				break;
			case 3:
				mesh = GeometryMesh.CreateCone();
				texture = TextureResource.CreateGradient(256, 256, .Green, .Blue);
				break;
			case 4:
				mesh = GeometryMesh.CreateTorus();
				texture = TextureResource.CreateGradient(256, 256, .Blue, .Coral);
				break;
			}

			renderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(mesh ?? GeometryMesh.CreateCube(), true));
			UnlitMaterial unlit = new UnlitMaterial();
			unlit.Color = .White;
			unlit.MainTexture = engine.ResourceSystem.AddResource(texture ?? TextureResource.CreateSolidColor(256, 256, .Turquoise));

			var material = new MaterialResource(unlit, true);
			renderer.Material = engine.ResourceSystem.AddResource(material);
		}

		// Create floor plane
		var plane = scene.CreateEntity("Floor");
		plane.Transform.Position = Vector3(0, -1.5f, 0);
		plane.Transform.Scale = Vector3(10, 1, 10);
		var planeRenderer = plane.AddComponent<MeshRenderer>();
		planeRenderer.Color = Color.White;

		// Use a neutral gray material for the floor to show light colors
		var floorMat = new UnlitMaterial();
		floorMat.Color = .Green;
		/*floorMat.DiffuseColor = Color(0.7f, 0.7f, 0.7f, 1.0f);
		floorMat.SpecularColor = Color(0.3f, 0.3f, 0.3f, 1.0f);
		floorMat.Shininess = 32.0f;
		floorMat.AmbientColor = Color(0.05f, 0.05f, 0.05f, 1.0f);*/

		planeRenderer.Material = engine.ResourceSystem.AddResource(new MaterialResource(floorMat, true));
		var planeMesh = GeometryMesh.CreatePlane();

		planeRenderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(planeMesh, true));

		// Load GLTF model
		LoadGLTFModel(engine, scene);

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
				position += right * moveSpeed;
			}
			if (keyboard.IsKeyDown(.D))
			{
				position -= right * moveSpeed;
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
				mCameraYaw -= mouseDelta.X * mouseSensitivity;
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
				position += right * mouseDelta.X * panSpeed * 0.01f;
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
				Debug.WriteLine("=== Directional Light Settings ===");
				Debug.WriteLine("Rotation: Yaw={0:F2}°, Pitch={1:F2}°",
					Math.RadiansToDegrees(mSunYaw),
					Math.RadiansToDegrees(mSunPitch));
				Debug.WriteLine("Color: R={0:F2}, G={1:F2}, B={2:F2}",
					mSunLight.Color.X,
					mSunLight.Color.Y,
					mSunLight.Color.Z);
				Debug.WriteLine("Intensity: {0:F2}", mSunLight.Intensity);
				Debug.WriteLine("Controls:");
				Debug.WriteLine("  J/L - Rotate horizontally");
				Debug.WriteLine("  I/K - Rotate vertically");
				Debug.WriteLine("  Y/H - Increase/Decrease intensity");
				Debug.WriteLine("  T/G - Warmer/Cooler color");
				Debug.WriteLine("  R   - Reset to default");
				Debug.WriteLine("  F1  - Show this help");
			}
		}
	}

	// Convert Model.MeshPrimitive to Geometry.Mesh
	private GeometryMesh ConvertToGeometryMesh(MeshPrimitive primitive)
	{
		let mesh = new GeometryMesh();
		mesh.SetupCommonVertexFormat();

		// Copy vertices
		mesh.Vertices.Resize((int32)primitive.Vertices.Count);
		for (int32 i = 0; i < primitive.Vertices.Count; i++)
		{
			let v = primitive.Vertices[i];
			mesh.SetPosition(i, v.Position);
			mesh.SetNormal(i, v.Normal);
			mesh.SetUV(i, v.TexCoord0);
			mesh.SetTangent(i, Vector3(v.Tangent.X, v.Tangent.Y, v.Tangent.Z));
			mesh.SetColor(i, PackColor(v.Color));
		}

		// Copy indices
		mesh.Indices.Resize((int32)primitive.Indices.Count);
		for (int32 i = 0; i < primitive.Indices.Count; i++)
			mesh.Indices.SetIndex(i, primitive.Indices[i]);

		mesh.AddSubMesh(SubMesh(0, (int32)primitive.Indices.Count));
		return mesh;
	}

	private uint32 PackColor(Vector4 color)
	{
		uint8 r = (uint8)(Math.Clamp(color.X, 0, 1) * 255);
		uint8 g = (uint8)(Math.Clamp(color.Y, 0, 1) * 255);
		uint8 b = (uint8)(Math.Clamp(color.Z, 0, 1) * 255);
		uint8 a = (uint8)(Math.Clamp(color.W, 0, 1) * 255);
		return (uint32)r | ((uint32)g << 8) | ((uint32)b << 16) | ((uint32)a << 24);
	}

	private void LoadGLTFModel(Engine engine, Scene scene)
	{
		let processor = scope GLTFModelProcessor();

		let modelPath = scope String();
		Directory.GetCurrentDirectory(modelPath);
		modelPath.Append("\\Assets\\Fox\\glTF-Binary\\Fox.glb");

		let model = processor.Read(modelPath);
		if (model == null)
		{
			Debug.WriteLine("Failed to load GLTF model");
			return;
		}
		defer delete model;

		// Create texture from model (first texture if available)
		// Transfer ownership of image from model to texture resource
		TextureResource modelTexture = null;
		if (model.TextureCount > 0 && model.Textures[0].ImageData != null)
		{
			let image = model.Textures[0].ImageData;
			model.Textures[0].ImageData = null;  // Transfer ownership
			modelTexture = new TextureResource(image, true);
			modelTexture.SetupFor3D();
		}

		// Create material
		let material = new UnlitMaterial();
		material.Color = .White;
		if (modelTexture != null)
			material.MainTexture = engine.ResourceSystem.AddResource(modelTexture);

		// Convert each mesh primitive and create entities
		for (int m = 0; m < model.MeshCount; m++)
		{
			let modelMesh = model.Meshes[m];
			for (int p = 0; p < modelMesh.Primitives.Count; p++)
			{
				let primitive = modelMesh.Primitives[p];
				let geometryMesh = ConvertToGeometryMesh(primitive);

				var entity = scene.CreateEntity(scope $"Fox_{m}_{p}");
				entity.Transform.Position = Vector3(0, -1.5f, -3);  // Center, in front of other meshes
				entity.Transform.Scale = Vector3(0.02f, 0.02f, 0.02f);  // Fox is large, scale down

				var renderer = entity.AddComponent<MeshRenderer>();
				renderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(geometryMesh, true));
				renderer.Material = engine.ResourceSystem.AddResource(new MaterialResource(material, true));
			}
		}

		Debug.WriteLine(scope $"Loaded Fox model: {model.MeshCount} meshes, {model.TextureCount} textures");
	}
}

class Program
{
	public static void Main(params String[] args)
	{
		ILogger logger = scope DebugLogger(.Trace);

		var windowSystem = scope SDL3WindowSystem("Sandbox", 1366, 768);
		var app = scope SandboxApplication(logger, windowSystem);

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