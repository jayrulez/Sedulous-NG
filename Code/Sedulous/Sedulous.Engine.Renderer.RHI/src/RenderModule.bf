using Sedulous.SceneGraph;
using System;
using Sedulous.Engine.Core;
using Sedulous.RHI;
using Sedulous.Mathematics;
using System.Collections;
using Sedulous.Engine.Renderer.GPU;
using Sedulous.Utilities;
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

		// Create view frustum for culling
		if (mActiveCamera != null)
		{
			mViewFrustum = BoundingFrustum(mViewMatrix * mProjectionMatrix);
		}

		// Collect render commands (with frustum culling and transparency separation)
		CollectRenderCommands();
		CollectSkinnedRenderCommands();

		// Sort render commands
		SortRenderCommands();

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
}