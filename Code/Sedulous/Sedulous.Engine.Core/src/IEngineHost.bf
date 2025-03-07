namespace Sedulous.Engine.Core;

interface IEngineHost
{
	IEngine Engine { get; }

	bool IsRunning { get; }

	bool IsSuspended { get; }

	bool SupportsMultipleThreads { get; }

	void Exit();
}