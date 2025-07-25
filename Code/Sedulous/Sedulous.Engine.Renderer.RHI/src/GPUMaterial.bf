using System;
using System.Collections;
using Sedulous.Mathematics;
using Sedulous.Resources;
using Sedulous.Engine.Renderer.GPU;
using Sedulous.RHI;

namespace Sedulous.Engine.Renderer.RHI;

class GPUMaterial : GPUResource
{
	private GraphicsContext mGraphicsContext;
	private Material mMaterial;

	// Cached GPU resources
	private Buffer mUniformBuffer;
	private uint32 mUniformBufferSize;
	private List<GPUResourceHandle<GPUTexture>> mGPUTextures = new .() ~ delete _;

	// Pipeline state derived from material
	public Material.BlendMode BlendMode => mMaterial.Blending;
	public Material.CullMode CullMode => mMaterial.Culling;
	public bool DepthWrite => mMaterial.DepthWrite;
	public bool DepthTest => mMaterial.DepthTest;
	public StringView ShaderName => mMaterial.ShaderName;

	public this(StringView name, GraphicsContext context, Material material, Dictionary<TextureResource, GPUResourceHandle<GPUTexture>> textureCache)
		: base(name)
	{
		mGraphicsContext = context;
		mMaterial = material;

		// Create uniform buffer if material needs one
		mUniformBufferSize = (uint32)material.GetUniformDataSize();
		if (mUniformBufferSize > 0)
		{
			CreateUniformBuffer();
		}

		// Cache GPU textures
		CacheTextures(textureCache);
	}

	public ~this()
	{
		if (mUniformBuffer != null)
		{
			mGraphicsContext.Factory.DestroyBuffer(ref mUniformBuffer);
		}

		for(var item in mGPUTextures)
		{
			item.Release();
		}
	}

	private void CreateUniformBuffer()
	{
		var bufferDesc = BufferDescription(mUniformBufferSize, .ConstantBuffer, .Dynamic);

		mUniformBuffer = mGraphicsContext.Factory.CreateBuffer(bufferDesc);
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

	public Buffer UniformBuffer => mUniformBuffer;
	public uint32 UniformBufferSize => mUniformBufferSize;
}