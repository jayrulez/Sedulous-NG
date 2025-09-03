using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.Engine.Renderer.RHI.RenderGraph
{
	public class RenderGraphBuilder
	{
		private RenderGraph mGraph;
		private RenderGraphPass mCurrentPass;
		
		public this()
		{
		}

		public void Setup(RenderGraph graph, RenderGraphPass pass)
		{
			mGraph = graph;
			mCurrentPass = pass;
		}

		public RenderGraphBuilder UseTexture(RenderGraphResourceHandle handle)
		{
			mCurrentPass.AddInput(handle);
			return this;
		}

		public RenderGraphBuilder UseBuffer(RenderGraphResourceHandle handle)
		{
			mCurrentPass.AddInput(handle);
			return this;
		}

		public RenderGraphBuilder WriteTexture(RenderGraphResourceHandle handle)
		{
			mCurrentPass.AddOutput(handle);
			return this;
		}

		public RenderGraphBuilder WriteBuffer(RenderGraphResourceHandle handle)
		{
			mCurrentPass.AddOutput(handle);
			return this;
		}

		public RenderGraphBuilder SetRenderTarget(RenderGraphResourceHandle colorTarget, RenderGraphResourceHandle depthTarget = .Invalid)
		{
			if (mCurrentPass.PassType == .Graphics)
			{
				let graphicsPass = mCurrentPass as RenderGraphGraphicsPass;
				
				// Add as outputs since we're writing to them
				if (colorTarget.IsValid)
					mCurrentPass.AddOutput(colorTarget);
				if (depthTarget.IsValid)
					mCurrentPass.AddOutput(depthTarget);
			}
			return this;
		}

		public RenderGraphBuilder SetRenderTargets(RenderGraphResourceHandle[] colorTargets, RenderGraphResourceHandle depthTarget = .Invalid)
		{
			if (mCurrentPass.PassType == .Graphics)
			{
				let graphicsPass = mCurrentPass as RenderGraphGraphicsPass;
				
				for (let target in colorTargets)
				{
					if (target.IsValid)
						mCurrentPass.AddOutput(target);
				}
				
				if (depthTarget.IsValid)
					mCurrentPass.AddOutput(depthTarget);
			}
			return this;
		}

		public RenderGraphBuilder DependsOn(RenderGraphPassHandle pass)
		{
			mCurrentPass.AddDependency(pass);
			return this;
		}

		public RenderGraphBuilder SetFlags(RenderGraphPassFlags flags)
		{
			mCurrentPass.Flags = flags;
			return this;
		}

		public RenderGraphBuilder EnableAsyncCompute()
		{
			mCurrentPass.Flags |= .AsyncCompute | .EnableAsyncCompute;
			return this;
		}

		public RenderGraphBuilder DisableCulling()
		{
			mCurrentPass.Flags |= .DisableCulling;
			return this;
		}

		public RenderGraphPass Build()
		{
			return mCurrentPass;
		}
	}
}