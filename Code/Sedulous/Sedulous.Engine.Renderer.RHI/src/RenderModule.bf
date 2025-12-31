using Sedulous.SceneGraph;
using System;
using Sedulous.Engine.Core;
using Sedulous.RHI;
using Sedulous.Mathematics;
using System.Collections;
using Sedulous.Engine.Renderer.GPU;
using Sedulous.Utilities;
namespace Sedulous.Engine.Renderer.RHI;

struct MeshRenderCommand
{
	public Entity Entity;
	public Matrix WorldMatrix;
	public MeshRenderer Renderer;
	public float DistanceToCamera;
}

struct SkinnedMeshRenderCommand
{
	public Entity Entity;
	public Matrix WorldMatrix;
	public SkinnedMeshRenderer Renderer;
	public Animator Animator;
	public float DistanceToCamera;
}

class RenderModule : SceneModule
{
	public override StringView Name => "Render";

	private RHIRendererSubsystem mRenderer;
	private RenderCache mCache;

	// Render command lists (rebuilt each frame)
	private List<MeshRenderCommand> mMeshCommands = new .() ~ delete _;
	private List<SkinnedMeshRenderCommand> mSkinnedMeshCommands = new .() ~ delete _;

	// Current frame data
	private Camera mActiveCamera;
	private Transform mActiveCameraTransform;
	private Matrix mViewMatrix;
	private Matrix mProjectionMatrix;

	// Lighting data
	private LightingUniforms mCurrentLighting;

	private EntityQuery mMeshesQuery;
	private EntityQuery mSkinnedMeshesQuery;
	private EntityQuery mCamerasQuery;
	private EntityQuery mDirectionalLightsQuery;

	public this(RHIRendererSubsystem renderer)
	{
		mRenderer = renderer;
		mCache = new RenderCache(renderer, renderer.GPUResources);

		mMeshesQuery = CreateQuery().With<MeshRenderer>();
		mSkinnedMeshesQuery = CreateQuery().With<SkinnedMeshRenderer>().With<Animator>();
		mCamerasQuery = CreateQuery().With<Camera>();
		mDirectionalLightsQuery = CreateQuery().With<DirectionalLight>();

		// Initialize default lighting
		mCurrentLighting = .()
		{
			DirectionalLightDir = Vector4(0.5f, -1.0f, 0.3f, 0),
			DirectionalLightColor = Vector4(1.0f, 0.95f, 0.9f, 1.0f),
			AmbientLight = Vector4(0.1f, 0.1f, 0.15f, 0)
		};
	}

	public ~this()
	{
		delete mCache;

		DestroyQuery(mMeshesQuery);
		DestroyQuery(mSkinnedMeshesQuery);
		DestroyQuery(mCamerasQuery);
		DestroyQuery(mDirectionalLightsQuery);
	}

	protected override void OnUpdate(Time time)
	{
		// Find active camera and lights
		UpdateActiveCamera();
		UpdateLighting();

		// Clear render commands
		mMeshCommands.Clear();
		mSkinnedMeshCommands.Clear();

		// Collect render commands
		CollectRenderCommands();
		CollectSkinnedRenderCommands();

		// Sort render commands
		SortRenderCommands();
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
	}

	internal void RenderFrame(IEngine.UpdateInfo info, CommandBuffer commandBuffer)
	{
		PrepareGPUResources(commandBuffer);

		// Update lighting buffer
		commandBuffer.UpdateBufferData(mRenderer.LightingBuffer, &mCurrentLighting, (uint32)sizeof(LightingUniforms));

		RenderMeshes(commandBuffer);
		RenderSkinnedMeshes(commandBuffer);
	}

	internal void PrepareGPUResources(CommandBuffer commandBuffer)
	{
		// Create GPU resources for any new mesh renderers
		for (var command in mMeshCommands)
		{
			mCache.GetOrCreateMesh(command.Renderer);

			var materialHandle = mCache.GetOrCreateMaterial(command.Renderer);
			if (materialHandle.IsValid)
				materialHandle.Resource.UpdateUniformData(commandBuffer);
		}

		// Prepare skinned mesh GPU resources
		for (var command in mSkinnedMeshCommands)
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

	private void UpdateVertexUniforms()
	{
		if (mMeshCommands.IsEmpty)
			return;

		// Update all object data at once
		var mapped = mRenderer.GraphicsContext.MapMemory(mRenderer.UnlitVertexCB, MapMode.Write);

		const int32 ALIGNMENT = 256;
		int32 alignedSize = ((sizeof(UnlitVertexUniforms) + ALIGNMENT - 1) / ALIGNMENT) * ALIGNMENT;

		for (int i = 0; i < mMeshCommands.Count; i++)
		{
			var command = mMeshCommands[i];
			var vertexUniforms = UnlitVertexUniforms()
				{
					MVPMatrix = command.WorldMatrix * mViewMatrix * mProjectionMatrix,
					ModelMatrix = command.WorldMatrix
				};

			// Write to the aligned offset
			UnlitVertexUniforms* dest = (UnlitVertexUniforms*)((uint8*)mapped.Data + i * alignedSize);
			*dest = vertexUniforms;
		}

		mRenderer.GraphicsContext.UnmapMemory(mRenderer.UnlitVertexCB);
	}

	internal void RenderMeshes(CommandBuffer commandBuffer)
	{
		if (mMeshCommands.IsEmpty)
			return;

		// Render pass is already begun by rendergraph
		commandBuffer.SetGraphicsPipelineState(mRenderer.UnlitPipeline);

		const int32 ALIGNMENT = 256;
		int32 alignedSize = ((sizeof(UnlitVertexUniforms) + ALIGNMENT - 1) / ALIGNMENT) * ALIGNMENT;

		GPUMaterial currentMaterial = null;

		for (int i = 0; i < mMeshCommands.Count; i++)
		{
			var command = mMeshCommands[i];

			// Get the material for this object
			if (mCache.TryGetMaterial(command.Renderer, let materialHandle))
			{
				var gpuMaterial = materialHandle.Resource;

				// Only update if material changed (batching)
				if (gpuMaterial != currentMaterial)
				{
					currentMaterial = gpuMaterial;

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
				commandBuffer.SetResourceSet(mRenderer.DefaultUnlitMaterialResourceSet, 1);
			}

			// Set resource set with dynamic offset
			uint32 dynamicOffset = (uint32)(i * alignedSize);
			commandBuffer.SetResourceSet(mRenderer.UnlitResourceSet, 0, scope .(dynamicOffset));

			RenderMesh(command, commandBuffer);
		}
		// Render pass will be ended by rendergraph
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

	private void CollectRenderCommands()
	{
		for (var entity in mMeshesQuery.GetEntities(Scene, .. scope .()))
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

	private void CollectSkinnedRenderCommands()
	{
		for (var entity in mSkinnedMeshesQuery.GetEntities(Scene, .. scope .()))
		{
			if (entity.HasComponent<SkinnedMeshRenderer>() && entity.HasComponent<Animator>())
			{
				var renderer = entity.GetComponent<SkinnedMeshRenderer>();
				var animator = entity.GetComponent<Animator>();
				var transform = entity.Transform;

				var command = SkinnedMeshRenderCommand()
					{
						Entity = entity,
						WorldMatrix = transform.WorldMatrix,
						Renderer = renderer,
						Animator = animator,
						DistanceToCamera = 0
					};

				if (mActiveCamera != null)
				{
					command.DistanceToCamera = Vector3.Distance(transform.Position, mActiveCameraTransform.Position);
				}

				mSkinnedMeshCommands.Add(command);
			}
		}
	}

	private void SortRenderCommands()
	{
		// Sort front-to-back for better depth rejection
		mMeshCommands.Sort(scope (lhs, rhs) => lhs.DistanceToCamera.CompareTo(rhs.DistanceToCamera));
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
		}
		else
		{
			commandBuffer.Draw(mesh.VertexCount);
		}
	}

	private void UpdateSkinnedVertexUniforms()
	{
		if (mSkinnedMeshCommands.IsEmpty)
			return;

		// Update all object data at once
		var mapped = mRenderer.GraphicsContext.MapMemory(mRenderer.UnlitVertexCB, MapMode.Write);

		const int32 ALIGNMENT = 256;
		int32 alignedSize = ((sizeof(UnlitVertexUniforms) + ALIGNMENT - 1) / ALIGNMENT) * ALIGNMENT;

		// Offset to place after regular mesh uniforms
		int startOffset = mMeshCommands.Count;

		for (int i = 0; i < mSkinnedMeshCommands.Count; i++)
		{
			var command = mSkinnedMeshCommands[i];
			var vertexUniforms = UnlitVertexUniforms()
				{
					MVPMatrix = command.WorldMatrix * mViewMatrix * mProjectionMatrix,
					ModelMatrix = command.WorldMatrix
				};

			// Write to the aligned offset
			UnlitVertexUniforms* dest = (UnlitVertexUniforms*)((uint8*)mapped.Data + (startOffset + i) * alignedSize);
			*dest = vertexUniforms;
		}

		mRenderer.GraphicsContext.UnmapMemory(mRenderer.UnlitVertexCB);

		// Update bone matrices for each animator
		for (var command in mSkinnedMeshCommands)
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
	}

	internal void RenderSkinnedMeshes(CommandBuffer commandBuffer)
	{
		if (mSkinnedMeshCommands.IsEmpty)
			return;

		const int32 ALIGNMENT = 256;
		int32 alignedSize = ((sizeof(UnlitVertexUniforms) + ALIGNMENT - 1) / ALIGNMENT) * ALIGNMENT;
		int startOffset = mMeshCommands.Count;

		GPUMaterial currentMaterial = null;
		StringView currentShaderName = default;

		for (int i = 0; i < mSkinnedMeshCommands.Count; i++)
		{
			var command = mSkinnedMeshCommands[i];

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
			uint32 dynamicOffset = (uint32)((startOffset + i) * alignedSize);
			commandBuffer.SetResourceSet(mRenderer.UnlitResourceSet, 0, scope .(dynamicOffset));

			// Set bone matrices resource set
			if (mCache.TryGetBoneResourceSet(command.Animator, let boneResourceSet))
			{
				commandBuffer.SetResourceSet(boneResourceSet, 2);
			}

			RenderSkinnedMesh(command, commandBuffer);
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
		}
		else
		{
			commandBuffer.Draw(mesh.VertexCount);
		}
	}
}