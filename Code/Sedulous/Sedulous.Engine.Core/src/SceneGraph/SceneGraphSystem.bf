using System.Collections;
using Sedulous.Engine.Core;
using System;
namespace Sedulous.Engine.SceneGraph;

using internal Sedulous.Engine.SceneGraph;
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

	public Result<void> CreateScene(out Scene scene)
	{
		scene = ?;

		for (var subsystem in mEngine.Subsystems)
		{
			subsystem.SceneCreated(scene);
		}

		return .Ok;
	}

	public void DestroyScene(Scene scene)
	{
		for (var subsystem in mEngine.Subsystems)
		{
			subsystem.SceneDestroyed(scene);
		}
	}
}