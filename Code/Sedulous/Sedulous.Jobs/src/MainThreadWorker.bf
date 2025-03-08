using System;
namespace Sedulous.Jobs;

using internal Sedulous.Jobs;

internal class MainThreadWorker : Worker
{
	public this(JobSystem jobSystem, StringView name)
		: base(jobSystem, name, .Persistent)
	{
	}

	public ~this()
	{
	}

	public override void Update()
	{
		ProcessJobs();
	}
}