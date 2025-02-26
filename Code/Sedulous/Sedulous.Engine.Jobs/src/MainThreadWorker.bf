using System;
namespace Sedulous.Engine.Jobs;

using internal Sedulous.Engine.Jobs;

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