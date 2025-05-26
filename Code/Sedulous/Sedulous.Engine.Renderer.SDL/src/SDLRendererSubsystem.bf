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

    internal SDL_GPUDevice* mDevice;
    private SDL3Window mPrimaryWindow;
    private Dictionary<String, SDL_GPUGraphicsPipeline*> mPipelineCache = new .() ~ delete _;
    private Dictionary<String, SDL_GPUShader*> mShaderCache = new .() ~ delete _;

	private IEngine.RegisteredUpdateFunctionInfo? mUpdateFunctionRegistration;
	private IEngine.RegisteredUpdateFunctionInfo? mRenderFunctionRegistration;

	private delegate void(uint32 width, uint32 height) mWindowResizeDelegate = null ~ delete _;

    // Uniform buffers
    internal SDL_GPUBuffer* CameraBuffer;
    internal SDL_GPUBuffer* MaterialBuffer;
    internal SDL_GPUBuffer* ObjectBuffer;

    public uint32 Width => mPrimaryWindow.Width;
    public uint32 Height => mPrimaryWindow.Height;

    public this(SDL3Window primaryWindow)
    {
        mPrimaryWindow = primaryWindow;
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
				Priority = -100,
				Stage = .PostUpdate,
				Function = new => OnRender
			});

        // Initialize SDL GPU device
        mDevice = SDL_CreateGPUDevice(
            .SDL_GPU_SHADERFORMAT_SPIRV | .SDL_GPU_SHADERFORMAT_DXIL| .SDL_GPU_SHADERFORMAT_MSL,
            true, null);

        if (!SDL_ClaimWindowForGPUDevice(mDevice, (SDL_Window*)mPrimaryWindow.GetNativePointer("SDL")))
        {
			SDL_Log("GPUClaimWindow failed");
            return .Err;
        }

		GetGPUShaderFormat();

        // Create uniform buffers
        CreateUniformBuffers();
        
        // Load default shaders
        LoadDefaultShaders();

        return base.OnInitializing(engine);
    }

    protected override void OnUnitializing(IEngine engine)
    {
        // Cleanup pipelines
        for (var pipeline in mPipelineCache.Values)
        {
            SDL_ReleaseGPUGraphicsPipeline(mDevice, pipeline);
        }
        
        // Cleanup shaders
        for (var shader in mShaderCache.Values)
        {
            SDL_ReleaseGPUShader(mDevice, shader);
        }

        // Cleanup uniform buffers
        SDL_ReleaseGPUBuffer(mDevice, CameraBuffer);
        SDL_ReleaseGPUBuffer(mDevice, MaterialBuffer);
        SDL_ReleaseGPUBuffer(mDevice, ObjectBuffer);

        SDL_ReleaseWindowFromGPUDevice(mDevice, (SDL_Window*)mPrimaryWindow.GetNativePointer("SDL"));
        SDL_DestroyGPUDevice(mDevice);

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

		base.OnUnitializing(engine);
    }

    protected override void CreateSceneModules(Scene scene, List<SceneModule> modules)
    {
        modules.Add(new RenderModule(this));
        modules.Add(new CullingModule(this));
        modules.Add(new LightingModule(this));
		modules.Add(new PostProcessModule(this));
    }

    private void CreateUniformBuffers()
    {
        var cameraBufferDesc = SDL_GPUBufferCreateInfo()
        {
            usage = .SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ,
            size = sizeof(CameraData)
        };
        CameraBuffer = SDL_CreateGPUBuffer(mDevice, &cameraBufferDesc);

        var materialBufferDesc = SDL_GPUBufferCreateInfo()
        {
            usage = .SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ,
            size = sizeof(Material.MaterialProperties)
        };
        MaterialBuffer = SDL_CreateGPUBuffer(mDevice, &materialBufferDesc);

        var objectBufferDesc = SDL_GPUBufferCreateInfo()
        {
            usage = .SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ,
            size = sizeof(Matrix)
        };
        ObjectBuffer = SDL_CreateGPUBuffer(mDevice, &objectBufferDesc);
    }

    private void LoadDefaultShaders()
    {
        // Load basic vertex and fragment shaders
        LoadShader("DefaultLit_VS", "shaders/DefaultLit_VS.hlsl", .SDL_SHADERCROSS_SHADERSTAGE_VERTEX);
        LoadShader("DefaultLit_PS", "shaders/DefaultLit_PS.hlsl", .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT);
        LoadShader("Unlit_VS", "shaders/Unlit_VS.hlsl", .SDL_SHADERCROSS_SHADERSTAGE_VERTEX);
        LoadShader("Unlit_PS", "shaders/Unlit_PS.hlsl", .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT);
    }

    private void LoadShader(StringView name, StringView path, SDL_ShaderCross_ShaderStage stage)
    {
        var byteCode = scope List<uint8>();
        CompileShader(scope String(path), stage, "main", byteCode);

        var shaderDesc = SDL_GPUShaderCreateInfo()
        {
            code = byteCode.Ptr,
            code_size = (uint32)byteCode.Count,
            entrypoint = "main",
            format = ShaderFormat,
            stage = (SDL_GPUShaderStage)stage
        };

        var shader = SDL_CreateGPUShader(mDevice, &shaderDesc);
        mShaderCache[new String(name)] = shader;
    }

    public SDL_GPUGraphicsPipeline* GetMaterialPipeline(Material material, bool enableBlending)
    {
        var pipelineKey = scope String();
        pipelineKey.AppendF("{}_Blend{}", material.ShaderName, enableBlending);

        if (!mPipelineCache.TryGetValue(pipelineKey, var pipeline))
        {
            pipeline = CreateMaterialPipeline(material, enableBlending);
            mPipelineCache[new String(pipelineKey)] = pipeline;
        }

        return pipeline;
    }

    private SDL_GPUGraphicsPipeline* CreateMaterialPipeline(Material material, bool enableBlending)
    {
        var vertexShaderName = scope String();
        var fragmentShaderName = scope String();
        
        vertexShaderName.AppendF("{}_VS", material.ShaderName);
        fragmentShaderName.AppendF("{}_PS", material.ShaderName);

        var vertexShader = mShaderCache.GetValueOrDefault(vertexShaderName);
        var fragmentShader = mShaderCache.GetValueOrDefault(fragmentShaderName);

        if (vertexShader == null || fragmentShader == null)
        {
            // Fallback to default shaders
            vertexShader = mShaderCache["DefaultLit_VS"];
            fragmentShader = mShaderCache["DefaultLit_PS"];
        }

        // Define vertex attributes
        var vertexAttributes = SDL_GPUVertexAttribute[4]
        (
            .{ location = 0, buffer_slot = 0, format = .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, offset = 0 },     // Position
            .{ location = 1, buffer_slot = 0, format = .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, offset = 12 },   // Normal  
            .{ location = 2, buffer_slot = 0, format = .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, offset = 24 },   // TexCoord
            .{ location = 3, buffer_slot = 0, format = .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4, offset = 32 }    // Color
        );

        var vertexBufferDesc = SDL_GPUVertexBufferDescription()
        {
            slot = 0,
            pitch = sizeof(Mesh.Vertex),
            input_rate = .SDL_GPU_VERTEXINPUTRATE_VERTEX,
            instance_step_rate = 0
        };

        var vertexInputState = SDL_GPUVertexInputState()
        {
            vertex_buffer_descriptions = &vertexBufferDesc,
            num_vertex_buffers = 1,
            vertex_attributes = &vertexAttributes[0],
            num_vertex_attributes = 4
        };

        var colorTargetDesc = SDL_GPUColorTargetDescription()
        {
            format = .SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,
            blend_state = .{
                src_color_blendfactor = enableBlending ? .SDL_GPU_BLENDFACTOR_SRC_ALPHA : .SDL_GPU_BLENDFACTOR_ONE,
                dst_color_blendfactor = enableBlending ? .SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA : .SDL_GPU_BLENDFACTOR_ZERO,
                color_blend_op = .SDL_GPU_BLENDOP_ADD,
                src_alpha_blendfactor = .SDL_GPU_BLENDFACTOR_ONE,
                dst_alpha_blendfactor = .SDL_GPU_BLENDFACTOR_ZERO,
                alpha_blend_op = .SDL_GPU_BLENDOP_ADD,
                color_write_mask = .SDL_GPU_COLORCOMPONENT_R | .SDL_GPU_COLORCOMPONENT_G | .SDL_GPU_COLORCOMPONENT_B | .SDL_GPU_COLORCOMPONENT_A,
                enable_blend = enableBlending,
                enable_color_write_mask = false
            }
        };

        var targetInfo = SDL_GPUGraphicsPipelineTargetInfo()
        {
            color_target_descriptions = &colorTargetDesc,
            num_color_targets = 1,
            depth_stencil_format = .SDL_GPU_TEXTUREFORMAT_D32_FLOAT,
            has_depth_stencil_target = true
        };

        var pipelineDesc = SDL_GPUGraphicsPipelineCreateInfo()
        {
            vertex_shader = vertexShader,
            fragment_shader = fragmentShader,
            vertex_input_state = vertexInputState,
            primitive_type = .SDL_GPU_PRIMITIVETYPE_TRIANGLELIST,
            rasterizer_state = .{
                cull_mode = .SDL_GPU_CULLMODE_BACK,
                front_face = .SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE,
                fill_mode = .SDL_GPU_FILLMODE_FILL,
                enable_depth_bias = false,
                depth_bias_constant_factor = 0.0f,
                depth_bias_clamp = 0.0f,
                depth_bias_slope_factor = 0.0f
            },
            multisample_state = .{
                sample_count = .SDL_GPU_SAMPLECOUNT_1,
                sample_mask = 0xFFFFFFFF,
                enable_mask = true
            },
            depth_stencil_state = .{
                compare_op = .SDL_GPU_COMPAREOP_LESS,
                back_stencil_state = .{},
                front_stencil_state = .{},
                compare_mask = 0,
                write_mask = 0,
                enable_depth_test = true,
                enable_depth_write = true,
                enable_stencil_test = false
            },
            target_info = targetInfo,
            props = 0
        };

        return SDL_CreateGPUGraphicsPipeline(mDevice, &pipelineDesc);
    }

	private void OnUpdate(IEngine.UpdateInfo info)
	{
	}

    private void OnRender(IEngine.UpdateInfo info)
    {
        var commandBuffer = SDL_AcquireGPUCommandBuffer(mDevice);
        
        // Get swapchain texture
        SDL_GPUTexture* swapchainTexture = null;
        SDL_WaitAndAcquireGPUSwapchainTexture(commandBuffer, 
            (SDL_Window*)mPrimaryWindow.GetNativePointer("SDL"), 
            &swapchainTexture, null, null);

        // Render all active scenes
        for (var scene in info.Engine.SceneGraphSystem.ActiveScenes)
        {
            var renderModule = scene.GetModule<RenderModule>();
            if (renderModule != null)
            {
                renderModule.Render(commandBuffer, swapchainTexture);
            }
        }

        SDL_SubmitGPUCommandBuffer(commandBuffer);
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

    internal SDL_GPUShaderFormat ShaderFormat = .SDL_GPU_SHADERFORMAT_SPIRV; // Set appropriately

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
}