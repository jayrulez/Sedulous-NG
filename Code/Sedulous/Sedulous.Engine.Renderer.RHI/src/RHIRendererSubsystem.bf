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
	public GraphicsPipelineState SkinnedPhongPipeline => mPipelineManager.SkinnedPhongPipeline;
	public GraphicsPipelineState DebugLinePipeline => mPipelineManager.DebugLinePipeline;
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

	private delegate void(uint32, uint32) mResizeDelegate ~ delete _;
	private Viewport[] WindowViewports = new .[1] ~ delete _;
	private Rectangle[] WindowScissors = new .[1] ~ delete _;

	// Render Graph
	private RenderGraph mRenderGraph ~ delete _;
	private RenderGraphResourceHandle mBackBufferHandle;

	public this(Window window, GraphicsContext context)
	{
		mWindow = window;
		mGraphicsContext = context;
		mResizeDelegate = new => OnWindowResized;
		WindowViewports[0] = Viewport(0, 0, mWindow.Width, mWindow.Height);
		WindowScissors[0] = Rectangle(0, 0, (.)mWindow.Width, (.)mWindow.Height);
	}

	protected override Result<void> OnInitializing(IEngine engine)
	{
		mGraphicsContext.CreateDevice(scope ValidationLayer(mGraphicsContext.Logger));

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

		commandBuffer.End();
		commandBuffer.Commit();

		mCommandQueue.Submit();
		mCommandQueue.WaitIdle();

		mSwapChain.Present();
	}

	private void OnWindowResized(uint32 width, uint32 height)
	{
		mCommandQueue.WaitIdle();
		WindowViewports[0] = Viewport(0, 0, mWindow.Width, mWindow.Height);
		WindowScissors[0] = Rectangle(0, 0, (.)mWindow.Width, (.)mWindow.Height);
		mSwapChain.ResizeSwapChain((.)width, (.)height);
		
		// Reset render graph on resize
		if (mRenderGraph != null)
		{
			mRenderGraph.Reset();
			SetupRenderGraph();
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
		
		// Add main render pass
		var mainPass = mRenderGraph.AddPass<RenderGraphGraphicsPass>("MainRender", 
			new => MainRenderPassExecute);
		
		mainPass.Setup(mRenderGraph)
			.WriteTexture(mBackBufferHandle)
			.DependsOn(updatePass.Handle)
			.Build();
		
		var clearValue = ClearValue(ClearFlags.All, Color.CornflowerBlue);
		var mainRenderPass = mainPass;
		mainRenderPass.RenderPassDesc = RenderPassDescription(mSwapChain.FrameBuffer, clearValue);
		
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
		}
	}

	private void MainRenderPassExecute(CommandBuffer cmd, RenderGraphContext context)
	{
		cmd.SetViewports(WindowViewports);
		cmd.SetScissorRectangles(WindowScissors);

		for (var module in mRenderModules)
		{
			module.RenderMeshes(cmd);
			module.RenderSkinnedMeshes(cmd);
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