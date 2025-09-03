using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.Engine.Renderer.RHI.RenderGraph
{
	public enum RenderGraphPassType
	{
		Graphics,
		Compute,
		Copy,
		AsyncCompute
	}

	public enum RenderGraphPassFlags : uint32
	{
		None = 0,
		CullPass = 1 << 0,
		DisableCulling = 1 << 1,
		AsyncCompute = 1 << 2,
		EnableAsyncCompute = 1 << 3,
		GenerateMips = 1 << 4
	}

	public struct RenderGraphPassHandle : IHashable
	{
		public uint32 Index;

		public this(uint32 index)
		{
			Index = index;
		}

		public bool IsValid => Index != uint32.MaxValue;

		public static readonly RenderGraphPassHandle Invalid = .(uint32.MaxValue);

		public int GetHashCode()
		{
			return (int)Index;
		}

		public static bool operator==(RenderGraphPassHandle lhs, RenderGraphPassHandle rhs)
		{
			return lhs.Index == rhs.Index;
		}

		public static bool operator!=(RenderGraphPassHandle lhs, RenderGraphPassHandle rhs)
		{
			return !(lhs == rhs);
		}
	}

	public delegate void RenderFunc(CommandBuffer cmd, RenderGraphContext context);

	public abstract class RenderGraphPass
	{
		public RenderGraphPassHandle Handle { get; protected set; }
		public StringView Name { get; protected set; }
		public RenderGraphPassType PassType { get; protected set; }
		public RenderGraphPassFlags Flags { get; set; }
		
		protected List<RenderGraphResourceHandle> mInputResources = new .() ~ delete _;
		protected List<RenderGraphResourceHandle> mOutputResources = new .() ~ delete _;
		protected List<RenderGraphPassHandle> mDependencies = new .() ~ delete _;
		
		protected RenderFunc mRenderFunc ~ delete _;
		protected bool mCulled = false;
		protected uint32 mRefCount = 0;

		public this(RenderGraphPassHandle handle, StringView name, RenderGraphPassType type)
		{
			Handle = handle;
			Name = name;
			PassType = type;
			Flags = .None;
		}

		public void SetRenderFunc(RenderFunc renderFunc)
		{
			if (mRenderFunc != null)
				delete mRenderFunc;
			mRenderFunc = renderFunc;
		}

		public void AddInput(RenderGraphResourceHandle resource)
		{
			if (!mInputResources.Contains(resource))
				mInputResources.Add(resource);
		}

		public void AddOutput(RenderGraphResourceHandle resource)
		{
			if (!mOutputResources.Contains(resource))
				mOutputResources.Add(resource);
		}

		public void AddDependency(RenderGraphPassHandle pass)
		{
			if (!mDependencies.Contains(pass))
				mDependencies.Add(pass);
		}

		public void Execute(CommandBuffer cmd, RenderGraphContext context)
		{
			if (!mCulled && mRenderFunc != null)
			{
				mRenderFunc(cmd, context);
			}
		}

		public List<RenderGraphResourceHandle> InputResources => mInputResources;
		public List<RenderGraphResourceHandle> OutputResources => mOutputResources;
		public List<RenderGraphPassHandle> Dependencies => mDependencies;
		public bool IsCulled => mCulled;

		public void SetCulled(bool culled)
		{
			mCulled = culled;
		}

		public void AddRef()
		{
			mRefCount++;
		}

		public void Release()
		{
			if (mRefCount > 0)
				mRefCount--;
		}

		public uint32 RefCount => mRefCount;

		public RenderGraphBuilder Setup(RenderGraph graph)
		{
			graph.[Friend]mBuilder.Setup(graph, this);
			return graph.[Friend]mBuilder;
		}
	}

	public class RenderGraphGraphicsPass : RenderGraphPass
	{
		public RenderPassDescription RenderPassDesc { get; set; }
		
		public this(RenderGraphPassHandle handle, StringView name) 
			: base(handle, name, .Graphics)
		{
		}
	}

	public class RenderGraphComputePass : RenderGraphPass
	{
		public this(RenderGraphPassHandle handle, StringView name) 
			: base(handle, name, .Compute)
		{
		}
	}

	public class RenderGraphCopyPass : RenderGraphPass
	{
		public this(RenderGraphPassHandle handle, StringView name) 
			: base(handle, name, .Copy)
		{
		}
	}
}