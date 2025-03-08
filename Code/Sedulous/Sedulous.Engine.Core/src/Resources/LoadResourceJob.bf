using Sedulous.Jobs;
using System;
namespace Sedulous.Engine.Core.Resources;

internal class LoadResourceJob<T> : Job<Result<T, ResourceLoadError>>
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
		delegate void(Result<T, ResourceLoadError> result) onCompleted = null,
		bool ownsOnCompletedDelegate = true)
		: base(scope $"Load Asset '{path}'", flags, onCompleted, ownsOnCompletedDelegate)
	{
		mResourceSystem = resourceSystem;
		mPath.Set(path);
		mFromCache = fromCache;
		mCacheIfLoaded = cacheIfLoaded;
	}

	protected override Result<T, ResourceLoadError> OnExecute()
	{
		return mResourceSystem.LoadResource<T>(mPath, mFromCache, mCacheIfLoaded);
	}
}