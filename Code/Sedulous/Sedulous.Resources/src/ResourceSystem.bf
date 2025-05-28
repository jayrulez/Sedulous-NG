using Sedulous.Jobs;
using System.Threading;
using System.Collections;
using System;
using Sedulous.Foundation.Logging.Abstractions;
namespace Sedulous.Resources;

using internal Sedulous.Resources;

class ResourceSystem
{
	private readonly JobSystem mJobSystem;
	private readonly ILogger mLogger;

	private readonly Monitor mResourceManagersByResourceTypesMonitor = new .() ~ delete _;
	private readonly Dictionary<Type, IResourceManager> mResourceManagersByResourceTypes = new .() ~ delete _;
	private readonly ResourceCache mCache = new .() ~ delete _;

	public this(ILogger logger, JobSystem jobSystem)
	{
		mLogger = logger;
		mJobSystem = jobSystem;
	}

	internal void Startup() { }
	internal void Shutdown() { }

	internal void Update(int64 elapsedTicks)
	{
	}

	private IResourceManager GetResourceManagerByResourceType<T>() where T : IResource
	{
		using (mResourceManagersByResourceTypesMonitor.Enter())
		{
			var type = typeof(T);

			if (mResourceManagersByResourceTypes.ContainsKey(type))
			{
				return mResourceManagersByResourceTypes[type];
			}

			return null;
		}
	}

	private IResourceManager GetResourceManagerByResourceType(Type type)
	{
		using (mResourceManagersByResourceTypesMonitor.Enter())
		{
			if (mResourceManagersByResourceTypes.ContainsKey(type))
			{
				return mResourceManagersByResourceTypes[type];
			}

			return null;
		}
	}

	public void AddResourceManager(IResourceManager manager)
	{
		using (mResourceManagersByResourceTypesMonitor.Enter())
		{
			if (mResourceManagersByResourceTypes.ContainsKey(manager.ResourceType))
			{
				mLogger?.LogWarning("A resource manager has already been registered for type '{0}'.", manager.ResourceType.GetName(.. scope .()));
				return;
			}
			mResourceManagersByResourceTypes.Add(manager.ResourceType, manager);
		}
	}

	public void RemoveResourceManager(IResourceManager manager)
	{
		using (mResourceManagersByResourceTypesMonitor.Enter())
		{
			if (mResourceManagersByResourceTypes.TryGet(manager.ResourceType, var resourceType, ?))
			{
				mResourceManagersByResourceTypes.Remove(resourceType);
			}
		}
	}

	public Result<T, ResourceLoadError> LoadResource<T>(StringView path, bool fromCache = true, bool cacheIfLoaded = true) where T : IResource
	{
		var cacheKey = ResourceCacheKey(path, typeof(T));
		if (fromCache)
		{
			var resource = mCache.Get(cacheKey);
			if (resource != null)
			{
				resource.AddRef();
				return (T)resource;
			}
		}

		var resourceManager = GetResourceManagerByResourceType<T>();
		if (resourceManager == null)
			return .Err(.ManagerNotFound);

		var loadResult = resourceManager.Load(path);
		if (loadResult case .Err(let error))
		{
			return .Err(error);
		}

		var resource = (T)loadResult.Value;

		if (cacheIfLoaded)
		{
			mCache.Set(cacheKey, resource);
		}

		resource.AddRef();

		return .Ok(resource);
	}

	public Job<Result<T, ResourceLoadError>> LoadResourceAsync<T>(StringView path,
		bool fromCache = true,
		bool cacheIfLoaded = true,
		delegate void(Result<T, ResourceLoadError> result) onCompleted = null,
		bool ownsOnCompletedDelegate = true)
		where T : IResource
	{
		var job = new LoadResourceJob<T>(this, path, fromCache, cacheIfLoaded, .AutoRelease, onCompleted, ownsOnCompletedDelegate);
		mJobSystem.AddJob(job);
		return job;
	}

	public void UnloadResource<T>(T resource) where T : IResource
	{
		mCache.Remove(resource);

		if (resource.RefCount > 1)
		{
			mLogger.LogWarning(scope $"Unloading resource '{resource.Id}' with RefCount {resource.RefCount}. Resource must be manually freed.");
		}
		resource.ReleaseRefNoDelete();

		var resourceManager = GetResourceManagerByResourceType<T>();
		if (resourceManager == null)
		{
			mLogger.LogWarning(scope $"ResourceManager for resource type '{resource.GetType().GetName(.. scope .())}' not found.");
		} else
		{
			resourceManager.Unload(resource);
		}
	}
}