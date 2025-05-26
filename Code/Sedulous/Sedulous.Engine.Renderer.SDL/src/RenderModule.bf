using Sedulous.Engine.Core.SceneGraph;
using System;
using SDL3Native;
using System.Collections;
using Sedulous.Foundation.Mathematics;
namespace Sedulous.Engine.Renderer.SDL;

using internal Sedulous.Engine.Renderer.SDL;

class RenderModule : SceneModule
{
    public override StringView Name => "Render";

    private SDLRendererSubsystem mRenderer;
    private List<RenderCommand> mOpaqueCommands = new .() ~ delete _;
    private List<RenderCommand> mTransparentCommands = new .() ~ delete _;
    private Dictionary<Mesh, GPUMesh> mMeshCache = new .() ~ delete _;
    private Dictionary<Texture, GPUTexture> mTextureCache = new .() ~ delete _;
    private CameraData mCurrentCamera;

    public this(SDLRendererSubsystem renderer)
    {
        mRenderer = renderer;
    }

    public ~this()
    {
        // Cleanup GPU resources
        for (var gpuMesh in mMeshCache.Values)
        {
            SDL_ReleaseGPUBuffer(mRenderer.mDevice, gpuMesh.VertexBuffer);
            SDL_ReleaseGPUBuffer(mRenderer.mDevice, gpuMesh.IndexBuffer);
            delete gpuMesh;
        }
        
        for (var gpuTexture in mTextureCache.Values)
        {
            SDL_ReleaseGPUTexture(mRenderer.mDevice, gpuTexture.Texture);
            SDL_ReleaseGPUSampler(mRenderer.mDevice, gpuTexture.Sampler);
            delete gpuTexture;
        }
    }

    protected override void RegisterComponentInterests()
    {
        RegisterComponentInterest<MeshRenderer>();
        RegisterComponentInterest<Camera>();
    }

    protected override bool ShouldTrackEntity(Entity entity)
    {
        return entity.HasComponent<MeshRenderer>() || entity.HasComponent<Camera>();
    }

    protected override void Update(TimeSpan deltaTime)
    {
        // Find active camera
        UpdateActiveCamera();
        
        // Clear previous frame commands
        mOpaqueCommands.Clear();
        mTransparentCommands.Clear();
        
        // Collect render commands from all renderable entities
        CollectRenderCommands();
        
        // Sort commands for optimal rendering
        SortRenderCommands();
    }

    private void UpdateActiveCamera()
    {
        // Find camera entity
        Entity cameraEntity = null;
        for (var entity in TrackedEntities)
        {
            if (entity.HasComponent<Camera>())
            {
                cameraEntity = entity;
                break;
            }
        }
        
        if (cameraEntity != null)
        {
            var camera = cameraEntity.GetComponent<Camera>();
            var transform = cameraEntity.Transform;
            
            mCurrentCamera.ViewMatrix = camera.ViewMatrix;
            mCurrentCamera.ProjectionMatrix = camera.ProjectionMatrix;
            mCurrentCamera.ViewProjectionMatrix = mCurrentCamera.ViewMatrix * mCurrentCamera.ProjectionMatrix;
            mCurrentCamera.Position = transform.Position;
            mCurrentCamera.Forward = transform.Forward;
        }
    }

    private void CollectRenderCommands()
    {
        for (var entity in TrackedEntities)
        {
            var meshRenderer = entity.GetComponent<MeshRenderer>();
            if (meshRenderer != null && 
                meshRenderer.Mesh.IsValid && 
                meshRenderer.Material.IsValid)
            {
                var command = RenderCommand()
                {
                    Entity = entity,
                    Mesh = meshRenderer.Mesh.Resource,
                    Material = meshRenderer.Material.Resource,
                    WorldMatrix = entity.Transform.WorldMatrix,
                    DistanceToCamera = Vector3.Distance(entity.Transform.Position, mCurrentCamera.Position),
                    IsTransparent = IsTransparent(meshRenderer.Material.Resource)
                };
                
                if (command.IsTransparent)
                {
                    mTransparentCommands.Add(command);
                }
                else
                {
                    mOpaqueCommands.Add(command);
                }
            }
        }
    }

    private void SortRenderCommands()
    {
        // Sort opaque objects front-to-back (for early Z rejection)
        mOpaqueCommands.Sort(scope (lhs, rhs) => {
            return lhs.DistanceToCamera.CompareTo(rhs.DistanceToCamera);
        });
        
        // Sort transparent objects back-to-front (for correct blending)
        mTransparentCommands.Sort(scope (lhs, rhs) => {
            return rhs.DistanceToCamera.CompareTo(lhs.DistanceToCamera);
        });
    }

    private bool IsTransparent(Material material)
    {
        // Check if material has transparency
        return material.Properties.AlbedoColor.W < 1.0f ||
               material.ShaderName.Contains("Transparent");
    }

    public void Render(SDL_GPUCommandBuffer* commandBuffer, SDL_GPUTexture* renderTarget)
    {
        // Update camera uniform buffer
        UpdateCameraUniforms();
        
        // Begin render pass
        var colorTarget = SDL_GPUColorTargetInfo()
        {
            texture = renderTarget,
            clear_color = .{ r = 0.2f, g = 0.3f, b = 0.4f, a = 1.0f },
            load_op = .SDL_GPU_LOADOP_CLEAR,
            store_op = .SDL_GPU_STOREOP_STORE
        };
        
        var renderPass = SDL_BeginGPURenderPass(commandBuffer, &colorTarget, 1, null);
        
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
        
        // Render opaque objects
        RenderCommands(renderPass, mOpaqueCommands, false);
        
        // Render transparent objects
        RenderCommands(renderPass, mTransparentCommands, true);
        
        SDL_EndGPURenderPass(renderPass);
    }

    private void RenderCommands(SDL_GPURenderPass* renderPass, List<RenderCommand> commands, bool enableBlending)
    {
        Material currentMaterial = null;
        Mesh currentMesh = null;
        
        for (var command in commands)
        {
            // Bind material if changed
            if (currentMaterial != command.Material)
            {
                BindMaterial(renderPass, command.Material, enableBlending);
                currentMaterial = command.Material;
            }
            
            // Bind mesh if changed
            if (currentMesh != command.Mesh)
            {
                BindMesh(renderPass, command.Mesh);
                currentMesh = command.Mesh;
            }
            
            // Update per-object uniforms (world matrix)
            UpdateObjectUniforms(command.WorldMatrix);
            
            // Draw
            var gpuMesh = GetOrCreateGPUMesh(command.Mesh);
            SDL_DrawGPUIndexedPrimitives(renderPass, gpuMesh.IndexCount, 1, 0, 0, 0);
        }
    }

    private void BindMaterial(SDL_GPURenderPass* renderPass, Material material, bool enableBlending)
    {
        // Bind shader pipeline
        var pipeline = mRenderer.GetMaterialPipeline(material, enableBlending);
        SDL_BindGPUGraphicsPipeline(renderPass, pipeline);
        
        // Bind textures
        if (material.AlbedoTexture.IsValid)
        {
            var gpuTexture = GetOrCreateGPUTexture(material.AlbedoTexture.Resource);
            var textureBinding = SDL_GPUTextureSamplerBinding()
            {
                texture = gpuTexture.Texture,
                sampler = gpuTexture.Sampler
            };
            SDL_BindGPUFragmentSamplers(renderPass, 0, &textureBinding, 1);
        }
        
        // Update material uniform buffer
        UpdateMaterialUniforms(material);
    }

    private void BindMesh(SDL_GPURenderPass* renderPass, Mesh mesh)
    {
        var gpuMesh = GetOrCreateGPUMesh(mesh);
        
        var vertexBinding = SDL_GPUBufferBinding()
        {
            buffer = gpuMesh.VertexBuffer,
            offset = 0
        };
        
        SDL_BindGPUVertexBuffers(renderPass, 0, &vertexBinding, 1);
        SDL_BindGPUIndexBuffer(renderPass, scope .(){ buffer = gpuMesh.IndexBuffer, offset = 0 }, .SDL_GPU_INDEXELEMENTSIZE_32BIT);
    }

    private GPUMesh GetOrCreateGPUMesh(Mesh mesh)
    {
        if (!mMeshCache.TryGetValue(mesh, var gpuMesh))
        {
            gpuMesh = new GPUMesh(mRenderer.mDevice, mesh);
            mMeshCache[mesh] = gpuMesh;
        }
        return gpuMesh;
    }

    private GPUTexture GetOrCreateGPUTexture(Texture texture)
    {
        if (!mTextureCache.TryGetValue(texture, var gpuTexture))
        {
            gpuTexture = new GPUTexture(mRenderer.mDevice, texture);
            mTextureCache[texture] = gpuTexture;
        }
        return gpuTexture;
    }

    private void UpdateCameraUniforms()
    {
    }

    private void UpdateMaterialUniforms(Material material)
    {
    }

    private void UpdateObjectUniforms(Matrix worldMatrix)
    {
    }
}