using System;
namespace Sedulous.Platform.Core;

abstract class WindowSystem
{
	public typealias FrameCallback = delegate void(int64 elapsedTicks);

	public abstract bool IsRunning { get; }

	public abstract Window PrimaryWindow {get;}

	public abstract Window GetWindowById(int32 windowId);

	public abstract void StartMainLoop();
	public abstract void StopMainLoop();
	public abstract void RunOneFrame(FrameCallback callback);
}