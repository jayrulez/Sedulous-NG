using SDL3Native;
using SDL3_shadercross;
using System;
using System.Diagnostics;
namespace SDLGPUTest;

class Program
{
	static SDL_GPUGraphicsPipeline* FillPipeline;
	static SDL_GPUGraphicsPipeline* LinePipeline;
	static SDL_GPUViewport SmallViewport = .() { x = 160, y = 120, w = 320, h = 240, min_depth = 0.1f, max_depth = 1.0f };
	static SDL_Rect ScissorRect = .() { x = 320, y = 240, w = 320, h = 240 };

	static bool UseWireframeMode = false;
	static bool UseSmallViewport = false;
	static bool UseScissorRect = false;

	struct Context
	{
		public char8* ExampleName;
		public char8* BasePath;
		public SDL_Window* Window;
		public SDL_GPUDevice* Device;
		public bool LeftPressed;
		public bool RightPressed;
		public bool DownPressed;
		public bool UpPressed;
		public float DeltaTime;
	}

	static int CommonInit(Context* context, SDL_WindowFlags windowFlags)
	{
		context.Device = SDL_CreateGPUDevice(
			.SDL_GPU_SHADERFORMAT_SPIRV | .SDL_GPU_SHADERFORMAT_DXIL | .SDL_GPU_SHADERFORMAT_MSL,
			true,
			null);

		if (context.Device == null)
		{
			SDL_Log("GPUCreateDevice failed");
			return -1;
		}

		context.Window = SDL_CreateWindow(context.ExampleName, 640, 480, windowFlags);
		if (context.Window == null)
		{
			SDL_Log("CreateWindow failed: %s", SDL_GetError());
			return -1;
		}

		if (!SDL_ClaimWindowForGPUDevice(context.Device, context.Window))
		{
			SDL_Log("GPUClaimWindow failed");
			return -1;
		}

		return 0;
	}

	static void CommonQuit(Context* context)
	{
		SDL_ReleaseWindowFromGPUDevice(context.Device, context.Window);
		SDL_DestroyWindow(context.Window);
		SDL_DestroyGPUDevice(context.Device);
	}

	static int Init(Context* context)
	{
		int result = CommonInit(context, 0);
		if (result < 0)
		{
			return result;
		}

		// Create the shaders
		SDL_GPUShader* vertexShader = LoadShader(context.Device, "shaders/RawTriangle.vert.hlsl", 0, 0, 0, 0);
		if (vertexShader == null)
		{
			SDL_Log("Failed to create vertex shader!");
			return -1;
		}

		SDL_GPUShader* fragmentShader = LoadShader(context.Device, "shaders/SolidColor.frag.hlsl", 0, 0, 0, 0);
		if (fragmentShader == null)
		{
			SDL_Log("Failed to create fragment shader!");
			return -1;
		}

		// Create the pipelines
		SDL_GPUColorTargetDescription[] color_targets = scope .[](SDL_GPUColorTargetDescription()
			{
				format = SDL_GetGPUSwapchainTextureFormat(context.Device, context.Window)
			});
		SDL_GPUGraphicsPipelineCreateInfo pipelineCreateInfo = .()
			{
				target_info = .()
					{
						num_color_targets = 1,
						color_target_descriptions = color_targets.Ptr
					},
				primitive_type = .SDL_GPU_PRIMITIVETYPE_TRIANGLELIST,
				vertex_shader = vertexShader,
				fragment_shader = fragmentShader
			};

		pipelineCreateInfo.rasterizer_state.fill_mode = .SDL_GPU_FILLMODE_FILL;
		FillPipeline = SDL_CreateGPUGraphicsPipeline(context.Device, &pipelineCreateInfo);
		if (FillPipeline == null)
		{
			char8* error = SDL_GetError();
			SDL_Log(scope $"Failed to create fill pipeline: {scope String(error)}");
			return -1;
		}

		pipelineCreateInfo.rasterizer_state.fill_mode = .SDL_GPU_FILLMODE_LINE;
		LinePipeline = SDL_CreateGPUGraphicsPipeline(context.Device, &pipelineCreateInfo);
		if (LinePipeline == null)
		{
			char8* error = SDL_GetError();
			SDL_Log(scope $"Failed to create line pipeline: {scope String(error)}");
			return -1;
		}

		// Clean up shader resources
		SDL_ReleaseGPUShader(context.Device, vertexShader);
		SDL_ReleaseGPUShader(context.Device, fragmentShader);

		// Finally, print instructions!
		SDL_Log("Press Left to toggle wireframe mode");
		SDL_Log("Press Down to toggle small viewport");
		SDL_Log("Press Right to toggle scissor rect");

		return 0;
	}

	static int Update(Context* context)
	{
		if (context.LeftPressed)
		{
			UseWireframeMode = !UseWireframeMode;
		}

		if (context.DownPressed)
		{
			UseSmallViewport = !UseSmallViewport;
		}

		if (context.RightPressed)
		{
			UseScissorRect = !UseScissorRect;
		}

		return 0;
	}

	static int Draw(Context* context)
	{
		SDL_GPUCommandBuffer* cmdbuf = SDL_AcquireGPUCommandBuffer(context.Device);
		if (cmdbuf == null)
		{
			SDL_Log("AcquireGPUCommandBuffer failed: %s", SDL_GetError());
			return -1;
		}

		SDL_GPUTexture* swapchainTexture = null;
		if (!SDL_WaitAndAcquireGPUSwapchainTexture(cmdbuf, context.Window, &swapchainTexture, null, null))
		{
			SDL_Log("WaitAndAcquireGPUSwapchainTexture failed: %s", SDL_GetError());
			return -1;
		}

		if (swapchainTexture != null)
		{
			SDL_GPUColorTargetInfo colorTargetInfo = .();
			colorTargetInfo.texture = swapchainTexture;
			colorTargetInfo.clear_color = .() { r = 0.0f, g = 0.0f, b = 0.0f, a = 1.0f };
			colorTargetInfo.load_op = .SDL_GPU_LOADOP_CLEAR;
			colorTargetInfo.store_op = .SDL_GPU_STOREOP_STORE;

			SDL_GPURenderPass* renderPass = SDL_BeginGPURenderPass(cmdbuf, &colorTargetInfo, 1, null);
			SDL_BindGPUGraphicsPipeline(renderPass, UseWireframeMode ? LinePipeline : FillPipeline);
			if (UseSmallViewport)
			{
				SDL_SetGPUViewport(renderPass, &SmallViewport);
			}
			if (UseScissorRect)
			{
				SDL_SetGPUScissor(renderPass, &ScissorRect);
			}
			SDL_DrawGPUPrimitives(renderPass, 3, 1, 0, 0);
			SDL_EndGPURenderPass(renderPass);
		}

		SDL_SubmitGPUCommandBuffer(cmdbuf);

		return 0;
	}

	static void Quit(Context* context)
	{
		SDL_ReleaseGPUGraphicsPipeline(context.Device, FillPipeline);
		SDL_ReleaseGPUGraphicsPipeline(context.Device, LinePipeline);

		UseWireframeMode = false;
		UseSmallViewport = false;
		UseScissorRect = false;

		CommonQuit(context);
	}

	static SDL_GPUShader* LoadShader(
		SDL_GPUDevice* device,
		String shaderFilePath,
		uint32 samplerCount,
		uint32 uniformBufferCount,
		uint32 storageBufferCount,
		uint32 storageTextureCount
		)
	{
	// Auto-detect the shader stage from the file name for convenience
		SDL_GPUShaderStage stage;
		SDL_ShaderCross_ShaderStage scStage;
		if (shaderFilePath.Contains(".vert"))
		{
			stage = .SDL_GPU_SHADERSTAGE_VERTEX;
			scStage = .SDL_SHADERCROSS_SHADERSTAGE_VERTEX;
		}
		else if (shaderFilePath.Contains(".frag"))
		{
			stage = .SDL_GPU_SHADERSTAGE_FRAGMENT;
			scStage = .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT;
		}
		else
		{
			SDL_Log("Invalid shader stage!");
			return null;
		}

		SDL_GPUShaderFormat backendFormats = SDL_GetGPUShaderFormats(device);
		SDL_GPUShaderFormat format = .SDL_GPU_SHADERFORMAT_INVALID;
		char8* entrypoint;

		if (backendFormats & .SDL_GPU_SHADERFORMAT_SPIRV != 0)
		{
			format = .SDL_GPU_SHADERFORMAT_SPIRV;
			entrypoint = "main";
		} else if (backendFormats & .SDL_GPU_SHADERFORMAT_MSL != 0)
		{
			format = .SDL_GPU_SHADERFORMAT_MSL;
			entrypoint = "main0";
		} else if (backendFormats & .SDL_GPU_SHADERFORMAT_DXIL != 0)
		{
			format = .SDL_GPU_SHADERFORMAT_DXIL;
			entrypoint = "main";
		} else
		{
			SDL_Log("%s", "Unrecognized backend shader format!");
			return null;
		}

		uint sourceCodeSize = 0;
		void* shaderSourceCode = SDL_LoadFile(shaderFilePath.CStr(), &sourceCodeSize);
		if (shaderSourceCode == null)
		{
			SDL_Log("Failed to load shader from disk! %s", shaderFilePath.CStr());
			return null;
		}

		String strCode = scope String((char8*)shaderSourceCode);

		SDL_ShaderCross_HLSL_Info hlslInfo = .()
			{
				source = strCode.CStr(),
				entrypoint = "main",
				shader_stage = scStage,
				enable_debug = true
			};
		uint spirvByteCodeSize = 0;
		void* spirvByteCode = SDL_ShaderCross_CompileSPIRVFromHLSL(&hlslInfo, &spirvByteCodeSize);

		SDL_GPUShaderCreateInfo shaderInfo = .()
			{
				code = (uint8*)spirvByteCode,
				code_size = spirvByteCodeSize,
				entrypoint = entrypoint,
				format = format,
				stage = stage,
				num_samplers = samplerCount,
				num_uniform_buffers = uniformBufferCount,
				num_storage_buffers = storageBufferCount,
				num_storage_textures = storageTextureCount
			};
		SDL_GPUShader* shader = SDL_CreateGPUShader(device, &shaderInfo);
		if (shader == null)
		{
			SDL_Log("Failed to create shader!");
			SDL_free(shaderSourceCode);
			return null;
		}

		SDL_free(shaderSourceCode);
		return shader;
	}

	public static void Main()
	{
		if (!SDL_ShaderCross_Init())
		{
			return;
		}
		defer SDL_ShaderCross_Quit();

		Context context = .();

		if (!SDL_Init(.SDL_INIT_VIDEO))
		{
			Debug.WriteLine("SDL_Init failed: {0}", SDL_GetError());
			return;
		}
		defer SDL_Quit();

		/*let window = SDL_CreateWindow("SDL3 Beef", 1280, 720, .SDL_WINDOW_RESIZABLE);
		if (window == null)
		{
			Debug.WriteLine("SDL_CreateWindow failed: {0}", SDL_GetError());
			return;
		}
		defer SDL_DestroyWindow(window);*/

		Init(&context);
		defer Quit(&context);

		while (true)
		{
			SDL_Event ev = .();
			while (SDL_PollEvent(&ev))
			{
				if (ev.type == (.)SDL_EventType.SDL_EVENT_QUIT)
					return;
			}
			Update(&context);
			Draw(&context);
		}
	}
}