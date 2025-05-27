using Sedulous.Engine.Core.SceneGraph;
using System;
using SDL3Native;
using System.Collections;
using Sedulous.Foundation.Mathematics;
using Sedulous.Engine.Core.Resources;

namespace Sedulous.Engine.Renderer.SDL;

using internal Sedulous.Engine.Renderer.SDL;

// Components
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
			//mViewMatrix = mActiveCamera.GetViewMatrix(mActiveCameraTransform);
            mViewMatrix = mActiveCamera.ViewMatrix;
            //float aspectRatio = (float)mRenderer.Width / (float)mRenderer.Height;
			//mProjectionMatrix = mActiveCamera.GetProjectionMatrix(aspectRatio);
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
                RenderObject(commandBuffer, renderPass, command);
            }

            SDL_EndGPURenderPass(renderPass);
        }

        SDL_SubmitGPUCommandBuffer(commandBuffer);
    }

    private void RenderObject(SDL_GPUCommandBuffer* commandBuffer, SDL_GPURenderPass* renderPass, RenderCommand command)
    {
        // Get mesh data (using default cube for now)
        SDL_GPUBuffer* vertexBuffer;
        SDL_GPUBuffer* indexBuffer;
        uint32 indexCount;
        mRenderer.GetDefaultMesh(out vertexBuffer, out indexBuffer, out indexCount);

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

        // Draw
        SDL_DrawGPUIndexedPrimitives(renderPass, indexCount, 1, 0, 0, 0);
    }
}