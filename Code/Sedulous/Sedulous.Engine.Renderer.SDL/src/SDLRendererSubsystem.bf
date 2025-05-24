using Sedulous.Engine.Core;
using SDL3_shadercross;
using System.Collections;
using System;
using System.IO;
using SDL3Native;
using Sedulous.Foundation.Mathematics;
using Sedulous.Platform.Core;
using Sedulous.Platform.SDL3;
using Sedulous.Engine.Core.SceneGraph;
namespace Sedulous.Engine.Renderer.SDL;

class SDLRendererSubsystem : Subsystem
{
	public override StringView Name => "SDLRenderer";

	private Camera mActiveCamera;
	private readonly SDL3Window mPrimaryWindow;
	private RenderPipeline mRenderPipeline;

	private SDL_GPUViewport mViewport = .();
	private SDL_Rect mScissor = .();

	private IEngine.RegisteredUpdateFunctionInfo? mUpdateFunctionRegistration;
	private IEngine.RegisteredUpdateFunctionInfo? mRenderFunctionRegistration;

	private delegate void(uint32 width, uint32 height) mWindowResizeDelegate = null ~ delete _;


	public Camera Camera
	{
		get => mActiveCamera;
		set => mActiveCamera = value;
	}
	
	internal SDL_GPUDevice* mDevice;

	internal SDL_GPUBuffer* CameraBuffer;

	internal SDL_GPUShader* FullscreenVertexShader;

	internal SDL_GPUShaderFormat ShaderFormat = .SDL_GPU_SHADERFORMAT_INVALID;

	internal uint32 Width => mPrimaryWindow.Width;
	internal uint32 Height => mPrimaryWindow.Height;


	public this(SDL3Window primaryWindow)
	{
		mPrimaryWindow = primaryWindow;
	}

	public ~this()
	{
	}

	protected override Result<void> OnInitializing(IEngine engine)
	{
		mUpdateFunctionRegistration = engine.RegisterUpdateFunction(.()
			{
				Priority = 1,
				Stage = .VariableUpdate,
				Function = new => OnUpdate
			});

		mRenderFunctionRegistration = engine.RegisterUpdateFunction(.()
			{
				Priority = 1,
				Stage = .PostUpdate,
				Function = new => OnRender
			});

		mDevice = SDL_CreateGPUDevice(
			.SDL_GPU_SHADERFORMAT_SPIRV | .SDL_GPU_SHADERFORMAT_DXIL | .SDL_GPU_SHADERFORMAT_MSL,
			true,
			null);

		if (!SDL_ClaimWindowForGPUDevice(mDevice, (SDL_Window*)mPrimaryWindow.GetNativePointer("SDL")))
		{
			SDL_Log("GPUClaimWindow failed");
			return .Err;
		}

		GetGPUShaderFormat();

		mRenderPipeline = new .(this);

		uint32 x = mPrimaryWindow.Width/2;
		uint32 y = mPrimaryWindow.Height/2;
		uint32 w = mPrimaryWindow.Width;
		uint32 h = mPrimaryWindow.Height;

		mViewport = .() { x = x, y = y, w = w, h = h, min_depth = 0.1f, max_depth = 1.0f };
		mScissor = .() { x = (int32)x, y = (int32)y, w = (int32)w, h = (int32)h };

		mPrimaryWindow.OnResized.Add(mWindowResizeDelegate = new (width, height) =>
			{
				SDL_WaitForGPUIdle(mDevice);

				uint32 x = width/2;
				uint32 y = height/2;
				uint32 w = width;
				uint32 h = height;

				mViewport = .() { x = x, y = y, w = w, h = h, min_depth = 0.1f, max_depth = 1.0f };
				mScissor = .() { x = (int32)x, y = (int32)y, w = (int32)w, h = (int32)h };

				// todo: resize swapchain

				mRenderPipeline.OnResize(width, height);
			});
		{
			// Allocate buffer for camera data
			var cameraBufferDescription = SDL_GPUBufferCreateInfo()
				{
					usage = .SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ,
					size = sizeof(Matrix) * 2
				};
			CameraBuffer = SDL_CreateGPUBuffer(mDevice, &cameraBufferDescription);
		}
		{
			// Fullscreen VS
			uint8[] vsByteCode = null;
			{
				List<uint8> byteCode = scope .();
				CompileShader("shaders/Fullscreen_VS.hlsl", .SDL_SHADERCROSS_SHADERSTAGE_VERTEX, "main", byteCode);

				vsByteCode = scope:: .[byteCode.Count];
				byteCode.CopyTo(vsByteCode);
			}

			SDL_GPUShaderCreateInfo fullscreenVSShaderDescription = .()
			{
				code = (uint8*)vsByteCode.Ptr,
				code_size = (uint)vsByteCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_VERTEX,
				num_samplers = 0,
				num_uniform_buffers = 0,
				num_storage_buffers = 0,
				num_storage_textures = 0
			};

			FullscreenVertexShader = SDL_CreateGPUShader(mDevice, &fullscreenVSShaderDescription);
		}

		mRenderPipeline.Setup();

		return base.OnInitializing(engine);
	}

	protected override void OnUnitializing(IEngine engine)
	{
		mRenderPipeline.Destroy();
		delete mRenderPipeline;


		SDL_ReleaseGPUShader(mDevice, FullscreenVertexShader);

		SDL_ReleaseGPUBuffer(mDevice, CameraBuffer);

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

		SDL_ReleaseWindowFromGPUDevice(mDevice, (SDL_Window*)mPrimaryWindow.GetNativePointer("SDL"));
		SDL_DestroyGPUDevice(mDevice);

		base.OnUnitializing(engine);
	}

    protected override void CreateSceneModules(Scene scene, List<SceneModule> modules)
    {
        // Create multiple render-related modules
        modules.Add(new RenderModule(this));           // Main rendering
        modules.Add(new CullingModule(this));          // Frustum culling
        modules.Add(new LightingModule(this));         // Light management
        modules.Add(new PostProcessModule(this));      // Post-processing effects
    }

	private void OnUpdate(IEngine.UpdateInfo info)
	{
	}

	private void OnRender(IEngine.UpdateInfo info)
	{
		// begin render frame

		SDL_GPUCommandBuffer* commandBuffer = SDL_AcquireGPUCommandBuffer(mDevice);

		// Upload Camera Data
		if (Camera != null)
		{
			Matrix viewMatrix = Camera.ViewMatrix;
			Matrix projectionMatrix = Camera.ProjectionMatrix;

			// Update the camera constant buffer
			//mDevice.UpdateBufferData(CameraBuffer, ref viewMatrix, 0);
			//mDevice.UpdateBufferData(CameraBuffer, ref projectionMatrix, sizeof(Matrix));
		}

		mRenderPipeline.Execute(commandBuffer);

		{
			SDL_GPUTexture* swapchainTexture = null;
			SDL_WaitAndAcquireGPUSwapchainTexture(commandBuffer, (SDL_Window*)mPrimaryWindow.GetNativePointer("SDL"), &swapchainTexture, null, null);
			SDL_GPUColorTargetInfo colorTargetInfo = .();
			colorTargetInfo.texture = swapchainTexture;
			colorTargetInfo.clear_color = .() { r = 1.0f, g = 1.0f, b = 0.0f, a = 1.0f };
			colorTargetInfo.load_op = .SDL_GPU_LOADOP_CLEAR;
			colorTargetInfo.store_op = .SDL_GPU_STOREOP_STORE;

			SDL_GPURenderPass* renderPass = SDL_BeginGPURenderPass(commandBuffer, &colorTargetInfo, 1, null);

			SDL_SetGPUViewport(renderPass, &mViewport);
			SDL_SetGPUScissor(renderPass, &mScissor);
			SDL_EndGPURenderPass(renderPass);
		}

		SDL_SubmitGPUCommandBuffer(commandBuffer);


		// end render frame
	}

	private void GetGPUShaderFormat()
	{
		
		SDL_GPUShaderFormat backendFormats = SDL_GetGPUShaderFormats(mDevice);
		ShaderFormat = .SDL_GPU_SHADERFORMAT_INVALID;

		if (backendFormats & .SDL_GPU_SHADERFORMAT_SPIRV != 0)
		{
			ShaderFormat = .SDL_GPU_SHADERFORMAT_SPIRV;
		} else if (backendFormats & .SDL_GPU_SHADERFORMAT_MSL != 0)
		{
			ShaderFormat = .SDL_GPU_SHADERFORMAT_MSL;
		} else if (backendFormats & .SDL_GPU_SHADERFORMAT_DXIL != 0)
		{
			ShaderFormat = .SDL_GPU_SHADERFORMAT_DXIL;
		} else
		{
			SDL_Log("%s", "Unrecognized backend shader format!");
			return;
		}
	}

	internal void CompileShader(String shaderPath, SDL_ShaderCross_ShaderStage stage, String entrypoint, List<uint8> byteCode)
	{
		String error = scope .();
		String shaderSource = scope .();
		if (File.ReadAllText(shaderPath, shaderSource) case .Err)
		{
			Runtime.FatalError(scope $"Failed to read shader: {shaderPath}.");
		}

		SDL_ShaderCross_HLSL_Info hlslInfo = .()
		{
			source = shaderSource.CStr(),
			entrypoint = entrypoint.CStr(),
			shader_stage = stage,
			enable_debug = true
		};

		uint spirvByteCodeSize = 0;
		void* spirvByteCode = SDL_ShaderCross_CompileSPIRVFromHLSL(&hlslInfo, &spirvByteCodeSize);
		if(spirvByteCode == null)
		{
			error.Set(scope .(SDL_GetError()));
			Runtime.FatalError(scope $"Shader compilation fail: {shaderPath} - {error}");
		}

		byteCode.AddRange(Span<uint8>((uint8*)spirvByteCode, (int)spirvByteCodeSize));
	}
}