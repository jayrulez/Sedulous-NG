using System.Diagnostics;
using System.Threading;
using System;
namespace Sedulous.Engine.Renderer.GPU;

abstract class GPUResource : IGPUResource
{
	private int mRefCount = 0;

	private String mName = new .() ~ delete _;

	public StringView Name => mName;

	public ~this()
	{
		Debug.Assert(mRefCount == 0);
	}

	public int RefCount
	{
		get
		{
			return mRefCount;
		}
	}

	public this(StringView name)
	{
		mName.Set(name);
	}

	public void AddRef()
	{
		Interlocked.Increment(ref mRefCount);
	}

	public void ReleaseRef()
	{
		int refCount = Interlocked.Decrement(ref mRefCount);
		Debug.Assert(refCount >= 0);
		if (refCount == 0)
		{
			delete this;
		}
	}

	public void ReleaseLastRef()
	{
		int refCount = Interlocked.Decrement(ref mRefCount);
		Debug.Assert(refCount == 0);
		if (refCount == 0)
		{
			delete this;
		}
	}

	public int ReleaseRefNoDelete()
	{
		int refCount = Interlocked.Decrement(ref mRefCount);
		Debug.Assert(refCount >= 0);
		return refCount;
	}
}