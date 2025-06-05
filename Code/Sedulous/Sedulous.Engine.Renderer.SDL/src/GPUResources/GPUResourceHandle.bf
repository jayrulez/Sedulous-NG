namespace Sedulous.Engine.Renderer.SDL;

struct GPUResourceHandle<T> where T : IGPUResource
{
	private T mResource;
	private bool mIsValid;

	public T Resource
	{
		get
		{
			if (!mIsValid || mResource?.RefCount <= 0)
				return default;
			return mResource;
		}
	}

	public bool IsValid => mIsValid && mResource?.RefCount > 0;

	public this(T resource)
	{
		mResource = resource;
		mIsValid = resource != null;
		if (mIsValid)
			mResource.AddRef();
	}

	public void Release() mut
	{
		if (mIsValid && mResource != null)
		{
			mResource.ReleaseRef();
			mResource = default;
			mIsValid = false;
		}
	}
}