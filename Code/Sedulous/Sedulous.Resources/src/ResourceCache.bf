using System.Collections;
using System.Threading;
namespace Sedulous.Resources;

using internal Sedulous.Resources;

internal class ResourceCache
{
	private readonly Monitor mResourcesMonitor = new .() ~ delete _;
	private readonly Dictionary<ResourceCacheKey, ResourceHandle<IResource>> mResources = new .() ~ delete _;

	public void Set(ResourceCacheKey key, ResourceHandle<IResource> resource)
	{
		using (mResourcesMonitor.Enter())
		{
			mResources[key] = resource;
		}
	}

	public void AddIfNotExist(ResourceCacheKey key, ResourceHandle<IResource> resource)
	{
		using (mResourcesMonitor.Enter())
		{
			if (!mResources.ContainsKey(key))
				mResources[key] = resource;
		}
	}

	public ResourceHandle<IResource> Get(ResourceCacheKey key)
	{
		using (mResourcesMonitor.Enter())
		{
			if (mResources.ContainsKey(key))
				return mResources[key];

			return .(null);
		}
	}

	public void Remove(ResourceCacheKey key)
	{
		using (mResourcesMonitor.Enter())
		{
			if (mResources.ContainsKey(key))
				mResources.Remove(key);
		}
	}

	internal void Remove(ResourceHandle<IResource> resource)
	{
		using (mResourcesMonitor.Enter())
		{
			List<ResourceCacheKey> keysToRemove = scope .();
			for (var entry in mResources)
			{
				if (entry.value == resource)
					keysToRemove.Add(entry.key);
			}

			for (var key in keysToRemove)
				mResources.Remove(key);
		}
	}

	public void Clear()
	{
		using (mResourcesMonitor.Enter())
		{
			mResources.Clear();
		}
	}
}