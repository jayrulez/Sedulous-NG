using Sedulous.Jobs;
using System;
namespace Sedulous.Resources;

internal class LoadResourceJob<T> : Job<Result<ResourceHandle<T>, ResourceLoadError>>
	where T : IResource
{
	private readonly ResourceSystem mResourceSystem;
	private readonly String mPath = new .() ~ delete _;
	private readonly bool mFromCache;
	private readonly bool mCacheIfLoaded;

	public this(ResourceSystem resourceSystem,
		StringView path,
		bool fromCache = true,
		bool cacheIfLoaded = true,
		JobFlags flags = .None,
		delegate void(Result<ResourceHandle<T>, ResourceLoadError> result) onCompleted = null,
		bool ownsOnCompletedDelegate = true)
		: base(scope $"Load Asset '{path}'", flags, onCompleted, ownsOnCompletedDelegate)
	{
		mResourceSystem = resourceSystem;
		mPath.Set(path);
		mFromCache = fromCache;
		mCacheIfLoaded = cacheIfLoaded;
	}

	protected override Result<ResourceHandle<T>, ResourceLoadError> OnExecute()
	{
		return mResourceSystem.LoadResource<T>(mPath, mFromCache, mCacheIfLoaded);
	}
}