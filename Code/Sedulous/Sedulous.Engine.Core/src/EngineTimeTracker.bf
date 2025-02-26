using System;
namespace Sedulous.Engine.Core;

using internal Sedulous.Engine.Core;

sealed class EngineTimeTracker
{
	public EngineTime Reset()
	{
		mTime.ElapsedTime     = TimeSpan.Zero;
		mTime.TotalTime       = TimeSpan.Zero;
		return mTime;
	}

	public EngineTime Increment(TimeSpan ts)
	{
		mTime.ElapsedTime = ts;
		mTime.TotalTime = mTime.TotalTime + ts;
		return mTime;
	}

	public EngineTime Time => mTime;

	private readonly EngineTime mTime = new .() ~ delete _;
}