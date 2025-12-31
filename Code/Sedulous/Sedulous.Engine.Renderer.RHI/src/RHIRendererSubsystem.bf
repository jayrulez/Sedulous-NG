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
	private readonly TextureResourceManager mTextureResourceManager = new .() ~ delete _;
	private readonly MaterialResourceManager mMaterialResourceManager = new .() ~ delete _;

	private List<RenderModule> mModules = new .() ~ delete _;

	private GPUResourceManager mGPUResourceManager ~ delete _;

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

	private GraphicsPipelineState mUnlitPipeline;
	public GraphicsPipelineState UnlitPipeline => mUnlitPipeline;

	private ResourceLayout mUnlitPerObjectResourceLayout;

	private LayoutElementDescription[] mUnlitMaterialLayoutElements ~ delete _;
	private ResourceLayout mUnlitMaterialResourceLayout;
	public ResourceLayout UnlitMaterialResourceLayout => mUnlitMaterialResourceLayout;

	private ResourceSet mDefaultUnlitMaterialResourceSet;
	public ResourceSet DefaultUnlitMaterialResourceSet => mDefaultUnlitMaterialResourceSet;

	private ResourceSet mUnlitPerObjectResourceSet;
	public ResourceSet UnlitResourceSet => mUnlitPerObjectResourceSet;

	private Buffer mUnlitVertexCB;
	public Buffer UnlitVertexCB => mUnlitVertexCB;

	private Buffer mDefaultUnlitMaterialCB;
	public Buffer DefaultUnlitMaterialCB => mDefaultUnlitMaterialCB;

	/*private Buffer mUnlitPixelCB;
	public Buffer UnlitPixelCB => mUnlitPixelCB;*/

	private Shader mVertexShader;
	private Shader mPixelShader;

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
		engine.ResourceSystem.AddResourceManager(mTextureResourceManager);
		engine.ResourceSystem.AddResourceManager(mMaterialResourceManager);

		mGPUResourceManager = new GPUResourceManager(mGraphicsContext);
		CreateDefaultTextures();

		CreateUnlitPipeline();

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

		DestroyUnlitPipeline();

		mDefaultWhiteTexture.Release();
		mDefaultBlackTexture.Release();
		mDefaultNormalTexture.Release();

		engine.ResourceSystem.RemoveResourceManager(mMeshResourceManager);
		engine.ResourceSystem.RemoveResourceManager(mTextureResourceManager);
		engine.ResourceSystem.RemoveResourceManager(mMaterialResourceManager);

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
		var module = new RenderModule(this);
		scene.AddModule(module);
		modules.Add(module);
		mModules.Add(module);
	}

	protected override void DestroySceneModules(Scene scene)
	{
		for (int i = mModules.Count - 1; i >= 0; i--)
		{
			if (mModules[i].Scene == scene)
			{
				scene.RemoveModule(mModules[i]);
				delete mModules[i];
				mModules.RemoveAt(i);
			}
		}
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
		for (var module in mModules)
		{
			module.PrepareGPUResources(cmd);
		}
	}

	private void MainRenderPassExecute(CommandBuffer cmd, RenderGraphContext context)
	{
		cmd.SetViewports(WindowViewports);
		cmd.SetScissorRectangles(WindowScissors);
		
		for (var module in mModules)
		{
			module.RenderMeshes(cmd);
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

	private void CreateUnlitPipeline()
	{
		{
			var byteCode = CompileShaderSource(mGraphicsContext, ShaderSources.UnlitShadersVS, .Vertex, "VS", .. scope .());
			var shaderBytes = scope uint8[byteCode.Count];
			byteCode.CopyTo(shaderBytes);
			var vsDesc = ShaderDescription(.Vertex, "VS", shaderBytes);
			mVertexShader = mGraphicsContext.Factory.CreateShader(vsDesc);
		}
		{
			var byteCode = CompileShaderSource(mGraphicsContext, ShaderSources.UnlitShadersPS, .Pixel, "PS", .. scope .());
			var shaderBytes = scope uint8[byteCode.Count];
			byteCode.CopyTo(shaderBytes);
			var psDesc = ShaderDescription(.Pixel, "PS", shaderBytes);
			mPixelShader = mGraphicsContext.Factory.CreateShader(psDesc);
		}
		{

		// Create a larger buffer for multiple objects
			const int32 MAX_OBJECTS = 1000;
			const int32 ALIGNMENT = 256; // Typical uniform buffer alignment requirement

		// Align each object's data to 256 bytes
			int32 alignedSize = ((sizeof(UnlitVertexUniforms) + ALIGNMENT - 1) / ALIGNMENT) * ALIGNMENT;

			var perObjectCBDesc = BufferDescription(
				(uint32)(alignedSize * MAX_OBJECTS),
				.ConstantBuffer,
				.Dynamic,
				.Write
				);
			mUnlitVertexCB = mGraphicsContext.Factory.CreateBuffer(perObjectCBDesc);
		}
		{
			// Create a small default material buffer with default values
			var defaultMaterialData = scope UnlitFragmentUniforms()
				{
					MaterialTint = Color.White.ToVector4(),
					MaterialProperties = Vector4(1, 1, 1, 0)
				};

			var defaultMaterialBufferDesc = BufferDescription(
				sizeof(UnlitVertexUniforms),
				.ConstantBuffer,
				.Dynamic
				);
			mDefaultUnlitMaterialCB = mGraphicsContext.Factory.CreateBuffer(defaultMaterialData, defaultMaterialBufferDesc);
		}

		var vertexFormat = scope LayoutDescription()
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Position))
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Normal))
			.Add(ElementDescription(ElementFormat.Float2, ElementSemanticType.TexCoord))
			.Add(ElementDescription(ElementFormat.UByte4Normalized, ElementSemanticType.Color))
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Tangent));
		var vertexLayouts = scope InputLayouts();
		vertexLayouts.Add(vertexFormat);

		// Unlit Per Object ResourceLayout
		{
			LayoutElementDescription[] layoutElementDescs = scope:: LayoutElementDescription[](
				LayoutElementDescription(0, .ConstantBuffer, .Vertex, true, sizeof(UnlitVertexUniforms))
				);

			ResourceLayoutDescription resourceLayoutDesc = ResourceLayoutDescription(params layoutElementDescs);

			mUnlitPerObjectResourceLayout = mGraphicsContext.Factory.CreateResourceLayout(resourceLayoutDesc);
		}

		// Unlit Material ResourceLayout
		{
			mUnlitMaterialLayoutElements = new LayoutElementDescription[](
				LayoutElementDescription(0, .ConstantBuffer, .Pixel, false, sizeof(UnlitFragmentUniforms)),
				LayoutElementDescription(0, .Texture, .Pixel), 
				LayoutElementDescription(0, .Sampler, .Pixel)
				);

			ResourceLayoutDescription resourceLayoutDesc = ResourceLayoutDescription(params mUnlitMaterialLayoutElements);

			mUnlitMaterialResourceLayout = mGraphicsContext.Factory.CreateResourceLayout(resourceLayoutDesc);
		}

		var meshPipelineDescription = GraphicsPipelineDescription
			{
				RenderStates = RenderStateDescription.Default,
				Shaders = .()
					{
						VertexShader = mVertexShader,
						PixelShader = mPixelShader
					},
				InputLayouts = vertexLayouts,
				ResourceLayouts = scope ResourceLayout[](mUnlitPerObjectResourceLayout, mUnlitMaterialResourceLayout),
				PrimitiveTopology = .TriangleList,
				Outputs = .CreateFromFrameBuffer(mSwapChain.FrameBuffer)
			};

		mUnlitPipeline = mGraphicsContext.Factory.CreateGraphicsPipeline(meshPipelineDescription);

		// Per object resource set
		{
			ResourceSetDescription resourceSetDesc = .(mUnlitPerObjectResourceLayout, mUnlitVertexCB);
			mUnlitPerObjectResourceSet = mGraphicsContext.Factory.CreateResourceSet(resourceSetDesc);
		}

		// default material resource set
		{
			ResourceSetDescription resourceSetDesc = .(mUnlitMaterialResourceLayout, mDefaultUnlitMaterialCB, mDefaultWhiteTexture.Resource.Texture, mGraphicsContext.DefaultSampler);
			mDefaultUnlitMaterialResourceSet = mGraphicsContext.Factory.CreateResourceSet(resourceSetDesc);
		}
	}

	private void DestroyUnlitPipeline()
	{
		mGraphicsContext.Factory.DestroyResourceSet(ref mDefaultUnlitMaterialResourceSet);
		mGraphicsContext.Factory.DestroyResourceSet(ref mUnlitPerObjectResourceSet);
		mGraphicsContext.Factory.DestroyResourceLayout(ref mUnlitMaterialResourceLayout);
		mGraphicsContext.Factory.DestroyResourceLayout(ref mUnlitPerObjectResourceLayout);
		mGraphicsContext.Factory.DestroyGraphicsPipeline(ref mUnlitPipeline);

		mGraphicsContext.Factory.DestroyBuffer(ref mDefaultUnlitMaterialCB);
		mGraphicsContext.Factory.DestroyBuffer(ref mUnlitVertexCB);

		mGraphicsContext.Factory.DestroyShader(ref mPixelShader);
		mGraphicsContext.Factory.DestroyShader(ref mVertexShader);
	}

	public ResourceLayout GetMaterialResourceLayout(StringView shaderName)
	{
		switch (shaderName)
		{
		case "Unlit": return mUnlitMaterialResourceLayout;
		default: return mUnlitMaterialResourceLayout; // Fallback
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