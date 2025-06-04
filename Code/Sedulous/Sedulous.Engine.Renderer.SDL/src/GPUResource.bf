using System.Diagnostics;
using System.Threading;
namespace Sedulous.Engine.Renderer.SDL;

abstract class GPUResource : IGPUResource
{
	private int mRefCount = 0;

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