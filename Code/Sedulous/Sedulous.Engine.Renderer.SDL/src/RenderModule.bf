using Sedulous.SceneGraph;
using System;
using SDL3Native;
using System.Collections;
using Sedulous.Mathematics;
using Sedulous.Resources;
using Sedulous.SceneGraph;
using Sedulous.Utilities;
using Sedulous.Geometry;

namespace Sedulous.Engine.Renderer.SDL;

using internal Sedulous.Engine.Renderer.SDL;

struct MeshRenderCommand
{
	public Entity Entity;
	public Matrix WorldMatrix;
	public MeshRenderer Renderer;
	public float DistanceToCamera;
}

struct SpriteRenderCommand
{
	public Entity Entity;
	public SpriteRenderer Renderer;
	public Transform Transform;
	public float DistanceToCamera;
	public int32 SortKey; // Combines layer and order
}

class RenderModule : SceneModule
{
	public override StringView Name => "Render";

	private SDLRendererSubsystem mRenderer;

	// 3D rendering
	private List<MeshRenderCommand> mMeshCommands = new .() ~ delete _;
	private Dictionary<MeshRenderer, GPUResourceHandle<GPUMesh>> mRendererMeshes = new .() ~ delete _;
	private Dictionary<MeshRenderer, GPUResourceHandle<GPUMaterial>> mRendererMaterials = new .() ~ delete _;

	// Sprite rendering
	private List<SpriteRenderCommand> mSpriteCommands = new .() ~ delete _;
	private Dictionary<SpriteRenderer, GPUResourceHandle<GPUTexture>> mSpriteTextures = new .() ~ delete _;
	private GPUResourceHandle<GPUMesh> mSpriteQuadMesh ~ _.Release();

	// Current frame data
	private Camera mActiveCamera;
	private Transform mActiveCameraTransform;
	private List<(Light light, Transform transform)> mLights = new .() ~ delete _;
	private Matrix mViewMatrix;
	private Matrix mProjectionMatrix;

	// Depth buffer
	private SDL_GPUTexture* mDepthTexture;

	public this(SDLRendererSubsystem renderer)
	{
		mRenderer = renderer;
		CreateDepthBuffer();
		CreateSpriteQuadMesh();
	}

	public ~this()
	{
		for(var entry in mSpriteTextures)
		{
			entry.value.Release();
		}

		for(var entry in mRendererMaterials)
		{
			entry.value.Release();
		}

		for(var entry in mRendererMeshes)
		{
			entry.value.Release();
		}
		
		if (mDepthTexture != null)
		{
			SDL_ReleaseGPUTexture(mRenderer.mDevice, mDepthTexture);
		}
	}

	private void CreateDepthBuffer()
	{
		var depthTextureDesc = SDL_GPUTextureCreateInfo()
			{
				type = .SDL_GPU_TEXTURETYPE_2D,
				format = .SDL_GPU_TEXTUREFORMAT_D32_FLOAT,
				width = mRenderer.Width,
				height = mRenderer.Height,
				layer_count_or_depth = 1,
				num_levels = 1,
				sample_count = .SDL_GPU_SAMPLECOUNT_1,
				usage = .SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET,
				props = 0
			};
		mDepthTexture = SDL_CreateGPUTexture(mRenderer.mDevice, &depthTextureDesc);
	}

	private void CreateSpriteQuadMesh()
	{
		// Create a simple quad mesh for sprites
		var mesh = new Mesh();
		mesh.SetupCommonVertexFormat();

		mesh.Vertices.Resize(4);
		mesh.Indices.Resize(6);

		// Vertices (unit quad centered at origin)
		mesh.SetPosition(0, .(-0.5f, -0.5f, 0));
		mesh.SetPosition(1, .(0.5f, -0.5f, 0));
		mesh.SetPosition(2, .(0.5f, 0.5f, 0));
		mesh.SetPosition(3, .(-0.5f, 0.5f, 0));

		// UVs
		mesh.SetUV(0, .(0, 1));
		mesh.SetUV(1, .(1, 1));
		mesh.SetUV(2, .(1, 0));
		mesh.SetUV(3, .(0, 0));

		// Normals (facing forward)
		for (int32 i = 0; i < 4; i++)
		{
			mesh.SetNormal(i, .(0, 0, 1));
			mesh.SetColor(i, Color.White.PackedValue);
		}

		// Indices
		mesh.Indices.SetIndex(0, 0);
		mesh.Indices.SetIndex(1, 1);
		mesh.Indices.SetIndex(2, 2);
		mesh.Indices.SetIndex(3, 0);
		mesh.Indices.SetIndex(4, 2);
		mesh.Indices.SetIndex(5, 3);

		var gpuMesh = new GPUMesh("SpriteQuad", mRenderer.mDevice, mesh);
		mSpriteQuadMesh = GPUResourceHandle<GPUMesh>(gpuMesh);
		delete mesh;
	}

	protected override void RegisterComponentInterests()
	{
		RegisterComponentInterest<MeshRenderer>();
		RegisterComponentInterest<SpriteRenderer>();
		RegisterComponentInterest<Camera>();
		RegisterComponentInterest<DirectionalLight>();
		RegisterComponentInterest<PointLight>();
		RegisterComponentInterest<SpotLight>();
	}

	protected override bool ShouldTrackEntity(Entity entity)
	{
		return entity.HasComponent<MeshRenderer>() ||
			entity.HasComponent<SpriteRenderer>() ||
			entity.HasComponent<Camera>() ||
			entity.HasComponent<DirectionalLight>() ||
			entity.HasComponent<PointLight>() ||
			entity.HasComponent<SpotLight>();
	}

	protected override void OnUpdate(Time time)
	{
		// Find active camera and lights
		UpdateActiveCameraAndLights();

		// Clear render commands
		mMeshCommands.Clear();
		mSpriteCommands.Clear();

		// Collect render commands
		CollectRenderCommands();
		CollectSpriteCommands();

		// Sort render commands
		SortRenderCommands();
		SortSpriteCommands();

		// Render the frame
		// RenderFrame();
	}

	/*protected override void OnEntityRemoved(Entity entity)
	{
		base.OnEntityRemoved(entity);
		
		// Clean up any cached resources for this entity
		if (entity.HasComponent<MeshRenderer>())
		{
			var renderer = entity.GetComponent<MeshRenderer>();
			if (mRendererMeshes.GetAndRemove(renderer) case .Ok(let handle))
				handle.Release();
			if (mRendererMaterials.GetAndRemove(renderer) case .Ok(let handle))
				handle.Release();
		}
		
		if (entity.HasComponent<SpriteRenderer>())
		{
			var renderer = entity.GetComponent<SpriteRenderer>();
			if (mSpriteTextures.GetAndRemove(renderer) case .Ok(let handle))
				handle.Release();
		}
	}*/

	private void UpdateActiveCameraAndLights()
	{
		mActiveCamera = null;
		mLights.Clear();

		for (var entity in TrackedEntities)
		{
			if (mActiveCamera == null && entity.HasComponent<Camera>())
			{
				mActiveCamera = entity.GetComponent<Camera>();
				mActiveCameraTransform = entity.Transform;
			}

			// Check for any light type
			Light light = null;
			if (entity.HasComponent<DirectionalLight>())
				light = entity.GetComponent<DirectionalLight>();
			else if (entity.HasComponent<PointLight>())
				light = entity.GetComponent<PointLight>();
			else if (entity.HasComponent<SpotLight>())
				light = entity.GetComponent<SpotLight>();

			if (light != null)
			{
				mLights.Add((light, entity.Transform));

				// Limit to MAX_LIGHTS
				if (mLights.Count >= MAX_LIGHTS)
					break;
			}
		}

		// Update matrices if we have a camera
		if (mActiveCamera != null)
		{
			// Ensure aspect ratio is up to date
			if (mRenderer.Width > 0 && mRenderer.Height > 0)
			{
				mActiveCamera.AspectRatio = (float)mRenderer.Width / (float)mRenderer.Height;
			}

			mViewMatrix = mActiveCamera.ViewMatrix;
			mProjectionMatrix = mActiveCamera.ProjectionMatrix;
		}
		else
		{
			SDL_Log("Warning: No active camera found!");
		}
	}

	private void CollectRenderCommands()
	{
		for (var entity in TrackedEntities)
		{
			if (entity.HasComponent<MeshRenderer>())
			{
				var renderer = entity.GetComponent<MeshRenderer>();
				var transform = entity.Transform;

				var command = MeshRenderCommand()
					{
						Entity = entity,
						WorldMatrix = transform.WorldMatrix,
						Renderer = renderer,
						DistanceToCamera = 0
					};

				if (mActiveCamera != null)
				{
					command.DistanceToCamera = Vector3.Distance(transform.Position, mActiveCameraTransform.Position);
				}

				mMeshCommands.Add(command);
			}
		}
	}

	private void CollectSpriteCommands()
	{
		for (var entity in TrackedEntities)
		{
			if (entity.HasComponent<SpriteRenderer>())
			{
				var renderer = entity.GetComponent<SpriteRenderer>();
				var transform = entity.Transform;

				// Skip if no texture
				if (!renderer.Texture.IsValid || renderer.Texture.Resource == null)
					continue;

				var command = SpriteRenderCommand()
					{
						Entity = entity,
						Renderer = renderer,
						Transform = transform,
						DistanceToCamera = 0,
						SortKey = (renderer.SortingLayer << 16) | (renderer.OrderInLayer & 0xFFFF)
					};

				// Calculate distance for transparency sorting within same layer
				if (mActiveCamera != null)
				{
					command.DistanceToCamera = Vector3.Distance(transform.Position, mActiveCameraTransform.Position);
				}

				mSpriteCommands.Add(command);
			}
		}
	}

	private void SortRenderCommands()
	{
		// Sort front-to-back for better depth rejection
		mMeshCommands.Sort(scope (lhs, rhs) => lhs.DistanceToCamera.CompareTo(rhs.DistanceToCamera));
	}

	private void SortSpriteCommands()
	{
		// Sort by: Layer first, then order in layer, then distance (back to front for transparency)
		mSpriteCommands.Sort(scope (lhs, rhs) =>
			{
				// First sort by layer/order key
				int sortKeyCompare = lhs.SortKey <=> rhs.SortKey;
				if (sortKeyCompare != 0)
					return sortKeyCompare;

				// Same layer/order: sort back-to-front for proper transparency
				return rhs.DistanceToCamera.CompareTo(lhs.DistanceToCamera);
			});
	}

	internal void RenderFrame()
	{
		var commandBuffer = SDL_AcquireGPUCommandBuffer(mRenderer.mDevice);
		if (commandBuffer == null)
		{
			SDL_Log("AcquireGPUCommandBuffer failed: %s", SDL_GetError());
			return;
		}

		defer SDL_SubmitGPUCommandBuffer(commandBuffer);

		// Create GPU resources for any new renderers
		PrepareGPUResources();

		// Get swapchain texture
		SDL_GPUTexture* swapchainTexture = null;
		if (!SDL_WaitAndAcquireGPUSwapchainTexture(commandBuffer,
			(SDL_Window*)mRenderer.mPrimaryWindow.GetNativePointer("SDL"),
			&swapchainTexture, null, null))
		{
			SDL_Log("WaitAndAcquireGPUSwapchainTexture failed: %s", SDL_GetError());
			return;
		}

		if (swapchainTexture == null)
		{
			return;
		}

		// First pass: 3D objects with depth
		Render3DObjects(commandBuffer, swapchainTexture);

		// Second pass: Sprites (no depth write, alpha blended)
		RenderSprites(commandBuffer, swapchainTexture);
	}

	private void PrepareGPUResources()
	{
		var resourceManager = mRenderer.GPUResources;
		
		// Create GPU resources for any new mesh renderers
		for (var command in mMeshCommands)
		{
			// Get or create GPU mesh
			if (!mRendererMeshes.ContainsKey(command.Renderer))
			{
				if (command.Renderer.Mesh.IsValid && command.Renderer.Mesh.Resource != null)
				{
					// This returns a new handle (adds ref)
					var gpuMesh = resourceManager.GetOrCreateMesh(command.Renderer.Mesh.Resource);
					if (gpuMesh.IsValid)
					{
						mRendererMeshes[command.Renderer] = gpuMesh;
					}
				}
			}
			
			// Get or create GPU material
			if (!mRendererMaterials.ContainsKey(command.Renderer))
			{
				if (command.Renderer.Material.IsValid && command.Renderer.Material.Resource != null)
				{
					// This returns a new handle (adds ref)
					var gpuMaterial = resourceManager.GetOrCreateMaterial(command.Renderer.Material.Resource);
					if (gpuMaterial.IsValid)
					{
						mRendererMaterials[command.Renderer] = gpuMaterial;
					}
				}
			}
		}
		
		// Create GPU textures for sprites
		for (var command in mSpriteCommands)
		{
			if (!mSpriteTextures.ContainsKey(command.Renderer))
			{
				if (command.Renderer.Texture.IsValid && command.Renderer.Texture.Resource != null)
				{
					// This returns a new handle (adds ref)
					var gpuTexture = resourceManager.GetOrCreateTexture(command.Renderer.Texture.Resource);
					if (gpuTexture.IsValid)
					{
						mSpriteTextures[command.Renderer] = gpuTexture;
					}
				}
			}
		}
	}

	private void Render3DObjects(SDL_GPUCommandBuffer* commandBuffer, SDL_GPUTexture* swapchainTexture)
	{
		if (mMeshCommands.IsEmpty)
			return;

		// Setup render targets for 3D pass
		var colorTarget = SDL_GPUColorTargetInfo()
			{
				texture = swapchainTexture,
				clear_color = . { r = 0.1f, g = 0.2f, b = 0.3f, a = 1.0f },
				load_op = .SDL_GPU_LOADOP_CLEAR,
				store_op = .SDL_GPU_STOREOP_STORE
			};

		var depthTarget = SDL_GPUDepthStencilTargetInfo()
			{
				texture = mDepthTexture,
				clear_depth = 1.0f,
				load_op = .SDL_GPU_LOADOP_CLEAR,
				store_op = .SDL_GPU_STOREOP_STORE, // Keep depth for sprite rendering
				stencil_load_op = .SDL_GPU_LOADOP_DONT_CARE,
				stencil_store_op = .SDL_GPU_STOREOP_DONT_CARE,
				cycle = false
			};

		var renderPass = SDL_BeginGPURenderPass(commandBuffer, &colorTarget, 1, &depthTarget);
		defer SDL_EndGPURenderPass(renderPass);

		// Set viewport
		var viewport = SDL_GPUViewport()
			{
				x = 0, y = 0,
				w = (float)mRenderer.Width,
				h = (float)mRenderer.Height,
				min_depth = 0.0f,
				max_depth = 1.0f
			};
		SDL_SetGPUViewport(renderPass, &viewport);

		// Render all 3D objects
		for (var command in mMeshCommands)
		{
			RenderObject(commandBuffer, renderPass, command);
		}
	}

	private void RenderSprites(SDL_GPUCommandBuffer* commandBuffer, SDL_GPUTexture* swapchainTexture)
	{
		if (mSpriteCommands.IsEmpty)
			return;

		// Setup render targets for sprite pass (no clear, preserve 3D render)
		var colorTarget = SDL_GPUColorTargetInfo()
			{
				texture = swapchainTexture,
				load_op = .SDL_GPU_LOADOP_LOAD, // Don't clear
				store_op = .SDL_GPU_STOREOP_STORE
			};

		// Use depth buffer for testing but not writing (sprites respect depth but don't write to it)
		var depthTarget = SDL_GPUDepthStencilTargetInfo()
			{
				texture = mDepthTexture,
				load_op = .SDL_GPU_LOADOP_DONT_CARE, // Don't load when cycling
				store_op = .SDL_GPU_STOREOP_DONT_CARE,
				stencil_load_op = .SDL_GPU_LOADOP_DONT_CARE,
				stencil_store_op = .SDL_GPU_STOREOP_DONT_CARE,
				cycle = true // Read-only depth
			};

		var renderPass = SDL_BeginGPURenderPass(commandBuffer, &colorTarget, 1, &depthTarget);
		defer SDL_EndGPURenderPass(renderPass);

		// Set viewport
		var viewport = SDL_GPUViewport()
			{
				x = 0, y = 0,
				w = (float)mRenderer.Width,
				h = (float)mRenderer.Height,
				min_depth = 0.0f,
				max_depth = 1.0f
			};
		SDL_SetGPUViewport(renderPass, &viewport);

		// Render all sprites
		// TODO: Batch sprites by texture to reduce state changes
		for (var command in mSpriteCommands)
		{
			RenderSprite(commandBuffer, renderPass, command);
		}
	}

	private void RenderObject(SDL_GPUCommandBuffer* commandBuffer, SDL_GPURenderPass* renderPass, MeshRenderCommand command)
	{
		if (!mRendererMeshes.TryGetValue(command.Renderer, let meshHandle) || !meshHandle.IsValid)
			return;

		var mesh = meshHandle.Resource;

		// Get mesh data
		SDL_GPUBuffer* vertexBuffer = mesh.VertexBuffer;
		SDL_GPUBuffer* indexBuffer = mesh.IndexBuffer;
		uint32 indexCount = mesh.IndexCount;

		// Determine which pipeline to use
		bool useLit = true;
		bool usePBR = false;
		GPUMaterial gpuMaterial = null;

		if (mRendererMaterials.TryGetValue(command.Renderer, let materialHandle) && materialHandle.IsValid)
		{
			gpuMaterial = materialHandle.Resource;
			// Determine pipeline based on material's shader name
			switch (gpuMaterial.ShaderName)
			{
			case "Unlit":
				useLit = false;
				usePBR = false;
			case "PBR":
				useLit = false;
				usePBR = true;
			default: // "Phong" or others
				useLit = true;
				usePBR = false;
			}
		}

		// Bind pipeline
		SDL_GPUGraphicsPipeline* pipeline;
		if (usePBR)
			pipeline = mRenderer.GetPBRPipeline();
		else
			pipeline = mRenderer.GetPipeline(useLit);
		SDL_BindGPUGraphicsPipeline(renderPass, pipeline);

		// Bind vertex and index buffers
		var vertexBinding = SDL_GPUBufferBinding()
			{
				buffer = vertexBuffer,
				offset = 0
			};
		SDL_BindGPUVertexBuffers(renderPass, 0, &vertexBinding, 1);
		SDL_BindGPUIndexBuffer(renderPass, scope .() { buffer = indexBuffer, offset = 0 }, .SDL_GPU_INDEXELEMENTSIZE_32BIT);

		// Bind textures - always ensure something is bound to prevent crashes
		if (gpuMaterial != null)
		{
			// Let the material bind its textures, filling missing slots with defaults
			gpuMaterial.BindTextures(renderPass,
				mRenderer.GetDefaultWhiteTexture(),
				mRenderer.GetDefaultNormalTexture(),
				mRenderer.GetDefaultBlackTexture());
		}
		else
		{
			// No material - bind appropriate defaults based on pipeline
			if (usePBR)
			{
				// For PBR without material, bind defaults
				var defaultWhite = mRenderer.GetDefaultWhiteTexture();
				var defaultNormal = mRenderer.GetDefaultNormalTexture();

				// Albedo texture
				var albedoBinding = SDL_GPUTextureSamplerBinding()
					{
						texture = defaultWhite.Resource.Texture,
						sampler = defaultWhite.Resource.Sampler
					};
				SDL_BindGPUFragmentSamplers(renderPass, 0, &albedoBinding, 1);

				// Normal texture
				var normalBinding = SDL_GPUTextureSamplerBinding()
					{
						texture = defaultNormal.Resource.Texture,
						sampler = defaultNormal.Resource.Sampler
					};
				SDL_BindGPUFragmentSamplers(renderPass, 1, &normalBinding, 1);

				// Metallic/Roughness texture (use white)
				var metallicBinding = SDL_GPUTextureSamplerBinding()
					{
						texture = defaultWhite.Resource.Texture,
						sampler = defaultWhite.Resource.Sampler
					};
				SDL_BindGPUFragmentSamplers(renderPass, 2, &metallicBinding, 1);
			}
			else
			{
				// For lit and unlit without material, bind default white texture
				var defaultWhite = mRenderer.GetDefaultWhiteTexture();
				var textureSamplerBinding = SDL_GPUTextureSamplerBinding()
					{
						texture = defaultWhite.Resource.Texture,
						sampler = defaultWhite.Resource.Sampler
					};
				SDL_BindGPUFragmentSamplers(renderPass, 0, &textureSamplerBinding, 1);
			}
		}

		// Push uniform data for this object
		if (mActiveCamera != null)
		{
			if (usePBR)
			{
				// PBR rendering
				Matrix normalMatrix = command.WorldMatrix;
				normalMatrix = Matrix.Invert(normalMatrix);
				normalMatrix = Matrix.Transpose(normalMatrix);

				var vertexUniforms = PBRVertexUniforms()
					{
						MVPMatrix = command.WorldMatrix * mViewMatrix * mProjectionMatrix,
						ModelMatrix = command.WorldMatrix,
						NormalMatrix = normalMatrix
					};

				SDL_PushGPUVertexUniformData(commandBuffer, 0, &vertexUniforms, sizeof(PBRVertexUniforms));

				// Prepare PBR fragment uniforms with light array
				var fragmentUniforms = PBRFragmentUniforms();

				// Default PBR values
				var albedoColor = command.Renderer.Color.ToVector4();
				var emissiveColor = Vector4.Zero;
				float metallic = 0.0f;
				float roughness = 0.5f;
				float ao = 1.0f;

				if (gpuMaterial != null && command.Renderer.Material.Resource?.Material is PBRMaterial)
				{
					var pbrMat = command.Renderer.Material.Resource?.Material as PBRMaterial;
					albedoColor = pbrMat.AlbedoColor.ToVector4();
					emissiveColor = Vector4(
						pbrMat.EmissiveColor.R / 255.0f,
						pbrMat.EmissiveColor.G / 255.0f,
						pbrMat.EmissiveColor.B / 255.0f,
						pbrMat.EmissiveIntensity
						);
					metallic = pbrMat.Metallic;
					roughness = pbrMat.Roughness;
					ao = pbrMat.AmbientOcclusion;
				}

				fragmentUniforms.AlbedoColor = albedoColor;
				fragmentUniforms.EmissiveColor = emissiveColor;
				fragmentUniforms.MetallicRoughnessAO = Vector4(metallic, roughness, ao, 0);
				fragmentUniforms.CameraPos = Vector4(mActiveCameraTransform.Position.X, mActiveCameraTransform.Position.Y, mActiveCameraTransform.Position.Z, 0);

				// Fill light array
				int lightCount = Math.Min(mLights.Count, MAX_LIGHTS);
				for (int i = 0; i < lightCount; i++)
				{
					var (light, transform) = mLights[i];

					// Position and type
					float lightType = 0.0f; // Default to directional
					if (light is PointLight)
						lightType = 1.0f;
					else if (light is SpotLight)
						lightType = 2.0f;

					fragmentUniforms.Lights[i].PositionType = Vector4(
						transform.Position.X,
						transform.Position.Y,
						transform.Position.Z,
						lightType
						);

					// Direction and range
					var direction = transform.Forward;
					float range = 10.0f; // Default range for point/spot lights
					if (light is PointLight)
					{
						range = ((PointLight)light).Range;
					}
					else if (light is SpotLight)
					{
						range = ((SpotLight)light).Range;
					}

					fragmentUniforms.Lights[i].DirectionRange = Vector4(
						direction.X,
						direction.Y,
						direction.Z,
						range
						);

					// Color and intensity
					fragmentUniforms.Lights[i].ColorIntensity = Vector4(
						light.Color.X,
						light.Color.Y,
						light.Color.Z,
						light.Intensity
						);

					// Spot angles (for spot lights)
					float innerCos = 1.0f;
					float outerCos = 0.0f;
					if (light is SpotLight)
					{
						var spotLight = (SpotLight)light;
						innerCos = Math.Cos(Math.DegreesToRadians(spotLight.InnerConeAngle));
						outerCos = Math.Cos(Math.DegreesToRadians(spotLight.OuterConeAngle));
					}

					fragmentUniforms.Lights[i].SpotAngles = Vector4(innerCos, outerCos, 1.0f, 0.0f);
				}

				fragmentUniforms.LightCount = Vector4((float)lightCount, 0, 0, 0);

				SDL_PushGPUFragmentUniformData(commandBuffer, 0, &fragmentUniforms, sizeof(PBRFragmentUniforms));
			}
			else if (useLit)
			{
				// Prepare vertex uniforms
				Matrix normalMatrix = command.WorldMatrix;
				normalMatrix = Matrix.Invert(normalMatrix);
				normalMatrix = Matrix.Transpose(normalMatrix);

				var vertexUniforms = LitVertexUniforms()
					{
						MVPMatrix = command.WorldMatrix * mViewMatrix * mProjectionMatrix,
						ModelMatrix = command.WorldMatrix,
						NormalMatrix = normalMatrix
					};

				// Push vertex uniform data
				SDL_PushGPUVertexUniformData(commandBuffer, 0, &vertexUniforms, sizeof(LitVertexUniforms));

				// Prepare fragment uniforms with light array
				var fragmentUniforms = LitFragmentUniforms();

				// Use material color if available, otherwise use renderer's color
				var materialColor = command.Renderer.Color.ToVector4();
				var specularColor = Vector4(0.5f, 0.5f, 0.5f, 32.0f); // Default specular with shininess
				var ambientColor = Vector4(0.2f, 0.2f, 0.2f, 1.0f); // Default ambient

				if (gpuMaterial != null && command.Renderer.Material.Resource?.Material is PhongMaterial)
				{
					var phongMat = command.Renderer.Material.Resource?.Material as PhongMaterial;
					materialColor = phongMat.DiffuseColor.ToVector4();
					specularColor = Vector4(
						phongMat.SpecularColor.R / 255.0f,
						phongMat.SpecularColor.G / 255.0f,
						phongMat.SpecularColor.B / 255.0f,
						phongMat.Shininess
						);
					ambientColor = phongMat.AmbientColor.ToVector4();
				}

				fragmentUniforms.MaterialColor = materialColor;
				fragmentUniforms.SpecularColorShininess = specularColor;
				fragmentUniforms.AmbientColor = ambientColor;
				fragmentUniforms.CameraPos = Vector4(mActiveCameraTransform.Position.X, mActiveCameraTransform.Position.Y, mActiveCameraTransform.Position.Z, 0);

				// Fill light array
				int lightCount = Math.Min(mLights.Count, MAX_LIGHTS);
				for (int i = 0; i < lightCount; i++)
				{
					var (light, transform) = mLights[i];

					// Position and type
					float lightType = 0.0f; // Default to directional
					if (light is PointLight)
						lightType = 1.0f;
					else if (light is SpotLight)
						lightType = 2.0f;

					fragmentUniforms.Lights[i].PositionType = Vector4(
						transform.Position.X,
						transform.Position.Y,
						transform.Position.Z,
						lightType
						);

					// Direction and range
					var direction = transform.Forward;
					float range = 10.0f; // Default range for point/spot lights
					if (light is PointLight)
					{
						range = ((PointLight)light).Range;
					}
					else if (light is SpotLight)
					{
						range = ((SpotLight)light).Range;
					}

					fragmentUniforms.Lights[i].DirectionRange = Vector4(
						direction.X,
						direction.Y,
						direction.Z,
						range
						);

					// Color and intensity
					fragmentUniforms.Lights[i].ColorIntensity = Vector4(
						light.Color.X,
						light.Color.Y,
						light.Color.Z,
						light.Intensity
						);

					// Spot angles (for spot lights)
					float innerCos = 1.0f;
					float outerCos = 0.0f;
					if (light is SpotLight)
					{
						var spotLight = (SpotLight)light;
						innerCos = Math.Cos(Math.DegreesToRadians(spotLight.InnerConeAngle));
						outerCos = Math.Cos(Math.DegreesToRadians(spotLight.OuterConeAngle));
					}

					fragmentUniforms.Lights[i].SpotAngles = Vector4(innerCos, outerCos, 1.0f, 0.0f);
				}

				fragmentUniforms.LightCount = Vector4((float)lightCount, 0, 0, 0);

				// Push fragment uniform data
				SDL_PushGPUFragmentUniformData(commandBuffer, 0, &fragmentUniforms, sizeof(LitFragmentUniforms));
			}
			else
			{
				// Unlit rendering
				var vertexUniforms = UnlitVertexUniforms()
					{
						MVPMatrix = command.WorldMatrix * mViewMatrix * mProjectionMatrix,
						ModelMatrix = command.WorldMatrix
					};

				// Use material color if available
				var materialColor = command.Renderer.Color.ToVector4();
				if (gpuMaterial != null && command.Renderer.Material.Resource?.Material is UnlitMaterial)
				{
					var unlitMat = command.Renderer.Material.Resource?.Material as UnlitMaterial;
					materialColor = unlitMat.Color.ToVector4();
				}

				var fragmentUniforms = UnlitFragmentUniforms()
					{
						MaterialColor = materialColor
					};

				// Push uniform data
				SDL_PushGPUVertexUniformData(commandBuffer, 0, &vertexUniforms, sizeof(UnlitVertexUniforms));
				SDL_PushGPUFragmentUniformData(commandBuffer, 0, &fragmentUniforms, sizeof(UnlitFragmentUniforms));
			}
		}

		// Draw
		SDL_DrawGPUIndexedPrimitives(renderPass, indexCount, 1, 0, 0, 0);
	}

	private void RenderSprite(SDL_GPUCommandBuffer* commandBuffer, SDL_GPURenderPass* renderPass, SpriteRenderCommand command)
	{
		if (!mSpriteTextures.TryGetValue(command.Renderer, let gpuTexture) || !gpuTexture.IsValid)
			return;

		// Get sprite pipeline
		var pipeline = mRenderer.GetSpritePipeline();
		SDL_BindGPUGraphicsPipeline(renderPass, pipeline);

		// Bind vertex and index buffers from sprite quad
		var vertexBinding = SDL_GPUBufferBinding()
			{
				buffer = mSpriteQuadMesh.Resource.VertexBuffer,
				offset = 0
			};
		SDL_BindGPUVertexBuffers(renderPass, 0, &vertexBinding, 1);
		SDL_BindGPUIndexBuffer(renderPass, scope .() { buffer = mSpriteQuadMesh.Resource.IndexBuffer, offset = 0 }, .SDL_GPU_INDEXELEMENTSIZE_32BIT);

		// Bind texture and sampler
		var textureSamplerBinding = SDL_GPUTextureSamplerBinding()
			{
				texture = gpuTexture.Resource.Texture,
				sampler = gpuTexture.Resource.Sampler
			};
		SDL_BindGPUFragmentSamplers(renderPass, 0, &textureSamplerBinding, 1);

		// Calculate sprite transform
		var spriteSize = command.Renderer.GetRenderSize();
		var pivot = command.Renderer.Pivot;

		// Build sprite transform matrix
		var pivotOffset = Matrix.CreateTranslation(-pivot.X * spriteSize.X, -pivot.Y * spriteSize.Y, 0);
		var scale = Matrix.CreateScale(spriteSize.X, spriteSize.Y, 1);
		var worldMatrix = pivotOffset * scale * command.Transform.WorldMatrix;

		// Handle billboarding
		if (command.Renderer.Billboard != .None && mActiveCamera != null)
		{
			var position = command.Transform.Position;
			var cameraPos = mActiveCameraTransform.Position;

			switch (command.Renderer.Billboard)
			{
			case .Full:
				// Full billboard: extract camera's right and up vectors from view matrix
				// The view matrix transforms from world to camera space, so we need its inverse
				var cameraWorldMatrix = Matrix.Invert(mViewMatrix);

				// Extract camera's right and up vectors (first two rows of camera world matrix)
				var right = Vector3(cameraWorldMatrix.M11, cameraWorldMatrix.M12, cameraWorldMatrix.M13);
				var up = Vector3(cameraWorldMatrix.M21, cameraWorldMatrix.M22, cameraWorldMatrix.M23);

				// Build billboard matrix that faces camera
				var billboardMatrix = Matrix(
					right.X * spriteSize.X, right.Y * spriteSize.X, right.Z * spriteSize.X, 0,
					up.X * spriteSize.Y, up.Y * spriteSize.Y, up.Z * spriteSize.Y, 0,
					0, 0, 0, 0, // No forward vector needed for billboard
					position.X, position.Y, position.Z, 1
					);

				// Apply pivot offset in billboard space
				var pivotOffsetWorld = right * (-pivot.X * spriteSize.X) + up * (-pivot.Y * spriteSize.Y);
				billboardMatrix.M41 += pivotOffsetWorld.X;
				billboardMatrix.M42 += pivotOffsetWorld.Y;
				billboardMatrix.M43 += pivotOffsetWorld.Z;

				worldMatrix = billboardMatrix;

			case .AxisAligned:
				// Y-axis aligned billboard: only rotate around Y to face camera
				// Keep the sprite upright while rotating to face camera horizontally
				var toCameraXZ = Vector3(cameraPos.X - position.X, 0, cameraPos.Z - position.Z);
				if (toCameraXZ.LengthSquared() > 0.0001f)
				{
					// Get camera's right vector projected onto XZ plane
					var cameraWorldMatrix = Matrix.Invert(mViewMatrix);
					var cameraRight = Vector3(cameraWorldMatrix.M11, 0, cameraWorldMatrix.M13);

					// Normalize and ensure we have a valid right vector
					if (cameraRight.LengthSquared() > 0.0001f)
					{
						cameraRight = Vector3.Normalize(cameraRight);
					}
					else
					{
						// Fallback if camera is looking straight up/down
						toCameraXZ = Vector3.Normalize(toCameraXZ);
						cameraRight = Vector3.Cross(Vector3.Up, toCameraXZ);
					}

					// Build the billboard matrix
					var billboardMatrix = Matrix(
						cameraRight.X * spriteSize.X, 0, cameraRight.Z * spriteSize.X, 0,
						0, spriteSize.Y, 0, 0, // Keep Y-up
						0, 0, 0, 0,
						position.X, position.Y, position.Z, 1
						);

					// Apply pivot offset
					var pivotOffsetWorld = cameraRight * (-pivot.X * spriteSize.X) + Vector3.Up * (-pivot.Y * spriteSize.Y);
					billboardMatrix.M41 += pivotOffsetWorld.X;
					billboardMatrix.M42 += pivotOffsetWorld.Y;
					billboardMatrix.M43 += pivotOffsetWorld.Z;

					worldMatrix = billboardMatrix;
				}

			default:
				break;
			}
		}

		// Calculate UV offset and scale from source rect
		Vector2 uvMin, uvMax;
		command.Renderer.GetUVs(out uvMin, out uvMax);

		var uvOffset = uvMin;
		var uvScale = uvMax - uvMin;

		// Push vertex uniforms
		var vertexUniforms = SpriteVertexUniforms()
			{
				MVPMatrix = worldMatrix * mViewMatrix * mProjectionMatrix,
				UVOffsetScale = Vector4(uvOffset.X, uvOffset.Y, uvScale.X, uvScale.Y)
			};
		SDL_PushGPUVertexUniformData(commandBuffer, 0, &vertexUniforms, sizeof(SpriteVertexUniforms));

		// Push fragment uniforms
		var fragmentUniforms = SpriteFragmentUniforms()
			{
				TintColor = command.Renderer.Color.ToVector4()
			};
		SDL_PushGPUFragmentUniformData(commandBuffer, 0, &fragmentUniforms, sizeof(SpriteFragmentUniforms));

		// Draw
		SDL_DrawGPUIndexedPrimitives(renderPass, 6, 1, 0, 0, 0);
	}
}