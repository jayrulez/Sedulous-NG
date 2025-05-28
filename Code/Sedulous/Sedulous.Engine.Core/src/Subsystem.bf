using System;
using Sedulous.SceneGraph;
using System.Collections;
using Sedulous.Jobs;
namespace Sedulous.Engine.Core;

abstract class Subsystem
{
    private IEngine mEngine = null;
    private bool mInitialized = false;
    private List<IEngine.RegisteredUpdateFunctionInfo> mUpdateRegistrations = new .() ~ delete _;

    public abstract StringView Name { get; }

	private delegate void SceneCreatedHandler(SceneCreatedMessage message);
	private delegate void SceneDestroyedHandler(SceneDestroyedMessage message);

	private SceneCreatedHandler mSceneCreatedHandler = (new (message) => { SceneCreated(message.Scene); }) ~ delete _;
	private SceneDestroyedHandler mSceneDestroyedHandler = (new (message) => { SceneDestroyed(message.Scene); }) ~ delete _;

    internal Result<void> Initialize(IEngine engine)
    {
        if (mInitialized)
            return .Ok;

        mEngine = engine;

		mEngine.Messages.Subscribe<SceneCreatedMessage>(mSceneCreatedHandler);
		mEngine.Messages.Subscribe<SceneDestroyedMessage>(mSceneDestroyedHandler);

        if (OnInitializing(mEngine) case .Ok)
        {
            mInitialized = true;
            return .Ok;
        }

        return .Err;
    }

    internal void Initialized(IEngine engine)
    {
        OnInitialized(engine);
    }

    protected virtual Result<void> OnInitializing(IEngine engine)
    {
        return .Ok;
    }

    protected virtual void OnInitialized(IEngine engine) { }

    internal void Uninitialize()
    {
        if (!mInitialized)
            return;

        OnUnitializing(mEngine);

		mEngine.Messages.Unsubscribe<SceneCreatedMessage>(mSceneCreatedHandler);
		mEngine.Messages.Unsubscribe<SceneDestroyedMessage>(mSceneDestroyedHandler);

        // Cleanup update registrations
        mEngine.UnregisterUpdateFunctions(mUpdateRegistrations);
        for (var registration in mUpdateRegistrations)
        {
            delete registration.Function;
        }
        mUpdateRegistrations.Clear();

        mInitialized = false;
        mEngine = null;
    }

    protected virtual void OnUnitializing(IEngine engine) { }

    // Enhanced: Automatic scene module creation (multiple modules per subsystem)
    internal void SceneCreated(Scene scene)
    {
        var modules = scope List<SceneModule>();
        CreateSceneModules(scene, modules);
        
        for (var module in modules)
        {
            scene.AddModule(module);
        }
        
        OnSceneCreated(scene);
    }

    internal void SceneDestroyed(Scene scene)
    {
        OnSceneDestroyed(scene);

		DestroySceneModules(scene);
    }

    // Override this to create subsystem-specific scene modules
	protected virtual void CreateSceneModules(Scene scene, List<SceneModule> modules) { }
    protected virtual void DestroySceneModules(Scene scene) { }

    protected virtual void OnSceneCreated(Scene scene) { }
    protected virtual void OnSceneDestroyed(Scene scene) { }

    // Convenience methods for subsystems
    protected void RegisterUpdateFunction(IEngine.UpdateFunctionInfo info)
    {
        var registration = mEngine.RegisterUpdateFunction(info);
        mUpdateRegistrations.Add(registration);
    }

    protected void ScheduleJob(JobBase job)
    {
        mEngine.JobSystem.AddJob(job);
    }

    protected void ScheduleWork(delegate void() work, StringView name = null)
    {
        mEngine.JobSystem.AddJob(work, name);
    }

    protected IEngine Engine => mEngine;
}