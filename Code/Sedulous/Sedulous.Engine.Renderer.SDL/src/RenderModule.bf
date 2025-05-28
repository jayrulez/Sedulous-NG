using Sedulous.Engine.Core.SceneGraph;
using System;
using SDL3Native;
using System.Collections;
using Sedulous.Foundation.Mathematics;
using Sedulous.Resources;

namespace Sedulous.Engine.Renderer.SDL;

using internal Sedulous.Engine.Renderer.SDL;

// Components
class SpriteRenderer : Component
{
    private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<SpriteRenderer>();
    public override ComponentTypeId TypeId => sTypeId;
    
    public ResourceHandle<Texture> Texture { get; set; }
    public Color Color { get; set; } = .White;
}

class MeshRenderer : Component
{
    private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<MeshRenderer>();
    public override ComponentTypeId TypeId => sTypeId;
	
	public ResourceHandle<Mesh> Mesh { get; set; }
	public ResourceHandle<Material> Material { get; set; }

    public bool UseLighting = true;
    public Vector4 Color = .(1, 1, 1, 1);
}

class Camera : Component
{
    private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<Camera>();
    public override ComponentTypeId TypeId => sTypeId;

    public float FieldOfView = 60.0f;
    public float AspectRatio { get; set; } = 16.0f / 9.0f;
    public float NearPlane = 0.1f;
    public float FarPlane = 1000.0f;
    

	public Matrix ViewMatrix => CalculateViewMatrix();
	public Matrix ProjectionMatrix => CalculateProjectionMatrix();

	private Matrix CalculateViewMatrix()
	{
	    return Matrix.CreateLookAt(
	        Entity.Transform.Position,
	        Entity.Transform.Position + Entity.Transform.Forward,
	        Entity.Transform.Up
	    );
	}

	private Matrix CalculateProjectionMatrix()
	{
	    return Matrix.CreatePerspectiveFieldOfView(
	        Radians.FromDegrees(FieldOfView),
	        AspectRatio,
	        NearPlane,
	        FarPlane
	    );
	}
}

class Light : Component
{
    private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<Light>();
    public override ComponentTypeId TypeId => sTypeId;

    public enum LightType
    {
        Directional,
        Point,
        Spot
    }
    
    public LightType Type = .Directional;
    public Vector3 Color = .(1, 1, 1);
    public float Intensity = 1.0f;
}

// Render data structures
struct RenderCommand
{
    public Entity Entity;
    public Matrix WorldMatrix;
    public MeshRenderer Renderer;
    public float DistanceToCamera;
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

    public this(SDLRendererSubsystem renderer)
    {
        mRenderer = renderer;
        CreateDepthBuffer();
    }

    public ~this()
    {
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

    private void RenderFrame()
    {
        var commandBuffer = SDL_AcquireGPUCommandBuffer(mRenderer.mDevice);
        
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

        // For now, just update with the first object's data
        // In a real system, you'd batch updates or use dynamic offsets
        var firstCommand = mRenderCommands[0];

        // Get uniform buffers
        SDL_GPUBuffer* vertexUniformBuffer;
        SDL_GPUBuffer* fragmentUniformBuffer;
        mRenderer.GetUniformBuffers(out vertexUniformBuffer, out fragmentUniformBuffer);

        if (firstCommand.Renderer.UseLighting)
        {
            // Update vertex uniforms
            Matrix normalMatrix = firstCommand.WorldMatrix;
            normalMatrix = Matrix.Invert(normalMatrix);
            normalMatrix = Matrix.Transpose(normalMatrix);

            var vertexUniforms = LitVertexUniforms()
            {
                ViewProjection = mViewProjectionMatrix,
                World = firstCommand.WorldMatrix,
                NormalMatrix = normalMatrix
            };

            // Update fragment uniforms
            var lightDir = mMainLight != null ? mMainLightTransform.Forward : Vector3(0, -1, 0);
            var lightColor = mMainLight != null ? mMainLight.Color : Vector3(1, 1, 1);
            var lightIntensity = mMainLight != null ? mMainLight.Intensity : 1.0f;

            var fragmentUniforms = LitFragmentUniforms()
            {
                LightDirAndIntensity = Vector4(lightDir.X, lightDir.Y, lightDir.Z, lightIntensity),
                LightColorPad = Vector4(lightColor.X, lightColor.Y, lightColor.Z, 0),
                MaterialColor = firstCommand.Renderer.Color,
                CameraPosAndPad = Vector4(mActiveCameraTransform.Position.X, mActiveCameraTransform.Position.Y, mActiveCameraTransform.Position.Z, 0)
            };

            // Upload uniforms
            UploadUniforms(commandBuffer, vertexUniformBuffer, &vertexUniforms, sizeof(LitVertexUniforms));
            UploadUniforms(commandBuffer, fragmentUniformBuffer, &fragmentUniforms, sizeof(LitFragmentUniforms));
        }
        else
        {
            // Unlit rendering
            var vertexUniforms = UnlitVertexUniforms()
            {
                ViewProjection = mViewProjectionMatrix,
                World = firstCommand.WorldMatrix
            };

            var fragmentUniforms = UnlitFragmentUniforms()
            {
                MaterialColor = firstCommand.Renderer.Color
            };

            // Upload uniforms
            UploadUniforms(commandBuffer, vertexUniformBuffer, &vertexUniforms, sizeof(UnlitVertexUniforms));
            UploadUniforms(commandBuffer, fragmentUniformBuffer, &fragmentUniforms, sizeof(UnlitFragmentUniforms));
        }
    }

    private void RenderObject(SDL_GPURenderPass* renderPass, RenderCommand command)
    {
        // Get mesh data (using default cube for now)
        SDL_GPUBuffer* vertexBuffer;
        SDL_GPUBuffer* indexBuffer;
        uint32 indexCount;
        mRenderer.GetDefaultMesh(out vertexBuffer, out indexBuffer, out indexCount);

        // Get uniform buffers
        SDL_GPUBuffer* vertexUniformBuffer;
        SDL_GPUBuffer* fragmentUniformBuffer;
        mRenderer.GetUniformBuffers(out vertexUniformBuffer, out fragmentUniformBuffer);

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

        // Bind uniform buffers
        SDL_BindGPUVertexStorageBuffers(renderPass, 0, &vertexUniformBuffer, 1);
        SDL_BindGPUFragmentStorageBuffers(renderPass, 0, &fragmentUniformBuffer, 1);

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