namespace Sedulous.Engine.Core.Resources;

struct ResourceHandle<T> where T : IResource, class
{
    private T mResource;
    private bool mIsValid;
    
    public T Resource 
    { 
        get 
        {
            if (!mIsValid || mResource?.RefCount <= 0)
                return null;
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
            mResource = null;
            mIsValid = false;
        }
    }
}