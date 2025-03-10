using System;
using Sedulous.Engine.Core.SceneGraph;
namespace Sedulous.Engine.Core;

abstract class Subsystem
{
	private IEngine mEngine = null;
	private bool mInitialized = false;

	public abstract StringView Name { get; }

	internal Result<void> Initialize(IEngine engine)
	{
		if (mInitialized)
			return .Ok;

		mEngine = engine;
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

		mInitialized = false;
		mEngine = null;
	}

	protected virtual void OnUnitializing(IEngine engine) { }

	internal void SceneCreated(Scene scene)
	{
		OnSceneCreated(scene);
	}

	protected virtual void OnSceneCreated(Scene scene) { }

	internal void SceneDestroyed(Scene scene)
	{
		OnSceneDestroyed(scene);
	}

	protected virtual void OnSceneDestroyed(Scene scene) { }
}