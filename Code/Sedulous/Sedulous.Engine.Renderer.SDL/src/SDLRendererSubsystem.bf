using Sedulous.Engine.Core;
using SDL3_shadercross;
using System.Collections;
using System;
using System.IO;
using SDL3Native;
using Sedulous.Mathematics;
using Sedulous.Platform.Core;
using Sedulous.Platform.SDL3;
using Sedulous.SceneGraph;
using Sedulous.Geometry;

namespace Sedulous.Engine.Renderer.SDL;

using internal Sedulous.Engine.Renderer.SDL;

// Uniform buffer structures must match shader exactly and follow HLSL alignment rules
static
{
	public const int MAX_LIGHTS = 16;
}

[CRepr, Packed]
struct LitVertexUniforms
{
	public Matrix MVPMatrix; // 64 bytes (4x float4)
	public Matrix ModelMatrix; // 64 bytes (4x float4)
	public Matrix NormalMatrix; // 64 bytes (4x float4)
	// Total: 192 bytes (multiple of 16)
}

[CRepr, Packed]
struct LightData
{
	public Vector4 PositionType; // xyz = position, w = type (0=dir, 1=point, 2=spot)
	public Vector4 DirectionRange; // xyz = direction, w = range
	public Vector4 ColorIntensity; // xyz = color, w = intensity
	public Vector4 SpotAngles; // x = inner angle cos, y = outer angle cos, z = constant atten, w = linear atten
	// Total: 64 bytes per light
}

[CRepr, Packed]
struct LitFragmentUniforms
{
	// Material properties
	public Vector4 MaterialColor; // 16 bytes - diffuse color
	public Vector4 SpecularColorShininess; // 16 bytes - xyz = specular color, w = shininess
	public Vector4 AmbientColor; // 16 bytes - ambient color
	public Vector4 CameraPos; // 16 bytes - xyz = position, w = padding
	
	// Light array
	public LightData[MAX_LIGHTS] Lights; // 64 * 16 = 1024 bytes
	public Vector4 LightCount; // 16 bytes - x = active light count, yzw = padding
	
	// Total: 1088 bytes (multiple of 16)
}

[CRepr, Packed]
struct UnlitVertexUniforms
{
	public Matrix MVPMatrix; // 64 bytes (4x float4)
	public Matrix ModelMatrix; // 64 bytes (4x float4)
	// Total: 128 bytes (multiple of 16)
}

[CRepr, Packed]
struct UnlitFragmentUniforms
{
	public Vector4 MaterialColor; // 16 bytes
	// Total: 16 bytes (multiple of 16)
}

[CRepr, Packed]
struct SpriteVertexUniforms
{
	public Matrix MVPMatrix; // 64 bytes (4x float4)
	public Vector4 UVOffsetScale; // 16 bytes - xy = offset, zw = scale
	// Total: 80 bytes (multiple of 16)
}

[CRepr, Packed]
struct SpriteFragmentUniforms
{
	public Vector4 TintColor; // 16 bytes - rgba tint color
	// Total: 16 bytes (multiple of 16)
}

[CRepr, Packed]
struct PBRVertexUniforms
{
	public Matrix MVPMatrix; // 64 bytes (4x float4)
	public Matrix ModelMatrix; // 64 bytes (4x float4)
	public Matrix NormalMatrix; // 64 bytes (4x float4)
	// Total: 192 bytes (multiple of 16)
}

[CRepr, Packed]
struct PBRFragmentUniforms
{
	// Material properties
	public Vector4 AlbedoColor; // 16 bytes - base color
	public Vector4 EmissiveColor; // 16 bytes - xyz = emissive, w = intensity
	public Vector4 MetallicRoughnessAO; // 16 bytes - x = metallic, y = roughness, z = AO, w = padding
	public Vector4 CameraPos; // 16 bytes - xyz = position, w = padding
	
	// Light array
	public LightData[MAX_LIGHTS] Lights; // 64 * 16 = 1024 bytes
	public Vector4 LightCount; // 16 bytes - x = active light count, yzw = padding
	
	// Total: 1088 bytes (multiple of 16)
}

class SDLRendererSubsystem : Subsystem
{
	public override StringView Name => "SDLRenderer";

	internal SDL_GPUDevice* mDevice;
	internal SDL3Window mPrimaryWindow;

	internal SDL_GPUShaderFormat ShaderFormat = .SDL_GPU_SHADERFORMAT_SPIRV; // Set appropriately

	private IEngine.RegisteredUpdateFunctionInfo? mUpdateFunctionRegistration;
	private IEngine.RegisteredUpdateFunctionInfo? mRenderFunctionRegistration;

	private readonly MeshResourceManager mMeshResourceManager = new .() ~ delete _;
	private readonly TextureResourceManager mTextureResourceManager = new .() ~ delete _;
	private readonly MaterialResourceManager mMaterialResourceManager = new .() ~ delete _;

	private List<RenderModule> mRenderModules = new .() ~ delete _;

	// Pipelines
	private SDL_GPUGraphicsPipeline* mLitPipeline;
	private SDL_GPUGraphicsPipeline* mUnlitPipeline;
	private SDL_GPUGraphicsPipeline* mPBRPipeline;
	private SDL_GPUGraphicsPipeline* mSpritePipeline;
	// private SDL_GPUGraphicsPipeline* mLitPipelineWithTangents;
	// private SDL_GPUGraphicsPipeline* mPBRPipelineWithTangents;
	private SDL_GPUShader* mLitVertexShader;
	private SDL_GPUShader* mLitFragmentShader;
	private SDL_GPUShader* mUnlitVertexShader;
	private SDL_GPUShader* mUnlitFragmentShader;
	private SDL_GPUShader* mPBRVertexShader;
	private SDL_GPUShader* mPBRFragmentShader;
	private SDL_GPUShader* mSpriteVertexShader;
	private SDL_GPUShader* mSpriteFragmentShader;

	// Default textures
	private GPUResourceHandle<GPUTexture> mDefaultWhiteTexture;
	private GPUResourceHandle<GPUTexture> mDefaultBlackTexture;
	private GPUResourceHandle<GPUTexture> mDefaultNormalTexture;

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

		engine.ResourceSystem.AddResourceManager(mMeshResourceManager);
		engine.ResourceSystem.AddResourceManager(mTextureResourceManager);
		engine.ResourceSystem.AddResourceManager(mMaterialResourceManager);

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
		CreateShaders();
		CreatePipelines();
		CreateDefaultTextures();

		return base.OnInitializing(engine);
	}

	protected override void OnUnitializing(IEngine engine)
	{
		// Cleanup
		mDefaultWhiteTexture.Release();
		mDefaultBlackTexture.Release();
		mDefaultNormalTexture.Release();

		SDL_ReleaseGPUGraphicsPipeline(mDevice, mLitPipeline);
		SDL_ReleaseGPUGraphicsPipeline(mDevice, mUnlitPipeline);
		SDL_ReleaseGPUGraphicsPipeline(mDevice, mPBRPipeline);
		SDL_ReleaseGPUGraphicsPipeline(mDevice, mSpritePipeline);
		//if (mLitPipelineWithTangents != null)
		//    SDL_ReleaseGPUGraphicsPipeline(mDevice, mLitPipelineWithTangents);
		//if (mPBRPipelineWithTangents != null)
		//    SDL_ReleaseGPUGraphicsPipeline(mDevice, mPBRPipelineWithTangents);
		SDL_ReleaseGPUShader(mDevice, mLitVertexShader);
		SDL_ReleaseGPUShader(mDevice, mLitFragmentShader);
		SDL_ReleaseGPUShader(mDevice, mUnlitVertexShader);
		SDL_ReleaseGPUShader(mDevice, mUnlitFragmentShader);
		SDL_ReleaseGPUShader(mDevice, mPBRVertexShader);
		SDL_ReleaseGPUShader(mDevice, mPBRFragmentShader);
		SDL_ReleaseGPUShader(mDevice, mSpriteVertexShader);
		SDL_ReleaseGPUShader(mDevice, mSpriteFragmentShader);

		SDL_ReleaseWindowFromGPUDevice(mDevice, (SDL_Window*)mPrimaryWindow.GetNativePointer("SDL"));

		SDL_DestroyGPUDevice(mDevice);

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

		base.OnUnitializing(engine);
	}

	protected override void CreateSceneModules(Scene scene, List<SceneModule> modules)
	{
		var renderModule = new RenderModule(this);
		modules.Add(renderModule);
		mRenderModules.Add(renderModule);
	}

	protected override void DestroySceneModules(Scene scene)
	{
		for (int i = mRenderModules.Count - 1; i >= 0; i--)
		{
			if (mRenderModules[i].Scene == scene)
			{
				delete mRenderModules[i];
				mRenderModules.RemoveAt(i);
			}
		}
	}

	private void CreateShaders()
	{
		// Compile all shaders
		var litVsCode = scope List<uint8>();
		var litPsCode = scope List<uint8>();
		var unlitVsCode = scope List<uint8>();
		var unlitPsCode = scope List<uint8>();
		var pbrVsCode = scope List<uint8>();
		var pbrPsCode = scope List<uint8>();
		var spriteVsCode = scope List<uint8>();
		var spritePsCode = scope List<uint8>();

		CompileShaderFromSource(ShaderSources.LitVertex, .SDL_SHADERCROSS_SHADERSTAGE_VERTEX, "main", litVsCode);
		CompileShaderFromSource(ShaderSources.LitFragment, .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT, "main", litPsCode);
		CompileShaderFromSource(ShaderSources.UnlitVertex, .SDL_SHADERCROSS_SHADERSTAGE_VERTEX, "main", unlitVsCode);
		CompileShaderFromSource(ShaderSources.UnlitFragment, .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT, "main", unlitPsCode);
		CompileShaderFromSource(ShaderSources.PBRVertex, .SDL_SHADERCROSS_SHADERSTAGE_VERTEX, "main", pbrVsCode);
		CompileShaderFromSource(ShaderSources.PBRFragment, .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT, "main", pbrPsCode);
		CompileShaderFromSource(ShaderSources.SpriteVertex, .SDL_SHADERCROSS_SHADERSTAGE_VERTEX, "main", spriteVsCode);
		CompileShaderFromSource(ShaderSources.SpriteFragment, .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT, "main", spritePsCode);

		// Create shader objects
		var litVsDesc = SDL_GPUShaderCreateInfo()
			{
				code = litVsCode.Ptr,
				code_size = (uint32)litVsCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_VERTEX,
				num_samplers = 0,
				num_uniform_buffers = 1, // We have 1 uniform buffer
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
				num_samplers = 1, // We have 1 texture sampler
				num_uniform_buffers = 1, // We have 1 uniform buffer
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
				num_uniform_buffers = 1, // We have 1 uniform buffer
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
				num_samplers = 1, // We have 1 texture sampler
				num_uniform_buffers = 1, // We have 1 uniform buffer
				num_storage_buffers = 0,
				num_storage_textures = 0
			};
		mUnlitFragmentShader = SDL_CreateGPUShader(mDevice, &unlitPsDesc);

		// Create PBR shaders
		var pbrVsDesc = SDL_GPUShaderCreateInfo()
			{
				code = pbrVsCode.Ptr,
				code_size = (uint32)pbrVsCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_VERTEX,
				num_samplers = 0,
				num_uniform_buffers = 1, // We have 1 uniform buffer
				num_storage_buffers = 0,
				num_storage_textures = 0
			};
		mPBRVertexShader = SDL_CreateGPUShader(mDevice, &pbrVsDesc);

		var pbrPsDesc = SDL_GPUShaderCreateInfo()
			{
				code = pbrPsCode.Ptr,
				code_size = (uint32)pbrPsCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_FRAGMENT,
				num_samplers = 3, // Albedo, Normal, MetallicRoughness
				num_uniform_buffers = 1, // We have 1 uniform buffer
				num_storage_buffers = 0,
				num_storage_textures = 0
			};
		mPBRFragmentShader = SDL_CreateGPUShader(mDevice, &pbrPsDesc);

		// Create sprite shaders
		var spriteVsDesc = SDL_GPUShaderCreateInfo()
			{
				code = spriteVsCode.Ptr,
				code_size = (uint32)spriteVsCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_VERTEX,
				num_samplers = 0,
				num_uniform_buffers = 1, // We have 1 uniform buffer
				num_storage_buffers = 0,
				num_storage_textures = 0
			};
		mSpriteVertexShader = SDL_CreateGPUShader(mDevice, &spriteVsDesc);

		var spritePsDesc = SDL_GPUShaderCreateInfo()
			{
				code = spritePsCode.Ptr,
				code_size = (uint32)spritePsCode.Count,
				entrypoint = "main",
				format = ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_FRAGMENT,
				num_samplers = 1, // We have 1 sampler for the sprite texture
				num_uniform_buffers = 1, // We have 1 uniform buffer
				num_storage_buffers = 0,
				num_storage_textures = 0
			};
		mSpriteFragmentShader = SDL_CreateGPUShader(mDevice, &spritePsDesc);
	}

	private void CreatePipelines()
	{
	    // Query the swapchain format
	    SDL_GPUTextureFormat swapchainFormat = SDL_GetGPUSwapchainTextureFormat(mDevice, (SDL_Window*)mPrimaryWindow.GetNativePointer("SDL"));

	    // Define vertex attributes for standard format
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

	    SDL_GPUColorTargetBlendState blendState = .()
	    {
	        src_color_blendfactor = .SDL_GPU_BLENDFACTOR_SRC_ALPHA,
	        dst_color_blendfactor = .SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
	        color_blend_op = .SDL_GPU_BLENDOP_ADD,
	        src_alpha_blendfactor = .SDL_GPU_BLENDFACTOR_ONE,
	        dst_alpha_blendfactor = .SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
	        alpha_blend_op = .SDL_GPU_BLENDOP_ADD,
	        color_write_mask = .SDL_GPU_COLORCOMPONENT_R | .SDL_GPU_COLORCOMPONENT_G |
	            .SDL_GPU_COLORCOMPONENT_B | .SDL_GPU_COLORCOMPONENT_A,
	        enable_blend = true,
	        enable_color_write_mask = false
	    };

	    var colorTargetDesc = SDL_GPUColorTargetDescription()
	    {
	        format = swapchainFormat,
	        blend_state = blendState
	    };

	    var targetInfo = SDL_GPUGraphicsPipelineTargetInfo()
	    {
	        color_target_descriptions = &colorTargetDesc,
	        num_color_targets = 1,
	        depth_stencil_format = .SDL_GPU_TEXTUREFORMAT_D32_FLOAT,
	        has_depth_stencil_target = true
	    };

	    SDL_GPURasterizerState rasterState = .()
	    {
	        fill_mode = .SDL_GPU_FILLMODE_FILL,
	        cull_mode = .SDL_GPU_CULLMODE_BACK,
	        front_face = .SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE,
	        depth_bias_constant_factor = 0,
	        depth_bias_clamp = 0,
	        depth_bias_slope_factor = 0,
	        enable_depth_bias = false,
	        enable_depth_clip = true
	    };

	    SDL_GPUDepthStencilState depthStencilState = .()
	    {
	        compare_op = .SDL_GPU_COMPAREOP_LESS,
	        back_stencil_state = .(),
	        front_stencil_state = .(),
	        compare_mask = 0,
	        write_mask = 0,
	        enable_depth_test = true,
	        enable_depth_write = true,
	        enable_stencil_test = false
	    };

	    var pipelineDesc = SDL_GPUGraphicsPipelineCreateInfo()
	    {
	        vertex_shader = mLitVertexShader,
	        fragment_shader = mLitFragmentShader,
	        vertex_input_state = vertexInputState,
	        primitive_type = .SDL_GPU_PRIMITIVETYPE_TRIANGLELIST,
	        rasterizer_state = rasterState,
	        multisample_state = .
	        {
	            sample_count = .SDL_GPU_SAMPLECOUNT_1,
	            sample_mask = 0,
	            enable_mask = false
	        },
	        depth_stencil_state = depthStencilState,
	        target_info = targetInfo,
	        props = 0
	    };

	    mLitPipeline = SDL_CreateGPUGraphicsPipeline(mDevice, &pipelineDesc);

	    // Create unlit pipeline
	    // Reset to default states for unlit
	    pipelineDesc.vertex_shader = mUnlitVertexShader;
	    pipelineDesc.fragment_shader = mUnlitFragmentShader;
	    pipelineDesc.rasterizer_state = rasterState;
	    pipelineDesc.depth_stencil_state = depthStencilState;
	    pipelineDesc.target_info = targetInfo;

	    mUnlitPipeline = SDL_CreateGPUGraphicsPipeline(mDevice, &pipelineDesc);

	    // Create sprite pipeline
	    // Sprite pipeline uses alpha blending and no depth write
	    colorTargetDesc.blend_state = SDL_GPUColorTargetBlendState()
	    {
	        src_color_blendfactor = .SDL_GPU_BLENDFACTOR_SRC_ALPHA,
	        dst_color_blendfactor = .SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
	        color_blend_op = .SDL_GPU_BLENDOP_ADD,
	        src_alpha_blendfactor = .SDL_GPU_BLENDFACTOR_ONE,
	        dst_alpha_blendfactor = .SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
	        alpha_blend_op = .SDL_GPU_BLENDOP_ADD,
	        color_write_mask = .SDL_GPU_COLORCOMPONENT_R | .SDL_GPU_COLORCOMPONENT_G |
	            .SDL_GPU_COLORCOMPONENT_B | .SDL_GPU_COLORCOMPONENT_A,
	        enable_blend = true,
	        enable_color_write_mask = false
	    };

	    targetInfo.color_target_descriptions = &colorTargetDesc;

	    // Sprites test depth but don't write to it
	    depthStencilState.enable_depth_write = false;

	    // No backface culling for sprites (they might be flipped)
	    rasterState.cull_mode = .SDL_GPU_CULLMODE_NONE;

	    pipelineDesc.vertex_shader = mSpriteVertexShader;
	    pipelineDesc.fragment_shader = mSpriteFragmentShader;
	    pipelineDesc.rasterizer_state = rasterState;
	    pipelineDesc.depth_stencil_state = depthStencilState;
	    pipelineDesc.target_info = targetInfo;

	    mSpritePipeline = SDL_CreateGPUGraphicsPipeline(mDevice, &pipelineDesc);

	    // Create PBR pipeline
	    // Reset to default states for PBR
	    colorTargetDesc.blend_state = blendState; // Use the original blend state
	    targetInfo.color_target_descriptions = &colorTargetDesc;

	    depthStencilState.enable_depth_write = true;
	    depthStencilState.enable_depth_test = true;
	    rasterState.cull_mode = .SDL_GPU_CULLMODE_BACK;

	    pipelineDesc.vertex_shader = mPBRVertexShader;
	    pipelineDesc.fragment_shader = mPBRFragmentShader;
	    pipelineDesc.rasterizer_state = rasterState;
	    pipelineDesc.depth_stencil_state = depthStencilState;
	    pipelineDesc.target_info = targetInfo;

	    mPBRPipeline = SDL_CreateGPUGraphicsPipeline(mDevice, &pipelineDesc);

	    // OPTIONAL: Create pipelines with tangent support if you have tangent-aware shaders
	    // CreateTangentPipelines(swapchainFormat);
	}

	// Optional method to create pipelines with tangent vertex format
	// Uncomment if you have created tangent-aware vertex shaders
	/*
	private void CreateTangentPipelines(SDL_GPUTextureFormat swapchainFormat)
	{
	    // Define vertex attributes with tangents
	    var vertexAttributesWithTangents = SDL_GPUVertexAttribute[5](
	        . { location = 0, buffer_slot = 0, format = .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, offset = 0 }, // Position
	        . { location = 1, buffer_slot = 0, format = .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, offset = 12 }, // Normal
	        . { location = 2, buffer_slot = 0, format = .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, offset = 24 }, // TexCoord
	        . { location = 3, buffer_slot = 0, format = .SDL_GPU_VERTEXELEMENTFORMAT_UINT, offset = 32 }, // Color
	        . { location = 4, buffer_slot = 0, format = .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4, offset = 36 } // Tangent
	    );

	    var vertexBufferDescWithTangents = SDL_GPUVertexBufferDescription()
	    {
	        slot = 0,
	        pitch = sizeof(Vector3) + sizeof(Vector3) + sizeof(Vector2) + sizeof(uint32) + sizeof(Vector4),
	        input_rate = .SDL_GPU_VERTEXINPUTRATE_VERTEX,
	        instance_step_rate = 0
	    };

	    var vertexInputStateWithTangents = SDL_GPUVertexInputState()
	    {
	        vertex_buffer_descriptions = &vertexBufferDescWithTangents,
	        num_vertex_buffers = 1,
	        vertex_attributes = &vertexAttributesWithTangents[0],
	        num_vertex_attributes = 5
	    };

	    // Same pipeline creation code as above but with vertexInputStateWithTangents
	    // and tangent-aware shaders (mLitVertexShaderWithTangents, etc.)
	    
	    // You would need separate shaders compiled with tangent support
	    // For now, the screen-space derivative approach works without this
	}
	*/

	private void OnUpdate(IEngine.UpdateInfo info)
	{
		// Nothing to update for now
	}

	private void OnRender(IEngine.UpdateInfo info)
	{
		for (var module in mRenderModules)
		{
			module.RenderFrame();
		}
	}

	public SDL_GPUGraphicsPipeline* GetPipeline(bool lit)
	{
		return lit ? mLitPipeline : mUnlitPipeline;
	}

	public SDL_GPUGraphicsPipeline* GetPBRPipeline()
	{
		return mPBRPipeline;
	}

	public SDL_GPUGraphicsPipeline* GetSpritePipeline()
	{
		return mSpritePipeline;
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

	private void CreateDefaultTextures()
	{
		// Create 1x1 white texture
		{
			var whiteImage = scope Sedulous.Imaging.Image(1, 1, .RGBA8);
			whiteImage.SetPixel(0, 0, .White);
			mDefaultWhiteTexture = GPUResourceHandle<GPUTexture>(new GPUTexture("DefaultWhite", mDevice, whiteImage));
		}

		// Create 1x1 black texture
		{
			var blackImage = scope Sedulous.Imaging.Image(1, 1, .RGBA8);
			blackImage.SetPixel(0, 0, .Black);
			mDefaultBlackTexture = GPUResourceHandle<GPUTexture>(new GPUTexture("DefaultBlack", mDevice, blackImage));
		}

		// Create 1x1 default normal texture (pointing up)
		{
			var normalImage = scope Sedulous.Imaging.Image(1, 1, .RGBA8);
			normalImage.SetPixel(0, 0, Color(128, 128, 255, 255)); // Normal pointing up
			mDefaultNormalTexture = GPUResourceHandle<GPUTexture>(new GPUTexture("DefaultNormal", mDevice, normalImage));
		}
	}

	public GPUResourceHandle<GPUTexture> GetDefaultWhiteTexture() => mDefaultWhiteTexture;
	public GPUResourceHandle<GPUTexture> GetDefaultBlackTexture() => mDefaultBlackTexture;
	public GPUResourceHandle<GPUTexture> GetDefaultNormalTexture() => mDefaultNormalTexture;
}