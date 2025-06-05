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

	// Returns true if material has all required textures, false if defaults are needed
	public bool HasRequiredTextures()
	{
		switch (mMaterial.ShaderName)
		{
		case "Phong":
			// Phong requires at least a diffuse texture (slot 0)
			return mGPUTextures.Count >= 1;
		case "PBR":
			// PBR requires at least albedo (slot 0)
			// Normal and metallic/roughness are optional but recommended
			return mGPUTextures.Count >= 1;
		case "Unlit":
			// Unlit requires a main texture (slot 0)
			return mGPUTextures.Count >= 1;
		default:
			return false;
		}
	}

	public void BindTextures(SDL_GPURenderPass* renderPass,
		GPUResourceHandle<GPUTexture> defaultWhite,
		GPUResourceHandle<GPUTexture> defaultNormal,
		GPUResourceHandle<GPUTexture> defaultBlack)
	{
		// Bind textures based on material type, filling missing slots with defaults
		switch (mMaterial.ShaderName)
		{
		case "Phong":
			// Slot 0: Diffuse texture
			BindTextureSlot(renderPass, 0, 0, defaultWhite);

		case "PBR":
			// Slot 0: Albedo texture
			BindTextureSlot(renderPass, 0, 0, defaultWhite);
			// Slot 1: Normal texture
			BindTextureSlot(renderPass, 1, 1, defaultNormal);
			// Slot 2: Metallic/Roughness texture
			BindTextureSlot(renderPass, 2, 2, defaultWhite);
			// Note: AO and Emissive slots could be added here if needed

		case "Unlit":
			// Slot 0: Main texture
			BindTextureSlot(renderPass, 0, 0, defaultWhite);

		default:
			// Unknown material type - bind default white to slot 0
			var binding = SDL_GPUTextureSamplerBinding()
				{
					texture = defaultWhite.Resource.Texture,
					sampler = defaultWhite.Resource.Sampler
				};
			SDL_BindGPUFragmentSamplers(renderPass, 0, &binding, 1);
		}
	}

	private void BindTextureSlot(SDL_GPURenderPass* renderPass, uint32 slot,
		int textureIndex, GPUResourceHandle<GPUTexture> defaultTexture)
	{
		SDL_GPUTextureSamplerBinding binding;

		if (textureIndex < mGPUTextures.Count && mGPUTextures[textureIndex].IsValid)
		{
			// Use the material's texture
			binding = SDL_GPUTextureSamplerBinding()
				{
					texture = mGPUTextures[textureIndex].Resource.Texture,
					sampler = mGPUTextures[textureIndex].Resource.Sampler
				};
		}
		else
		{
			// Use default texture
			binding = SDL_GPUTextureSamplerBinding()
				{
					texture = defaultTexture.Resource.Texture,
					sampler = defaultTexture.Resource.Sampler
				};
		}

		SDL_BindGPUFragmentSamplers(renderPass, slot, &binding, 1);
	}

	public SDL_GPUBuffer* UniformBuffer => mUniformBuffer;
	public uint32 UniformBufferSize => mUniformBufferSize;
}