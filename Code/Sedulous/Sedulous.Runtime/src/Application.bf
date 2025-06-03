using Sedulous.Engine.Core;
using Sedulous.Platform.Core;
using Sedulous.Logging.Abstractions;
namespace Sedulous.Runtime;

class Application : IEngineHost
{
	private readonly Engine mEngine;

	public IEngine Engine => mEngine;

	public bool IsRunning => mWindowSystem.IsRunning;

	private bool mIsSuspended = false;

	public bool IsSuspended => mIsSuspended;

	public bool SupportsMultipleThreads => true;

	private readonly WindowSystem mWindowSystem;

	public WindowSystem WindowSystem => mWindowSystem;

	private readonly ILogger mLogger;

	public ILogger Logger => mLogger;

	public this(ILogger logger, WindowSystem windowSystem)
	{
		mLogger = logger;

		mWindowSystem = windowSystem; 

		mEngine = new .(this, mLogger);
	}

	public ~this()
	{
		delete mEngine;
	}

	public void Exit()
	{
		mWindowSystem.RequestExit();
	}

	protected virtual void OnEngineInitializing(EngineInitializer initializer){}
	protected virtual void OnEngineInitialized(Engine engine){}
	protected virtual void OnEngineShuttingDown(Engine engine){}
	protected virtual void OnEngineShutDown(Engine engine){}

	public void Run(EngineInitializingCallback initializingCallback = null,
		EngineInitializedCallback initializedCallback = null,
		EngineShuttingDownCallback shuttingDownCallback = null)
	{
		EngineInitializer engineInitializer = new .();

		OnEngineInitializing(engineInitializer);

		if (initializingCallback != null)
		{
			initializingCallback(engineInitializer);
		}

		if (mEngine.Initialize(engineInitializer) case .Err)
		{
			mLogger?.LogError("Engine initialization failed.");
			return;
		}

		OnEngineInitialized(mEngine);

		if (initializedCallback != null)
		{
			initializedCallback(mEngine);
		}

		mWindowSystem.StartMainLoop();
		while (mWindowSystem.IsRunning)
		{
			mWindowSystem.RunOneFrame(scope => mEngine.Update);
		}
		mWindowSystem.StopMainLoop();

		OnEngineShuttingDown(mEngine);

		if (shuttingDownCallback != null)
		{
			shuttingDownCallback(mEngine);
		}

		mEngine.Shutdown();
		OnEngineShutDown(mEngine);
		delete engineInitializer;
	}
}