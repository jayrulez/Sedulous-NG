using System.Collections;
using System;
using Sedulous.Messaging;
namespace Sedulous.SceneGraph;

using internal Sedulous.SceneGraph;

class SceneGraphSystem
{
	private readonly MessageBus mMessageBus;
	public MessageBus MessageBus => mMessageBus;

	private readonly List<Scene> mScenes = new .() ~ delete _;
	private List<Scene> mActiveScenes = new .() ~ delete _;

	public Span<Scene> ActiveScenes => mActiveScenes;

	public this(MessageBus messageBus)
	{
		mMessageBus = messageBus;
	}

	internal void Update(TimeSpan deltaTime)
	{
		for (var scene in mActiveScenes)
		{
			scene.Update(deltaTime);
		}
	}

	internal Result<void> Startup()
	{
		return .Ok;
	}

	internal void Shutdown()
	{
		// Cleanup all scenes
		for (var scene in mScenes)
		{
		    DestroyScene(scene);
		}
		mScenes.Clear();
		mActiveScenes.Clear();
	}

	public Result<Scene> CreateScene(StringView name = "Scene")
	{
        var scene = new Scene(this);
        scene.Name.Set(name);
        
        mScenes.Add(scene);

        // Notify that a scene was created
		MessageBus.Publish(new SceneCreatedMessage(scene));

        return .Ok(scene);
	}

	public void DestroyScene(Scene scene)
	{
		if (!mScenes.Contains(scene))
			return;

		// Remove from active list
		mActiveScenes.Remove(scene);

		MessageBus.Publish(new SceneDestroyedMessage(scene));

		// Cleanup
		mScenes.Remove(scene);
		delete scene;
	}

	public void SetActiveScene(Scene scene)
	{
	    if (!mScenes.Contains(scene))
	        return;

	    mActiveScenes.Clear();
	    mActiveScenes.Add(scene);
	}

	public void AddActiveScene(Scene scene)
	{
	    if (mScenes.Contains(scene) && !mActiveScenes.Contains(scene))
	    {
	        mActiveScenes.Add(scene);
	    }
	}

	public void RemoveActiveScene(Scene scene)
	{
	    mActiveScenes.Remove(scene);
	}
}