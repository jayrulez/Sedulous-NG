using Sedulous.Engine.Core;
using SDL3_shadercross;
using System.Collections;
using System;
using System.IO;
using SDL3Native;
using Sedulous.Foundation.Mathematics;
using Sedulous.Platform.Core;
using Sedulous.Platform.SDL3;
using Sedulous.SceneGraph;
using Sedulous.Geometry;

namespace Sedulous.Engine.Renderer.SDL;

struct Vertex
{
	public Vector3 Position;
	public Vector3 Normal;
	public Vector2 TexCoord;
	public Vector4 Color;
}

struct CameraData
{
	public Matrix ViewMatrix;
	public Matrix ProjectionMatrix;
	public Matrix ViewProjectionMatrix;
	public Vector3 Position;
	public float _padding0;
	public Vector3 Forward;
	public float _padding1;
}

struct ObjectData
{
	public Matrix WorldMatrix;
	public Matrix NormalMatrix;
}

struct LightData
{
	public Vector3 Direction;
	public float Intensity;
	public Vector3 Color;
	public float _padding;
}

struct MaterialData
{
	public Vector4 AlbedoColor;
	public float Metallic;
	public float Roughness;
	public float AmbientOcclusion;
	public float _padding;
}

class SDLRendererSubsystem : Subsystem
{
	public override StringView Name => "SDLRenderer";

	internal SDL_GPUDevice* mDevice;
	internal SDL3Window mPrimaryWindow;

	internal SDL_GPUShaderFormat ShaderFormat = .SDL_GPU_SHADERFORMAT_SPIRV; // Set appropriately

	private IEngine.RegisteredUpdateFunctionInfo? mUpdateFunctionRegistration;
	private IEngine.RegisteredUpdateFunctionInfo? mRenderFunctionRegistration;

	// Pipelines
	private SDL_GPUGraphicsPipeline* mLitPipeline;
	private SDL_GPUGraphicsPipeline* mUnlitPipeline;
	private SDL_GPUShader* mLitVertexShader;
	private SDL_GPUShader* mLitFragmentShader;
	private SDL_GPUShader* mUnlitVertexShader;
	private SDL_GPUShader* mUnlitFragmentShader;

	// Default resources
	private SDL_GPUBuffer* mCubeVertexBuffer;
	private SDL_GPUBuffer* mCubeIndexBuffer;
	private uint32 mGeometryIndexCount;

	// Uniform buffers
	private SDL_GPUBuffer* mVertexUniformBuffer;
	private SDL_GPUBuffer* mFragmentUniformBuffer;

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
		CreateDefaultMeshes();
		CreateUniformBuffers();
		CreateShaders();
		CreatePipelines();

		return base.OnInitializing(engine);
	}

	protected override void OnUnitializing(IEngine engine)
	{
		// Cleanup
		SDL_ReleaseGPUGraphicsPipeline(mDevice, mLitPipeline);
		SDL_ReleaseGPUGraphicsPipeline(mDevice, mUnlitPipeline);
		SDL_ReleaseGPUShader(mDevice, mLitVertexShader);
		SDL_ReleaseGPUShader(mDevice, mLitFragmentShader);
		SDL_ReleaseGPUShader(mDevice, mUnlitVertexShader);
		SDL_ReleaseGPUShader(mDevice, mUnlitFragmentShader);
		SDL_ReleaseGPUBuffer(mDevice, mCubeVertexBuffer);
		SDL_ReleaseGPUBuffer(mDevice, mCubeIndexBuffer);
		SDL_ReleaseGPUBuffer(mDevice, mVertexUniformBuffer);
		SDL_ReleaseGPUBuffer(mDevice, mFragmentUniformBuffer);

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

	private void CreateDefaultMeshes()
	{
	    var geometry = Mesh.CreateCylinder();
	    for(int32 i = 0; i < geometry.Vertices.VertexCount; i++)
	    {
	        geometry.SetColor(i, Color.White.PackedValue);
	    }
	    defer delete geometry;

	    mGeometryIndexCount = (uint32)geometry.Indices.IndexCount;

	    // Calculate buffer sizes once
	    uint32 vertexDataSize = uint32(geometry.Vertices.VertexSize * geometry.Vertices.VertexCount);
	    uint32 indexDataSize = uint32(geometry.Indices.GetIndexSize() * geometry.Indices.IndexCount);
	    uint32 totalDataSize = vertexDataSize + indexDataSize;

	    // Create vertex buffer
	    var vertexBufferDesc = SDL_GPUBufferCreateInfo()
	        {
	            usage = .SDL_GPU_BUFFERUSAGE_VERTEX,
	            size = vertexDataSize
	        };
	    mCubeVertexBuffer = SDL_CreateGPUBuffer(mDevice, &vertexBufferDesc);

	    // Create index buffer
	    var indexBufferDesc = SDL_GPUBufferCreateInfo()
	        {
	            usage = .SDL_GPU_BUFFERUSAGE_INDEX,
	            size = indexDataSize
	        };
	    mCubeIndexBuffer = SDL_CreateGPUBuffer(mDevice, &indexBufferDesc);

	    // Upload data
	    var transferBuffer = SDL_CreateGPUTransferBuffer(mDevice, scope .()
	        {
	            size = totalDataSize,
	            usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD
	        });

	    void* mappedData = SDL_MapGPUTransferBuffer(mDevice, transferBuffer, false);
	    Internal.MemCpy(mappedData, geometry.Vertices.GetRawData(), vertexDataSize);
	    Internal.MemCpy((uint8*)mappedData + vertexDataSize, geometry.Indices.GetRawData(), indexDataSize);
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
	            buffer = mCubeVertexBuffer,
	            offset = 0,
	            size = vertexDataSize
	        }, false);

	    SDL_UploadToGPUBuffer(copyPass, scope .()
	        {
	            transfer_buffer = transferBuffer,
	            offset = vertexDataSize
	        }, scope .()
	        {
	            buffer = mCubeIndexBuffer,
	            offset = 0,
	            size = indexDataSize
	        }, false);

	    SDL_EndGPUCopyPass(copyPass);
	    SDL_SubmitGPUCommandBuffer(commandBuffer);
	    SDL_ReleaseGPUTransferBuffer(mDevice, transferBuffer);
	}

	private void CreateUniformBuffers()
	{
		// Create vertex uniform buffer (large enough for lit shader uniforms)
		var vertexUniformDesc = SDL_GPUBufferCreateInfo()
			{
				usage = .SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ,
				size = sizeof(Matrix) * 3 // ViewProjection, World, NormalMatrix
			};

		mVertexUniformBuffer = SDL_CreateGPUBuffer(mDevice, &vertexUniformDesc);

		// Create fragment uniform buffer
		var fragmentUniformDesc = SDL_GPUBufferCreateInfo()
			{
				usage = .SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ,
				size = sizeof(Vector4) * 4 // LightDir+Intensity, LightColor+pad, MaterialColor, CameraPos+pad
			};
		mFragmentUniformBuffer = SDL_CreateGPUBuffer(mDevice, &fragmentUniformDesc);
	}

	private void CreateShaders()
	{
		// Simple lit vertex shader with uint32 color
		String litVertexShaderSource = """
		struct VSInput
		{
		    float3 Position : POSITION0;
		    float3 Normal : NORMAL0;
		    float2 TexCoord : TEXCOORD0;
		    uint Color : COLOR0;
		};

		struct VSOutput
		{
		    float4 Position : SV_Position;
		    float3 WorldPos : TEXCOORD0;
		    float3 Normal : NORMAL0;
		    float2 TexCoord : TEXCOORD1;
		    float4 Color : COLOR0;
		};

		// Helper function to unpack uint32 color to float4
		float4 UnpackColor(uint packedColor)
		{
		    float4 color;
		    color.r = float((packedColor >> 0) & 0xFF) / 255.0;
		    color.g = float((packedColor >> 8) & 0xFF) / 255.0;
		    color.b = float((packedColor >> 16) & 0xFF) / 255.0;
		    color.a = float((packedColor >> 24) & 0xFF) / 255.0;
		    return color;
		}

		VSOutput main(VSInput input)
		{
		    VSOutput output;
		    // For now, just pass through with basic projection
		    output.Position = float4(input.Position * 0.5, 1.0);
		    output.WorldPos = input.Position;
		    output.Normal = input.Normal;
		    output.TexCoord = input.TexCoord;
		    output.Color = UnpackColor(input.Color);
		    return output;
		}
		""";

		// Lit fragment shader (no changes needed since it receives float4)
		String litFragmentShaderSource = """
		struct PSInput
		{
		    float4 Position : SV_Position;
		    float3 WorldPos : TEXCOORD0;
		    float3 Normal : NORMAL0;
		    float2 TexCoord : TEXCOORD1;
		    float4 Color : COLOR0;
		};

		float4 main(PSInput input) : SV_Target
		{
		    // Simple directional lighting
		    float3 lightDir = normalize(float3(0.5, -1.0, 0.5));
		    
		    float3 normal = normalize(input.Normal);
		    
		    float NdotL = max(dot(normal, -lightDir), 0.0);
		    
		    float3 diffuse = NdotL * float3(1, 1, 1);
		    
		    float3 ambient = float3(0.3, 0.3, 0.3);
		    
		    float3 finalColor = (ambient + diffuse) * input.Color.rgb;
		    
		    return float4(finalColor, input.Color.a);
		}
		""";

		// Simple unlit vertex shader with uint32 color
		String unlitVertexShaderSource = """
		struct VSInput
		{
		    float3 Position : POSITION0;
		    float3 Normal : NORMAL0;
		    float2 TexCoord : TEXCOORD0;
		    uint Color : COLOR0;
		};

		struct VSOutput
		{
		    float4 Position : SV_Position;
		    float2 TexCoord : TEXCOORD0;
		    float4 Color : COLOR0;
		};

		// Helper function to unpack uint32 color to float4
		float4 UnpackColor(uint packedColor)
		{
		    float4 color;
		    color.r = float((packedColor >> 0) & 0xFF) / 255.0;
		    color.g = float((packedColor >> 8) & 0xFF) / 255.0;
		    color.b = float((packedColor >> 16) & 0xFF) / 255.0;
		    color.a = float((packedColor >> 24) & 0xFF) / 255.0;
		    return color;
		}

		VSOutput main(VSInput input)
		{
		    VSOutput output;
		    output.Position = float4(input.Position * 0.5, 1.0);
		    output.TexCoord = input.TexCoord;
		    output.Color = UnpackColor(input.Color);
		    return output;
		}
		""";

		// Unlit fragment shader (no changes needed since it receives float4)
		String unlitFragmentShaderSource = """
		struct PSInput
		{
		    float4 Position : SV_Position;
		    float2 TexCoord : TEXCOORD0;
		    float4 Color : COLOR0;
		};

		float4 main(PSInput input) : SV_Target
		{
		    return input.Color;
		}
		""";

		// Compile all shaders
		var litVsCode = scope List<uint8>();
		var litPsCode = scope List<uint8>();
		var unlitVsCode = scope List<uint8>();
		var unlitPsCode = scope List<uint8>();

		CompileShaderFromSource(litVertexShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_VERTEX, "main", litVsCode);
		CompileShaderFromSource(litFragmentShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT, "main", litPsCode);
		CompileShaderFromSource(unlitVertexShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_VERTEX, "main", unlitVsCode);
		CompileShaderFromSource(unlitFragmentShaderSource, .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT, "main", unlitPsCode);

		// Create shader objects
		var litVsDesc = SDL_GPUShaderCreateInfo()
			{
				code = litVsCode.Ptr,
				code_size = (uint32)litVsCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_VERTEX,
				num_samplers = 0,
				num_uniform_buffers = 0,
				num_storage_buffers = 0,
				num_storage_textures = 0
			};
		mLitVertexShader = SDL_CreateGPUShader(mDevice, &litVsDesc);

		var litPsDesc = SDL_GPUShaderCreateInfo()
			{
				code = litPsCode.Ptr,
				code_size = (uint32)litPsCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_FRAGMENT,
				num_samplers = 0,
				num_uniform_buffers = 0,
				num_storage_buffers = 0,
				num_storage_textures = 0
			};
		mLitFragmentShader = SDL_CreateGPUShader(mDevice, &litPsDesc);

		var unlitVsDesc = SDL_GPUShaderCreateInfo()
			{
				code = unlitVsCode.Ptr,
				code_size = (uint32)unlitVsCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_VERTEX,
				num_samplers = 0,
				num_uniform_buffers = 0,
				num_storage_buffers = 0,
				num_storage_textures = 0
			};
		mUnlitVertexShader = SDL_CreateGPUShader(mDevice, &unlitVsDesc);

		var unlitPsDesc = SDL_GPUShaderCreateInfo()
			{
				code = unlitPsCode.Ptr,
				code_size = (uint32)unlitPsCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_FRAGMENT,
				num_samplers = 0,
				num_uniform_buffers = 0,
				num_storage_buffers = 0,
				num_storage_textures = 0
			};
		mUnlitFragmentShader = SDL_CreateGPUShader(mDevice, &unlitPsDesc);
	}

	private void CreatePipelines()
	{
		// Query the swapchain format
		SDL_GPUTextureFormat swapchainFormat = SDL_GetGPUSwapchainTextureFormat(mDevice, (SDL_Window*)mPrimaryWindow.GetNativePointer("SDL"));

		// Define vertex attributes
		var vertexAttributes = SDL_GPUVertexAttribute[4](
			. { location = 0, buffer_slot = 0, format = .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, offset = 0 }, // Position
			. { location = 1, buffer_slot = 0, format = .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, offset = 12 }, // Normal
			. { location = 2, buffer_slot = 0, format = .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, offset = 24 }, // TexCoord
			. { location = 3, buffer_slot = 0, format = .SDL_GPU_VERTEXELEMENTFORMAT_UINT, offset = 32 } // Color
			);

		var vertexBufferDesc = SDL_GPUVertexBufferDescription()
			{
				slot = 0,
				pitch = sizeof(Vector3) + sizeof(Vector3) + sizeof(Vector2) + sizeof(uint32),
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
				format = swapchainFormat,
				blend_state = .
					{
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
				depth_stencil_format = .SDL_GPU_TEXTUREFORMAT_D32_FLOAT,
				has_depth_stencil_target = true
			};

		var pipelineDesc = SDL_GPUGraphicsPipelineCreateInfo()
			{
				vertex_shader = mLitVertexShader,
				fragment_shader = mLitFragmentShader,
				vertex_input_state = vertexInputState,
				primitive_type = .SDL_GPU_PRIMITIVETYPE_TRIANGLELIST,
				rasterizer_state = .
					{
						cull_mode = .SDL_GPU_CULLMODE_BACK,
						front_face = .SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE,
						fill_mode = .SDL_GPU_FILLMODE_FILL,
						enable_depth_bias = false,
						depth_bias_constant_factor = 0.0f,
						depth_bias_clamp = 0.0f,
						depth_bias_slope_factor = 0.0f
					},
				multisample_state = .
					{
						sample_count = .SDL_GPU_SAMPLECOUNT_1,
						sample_mask = 0,
						enable_mask = false
					},
				depth_stencil_state = .
					{
						compare_op = .SDL_GPU_COMPAREOP_LESS,
						back_stencil_state = . { },
						front_stencil_state = . { },
						compare_mask = 0,
						write_mask = 0,
						enable_depth_test = true,
						enable_depth_write = true,
						enable_stencil_test = false
					},
				target_info = targetInfo,
				props = 0
			};

		mLitPipeline = SDL_CreateGPUGraphicsPipeline(mDevice, &pipelineDesc);

		// Create unlit pipeline
		pipelineDesc.vertex_shader = mUnlitVertexShader;
		pipelineDesc.fragment_shader = mUnlitFragmentShader;
		pipelineDesc.depth_stencil_state.enable_depth_test = false;
		pipelineDesc.depth_stencil_state.enable_depth_write = false;
		pipelineDesc.rasterizer_state.cull_mode = .SDL_GPU_CULLMODE_NONE;

		mUnlitPipeline = SDL_CreateGPUGraphicsPipeline(mDevice, &pipelineDesc);
	}

	private void OnUpdate(IEngine.UpdateInfo info)
	{
		// Nothing to update for now
	}

	private void OnRender(IEngine.UpdateInfo info)
	{
		// Rendering is now handled by the RenderModule
	}

	public SDL_GPUGraphicsPipeline* GetPipeline(bool lit)
	{
		return lit ? mLitPipeline : mUnlitPipeline;
	}

	public void GetDefaultMesh(out SDL_GPUBuffer* vertexBuffer, out SDL_GPUBuffer* indexBuffer, out uint32 indexCount)
	{
		vertexBuffer = mCubeVertexBuffer;
		indexBuffer = mCubeIndexBuffer;
		indexCount = mGeometryIndexCount;
	}

	public void GetUniformBuffers(out SDL_GPUBuffer* vertexUniformBuffer, out SDL_GPUBuffer* fragmentUniformBuffer)
	{
		vertexUniformBuffer = mVertexUniformBuffer;
		fragmentUniformBuffer = mFragmentUniformBuffer;
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
		if (spirvByteCode == null)
		{
			Runtime.FatalError(scope $"Shader compilation failed: {StringView(SDL_GetError())}");
		}

		byteCode.AddRange(Span<uint8>((uint8*)spirvByteCode, (int)spirvByteCodeSize));
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
}