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
using System.Diagnostics;
using Sedulous.Imaging;
using Sedulous.Engine.Renderer.RHI;
using Sedulous.RHI.Vulkan;
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
		for(var entity in mRotatingQuery.GetEntities(Scene, .. scope .()))
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
				renderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(mesh, true));
			}
		}

		// Create objects
		for (int i = 0; i < 5; i++)
		{
			var geometry = scene.CreateEntity(scope $"Geometry{i}");
			geometry.Transform.Position = Vector3(i * 2 - 4, 0, 0);
			geometry.Transform.Scale = Vector3(1, 1, 1);
			//geometry.AddComponent<RotateComponent>();
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
		{
			Console.WriteLine("=== Setting up Normal Mapping Test ===");

			// Create normal mapping test row - positioned behind the main objects
			for (int i = 0; i < 6; i++)
			{
				var normalTestEntity = scene.CreateEntity(scope $"NormalTest{i}");
				normalTestEntity.Transform.Position = Vector3(i * 2 - 10, 0, 4); // Behind main objects
				normalTestEntity.Transform.Scale = Vector3(4f, 4f, 4f); // Larger for better visibility

				var renderer = normalTestEntity.AddComponent<MeshRenderer>();
				renderer.Color = Color.White;

				// Create mesh - use different shapes for variety
				Mesh mesh = null;
				if (i % 3 == 0)
					mesh = Mesh.CreateCube();
				else if (i % 3 == 1)
					mesh = Mesh.CreateCube(); //Mesh.CreateSphere(0.5f, 64, 64); // Even higher resolution for better normal mapping
				else
					mesh = Mesh.CreateCube(); //Mesh.CreateCylinder(0.5f, 1.0f, 64); // Even higher resolution

				// Create materials with different normal maps
				PhongMaterial material = new PhongMaterial();
				material.DiffuseColor = Color(0.7f, 0.7f, 0.7f, 1.0f); // Slightly darker to show normal effects better
				material.SpecularColor = Color(0.8f, 0.8f, 0.8f, 1.0f); // Higher specular
				material.Shininess = 128.0f; // Very high shininess shows normal mapping better
				material.AmbientColor = Color(0.05f, 0.05f, 0.05f, 1.0f); // Lower ambient

				// Create diffuse texture
				material.DiffuseTexture = engine.ResourceSystem.AddResource(TextureResource.CreateWhite(64));

				// Create different normal maps for each object
				String normalMapType = "";
				switch (i)
				{
				case 0:
					// Flat normal map (baseline - should look like no normal mapping)
					material.NormalTexture = engine.ResourceSystem.AddResource(TextureResource.CreateFlatNormalMap(256));
					normalMapType = "Flat (Baseline)";

				case 1:
					// Wave pattern normal map - MUCH STRONGER for sphere
					material.NormalTexture = engine.ResourceSystem.AddResource(TextureResource.CreateWaveNormalMap(256, 3.0f, 3.0f, 1.5f));
					normalMapType = "Wave Pattern (STRONG)";

				case 2:
					// Circular bump normal map - good for cylinder
					material.NormalTexture = engine.ResourceSystem.AddResource(TextureResource.CreateCircularBumpNormalMap(256, 1.5f, 1.2f));
					normalMapType = "Circular Bump";

				case 3:
					// Brick pattern normal map - FEWER, LARGER BRICKS
					material.NormalTexture = engine.ResourceSystem.AddResource(TextureResource.CreateBrickNormalMap(256, 3, 2, 1.0f));
					normalMapType = "Brick Pattern (LARGE)";

				case 4:
					// Noise-based normal map - STRONGER NOISE
					material.NormalTexture = engine.ResourceSystem.AddResource(TextureResource.CreateNoiseNormalMap(256, 0.03f, 0.8f, 54321));
					normalMapType = "Noise Texture (STRONG)";

				case 5:
					// Test pattern normal map (shows multiple effects)
					material.NormalTexture = engine.ResourceSystem.AddResource(TextureResource.CreateTestPatternNormalMap(256));
					normalMapType = "Test Pattern";
				}

				Console.WriteLine($"Created normal mapping test {i}: {normalMapType}");

				renderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(mesh, true));
				renderer.Material = engine.ResourceSystem.AddResource(new MaterialResource(material, true));
			}

			// Create MULTIPLE dedicated lights for the normal mapping test area
			// Main light - strong white light from front-right
			var normalTestLightEntity = scene.CreateEntity("NormalTestLight");
			normalTestLightEntity.Transform.Position = Vector3(2, 4, 1); // Front-right of test objects
			var normalTestLight = normalTestLightEntity.AddComponent<PointLight>();
			normalTestLight.Color = Vector3(1.0f, 1.0f, 1.0f); // Pure white to show normal details clearly
			normalTestLight.Intensity = 6.0f; // Very bright to emphasize normal mapping
			normalTestLight.Range = 15.0f;

			// Secondary light - softer from the left
			var normalTestLight2Entity = scene.CreateEntity("NormalTestLight2");
			normalTestLight2Entity.Transform.Position = Vector3(-3, 3, 1); // Front-left of test objects
			var normalTestLight2 = normalTestLight2Entity.AddComponent<PointLight>();
			normalTestLight2.Color = Vector3(0.8f, 0.9f, 1.0f); // Slightly blue-tinted
			normalTestLight2.Intensity = 4.0f;
			normalTestLight2.Range = 12.0f;

			// Add visual representations for the normal test lights
			for (int lightIdx = 1; lightIdx <= 2; lightIdx++)
			{
				var normalTestLightVisual = scene.CreateEntity(scope $"NormalTestLightVisual{lightIdx}");
				var lightEntity = scene.FindEntity(scope $"NormalTestLight{lightIdx == 1 ? "" : "2"}");
				if (lightEntity != null)
				{
					normalTestLightVisual.Transform.Position = lightEntity.Transform.Position;
					normalTestLightVisual.Transform.Scale = Vector3(0.15f, 0.15f, 0.15f);
					var normalTestLightRenderer = normalTestLightVisual.AddComponent<MeshRenderer>();
					normalTestLightRenderer.Color = Color.White;
					var normalTestLightMat = new UnlitMaterial();
					normalTestLightMat.Color = Color.White;
					normalTestLightRenderer.Material = engine.ResourceSystem.AddResource(new MaterialResource(normalTestLightMat, true));
					var normalTestLightMesh = Mesh.CreateSphere(0.5f, 16, 16);
					normalTestLightRenderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(normalTestLightMesh, true));
				}
			}

			// Create information labels (as sprites) above each normal test object
			for (int i = 0; i < 6; i++)
			{
				String labelText = "";
				switch (i)
				{
				case 0: labelText = "Flat";
				case 1: labelText = "WAVE";
				case 2: labelText = "Bump";
				case 3: labelText = "Brick";
				case 4: labelText = "Noise";
				case 5: labelText = "Test";
				}

				var labelEntity = scene.CreateEntity(scope $"NormalLabel{i}");
				labelEntity.Transform.Position = Vector3(i * 2 - 5, 3.0f, 3); // Above each test object

				var labelRenderer = labelEntity.AddComponent<SpriteRenderer>();
				labelRenderer.Texture = engine.ResourceSystem.AddResource(TextureResource.CreateSolidColor(128, 32, Color.White));
				labelRenderer.Color = Color(0.2f, 0.8f, 0.2f, 0.9f); // Semi-transparent green
				labelRenderer.Size = Vector2(1.8f, 0.6f); // Larger labels
				labelRenderer.Billboard = .Full; // Always face camera
			}

			// Add some explanatory text as console output
			Console.WriteLine("=== Normal Mapping Test Setup Complete ===");
			Console.WriteLine("Look at the back row of objects (behind the main demo objects):");
			Console.WriteLine("- Object 0 (Flat): Baseline - should look like regular lighting");
			Console.WriteLine("- Object 1 (WAVE): Should show VERY STRONG wavy bumps on SPHERE");
			Console.WriteLine("- Object 2 (Bump): Should show a PROMINENT circular bump on CYLINDER");
			Console.WriteLine("- Object 3 (Brick): Should show LARGE brick pattern with deep mortar on CUBE");
			Console.WriteLine("- Object 4 (Noise): Should show STRONG organic rough surface texture");
			Console.WriteLine("- Object 5 (Test): Shows multiple patterns in quadrants");
			Console.WriteLine("");
			Console.WriteLine("The effects should be MUCH more visible now from a distance!");
			Console.WriteLine("Move the camera around to see how the lighting changes with normal mapping!");
			Console.WriteLine("Use right-click + mouse drag to look around.");
			Console.WriteLine("Use WASD to move, Q/E for up/down.");
			Console.WriteLine("");

			// Add a test to verify tangent generation
			Console.WriteLine("=== Verifying Tangent Generation ===");
			var testMesh = Mesh.CreateCube();
			bool tangentsValid = true;
			for (int32 v = 0; v < Math.Min(testMesh.Vertices.VertexCount, 8); v++)
			{
				var normal = testMesh.GetNormal(v);
				var tangent = testMesh.GetTangent(v);
				float dot = Math.Abs(Vector3.Dot(normal, tangent));

				if (dot > 0.1f)
				{
					Console.WriteLine($"️  Vertex {v}: Tangent not perpendicular to normal (dot = {dot})");
					tangentsValid = false;
				}
			}

			if (tangentsValid)
			{
				Console.WriteLine("Tangent generation verified - all tangents are properly perpendicular to normals");
			}
			else
			{
				Console.WriteLine("Tangent generation has issues - normal mapping may not work correctly");
			}

			delete testMesh;
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

		planeRenderer.Mesh = engine.ResourceSystem.AddResource(new MeshResource(planeMesh, true));

		// Create a sprite entity
		var spriteEntity = scene.CreateEntity("TestSprite");
		spriteEntity.Transform.Position = Vector3(-6, 6, 0);

		spriteEntity.AddComponent<ControllerComponent>();

		var spriteRenderer = spriteEntity.AddComponent<SpriteRenderer>();
		spriteRenderer.Texture = engine.ResourceSystem.AddResource(/*new TextureResource(ImageLoaderFactory.LoadImage("images/ball.png"), true)*/TextureResource.CreateCheckerboard(256, 32));
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
}

class Program
{
	public static void Main(params String[] args)
	{
		ILogger logger = scope DebugLogger(.Trace);

		var windowSystem = scope SDL3WindowSystem("Sandbox", 1366, 768);
		var app = scope SandboxApplication(logger, windowSystem);

		//var renderer = scope SDLRendererSubsystem((SDL3Window)windowSystem.PrimaryWindow);
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