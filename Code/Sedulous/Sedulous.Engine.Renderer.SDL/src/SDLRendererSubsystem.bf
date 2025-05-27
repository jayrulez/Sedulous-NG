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

struct Vertex
{
    public Vector3 Position;
    public Vector3 Color;
}

class SDLRendererSubsystem : Subsystem
{
    public override StringView Name => "SDLRenderer";

    internal SDL_GPUDevice* mDevice;
    private SDL3Window mPrimaryWindow;
    
    private IEngine.RegisteredUpdateFunctionInfo? mUpdateFunctionRegistration;
    private IEngine.RegisteredUpdateFunctionInfo? mRenderFunctionRegistration;
    
    // Basic pipeline for triangle
    private SDL_GPUGraphicsPipeline* mTrianglePipeline;
    private SDL_GPUShader* mVertexShader;
    private SDL_GPUShader* mFragmentShader;
    
    // Vertex buffer for triangle
    private SDL_GPUBuffer* mTriangleVertexBuffer;
    
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
            .SDL_GPU_SHADERFORMAT_SPIRV | .SDL_GPU_SHADERFORMAT_DXIL | .SDL_GPU_SHADERFORMAT_MSL,
            true, null);

        if (!SDL_ClaimWindowForGPUDevice(mDevice, (SDL_Window*)mPrimaryWindow.GetNativePointer("SDL")))
        {
            SDL_Log("GPUClaimWindow failed");
            return .Err;
        }

        GetGPUShaderFormat();

        // Create basic resources
        CreateTriangleResources();
        CreateShaders();
        CreatePipeline();

        return base.OnInitializing(engine);
    }

    protected override void OnUnitializing(IEngine engine)
    {
        // Cleanup
        SDL_ReleaseGPUGraphicsPipeline(mDevice, mTrianglePipeline);
        SDL_ReleaseGPUShader(mDevice, mVertexShader);
        SDL_ReleaseGPUShader(mDevice, mFragmentShader);
        SDL_ReleaseGPUBuffer(mDevice, mTriangleVertexBuffer);

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

	private RenderModule mRenderModule = null;

    protected override void CreateSceneModules(Scene scene, List<SceneModule> modules)
    {
        modules.Add(mRenderModule = new RenderModule(this));
    }

    protected override void DestroySceneModules(Scene scene)
    {
        delete mRenderModule;
    }

    private void CreateTriangleResources()
    {
        // Simple triangle vertices with position and color
        Vertex[3] triangleData = .(
            .{ Position = .(-0.5f, -0.5f, 0.0f), Color = .(1.0f, 0.0f, 0.0f) },
            .{ Position = .(0.5f, -0.5f, 0.0f), Color = .(0.0f, 1.0f, 0.0f) },
            .{ Position = .(0.0f, 0.5f, 0.0f), Color = .(0.0f, 0.0f, 1.0f) }
        );

        // Create vertex buffer
        var vertexBufferDesc = SDL_GPUBufferCreateInfo()
        {
            usage = .SDL_GPU_BUFFERUSAGE_VERTEX,
            size = sizeof(Vertex) * 3
        };
        mTriangleVertexBuffer = SDL_CreateGPUBuffer(mDevice, &vertexBufferDesc);

        // Upload triangle data
        var transferBuffer = SDL_CreateGPUTransferBuffer(mDevice, scope .()
        {
            size = sizeof(Vertex) * 3,
            usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD
        });

        void* mappedData = SDL_MapGPUTransferBuffer(mDevice, transferBuffer, false);
        Internal.MemCpy(mappedData, &triangleData[0], sizeof(Vertex) * 3);
        SDL_UnmapGPUTransferBuffer(mDevice, transferBuffer);

        // Upload to GPU
        var commandBuffer = SDL_AcquireGPUCommandBuffer(mDevice);
        var copyPass = SDL_BeginGPUCopyPass(commandBuffer);
        
        SDL_UploadToGPUBuffer(copyPass, scope .()
        {
            transfer_buffer = transferBuffer,
            offset = 0
        }, scope .()
        {
            buffer = mTriangleVertexBuffer,
            offset = 0,
            size = sizeof(Vertex) * 3
        }, false);
        
        SDL_EndGPUCopyPass(copyPass);
        SDL_SubmitGPUCommandBuffer(commandBuffer);
        
        SDL_ReleaseGPUTransferBuffer(mDevice, transferBuffer);
    }

    private void CreateShaders()
    {
        // Simple vertex shader that passes through vertex data
        String vertexShaderSource = """
struct VSInput
{
    float3 Position : POSITION0;
    float3 Color : COLOR0;
};

struct VSOutput
{
    float4 Position : SV_Position;
    float3 Color : COLOR0;
};

VSOutput main(VSInput input)
{
    VSOutput output;
    output.Position = float4(input.Position, 1.0);
    output.Color = input.Color;
    return output;
}
""";

        // Simple fragment shader
        String fragmentShaderSource = """
struct PSInput
{
    float4 Position : SV_Position;
    float3 Color : COLOR0;
};

float4 main(PSInput input) : SV_Target
{
    return float4(input.Color, 1.0);
}
""";

        // Compile shaders
        var vsCode = scope List<uint8>();
        var psCode = scope List<uint8>();
        
        CompileShaderFromSource(vertexShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_VERTEX, "main", vsCode);
        CompileShaderFromSource(fragmentShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT, "main", psCode);

        // Create shader objects
        var vsDesc = SDL_GPUShaderCreateInfo()
        {
            code = vsCode.Ptr,
            code_size = (uint32)vsCode.Count,
            entrypoint = "main",
            format = ShaderFormat,
            stage = .SDL_GPU_SHADERSTAGE_VERTEX,
            num_samplers = 0,
            num_uniform_buffers = 0,
            num_storage_buffers = 0,
            num_storage_textures = 0
        };
        mVertexShader = SDL_CreateGPUShader(mDevice, &vsDesc);

        var psDesc = SDL_GPUShaderCreateInfo()
        {
            code = psCode.Ptr,
            code_size = (uint32)psCode.Count,
            entrypoint = "main",
            format = ShaderFormat,
            stage = .SDL_GPU_SHADERSTAGE_FRAGMENT,
            num_samplers = 0,
            num_uniform_buffers = 0,
            num_storage_buffers = 0,
            num_storage_textures = 0
        };
        mFragmentShader = SDL_CreateGPUShader(mDevice, &psDesc);
    }

    private void CreatePipeline()
    {
        // Query the swapchain format
        SDL_GPUTextureFormat swapchainFormat = SDL_GetGPUSwapchainTextureFormat(mDevice, (SDL_Window*)mPrimaryWindow.GetNativePointer("SDL"));

        // Define vertex attributes
        var vertexAttributes = SDL_GPUVertexAttribute[2](
            .{ location = 0, buffer_slot = 0, format = .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, offset = 0 },    // Position
            .{ location = 1, buffer_slot = 0, format = .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, offset = 12 }    // Color
        );

        var vertexBufferDesc = SDL_GPUVertexBufferDescription()
        {
            slot = 0,
            pitch = 24, // sizeof(Vector3) * 2
            input_rate = .SDL_GPU_VERTEXINPUTRATE_VERTEX,
            instance_step_rate = 0
        };

        var vertexInputState = SDL_GPUVertexInputState()
        {
            vertex_buffer_descriptions = &vertexBufferDesc,
            num_vertex_buffers = 1,
            vertex_attributes = &vertexAttributes[0],
            num_vertex_attributes = 2
        };

        var colorTargetDesc = SDL_GPUColorTargetDescription()
        {
            format = swapchainFormat,
            blend_state = .{
                src_color_blendfactor = .SDL_GPU_BLENDFACTOR_ONE,
                dst_color_blendfactor = .SDL_GPU_BLENDFACTOR_ZERO,
                color_blend_op = .SDL_GPU_BLENDOP_ADD,
                src_alpha_blendfactor = .SDL_GPU_BLENDFACTOR_ONE,
                dst_alpha_blendfactor = .SDL_GPU_BLENDFACTOR_ZERO,
                alpha_blend_op = .SDL_GPU_BLENDOP_ADD,
                color_write_mask = .SDL_GPU_COLORCOMPONENT_R | .SDL_GPU_COLORCOMPONENT_G | 
                                  .SDL_GPU_COLORCOMPONENT_B | .SDL_GPU_COLORCOMPONENT_A,
                enable_blend = false,
                enable_color_write_mask = false
            }
        };

        var targetInfo = SDL_GPUGraphicsPipelineTargetInfo()
        {
            color_target_descriptions = &colorTargetDesc,
            num_color_targets = 1,
            depth_stencil_format = .SDL_GPU_TEXTUREFORMAT_INVALID,
            has_depth_stencil_target = false
        };

        var pipelineDesc = SDL_GPUGraphicsPipelineCreateInfo()
        {
            vertex_shader = mVertexShader,
            fragment_shader = mFragmentShader,
            vertex_input_state = vertexInputState,
            primitive_type = .SDL_GPU_PRIMITIVETYPE_TRIANGLELIST,
            rasterizer_state = .{
                cull_mode = .SDL_GPU_CULLMODE_NONE,
                front_face = .SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE,
                fill_mode = .SDL_GPU_FILLMODE_FILL,
                enable_depth_bias = false,
                depth_bias_constant_factor = 0.0f,
                depth_bias_clamp = 0.0f,
                depth_bias_slope_factor = 0.0f
            },
            multisample_state = .{
                sample_count = .SDL_GPU_SAMPLECOUNT_1,
                sample_mask = 0,
                enable_mask = false
            },
            depth_stencil_state = .{
                compare_op = .SDL_GPU_COMPAREOP_ALWAYS,
                back_stencil_state = .{},
                front_stencil_state = .{},
                compare_mask = 0,
                write_mask = 0,
                enable_depth_test = false,
                enable_depth_write = false,
                enable_stencil_test = false
            },
            target_info = targetInfo,
            props = 0
        };

        mTrianglePipeline = SDL_CreateGPUGraphicsPipeline(mDevice, &pipelineDesc);
    }

    private void OnUpdate(IEngine.UpdateInfo info)
    {
        // Nothing to update for now
    }

    private void OnRender(IEngine.UpdateInfo info)
    {
        var commandBuffer = SDL_AcquireGPUCommandBuffer(mDevice);
        
        // Get swapchain texture
        SDL_GPUTexture* swapchainTexture = null;
        SDL_WaitAndAcquireGPUSwapchainTexture(commandBuffer, 
            (SDL_Window*)mPrimaryWindow.GetNativePointer("SDL"), 
            &swapchainTexture, null, null);

        if (swapchainTexture != null)
        {
            // Begin render pass
            var colorTarget = SDL_GPUColorTargetInfo()
            {
                texture = swapchainTexture,
                clear_color = .{ r = 0.2f, g = 0.3f, b = 0.4f, a = 1.0f },
                load_op = .SDL_GPU_LOADOP_CLEAR,
                store_op = .SDL_GPU_STOREOP_STORE
            };

            var renderPass = SDL_BeginGPURenderPass(commandBuffer, &colorTarget, 1, null);

            // Set viewport
            var viewport = SDL_GPUViewport()
            {
                x = 0, y = 0,
                w = (float)Width,
                h = (float)Height,
                min_depth = 0.0f,
                max_depth = 1.0f
            };
            SDL_SetGPUViewport(renderPass, &viewport);

            // Bind pipeline
            SDL_BindGPUGraphicsPipeline(renderPass, mTrianglePipeline);

            // Bind vertex buffer
            var vertexBinding = SDL_GPUBufferBinding()
            {
                buffer = mTriangleVertexBuffer,
                offset = 0
            };
            SDL_BindGPUVertexBuffers(renderPass, 0, &vertexBinding, 1);

            // Draw triangle
            SDL_DrawGPUPrimitives(renderPass, 3, 1, 0, 0);

            SDL_EndGPURenderPass(renderPass);
        }

        SDL_SubmitGPUCommandBuffer(commandBuffer);
    }

    private void CompileShaderFromSource(String source, SDL_ShaderCross_ShaderStage stage, 
        String entrypoint, List<uint8> byteCode)
    {
        SDL_ShaderCross_HLSL_Info hlslInfo = .()
        {
            source = source.CStr(),
            entrypoint = entrypoint.CStr(),
            shader_stage = stage,
            enable_debug = false
        };

        uint spirvByteCodeSize = 0;
        void* spirvByteCode = SDL_ShaderCross_CompileSPIRVFromHLSL(&hlslInfo, &spirvByteCodeSize);
        if(spirvByteCode == null)
        {
            Runtime.FatalError(scope $"Shader compilation failed: {StringView(SDL_GetError())}");
        }

        byteCode.AddRange(Span<uint8>((uint8*)spirvByteCode, (int)spirvByteCodeSize));
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
		if (spirvByteCode == null)
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