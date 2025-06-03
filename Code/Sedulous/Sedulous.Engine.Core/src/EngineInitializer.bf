using System.Collections;
using System;
using Sedulous.Logging.Abstractions;
namespace Sedulous.Engine.Core;

class EngineInitializer
{
	private List<Subsystem> mSubsystems = new .() ~ delete _;

	public Span<Subsystem> Subsystems => mSubsystems;

	public LogLevel LogLevel { get; set; }

	public this()
	{

	}

	public Result<void> AddSubsystem(Subsystem subsystem)
	{
		if (mSubsystems.Contains(subsystem))
		{
			return .Err;
		}

		mSubsystems.Add(subsystem);

		return .Ok;
	}
}