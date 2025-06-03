using Sedulous.SceneGraph;
using System;
using SDL3Native;
using System.Collections;
using Sedulous.Mathematics;
using Sedulous.Resources;
using Sedulous.SceneGraph;
using Sedulous.Utilities;

namespace Sedulous.Engine.Renderer.SDL;

using internal Sedulous.Engine.Renderer.SDL;

class RenderModule : SceneModule
{
	public override StringView Name => "Render";

	private SDLRendererSubsystem mRenderer;
	private List<RenderCommand> mRenderCommands = new .() ~ delete _;

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
	}

	public ~this()
	{
		for (var entry in mRendererMeshes)
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

	protected override void RegisterComponentInterests()
	{
		RegisterComponentInterest<MeshRenderer>();
		RegisterComponentInterest<Camera>();
		RegisterComponentInterest<Light>();
	}

	protected override bool ShouldTrackEntity(Entity entity)
	{
		return entity.HasComponent<MeshRenderer>() ||
			entity.HasComponent<Camera>() ||
			entity.HasComponent<Light>();
	}

	protected override void OnUpdate(Time time)
	{
		// Find active camera and lights
		UpdateActiveCameraAndLights();

		// Clear render commands
		mRenderCommands.Clear();

		// Collect render commands
		CollectRenderCommands();

		// Sort render commands
		SortRenderCommands();

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
			//mViewMatrix = Matrix.Invert(mViewMatrix);
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

	private void SortRenderCommands()
	{
		// Sort front-to-back for better depth rejection
		mRenderCommands.Sort(scope (lhs, rhs) => lhs.DistanceToCamera.CompareTo(rhs.DistanceToCamera));
	}

	private Dictionary<MeshRenderer, GPUMesh> mRendererMeshes = new .() ~ delete _;

	private void RenderFrame()
	{
		var commandBuffer = SDL_AcquireGPUCommandBuffer(mRenderer.mDevice);
		if (commandBuffer == null)
		{
			SDL_Log("AcquireGPUCommandBuffer failed: %s", SDL_GetError());
			return;
		}

		defer SDL_SubmitGPUCommandBuffer(commandBuffer);

		// Create GPU meshes for any new renderers
		for (var command in mRenderCommands)
		{
			if (!mRendererMeshes.ContainsKey(command.Renderer))
			{
				mRendererMeshes[command.Renderer] = new GPUMesh(mRenderer.mDevice, command.Renderer.Mesh.Resource.Mesh);
			}
		}

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
			// Setup render targets
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
				store_op = .SDL_GPU_STOREOP_DONT_CARE,
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

			// Update camera aspect ratio if needed
		if (mActiveCamera != null)
		{
			mActiveCamera.AspectRatio = (float)mRenderer.Width / (float)mRenderer.Height;
		}

			// Render all commands
		for (var command in mRenderCommands)
		{
			RenderObject(commandBuffer, renderPass, command);
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
		var pipeline = mRenderer.GetPipeline( /*command.Renderer.UseLighting*/true);
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
			if ( /*command.Renderer.UseLighting*/true)
			{
				// Prepare vertex uniforms
				Matrix normalMatrix = command.WorldMatrix;
				normalMatrix = Matrix.Invert(normalMatrix);
				normalMatrix = Matrix.Transpose(normalMatrix);

				var vertexUniforms = LitVertexUniforms()
					{
						MVPMatrix = command.WorldMatrix * mViewMatrix * mProjectionMatrix,
						ModelMatrix = command.WorldMatrix,
						NormalMatrix = normalMatrix // Already transposed
					};

				// Push vertex uniform data - slot 0 matches register(b0)
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

				// Push fragment uniform data - slot 0 matches register(b0)
				SDL_PushGPUFragmentUniformData(commandBuffer, 0, &fragmentUniforms, sizeof(LitFragmentUniforms));
			}
			/*else
			{
				// Unlit rendering
				var vertexUniforms = UnlitVertexUniforms()
				{
					MVPMatrix = command.WorldMatrix * mViewMatrix * mProjectionMatrix, 
					ModelMatrix = command.WorldMatrix 
				};

				var fragmentUniforms = UnlitFragmentUniforms()
				{
					MaterialColor = command.Renderer.Color
				};

				// Push uniform data
				SDL_PushGPUVertexUniformData(commandBuffer, 0, &vertexUniforms, sizeof(UnlitVertexUniforms));
				SDL_PushGPUFragmentUniformData(commandBuffer, 0, &fragmentUniforms, sizeof(UnlitFragmentUniforms));
			}*/
		}

		// Draw
		SDL_DrawGPUIndexedPrimitives(renderPass, indexCount, 1, 0, 0, 0);
	}
}