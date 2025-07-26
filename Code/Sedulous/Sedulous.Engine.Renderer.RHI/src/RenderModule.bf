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

class RenderModule: SceneModule
{
	public override StringView Name => "Render";

	private RHIRendererSubsystem mRenderer;

	// 3D rendering
	private List<MeshRenderCommand> mMeshCommands = new .() ~ delete _;
	private Dictionary<MeshRenderer, GPUResourceHandle<GPUMesh>> mRendererMeshes = new .() ~ delete _;
	private Dictionary<MeshRenderer, GPUResourceHandle<GPUMaterial>> mRendererMaterials = new .() ~ delete _;
	
	// Current frame data
	private Camera mActiveCamera;
	private Transform mActiveCameraTransform;
	private Matrix mViewMatrix;
	private Matrix mProjectionMatrix;
	
	private EntityQuery mMeshesQuery;
	private EntityQuery mCamerasQuery;

	public this(RHIRendererSubsystem renderer)
	{
		mRenderer = renderer;
		
		mMeshesQuery = CreateQuery().With<MeshRenderer>();
		mCamerasQuery = CreateQuery().With<Camera>();
	}

	public ~this()
	{
		for (var entry in mRendererMaterials)
		{
			entry.value.Release();
		}

		for (var entry in mRendererMeshes)
		{
			entry.value.Release();
		}
		
		DestroyQuery(mMeshesQuery);
		DestroyQuery(mCamerasQuery);
	}

	protected override void OnUpdate(Time time)
	{
		// Find active camera and lights
		UpdateActiveCamera();

		// Clear render commands
		mMeshCommands.Clear();

		// Collect render commands
		CollectRenderCommands();

		// Sort render commands
		SortRenderCommands();
	}

	internal void RenderFrame(IEngine.UpdateInfo info, CommandBuffer commandBuffer)
	{
		PrepareGPUResources();

		/*var perFrameData = PerFrameData()
			{
				ViewMatrix = mViewMatrix,
				ProjectionMatrix = mProjectionMatrix,
				ViewProjectionMatrix = mViewMatrix * mProjectionMatrix
			};

		mRenderer.GraphicsContext.UpdateBufferData<PerFrameData>(mRenderer.PerFrameConstantBuffer, scope PerFrameData[](perFrameData));*/

		RenderMeshes(commandBuffer);
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

	private void SortRenderCommands()
	{
		// Sort front-to-back for better depth rejection
		mMeshCommands.Sort(scope (lhs, rhs) => lhs.DistanceToCamera.CompareTo(rhs.DistanceToCamera));
	}

	private void RenderMeshes(CommandBuffer commandBuffer)
	{
		if (mMeshCommands.IsEmpty)
			return;

		// Update all object data at once
		var mapped = mRenderer.GraphicsContext.MapMemory(mRenderer.PerObjectConstantBuffer, MapMode.Write);

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

		mRenderer.GraphicsContext.UnmapMemory(mRenderer.PerObjectConstantBuffer);

		RenderPassDescription renderPass = RenderPassDescription(mRenderer.SwapChainFrameBuffer, ClearValue.None);
		commandBuffer.BeginRenderPass(renderPass);
		commandBuffer.SetGraphicsPipelineState(mRenderer.UnlitPipeline);
		//commandBuffer.SetResourceSet(mRenderer.UnlitResourceSet);
		for (int i = 0; i < mMeshCommands.Count; i++)
		{
			var command = mMeshCommands[i];
			// Set resource set with dynamic offset
			uint32 dynamicOffset = (uint32)(i * alignedSize);
			commandBuffer.SetResourceSet(mRenderer.UnlitResourceSet, 0, scope .(dynamicOffset));

			RenderMesh(command, commandBuffer);
		}
		commandBuffer.EndRenderPass();
	}

	private void RenderMesh(MeshRenderCommand command, CommandBuffer commandBuffer)
	{
		if (!mRendererMeshes.TryGetValue(command.Renderer, let meshHandle) || !meshHandle.IsValid)
			return;

		var mesh = meshHandle.Resource;

		// Get mesh data
		Buffer vertexBuffer = mesh.VertexBuffer;
		Buffer indexBuffer = mesh.IndexBuffer;
		uint32 indexCount = mesh.IndexCount;

		/*var vertexUniforms = UnlitVertexUniforms()
			{
				MVPMatrix = command.WorldMatrix * mViewMatrix * mProjectionMatrix,
				//MVPMatrix =  mProjectionMatrix * mViewMatrix *command.WorldMatrix,
				ModelMatrix = command.WorldMatrix
			};

		mRenderer.GraphicsContext.UpdateBufferData<UnlitVertexUniforms>(mRenderer.PerObjectConstantBuffer, scope UnlitVertexUniforms[](vertexUniforms));
		mRenderer.GraphicsContext.SyncUpcopyQueue();*/


		commandBuffer.SetVertexBuffers(scope Buffer[](vertexBuffer));
		commandBuffer.SetIndexBuffer(indexBuffer, .UInt32);

		commandBuffer.DrawIndexed(indexCount);
	}

	private void PrepareGPUResources()
	{
		var resourceManager = mRenderer.GPUResources;

		// Create GPU resources for any new mesh renderers
		for (var command in mMeshCommands)
		{
			// Get or create GPU mesh
			if (!mRendererMeshes.ContainsKey(command.Renderer))
			{
				if (command.Renderer.Mesh.IsValid && command.Renderer.Mesh.Resource != null)
				{
					// This returns a new handle (adds ref)
					var gpuMesh = resourceManager.GetOrCreateMesh(command.Renderer.Mesh.Resource);
					if (gpuMesh.IsValid)
					{
						mRendererMeshes[command.Renderer] = gpuMesh;
					}
				}
			}

			// Get or create GPU material
			if (!mRendererMaterials.ContainsKey(command.Renderer))
			{
				if (command.Renderer.Material.IsValid && command.Renderer.Material.Resource != null)
				{
					// This returns a new handle (adds ref)
					var gpuMaterial = resourceManager.GetOrCreateMaterial(command.Renderer.Material.Resource);
					if (gpuMaterial.IsValid)
					{
						mRendererMaterials[command.Renderer] = gpuMaterial;
					}
				}
			}
		}
	}
}