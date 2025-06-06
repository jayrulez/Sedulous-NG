using System;
using System.Collections;
using Sedulous.Resources;
using Sedulous.Geometry;
using Sedulous.Engine.Renderer;
using SDL3Native;

namespace Sedulous.Engine.Renderer.SDL;

// Simplified GPU Resource Manager - relies on reference counting
class GPUResourceManager
{
    private SDL_GPUDevice* mDevice;
    
    // Resource caches - resources are automatically cleaned up when ref count hits 0
    private Dictionary<MeshResource, GPUMesh> mMeshCache = new .() ~ delete _;
    private Dictionary<TextureResource, GPUTexture> mTextureCache = new .() ~ delete _;
    private Dictionary<MaterialResource, GPUMaterial> mMaterialCache = new .() ~ delete _;
    
    // Statistics
    public int TotalMeshes => mMeshCache.Count;
    public int TotalTextures => mTextureCache.Count;
    public int TotalMaterials => mMaterialCache.Count;
    
    public this(SDL_GPUDevice* device)
    {
        mDevice = device;
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
            mDevice, 
            meshResource.Mesh
        );
        
        // Cache the raw pointer
        mMeshCache[meshResource] = gpuMesh;
        
        SDL_Log("Created GPU Mesh: %s (Total: %d)", meshResource.Name.Ptr, mMeshCache.Count);
        
        // Return a handle (this adds the first ref)
        return GPUResourceHandle<GPUMesh>(gpuMesh);
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
            mDevice, 
            textureResource
        );
        
        // Cache the raw object
        mTextureCache[textureResource] = gpuTexture;
        
        SDL_Log("Created GPU Texture: %s (Total: %d)", textureResource.Name.Ptr, mTextureCache.Count);
        
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
            mDevice, 
            materialResource.Material, 
            materialTextureCache
        );
        
        // Cache the raw pointer
        mMaterialCache[materialResource] = gpuMaterial;
        
        SDL_Log("Created GPU Material: %s (Total: %d)", materialResource.Name.Ptr, mMaterialCache.Count);
        
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
            SDL_Log("Cleaned %d dead cache entries", removedCount);
        }
    }
}