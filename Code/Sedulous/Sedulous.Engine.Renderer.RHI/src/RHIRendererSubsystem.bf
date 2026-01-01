using Sedulous.Engine.Core;
using System;
using System.Collections;
using Sedulous.SceneGraph;
using Sedulous.Platform.Core;
using Sedulous.Engine.Renderer.GPU;
using Sedulous.RHI;
using Sedulous.Mathematics;
using Sedulous.RHI.VertexFormats;
using Sedulous.Engine.Renderer.RHI.RenderGraph;
namespace Sedulous.Engine.Renderer.RHI;

using internal Sedulous.Engine.Renderer.RHI;

class RHIRendererSubsystem : Subsystem
{
	public override StringView Name => "RHIRenderer";

	internal Window mWindow;

	private IEngine.RegisteredUpdateFunctionInfo? mUpdateFunctionRegistration;
	private IEngine.RegisteredUpdateFunctionInfo? mRenderFunctionRegistration;

	private readonly MeshResourceManager mMeshResourceManager = new .() ~ delete _;
	private readonly SkinnedMeshResourceManager mSkinnedMeshResourceManager = new .() ~ delete _;
	private readonly TextureResourceManager mTextureResourceManager = new .() ~ delete _;
	private readonly MaterialResourceManager mMaterialResourceManager = new .() ~ delete _;
	private readonly SkinResourceManager mSkinResourceManager = new .() ~ delete _;
	private readonly SkeletonResourceManager mSkeletonResourceManager = new .() ~ delete _;
	private readonly AnimationResourceManager mAnimationResourceManager = new .() ~ delete _;

	private List<RenderModule> mRenderModules = new .() ~ delete _;
	private List<AnimationModule> mAnimationModules = new .() ~ delete _;

	private GPUResourceManager mGPUResourceManager ~ delete _;
	private ShaderManager mShaderManager ~ delete _;
	private PipelineManager mPipelineManager ~ delete _;

	public GPUResourceManager GPUResources => mGPUResourceManager;

	// Default textures
	private GPUResourceHandle<GPUTexture> mDefaultWhiteTexture;
	private GPUResourceHandle<GPUTexture> mDefaultBlackTexture;
	private GPUResourceHandle<GPUTexture> mDefaultNormalTexture;

	public GPUResourceHandle<GPUTexture> GetDefaultWhiteTexture() => mDefaultWhiteTexture;
	public GPUResourceHandle<GPUTexture> GetDefaultBlackTexture() => mDefaultBlackTexture;
	public GPUResourceHandle<GPUTexture> GetDefaultNormalTexture() => mDefaultNormalTexture;

	public uint32 Width => mWindow.Width;
	public uint32 Height => mWindow.Height;

	private GraphicsContext mGraphicsContext;

	public GraphicsContext GraphicsContext => mGraphicsContext;

	private SwapChain mSwapChain;

	public FrameBuffer SwapChainFrameBuffer => mSwapChain.FrameBuffer;

	private CommandQueue mCommandQueue;

	// Pipeline accessors (delegate to PipelineManager)
	public GraphicsPipelineState UnlitPipeline => mPipelineManager.UnlitPipeline;
	public GraphicsPipelineState SkinnedUnlitPipeline => mPipelineManager.SkinnedUnlitPipeline;
	public GraphicsPipelineState PhongPipeline => mPipelineManager.PhongPipeline;
	public GraphicsPipelineState SkinnedPhongPipeline => mPipelineManager.SkinnedPhongPipeline;
	public GraphicsPipelineState PBRPipeline => mPipelineManager.PBRPipeline;
	public GraphicsPipelineState SkinnedPBRPipeline => mPipelineManager.SkinnedPBRPipeline;
	public GraphicsPipelineState DebugLinePipeline => mPipelineManager.DebugLinePipeline;
	public GraphicsPipelineState DepthOnlyPipeline => mPipelineManager.DepthOnlyPipeline;
	public GraphicsPipelineState SkinnedDepthOnlyPipeline => mPipelineManager.SkinnedDepthOnlyPipeline;
	public GraphicsPipelineState SpritePipeline => mPipelineManager.SpritePipeline;
	public ResourceLayout SkinnedPerObjectResourceLayout => mPipelineManager.SkinnedPerObjectResourceLayout;
	public ResourceLayout BoneMatricesResourceLayout => mPipelineManager.BoneMatricesResourceLayout;
	public ResourceLayout UnlitMaterialResourceLayout => mPipelineManager.UnlitMaterialResourceLayout;
	public ResourceLayout DebugResourceLayout => mPipelineManager.DebugResourceLayout;
	public ResourceSet DefaultUnlitMaterialResourceSet => mPipelineManager.DefaultUnlitMaterialResourceSet;
	public ResourceSet UnlitResourceSet => mPipelineManager.UnlitPerObjectResourceSet;
	public Buffer UnlitVertexCB => mPipelineManager.UnlitVertexCB;
	public Buffer DefaultUnlitMaterialCB => mPipelineManager.DefaultUnlitMaterialCB;
	public MaterialPipelineRegistry MaterialRegistry => mPipelineManager.MaterialRegistry;
	public Buffer LightingBuffer => mPipelineManager.LightingBuffer;
	public ResourceSet LightingResourceSet => mPipelineManager.LightingResourceSet;
	public Buffer SpriteVertexCB => mPipelineManager.SpriteVertexCB;
	public Buffer DefaultSpriteMaterialCB => mPipelineManager.DefaultSpriteMaterialCB;
	public ResourceSet SpritePerObjectResourceSet => mPipelineManager.SpritePerObjectResourceSet;
	public ResourceSet DefaultSpriteMaterialResourceSet => mPipelineManager.DefaultSpriteMaterialResourceSet;
	public ResourceLayout SpriteMaterialResourceLayout => mPipelineManager.SpriteMaterialResourceLayout;

	private delegate void(uint32, uint32) mResizeDelegate ~ delete _;
	private Viewport[] WindowViewports = new .[1] ~ delete _;
	private Rectangle[] WindowScissors = new .[1] ~ delete _;

	// Render Graph
	private RenderGraph mRenderGraph ~ delete _;
	private RenderGraphResourceHandle mBackBufferHandle;

	// Hi-Z Occlusion Culling resources
	private const uint32 HIZ_SIZE = 64;  // Fixed Hi-Z texture size
	private Texture mHiZTexture;
	private ResourceSet mHiZResourceSet;
	private SamplerState mHiZSampler;

	public Texture HiZTexture => mHiZTexture;
	public uint32 HiZSize => HIZ_SIZE;

	// GPU-Driven Culling resources
	public const int MAX_GPU_OBJECTS = 4096;
	public const int MAX_GPU_MESHES = 1024;

	private Buffer mObjectDataBuffer;       // Per-object data (world matrix, bounds)
	private Buffer mMeshInfoBuffer;         // Per-mesh info (index count, offsets)
	private Buffer mIndirectArgsBuffer;     // Indirect draw arguments
	private Buffer mVisibleIndicesBuffer;   // Object indices for visible objects
	private Buffer mDrawCountBuffer;        // Atomic counter for visible count
	private Buffer mCullingUniformsBuffer;  // Culling shader uniforms
	private ResourceSet mGPUCullingResourceSet;

	// Sprite quad buffers (for dynamic quad generation)
	private Buffer mSpriteQuadVertexBuffer;
	private Buffer mSpriteQuadIndexBuffer;

	// Picking resources (GPU-based object picking)
	private Texture mPickingRenderTarget;       // R32_UInt render target for entity IDs
	private Texture mPickingDepthTexture;       // Depth buffer for picking pass
	private FrameBuffer mPickingFrameBuffer;    // Framebuffer for picking render pass
	private Texture mPickingStagingTexture;     // Staging texture for CPU readback
	private bool mPickingResourcesCreated = false;

	// Picking state
	private bool mPickingRequested = false;
	private int32 mPickX;
	private int32 mPickY;
	private uint32 mLastPickedEntityId = 0;
	private bool mPickResultReady = false;

	// Selection state (for outline rendering)
	private Entity mSelectedEntity = null;
	private Vector4 mOutlineColor = Vector4(1.0f, 0.5f, 0.0f, 1.0f);  // Orange by default
	private float mOutlineThickness = 0.02f;

	public Buffer ObjectDataBuffer => mObjectDataBuffer;
	public Buffer MeshInfoBuffer => mMeshInfoBuffer;
	public Buffer IndirectArgsBuffer => mIndirectArgsBuffer;
	public Buffer VisibleIndicesBuffer => mVisibleIndicesBuffer;
	public Buffer DrawCountBuffer => mDrawCountBuffer;
	public Buffer CullingUniformsBuffer => mCullingUniformsBuffer;
	public ResourceSet GPUCullingResourceSet => mGPUCullingResourceSet;
	public Buffer SpriteQuadVertexBuffer => mSpriteQuadVertexBuffer;
	public Buffer SpriteQuadIndexBuffer => mSpriteQuadIndexBuffer;

	// Picking accessors
	public FrameBuffer PickingFrameBuffer => mPickingFrameBuffer;
	public Texture PickingRenderTarget => mPickingRenderTarget;
	public bool PickingResourcesCreated => mPickingResourcesCreated;
	public bool PickResultReady => mPickResultReady;
	public uint32 LastPickedEntityId => mLastPickedEntityId;
	public GraphicsPipelineState PickingPipeline => mPipelineManager?.PickingPipeline;
	public GraphicsPipelineState SkinnedPickingPipeline => mPipelineManager?.SkinnedPickingPipeline;
	public GraphicsPipelineState SpritePickingPipeline => mPipelineManager?.SpritePickingPipeline;
	public ResourceLayout PickingResourceLayout => mPipelineManager?.PickingResourceLayout;
	public ResourceLayout SpritePickingResourceLayout => mPipelineManager?.SpritePickingResourceLayout;
	public Buffer PickingUniformBuffer => mPipelineManager?.PickingUniformBuffer;
	public Buffer SpritePickingParamsBuffer => mPipelineManager?.SpritePickingParamsBuffer;
	public ResourceSet PickingResourceSet => mPipelineManager?.PickingResourceSet;
	public ResourceSet SpritePickingResourceSet => mPipelineManager?.SpritePickingResourceSet;

	// Outline/Selection accessors
	public GraphicsPipelineState OutlinePipeline => mPipelineManager?.OutlinePipeline;
	public GraphicsPipelineState SkinnedOutlinePipeline => mPipelineManager?.SkinnedOutlinePipeline;
	public ResourceLayout OutlineResourceLayout => mPipelineManager?.OutlineResourceLayout;
	public Buffer OutlineUniformBuffer => mPipelineManager?.OutlineUniformBuffer;
	public ResourceSet OutlineResourceSet => mPipelineManager?.OutlineResourceSet;
	public Entity SelectedEntity => mSelectedEntity;
	public Vector4 OutlineColor
	{
		get => mOutlineColor;
		set => mOutlineColor = value;
	}
	public float OutlineThickness
	{
		get => mOutlineThickness;
		set => mOutlineThickness = value;
	}

	/// Get the entity that was picked (searches all scenes managed by this subsystem)
	public Entity GetPickedEntity()
	{
		if (!mPickResultReady || mLastPickedEntityId == 0)
			return null;

		// Search through all scenes for the entity with this ID
		for (var module in mRenderModules)
		{
			if (var entity = module.Scene?.FindEntity((Sedulous.SceneGraph.EntityId)mLastPickedEntityId))
				return entity;
		}
		return null;
	}

	/// Clear the pick result (call after handling)
	public void ClearPickResult()
	{
		mPickResultReady = false;
		mLastPickedEntityId = 0;
	}

	/// Set the currently selected entity (will be rendered with an outline)
	public void SetSelectedEntity(Entity entity)
	{
		mSelectedEntity = entity;
	}

	/// Clear the current selection
	public void ClearSelection()
	{
		mSelectedEntity = null;
	}

	public this(Window window, GraphicsContext context)
	{
		mWindow = window;
		mGraphicsContext = context;
		mResizeDelegate = new => OnWindowResized;
		WindowViewports[0] = Viewport(0, 0, mWindow.Width, mWindow.Height);
		WindowScissors[0] = Rectangle(0, 0, (.)mWindow.Width, (.)mWindow.Height);
	}

	private ValidationLayer mValidationLayer ~ delete _;

	protected override Result<void> OnInitializing(IEngine engine)
	{
		mGraphicsContext.CreateDevice(mValidationLayer  = new ValidationLayer(mGraphicsContext.Logger));

		Sedulous.RHI.SurfaceInfo surfaceInfo = *(Sedulous.RHI.SurfaceInfo*)&mWindow.SurfaceInfo;

		SwapChainDescription swapChainDescription = CreateSwapChainDescription((.)mWindow.Width, (.)mWindow.Height, ref surfaceInfo);
		mSwapChain = mGraphicsContext.CreateSwapChain(swapChainDescription);

		mCommandQueue = mGraphicsContext.Factory.CreateCommandQueue();

		mWindow.OnResized.Add(mResizeDelegate);

		mUpdateFunctionRegistration = engine.RegisterUpdateFunction(.()
			{
				Priority = 1,
				Stage = .VariableUpdate,
				Function = new => OnUpdate
			});

		mRenderFunctionRegistration = engine.RegisterUpdateFunction(.()
			{
				Priority = -100,
				Stage = .PostUpdate,
				Function = new => OnRender
			});

		engine.ResourceSystem.AddResourceManager(mMeshResourceManager);
		engine.ResourceSystem.AddResourceManager(mSkinnedMeshResourceManager);
		engine.ResourceSystem.AddResourceManager(mTextureResourceManager);
		engine.ResourceSystem.AddResourceManager(mMaterialResourceManager);
		engine.ResourceSystem.AddResourceManager(mSkinResourceManager);
		engine.ResourceSystem.AddResourceManager(mSkeletonResourceManager);
		engine.ResourceSystem.AddResourceManager(mAnimationResourceManager);

		mGPUResourceManager = new GPUResourceManager(mGraphicsContext);
		CreateDefaultTextures();

		mShaderManager = new ShaderManager(mGraphicsContext);
		mPipelineManager = new PipelineManager(mGraphicsContext, this, mShaderManager);
		mPipelineManager.Initialize(mSwapChain.FrameBuffer);

		// Create Hi-Z resources
		CreateHiZResources();

		// Create GPU culling resources
		CreateGPUCullingResources();

		// Create sprite quad buffers
		CreateSpriteQuadBuffers();

		// Create picking resources and pipeline
		CreatePickingResources();

		// Create render graph
		mRenderGraph = new RenderGraph("Main", mGraphicsContext, mGraphicsContext.Factory);
		SetupRenderGraph();

		return base.OnInitializing(engine);
	}

	protected override void OnUnitializing(IEngine engine)
	{
		// Cleanup
		if (mRenderGraph != null)
		{
			mRenderGraph.Reset();
		}

		// Picking resources cleanup
		DestroyPickingResources();

		// Sprite quad buffers cleanup
		DestroySpriteQuadBuffers();

		// GPU culling cleanup
		DestroyGPUCullingResources();

		// Hi-Z cleanup
		DestroyHiZResources();

		// PipelineManager cleanup handled by destructor

		mDefaultWhiteTexture.Release();
		mDefaultBlackTexture.Release();
		mDefaultNormalTexture.Release();

		engine.ResourceSystem.RemoveResourceManager(mMeshResourceManager);
		engine.ResourceSystem.RemoveResourceManager(mSkinnedMeshResourceManager);
		engine.ResourceSystem.RemoveResourceManager(mTextureResourceManager);
		engine.ResourceSystem.RemoveResourceManager(mMaterialResourceManager);
		engine.ResourceSystem.RemoveResourceManager(mSkinResourceManager);
		engine.ResourceSystem.RemoveResourceManager(mSkeletonResourceManager);
		engine.ResourceSystem.RemoveResourceManager(mAnimationResourceManager);

		if (mUpdateFunctionRegistration.HasValue)
		{
			engine.UnregisterUpdateFunction(mUpdateFunctionRegistration.Value);
			delete mUpdateFunctionRegistration.Value.Function;
			mUpdateFunctionRegistration = null;
		}

		if (mRenderFunctionRegistration.HasValue)
		{
			engine.UnregisterUpdateFunction(mRenderFunctionRegistration.Value);
			delete mRenderFunctionRegistration.Value.Function;
			mRenderFunctionRegistration = null;
		}

		mWindow.OnResized.Remove(mResizeDelegate);

		mGraphicsContext.Factory.DestroyCommandQueue(ref mCommandQueue);
		mGraphicsContext.DestroySwapChain(ref mSwapChain);

		base.OnUnitializing(engine);
	}

	protected override void CreateSceneModules(Scene scene, List<SceneModule> modules)
	{
		// Animation module (updates before render)
		var animModule = new AnimationModule();
		scene.AddModule(animModule);
		modules.Add(animModule);
		mAnimationModules.Add(animModule);

		// Render module
		var renderModule = new RenderModule(this);
		scene.AddModule(renderModule);
		modules.Add(renderModule);
		mRenderModules.Add(renderModule);
	}

	protected override void DestroySceneModules(Scene scene)
	{
		for (int i = mRenderModules.Count - 1; i >= 0; i--)
		{
			if (mRenderModules[i].Scene == scene)
			{
				scene.RemoveModule(mRenderModules[i]);
				delete mRenderModules[i];
				mRenderModules.RemoveAt(i);
			}
		}
		for (int i = mAnimationModules.Count - 1; i >= 0; i--)
		{
			if (mAnimationModules[i].Scene == scene)
			{
				scene.RemoveModule(mAnimationModules[i]);
				delete mAnimationModules[i];
				mAnimationModules.RemoveAt(i);
			}
		}
	}

	/// Get the debug renderer for a specific scene
	public DebugRenderer GetDebugRenderer(Scene scene)
	{
		for (var module in mRenderModules)
		{
			if (module.Scene == scene)
				return module.DebugRenderer;
		}
		return null;
	}

	/// Get the first available debug renderer (convenience for single-scene apps)
	public DebugRenderer GetDebugRenderer()
	{
		if (mRenderModules.Count > 0)
			return mRenderModules[0].DebugRenderer;
		return null;
	}

	private void OnUpdate(IEngine.UpdateInfo info)
	{
	}

	private void OnRender(IEngine.UpdateInfo info)
	{
		// Update render graph resources if window resized
		UpdateRenderGraphResources();

		// Execute render graph
		CommandBuffer commandBuffer = mCommandQueue.CommandBuffer();
		commandBuffer.Begin();

		mRenderGraph.Execute(commandBuffer);

		// Execute picking pass if requested (outside main render graph)
		if (mPickingRequested && mPickingResourcesCreated)
		{
			for (var module in mRenderModules)
			{
				module.RenderForPicking(commandBuffer, mPickingFrameBuffer);
			}

			// Copy picked pixel to staging texture for CPU readback
			MarkPickingComplete(commandBuffer);
		}

		commandBuffer.End();
		commandBuffer.Commit();

		mCommandQueue.Submit();
		mCommandQueue.WaitIdle();

		// Read back pick result after GPU work completes
		if (mPickingRequested)
		{
			ReadPickResult();
		}

		mSwapChain.Present();
	}

	private void OnWindowResized(uint32 width, uint32 height)
	{
		// Skip resize if window is minimized (zero size)
		if (width == 0 || height == 0)
			return;

		mCommandQueue.WaitIdle();
		WindowViewports[0] = Viewport(0, 0, mWindow.Width, mWindow.Height);
		WindowScissors[0] = Rectangle(0, 0, (.)mWindow.Width, (.)mWindow.Height);
		mSwapChain.ResizeSwapChain((.)width, (.)height);

		// Recreate Hi-Z resource set since it references the depth texture
		RecreateHiZResourceSet();

		// Recreate picking resources with new size
		RecreatePickingResources();

		// Reset render graph on resize
		if (mRenderGraph != null)
		{
			mRenderGraph.Reset();
			SetupRenderGraph();
		}
	}

	private void RecreateHiZResourceSet()
	{
		// Destroy old resource set that references the old depth texture
		if (mHiZResourceSet != null)
			mGraphicsContext.Factory.DestroyResourceSet(ref mHiZResourceSet);

		// Create new resource set with the new depth texture
		var depthAttachment = mSwapChain.FrameBuffer.DepthStencilTarget;
		if (depthAttachment.HasValue)
		{
			var depthTexture = depthAttachment.Value.AttachmentTexture;
			ResourceSetDescription hiZSetDesc = .(
				mPipelineManager.HiZResourceLayout,
				depthTexture,                     // Input depth texture
				mHiZTexture,                      // Output Hi-Z texture (UAV)
				mPipelineManager.HiZParamsBuffer  // Params constant buffer
			);
			mHiZResourceSet = mGraphicsContext.Factory.CreateResourceSet(hiZSetDesc);
		}
	}

	private void SetupRenderGraph()
	{
		// Import back buffer
		mBackBufferHandle = mRenderGraph.ImportTexture("BackBuffer", mSwapChain.GetCurrentFramebufferTexture());

		// Add buffer update pass (outside render pass)
		var updatePass = mRenderGraph.AddPass<RenderGraphComputePass>("BufferUpdate",
			new => BufferUpdatePassExecute);

		updatePass.Setup(mRenderGraph)
			.Build();

		// Add depth prepass - clears and writes depth buffer
		var depthPrepass = mRenderGraph.AddPass<RenderGraphGraphicsPass>("DepthPrepass",
			new => DepthPrepassExecute);

		depthPrepass.Setup(mRenderGraph)
			.WriteTexture(mBackBufferHandle)  // Uses same framebuffer (including depth)
			.DependsOn(updatePass.Handle)
			.Build();

		// Depth prepass: clear depth only, don't touch color
		var depthClearValue = ClearValue(.Depth, 1.0f, 0);
		depthPrepass.RenderPassDesc = RenderPassDescription(mSwapChain.FrameBuffer, depthClearValue);

		// Add Hi-Z generation pass (after depth prepass, before GPU culling)
		var hiZPass = mRenderGraph.AddPass<RenderGraphComputePass>("HiZGenerate",
			new => HiZGenerateExecute);

		hiZPass.Setup(mRenderGraph)
			.DependsOn(depthPrepass.Handle)  // Depends on depth prepass
			.Build();

		// Add GPU culling pass (after Hi-Z generation, before main render)
		var gpuCullingPass = mRenderGraph.AddPass<RenderGraphComputePass>("GPUCulling",
			new => GPUCullingExecute);

		gpuCullingPass.Setup(mRenderGraph)
			.DependsOn(hiZPass.Handle)  // Depends on Hi-Z generation
			.Build();

		// Add main render pass - depends on GPU culling
		var mainPass = mRenderGraph.AddPass<RenderGraphGraphicsPass>("MainRender",
			new => MainRenderPassExecute);

		mainPass.Setup(mRenderGraph)
			.WriteTexture(mBackBufferHandle)
			.DependsOn(gpuCullingPass.Handle)  // Depends on GPU culling now
			.Build();

		// Main pass: clear color, load existing depth (from prepass)
		var mainClearValue = ClearValue(.Target, Color.CornflowerBlue);
		mainPass.RenderPassDesc = RenderPassDescription(mSwapChain.FrameBuffer, mainClearValue);

		// Compile render graph
		mRenderGraph.Compile();
	}

	private void BufferUpdatePassExecute(CommandBuffer cmd, RenderGraphContext context)
	{
		// Update all buffers outside of render pass
		for (var module in mRenderModules)
		{
			module.PrepareGPUResources(cmd);
			module.UpdateLightingBuffer(cmd);
			module.UpdateDebugBuffers(cmd);
			module.UpdateSpriteUniforms();
			module.UpdateOutlineUniforms(cmd);
		}
	}

	private void DepthPrepassExecute(CommandBuffer cmd, RenderGraphContext context)
	{
		cmd.SetViewports(WindowViewports);
		cmd.SetScissorRectangles(WindowScissors);

		// Render depth for all opaque geometry
		for (var module in mRenderModules)
		{
			module.RenderDepthPrepass(cmd);
		}
	}

	private void HiZGenerateExecute(CommandBuffer cmd, RenderGraphContext context)
	{
		// Skip if Hi-Z resources weren't created (no depth buffer)
		if (mHiZResourceSet == null)
			return;

		// Update Hi-Z params
		var hiZParams = HiZParams()
		{
			OutputSizeX = HIZ_SIZE,
			OutputSizeY = HIZ_SIZE,
			InputSizeX = mWindow.Width,
			InputSizeY = mWindow.Height
		};
		cmd.UpdateBufferData(mPipelineManager.HiZParamsBuffer, &hiZParams, (uint32)sizeof(HiZParams), 0);

		// Set compute pipeline and resource set
		cmd.SetComputePipelineState(mPipelineManager.HiZDownsamplePipeline);
		cmd.SetResourceSet(mHiZResourceSet, 0);

		// Dispatch compute shader
		// Thread group size is 8x8, so dispatch (HIZ_SIZE/8) groups in each dimension
		uint32 groupCountX = (HIZ_SIZE + 7) / 8;
		uint32 groupCountY = (HIZ_SIZE + 7) / 8;
		cmd.Dispatch(groupCountX, groupCountY, 1);

		// Barrier to ensure compute is done before GPU culling
		cmd.ResourceBarrierUnorderedAccessView(mHiZTexture);

		// Transition depth texture back to attachment layout for subsequent render passes
		var depthAttachment = mSwapChain.FrameBuffer.DepthStencilTarget;
		if (depthAttachment.HasValue)
		{
			cmd.TransitionDepthToAttachment(depthAttachment.Value.AttachmentTexture);
		}
	}

	private void GPUCullingExecute(CommandBuffer cmd, RenderGraphContext context)
	{
		// Skip if GPU culling resources weren't created
		if (mGPUCullingResourceSet == null)
			return;

		// Clear draw count to zero
		uint32 zero = 0;
		cmd.UpdateBufferData(mDrawCountBuffer, &zero, sizeof(uint32), 0);

		// Barrier to ensure draw count is cleared before compute
		cmd.ResourceBarrierUnorderedAccessView(mDrawCountBuffer);

		// Update culling uniforms
		// Note: RenderModule needs to populate ObjectData and provide the camera info
		// For now, the uniforms are updated by the first RenderModule in PrepareGPUResources

		// Set compute pipeline and resource set
		cmd.SetComputePipelineState(mPipelineManager.GPUCullingPipeline);
		cmd.SetResourceSet(mGPUCullingResourceSet, 0);

		// Dispatch compute shader - one thread per object
		// Thread group size is 64, so dispatch ceil(objectCount/64) groups
		// Note: The actual object count is set in the culling uniforms by RenderModule
		uint32 maxObjects = (uint32)MAX_GPU_OBJECTS;
		uint32 groupCount = (maxObjects + 63) / 64;
		cmd.Dispatch(groupCount, 1, 1);

		// Barrier to ensure culling compute is done before rendering
		cmd.ResourceBarrierUnorderedAccessView(mIndirectArgsBuffer);
		cmd.ResourceBarrierUnorderedAccessView(mVisibleIndicesBuffer);
		cmd.ResourceBarrierUnorderedAccessView(mDrawCountBuffer);
	}

	private void MainRenderPassExecute(CommandBuffer cmd, RenderGraphContext context)
	{
		cmd.SetViewports(WindowViewports);
		cmd.SetScissorRectangles(WindowScissors);

		for (var module in mRenderModules)
		{
			module.RenderMeshes(cmd);
			module.RenderSkinnedMeshes(cmd);
			module.RenderSprites(cmd);
			module.RenderOutline(cmd);  // Render selection outline after meshes
			module.RenderDebugLines(cmd);
		}
	}

	private void UpdateRenderGraphResources()
	{
		// Check if we need to recreate resources due to window resize
		// This would be handled by OnWindowResized
	}

	private void CreateDefaultTextures()
	{
		// Create 1x1 white texture
		{
			var whiteImage = scope Sedulous.Imaging.Image(1, 1, .RGBA8);
			whiteImage.SetPixel(0, 0, .White);
			mDefaultWhiteTexture = GPUResourceHandle<GPUTexture>(new GPUTexture("DefaultWhite", mGraphicsContext, whiteImage));
		}

		// Create 1x1 black texture
		{
			var blackImage = scope Sedulous.Imaging.Image(1, 1, .RGBA8);
			blackImage.SetPixel(0, 0, .Black);
			mDefaultBlackTexture = GPUResourceHandle<GPUTexture>(new GPUTexture("DefaultBlack", mGraphicsContext, blackImage));
		}

		// Create 1x1 default normal texture (pointing up)
		{
			var normalImage = scope Sedulous.Imaging.Image(1, 1, .RGBA8);
			normalImage.SetPixel(0, 0, Color(128, 128, 255, 255)); // Normal pointing up
			mDefaultNormalTexture = GPUResourceHandle<GPUTexture>(new GPUTexture("DefaultNormal", mGraphicsContext, normalImage));
		}

		mGraphicsContext.SyncUpcopyQueue();
	}

	public ResourceLayout GetMaterialResourceLayout(StringView shaderName)
	{
		return mPipelineManager.GetMaterialResourceLayout(shaderName);
	}

	private void CreateHiZResources()
	{
		// Create Hi-Z output texture (UAV for compute shader write)
		var hiZDesc = TextureDescription()
		{
			Type = .Texture2D,
			Format = .R32_Float,  // Single channel float depth
			Width = HIZ_SIZE,
			Height = HIZ_SIZE,
			Depth = 1,
			MipLevels = 1,
			ArraySize = 1,
			Faces = 1,
			Flags = .ShaderResource | .UnorderedAccess,  // Read and write access
			Usage = .Default,
			SampleCount = .None,
			CpuAccess = .None
		};
		mHiZTexture = mGraphicsContext.Factory.CreateTexture(hiZDesc, "HiZTexture");

		// Create point sampler for depth texture
		var samplerDesc = SamplerStateDescription()
		{
			Filter = .MinPoint_MagPoint_MipPoint,
			AddressU = .Clamp,
			AddressV = .Clamp,
			AddressW = .Clamp
		};
		mHiZSampler = mGraphicsContext.Factory.CreateSamplerState(samplerDesc);

		// Create resource set for Hi-Z compute pass
		// Layout: InputDepth (Texture), OutputDepth (UAV), HiZParams (CB)
		var depthAttachment = mSwapChain.FrameBuffer.DepthStencilTarget;
		if (depthAttachment.HasValue)
		{
			var depthTexture = depthAttachment.Value.AttachmentTexture;
			ResourceSetDescription hiZSetDesc = .(
				mPipelineManager.HiZResourceLayout,
				depthTexture,                     // Input depth texture
				mHiZTexture,                      // Output Hi-Z texture (UAV)
				mPipelineManager.HiZParamsBuffer  // Params constant buffer
			);
			mHiZResourceSet = mGraphicsContext.Factory.CreateResourceSet(hiZSetDesc);
		}
	}

	private void DestroyHiZResources()
	{
		if (mHiZResourceSet != null)
			mGraphicsContext.Factory.DestroyResourceSet(ref mHiZResourceSet);
		if (mHiZSampler != null)
			mGraphicsContext.Factory.DestroySampler(ref mHiZSampler);
		if (mHiZTexture != null)
			mGraphicsContext.Factory.DestroyTexture(ref mHiZTexture);
	}

	private void CreateGPUCullingResources()
	{
		// Object data buffer - per-object world matrix and bounds (96 bytes each)
		var objectDataDesc = BufferDescription(
			(uint32)(MAX_GPU_OBJECTS * sizeof(GPUObjectData)),
			.ShaderResource | .BufferStructured,
			.Dynamic,
			.Write
		);
		objectDataDesc.StructureByteStride = (uint32)sizeof(GPUObjectData);
		mObjectDataBuffer = mGraphicsContext.Factory.CreateBuffer(objectDataDesc, "ObjectDataBuffer");

		// Mesh info buffer - per-mesh index count and offsets (16 bytes each)
		var meshInfoDesc = BufferDescription(
			(uint32)(MAX_GPU_MESHES * sizeof(GPUMeshInfo)),
			.ShaderResource | .BufferStructured,
			.Dynamic,
			.Write
		);
		meshInfoDesc.StructureByteStride = (uint32)sizeof(GPUMeshInfo);
		mMeshInfoBuffer = mGraphicsContext.Factory.CreateBuffer(meshInfoDesc, "MeshInfoBuffer");

		// Indirect args buffer - IndirectDrawArgsIndexedInstanced (20 bytes each)
		// Needs UnorderedAccess for compute write + IndirectBuffer for indirect draw
		var indirectArgsDesc = BufferDescription(
			(uint32)(MAX_GPU_OBJECTS * 20),  // 20 bytes per IndirectDrawArgsIndexedInstanced
			.ShaderResource | .BufferStructured | .UnorderedAccess | .IndirectBuffer,
			.Default,
			.None
		);
		indirectArgsDesc.StructureByteStride = 20;
		mIndirectArgsBuffer = mGraphicsContext.Factory.CreateBuffer(indirectArgsDesc, "IndirectArgsBuffer");

		// Visible indices buffer - uint per visible object
		// Needs UnorderedAccess for compute write + ShaderResource for vertex shader read
		var visibleIndicesDesc = BufferDescription(
			(uint32)(MAX_GPU_OBJECTS * sizeof(uint32)),
			.ShaderResource | .BufferStructured | .UnorderedAccess,
			.Default,
			.None
		);
		visibleIndicesDesc.StructureByteStride = sizeof(uint32);
		mVisibleIndicesBuffer = mGraphicsContext.Factory.CreateBuffer(visibleIndicesDesc, "VisibleIndicesBuffer");

		// Draw count buffer - single uint32 atomic counter
		// Needs UnorderedAccess for atomic operations in compute shader
		var drawCountDesc = BufferDescription(
			sizeof(uint32),
			.ShaderResource | .BufferStructured | .UnorderedAccess,
			.Default,
			.None
		);
		drawCountDesc.StructureByteStride = sizeof(uint32);
		mDrawCountBuffer = mGraphicsContext.Factory.CreateBuffer(drawCountDesc, "DrawCountBuffer");

		// Culling uniforms buffer
		var cullingUniformsDesc = BufferDescription(
			(uint32)sizeof(GPUCullingUniforms),
			.ConstantBuffer,
			.Dynamic,
			.Write
		);
		mCullingUniformsBuffer = mGraphicsContext.Factory.CreateBuffer(cullingUniformsDesc, "CullingUniformsBuffer");

		// Create GPU culling resource set
		// Layout: t0=ObjectData, t1=MeshInfo, t2=HiZTexture, s0=HiZSampler,
		//         u0=IndirectArgs, u1=VisibleIndices, u2=DrawCount, b0=CullingUniforms
		ResourceSetDescription cullingSetDesc = .(
			mPipelineManager.GPUCullingResourceLayout,
			mObjectDataBuffer,          // t0: ObjectData
			mMeshInfoBuffer,            // t1: MeshInfo
			mHiZTexture,                // t2: HiZTexture
			mHiZSampler,                // s0: HiZSampler
			mIndirectArgsBuffer,        // u0: IndirectArgs
			mVisibleIndicesBuffer,      // u1: VisibleIndices
			mDrawCountBuffer,           // u2: DrawCount
			mCullingUniformsBuffer      // b0: CullingUniforms
		);
		mGPUCullingResourceSet = mGraphicsContext.Factory.CreateResourceSet(cullingSetDesc);
	}

	private void DestroyGPUCullingResources()
	{
		if (mGPUCullingResourceSet != null)
			mGraphicsContext.Factory.DestroyResourceSet(ref mGPUCullingResourceSet);
		if (mCullingUniformsBuffer != null)
			mGraphicsContext.Factory.DestroyBuffer(ref mCullingUniformsBuffer);
		if (mDrawCountBuffer != null)
			mGraphicsContext.Factory.DestroyBuffer(ref mDrawCountBuffer);
		if (mVisibleIndicesBuffer != null)
			mGraphicsContext.Factory.DestroyBuffer(ref mVisibleIndicesBuffer);
		if (mIndirectArgsBuffer != null)
			mGraphicsContext.Factory.DestroyBuffer(ref mIndirectArgsBuffer);
		if (mMeshInfoBuffer != null)
			mGraphicsContext.Factory.DestroyBuffer(ref mMeshInfoBuffer);
		if (mObjectDataBuffer != null)
			mGraphicsContext.Factory.DestroyBuffer(ref mObjectDataBuffer);
	}

	private void CreateSpriteQuadBuffers()
	{
		// Sprite quad vertex buffer (4 vertices, static unit quad)
		// Unit quad corners: (0,0), (1,0), (1,1), (0,1)
		SpriteVertex[4] vertices = .(
			SpriteVertex() { Position = Vector3(0, 0, 0) },  // Bottom-left
			SpriteVertex() { Position = Vector3(1, 0, 0) },  // Bottom-right
			SpriteVertex() { Position = Vector3(1, 1, 0) },  // Top-right
			SpriteVertex() { Position = Vector3(0, 1, 0) }   // Top-left
		);

		var vertexBufferDesc = BufferDescription(
			(uint32)(sizeof(SpriteVertex) * 4),
			.VertexBuffer,
			.Default,
			.None
		);
		mSpriteQuadVertexBuffer = mGraphicsContext.Factory.CreateBuffer(&vertices[0], vertexBufferDesc, "SpriteQuadVertexBuffer");

		// Sprite quad index buffer (6 indices for 2 triangles, static)
		uint16[6] indices = .(0, 1, 2, 0, 2, 3);
		var indexBufferDesc = BufferDescription(
			(uint32)(sizeof(uint16) * 6),
			.IndexBuffer,
			.Default,
			.None
		);
		mSpriteQuadIndexBuffer = mGraphicsContext.Factory.CreateBuffer(&indices[0], indexBufferDesc, "SpriteQuadIndexBuffer");
	}

	private void DestroySpriteQuadBuffers()
	{
		if (mSpriteQuadIndexBuffer != null)
			mGraphicsContext.Factory.DestroyBuffer(ref mSpriteQuadIndexBuffer);
		if (mSpriteQuadVertexBuffer != null)
			mGraphicsContext.Factory.DestroyBuffer(ref mSpriteQuadVertexBuffer);
	}

	private void CreatePickingResources()
	{
		// Create picking render target (R32_UInt for entity IDs)
		var pickingRTDesc = TextureDescription()
		{
			Type = .Texture2D,
			Format = .R32_UInt,
			Width = mWindow.Width,
			Height = mWindow.Height,
			Depth = 1,
			MipLevels = 1,
			ArraySize = 1,
			Faces = 1,
			Flags = .RenderTarget | .ShaderResource,
			Usage = .Default,
			SampleCount = .None,
			CpuAccess = .None
		};
		mPickingRenderTarget = mGraphicsContext.Factory.CreateTexture(pickingRTDesc, "PickingRenderTarget");

		// Create picking depth texture (D32_Float)
		var pickingDepthDesc = TextureDescription()
		{
			Type = .Texture2D,
			Format = .D32_Float,
			Width = mWindow.Width,
			Height = mWindow.Height,
			Depth = 1,
			MipLevels = 1,
			ArraySize = 1,
			Faces = 1,
			Flags = .DepthStencil,
			Usage = .Default,
			SampleCount = .None,
			CpuAccess = .None
		};
		mPickingDepthTexture = mGraphicsContext.Factory.CreateTexture(pickingDepthDesc, "PickingDepthTexture");

		// Create picking staging texture (same size as RT for proper copy alignment)
		var stagingDesc = TextureDescription()
		{
			Type = .Texture2D,
			Format = .R32_UInt,
			Width = mWindow.Width,
			Height = mWindow.Height,
			Depth = 1,
			MipLevels = 1,
			ArraySize = 1,
			Faces = 1,
			Flags = .None,
			Usage = .Staging,
			SampleCount = .None,
			CpuAccess = .Read
		};
		mPickingStagingTexture = mGraphicsContext.Factory.CreateTexture(stagingDesc, "PickingStagingTexture");

		// Create picking framebuffer
		var depthAttachment = FrameBufferAttachment(mPickingDepthTexture, 0, 1);
		var colorAttachments = FrameBufferAttachmentList(FrameBufferAttachment(mPickingRenderTarget, 0, 1));
		mPickingFrameBuffer = mGraphicsContext.Factory.CreateFrameBuffer(depthAttachment, colorAttachments, false);

		// Initialize picking pipelines with the picking framebuffer
		mPipelineManager.InitializePickingPipelines(mPickingFrameBuffer);

		mPickingResourcesCreated = true;
	}

	private void DestroyPickingResources()
	{
		if (!mPickingResourcesCreated)
			return;

		// Note: Picking pipeline resources are cleaned up by PipelineManager.Destroy()

		if (mPickingFrameBuffer != null)
			mGraphicsContext.Factory.DestroyFrameBuffer(ref mPickingFrameBuffer);
		if (mPickingStagingTexture != null)
			mGraphicsContext.Factory.DestroyTexture(ref mPickingStagingTexture);
		if (mPickingDepthTexture != null)
			mGraphicsContext.Factory.DestroyTexture(ref mPickingDepthTexture);
		if (mPickingRenderTarget != null)
			mGraphicsContext.Factory.DestroyTexture(ref mPickingRenderTarget);

		mPickingResourcesCreated = false;
	}

	private void RecreatePickingResources()
	{
		if (!mPickingResourcesCreated)
			return;

		// Destroy old resources (but not pipeline - that stays the same)
		if (mPickingFrameBuffer != null)
			mGraphicsContext.Factory.DestroyFrameBuffer(ref mPickingFrameBuffer);
		if (mPickingStagingTexture != null)
			mGraphicsContext.Factory.DestroyTexture(ref mPickingStagingTexture);
		if (mPickingDepthTexture != null)
			mGraphicsContext.Factory.DestroyTexture(ref mPickingDepthTexture);
		if (mPickingRenderTarget != null)
			mGraphicsContext.Factory.DestroyTexture(ref mPickingRenderTarget);

		// Recreate render target and depth with new size
		var pickingRTDesc = TextureDescription()
		{
			Type = .Texture2D,
			Format = .R32_UInt,
			Width = mWindow.Width,
			Height = mWindow.Height,
			Depth = 1,
			MipLevels = 1,
			ArraySize = 1,
			Faces = 1,
			Flags = .RenderTarget | .ShaderResource,
			Usage = .Default,
			SampleCount = .None,
			CpuAccess = .None
		};
		mPickingRenderTarget = mGraphicsContext.Factory.CreateTexture(pickingRTDesc, "PickingRenderTarget");

		var pickingDepthDesc = TextureDescription()
		{
			Type = .Texture2D,
			Format = .D32_Float,
			Width = mWindow.Width,
			Height = mWindow.Height,
			Depth = 1,
			MipLevels = 1,
			ArraySize = 1,
			Faces = 1,
			Flags = .DepthStencil,
			Usage = .Default,
			SampleCount = .None,
			CpuAccess = .None
		};
		mPickingDepthTexture = mGraphicsContext.Factory.CreateTexture(pickingDepthDesc, "PickingDepthTexture");

		// Recreate staging texture with new size
		var stagingDesc = TextureDescription()
		{
			Type = .Texture2D,
			Format = .R32_UInt,
			Width = mWindow.Width,
			Height = mWindow.Height,
			Depth = 1,
			MipLevels = 1,
			ArraySize = 1,
			Faces = 1,
			Flags = .None,
			Usage = .Staging,
			SampleCount = .None,
			CpuAccess = .Read
		};
		mPickingStagingTexture = mGraphicsContext.Factory.CreateTexture(stagingDesc, "PickingStagingTexture");

		var depthAttachment = FrameBufferAttachment(mPickingDepthTexture, 0, 1);
		var colorAttachments = FrameBufferAttachmentList(FrameBufferAttachment(mPickingRenderTarget, 0, 1));
		mPickingFrameBuffer = mGraphicsContext.Factory.CreateFrameBuffer(depthAttachment, colorAttachments, false);
	}

	/// Request a pick at the given screen coordinates. The result will be available on the next frame.
	public void RequestPick(int32 screenX, int32 screenY)
	{
		if (!mPickingResourcesCreated)
			return;

		mPickingRequested = true;
		mPickX = Math.Clamp(screenX, 0, (int32)mWindow.Width - 1);
		mPickY = Math.Clamp(screenY, 0, (int32)mWindow.Height - 1);
		mPickResultReady = false;
	}

	/// Check if a pick was requested for this frame
	public bool IsPickingRequested => mPickingRequested;

	/// Get the pick coordinates
	public void GetPickCoordinates(out int32 x, out int32 y)
	{
		x = mPickX;
		y = mPickY;
	}

	/// Mark the pick as processed (called after rendering picking pass)
	public void MarkPickingComplete(CommandBuffer cmd)
	{
		if (!mPickingRequested)
			return;

		// Copy the single pixel from the picking render target to staging texture at the same position
		// Parameters: source, srcX, srcY, srcZ, srcMip, srcArray, dest, dstX, dstY, dstZ, dstMip, dstArray, width, height, depth, layerCount
		cmd.CopyTextureDataTo(
			mPickingRenderTarget, (uint32)mPickX, (uint32)mPickY, 0, 0, 0,
			mPickingStagingTexture, (uint32)mPickX, (uint32)mPickY, 0, 0, 0,
			1, 1, 1, 1);
	}

	/// Read back the picked entity ID from the staging texture (must be called after GPU work completes)
	public void ReadPickResult()
	{
		if (!mPickingRequested)
			return;

		mPickingRequested = false;

		// Map staging texture to read the picked entity ID at the correct offset
		var mappedResource = mGraphicsContext.MapMemory(mPickingStagingTexture, .Read);
		if (mappedResource.Data != null)
		{
			// Calculate offset in the mapped memory
			// RowPitch is the number of bytes per row, pixel size is 4 bytes (R32_UInt)
			int32 pixelSize = 4;
			int32 rowPitch = (int32)mappedResource.RowPitch;
			int32 offset = mPickY * rowPitch + mPickX * pixelSize;

			mLastPickedEntityId = *(uint32*)((uint8*)mappedResource.Data + offset);
			mGraphicsContext.UnmapMemory(mPickingStagingTexture);
			mPickResultReady = true;
		}
	}

	private static TextureSampleCount SampleCount = TextureSampleCount.None;

	private static SwapChainDescription CreateSwapChainDescription(uint32 width, uint32 height, ref Sedulous.RHI.SurfaceInfo surfaceInfo)
	{
		return SwapChainDescription()
			{
				Width = width,
				Height = height,
				SurfaceInfo = surfaceInfo,
				ColorTargetFormat = PixelFormat.R8G8B8A8_UNorm,
				ColorTargetFlags = TextureFlags.RenderTarget | TextureFlags.ShaderResource,
				DepthStencilTargetFormat = PixelFormat.D24_UNorm_S8_UInt,
				DepthStencilTargetFlags = TextureFlags.DepthStencil,
				SampleCount = SampleCount,
				IsWindowed = true,
				RefreshRate = 60
			};
	}
}