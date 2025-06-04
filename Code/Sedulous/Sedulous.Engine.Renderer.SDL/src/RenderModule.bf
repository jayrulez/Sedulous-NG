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

// Sprite render command
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
	private List<RenderCommand> mRenderCommands = new .() ~ delete _;
	private Dictionary<MeshRenderer, GPUMesh> mRendererMeshes = new .() ~ delete _;

	// Sprite rendering
	private List<SpriteRenderCommand> mSpriteCommands = new .() ~ delete _;
	private Dictionary<TextureResource, GPUTexture> mTextureCache = new .() ~ delete _;
	private GPUMesh mSpriteQuadMesh ~ delete _;

	// Current frame data
	private Camera mActiveCamera;
	private Transform mActiveCameraTransform;
	private Light mMainLight;
	private Transform mMainLightTransform;
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
		for (var entry in mRendererMeshes)
		{
			delete entry.value;
		}

		for (var entry in mTextureCache)
		{
			delete entry.value;
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

		mSpriteQuadMesh = new GPUMesh(mRenderer.mDevice, mesh);
		delete mesh;
	}

	protected override void RegisterComponentInterests()
	{
		RegisterComponentInterest<MeshRenderer>();
		RegisterComponentInterest<SpriteRenderer>();
		RegisterComponentInterest<Camera>();
		RegisterComponentInterest<Light>();
	}

	protected override bool ShouldTrackEntity(Entity entity)
	{
		return entity.HasComponent<MeshRenderer>() ||
			entity.HasComponent<SpriteRenderer>() ||
			entity.HasComponent<Camera>() ||
			entity.HasComponent<Light>();
	}

	protected override void OnUpdate(Time time)
	{
		// Find active camera and lights
		UpdateActiveCameraAndLights();

		// Clear render commands
		mRenderCommands.Clear();
		mSpriteCommands.Clear();

		// Collect render commands
		CollectRenderCommands();
		CollectSpriteCommands();

		// Sort render commands
		SortRenderCommands();
		SortSpriteCommands();

		// Render the frame
		RenderFrame();
	}

	private void UpdateActiveCameraAndLights()
	{
		mActiveCamera = null;
		mMainLight = null;

		for (var entity in TrackedEntities)
		{
			if (mActiveCamera == null && entity.HasComponent<Camera>())
			{
				mActiveCamera = entity.GetComponent<Camera>();
				mActiveCameraTransform = entity.Transform;
			}

			if (mMainLight == null && entity.HasComponent<Light>())
			{
				var light = entity.GetComponent<Light>();
				if (light.Type == .Directional)
				{
					mMainLight = light;
					mMainLightTransform = entity.Transform;
				}
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

			mViewMatrix =  mActiveCamera.ViewMatrix;
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

				var command = RenderCommand()
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

				mRenderCommands.Add(command);
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
		mRenderCommands.Sort(scope (lhs, rhs) => lhs.DistanceToCamera.CompareTo(rhs.DistanceToCamera));
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

	private void RenderFrame()
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
		// Create GPU meshes for any new mesh renderers
		for (var command in mRenderCommands)
		{
			if (!mRendererMeshes.ContainsKey(command.Renderer))
			{
				mRendererMeshes[command.Renderer] = new GPUMesh(mRenderer.mDevice, command.Renderer.Mesh.Resource.Mesh);
			}
		}

		// Create GPU textures for any new sprite textures
		for (var command in mSpriteCommands)
		{
			var textureResource = command.Renderer.Texture.Resource;
			if (!mTextureCache.ContainsKey(textureResource))
			{
				mTextureCache[textureResource] = new GPUTexture(mRenderer.mDevice, textureResource);
			}
		}
	}

	private void Render3DObjects(SDL_GPUCommandBuffer* commandBuffer, SDL_GPUTexture* swapchainTexture)
	{
		if (mRenderCommands.IsEmpty)
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
		for (var command in mRenderCommands)
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
				load_op = .SDL_GPU_LOADOP_LOAD,
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

	private void RenderObject(SDL_GPUCommandBuffer* commandBuffer, SDL_GPURenderPass* renderPass, RenderCommand command)
	{
		if (!mRendererMeshes.ContainsKey(command.Renderer))
			return;

		var mesh = mRendererMeshes[command.Renderer];

		// Get mesh data
		SDL_GPUBuffer* vertexBuffer = mesh.VertexBuffer;
		SDL_GPUBuffer* indexBuffer = mesh.IndexBuffer;
		uint32 indexCount = mesh.IndexCount;

		// Bind pipeline
		var pipeline = mRenderer.GetPipeline(true);
		SDL_BindGPUGraphicsPipeline(renderPass, pipeline);

		// Bind vertex and index buffers
		var vertexBinding = SDL_GPUBufferBinding()
			{
				buffer = vertexBuffer,
				offset = 0
			};
		SDL_BindGPUVertexBuffers(renderPass, 0, &vertexBinding, 1);
		SDL_BindGPUIndexBuffer(renderPass, scope .() { buffer = indexBuffer, offset = 0 }, .SDL_GPU_INDEXELEMENTSIZE_32BIT);

		// Push uniform data for this object
		if (mActiveCamera != null)
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

				// Prepare fragment uniforms
			var lightDir = mMainLight != null ? mMainLightTransform.Forward : Vector3(0, -1, 0);
			var lightColor = mMainLight != null ? mMainLight.Color : Vector3(1, 1, 1);
			var lightIntensity = mMainLight != null ? mMainLight.Intensity : 1.0f;

			var fragmentUniforms = LitFragmentUniforms()
				{
					LightDirAndIntensity = Vector4(lightDir.X, lightDir.Y, lightDir.Z, lightIntensity),
					LightColorPad = Vector4(lightColor.X, lightColor.Y, lightColor.Z, 0),
					MaterialColor = command.Renderer.Color.ToVector4(),
					CameraPosAndPad = Vector4(mActiveCameraTransform.Position.X, mActiveCameraTransform.Position.Y, mActiveCameraTransform.Position.Z, 0)
				};

				// Push fragment uniform data
			SDL_PushGPUFragmentUniformData(commandBuffer, 0, &fragmentUniforms, sizeof(LitFragmentUniforms));
		}

		// Draw
		SDL_DrawGPUIndexedPrimitives(renderPass, indexCount, 1, 0, 0, 0);
	}

	private void RenderSprite(SDL_GPUCommandBuffer* commandBuffer, SDL_GPURenderPass* renderPass, SpriteRenderCommand command)
	{
		var gpuTexture = mTextureCache[command.Renderer.Texture.Resource];
		if (gpuTexture == null)
			return;

		// TODO: Get sprite pipeline from renderer when implemented
		// For now, we'll need to add GetSpritePipeline() to SDLRendererSubsystem
		/*
		var pipeline = mRenderer.GetSpritePipeline();
		SDL_BindGPUGraphicsPipeline(renderPass, pipeline);
		
		// Bind vertex and index buffers from sprite quad
		var vertexBinding = SDL_GPUBufferBinding()
		{
			buffer = mSpriteQuadMesh.VertexBuffer,
			offset = 0
		};
		SDL_BindGPUVertexBuffers(renderPass, 0, &vertexBinding, 1);
		SDL_BindGPUIndexBuffer(renderPass, scope .() { buffer = mSpriteQuadMesh.IndexBuffer, offset = 0 }, .SDL_GPU_INDEXELEMENTSIZE_32BIT);
		
		// TODO: Bind texture and sampler
		// This will depend on how your sprite shader is set up
		
		// Calculate sprite transform
		var spriteSize = command.Renderer.GetRenderSize();
		var pivot = command.Renderer.Pivot;
		
		// Build sprite transform matrix
		var pivotOffset = Matrix.CreateTranslation(-pivot.X * spriteSize.X, -pivot.Y * spriteSize.Y, 0);
		var scale = Matrix.CreateScale(spriteSize.X, spriteSize.Y, 1);
		var worldMatrix = pivotOffset * scale * command.Transform.WorldMatrix;
		
		// Handle billboarding
		if (command.Renderer.Billboard != .None)
		{
			// TODO: Implement billboarding transforms
		}
		
		// Push sprite uniforms
		// TODO: Create sprite-specific uniform structure
		
		// Draw
		SDL_DrawGPUIndexedPrimitives(renderPass, 6, 1, 0, 0, 0);
		*/

		// For now, log that sprite rendering is not yet implemented
		SDL_Log("Sprite rendering pipeline not yet implemented");
	}
}