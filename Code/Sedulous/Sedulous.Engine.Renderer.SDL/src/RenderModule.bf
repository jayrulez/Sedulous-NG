using Sedulous.SceneGraph;
using System;
using SDL3Native;
using System.Collections;
using Sedulous.Foundation.Mathematics;
using Sedulous.Resources;
using Sedulous.SceneGraph;

namespace Sedulous.Engine.Renderer.SDL;

using internal Sedulous.Engine.Renderer.SDL;

// Render data structures
struct RenderCommand
{
    public Entity Entity;
    public Matrix WorldMatrix;
    public MeshRenderer Renderer;
    public float DistanceToCamera;
	public uint32 UniformOffset; // Offset into the uniform buffer for this object
}

// Uniform buffer structures must match shader exactly
[CRepr, Packed]
struct LitVertexUniforms
{
    public Matrix ViewProjection;
    public Matrix World;
    public Matrix NormalMatrix;
}

[CRepr, Packed]
struct LitFragmentUniforms
{
    public Vector4 LightDirAndIntensity;  // xyz = direction, w = intensity
    public Vector4 LightColorPad;          // xyz = color, w = padding
    public Vector4 MaterialColor;
    public Vector4 CameraPosAndPad;        // xyz = position, w = padding
}

[CRepr, Packed]
struct UnlitVertexUniforms
{
    public Matrix ViewProjection;
    public Matrix World;
}

[CRepr, Packed]
struct UnlitFragmentUniforms
{
    public Vector4 MaterialColor;
}

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
    private Matrix mViewProjectionMatrix;
    
    // Depth buffer
    private SDL_GPUTexture* mDepthTexture;

	// Dynamic uniform buffer management
	private const uint32 UNIFORM_ALIGNMENT = 256; // Typical alignment requirement
	private SDL_GPUBuffer* mDynamicVertexUniformBuffer;
	private SDL_GPUBuffer* mDynamicFragmentUniformBuffer;
	private uint32 mMaxObjectCount = 1000; // Maximum objects we can render

	// Staging data for uniform updates
	private uint8* mVertexUniformStagingData ~ delete _;
	private uint8* mFragmentUniformStagingData ~ delete _;

    public this(SDLRendererSubsystem renderer)
    {
        mRenderer = renderer;
        CreateDepthBuffer();
		CreateDynamicUniformBuffers();
    }

    public ~this()
    {
		for(var entry in mRendererMeshes)
		{
			delete entry.value;
		}

        if (mDepthTexture != null)
        {
            SDL_ReleaseGPUTexture(mRenderer.mDevice, mDepthTexture);
        }

		if (mDynamicVertexUniformBuffer != null)
		{
		    SDL_ReleaseGPUBuffer(mRenderer.mDevice, mDynamicVertexUniformBuffer);
		}

		if (mDynamicFragmentUniformBuffer != null)
		{
		    SDL_ReleaseGPUBuffer(mRenderer.mDevice, mDynamicFragmentUniformBuffer);
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

	private void CreateDynamicUniformBuffers()
	{
	    // Calculate sizes with alignment
	    uint32 vertexUniformSize = (uint32)Math.Max(sizeof(LitVertexUniforms), sizeof(UnlitVertexUniforms));
	    uint32 fragmentUniformSize = (uint32)Math.Max(sizeof(LitFragmentUniforms), sizeof(UnlitFragmentUniforms));
	    
	    // Align to UNIFORM_ALIGNMENT
	    vertexUniformSize = (vertexUniformSize + UNIFORM_ALIGNMENT - 1) & ~(UNIFORM_ALIGNMENT - 1);
	    fragmentUniformSize = (fragmentUniformSize + UNIFORM_ALIGNMENT - 1) & ~(UNIFORM_ALIGNMENT - 1);
	    
	    // Create buffers large enough for all objects
	    var vertexBufferSize = vertexUniformSize * mMaxObjectCount;
	    var fragmentBufferSize = fragmentUniformSize * mMaxObjectCount;
	    
	    var vertexUniformDesc = SDL_GPUBufferCreateInfo()
	    {
	        usage = .SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ,
	        size = vertexBufferSize
	    };
	    mDynamicVertexUniformBuffer = SDL_CreateGPUBuffer(mRenderer.mDevice, &vertexUniformDesc);
	    
	    var fragmentUniformDesc = SDL_GPUBufferCreateInfo()
	    {
	        usage = .SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ,
	        size = fragmentBufferSize
	    };
	    mDynamicFragmentUniformBuffer = SDL_CreateGPUBuffer(mRenderer.mDevice, &fragmentUniformDesc);
	    
	    // Allocate staging memory
	    mVertexUniformStagingData = new uint8[vertexBufferSize]*;
	    mFragmentUniformStagingData = new uint8[fragmentBufferSize]*;
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

    protected override void OnUpdate(TimeSpan deltaTime)
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
            mViewMatrix = mActiveCamera.ViewMatrix;
            mProjectionMatrix = mActiveCamera.ProjectionMatrix;
            mViewProjectionMatrix = mViewMatrix * mProjectionMatrix;
        }
    }

    private void CollectRenderCommands()
    {
		uint32 uniformOffset = 0;

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
                    DistanceToCamera = 0,
					UniformOffset = uniformOffset
                };
                
                if (mActiveCamera != null)
                {
                    command.DistanceToCamera = Vector3.Distance(transform.Position, mActiveCameraTransform.Position);
                }
                
                mRenderCommands.Add(command);
				uniformOffset++;
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

		for (var command in mRenderCommands)
		{
			if(!mRendererMeshes.ContainsKey(command.Renderer))
			{
				mRendererMeshes[command.Renderer] = new GPUMesh(mRenderer.mDevice, command.Renderer.Mesh.Resource.Mesh);
			}
		}
        
        // Get swapchain texture
        SDL_GPUTexture* swapchainTexture = null;
        SDL_WaitAndAcquireGPUSwapchainTexture(commandBuffer, 
            (SDL_Window*)mRenderer.mPrimaryWindow.GetNativePointer("SDL"), 
            &swapchainTexture, null, null);

        if (swapchainTexture != null)
        {
            // Update all uniforms before starting render pass
            UpdateAllUniforms(commandBuffer);

            // Setup render targets
            var colorTarget = SDL_GPUColorTargetInfo()
            {
                texture = swapchainTexture,
                clear_color = .{ r = 0.1f, g = 0.2f, b = 0.3f, a = 1.0f },
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

            // Render all commands
            for (var command in mRenderCommands)
            {
                RenderObject(renderPass, command);
            }

            SDL_EndGPURenderPass(renderPass);
        }

        SDL_SubmitGPUCommandBuffer(commandBuffer);
    }

    private void UpdateAllUniforms(SDL_GPUCommandBuffer* commandBuffer)
    {
        if (mRenderCommands.Count == 0 || mActiveCamera == null)
		    return;

		// Calculate aligned sizes
		uint32 vertexUniformSize = (uint32)Math.Max(sizeof(LitVertexUniforms), sizeof(UnlitVertexUniforms));
		uint32 fragmentUniformSize = (uint32)Math.Max(sizeof(LitFragmentUniforms), sizeof(UnlitFragmentUniforms));

		vertexUniformSize = (vertexUniformSize + UNIFORM_ALIGNMENT - 1) & ~(UNIFORM_ALIGNMENT - 1);
		fragmentUniformSize = (fragmentUniformSize + UNIFORM_ALIGNMENT - 1) & ~(UNIFORM_ALIGNMENT - 1);

		// Update uniforms for each object
		for (int i = 0; i < mRenderCommands.Count; i++)
		{
		    var command = mRenderCommands[i];
		    uint32 vertexOffset = (uint32)i * vertexUniformSize;
		    uint32 fragmentOffset = (uint32)i * fragmentUniformSize;

		    if (command.Renderer.UseLighting)
		    {
		        // Update vertex uniforms
		        Matrix normalMatrix = command.WorldMatrix;
		        normalMatrix = Matrix.Invert(normalMatrix);
		        normalMatrix = Matrix.Transpose(normalMatrix);

		        var vertexUniforms = LitVertexUniforms()
		        {
		            ViewProjection = mViewProjectionMatrix,
		            World = command.WorldMatrix,
		            NormalMatrix = normalMatrix
		        };

		        // Copy to staging buffer
		        Internal.MemCpy(mVertexUniformStagingData + vertexOffset, &vertexUniforms, sizeof(LitVertexUniforms));

		        // Update fragment uniforms
		        var lightDir = mMainLight != null ? mMainLightTransform.Forward : Vector3(0, -1, 0);
		        var lightColor = mMainLight != null ? mMainLight.Color : Vector3(1, 1, 1);
		        var lightIntensity = mMainLight != null ? mMainLight.Intensity : 1.0f;

		        var fragmentUniforms = LitFragmentUniforms()
		        {
		            LightDirAndIntensity = Vector4(lightDir.X, lightDir.Y, lightDir.Z, lightIntensity),
		            LightColorPad = Vector4(lightColor.X, lightColor.Y, lightColor.Z, 0),
		            MaterialColor = command.Renderer.Color,
		            CameraPosAndPad = Vector4(mActiveCameraTransform.Position.X, 
		                mActiveCameraTransform.Position.Y, mActiveCameraTransform.Position.Z, 0)
		        };

		        // Copy to staging buffer
		        Internal.MemCpy(mFragmentUniformStagingData + fragmentOffset, &fragmentUniforms, sizeof(LitFragmentUniforms));
		    }
		    else
		    {
		        // Unlit rendering
		        var vertexUniforms = UnlitVertexUniforms()
		        {
		            ViewProjection = mViewProjectionMatrix,
		            World = command.WorldMatrix
		        };

		        var fragmentUniforms = UnlitFragmentUniforms()
		        {
		            MaterialColor = command.Renderer.Color
		        };

		        // Copy to staging buffers
		        Internal.MemCpy(mVertexUniformStagingData + vertexOffset, &vertexUniforms, sizeof(UnlitVertexUniforms));
		        Internal.MemCpy(mFragmentUniformStagingData + fragmentOffset, &fragmentUniforms, sizeof(UnlitFragmentUniforms));
		    }
		}

		// Upload all uniform data at once
		uint32 totalVertexSize = (uint32)mRenderCommands.Count * vertexUniformSize;
		uint32 totalFragmentSize = (uint32)mRenderCommands.Count * fragmentUniformSize;

		UploadUniforms(commandBuffer, mDynamicVertexUniformBuffer, mVertexUniformStagingData, totalVertexSize);
		UploadUniforms(commandBuffer, mDynamicFragmentUniformBuffer, mFragmentUniformStagingData, totalFragmentSize);
    }

    private void RenderObject(SDL_GPURenderPass* renderPass, RenderCommand command)
    {
		if(!mRendererMeshes.ContainsKey(command.Renderer))
			return;

		var mesh = mRendererMeshes[command.Renderer];

        // Get mesh data (using default cube for now)
        SDL_GPUBuffer* vertexBuffer = mesh.VertexBuffer;
        SDL_GPUBuffer* indexBuffer = mesh.IndexBuffer;
        uint32 indexCount = mesh.IndexCount;

        //mRenderer.GetDefaultMesh(out vertexBuffer, out indexBuffer, out indexCount);

        // Calculate uniform offsets
		uint32 vertexUniformSize = (uint32)Math.Max(sizeof(LitVertexUniforms), sizeof(UnlitVertexUniforms));
		uint32 fragmentUniformSize = (uint32)Math.Max(sizeof(LitFragmentUniforms), sizeof(UnlitFragmentUniforms));

		vertexUniformSize = (vertexUniformSize + UNIFORM_ALIGNMENT - 1) & ~(UNIFORM_ALIGNMENT - 1);
		fragmentUniformSize = (fragmentUniformSize + UNIFORM_ALIGNMENT - 1) & ~(UNIFORM_ALIGNMENT - 1);

		uint32 vertexOffset = command.UniformOffset * vertexUniformSize;
		uint32 fragmentOffset = command.UniformOffset * fragmentUniformSize;

        // Bind pipeline
        var pipeline = mRenderer.GetPipeline(command.Renderer.UseLighting);
        SDL_BindGPUGraphicsPipeline(renderPass, pipeline);

        // Bind vertex and index buffers
        var vertexBinding = SDL_GPUBufferBinding()
        {
            buffer = vertexBuffer,
            offset = 0
        };
        SDL_BindGPUVertexBuffers(renderPass, 0, &vertexBinding, 1);
        SDL_BindGPUIndexBuffer(renderPass, scope .() { buffer = indexBuffer, offset = 0 }, .SDL_GPU_INDEXELEMENTSIZE_32BIT);

        // Bind uniform buffers with dynamic offsets
		var vertexUniformBinding = SDL_GPUBufferBinding()
		{
		    buffer = mDynamicVertexUniformBuffer,
		    offset = vertexOffset
		};
		var fragmentUniformBinding = SDL_GPUBufferBinding()
		{
		    buffer = mDynamicFragmentUniformBuffer,
		    offset = fragmentOffset
		};

		SDL_BindGPUVertexStorageBuffers(renderPass, 0, &vertexUniformBinding.buffer, 1);
		SDL_BindGPUFragmentStorageBuffers(renderPass, 0, &fragmentUniformBinding.buffer, 1);

        // Draw
        SDL_DrawGPUIndexedPrimitives(renderPass, indexCount, 1, 0, 0, 0);
    }

    private void UploadUniforms(SDL_GPUCommandBuffer* commandBuffer, SDL_GPUBuffer* buffer, void* data, uint32 size)
    {
        // Create a transfer buffer
        var transferBuffer = SDL_CreateGPUTransferBuffer(mRenderer.mDevice, scope .()
        {
            size = size,
            usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD
        });

        // Map and copy data
        void* mappedData = SDL_MapGPUTransferBuffer(mRenderer.mDevice, transferBuffer, false);
        Internal.MemCpy(mappedData, data, size);
        SDL_UnmapGPUTransferBuffer(mRenderer.mDevice, transferBuffer);

        // Upload to GPU buffer
        var copyPass = SDL_BeginGPUCopyPass(commandBuffer);
        SDL_UploadToGPUBuffer(copyPass, scope .()
        {
            transfer_buffer = transferBuffer,
            offset = 0
        }, scope .()
        {
            buffer = buffer,
            offset = 0,
            size = size
        }, false);
        SDL_EndGPUCopyPass(copyPass);

        SDL_ReleaseGPUTransferBuffer(mRenderer.mDevice, transferBuffer);
    }
}