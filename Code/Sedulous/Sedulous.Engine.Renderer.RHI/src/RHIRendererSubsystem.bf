using Sedulous.Engine.Core;
using System;
using System.Collections;
using Sedulous.SceneGraph;
using Sedulous.Platform.Core;
using Sedulous.Engine.Renderer.GPU;
using Sedulous.RHI;
using Sedulous.Mathematics;
using Sedulous.RHI.VertexFormats;
namespace Sedulous.Engine.Renderer.RHI;

using internal Sedulous.Engine.Renderer.RHI;

[CRepr, Packed]
struct UnlitVertexUniforms
{
	public Matrix MVPMatrix; // 64 bytes (4x float4)
	public Matrix ModelMatrix; // 64 bytes (4x float4)
	// Total: 128 bytes (multiple of 16)
}

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

	private ResourceLayout mUnlitResourceLayout;

	private ResourceSet mUnlitResourceSet;
	public ResourceSet UnlitResourceSet => mUnlitResourceSet;

	private Buffer mPerObjectConstantBuffer;
	public Buffer PerObjectConstantBuffer => mPerObjectConstantBuffer;

	private Shader mVertexShader;
	private Shader mPixelShader;

	private delegate void(uint32, uint32) mResizeDelegate ~ delete _;
	private Viewport[] WindowViewports = new .[1] ~ delete _;
	private Rectangle[] WindowScissors = new .[1] ~ delete _;

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

		CreateShaders();

		CreateBuffers();

		CreatePipelines();

		return base.OnInitializing(engine);
	}

	protected override void OnUnitializing(IEngine engine)
	{
		// Cleanup

		DestroyPipelines();

		DestroyBuffers();

		DestroyShaders();

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
		CommandBuffer commandBuffer = mCommandQueue.CommandBuffer();

		commandBuffer.Begin();
		{
			// Clear screen
			ClearValue clearValue = .(ClearFlags.All, Color.CornflowerBlue);
			RenderPassDescription clearRenderPass = RenderPassDescription(mSwapChain.FrameBuffer, clearValue);
			commandBuffer.BeginRenderPass(clearRenderPass);

			commandBuffer.SetViewports(WindowViewports);
			commandBuffer.SetScissorRectangles(WindowScissors);

			commandBuffer.EndRenderPass();
		}
		{
			for (var module in mModules)
			{
				module.RenderFrame(info, commandBuffer);
			}
		}

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
	}

	private void CreatePipelines()
	{
		var vertexFormat = scope LayoutDescription()
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Position))
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Normal))
			.Add(ElementDescription(ElementFormat.Float2, ElementSemanticType.TexCoord))
			.Add(ElementDescription(ElementFormat.UByte4Normalized, ElementSemanticType.Color))
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Tangent));
		var vertexLayouts = scope InputLayouts();
		vertexLayouts.Add(vertexFormat);

		LayoutElementDescription[] layoutElementDescs = scope LayoutElementDescription[](
			//LayoutElementDescription(0, .ConstantBuffer, .Vertex, false, sizeof(PerFrameData)),
			LayoutElementDescription(0, .ConstantBuffer, .Vertex, true, sizeof(UnlitVertexUniforms))
			);

		ResourceLayoutDescription resourceLayoutDesc = ResourceLayoutDescription(params layoutElementDescs);

		mUnlitResourceLayout = mGraphicsContext.Factory.CreateResourceLayout(resourceLayoutDesc);

		var meshPipelineDescription = GraphicsPipelineDescription
			{
				RenderStates = RenderStateDescription.Default,
				Shaders = .()
					{
						VertexShader = mVertexShader,
						PixelShader = mPixelShader
					},
				InputLayouts = vertexLayouts,
				ResourceLayouts = scope ResourceLayout[](mUnlitResourceLayout),
				PrimitiveTopology = .TriangleList,
				Outputs = .CreateFromFrameBuffer(mSwapChain.FrameBuffer)
			};

		//meshPipelineDescription.RenderStates.RasterizerState.FrontCounterClockwise = false;
		meshPipelineDescription.RenderStates.RasterizerState.CullMode = .None;

		mUnlitPipeline = mGraphicsContext.Factory.CreateGraphicsPipeline(meshPipelineDescription);

		ResourceSetDescription resourceSetDesc = .(mUnlitResourceLayout, /*mPerFrameConstantBuffer,*/ mPerObjectConstantBuffer);
		mUnlitResourceSet = mGraphicsContext.Factory.CreateResourceSet(resourceSetDesc);
	}

	private void DestroyPipelines()
	{
		mGraphicsContext.Factory.DestroyResourceSet(ref mUnlitResourceSet);
		mGraphicsContext.Factory.DestroyResourceLayout(ref mUnlitResourceLayout);
		mGraphicsContext.Factory.DestroyGraphicsPipeline(ref mUnlitPipeline);
	}

	private void CreateBuffers()
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
	    mPerObjectConstantBuffer = mGraphicsContext.Factory.CreateBuffer(perObjectCBDesc);
	}

	private void DestroyBuffers()
	{
		mGraphicsContext.Factory.DestroyBuffer(ref mPerObjectConstantBuffer);
		//mGraphicsContext.Factory.DestroyBuffer(ref mPerFrameConstantBuffer);
	}

	private void CreateShaders()
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
	}

	private void DestroyShaders()
	{
		mGraphicsContext.Factory.DestroyShader(ref mPixelShader);
		mGraphicsContext.Factory.DestroyShader(ref mVertexShader);
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