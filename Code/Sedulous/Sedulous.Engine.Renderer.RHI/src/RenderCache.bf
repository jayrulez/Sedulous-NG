using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Engine.Renderer.GPU;

namespace Sedulous.Engine.Renderer.RHI;

/// Consolidated cache for GPU resources used during rendering.
/// Manages the mapping from CPU-side components to GPU resources.
class RenderCache
{
	private RHIRendererSubsystem mRenderer;
	private GPUResourceManager mResourceManager;

	// Mesh renderer caches
	private Dictionary<MeshRenderer, GPUResourceHandle<GPUMesh>> mMeshes = new .() ~ delete _;
	private Dictionary<MeshRenderer, GPUResourceHandle<GPUMaterial>> mMeshMaterials = new .() ~ delete _;

	// Skinned mesh renderer caches
	private Dictionary<SkinnedMeshRenderer, GPUResourceHandle<GPUSkinnedMesh>> mSkinnedMeshes = new .() ~ delete _;
	private Dictionary<SkinnedMeshRenderer, GPUResourceHandle<GPUMaterial>> mSkinnedMaterials = new .() ~ delete _;

	// Animation caches
	private Dictionary<Animator, GPUSkeleton> mSkeletons = new .() ~ delete _;
	private Dictionary<Animator, ResourceSet> mBoneResourceSets = new .() ~ delete _;

	// Material resource set cache
	private Dictionary<GPUMaterial, ResourceSet> mMaterialResourceSets = new .() ~ delete _;

	public this(RHIRendererSubsystem renderer, GPUResourceManager resourceManager)
	{
		mRenderer = renderer;
		mResourceManager = resourceManager;
	}

	public ~this()
	{
		Clear();
	}

	/// Clear all cached resources
	public void Clear()
	{
		// Release mesh handles
		for (var entry in mMeshes)
			entry.value.Release();
		mMeshes.Clear();

		// Release mesh material handles
		for (var entry in mMeshMaterials)
			entry.value.Release();
		mMeshMaterials.Clear();

		// Release skinned mesh handles
		for (var entry in mSkinnedMeshes)
			entry.value.Release();
		mSkinnedMeshes.Clear();

		// Release skinned material handles
		for (var entry in mSkinnedMaterials)
			entry.value.Release();
		mSkinnedMaterials.Clear();

		// Delete skeletons (owned)
		for (var entry in mSkeletons)
			delete entry.value;
		mSkeletons.Clear();

		// Destroy bone resource sets
		for (var entry in mBoneResourceSets)
			mRenderer.GraphicsContext.Factory.DestroyResourceSet(ref entry.value);
		mBoneResourceSets.Clear();

		// Destroy material resource sets
		for (var entry in mMaterialResourceSets)
			mRenderer.GraphicsContext.Factory.DestroyResourceSet(ref entry.value);
		mMaterialResourceSets.Clear();
	}

	// ============================================
	// Mesh Renderer Resources
	// ============================================

	/// Get or create GPU mesh for a MeshRenderer
	public GPUResourceHandle<GPUMesh> GetOrCreateMesh(MeshRenderer renderer)
	{
		if (mMeshes.TryGetValue(renderer, let existing))
			return existing;

		if (!renderer.Mesh.IsValid || renderer.Mesh.Resource == null)
			return default;

		var gpuMesh = mResourceManager.GetOrCreateMesh(renderer.Mesh.Resource);
		if (gpuMesh.IsValid)
			mMeshes[renderer] = gpuMesh;

		return gpuMesh;
	}

	/// Get or create GPU material for a MeshRenderer
	public GPUResourceHandle<GPUMaterial> GetOrCreateMaterial(MeshRenderer renderer)
	{
		if (mMeshMaterials.TryGetValue(renderer, let existing))
			return existing;

		if (!renderer.Material.IsValid || renderer.Material.Resource == null)
			return default;

		var gpuMaterial = mResourceManager.GetOrCreateMaterial(renderer.Material.Resource);
		if (gpuMaterial.IsValid)
			mMeshMaterials[renderer] = gpuMaterial;

		return gpuMaterial;
	}

	/// Check if mesh is cached for renderer
	public bool HasMesh(MeshRenderer renderer) => mMeshes.ContainsKey(renderer);

	/// Check if material is cached for renderer
	public bool HasMaterial(MeshRenderer renderer) => mMeshMaterials.ContainsKey(renderer);

	// ============================================
	// Skinned Mesh Renderer Resources
	// ============================================

	/// Get or create GPU skinned mesh for a SkinnedMeshRenderer
	public GPUResourceHandle<GPUSkinnedMesh> GetOrCreateSkinnedMesh(SkinnedMeshRenderer renderer)
	{
		if (mSkinnedMeshes.TryGetValue(renderer, let existing))
			return existing;

		if (!renderer.Mesh.IsValid || renderer.Mesh.Resource == null)
			return default;

		var gpuMesh = mResourceManager.GetOrCreateSkinnedMesh(renderer.Mesh.Resource);
		if (gpuMesh.IsValid)
			mSkinnedMeshes[renderer] = gpuMesh;

		return gpuMesh;
	}

	/// Get or create GPU material for a SkinnedMeshRenderer
	public GPUResourceHandle<GPUMaterial> GetOrCreateSkinnedMaterial(SkinnedMeshRenderer renderer)
	{
		if (mSkinnedMaterials.TryGetValue(renderer, let existing))
			return existing;

		if (!renderer.Material.IsValid || renderer.Material.Resource == null)
			return default;

		var gpuMaterial = mResourceManager.GetOrCreateMaterial(renderer.Material.Resource);
		if (gpuMaterial.IsValid)
			mSkinnedMaterials[renderer] = gpuMaterial;

		return gpuMaterial;
	}

	/// Check if skinned mesh is cached for renderer
	public bool HasSkinnedMesh(SkinnedMeshRenderer renderer) => mSkinnedMeshes.ContainsKey(renderer);

	/// Check if material is cached for skinned renderer
	public bool HasSkinnedMaterial(SkinnedMeshRenderer renderer) => mSkinnedMaterials.ContainsKey(renderer);

	/// Try to get cached skinned mesh
	public bool TryGetSkinnedMesh(SkinnedMeshRenderer renderer, out GPUResourceHandle<GPUSkinnedMesh> mesh)
	{
		return mSkinnedMeshes.TryGetValue(renderer, out mesh);
	}

	/// Try to get cached skinned material
	public bool TryGetSkinnedMaterial(SkinnedMeshRenderer renderer, out GPUResourceHandle<GPUMaterial> material)
	{
		return mSkinnedMaterials.TryGetValue(renderer, out material);
	}

	// ============================================
	// Animation Resources
	// ============================================

	/// Get or create GPU skeleton for an Animator
	public GPUSkeleton GetOrCreateSkeleton(Animator animator)
	{
		if (mSkeletons.TryGetValue(animator, let existing))
			return existing;

		var skeleton = new GPUSkeleton("Skeleton", mRenderer.GraphicsContext, MAX_BONES);
		mSkeletons[animator] = skeleton;

		// Also create the bone resource set
		var resourceSetDesc = ResourceSetDescription(mRenderer.BoneMatricesResourceLayout, skeleton.BoneMatrixBuffer);
		var resourceSet = mRenderer.GraphicsContext.Factory.CreateResourceSet(resourceSetDesc);
		mBoneResourceSets[animator] = resourceSet;

		return skeleton;
	}

	/// Try to get cached skeleton
	public bool TryGetSkeleton(Animator animator, out GPUSkeleton skeleton)
	{
		return mSkeletons.TryGetValue(animator, out skeleton);
	}

	/// Try to get bone resource set for animator
	public bool TryGetBoneResourceSet(Animator animator, out ResourceSet resourceSet)
	{
		return mBoneResourceSets.TryGetValue(animator, out resourceSet);
	}

	/// Check if skeleton is cached for animator
	public bool HasSkeleton(Animator animator) => mSkeletons.ContainsKey(animator);

	// ============================================
	// Material Resource Sets
	// ============================================

	/// Get or create resource set for a GPU material
	public ResourceSet GetOrCreateMaterialResourceSet(GPUMaterial material)
	{
		if (mMaterialResourceSets.TryGetValue(material, let existing))
			return existing;

		var resourceSet = CreateMaterialResourceSet(material);
		mMaterialResourceSets[material] = resourceSet;
		return resourceSet;
	}

	private ResourceSet CreateMaterialResourceSet(GPUMaterial material)
	{
		var resources = scope List<GraphicsResource>();

		// Use the material registry to fill resources (no hardcoded switches)
		mRenderer.MaterialRegistry.FillResourceSet(material.ShaderName, resources, material, mRenderer);

		GraphicsResource[] r = scope GraphicsResource[resources.Count];
		for (int i = 0; i < resources.Count; i++)
			r[i] = resources[i];

		var layout = mRenderer.MaterialRegistry.GetMaterialResourceLayout(material.ShaderName);
		return mRenderer.GraphicsContext.Factory.CreateResourceSet(
			ResourceSetDescription(layout, params r)
		);
	}

	// ============================================
	// Lookup helpers for rendering
	// ============================================

	/// Try to get cached mesh for MeshRenderer
	public bool TryGetMesh(MeshRenderer renderer, out GPUResourceHandle<GPUMesh> mesh)
	{
		return mMeshes.TryGetValue(renderer, out mesh);
	}

	/// Try to get cached material for MeshRenderer
	public bool TryGetMaterial(MeshRenderer renderer, out GPUResourceHandle<GPUMaterial> material)
	{
		return mMeshMaterials.TryGetValue(renderer, out material);
	}
}
