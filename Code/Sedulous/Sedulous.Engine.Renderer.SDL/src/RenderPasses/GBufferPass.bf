using System;
using System.IO;
using System.Collections;
using Sedulous.Foundation.Mathematics;
using SDL3Native;
namespace Sedulous.Engine.Renderer.SDL.RenderPasses;

using internal Sedulous.Engine.Renderer.SDL;

class GBufferPass : RenderPass
{
	public SDL_GPUTexture* Albedo;
	public SDL_GPUTexture* Normals;
	public SDL_GPUTexture* Roughness;
	public SDL_GPUTexture* Metallic;
	public SDL_GPUTexture* AO;
	public SDL_GPUTexture* Depth;

	private SDL_GPUShader* mVertexShader;
	private SDL_GPUShader* mPixelShader;
	private SDL_GPUGraphicsPipeline* mPipelineState;

	public this(RenderPipeline pipeline) : base(pipeline) { }

	public ~this()
	{

	}

	private void SetSharedResources()
	{
		Pipeline.SetSharedResource("GBuffer.Albedo", Albedo);
		Pipeline.SetSharedResource("GBuffer.Normals", Normals);
		Pipeline.SetSharedResource("GBuffer.Roughness", Roughness);
		Pipeline.SetSharedResource("GBuffer.Metallic", Metallic);
		Pipeline.SetSharedResource("GBuffer.AO", AO);
		Pipeline.SetSharedResource("GBuffer.Depth", Depth);
	}

	private void RemoveSharedResources()
	{
		Pipeline.RemoveSharedResource("GBuffer.Albedo");
		Pipeline.RemoveSharedResource("GBuffer.Normals");
		Pipeline.RemoveSharedResource("GBuffer.Roughness");
		Pipeline.RemoveSharedResource("GBuffer.Metallic");
		Pipeline.RemoveSharedResource("GBuffer.AO");
		Pipeline.RemoveSharedResource("GBuffer.Depth");
	}

	private void CreateResources(uint32 width, uint32 height, SDL_GPUSampleCount sampleCount = .SDL_GPU_SAMPLECOUNT_1, uint32 arraySize = 1)
	{
		DestroyResources();

		{
			// Albedo
			var textureDescription = SDL_GPUTextureCreateInfo()
				{
					type = arraySize > 1 ? .SDL_GPU_TEXTURETYPE_2D_ARRAY : .SDL_GPU_TEXTURETYPE_2D,
					format = .SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,
					width = width,
					height = height,
					layer_count_or_depth = 1,
					num_levels = 1,
					sample_count = sampleCount
				};

			Albedo = SDL_CreateGPUTexture(Renderer.mDevice, &textureDescription);
		}
		{
			// Normals
			// 
			var textureDescription = SDL_GPUTextureCreateInfo()
				{
					type = arraySize > 1 ? .SDL_GPU_TEXTURETYPE_2D_ARRAY : .SDL_GPU_TEXTURETYPE_2D,
					format = .SDL_GPU_TEXTUREFORMAT_R16G16B16A16_FLOAT, // Higher precision for normals
					width = width,
					height = height,
					layer_count_or_depth = 1,
					num_levels = 1,
					sample_count = sampleCount
				};
			Normals = SDL_CreateGPUTexture(Renderer.mDevice, &textureDescription);
		}
		{
			// Roughness
			// 
			var textureDescription = SDL_GPUTextureCreateInfo()
				{
					type = arraySize > 1 ? .SDL_GPU_TEXTURETYPE_2D_ARRAY : .SDL_GPU_TEXTURETYPE_2D,
					format = .SDL_GPU_TEXTUREFORMAT_A8_UNORM, // Stores roughness
					width = width,
					height = height,
					layer_count_or_depth = 1,
					num_levels = 1,
					sample_count = sampleCount
				};

			Roughness = SDL_CreateGPUTexture(Renderer.mDevice, &textureDescription);
		}
		{
			// Metallic
			// 
			var textureDescription = SDL_GPUTextureCreateInfo()
				{
					type = arraySize > 1 ? .SDL_GPU_TEXTURETYPE_2D_ARRAY : .SDL_GPU_TEXTURETYPE_2D,
					format = .SDL_GPU_TEXTUREFORMAT_A8_UNORM, // Stores metallic
					width = width,
					height = height,
					layer_count_or_depth = 1,
					num_levels = 1,
					sample_count = sampleCount
				};

			Metallic = SDL_CreateGPUTexture(Renderer.mDevice, &textureDescription);
		}
		{
			// AO
			// 
			var textureDescription = SDL_GPUTextureCreateInfo()
				{
					type = arraySize > 1 ? .SDL_GPU_TEXTURETYPE_2D_ARRAY : .SDL_GPU_TEXTURETYPE_2D,
					format = .SDL_GPU_TEXTUREFORMAT_A8_UNORM, // AO
					width = width,
					height = height,
					layer_count_or_depth = 1,
					num_levels = 1,
					sample_count = sampleCount
				};

			AO = SDL_CreateGPUTexture(Renderer.mDevice, &textureDescription);
		}
		{
			// Depth
			var textureDescription = SDL_GPUTextureCreateInfo()
				{
					type = arraySize > 1 ? .SDL_GPU_TEXTURETYPE_2D_ARRAY : .SDL_GPU_TEXTURETYPE_2D,
					format = .SDL_GPU_TEXTUREFORMAT_D24_UNORM_S8_UINT, // Depth
					width = width,
					height = height,
					layer_count_or_depth = 1,
					num_levels = 1,
					sample_count = sampleCount
				};

			Depth = SDL_CreateGPUTexture(Renderer.mDevice, &textureDescription);
		}

		SetSharedResources();
	}

	private void DestroyResources()
	{
		RemoveSharedResources();

		SDL_ReleaseGPUTexture(Renderer.mDevice, Albedo);
		SDL_ReleaseGPUTexture(Renderer.mDevice, Normals);
		SDL_ReleaseGPUTexture(Renderer.mDevice, Roughness);
		SDL_ReleaseGPUTexture(Renderer.mDevice, Metallic);
		SDL_ReleaseGPUTexture(Renderer.mDevice, AO);
		SDL_ReleaseGPUTexture(Renderer.mDevice, Depth);
	}

	public override void Initialize()
	{
		CreateResources(Renderer.Width, Renderer.Height);

		uint8[] vsByteCode = null;
		uint8[] psByteCode = null;

		// VS
		{
			List<uint8> byteCode = scope .();
			Renderer.CompileShader("shaders/GBuffer_VS.hlsl", .SDL_SHADERCROSS_SHADERSTAGE_VERTEX, "main", byteCode);

			vsByteCode = scope:: .[byteCode.Count];
			byteCode.CopyTo(vsByteCode);
		}

		// PS
		{
			List<uint8> byteCode = scope .();
			Renderer.CompileShader("shaders/GBuffer_PS.hlsl", .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT, "main", byteCode);

			psByteCode = scope:: .[byteCode.Count];
			byteCode.CopyTo(psByteCode);
		}

		SDL_GPUShaderCreateInfo vertexShaderDescription = .()
			{
				code = (uint8*)vsByteCode.Ptr,
				code_size = (uint)vsByteCode.Count,
				entrypoint = "main",
				format = Renderer.ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_VERTEX,
				num_samplers = 0,
				num_uniform_buffers = 0,
				num_storage_buffers = 0,
				num_storage_textures = 0
			};//ShaderDescription(.Vertex, "main", vsByteCode);
		SDL_GPUShaderCreateInfo pixelShaderDescription = .()
			{
				code = (uint8*)psByteCode.Ptr,
				code_size = (uint)psByteCode.Count,
				entrypoint = "main",
				format = Renderer.ShaderFormat,
				stage = .SDL_GPU_SHADERSTAGE_FRAGMENT,
				num_samplers = 0,
				num_uniform_buffers = 0,
				num_storage_buffers = 0,
				num_storage_textures = 0
			};//ShaderDescription(.Pixel, "main", psByteCode);

		mVertexShader = SDL_CreateGPUShader(Renderer.mDevice, &vertexShaderDescription);
		mPixelShader = SDL_CreateGPUShader(Renderer.mDevice, &pixelShaderDescription);

		/*// GBuffer resource layout
		mLayoutElementDescriptions = new LayoutElementDescription[](
			LayoutElementDescription(0, ResourceType.ConstantBuffer, ShaderStages.Vertex), // CameraBuffer
			LayoutElementDescription(0, ResourceType.Texture, ShaderStages.Pixel), // Albedo
			LayoutElementDescription(1, ResourceType.Texture, ShaderStages.Pixel), // Normal
			LayoutElementDescription(2, ResourceType.Texture, ShaderStages.Pixel), // Roughness
			LayoutElementDescription(3, ResourceType.Texture, ShaderStages.Pixel), // Metallic
			LayoutElementDescription(4, ResourceType.Texture, ShaderStages.Pixel), // AO
			//LayoutElementDescription(5, ResourceType.Texture, ShaderStages.Pixel), // Depth
			LayoutElementDescription(0, ResourceType.Sampler, ShaderStages.Pixel), // Sampler
			);
		ResourceLayoutDescription gbufferResourceLayoutDescription = ResourceLayoutDescription(params mLayoutElementDescriptions );

		mResourceLayout = Renderer.mDevice.Factory.CreateResourceLayout(ref gbufferResourceLayoutDescription);

		// GBuffer Resourse Set

		mResources = new GraphicsResource[](
			Renderer.CameraBuffer,
			Albedo,
			Normals,
			Roughness,
			Metallic,
			AO,
			//Depth,
			Renderer.mDevice.DefaultSampler
			);*/


		SDL_GPUColorTargetDescription[] colortargets = scope .[]();
		SDL_GPUColorTargetDescription depthTarget = .();

		SDL_GPUGraphicsPipelineCreateInfo pipelineDescription = .()
			{
				vertex_shader = mVertexShader,
				fragment_shader = mPixelShader,
				//vertex_input_state = ,
			 primitive_type = .SDL_GPU_PRIMITIVETYPE_TRIANGLELIST,
			 rasterizer_state = .()
					{
						fill_mode = .SDL_GPU_FILLMODE_FILL,
						cull_mode = .SDL_GPU_CULLMODE_BACK,
						front_face = .SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE
						},
			 //multisample_state = ,
			 //depth_stencil_state = ,
			 target_info = .()
					{
						num_color_targets = (uint32)colortargets.Count,
						color_target_descriptions = colortargets.Ptr 
					}
			};

		mPipelineState = SDL_CreateGPUGraphicsPipeline(Renderer.mDevice, &pipelineDescription);

		CreateCubeBuffers();
	}

	public override void Destroy()
	{
		DestroyCubeBuffers();

		SDL_ReleaseGPUGraphicsPipeline(Renderer.mDevice, mPipelineState);

		SDL_ReleaseGPUShader(Renderer.mDevice, mVertexShader);
		SDL_ReleaseGPUShader(Renderer.mDevice, mPixelShader);

		DestroyResources();
	}

	public override void Execute(SDL_GPUCommandBuffer* commandBuffer)
	{
			// GBuffer pass
		/*ClearValue gBufferClear = .(ClearFlags.All, 1, 0);
		gBufferClear.ColorValues.Count = FrameBuffer.ColorTargets.Count;
		for (int i = 0; i < gBufferClear.ColorValues.Count; i++)
			gBufferClear.ColorValues[i] = Color.CornflowerBlue.ToVector4();

		RenderPassDescription gBufferRenderPassDescription = RenderPassDescription(FrameBuffer, gBufferClear);


		commandBuffer.BeginRenderPass(ref gBufferRenderPassDescription);

		commandBuffer.SetViewports(scope Viewport[1](Viewport(0, 0, FrameBuffer.Width, FrameBuffer.Height)));
		commandBuffer.SetScissorRectangles(scope Rectangle[1](Rectangle(0, 0, (.)FrameBuffer.Width, (.)FrameBuffer.Height)));
		
		commandBuffer.SetResourceSet(mResourceSet);
		commandBuffer.SetGraphicsPipelineState(mPipelineState);

		// Geometry buffers
		{
			commandBuffer.SetVertexBuffers(scope Buffer[1](mCubeVertexBuffer));
			commandBuffer.SetIndexBuffer(mCubeIndexBuffer, .UInt32);
		}

		commandBuffer.DrawIndexed(Cube.Indices.Count, 0, 0);

		commandBuffer.EndRenderPass();*/
	}

	private SDL_GPUBuffer* mCubeVertexBuffer;
	private SDL_GPUBuffer* mCubeIndexBuffer;

	private void CreateCubeBuffers()
	{
		{
			SDL_GPUBufferCreateInfo description = .()
				{

				};//BufferDescription((.)sizeof(float) * (.)Cube.Vertices.Count, BufferFlags.VertexBuffer, ResourceUsage.Default);
			//mCubeVertexBuffer = SDL_CreateGPUBuffer(&Cube.Vertices, ref description, "Cube VB");
		}
		{
			SDL_GPUBufferCreateInfo description = .()
				{

				};//BufferDescription((.)sizeof(uint32) * (.)Cube.Indices.Count, BufferFlags.IndexBuffer, ResourceUsage.Default);
			//mCubeIndexBuffer = SDL_CreateGPUBuffer(&Cube.Indices, ref description, "Cube IB");
		}
	}

	private void DestroyCubeBuffers()
	{
		SDL_ReleaseGPUBuffer(Renderer.mDevice, mCubeVertexBuffer);
		SDL_ReleaseGPUBuffer(Renderer.mDevice, mCubeIndexBuffer);
	}
}