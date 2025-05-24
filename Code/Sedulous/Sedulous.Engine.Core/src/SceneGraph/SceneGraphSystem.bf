using System.Collections;
using Sedulous.Engine.Core;
using System;
namespace Sedulous.Engine.Core.SceneGraph;

using internal Sedulous.Engine.Core.SceneGraph;
using internal Sedulous.Engine.Core;

class SceneGraphSystem
{
	private readonly IEngine mEngine;
	private readonly List<Scene> mScenes = new .() ~ delete _;
	private List<Scene> mActiveScenes = new .() ~ delete _;

	private IEngine.RegisteredUpdateFunctionInfo? mUpdateFunctionRegistration;

	public this(IEngine engine)
	{
		mEngine = engine;
	}

	private void OnEngineUpdate(IEngine.UpdateInfo info)
	{
		for (var scene in mActiveScenes)
		{
			scene.Update(info.Time.ElapsedTime);
		}
	}

	internal Result<void> Startup()
	{
		mUpdateFunctionRegistration = mEngine.RegisterUpdateFunction(.()
			{
				Priority = -1,
				Stage = .VariableUpdate,
				Function = new => OnEngineUpdate
			});
		return .Ok;
	}

	internal void Shutdown()
	{
		if (mUpdateFunctionRegistration.HasValue)
		{
			mEngine.UnregisterUpdateFunction(mUpdateFunctionRegistration.Value);
			delete mUpdateFunctionRegistration.Value.Function;
			mUpdateFunctionRegistration = null;
		}
	}

	public Result<Scene> CreateScene(StringView name = "Scene")
	{
        var scene = new Scene();
        scene.Name.Set(name);
        scene.SetEngine(mEngine); // Set engine reference for events
        
        mScenes.Add(scene);

        // Notify all subsystems that a scene was created
        for (var subsystem in mEngine.Subsystems)
        {
            subsystem.SceneCreated(scene);
        }

        return .Ok(scene);
	}

	public void DestroyScene(Scene scene)
	{
		for (var subsystem in mEngine.Subsystems)
		{
			subsystem.SceneDestroyed(scene);
		}
	}
}