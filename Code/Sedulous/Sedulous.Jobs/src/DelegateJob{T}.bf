using System;
namespace Sedulous.Jobs;

class DelegateJob<T> : Job<T>
{
	private delegate T() mJob = null ~ { if(mOwnsJobDelegate)delete _;};
	private bool mOwnsJobDelegate = false;

	public this(delegate T() job,
		bool ownsJobDelegate,
		StringView? name,
		JobFlags flags,
		delegate void(T result) onCompleted = null,
		bool ownsOnCompletedDelegate = true) : base(name, flags, onCompleted, ownsOnCompletedDelegate)
	{
		mJob = job;
		mOwnsJobDelegate = ownsJobDelegate;
	}

	protected override T OnExecute()
	{
		if(mJob != null)
		{
			return mJob.Invoke();
		}
		return default;
	}
}