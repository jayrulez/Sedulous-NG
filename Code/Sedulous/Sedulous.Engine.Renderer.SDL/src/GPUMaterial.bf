using SDL3Native;
using System;
using System.Collections;
using Sedulous.Mathematics;
using Sedulous.Resources;

namespace Sedulous.Engine.Renderer.SDL;

class GPUMaterial : GPUResource
{
	private SDL_GPUDevice* mDevice;
	private Material mMaterial;

	// Cached GPU resources
	private SDL_GPUBuffer* mUniformBuffer;
	private uint32 mUniformBufferSize;
	private List<GPUResourceHandle<GPUTexture>> mGPUTextures = new .() ~ delete _;

	// Pipeline state derived from material
	public Material.BlendMode BlendMode => mMaterial.Blending;
	public Material.CullMode CullMode => mMaterial.Culling;
	public bool DepthWrite => mMaterial.DepthWrite;
	public bool DepthTest => mMaterial.DepthTest;
	public StringView ShaderName => mMaterial.ShaderName;

	public this(StringView name, SDL_GPUDevice* device, Material material, Dictionary<TextureResource, GPUResourceHandle<GPUTexture>> textureCache)
		: base(name)
	{
		mDevice = device;
		mMaterial = material;

		// Create uniform buffer if material needs one
		mUniformBufferSize = (uint32)material.GetUniformDataSize();
		if (mUniformBufferSize > 0)
		{
			CreateUniformBuffer();
			UpdateUniformBuffer();
		}

		// Cache GPU textures
		CacheTextures(textureCache);
	}

	public ~this()
	{
		if (mUniformBuffer != null)
		{
			SDL_ReleaseGPUBuffer(mDevice, mUniformBuffer);
		}
	}

	private void CreateUniformBuffer()
	{
		var bufferDesc = SDL_GPUBufferCreateInfo()
			{
				usage = .SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ,
				size = mUniformBufferSize
			};

		mUniformBuffer = SDL_CreateGPUBuffer(mDevice, &bufferDesc);
	}

	private void UpdateUniformBuffer()
	{
		if (mUniformBuffer == null || mUniformBufferSize == 0)
			return;

		// Create staging buffer
		var transferBuffer = SDL_CreateGPUTransferBuffer(mDevice, scope .()
			{
				usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD,
				size = mUniformBufferSize
			});

		defer SDL_ReleaseGPUTransferBuffer(mDevice, transferBuffer);

		// Map and fill buffer
		var data = SDL_MapGPUTransferBuffer(mDevice, transferBuffer, false);
		if (data != null)
		{
			mMaterial.FillUniformData(Span<uint8>((uint8*)data, (int)mUniformBufferSize));
			SDL_UnmapGPUTransferBuffer(mDevice, transferBuffer);

			// Upload to GPU
			var commandBuffer = SDL_AcquireGPUCommandBuffer(mDevice);
			if (commandBuffer != null)
			{
				var copyPass = SDL_BeginGPUCopyPass(commandBuffer);

				SDL_UploadToGPUBuffer(copyPass,
					scope SDL_GPUTransferBufferLocation()
					{
						transfer_buffer = transferBuffer,
						offset = 0
					},
						scope SDL_GPUBufferRegion()
					{
						buffer = mUniformBuffer,
						offset = 0,
						size = mUniformBufferSize
					},
						false);

				SDL_EndGPUCopyPass(copyPass);
				SDL_SubmitGPUCommandBuffer(commandBuffer);
			}
		}
	}

	private void CacheTextures(Dictionary<TextureResource, GPUResourceHandle<GPUTexture>> textureCache)
	{
		var textureList = scope List<ResourceHandle<TextureResource>>();
		mMaterial.GetTextureResources(textureList);

		for (var handle in textureList)
		{
			if (handle.IsValid && handle.Resource != null)
			{
				if (textureCache.TryGetValue(handle.Resource, let gpuTexture))
				{
					mGPUTextures.Add(gpuTexture);
				}
			}
		}
	}

	public void BindTextures(SDL_GPURenderPass* renderPass)
	{
		// Bind all textures for this material
		// The exact binding depends on the shader layout
		if (mGPUTextures.Count > 0)
		{
			for (int i = 0; i < mGPUTextures.Count; i++)
			{
				var gpuTexture = mGPUTextures[i];
				var binding = SDL_GPUTextureSamplerBinding()
					{
						texture = gpuTexture.Resource.Texture,
						sampler = gpuTexture.Resource.Sampler
					};
				SDL_BindGPUFragmentSamplers(renderPass, (uint32)i, &binding, 1);
			}
		}
		else
		{
			// No textures in material - this case is handled by RenderObject
			// which will bind default textures
		}
	}

	public SDL_GPUBuffer* UniformBuffer => mUniformBuffer;
	public uint32 UniformBufferSize => mUniformBufferSize;
}