using System;
using System.Collections;
using Sedulous.SceneGraph;
namespace Sedulous.Engine.Core;

class BehaviourSubsystem : Subsystem
{
	public override System.StringView Name => "Behaviour";

	private List<BehaviourModule> mModules = new .() ~ delete _;

	protected override Result<void> OnInitializing(IEngine engine)
	{
		return .Ok;
	}

	protected override void OnInitialized(IEngine engine) { }

	protected override void OnUnitializing(IEngine engine) { }

	protected override void CreateSceneModules(Scene scene, List<SceneModule> modules)
	{
		var module = new BehaviourModule();
		modules.Add(module);
		mModules.Add(module);
	}

	protected override void DestroySceneModules(Scene scene)
	{
		for (int i = mModules.Count - 1; i >= 0; i--)
		{
			if (mModules[i].Scene == scene)
			{
				delete mModules[i];
				mModules.RemoveAt(i);
			}
		}
	}

	protected override void OnSceneCreated(Scene scene) { }

	protected override void OnSceneDestroyed(Scene scene) { }

	

	private void OnUpdate(IEngine.UpdateInfo info)
	{
		for(var module in mModules)
		{
			//module.Update();
		}
	}

	private void OnFixedUpdate(IEngine.UpdateInfo info)
	{
	}

	private void OnPreUpdate(IEngine.UpdateInfo info)
	{
	}

	private void OnPostUpdate(IEngine.UpdateInfo info)
	{
	}
}