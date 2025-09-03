using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.Engine.Renderer.RHI.RenderGraph
{
	public class RenderGraphContext
	{
		private RenderGraph mRenderGraph;
		private RenderGraphPassHandle mCurrentPass;
		private Dictionary<RenderGraphResourceHandle, RenderGraphResource> mResourceMap ~ delete _;

		public this(RenderGraph renderGraph)
		{
			mRenderGraph = renderGraph;
			mResourceMap = new .();
		}

		public void SetCurrentPass(RenderGraphPassHandle pass)
		{
			mCurrentPass = pass;
		}

		public void SetResourceMap(Dictionary<RenderGraphResourceHandle, RenderGraphResource> resourceMap)
		{
			mResourceMap.Clear();
			for (let kv in resourceMap)
			{
				mResourceMap[kv.key] = kv.value;
			}
		}

		public Texture GetTexture(RenderGraphResourceHandle handle)
		{
			if (mResourceMap.TryGetValue(handle, let resource))
			{
				if (resource.ResourceType == .Texture)
				{
					let textureResource = resource as RenderGraphTextureResource;
					return textureResource.Texture;
				}
			}
			return null;
		}

		public Buffer GetBuffer(RenderGraphResourceHandle handle)
		{
			if (mResourceMap.TryGetValue(handle, let resource))
			{
				if (resource.ResourceType == .Buffer)
				{
					let bufferResource = resource as RenderGraphBufferResource;
					return bufferResource.Buffer;
				}
			}
			return null;
		}


		public RenderGraph RenderGraph => mRenderGraph;
		public GraphicsContext GraphicsContext => mRenderGraph.GraphicsContext;
		public ResourceFactory ResourceFactory => mRenderGraph.ResourceFactory;
	}
}