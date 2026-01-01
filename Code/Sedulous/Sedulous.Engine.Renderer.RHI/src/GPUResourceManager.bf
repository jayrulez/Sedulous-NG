using System;
using System.Collections;
using Sedulous.Resources;
using Sedulous.Geometry;
using Sedulous.Engine.Renderer;
using Sedulous.Engine.Renderer.GPU;
using Sedulous.RHI;

namespace Sedulous.Engine.Renderer.RHI;

using static Sedulous.RHI.ExtensionMethods;

// GPU Resource Manager - relies on reference counting
class GPUResourceManager
{
    private GraphicsContext mGraphicsContext;
    
    // Resource caches - resources are automatically cleaned up when ref count hits 0
    private Dictionary<MeshResource, GPUMesh> mMeshCache = new .() ~ delete _;
    private Dictionary<SkinnedMeshResource, GPUSkinnedMesh> mSkinnedMeshCache = new .() ~ delete _;
    private Dictionary<TextureResource, GPUTexture> mTextureCache = new .() ~ delete _;
    private Dictionary<MaterialResource, GPUMaterial> mMaterialCache = new .() ~ delete _;

    // Statistics
    public int TotalMeshes => mMeshCache.Count;
    public int TotalSkinnedMeshes => mSkinnedMeshCache.Count;
    public int TotalTextures => mTextureCache.Count;
    public int TotalMaterials => mMaterialCache.Count;

    /// Calculate total GPU memory used by all cached resources (in bytes)
    public uint64 TotalGPUMemory
    {
        get
        {
            uint64 total = 0;

            // Mesh buffers
            for (var (_, mesh) in mMeshCache)
            {
                if (mesh.RefCount > 0)
                {
                    if (mesh.VertexBuffer != null)
                        total += mesh.VertexBuffer.Description.SizeInBytes;
                    if (mesh.IndexBuffer != null)
                        total += mesh.IndexBuffer.Description.SizeInBytes;
                }
            }

            // Skinned mesh buffers
            for (var (_, mesh) in mSkinnedMeshCache)
            {
                if (mesh.RefCount > 0)
                {
                    if (mesh.VertexBuffer != null)
                        total += mesh.VertexBuffer.Description.SizeInBytes;
                    if (mesh.IndexBuffer != null)
                        total += mesh.IndexBuffer.Description.SizeInBytes;
                }
            }

            // Textures
            for (var (_, texture) in mTextureCache)
            {
                if (texture.RefCount > 0 && texture.Texture != null)
                {
                    var desc = texture.Texture.Description;
                    total += CalculateTextureMemory(desc);
                }
            }

            return total;
        }
    }

    private static uint64 CalculateTextureMemory(TextureDescription desc)
    {
        // Use existing GetSizeInBits extension method and convert to bytes
        uint64 bitsPerPixel = desc.Format.GetSizeInBits();
        uint64 bytesPerPixel = (bitsPerPixel + 7) / 8; // Round up to nearest byte
        uint64 baseSize = (uint64)desc.Width * desc.Height * desc.Depth * bytesPerPixel * desc.ArraySize;

        // Account for mipmaps (approximately 1.33x base size)
        if (desc.MipLevels > 1)
            baseSize = (baseSize * 4) / 3;

        return baseSize;
    }
    
    public this(GraphicsContext context)
    {
        mGraphicsContext = context;
    }
    
    // Get or create GPU mesh - returns a new handle (adds ref)
    public GPUResourceHandle<GPUMesh> GetOrCreateMesh(MeshResource meshResource)
    {
        if (meshResource == null || meshResource.Mesh == null)
            return default;
        
        // Check if we have it cached
        if (mMeshCache.TryGetValue(meshResource, let existingMesh))
        {
            // If it still has refs, return a new handle
            if (existingMesh.RefCount > 0)
            {
                return GPUResourceHandle<GPUMesh>(existingMesh);
            }
            else
            {
                // Resource was released, remove from cache
                mMeshCache.Remove(meshResource);
            }
        }
        
        // Create new GPU mesh
        var gpuMesh = new GPUMesh(
            scope $"Mesh_{meshResource.Name}_{meshResource.Id}", 
            mGraphicsContext, 
            meshResource.Mesh
        );
        
        // Cache the raw pointer
        mMeshCache[meshResource] = gpuMesh;
        
        mGraphicsContext.Logger.LogInformation("Created GPU Mesh: {} (Total: {})", meshResource.Name, mMeshCache.Count);
        
        // Return a handle (this adds the first ref)
        return GPUResourceHandle<GPUMesh>(gpuMesh);
    }

    // Get or create GPU skinned mesh - returns a new handle (adds ref)
    public GPUResourceHandle<GPUSkinnedMesh> GetOrCreateSkinnedMesh(SkinnedMeshResource meshResource)
    {
        if (meshResource == null || meshResource.Mesh == null)
            return default;

        // Check if we have it cached
        if (mSkinnedMeshCache.TryGetValue(meshResource, let existingMesh))
        {
            // If it still has refs, return a new handle
            if (existingMesh.RefCount > 0)
            {
                return GPUResourceHandle<GPUSkinnedMesh>(existingMesh);
            }
            else
            {
                // Resource was released, remove from cache
                mSkinnedMeshCache.Remove(meshResource);
            }
        }

        // Create new GPU skinned mesh
        var gpuMesh = new GPUSkinnedMesh(
            scope $"SkinnedMesh_{meshResource.Id}",
            mGraphicsContext,
            meshResource.Mesh
        );

        // Cache the raw pointer
        mSkinnedMeshCache[meshResource] = gpuMesh;

        mGraphicsContext.Logger.LogInformation("Created GPU Skinned Mesh (Total: {})", mSkinnedMeshCache.Count);

        // Return a handle (this adds the first ref)
        return GPUResourceHandle<GPUSkinnedMesh>(gpuMesh);
    }

    // Get or create GPU texture - returns a new handle (adds ref)
    public GPUResourceHandle<GPUTexture> GetOrCreateTexture(TextureResource textureResource)
    {
        if (textureResource == null || textureResource.Image == null)
            return default;
        
        // Check if we have it cached
        if (mTextureCache.TryGetValue(textureResource, let existingTexture))
        {
            // If it still has refs, return a new handle
            if (existingTexture.RefCount > 0)
            {
                return GPUResourceHandle<GPUTexture>(existingTexture);
            }
            else
            {
                // Resource was released, remove from cache
                mTextureCache.Remove(textureResource);
            }
        }
        
        // Create new GPU texture
        var gpuTexture = new GPUTexture(
            scope $"Texture_{textureResource.Name}_{textureResource.Id}", 
            mGraphicsContext, 
            textureResource
        );
        
        // Cache the raw object
        mTextureCache[textureResource] = gpuTexture;
        
        mGraphicsContext.Logger.LogInformation("Created GPU Texture: {} (Total: {})", textureResource.Name, mTextureCache.Count);
        
        // Return a handle (this adds the first ref)
        return GPUResourceHandle<GPUTexture>(gpuTexture);
    }
    
    // Get or create GPU material - returns a new handle (adds ref)
    public GPUResourceHandle<GPUMaterial> GetOrCreateMaterial(MaterialResource materialResource)
    {
        if (materialResource == null || materialResource.Material == null)
            return default;

        // Check if we have it cached
        if (mMaterialCache.TryGetValue(materialResource, let existingMaterial))
        {
            // If it still has refs, return a new handle
            if (existingMaterial.RefCount > 0)
            {
                return GPUResourceHandle<GPUMaterial>(existingMaterial);
            }
            else
            {
                // Resource was released, remove from cache
                mMaterialCache.Remove(materialResource);
            }
        }

        // First ensure all textures used by the material are loaded
        var textureList = scope List<ResourceHandle<TextureResource>>();
        materialResource.Material.GetTextureResources(textureList);

        // Build texture cache for material creation
        var materialTextureCache = scope Dictionary<TextureResource, GPUResourceHandle<GPUTexture>>();

        for (var textureHandle in textureList)
        {
            if (textureHandle.IsValid && textureHandle.Resource != null)
            {
                // Get or create the texture
                var gpuTextureHandle = GetOrCreateTexture(textureHandle.Resource);
                if (gpuTextureHandle.IsValid)
                {
                    materialTextureCache[textureHandle.Resource] = gpuTextureHandle;
                }
            }
        }

        // Create GPU material with texture handles
        var gpuMaterial = new GPUMaterial(
            scope $"Material_{materialResource.Name}_{materialResource.Id}",
            mGraphicsContext,
            materialResource.Material,
            materialTextureCache
        );

        // Cache the raw pointer
        mMaterialCache[materialResource] = gpuMaterial;

        mGraphicsContext.Logger.LogInformation("Created GPU Material: {} (Total: {})", materialResource.Name, mMaterialCache.Count);

        // Return a handle (this adds the first ref)
        return GPUResourceHandle<GPUMaterial>(gpuMaterial);
    }
    
    // Clean up entries with zero refs (optional - could be called periodically)
    public void CleanupDeadEntries()
    {
        int removedCount = 0;
        
        // Clean mesh cache
        var meshesToRemove = scope List<MeshResource>();
        for (var (resource, mesh) in mMeshCache)
        {
            if (mesh.RefCount == 0)
                meshesToRemove.Add(resource);
        }
        
        for (var resource in meshesToRemove)
        {
            mMeshCache.Remove(resource);
            removedCount++;
        }
        
        // Clean skinned mesh cache
        var skinnedMeshesToRemove = scope List<SkinnedMeshResource>();
        for (var (resource, mesh) in mSkinnedMeshCache)
        {
            if (mesh.RefCount == 0)
                skinnedMeshesToRemove.Add(resource);
        }

        for (var resource in skinnedMeshesToRemove)
        {
            mSkinnedMeshCache.Remove(resource);
            removedCount++;
        }

        // Clean texture cache
        var texturesToRemove = scope List<TextureResource>();
        for (var (resource, texture) in mTextureCache)
        {
            if (texture.RefCount == 0)
                texturesToRemove.Add(resource);
        }

        for (var resource in texturesToRemove)
        {
            mTextureCache.Remove(resource);
            removedCount++;
        }
        
        // Clean material cache
        var materialsToRemove = scope List<MaterialResource>();
        for (var (resource, material) in mMaterialCache)
        {
            if (material.RefCount == 0)
                materialsToRemove.Add(resource);
        }
        
        for (var resource in materialsToRemove)
        {
            mMaterialCache.Remove(resource);
            removedCount++;
        }
        
        if (removedCount > 0)
        {
            mGraphicsContext.Logger.LogInformation("Cleaned {} dead cache entries", removedCount);
        }
    }
}