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

	// Animation control
	private int32 mCurrentAnimationIndex = 0;
	private String[] mAnimationNames = new .("Survey", "Walk", "Run") ~ delete _;

	// Debug visualization
	private bool mShowLightDebug = true;
	private RHIRendererSubsystem mRHIRenderer;

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

		// Create sun light
		mSunLightEntity = scene.CreateEntity("Sun");
		mSunLightEntity.Transform.Rotation = Quaternion.CreateFromYawPitchRoll(mSunYaw, mSunPitch, 0);
		mSunLight = mSunLightEntity.AddComponent<DirectionalLight>();
		mSunLight.Color = Vector3(1.0f, 0.95f, 0.8f); // Warm white sunlight
		mSunLight.Intensity = 0.8f;

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

		// Create sprites demonstrating different billboard modes
		CreateSpriteDemo(engine, scene);

		// Load GLTF model
		LoadGLTFModel(engine, scene);

		// Load Duck model with PBR material
		LoadDuckModel(engine, scene);

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

			// Toggle debug visualization with F2
			if (keyboard.IsKeyPressed(.F2))
			{
				mShowLightDebug = !mShowLightDebug;
				Debug.WriteLine("Light debug visualization: {0}", mShowLightDebug ? "ON" : "OFF");
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
				Debug.WriteLine("  F2  - Toggle light debug visualization");
			}

			// Draw debug visualization for directional light
			if (mShowLightDebug)
			{
				if (mRHIRenderer == null)
					mRHIRenderer = ((Engine)info.Engine).GetSubsystem<RHIRendererSubsystem>().Value;

				var debugRenderer = mRHIRenderer?.GetDebugRenderer();
				if (debugRenderer != null)
				{
					var lightDir = mSunLightEntity.Transform.Forward;
					var lightColor = Color(
						(uint8)(mSunLight.Color.X * 255),
						(uint8)(mSunLight.Color.Y * 255),
						(uint8)(mSunLight.Color.Z * 255),
						255);

					// Draw light rays from "sun position" toward scene center
					debugRenderer.DrawDirectionalLight(lightDir, Vector3.Zero, 5.0f, lightColor);
				}
			}
		}

		// Object picking with left click (without Alt modifier)
		{
			var mouse = inputSubsystem.GetMouse();
			var keyboard = inputSubsystem.GetKeyboard();

			// Check for pick result from previous frame
			if (mRHIRenderer == null)
				mRHIRenderer = ((Engine)info.Engine).GetSubsystem<RHIRendererSubsystem>().Value;

			if (mRHIRenderer.PickResultReady)
			{
				var pickedEntity = mRHIRenderer.GetPickedEntity();
				if (pickedEntity != null)
				{
					Debug.WriteLine(scope $"Picked entity: {pickedEntity.Name} (ID: {pickedEntity.Id})");
				}
				else
				{
					Debug.WriteLine("Picked: Nothing (empty space)");
				}
				mRHIRenderer.ClearPickResult();
			}

			// Request pick on left click (without Alt - Alt is used for orbit)
			if (mouse.IsButtonPressed(.Left) && !keyboard.IsKeyDown(.LeftAlt))
			{
				var mousePos = mouse.Position;
				mRHIRenderer.RequestPick((int32)mousePos.X, (int32)mousePos.Y);
				Debug.WriteLine(scope $"Requesting pick at ({mousePos.X}, {mousePos.Y})");
			}
		}

		// Animation toggle with N key
		var keyboard = inputSubsystem.GetKeyboard();
		if (keyboard.IsKeyPressed(.N))
		{
			// Find animated fox entity and toggle animation
			var foxEntity = scene.FindEntity("AnimatedFox_0_0");
			if (foxEntity != null && foxEntity.HasComponent<Animator>())
			{
				var animator = foxEntity.GetComponent<Animator>();
				mCurrentAnimationIndex = (mCurrentAnimationIndex + 1) % (int32)animator.AnimationCount;
				animator.Play(mCurrentAnimationIndex);
				Debug.WriteLine(scope $"Playing animation {mCurrentAnimationIndex}: {mAnimationNames[mCurrentAnimationIndex]}");
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

	// Convert Model.MeshPrimitive to SkinnedMesh (with bone data)
	private SkinnedMesh ConvertToSkinnedMesh(MeshPrimitive primitive)
	{
		let mesh = new SkinnedMesh();

		// Copy vertices
		for (int32 i = 0; i < primitive.Vertices.Count; i++)
		{
			let v = primitive.Vertices[i];
			var vertex = SkinnedVertex();
			vertex.Position = v.Position;
			vertex.Normal = v.Normal;
			vertex.TexCoord = v.TexCoord0;
			vertex.Tangent = Vector3(v.Tangent.X, v.Tangent.Y, v.Tangent.Z);
			vertex.Color = PackColor(v.Color);
			vertex.Joints = v.Joints;
			vertex.Weights = v.Weights;
			mesh.AddVertex(vertex);
		}

		// Copy indices
		mesh.ReserveIndices((int32)primitive.Indices.Count);
		for (int32 i = 0; i < primitive.Indices.Count; i++)
			mesh.AddIndex(primitive.Indices[i]);

		mesh.AddSubMesh(SubMesh(0, (int32)primitive.Indices.Count));
		mesh.CalculateBounds();
		return mesh;
	}

	// Convert Model.Skin to SkinData
	private SkinData ConvertToSkinData(Sedulous.Model.Skin modelSkin)
	{
		let skin = new SkinData();
		if (modelSkin.Name != null)
			skin.Name = new String(modelSkin.Name);
		skin.SkeletonRootIndex = modelSkin.SkeletonRootIndex;

		for (var jointIndex in modelSkin.JointIndices)
			skin.JointIndices.Add(jointIndex);

		for (var ibm in modelSkin.InverseBindMatrices)
			skin.InverseBindMatrices.Add(ibm);

		return skin;
	}

	// Convert Model node list to SkeletonData
	private SkeletonData ConvertToSkeletonData(List<Node> nodes, List<int32> rootNodeIndices)
	{
		let skeleton = new SkeletonData();

		// Create a map from Node pointer to index
		var nodeToIndex = scope Dictionary<Node, int32>();
		for (int32 i = 0; i < nodes.Count; i++)
			nodeToIndex[nodes[i]] = i;

		// Copy nodes
		for (int32 i = 0; i < nodes.Count; i++)
		{
			var srcNode = nodes[i];
			var dstNode = new SkeletonNode();

			if (srcNode.Name != null)
				dstNode.Name = new String(srcNode.Name);

			dstNode.Translation = srcNode.Translation;
			dstNode.Rotation = srcNode.Rotation;
			dstNode.Scale = srcNode.Scale;

			// Find parent index
			if (srcNode.Parent != null && nodeToIndex.TryGetValue(srcNode.Parent, var parentIdx))
				dstNode.ParentIndex = parentIdx;
			else
				dstNode.ParentIndex = -1;

			// Copy child indices
			for (var child in srcNode.Children)
			{
				if (nodeToIndex.TryGetValue(child, var childIdx))
					dstNode.ChildIndices.Add(childIdx);
			}

			skeleton.Nodes.Add(dstNode);
		}

		// Copy root node indices
		for (var idx in rootNodeIndices)
			skeleton.RootNodeIndices.Add(idx);

		return skeleton;
	}

	// Convert Model.Animation to AnimationClipData
	private AnimationClipData ConvertToAnimationClipData(Sedulous.Model.Animation modelAnim)
	{
		let clip = new AnimationClipData();
		if (modelAnim.Name != null)
			clip.Name = new String(modelAnim.Name);

		for (var srcChannel in modelAnim.Channels)
		{
			var dstChannel = new AnimationChannelData();
			dstChannel.TargetNodeIndex = srcChannel.TargetNodeIndex;

			switch (srcChannel.TargetPath)
			{
			case .Translation: dstChannel.TargetPath = .Translation;
			case .Rotation: dstChannel.TargetPath = .Rotation;
			case .Scale: dstChannel.TargetPath = .Scale;
			case .Weights: dstChannel.TargetPath = .Weights;
			}

			// Copy sampler data
			var srcSampler = srcChannel.Sampler;
			switch (srcSampler.Interpolation)
			{
			case .Linear: dstChannel.Sampler.Interpolation = .Linear;
			case .Step: dstChannel.Sampler.Interpolation = .Step;
			case .CubicSpline: dstChannel.Sampler.Interpolation = .CubicSpline;
			}

			for (var time in srcSampler.KeyframeTimes)
				dstChannel.Sampler.KeyframeTimes.Add(time);

			for (var value in srcSampler.KeyframeValues)
				dstChannel.Sampler.KeyframeValues.Add(value);

			clip.Channels.Add(dstChannel);
		}

		return clip;
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
		TextureResource modelTexture = null;
		if (model.TextureCount > 0 && model.Textures[0].ImageData != null)
		{
			let image = model.Textures[0].ImageData;
			model.Textures[0].ImageData = null;  // Transfer ownership
			modelTexture = new TextureResource(image, true);
			modelTexture.SetupFor3D();
		}

		// Create Phong material for lighting support
		// Lighting comes from the scene's DirectionalLight entity
		let material = new PhongMaterial();
		material.DiffuseColor = .White;
		material.SpecularColor = Color(0.3f, 0.3f, 0.3f, 1.0f);
		material.Shininess = 16.0f;
		material.AmbientColor = .White; // Full ambient tint (scene ambient will provide the color)
		if (modelTexture != null)
			material.DiffuseTexture = engine.ResourceSystem.AddResource(modelTexture);

		// Check if model has skin (for animated mesh)
		bool hasSkin = model.SkinCount > 0 && model.AnimationCount > 0;

		if (hasSkin)
		{
			// Load as animated skinned mesh
			Debug.WriteLine(scope $"Loading animated Fox with {model.SkinCount} skins, {model.AnimationCount} animations");

			// Convert skeleton from model nodes
			let skeletonData = ConvertToSkeletonData(model.Nodes, model.RootNodeIndices);
			let skeletonRes = new SkeletonResource(skeletonData, true);

			// Convert skin
			let skinData = ConvertToSkinData(model.Skins[0]);
			let skinRes = new SkinResource(skinData, true);

			// Convert animations
			var animationResources = new List<ResourceHandle<AnimationResource>>();
			for (var anim in model.Animations)
			{
				let clipData = ConvertToAnimationClipData(anim);
				let animRes = new AnimationResource(clipData, true);
				animationResources.Add(engine.ResourceSystem.AddResource(animRes));
				var animName = anim.Name ?? "unnamed";
				Debug.WriteLine(scope $"  Animation: {animName}, Duration: {anim.Duration}s");
			}

			// Find mesh with skin and create skinned mesh
			for (int m = 0; m < model.MeshCount; m++)
			{
				let modelMesh = model.Meshes[m];
				for (int p = 0; p < modelMesh.Primitives.Count; p++)
				{
					let primitive = modelMesh.Primitives[p];
					let skinnedMesh = ConvertToSkinnedMesh(primitive);

					var entity = scene.CreateEntity(scope $"AnimatedFox_{m}_{p}");
					entity.Transform.Position = Vector3(0, -1.5f, -3);
					entity.Transform.Scale = Vector3(0.02f, 0.02f, 0.02f);

					// Add SkinnedMeshRenderer
					var skinnedRenderer = entity.AddComponent<SkinnedMeshRenderer>();
					skinnedRenderer.Mesh = engine.ResourceSystem.AddResource(new SkinnedMeshResource(skinnedMesh, true));
					skinnedRenderer.Material = engine.ResourceSystem.AddResource(new MaterialResource(material, true));
					skinnedRenderer.Skin = engine.ResourceSystem.AddResource(skinRes);

					// Add Animator
					var animator = entity.AddComponent<Animator>();
					animator.Skeleton = engine.ResourceSystem.AddResource(skeletonRes);

					// Add all animations
					for (var animHandle in animationResources)
						animator.AddAnimation(animHandle);

					// Start playing first animation (Survey)
					if (animator.AnimationCount > 0)
					{
						animator.Play(0);
						Debug.WriteLine(scope $"Playing animation 0");
					}
				}
			}

			// Clean up animation handles list (resources are now owned by animator)
			delete animationResources;

			Debug.WriteLine(scope $"Loaded animated Fox: {model.MeshCount} meshes, {model.NodeCount} nodes, {model.AnimationCount} animations");
		}
		else
		{
			// Load as static mesh (fallback)
			for (int m = 0; m < model.MeshCount; m++)
			{
				let modelMesh = model.Meshes[m];
				for (int p = 0; p < modelMesh.Primitives.Count; p++)
				{
					let primitive = modelMesh.Primitives[p];
					let geometryMesh = ConvertToGeometryMesh(primitive);

					var entity = scene.CreateEntity(scope $"Fox_{m}_{p}");
					entity.Transform.Position = Vector3(0, -1.5f, -3);
					entity.Transform.Scale = Vector3(0.02f, 0.02f, 0.02f);

					var renderer = entity.AddComponent<MeshRenderer>();
					renderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(geometryMesh, true));
					renderer.Material = engine.ResourceSystem.AddResource(new MaterialResource(material, true));
				}
			}

			Debug.WriteLine(scope $"Loaded static Fox model: {model.MeshCount} meshes, {model.TextureCount} textures");
		}
	}

	private void LoadDuckModel(Engine engine, Scene scene)
	{
		let processor = scope GLTFModelProcessor();

		let modelPath = scope String();
		Directory.GetCurrentDirectory(modelPath);
		modelPath.Append("\\Assets\\Duck\\glTF-Binary\\Duck.glb");

		let model = processor.Read(modelPath);
		if (model == null)
		{
			Debug.WriteLine("Failed to load Duck model");
			return;
		}
		defer delete model;

		// Create texture from model (first texture if available - the Duck has a color map)
		TextureResource albedoTexture = null;
		if (model.TextureCount > 0 && model.Textures[0].ImageData != null)
		{
			let image = model.Textures[0].ImageData;
			model.Textures[0].ImageData = null;  // Transfer ownership
			albedoTexture = new TextureResource(image, true);
			albedoTexture.SetupFor3D();
		}

		// Create PBR material
		let material = new PBRMaterial();
		material.AlbedoColor = .White;
		material.Metallic = 0.0f;      // Duck is not metallic
		material.Roughness = 0.6f;     // Slightly rough surface
		material.AmbientOcclusion = 1.0f;
		material.EmissiveColor = .Black;
		material.EmissiveIntensity = 0.0f;

		if (albedoTexture != null)
			material.AlbedoTexture = engine.ResourceSystem.AddResource(albedoTexture);

		// Load as static mesh (Duck model doesn't have animations)
		for (int m = 0; m < model.MeshCount; m++)
		{
			let modelMesh = model.Meshes[m];
			for (int p = 0; p < modelMesh.Primitives.Count; p++)
			{
				let primitive = modelMesh.Primitives[p];
				let geometryMesh = ConvertToGeometryMesh(primitive);

				var entity = scene.CreateEntity(scope $"Duck_{m}_{p}");
				entity.Transform.Position = Vector3(4, -1.5f, -2);  // Position to the right of the fox
				entity.Transform.Scale = Vector3(0.01f, 0.01f, 0.01f);  // Duck is fairly large, scale down
				//entity.AddComponent<RotateComponent>();  // Make it rotate like the other objects

				var renderer = entity.AddComponent<MeshRenderer>();
				renderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(geometryMesh, true));
				renderer.Material = engine.ResourceSystem.AddResource(new MaterialResource(material, true));
			}
		}

		Debug.WriteLine(scope $"Loaded Duck model with PBR material: {model.MeshCount} meshes, {model.TextureCount} textures");
	}

	private void CreateSpriteDemo(Engine engine, Scene scene)
	{
		// Row 1: Billboard mode comparison (Y = 1)

		// Sprite 1: No billboard (static orientation)
		{
			var texture = TextureResource.CreateCheckerboard(128, 16);
			texture.SetupForSprite();
			var texHandle = engine.ResourceSystem.AddResource(texture).Value;

			var sprite = scene.CreateEntity("Sprite_None");
			sprite.Transform.Position = Vector3(-4, 1, 2);
			sprite.Transform.Rotation = Quaternion.CreateFromYawPitchRoll(Math.PI_f * 0.25f, 0, 0);

			var renderer = sprite.AddComponent<SpriteRenderer>();
			renderer.Texture = texHandle;
			renderer.Color = .White;
			renderer.Size = Vector2(1.5f, 1.5f);
			renderer.Billboard = .None;
		}

		// Sprite 2: FacePosition (faces camera position, rotates when camera moves)
		{
			var texture = TextureResource.CreateSolidColor(64, 64, .Red);
			texture.SetupForSprite();
			var texHandle = engine.ResourceSystem.AddResource(texture).Value;

			var sprite = scene.CreateEntity("Sprite_FacePosition");
			sprite.Transform.Position = Vector3(-2, 1, 2);

			var renderer = sprite.AddComponent<SpriteRenderer>();
			renderer.Texture = texHandle;
			renderer.Color = .White;
			renderer.Size = Vector2(1.5f, 1.5f);
			renderer.Billboard = .FacePosition;
		}

		// Sprite 3: FacePositionY (faces camera position, Y-axis only)
		{
			var texture = TextureResource.CreateSolidColor(64, 64, .Green);
			texture.SetupForSprite();
			var texHandle = engine.ResourceSystem.AddResource(texture).Value;

			var sprite = scene.CreateEntity("Sprite_FacePositionY");
			sprite.Transform.Position = Vector3(0, 1, 2);

			var renderer = sprite.AddComponent<SpriteRenderer>();
			renderer.Texture = texHandle;
			renderer.Color = .White;
			renderer.Size = Vector2(1.5f, 1.5f);
			renderer.Billboard = .FacePositionY;
		}

		// Sprite 4: ViewAligned (always flat on screen, rotates with camera view)
		{
			var texture = TextureResource.CreateSolidColor(64, 64, .Blue);
			texture.SetupForSprite();
			var texHandle = engine.ResourceSystem.AddResource(texture).Value;

			var sprite = scene.CreateEntity("Sprite_ViewAligned");
			sprite.Transform.Position = Vector3(2, 1, 2);

			var renderer = sprite.AddComponent<SpriteRenderer>();
			renderer.Texture = texHandle;
			renderer.Color = .White;
			renderer.Size = Vector2(1.5f, 1.5f);
			renderer.Billboard = .ViewAligned;
		}

		// Sprite 5: ViewAlignedY (screen-aligned horizontally, Y-axis constrained)
		{
			var texture = TextureResource.CreateGradient(128, 128, .Yellow, .Orange);
			texture.SetupForSprite();
			var texHandle = engine.ResourceSystem.AddResource(texture).Value;

			var sprite = scene.CreateEntity("Sprite_ViewAlignedY");
			sprite.Transform.Position = Vector3(4, 1, 2);

			var renderer = sprite.AddComponent<SpriteRenderer>();
			renderer.Texture = texHandle;
			renderer.Color = .White;
			renderer.Size = Vector2(1.5f, 1.5f);
			renderer.Billboard = .ViewAlignedY;
		}

		// Row 2: Features demo (Y = 2.5)

		// Sprite with tint and flip
		{
			var texture = TextureResource.CreateCheckerboard(128, 16);
			texture.SetupForSprite();
			var texHandle = engine.ResourceSystem.AddResource(texture).Value;

			var sprite = scene.CreateEntity("Sprite_Tinted");
			sprite.Transform.Position = Vector3(-1, 2.5f, 2);

			var renderer = sprite.AddComponent<SpriteRenderer>();
			renderer.Texture = texHandle;
			renderer.Color = Color(255, 200, 100, 200);
			renderer.Size = Vector2(1.0f, 1.0f);
			renderer.Billboard = .ViewAligned;
			renderer.FlipX = true;
			renderer.SortingLayer = 1;
		}

		// Sprite with bottom pivot
		{
			var texture = TextureResource.CreateGradient(128, 128, .Cyan, .Magenta);
			texture.SetupForSprite();
			var texHandle = engine.ResourceSystem.AddResource(texture).Value;

			var sprite = scene.CreateEntity("Sprite_BottomPivot");
			sprite.Transform.Position = Vector3(1, 2.5f, 2);

			var renderer = sprite.AddComponent<SpriteRenderer>();
			renderer.Texture = texHandle;
			renderer.Color = .White;
			renderer.Size = Vector2(1.0f, 1.0f);
			renderer.Pivot = Vector2(0.5f, 0.0f);
			renderer.Billboard = .ViewAligned;
			renderer.SortingLayer = 1;
		}

		Debug.WriteLine("Created sprite demo:");
		Debug.WriteLine("  Bottom row (billboard modes):");
		Debug.WriteLine("    - None: Static 45-degree rotation (checkerboard)");
		Debug.WriteLine("    - FacePosition: Faces camera position (red) - rotates when camera MOVES");
		Debug.WriteLine("    - FacePositionY: Faces camera, Y-axis only (green)");
		Debug.WriteLine("    - ViewAligned: Screen-aligned (blue) - rotates when camera ROTATES");
		Debug.WriteLine("    - ViewAlignedY: Screen-aligned, Y-axis only (yellow/orange)");
		Debug.WriteLine("  Top row (features):");
		Debug.WriteLine("    - Tinted + FlipX (orange checkerboard)");
		Debug.WriteLine("    - Bottom pivot (gradient)");
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