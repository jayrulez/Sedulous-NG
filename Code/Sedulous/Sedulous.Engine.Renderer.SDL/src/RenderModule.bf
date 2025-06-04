using Sedulous.SceneGraph;
using System;
using SDL3Native;
using System.Collections;
using Sedulous.Mathematics;
using Sedulous.Resources;
using Sedulous.SceneGraph;
using Sedulous.Utilities;
using Sedulous.Geometry;
using Sedulous.Engine.Renderer.SDL;

namespace Sedulous.Engine.Renderer.SDL;

using internal Sedulous.Engine.Renderer.SDL;

class RenderModule : SceneModule
{
    public override StringView Name => "Render";

    private SDLRendererSubsystem mRenderer;

    // 3D rendering
	private List<MeshRenderCommand> mMeshCommands = new .() ~ delete _;
    private Dictionary<MeshRenderer, GPUMesh> mRendererMeshes = new .() ~ delete _;
    private Dictionary<MaterialResource, GPUMaterial> mMaterialCache = new .() ~ delete _;

    // Sprite rendering
    private List<SpriteRenderCommand> mSpriteCommands = new .() ~ delete _;
    private Dictionary<TextureResource, GPUResourceHandle<GPUTexture>> mTextureCache = new .() ~ delete _;
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
            entry.value.Release();
        }
        
        for (var entry in mMaterialCache)
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
        // Create GPU meshes for any new mesh renderers
		for (var command in mMeshCommands)
        {
            if (!mRendererMeshes.ContainsKey(command.Renderer))
            {
                mRendererMeshes[command.Renderer] = new GPUMesh(mRenderer.mDevice, command.Renderer.Mesh.Resource.Mesh);
            }
            
            // Create GPU materials
            if (command.Renderer.Material.IsValid && command.Renderer.Material.Resource != null)
            {
                var materialResource = command.Renderer.Material.Resource;
                if (!mMaterialCache.ContainsKey(materialResource))
                {
                    // First ensure all textures used by the material are in GPU cache
                    var textureList = scope List<ResourceHandle<TextureResource>>();
                    materialResource.Material.GetTextureResources(textureList);
                    
                    for (var textureHandle in textureList)
                    {
                        if (textureHandle.IsValid && textureHandle.Resource != null)
                        {
                            var textureResource = textureHandle.Resource;
                            if (!mTextureCache.ContainsKey(textureResource))
                            {
                                mTextureCache[textureResource] = GPUResourceHandle<GPUTexture>(new GPUTexture(mRenderer.mDevice, textureResource));
                            }
                        }
                    }
                    
                    // Now create the GPU material with texture cache
                    mMaterialCache[materialResource] = new GPUMaterial(mRenderer.mDevice, materialResource.Material, mTextureCache);
                }
            }
        }

        // Create GPU textures for any new sprite textures
        for (var command in mSpriteCommands)
        {
            var textureResource = command.Renderer.Texture.Resource;
            if (!mTextureCache.ContainsKey(textureResource))
            {
                mTextureCache[textureResource] = GPUResourceHandle<GPUTexture>(new GPUTexture(mRenderer.mDevice, textureResource));
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
            load_op = .SDL_GPU_LOADOP_LOAD,  // Don't clear
            store_op = .SDL_GPU_STOREOP_STORE
        };
        
        // Use depth buffer for testing but not writing (sprites respect depth but don't write to it)
        var depthTarget = SDL_GPUDepthStencilTargetInfo()
        {
            texture = mDepthTexture,
            load_op = .SDL_GPU_LOADOP_DONT_CARE,  // Don't load when cycling
            store_op = .SDL_GPU_STOREOP_DONT_CARE,
            stencil_load_op = .SDL_GPU_LOADOP_DONT_CARE,
            stencil_store_op = .SDL_GPU_STOREOP_DONT_CARE,
            cycle = true  // Read-only depth
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
        if (!mRendererMeshes.ContainsKey(command.Renderer))
            return;

        var mesh = mRendererMeshes[command.Renderer];

        // Get mesh data
        SDL_GPUBuffer* vertexBuffer = mesh.VertexBuffer;
        SDL_GPUBuffer* indexBuffer = mesh.IndexBuffer;
        uint32 indexCount = mesh.IndexCount;

        // Determine if we should use lit or unlit pipeline
        bool useLit = true;
        GPUMaterial gpuMaterial = null;
        
        if (command.Renderer.Material.IsValid && command.Renderer.Material.Resource != null)
        {
            var materialResource = command.Renderer.Material.Resource;
            if (mMaterialCache.TryGetValue(materialResource, let material))
            {
                gpuMaterial = material;
                // Use unlit pipeline if material's shader is "Unlit"
                useLit = material.ShaderName != "Unlit";
            }
        }

        // Bind pipeline
        var pipeline = mRenderer.GetPipeline(useLit);
        SDL_BindGPUGraphicsPipeline(renderPass, pipeline);

        // Bind vertex and index buffers
        var vertexBinding = SDL_GPUBufferBinding()
        {
            buffer = vertexBuffer,
            offset = 0
        };
        SDL_BindGPUVertexBuffers(renderPass, 0, &vertexBinding, 1);
        SDL_BindGPUIndexBuffer(renderPass, scope .() { buffer = indexBuffer, offset = 0 }, .SDL_GPU_INDEXELEMENTSIZE_32BIT);

        // Bind textures if we have a material
        if (gpuMaterial != null)
        {
            gpuMaterial.BindTextures(renderPass);
        }
        else if (useLit)
        {
            // For lit without material textures, bind default white texture
            var defaultWhite = mRenderer.GetDefaultWhiteTexture();
            var textureSamplerBinding = SDL_GPUTextureSamplerBinding()
            {
                texture = defaultWhite.Resource.Texture,
                sampler = defaultWhite.Resource.Sampler
            };
            SDL_BindGPUFragmentSamplers(renderPass, 0, &textureSamplerBinding, 1);
        }
        else if (!useLit)
        {
            // For unlit without material, bind a white texture
            var defaultWhite = mRenderer.GetDefaultWhiteTexture();
            var textureSamplerBinding = SDL_GPUTextureSamplerBinding()
            {
                texture = defaultWhite.Resource.Texture,
                sampler = defaultWhite.Resource.Sampler
            };
            SDL_BindGPUFragmentSamplers(renderPass, 0, &textureSamplerBinding, 1);
        }

        // Push uniform data for this object
        if (mActiveCamera != null)
        {
            if (useLit)
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

                var fragmentUniforms = LitFragmentUniforms()
                {
                    LightDirAndIntensity = Vector4(lightDir.X, lightDir.Y, lightDir.Z, lightIntensity),
                    LightColorPad = Vector4(lightColor.X, lightColor.Y, lightColor.Z, 0),
                    MaterialColor = materialColor,
                    CameraPosAndPad = Vector4(mActiveCameraTransform.Position.X, mActiveCameraTransform.Position.Y, mActiveCameraTransform.Position.Z, 0),
                    SpecularColorShininess = specularColor,
                    AmbientColor = ambientColor
                };

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
        var gpuTexture = mTextureCache[command.Renderer.Texture.Resource];
        if (!gpuTexture.IsValid)
            return;
            
        // Get sprite pipeline
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
                    0, 0, 0, 0,  // No forward vector needed for billboard
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
                        0, spriteSize.Y, 0, 0,  // Keep Y-up
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