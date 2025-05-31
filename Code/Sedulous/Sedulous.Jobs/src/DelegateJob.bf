using System;
namespace Sedulous.Jobs;

class DelegateJob : Job
{
	private delegate void() mJob = null ~ { if (mOwnsJobDelegate) delete _; };
	private bool mOwnsJobDelegate = false;

	public this(delegate void() job,
		bool ownsJobDelegate,
		StringView? name,
		JobFlags flags)
		: base(name, flags)
	{
		mJob = job;
		mOwnsJobDelegate = ownsJobDelegate;
	}

	protected override void OnExecute()
	{
		mJob?.Invoke();
	}
}