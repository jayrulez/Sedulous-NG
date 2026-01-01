using Sedulous.SceneGraph;
using System;
using Sedulous.Engine.Core;
using Sedulous.RHI;
using Sedulous.Mathematics;
using System.Collections;
using Sedulous.Engine.Renderer.GPU;
using Sedulous.Utilities;
using System.Diagnostics;
namespace Sedulous.Engine.Renderer.RHI;

public struct RenderStatistics
{
	public int DrawCalls;
	public int TriangleCount;
	public int ObjectsRendered;
	public int ObjectsCulled;
	public uint64 GPUMemoryUsed;

	public void Reset() mut
	{
		DrawCalls = 0;
		TriangleCount = 0;
		ObjectsRendered = 0;
		ObjectsCulled = 0;
		// GPUMemoryUsed is cumulative, updated from GPUResourceManager
	}
}

struct MeshRenderCommand
{
	public Entity Entity;
	public Matrix WorldMatrix;
	public MeshRenderer Renderer;
	public float DistanceToCamera;
	public BoundingBox WorldBounds;
	public bool IsTransparent;
}

struct SkinnedMeshRenderCommand
{
	public Entity Entity;
	public Matrix WorldMatrix;
	public SkinnedMeshRenderer Renderer;
	public Animator Animator;
	public float DistanceToCamera;
	public BoundingBox WorldBounds;
	public bool IsTransparent;
}

struct SpriteRenderCommand
{
	public Entity Entity;
	public Matrix WorldMatrix;
	public SpriteRenderer Renderer;
	public float DistanceToCamera;
	public int32 SortingLayer;
	public int32 OrderInLayer;
}

class RenderModule : SceneModule
{
	public override StringView Name => "Render";

	private RHIRendererSubsystem mRenderer;
	private RenderCache mCache;

	// Render command lists (rebuilt each frame, separated by transparency)
	private List<MeshRenderCommand> mOpaqueMeshCommands = new .() ~ delete _;
	private List<MeshRenderCommand> mTransparentMeshCommands = new .() ~ delete _;
	private List<SkinnedMeshRenderCommand> mOpaqueSkinnedCommands = new .() ~ delete _;
	private List<SkinnedMeshRenderCommand> mTransparentSkinnedCommands = new .() ~ delete _;
	private List<SpriteRenderCommand> mSpriteCommands = new .() ~ delete _;

	// Cached frustum for culling
	private BoundingFrustum mViewFrustum;

	// Current frame data
	private Camera mActiveCamera;
	private Transform mActiveCameraTransform;
	private Matrix mViewMatrix;
	private Matrix mProjectionMatrix;

	// Lighting data
	private LightingUniforms mCurrentLighting;

	// Debug rendering
	private DebugRenderer mDebugRenderer ~ delete _;
	private ResourceSet mDebugResourceSet;

	// Render statistics
	private RenderStatistics mStatistics;

	private EntityQuery mMeshesQuery;
	private EntityQuery mSkinnedMeshesQuery;
	private EntityQuery mSpritesQuery;
	private EntityQuery mCamerasQuery;
	private EntityQuery mDirectionalLightsQuery;

	/// Access to debug renderer for drawing debug lines
	public DebugRenderer DebugRenderer => mDebugRenderer;

	/// Access to render statistics (updated each frame)
	public ref RenderStatistics Statistics => ref mStatistics;

	public this(RHIRendererSubsystem renderer)
	{
		mRenderer = renderer;
		mCache = new RenderCache(renderer, renderer.GPUResources);
		mDebugRenderer = new DebugRenderer(renderer.GraphicsContext);

		mMeshesQuery = CreateQuery().With<MeshRenderer>();
		mSkinnedMeshesQuery = CreateQuery().With<SkinnedMeshRenderer>().With<Animator>();
		mSpritesQuery = CreateQuery().With<SpriteRenderer>();
		mCamerasQuery = CreateQuery().With<Camera>();
		mDirectionalLightsQuery = CreateQuery().With<DirectionalLight>();

		// Initialize default lighting
		// Note: PBR requires higher ambient than Phong due to energy conservation (division by PI)
		mCurrentLighting = .()
		{
			DirectionalLightDir = Vector4(0.5f, -1.0f, 0.3f, 0),
			DirectionalLightColor = Vector4(1.0f, 0.95f, 0.9f, 1.0f),
			AmbientLight = Vector4(0.3f, 0.3f, 0.35f, 0),  // Higher ambient for PBR
			CameraPosition = Vector4(0, 0, 0, 0)
		};

		// Create debug resource set
		ResourceSetDescription debugSetDesc = .(renderer.DebugResourceLayout, mDebugRenderer.UniformBuffer);
		mDebugResourceSet = renderer.GraphicsContext.Factory.CreateResourceSet(debugSetDesc);
	}

	public ~this()
	{
		if (mDebugResourceSet != null)
			mRenderer.GraphicsContext.Factory.DestroyResourceSet(ref mDebugResourceSet);

		delete mCache;

		DestroyQuery(mMeshesQuery);
		DestroyQuery(mSkinnedMeshesQuery);
		DestroyQuery(mSpritesQuery);
		DestroyQuery(mCamerasQuery);
		DestroyQuery(mDirectionalLightsQuery);
	}

	protected override void OnUpdate(Time time)
	{
		// Reset per-frame statistics
		mStatistics.Reset();

		// Clear debug lines from previous frame (before user code adds new ones)
		mDebugRenderer.Clear();

		// Find active camera and lights
		UpdateActiveCamera();
		UpdateLighting();

		// Clear render commands
		mOpaqueMeshCommands.Clear();
		mTransparentMeshCommands.Clear();
		mOpaqueSkinnedCommands.Clear();
		mTransparentSkinnedCommands.Clear();
		mSpriteCommands.Clear();

		// Create view frustum for culling
		if (mActiveCamera != null)
		{
			mViewFrustum = BoundingFrustum(mViewMatrix * mProjectionMatrix);
		}

		// Collect render commands (with frustum culling, transparency separation)
		// Note: GPU-based Hi-Z occlusion culling happens in GPUCullingExecute pass
		CollectRenderCommands();
		CollectSkinnedRenderCommands();
		CollectSpriteRenderCommands();

		// Sort render commands
		SortRenderCommands();
		SortSpriteCommands();

		// Update GPU memory statistic
		mStatistics.GPUMemoryUsed = mRenderer.GPUResources.TotalGPUMemory;
	}

	private void UpdateLighting()
	{
		// Find the first directional light in the scene
		for (var entity in mDirectionalLightsQuery.GetEntities(Scene, .. scope .()))
		{
			if (entity.HasComponent<DirectionalLight>())
			{
				var light = entity.GetComponent<DirectionalLight>();
				var transform = entity.Transform;

				// Get light direction from entity's forward vector
				var lightDir = transform.Forward;
				mCurrentLighting.DirectionalLightDir = Vector4(lightDir.X, lightDir.Y, lightDir.Z, 0);

				// Light color with intensity in W
				mCurrentLighting.DirectionalLightColor = Vector4(light.Color.X, light.Color.Y, light.Color.Z, light.Intensity);

				// Use first light found (primary sun light)
				break;
			}
		}

		// Update camera position for specular calculations
		if (mActiveCameraTransform != null)
		{
			var camPos = mActiveCameraTransform.WorldPosition;
			mCurrentLighting.CameraPosition = Vector4(camPos.X, camPos.Y, camPos.Z, 0);
		}
	}

	/*internal void RenderFrame(IEngine.UpdateInfo info, CommandBuffer commandBuffer)
	{
		PrepareGPUResources(commandBuffer);
		UpdateLightingBuffer(commandBuffer);
		UpdateDebugBuffers(commandBuffer);

		RenderMeshes(commandBuffer);
		RenderSkinnedMeshes(commandBuffer);
		RenderDebugLines(commandBuffer);
	}*/

	internal void UpdateLightingBuffer(CommandBuffer commandBuffer)
	{
		commandBuffer.UpdateBufferData(mRenderer.LightingBuffer, &mCurrentLighting, (uint32)sizeof(LightingUniforms));
	}

	internal void UpdateDebugBuffers(CommandBuffer commandBuffer)
	{
		// Always update the uniform buffer to ensure descriptor is valid
		var viewProj = mViewMatrix * mProjectionMatrix;
		mDebugRenderer.UpdateBuffers(commandBuffer, viewProj);
	}

	/// Render depth prepass for all opaque geometry (no material/lighting, depth-only)
	internal void RenderDepthPrepass(CommandBuffer commandBuffer)
	{
		const int32 ALIGNMENT = 256;
		int32 alignedSize = ((sizeof(UnlitVertexUniforms) + ALIGNMENT - 1) / ALIGNMENT) * ALIGNMENT;

		// Render opaque static meshes with depth-only pipeline
		if (!mOpaqueMeshCommands.IsEmpty)
		{
			commandBuffer.SetGraphicsPipelineState(mRenderer.DepthOnlyPipeline);

			int uniformIndex = 0;
			for (var command in mOpaqueMeshCommands)
			{
				// Set per-object resource set with dynamic offset
				uint32 dynamicOffset = (uint32)(uniformIndex * alignedSize);
				commandBuffer.SetResourceSet(mRenderer.UnlitResourceSet, 0, scope .(dynamicOffset));

				// Render mesh (depth only)
				RenderMeshDepthOnly(command, commandBuffer);
				uniformIndex++;
			}
		}

		// Render opaque skinned meshes with skinned depth-only pipeline
		if (!mOpaqueSkinnedCommands.IsEmpty)
		{
			commandBuffer.SetGraphicsPipelineState(mRenderer.SkinnedDepthOnlyPipeline);

			int uniformIndex = mOpaqueMeshCommands.Count; // Continue from where static meshes left off
			for (var command in mOpaqueSkinnedCommands)
			{
				// Set per-object resource set
				uint32 dynamicOffset = (uint32)(uniformIndex * alignedSize);
				commandBuffer.SetResourceSet(mRenderer.UnlitResourceSet, 0, scope .(dynamicOffset));

				// Set bone matrices resource set (Set 2)
				if (mCache.TryGetBoneResourceSet(command.Animator, let boneResourceSet))
				{
					commandBuffer.SetResourceSet(boneResourceSet, 2);
				}

				// Render skinned mesh (depth only)
				RenderSkinnedMeshDepthOnly(command, commandBuffer);
				uniformIndex++;
			}
		}

		// Note: Transparent objects skip depth prepass (they render in main pass only)
	}

	private void RenderMeshDepthOnly(MeshRenderCommand command, CommandBuffer commandBuffer)
	{
		if (!mCache.TryGetMesh(command.Renderer, let meshHandle) || !meshHandle.IsValid)
			return;

		var mesh = meshHandle.Resource;
		commandBuffer.SetVertexBuffers(scope Buffer[](mesh.VertexBuffer));

		if (mesh.IndexBuffer != null && mesh.IndexCount > 0)
		{
			commandBuffer.SetIndexBuffer(mesh.IndexBuffer, .UInt32);
			commandBuffer.DrawIndexed(mesh.IndexCount);
		}
		else
		{
			commandBuffer.Draw(mesh.VertexCount);
		}
	}

	private void RenderSkinnedMeshDepthOnly(SkinnedMeshRenderCommand command, CommandBuffer commandBuffer)
	{
		if (!mCache.TryGetSkinnedMesh(command.Renderer, let meshHandle) || !meshHandle.IsValid)
			return;

		var mesh = meshHandle.Resource;
		commandBuffer.SetVertexBuffers(scope Buffer[](mesh.VertexBuffer));

		if (mesh.IndexBuffer != null && mesh.IndexCount > 0)
		{
			commandBuffer.SetIndexBuffer(mesh.IndexBuffer, .UInt32);
			commandBuffer.DrawIndexed(mesh.IndexCount);
		}
		else
		{
			commandBuffer.Draw(mesh.VertexCount);
		}
	}

	internal void RenderDebugLines(CommandBuffer commandBuffer)
	{
		if (mDebugRenderer.LineCount == 0)
			return;

		// Set pipeline and resources
		commandBuffer.SetGraphicsPipelineState(mRenderer.DebugLinePipeline);
		commandBuffer.SetResourceSet(mDebugResourceSet, 0);
		commandBuffer.SetVertexBuffers(scope Buffer[](mDebugRenderer.VertexBuffer));

		// Draw lines
		commandBuffer.Draw((uint32)(mDebugRenderer.LineCount * 2));
		mStatistics.DrawCalls++;
	}

	internal void PrepareGPUResources(CommandBuffer commandBuffer)
	{
		// Upload GPU culling data
		PrepareGPUCullingData(commandBuffer);

		// Create GPU resources for opaque mesh renderers
		for (var command in mOpaqueMeshCommands)
		{
			mCache.GetOrCreateMesh(command.Renderer);

			var materialHandle = mCache.GetOrCreateMaterial(command.Renderer);
			if (materialHandle.IsValid)
				materialHandle.Resource.UpdateUniformData(commandBuffer);
		}

		// Create GPU resources for transparent mesh renderers
		for (var command in mTransparentMeshCommands)
		{
			mCache.GetOrCreateMesh(command.Renderer);

			var materialHandle = mCache.GetOrCreateMaterial(command.Renderer);
			if (materialHandle.IsValid)
				materialHandle.Resource.UpdateUniformData(commandBuffer);
		}

		// Prepare opaque skinned mesh GPU resources
		for (var command in mOpaqueSkinnedCommands)
		{
			mCache.GetOrCreateSkinnedMesh(command.Renderer);

			var materialHandle = mCache.GetOrCreateSkinnedMaterial(command.Renderer);
			if (materialHandle.IsValid)
				materialHandle.Resource.UpdateUniformData(commandBuffer);

			mCache.GetOrCreateSkeleton(command.Animator);
		}

		// Prepare transparent skinned mesh GPU resources
		for (var command in mTransparentSkinnedCommands)
		{
			mCache.GetOrCreateSkinnedMesh(command.Renderer);

			var materialHandle = mCache.GetOrCreateSkinnedMaterial(command.Renderer);
			if (materialHandle.IsValid)
				materialHandle.Resource.UpdateUniformData(commandBuffer);

			mCache.GetOrCreateSkeleton(command.Animator);
		}

		// Update vertex uniform buffer (outside render pass)
		UpdateVertexUniforms();
		UpdateSkinnedVertexUniforms();
	}

	/// Total number of mesh commands (opaque + transparent)
	private int TotalMeshCount => mOpaqueMeshCommands.Count + mTransparentMeshCommands.Count;

	/// Total number of skinned mesh commands (opaque + transparent)
	private int TotalSkinnedCount => mOpaqueSkinnedCommands.Count + mTransparentSkinnedCommands.Count;

	/// Prepare GPU culling data (object data and culling uniforms)
	private void PrepareGPUCullingData(CommandBuffer commandBuffer)
	{
		// Skip if no objects to cull
		int totalObjects = TotalMeshCount;
		if (totalObjects == 0)
			return;

		// Clamp to max GPU objects
		if (totalObjects > RHIRendererSubsystem.MAX_GPU_OBJECTS)
			totalObjects = RHIRendererSubsystem.MAX_GPU_OBJECTS;

		// Upload object data (world matrices and bounds)
		var objectDataMapped = mRenderer.GraphicsContext.MapMemory(mRenderer.ObjectDataBuffer, .Write);
		if (objectDataMapped.Data != null)
		{
			GPUObjectData* objectData = (GPUObjectData*)objectDataMapped.Data;
			int writeIndex = 0;

			// Write opaque mesh objects
			for (var command in mOpaqueMeshCommands)
			{
				if (writeIndex >= RHIRendererSubsystem.MAX_GPU_OBJECTS)
					break;

				objectData[writeIndex] = GPUObjectData()
				{
					WorldMatrix = command.WorldMatrix,
					BoundsMin = Vector4(command.WorldBounds.Min, 0),  // meshIndex would go in W
					BoundsMax = Vector4(command.WorldBounds.Max, 0)   // materialIndex would go in W
				};
				writeIndex++;
			}

			// Write transparent mesh objects
			for (var command in mTransparentMeshCommands)
			{
				if (writeIndex >= RHIRendererSubsystem.MAX_GPU_OBJECTS)
					break;

				objectData[writeIndex] = GPUObjectData()
				{
					WorldMatrix = command.WorldMatrix,
					BoundsMin = Vector4(command.WorldBounds.Min, 0),
					BoundsMax = Vector4(command.WorldBounds.Max, 0)
				};
				writeIndex++;
			}

			mRenderer.GraphicsContext.UnmapMemory(mRenderer.ObjectDataBuffer);
		}

		// Update culling uniforms
		var viewProjection = mViewMatrix * mProjectionMatrix;
		var frustumPlanes = ExtractFrustumPlanes(viewProjection);

		var cullingUniforms = GPUCullingUniforms()
		{
			ViewProjection = viewProjection,
			FrustumPlanes = frustumPlanes,
			ObjectCount = (uint32)totalObjects,
			HiZWidth = mRenderer.HiZSize,
			HiZHeight = mRenderer.HiZSize,
			Padding = 0
		};

		commandBuffer.UpdateBufferData(mRenderer.CullingUniformsBuffer, &cullingUniforms, (uint32)sizeof(GPUCullingUniforms));
	}

	/// Extract frustum planes from view-projection matrix (for GPU culling)
	private Vector4[6] ExtractFrustumPlanes(Matrix viewProjection)
	{
		Vector4[6] planes = default;

		// Left plane: row3 + row0
		planes[0] = Vector4(
			viewProjection.M14 + viewProjection.M11,
			viewProjection.M24 + viewProjection.M21,
			viewProjection.M34 + viewProjection.M31,
			viewProjection.M44 + viewProjection.M41
		);

		// Right plane: row3 - row0
		planes[1] = Vector4(
			viewProjection.M14 - viewProjection.M11,
			viewProjection.M24 - viewProjection.M21,
			viewProjection.M34 - viewProjection.M31,
			viewProjection.M44 - viewProjection.M41
		);

		// Bottom plane: row3 + row1
		planes[2] = Vector4(
			viewProjection.M14 + viewProjection.M12,
			viewProjection.M24 + viewProjection.M22,
			viewProjection.M34 + viewProjection.M32,
			viewProjection.M44 + viewProjection.M42
		);

		// Top plane: row3 - row1
		planes[3] = Vector4(
			viewProjection.M14 - viewProjection.M12,
			viewProjection.M24 - viewProjection.M22,
			viewProjection.M34 - viewProjection.M32,
			viewProjection.M44 - viewProjection.M42
		);

		// Near plane: row3 + row2
		planes[4] = Vector4(
			viewProjection.M14 + viewProjection.M13,
			viewProjection.M24 + viewProjection.M23,
			viewProjection.M34 + viewProjection.M33,
			viewProjection.M44 + viewProjection.M43
		);

		// Far plane: row3 - row2
		planes[5] = Vector4(
			viewProjection.M14 - viewProjection.M13,
			viewProjection.M24 - viewProjection.M23,
			viewProjection.M34 - viewProjection.M33,
			viewProjection.M44 - viewProjection.M43
		);

		// Normalize planes
		for (int i = 0; i < 6; i++)
		{
			float length = Math.Sqrt(planes[i].X * planes[i].X + planes[i].Y * planes[i].Y + planes[i].Z * planes[i].Z);
			if (length > 0.0001f)
			{
				planes[i].X /= length;
				planes[i].Y /= length;
				planes[i].Z /= length;
				planes[i].W /= length;
			}
		}

		return planes;
	}

	private void UpdateVertexUniforms()
	{
		if (mOpaqueMeshCommands.IsEmpty && mTransparentMeshCommands.IsEmpty)
			return;

		// Update all object data at once
		var mapped = mRenderer.GraphicsContext.MapMemory(mRenderer.UnlitVertexCB, MapMode.Write);

		const int32 ALIGNMENT = 256;
		int32 alignedSize = ((sizeof(UnlitVertexUniforms) + ALIGNMENT - 1) / ALIGNMENT) * ALIGNMENT;

		int writeIndex = 0;

		// Write opaque mesh uniforms first
		for (var command in mOpaqueMeshCommands)
		{
			var vertexUniforms = UnlitVertexUniforms()
				{
					MVPMatrix = command.WorldMatrix * mViewMatrix * mProjectionMatrix,
					ModelMatrix = command.WorldMatrix
				};

			UnlitVertexUniforms* dest = (UnlitVertexUniforms*)((uint8*)mapped.Data + writeIndex * alignedSize);
			*dest = vertexUniforms;
			writeIndex++;
		}

		// Then transparent mesh uniforms
		for (var command in mTransparentMeshCommands)
		{
			var vertexUniforms = UnlitVertexUniforms()
				{
					MVPMatrix = command.WorldMatrix * mViewMatrix * mProjectionMatrix,
					ModelMatrix = command.WorldMatrix
				};

			UnlitVertexUniforms* dest = (UnlitVertexUniforms*)((uint8*)mapped.Data + writeIndex * alignedSize);
			*dest = vertexUniforms;
			writeIndex++;
		}

		mRenderer.GraphicsContext.UnmapMemory(mRenderer.UnlitVertexCB);
	}

	internal void RenderMeshes(CommandBuffer commandBuffer)
	{
		if (mOpaqueMeshCommands.IsEmpty && mTransparentMeshCommands.IsEmpty)
			return;

		// Render pass is already begun by rendergraph
		StringView currentShaderName = "Unlit";
		commandBuffer.SetGraphicsPipelineState(mRenderer.UnlitPipeline);

		const int32 ALIGNMENT = 256;
		int32 alignedSize = ((sizeof(UnlitVertexUniforms) + ALIGNMENT - 1) / ALIGNMENT) * ALIGNMENT;

		GPUMaterial currentMaterial = null;
		int uniformIndex = 0;

		// 1. Render opaque meshes first (front-to-back)
		for (var command in mOpaqueMeshCommands)
		{
			// Get the material for this object
			if (mCache.TryGetMaterial(command.Renderer, let materialHandle))
			{
				var gpuMaterial = materialHandle.Resource;

				// Only update if material changed (batching)
				if (gpuMaterial != currentMaterial)
				{
					currentMaterial = gpuMaterial;

					// Switch pipeline if shader type changed
					if (gpuMaterial.ShaderName != currentShaderName)
					{
						currentShaderName = gpuMaterial.ShaderName;
						SetPipelineForShader(commandBuffer, currentShaderName);
					}

					if (gpuMaterial.UniformBuffer != null)
					{
						var materialResourceSet = mCache.GetOrCreateMaterialResourceSet(gpuMaterial);
						commandBuffer.SetResourceSet(materialResourceSet, 1);
					}
				}
			}
			else
			{
				// No material - bind a default material resource set
				if (currentShaderName != "Unlit")
				{
					currentShaderName = "Unlit";
					commandBuffer.SetGraphicsPipelineState(mRenderer.UnlitPipeline);
				}
				commandBuffer.SetResourceSet(mRenderer.DefaultUnlitMaterialResourceSet, 1);
			}

			// Set resource set with dynamic offset
			uint32 dynamicOffset = (uint32)(uniformIndex * alignedSize);
			commandBuffer.SetResourceSet(mRenderer.UnlitResourceSet, 0, scope .(dynamicOffset));

			RenderMesh(command, commandBuffer);
			uniformIndex++;
		}

		// 2. Render transparent meshes (back-to-front)
		for (var command in mTransparentMeshCommands)
		{
			// Get the material for this object
			if (mCache.TryGetMaterial(command.Renderer, let materialHandle))
			{
				var gpuMaterial = materialHandle.Resource;

				// Only update if material changed (batching)
				if (gpuMaterial != currentMaterial)
				{
					currentMaterial = gpuMaterial;

					// Switch pipeline if shader type changed
					if (gpuMaterial.ShaderName != currentShaderName)
					{
						currentShaderName = gpuMaterial.ShaderName;
						SetPipelineForShader(commandBuffer, currentShaderName);
					}

					if (gpuMaterial.UniformBuffer != null)
					{
						var materialResourceSet = mCache.GetOrCreateMaterialResourceSet(gpuMaterial);
						commandBuffer.SetResourceSet(materialResourceSet, 1);
					}
				}
			}
			else
			{
				// No material - bind a default material resource set
				if (currentShaderName != "Unlit")
				{
					currentShaderName = "Unlit";
					commandBuffer.SetGraphicsPipelineState(mRenderer.UnlitPipeline);
				}
				commandBuffer.SetResourceSet(mRenderer.DefaultUnlitMaterialResourceSet, 1);
			}

			// Set resource set with dynamic offset
			uint32 dynamicOffset = (uint32)(uniformIndex * alignedSize);
			commandBuffer.SetResourceSet(mRenderer.UnlitResourceSet, 0, scope .(dynamicOffset));

			RenderMesh(command, commandBuffer);
			uniformIndex++;
		}
		// Render pass will be ended by rendergraph
	}

	private void SetPipelineForShader(CommandBuffer commandBuffer, StringView shaderName)
	{
		switch (shaderName)
		{
		case "Phong":
			commandBuffer.SetGraphicsPipelineState(mRenderer.PhongPipeline);
			// Set lighting resource set at slot 2 for Phong
			commandBuffer.SetResourceSet(mRenderer.LightingResourceSet, 2);
		case "PBR":
			commandBuffer.SetGraphicsPipelineState(mRenderer.PBRPipeline);
			// Set lighting resource set at slot 2 for PBR
			commandBuffer.SetResourceSet(mRenderer.LightingResourceSet, 2);
		default:
			// Default to unlit for unknown shader types
			commandBuffer.SetGraphicsPipelineState(mRenderer.UnlitPipeline);
		}
	}

	private void UpdateActiveCamera()
	{
		mActiveCamera = null;

		for (var entity in mCamerasQuery.GetEntities(Scene, .. scope .()))
		{
			if (mActiveCamera == null && entity.HasComponent<Camera>())
			{
				mActiveCamera = entity.GetComponent<Camera>();
				mActiveCameraTransform = entity.Transform;
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
			//("Warning: No active camera found!");
		}
	}

	/// Transform a bounding box from local to world space
	private BoundingBox TransformBounds(BoundingBox localBounds, Matrix worldMatrix)
	{
		// Transform all 8 corners of the bounding box and create new AABB
		var corners = scope Vector3[8];
		localBounds.GetCorners(corners);

		var min = Vector3(float.MaxValue);
		var max = Vector3(float.MinValue);

		for (var corner in corners)
		{
			var transformed = Vector3.Transform(corner, worldMatrix);
			min = Vector3.Min(min, transformed);
			max = Vector3.Max(max, transformed);
		}

		return BoundingBox(min, max);
	}

	private void CollectRenderCommands()
	{
		for (var entity in mMeshesQuery.GetEntities(Scene, .. scope .()))
		{
			if (entity.HasComponent<MeshRenderer>())
			{
				var renderer = entity.GetComponent<MeshRenderer>();
				var transform = entity.Transform;
				var worldMatrix = transform.WorldMatrix;

				// Get mesh bounds and transform to world space
				if (!renderer.Mesh.IsValid || renderer.Mesh.Resource == null)
					continue;

				var localBounds = renderer.Mesh.Resource.Mesh.GetBounds();
				var worldBounds = TransformBounds(localBounds, worldMatrix);

				// Frustum culling - skip objects outside view
				// Note: Hi-Z occlusion culling is done on GPU in GPUCullingExecute pass
				if (mActiveCamera != null && mViewFrustum.Contains(worldBounds) == .Disjoint)
				{
					mStatistics.ObjectsCulled++;
					continue;
				}

				// Check if material is transparent
				bool isTransparent = false;
				if (renderer.Material.IsValid && renderer.Material.Resource?.Material != null)
				{
					isTransparent = renderer.Material.Resource.Material.Blending != .Opaque;
				}

				var command = MeshRenderCommand()
					{
						Entity = entity,
						WorldMatrix = worldMatrix,
						Renderer = renderer,
						DistanceToCamera = 0,
						WorldBounds = worldBounds,
						IsTransparent = isTransparent
					};

				if (mActiveCamera != null)
				{
					command.DistanceToCamera = Vector3.Distance(transform.Position, mActiveCameraTransform.Position);
				}

				// Add to appropriate list based on transparency
				if (isTransparent)
					mTransparentMeshCommands.Add(command);
				else
					mOpaqueMeshCommands.Add(command);
			}
		}
	}

	private void CollectSkinnedRenderCommands()
	{
		for (var entity in mSkinnedMeshesQuery.GetEntities(Scene, .. scope .()))
		{
			if (entity.HasComponent<SkinnedMeshRenderer>() && entity.HasComponent<Animator>())
			{
				var renderer = entity.GetComponent<SkinnedMeshRenderer>();
				var animator = entity.GetComponent<Animator>();
				var transform = entity.Transform;
				var worldMatrix = transform.WorldMatrix;

				// Get mesh bounds and transform to world space
				if (!renderer.Mesh.IsValid || renderer.Mesh.Resource == null)
					continue;

				var localBounds = renderer.Mesh.Resource.Mesh.Bounds;
				var worldBounds = TransformBounds(localBounds, worldMatrix);

				// Frustum culling - skip objects outside view
				// Note: Skinned meshes are not GPU-culled in initial implementation
				if (mActiveCamera != null && mViewFrustum.Contains(worldBounds) == .Disjoint)
				{
					mStatistics.ObjectsCulled++;
					continue;
				}

				// Check if material is transparent
				bool isTransparent = false;
				if (renderer.Material.IsValid && renderer.Material.Resource?.Material != null)
				{
					isTransparent = renderer.Material.Resource.Material.Blending != .Opaque;
				}

				var command = SkinnedMeshRenderCommand()
					{
						Entity = entity,
						WorldMatrix = worldMatrix,
						Renderer = renderer,
						Animator = animator,
						DistanceToCamera = 0,
						WorldBounds = worldBounds,
						IsTransparent = isTransparent
					};

				if (mActiveCamera != null)
				{
					command.DistanceToCamera = Vector3.Distance(transform.Position, mActiveCameraTransform.Position);
				}

				// Add to appropriate list based on transparency
				if (isTransparent)
					mTransparentSkinnedCommands.Add(command);
				else
					mOpaqueSkinnedCommands.Add(command);
			}
		}
	}

	private void SortRenderCommands()
	{
		// Opaque: front-to-back for better z-rejection
		mOpaqueMeshCommands.Sort(scope (lhs, rhs) => lhs.DistanceToCamera.CompareTo(rhs.DistanceToCamera));
		mOpaqueSkinnedCommands.Sort(scope (lhs, rhs) => lhs.DistanceToCamera.CompareTo(rhs.DistanceToCamera));

		// Transparent: back-to-front for correct blending
		mTransparentMeshCommands.Sort(scope (lhs, rhs) => rhs.DistanceToCamera.CompareTo(lhs.DistanceToCamera));
		mTransparentSkinnedCommands.Sort(scope (lhs, rhs) => rhs.DistanceToCamera.CompareTo(lhs.DistanceToCamera));
	}


	private void RenderMesh(MeshRenderCommand command, CommandBuffer commandBuffer)
	{
		if (!mCache.TryGetMesh(command.Renderer, let meshHandle) || !meshHandle.IsValid)
			return;

		var mesh = meshHandle.Resource;

		commandBuffer.SetVertexBuffers(scope Buffer[](mesh.VertexBuffer));

		// Use indexed or non-indexed draw depending on whether mesh has indices
		if (mesh.IndexBuffer != null && mesh.IndexCount > 0)
		{
			commandBuffer.SetIndexBuffer(mesh.IndexBuffer, .UInt32);
			commandBuffer.DrawIndexed(mesh.IndexCount);
			mStatistics.TriangleCount += (int)(mesh.IndexCount / 3);
		}
		else
		{
			commandBuffer.Draw(mesh.VertexCount);
			mStatistics.TriangleCount += (int)(mesh.VertexCount / 3);
		}

		mStatistics.DrawCalls++;
		mStatistics.ObjectsRendered++;
	}

	private void UpdateSkinnedVertexUniforms()
	{
		if (mOpaqueSkinnedCommands.IsEmpty && mTransparentSkinnedCommands.IsEmpty)
			return;

		// Update all object data at once
		var mapped = mRenderer.GraphicsContext.MapMemory(mRenderer.UnlitVertexCB, MapMode.Write);

		const int32 ALIGNMENT = 256;
		int32 alignedSize = ((sizeof(UnlitVertexUniforms) + ALIGNMENT - 1) / ALIGNMENT) * ALIGNMENT;

		// Offset to place after regular mesh uniforms (opaque + transparent)
		int writeIndex = TotalMeshCount;

		// Write opaque skinned uniforms first
		for (var command in mOpaqueSkinnedCommands)
		{
			var vertexUniforms = UnlitVertexUniforms()
				{
					MVPMatrix = command.WorldMatrix * mViewMatrix * mProjectionMatrix,
					ModelMatrix = command.WorldMatrix
				};

			UnlitVertexUniforms* dest = (UnlitVertexUniforms*)((uint8*)mapped.Data + writeIndex * alignedSize);
			*dest = vertexUniforms;
			writeIndex++;
		}

		// Then transparent skinned uniforms
		for (var command in mTransparentSkinnedCommands)
		{
			var vertexUniforms = UnlitVertexUniforms()
				{
					MVPMatrix = command.WorldMatrix * mViewMatrix * mProjectionMatrix,
					ModelMatrix = command.WorldMatrix
				};

			UnlitVertexUniforms* dest = (UnlitVertexUniforms*)((uint8*)mapped.Data + writeIndex * alignedSize);
			*dest = vertexUniforms;
			writeIndex++;
		}

		mRenderer.GraphicsContext.UnmapMemory(mRenderer.UnlitVertexCB);

		// Update bone matrices for opaque skinned meshes
		for (var command in mOpaqueSkinnedCommands)
		{
			UpdateBoneMatrices(command);
		}

		// Update bone matrices for transparent skinned meshes
		for (var command in mTransparentSkinnedCommands)
		{
			UpdateBoneMatrices(command);
		}
	}

	private void UpdateBoneMatrices(SkinnedMeshRenderCommand command)
	{
		if (mCache.TryGetSkeleton(command.Animator, let skeleton))
		{
			// Compute final bone matrices with inverse bind matrices
			var animator = command.Animator;
			var skinHandle = command.Renderer.Skin;

			if (skinHandle.IsValid && skinHandle.Resource != null)
			{
				var skin = skinHandle.Resource;
				var finalMatrices = scope Matrix[MAX_BONES];

				// Compute final bone matrices: InverseBindMatrix * WorldTransform (row-vector convention)
				for (int32 i = 0; i < Math.Min(skin.JointCount, animator.BoneMatrices.Count); i++)
				{
					int32 jointNodeIndex = skin.JointIndices[i];
					if (jointNodeIndex >= 0 && jointNodeIndex < animator.BoneMatrices.Count)
					{
						// Joint matrix for row-vector convention (v * M):
						// v_world = v_mesh * InverseBindMatrix * GlobalTransform
						finalMatrices[i] = skin.InverseBindMatrices[i] * animator.BoneMatrices[jointNodeIndex];
					}
					else
					{
						finalMatrices[i] = .Identity;
					}
				}

				skeleton.UpdateBoneMatrices(null, &finalMatrices[0], (int32)skin.JointCount);
			}
			else
			{
				// No skin - just use identity matrices
				skeleton.UpdateBoneMatrices(null, animator.BoneMatrices);
			}
		}
	}

	internal void RenderSkinnedMeshes(CommandBuffer commandBuffer)
	{
		if (mOpaqueSkinnedCommands.IsEmpty && mTransparentSkinnedCommands.IsEmpty)
			return;

		const int32 ALIGNMENT = 256;
		int32 alignedSize = ((sizeof(UnlitVertexUniforms) + ALIGNMENT - 1) / ALIGNMENT) * ALIGNMENT;

		// Start after mesh uniforms (both opaque and transparent)
		int uniformIndex = TotalMeshCount;

		GPUMaterial currentMaterial = null;
		StringView currentShaderName = default;

		// 1. Render opaque skinned meshes first (front-to-back)
		for (var command in mOpaqueSkinnedCommands)
		{
			// Get the material for this object
			if (mCache.TryGetSkinnedMaterial(command.Renderer, let materialHandle))
			{
				var gpuMaterial = materialHandle.Resource;

				// Only update if material changed (batching)
				if (gpuMaterial != currentMaterial)
				{
					currentMaterial = gpuMaterial;

					// Switch pipeline if shader type changed
					if (gpuMaterial.ShaderName != currentShaderName)
					{
						currentShaderName = gpuMaterial.ShaderName;
						SetSkinnedPipelineForShader(commandBuffer, currentShaderName);
					}

					if (gpuMaterial.UniformBuffer != null)
					{
						var materialResourceSet = mCache.GetOrCreateMaterialResourceSet(gpuMaterial);
						commandBuffer.SetResourceSet(materialResourceSet, 1);
					}
				}
			}
			else
			{
				// Default to unlit pipeline for objects without materials
				if (currentShaderName != "Unlit")
				{
					currentShaderName = "Unlit";
					commandBuffer.SetGraphicsPipelineState(mRenderer.SkinnedUnlitPipeline);
				}
				commandBuffer.SetResourceSet(mRenderer.DefaultUnlitMaterialResourceSet, 1);
			}

			// Set per-object resource set with dynamic offset
			uint32 dynamicOffset = (uint32)(uniformIndex * alignedSize);
			commandBuffer.SetResourceSet(mRenderer.UnlitResourceSet, 0, scope .(dynamicOffset));

			// Set bone matrices resource set
			if (mCache.TryGetBoneResourceSet(command.Animator, let boneResourceSet))
			{
				commandBuffer.SetResourceSet(boneResourceSet, 2);
			}

			RenderSkinnedMesh(command, commandBuffer);
			uniformIndex++;
		}

		// 2. Render transparent skinned meshes (back-to-front)
		for (var command in mTransparentSkinnedCommands)
		{
			// Get the material for this object
			if (mCache.TryGetSkinnedMaterial(command.Renderer, let materialHandle))
			{
				var gpuMaterial = materialHandle.Resource;

				// Only update if material changed (batching)
				if (gpuMaterial != currentMaterial)
				{
					currentMaterial = gpuMaterial;

					// Switch pipeline if shader type changed
					if (gpuMaterial.ShaderName != currentShaderName)
					{
						currentShaderName = gpuMaterial.ShaderName;
						SetSkinnedPipelineForShader(commandBuffer, currentShaderName);
					}

					if (gpuMaterial.UniformBuffer != null)
					{
						var materialResourceSet = mCache.GetOrCreateMaterialResourceSet(gpuMaterial);
						commandBuffer.SetResourceSet(materialResourceSet, 1);
					}
				}
			}
			else
			{
				// Default to unlit pipeline for objects without materials
				if (currentShaderName != "Unlit")
				{
					currentShaderName = "Unlit";
					commandBuffer.SetGraphicsPipelineState(mRenderer.SkinnedUnlitPipeline);
				}
				commandBuffer.SetResourceSet(mRenderer.DefaultUnlitMaterialResourceSet, 1);
			}

			// Set per-object resource set with dynamic offset
			uint32 dynamicOffset = (uint32)(uniformIndex * alignedSize);
			commandBuffer.SetResourceSet(mRenderer.UnlitResourceSet, 0, scope .(dynamicOffset));

			// Set bone matrices resource set
			if (mCache.TryGetBoneResourceSet(command.Animator, let boneResourceSet))
			{
				commandBuffer.SetResourceSet(boneResourceSet, 2);
			}

			RenderSkinnedMesh(command, commandBuffer);
			uniformIndex++;
		}
	}

	private void SetSkinnedPipelineForShader(CommandBuffer commandBuffer, StringView shaderName)
	{
		switch (shaderName)
		{
		case "Phong":
			commandBuffer.SetGraphicsPipelineState(mRenderer.SkinnedPhongPipeline);
			// Set lighting resource set at slot 3 for skinned Phong
			commandBuffer.SetResourceSet(mRenderer.LightingResourceSet, 3);
		case "PBR":
			commandBuffer.SetGraphicsPipelineState(mRenderer.SkinnedPBRPipeline);
			// Set lighting resource set at slot 3 for skinned PBR
			commandBuffer.SetResourceSet(mRenderer.LightingResourceSet, 3);
		default:
			// Default to unlit for unknown shader types
			commandBuffer.SetGraphicsPipelineState(mRenderer.SkinnedUnlitPipeline);
		}
	}

	private void RenderSkinnedMesh(SkinnedMeshRenderCommand command, CommandBuffer commandBuffer)
	{
		if (!mCache.TryGetSkinnedMesh(command.Renderer, let meshHandle) || !meshHandle.IsValid)
			return;

		var mesh = meshHandle.Resource;

		commandBuffer.SetVertexBuffers(scope Buffer[](mesh.VertexBuffer));

		// Use indexed or non-indexed draw depending on whether mesh has indices
		if (mesh.IndexBuffer != null && mesh.IndexCount > 0)
		{
			commandBuffer.SetIndexBuffer(mesh.IndexBuffer, .UInt32);
			commandBuffer.DrawIndexed(mesh.IndexCount);
			mStatistics.TriangleCount += (int)(mesh.IndexCount / 3);
		}
		else
		{
			commandBuffer.Draw(mesh.VertexCount);
			mStatistics.TriangleCount += (int)(mesh.VertexCount / 3);
		}

		mStatistics.DrawCalls++;
		mStatistics.ObjectsRendered++;
	}

	private void CollectSpriteRenderCommands()
	{
		for (var entity in mSpritesQuery.GetEntities(Scene, .. scope .()))
		{
			if (entity.HasComponent<SpriteRenderer>())
			{
				var renderer = entity.GetComponent<SpriteRenderer>();
				var transform = entity.Transform;

				// Skip if no texture
				if (!renderer.Texture.IsValid || renderer.Texture.Resource == null)
					continue;

				var worldMatrix = transform.WorldMatrix;

				// Apply billboarding if needed
				if (renderer.Billboard != .None && mActiveCamera != null)
				{
					worldMatrix = ComputeBillboardMatrix(transform, renderer.Billboard);
				}

				var command = SpriteRenderCommand()
				{
					Entity = entity,
					WorldMatrix = worldMatrix,
					Renderer = renderer,
					DistanceToCamera = 0,
					SortingLayer = renderer.SortingLayer,
					OrderInLayer = renderer.OrderInLayer
				};

				if (mActiveCamera != null)
				{
					command.DistanceToCamera = Vector3.Distance(transform.Position, mActiveCameraTransform.Position);
				}

				mSpriteCommands.Add(command);
			}
		}
	}

	private Matrix ComputeBillboardMatrix(Transform spriteTransform, SpriteRenderer.BillboardMode mode)
	{
		var position = spriteTransform.WorldPosition;
		var scale = spriteTransform.Scale;
		var scaleMatrix = Matrix.CreateScale(scale);
		var translationMatrix = Matrix.CreateTranslation(position);

		switch (mode)
		{
		case .FacePosition:
			// Position-based: face camera's world position
			var toCamera = mActiveCameraTransform.WorldPosition - position;
			if (toCamera.LengthSquared() < 0.0001f)
				return spriteTransform.WorldMatrix;

			var forward = Vector3.Normalize(toCamera);
			var right = Vector3.Normalize(Vector3.Cross(Vector3.UnitY, forward));
			var up = Vector3.Cross(forward, right);

			var rotationMatrix = Matrix(
				right.X, right.Y, right.Z, 0,
				up.X, up.Y, up.Z, 0,
				forward.X, forward.Y, forward.Z, 0,
				0, 0, 0, 1
			);
			return scaleMatrix * rotationMatrix * translationMatrix;

		case .FacePositionY:
			// Position-based with Y-axis constraint
			var toCameraY = mActiveCameraTransform.WorldPosition - position;
			toCameraY.Y = 0;  // Ignore Y difference
			if (toCameraY.LengthSquared() < 0.0001f)
				return spriteTransform.WorldMatrix;

			var forwardY = Vector3.Normalize(toCameraY);
			var rightY = Vector3.Cross(Vector3.UnitY, forwardY);
			var upY = Vector3.UnitY;

			var rotationMatrixY = Matrix(
				rightY.X, rightY.Y, rightY.Z, 0,
				upY.X, upY.Y, upY.Z, 0,
				forwardY.X, forwardY.Y, forwardY.Z, 0,
				0, 0, 0, 1
			);
			return scaleMatrix * rotationMatrixY * translationMatrix;

		case .ViewAligned:
			// View-aligned: extract camera axes from view matrix (sprite stays screen-aligned)
			// The view matrix transforms world to camera space, so its rows contain camera axes
			var camRight = Vector3(mViewMatrix.M11, mViewMatrix.M21, mViewMatrix.M31);
			var camUp = Vector3(mViewMatrix.M12, mViewMatrix.M22, mViewMatrix.M32);
			var camForward = -Vector3(mViewMatrix.M13, mViewMatrix.M23, mViewMatrix.M33);

			var viewRotationMatrix = Matrix(
				camRight.X, camRight.Y, camRight.Z, 0,
				camUp.X, camUp.Y, camUp.Z, 0,
				camForward.X, camForward.Y, camForward.Z, 0,
				0, 0, 0, 1
			);
			return scaleMatrix * viewRotationMatrix * translationMatrix;

		case .ViewAlignedY:
			// View-aligned with Y-axis constraint (horizontal screen alignment, vertical world-up)
			var camRightYC = Vector3(mViewMatrix.M11, mViewMatrix.M21, mViewMatrix.M31);
			// Project camera right onto XZ plane and normalize
			camRightYC.Y = 0;
			if (camRightYC.LengthSquared() < 0.0001f)
				camRightYC = Vector3.UnitX;  // Fallback if looking straight up/down
			else
				camRightYC = Vector3.Normalize(camRightYC);

			var upYC = Vector3.UnitY;
			var forwardYC = Vector3.Cross(camRightYC, upYC);

			var viewRotationMatrixY = Matrix(
				camRightYC.X, camRightYC.Y, camRightYC.Z, 0,
				upYC.X, upYC.Y, upYC.Z, 0,
				forwardYC.X, forwardYC.Y, forwardYC.Z, 0,
				0, 0, 0, 1
			);
			return scaleMatrix * viewRotationMatrixY * translationMatrix;

		default:
			return spriteTransform.WorldMatrix;
		}
	}

	private void SortSpriteCommands()
	{
		// Sort by: SortingLayer -> OrderInLayer -> Distance (back-to-front for alpha blending)
		mSpriteCommands.Sort(scope (lhs, rhs) => {
			// First by sorting layer
			if (lhs.SortingLayer != rhs.SortingLayer)
				return lhs.SortingLayer <=> rhs.SortingLayer;

			// Then by order in layer
			if (lhs.OrderInLayer != rhs.OrderInLayer)
				return lhs.OrderInLayer <=> rhs.OrderInLayer;

			// Finally by distance (back-to-front)
			return rhs.DistanceToCamera.CompareTo(lhs.DistanceToCamera);
		});
	}

	internal void UpdateSpriteUniforms()
	{
		if (mSpriteCommands.IsEmpty)
			return;

		// Update sprite uniform buffer with all sprite parameters
		var mapped = mRenderer.GraphicsContext.MapMemory(mRenderer.SpriteVertexCB, MapMode.Write);

		const int32 ALIGNMENT = 256;
		int32 alignedSize = ((sizeof(SpriteVertexUniforms) + ALIGNMENT - 1) / ALIGNMENT) * ALIGNMENT;

		int writeIndex = 0;
		for (var command in mSpriteCommands)
		{
			var renderer = command.Renderer;
			var size = renderer.GetRenderSize();
			var pivot = renderer.Pivot;

			// Get UVs (handles source rect and flipping)
			Vector2 uvMin, uvMax;
			renderer.GetUVs(out uvMin, out uvMax);

			// Get tint color as Vector4
			var tintColor = renderer.Color.ToVector4();

			var vertexUniforms = SpriteVertexUniforms()
			{
				MVPMatrix = command.WorldMatrix * mViewMatrix * mProjectionMatrix,
				SpriteParams = Vector4(size.X, size.Y, pivot.X, pivot.Y),
				UVBounds = Vector4(uvMin.X, uvMin.Y, uvMax.X, uvMax.Y),
				TintColor = tintColor
			};

			SpriteVertexUniforms* dest = (SpriteVertexUniforms*)((uint8*)mapped.Data + writeIndex * alignedSize);
			*dest = vertexUniforms;
			writeIndex++;
		}

		mRenderer.GraphicsContext.UnmapMemory(mRenderer.SpriteVertexCB);
	}

	internal void RenderSprites(CommandBuffer commandBuffer)
	{
		if (mSpriteCommands.IsEmpty)
			return;

		commandBuffer.SetGraphicsPipelineState(mRenderer.SpritePipeline);

		// Set static vertex and index buffers once for all sprites
		commandBuffer.SetVertexBuffers(scope Buffer[](mRenderer.SpriteQuadVertexBuffer));
		commandBuffer.SetIndexBuffer(mRenderer.SpriteQuadIndexBuffer, .UInt16);

		const int32 ALIGNMENT = 256;
		int32 alignedSize = ((sizeof(SpriteVertexUniforms) + ALIGNMENT - 1) / ALIGNMENT) * ALIGNMENT;

		// Render each sprite using the static quad
		int uniformIndex = 0;
		for (var command in mSpriteCommands)
		{
			// Set per-sprite resource set with dynamic offset
			uint32 dynamicOffset = (uint32)(uniformIndex * alignedSize);
			commandBuffer.SetResourceSet(mRenderer.SpritePerObjectResourceSet, 0, scope .(dynamicOffset));

			// Get or create sprite material resource set (for texture binding)
			var materialResourceSet = mCache.GetOrCreateSpriteResourceSet(command.Renderer);
			if (materialResourceSet != null)
				commandBuffer.SetResourceSet(materialResourceSet, 1);
			else
				commandBuffer.SetResourceSet(mRenderer.DefaultSpriteMaterialResourceSet, 1);

			// Draw the static unit quad (vertex shader applies size/pivot/UV transforms)
			commandBuffer.DrawIndexed(6);

			mStatistics.DrawCalls++;
			mStatistics.TriangleCount += 2;
			mStatistics.ObjectsRendered++;

			uniformIndex++;
		}
	}

	private Viewport[] mPickingViewports = new .[1] ~ delete _;
	private Rectangle[] mPickingScissorRectangles = new .[1] ~ delete _;

	/// Render all objects to the picking buffer with their entity IDs
	internal void RenderForPicking(CommandBuffer commandBuffer, FrameBuffer pickingFrameBuffer)
	{
		if (!mRenderer.PickingResourcesCreated)
			return;

		// Update picking uniforms
		UpdatePickingUniforms();

		const int32 ALIGNMENT = 256;
		int32 alignedSize = ((sizeof(PickingUniforms) + ALIGNMENT - 1) / ALIGNMENT) * ALIGNMENT;

		// Begin picking render pass
		// Clear to 0 (invalid entity ID) - R32_UInt interprets float bits as uint
		var clearValue = ClearValue(.Target | .Depth, 1.0f, 0, Vector4(0, 0, 0, 0));
		var pickingPassDesc = RenderPassDescription(pickingFrameBuffer, clearValue);
		commandBuffer.BeginRenderPass(pickingPassDesc);

		// Set viewport and scissors to match picking target
		mPickingViewports[0] = Viewport(0, 0, mRenderer.Width, mRenderer.Height);
		mPickingScissorRectangles[0] = Rectangle(0, 0, (.)mRenderer.Width, (.)mRenderer.Height);
		commandBuffer.SetViewports(mPickingViewports);
		commandBuffer.SetScissorRectangles(mPickingScissorRectangles);

		int uniformIndex = 0;

		// Render opaque meshes
		if (!mOpaqueMeshCommands.IsEmpty)
		{
			commandBuffer.SetGraphicsPipelineState(mRenderer.PickingPipeline);

			for (var command in mOpaqueMeshCommands)
			{
				// Set picking resource set with dynamic offset
				uint32 dynamicOffset = (uint32)(uniformIndex * alignedSize);
				commandBuffer.SetResourceSet(mRenderer.PickingResourceSet, 0, scope .(dynamicOffset));

				// Render mesh
				RenderMeshForPicking(command, commandBuffer);
				uniformIndex++;
			}
		}

		// Render transparent meshes (included for picking even though they're transparent)
		if (!mTransparentMeshCommands.IsEmpty)
		{
			commandBuffer.SetGraphicsPipelineState(mRenderer.PickingPipeline);

			for (var command in mTransparentMeshCommands)
			{
				uint32 dynamicOffset = (uint32)(uniformIndex * alignedSize);
				commandBuffer.SetResourceSet(mRenderer.PickingResourceSet, 0, scope .(dynamicOffset));

				RenderMeshForPicking(command, commandBuffer);
				uniformIndex++;
			}
		}

		// Render opaque skinned meshes
		if (!mOpaqueSkinnedCommands.IsEmpty)
		{
			commandBuffer.SetGraphicsPipelineState(mRenderer.SkinnedPickingPipeline);

			for (var command in mOpaqueSkinnedCommands)
			{
				uint32 dynamicOffset = (uint32)(uniformIndex * alignedSize);
				commandBuffer.SetResourceSet(mRenderer.PickingResourceSet, 0, scope .(dynamicOffset));

				// Set bone matrices resource set (Set 1 for skinned picking)
				if (mCache.TryGetBoneResourceSet(command.Animator, let boneResourceSet))
				{
					commandBuffer.SetResourceSet(boneResourceSet, 1);
				}

				RenderSkinnedMeshForPicking(command, commandBuffer);
				uniformIndex++;
			}
		}

		// Render transparent skinned meshes
		if (!mTransparentSkinnedCommands.IsEmpty)
		{
			commandBuffer.SetGraphicsPipelineState(mRenderer.SkinnedPickingPipeline);

			for (var command in mTransparentSkinnedCommands)
			{
				uint32 dynamicOffset = (uint32)(uniformIndex * alignedSize);
				commandBuffer.SetResourceSet(mRenderer.PickingResourceSet, 0, scope .(dynamicOffset));

				if (mCache.TryGetBoneResourceSet(command.Animator, let boneResourceSet))
				{
					commandBuffer.SetResourceSet(boneResourceSet, 1);
				}

				RenderSkinnedMeshForPicking(command, commandBuffer);
				uniformIndex++;
			}
		}

		// Render sprites
		if (!mSpriteCommands.IsEmpty && mRenderer.SpritePickingPipeline != null)
		{
			commandBuffer.SetGraphicsPipelineState(mRenderer.SpritePickingPipeline);

			// Set static vertex and index buffers for sprites
			commandBuffer.SetVertexBuffers(scope Buffer[](mRenderer.SpriteQuadVertexBuffer));
			commandBuffer.SetIndexBuffer(mRenderer.SpriteQuadIndexBuffer, .UInt16);

			const int32 PICKING_ALIGNMENT = 256;
			int32 pickingAlignedSize = ((sizeof(PickingUniforms) + PICKING_ALIGNMENT - 1) / PICKING_ALIGNMENT) * PICKING_ALIGNMENT;

			const int32 SPRITE_ALIGNMENT = 256;
			int32 spriteAlignedSize = ((sizeof(Vector4) + SPRITE_ALIGNMENT - 1) / SPRITE_ALIGNMENT) * SPRITE_ALIGNMENT;

			int spriteIndex = 0;
			for (var command in mSpriteCommands)
			{
				// Dynamic offsets for both picking uniforms and sprite params
				uint32 pickingOffset = (uint32)((mSpritePickingStartIndex + spriteIndex) * pickingAlignedSize);
				uint32 spriteOffset = (uint32)(spriteIndex * spriteAlignedSize);

				commandBuffer.SetResourceSet(mRenderer.SpritePickingResourceSet, 0, scope .(pickingOffset, spriteOffset));

				// Draw the sprite quad
				commandBuffer.DrawIndexed(6);
				spriteIndex++;
			}
		}

		commandBuffer.EndRenderPass();
	}

	// Track sprite picking uniform start index (after mesh uniforms)
	private int mSpritePickingStartIndex = 0;

	private void UpdatePickingUniforms()
	{
		int meshCommands = mOpaqueMeshCommands.Count + mTransparentMeshCommands.Count +
							mOpaqueSkinnedCommands.Count + mTransparentSkinnedCommands.Count;
		int spriteCommands = mSpriteCommands.Count;
		if (meshCommands == 0 && spriteCommands == 0)
			return;

		// Map picking uniform buffer
		var mapped = mRenderer.GraphicsContext.MapMemory(mRenderer.PickingUniformBuffer, MapMode.Write);
		if (mapped.Data == null)
			return;

		const int32 ALIGNMENT = 256;
		int32 alignedSize = ((sizeof(PickingUniforms) + ALIGNMENT - 1) / ALIGNMENT) * ALIGNMENT;

		int writeIndex = 0;

		// Write opaque mesh picking uniforms
		for (var command in mOpaqueMeshCommands)
		{
			var pickingUniforms = PickingUniforms()
			{
				MVPMatrix = command.WorldMatrix * mViewMatrix * mProjectionMatrix,
				EntityId = (uint32)command.Entity.Id,
				Padding0 = 0,
				Padding1 = 0,
				Padding2 = 0
			};

			PickingUniforms* dest = (PickingUniforms*)((uint8*)mapped.Data + writeIndex * alignedSize);
			*dest = pickingUniforms;
			writeIndex++;
		}

		// Write transparent mesh picking uniforms
		for (var command in mTransparentMeshCommands)
		{
			var pickingUniforms = PickingUniforms()
			{
				MVPMatrix = command.WorldMatrix * mViewMatrix * mProjectionMatrix,
				EntityId = (uint32)command.Entity.Id,
				Padding0 = 0,
				Padding1 = 0,
				Padding2 = 0
			};

			PickingUniforms* dest = (PickingUniforms*)((uint8*)mapped.Data + writeIndex * alignedSize);
			*dest = pickingUniforms;
			writeIndex++;
		}

		// Write opaque skinned mesh picking uniforms
		for (var command in mOpaqueSkinnedCommands)
		{
			var pickingUniforms = PickingUniforms()
			{
				MVPMatrix = command.WorldMatrix * mViewMatrix * mProjectionMatrix,
				EntityId = (uint32)command.Entity.Id,
				Padding0 = 0,
				Padding1 = 0,
				Padding2 = 0
			};

			PickingUniforms* dest = (PickingUniforms*)((uint8*)mapped.Data + writeIndex * alignedSize);
			*dest = pickingUniforms;
			writeIndex++;
		}

		// Write transparent skinned mesh picking uniforms
		for (var command in mTransparentSkinnedCommands)
		{
			var pickingUniforms = PickingUniforms()
			{
				MVPMatrix = command.WorldMatrix * mViewMatrix * mProjectionMatrix,
				EntityId = (uint32)command.Entity.Id,
				Padding0 = 0,
				Padding1 = 0,
				Padding2 = 0
			};

			PickingUniforms* dest = (PickingUniforms*)((uint8*)mapped.Data + writeIndex * alignedSize);
			*dest = pickingUniforms;
			writeIndex++;
		}

		// Record where sprite uniforms start
		mSpritePickingStartIndex = writeIndex;

		// Write sprite picking uniforms
		for (var command in mSpriteCommands)
		{
			var pickingUniforms = PickingUniforms()
			{
				MVPMatrix = command.WorldMatrix * mViewMatrix * mProjectionMatrix,
				EntityId = (uint32)command.Entity.Id,
				Padding0 = 0,
				Padding1 = 0,
				Padding2 = 0
			};

			PickingUniforms* dest = (PickingUniforms*)((uint8*)mapped.Data + writeIndex * alignedSize);
			*dest = pickingUniforms;
			writeIndex++;
		}

		mRenderer.GraphicsContext.UnmapMemory(mRenderer.PickingUniformBuffer);

		// Also populate sprite params buffer
		if (mSpriteCommands.Count > 0)
		{
			var spriteParamsMapped = mRenderer.GraphicsContext.MapMemory(mRenderer.SpritePickingParamsBuffer, MapMode.Write);
			if (spriteParamsMapped.Data != null)
			{
				const int32 SPRITE_ALIGNMENT = 256;
				int32 spriteAlignedSize = ((sizeof(Vector4) + SPRITE_ALIGNMENT - 1) / SPRITE_ALIGNMENT) * SPRITE_ALIGNMENT;

				int spriteIndex = 0;
				for (var command in mSpriteCommands)
				{
					var renderer = command.Renderer;
					var size = renderer.GetRenderSize();
					var pivot = renderer.Pivot;

					var spriteParams = Vector4(size.X, size.Y, pivot.X, pivot.Y);

					Vector4* dest = (Vector4*)((uint8*)spriteParamsMapped.Data + spriteIndex * spriteAlignedSize);
					*dest = spriteParams;
					spriteIndex++;
				}

				mRenderer.GraphicsContext.UnmapMemory(mRenderer.SpritePickingParamsBuffer);
			}
		}
	}

	private void RenderMeshForPicking(MeshRenderCommand command, CommandBuffer commandBuffer)
	{
		if (!mCache.TryGetMesh(command.Renderer, let meshHandle) || !meshHandle.IsValid)
			return;

		var mesh = meshHandle.Resource;
		commandBuffer.SetVertexBuffers(scope Buffer[](mesh.VertexBuffer));

		if (mesh.IndexBuffer != null && mesh.IndexCount > 0)
		{
			commandBuffer.SetIndexBuffer(mesh.IndexBuffer, .UInt32);
			commandBuffer.DrawIndexed(mesh.IndexCount);
		}
		else
		{
			commandBuffer.Draw(mesh.VertexCount);
		}
	}

	private void RenderSkinnedMeshForPicking(SkinnedMeshRenderCommand command, CommandBuffer commandBuffer)
	{
		if (!mCache.TryGetSkinnedMesh(command.Renderer, let meshHandle) || !meshHandle.IsValid)
			return;

		var mesh = meshHandle.Resource;
		commandBuffer.SetVertexBuffers(scope Buffer[](mesh.VertexBuffer));

		if (mesh.IndexBuffer != null && mesh.IndexCount > 0)
		{
			commandBuffer.SetIndexBuffer(mesh.IndexBuffer, .UInt32);
			commandBuffer.DrawIndexed(mesh.IndexCount);
		}
		else
		{
			commandBuffer.Draw(mesh.VertexCount);
		}
	}

	// Cached outline render data (set during UpdateOutlineUniforms, used during RenderOutline)
	private MeshRenderCommand? mOutlineMeshCommand = null;
	private SkinnedMeshRenderCommand? mOutlineSkinnedCommand = null;
	private SpriteRenderCommand? mOutlineSpriteCommand = null;  // Sprites don't use inverted hull, but track for future

	/// Update outline uniform buffer (must be called outside render pass)
	internal void UpdateOutlineUniforms(CommandBuffer commandBuffer)
	{
		var selectedEntity = mRenderer.SelectedEntity;
		mOutlineMeshCommand = null;
		mOutlineSkinnedCommand = null;
		mOutlineSpriteCommand = null;

		if (selectedEntity == null)
			return;

		// Find the selected entity in our render commands and cache it
		// Try static meshes first
		for (var command in mOpaqueMeshCommands)
		{
			if (command.Entity == selectedEntity)
			{
				mOutlineMeshCommand = command;
				break;
			}
		}

		if (mOutlineMeshCommand == null)
		{
			for (var command in mTransparentMeshCommands)
			{
				if (command.Entity == selectedEntity)
				{
					mOutlineMeshCommand = command;
					break;
				}
			}
		}

		// Try skinned meshes if not found in static
		if (mOutlineMeshCommand == null)
		{
			for (var command in mOpaqueSkinnedCommands)
			{
				if (command.Entity == selectedEntity)
				{
					mOutlineSkinnedCommand = command;
					break;
				}
			}

			if (mOutlineSkinnedCommand == null)
			{
				for (var command in mTransparentSkinnedCommands)
				{
					if (command.Entity == selectedEntity)
					{
						mOutlineSkinnedCommand = command;
						break;
					}
				}
			}
		}

		// Try sprites if not found in meshes
		// Note: Sprites don't support inverted hull outline - would need different technique
		if (mOutlineMeshCommand == null && mOutlineSkinnedCommand == null)
		{
			for (var command in mSpriteCommands)
			{
				if (command.Entity == selectedEntity)
				{
					mOutlineSpriteCommand = command;
					break;
				}
			}
		}

		// Update the uniform buffer with the found command
		if (mOutlineMeshCommand != null)
		{
			var cmd = mOutlineMeshCommand.Value;
			// Extract approximate scale from world matrix to make outline thickness scale-independent
			float scaleX = Vector3(cmd.WorldMatrix.M11, cmd.WorldMatrix.M12, cmd.WorldMatrix.M13).Length();
			float scaleY = Vector3(cmd.WorldMatrix.M21, cmd.WorldMatrix.M22, cmd.WorldMatrix.M23).Length();
			float scaleZ = Vector3(cmd.WorldMatrix.M31, cmd.WorldMatrix.M32, cmd.WorldMatrix.M33).Length();
			float avgScale = (scaleX + scaleY + scaleZ) / 3.0f;
			float adjustedThickness = mRenderer.OutlineThickness / Math.Max(avgScale, 0.001f);

			var outlineUniforms = OutlineUniforms()
			{
				MVPMatrix = cmd.WorldMatrix * mViewMatrix * mProjectionMatrix,
				ModelMatrix = cmd.WorldMatrix,
				OutlineColor = mRenderer.OutlineColor,
				OutlineThickness = adjustedThickness,
				Padding0 = 0,
				Padding1 = 0,
				Padding2 = 0
			};
			commandBuffer.UpdateBufferData(mRenderer.OutlineUniformBuffer, &outlineUniforms, (uint32)sizeof(OutlineUniforms));
		}
		else if (mOutlineSkinnedCommand != null)
		{
			var cmd = mOutlineSkinnedCommand.Value;
			// Extract approximate scale from world matrix to make outline thickness scale-independent
			float scaleX = Vector3(cmd.WorldMatrix.M11, cmd.WorldMatrix.M12, cmd.WorldMatrix.M13).Length();
			float scaleY = Vector3(cmd.WorldMatrix.M21, cmd.WorldMatrix.M22, cmd.WorldMatrix.M23).Length();
			float scaleZ = Vector3(cmd.WorldMatrix.M31, cmd.WorldMatrix.M32, cmd.WorldMatrix.M33).Length();
			float avgScale = (scaleX + scaleY + scaleZ) / 3.0f;
			float adjustedThickness = mRenderer.OutlineThickness / Math.Max(avgScale, 0.001f);

			var outlineUniforms = OutlineUniforms()
			{
				MVPMatrix = cmd.WorldMatrix * mViewMatrix * mProjectionMatrix,
				ModelMatrix = cmd.WorldMatrix,
				OutlineColor = mRenderer.OutlineColor,
				OutlineThickness = adjustedThickness,
				Padding0 = 0,
				Padding1 = 0,
				Padding2 = 0
			};
			commandBuffer.UpdateBufferData(mRenderer.OutlineUniformBuffer, &outlineUniforms, (uint32)sizeof(OutlineUniforms));
		}
	}

	/// Render outline for the currently selected entity
	internal void RenderOutline(CommandBuffer commandBuffer)
	{
		if (mOutlineMeshCommand != null)
		{
			RenderMeshOutline(mOutlineMeshCommand.Value, commandBuffer);
		}
		else if (mOutlineSkinnedCommand != null)
		{
			RenderSkinnedMeshOutline(mOutlineSkinnedCommand.Value, commandBuffer);
		}
	}

	private void RenderMeshOutline(MeshRenderCommand command, CommandBuffer commandBuffer)
	{
		if (!mCache.TryGetMesh(command.Renderer, let meshHandle) || !meshHandle.IsValid)
			return;

		// Set pipeline and resource set (uniform buffer already updated in UpdateOutlineUniforms)
		commandBuffer.SetGraphicsPipelineState(mRenderer.OutlinePipeline);
		commandBuffer.SetResourceSet(mRenderer.OutlineResourceSet, 0);

		// Render the mesh
		var mesh = meshHandle.Resource;
		commandBuffer.SetVertexBuffers(scope Buffer[](mesh.VertexBuffer));

		if (mesh.IndexBuffer != null && mesh.IndexCount > 0)
		{
			commandBuffer.SetIndexBuffer(mesh.IndexBuffer, .UInt32);
			commandBuffer.DrawIndexed(mesh.IndexCount);
		}
		else
		{
			commandBuffer.Draw(mesh.VertexCount);
		}

		mStatistics.DrawCalls++;
	}

	private void RenderSkinnedMeshOutline(SkinnedMeshRenderCommand command, CommandBuffer commandBuffer)
	{
		if (!mCache.TryGetSkinnedMesh(command.Renderer, let meshHandle) || !meshHandle.IsValid)
			return;

		// Set pipeline and resource sets (uniform buffer already updated in UpdateOutlineUniforms)
		commandBuffer.SetGraphicsPipelineState(mRenderer.SkinnedOutlinePipeline);
		commandBuffer.SetResourceSet(mRenderer.OutlineResourceSet, 0);

		// Set bone matrices resource set (Set 1 for skinned outline)
		if (mCache.TryGetBoneResourceSet(command.Animator, let boneResourceSet))
		{
			commandBuffer.SetResourceSet(boneResourceSet, 1);
		}
		else
		{
			return;  // Can't render without bones
		}

		// Render the mesh
		var mesh = meshHandle.Resource;
		commandBuffer.SetVertexBuffers(scope Buffer[](mesh.VertexBuffer));

		if (mesh.IndexBuffer != null && mesh.IndexCount > 0)
		{
			commandBuffer.SetIndexBuffer(mesh.IndexBuffer, .UInt32);
			commandBuffer.DrawIndexed(mesh.IndexCount);
		}
		else
		{
			commandBuffer.Draw(mesh.VertexCount);
		}

		mStatistics.DrawCalls++;
	}
}