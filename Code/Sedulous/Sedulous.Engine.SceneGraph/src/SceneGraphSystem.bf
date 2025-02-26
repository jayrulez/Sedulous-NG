using System.Collections;
namespace Sedulous.Engine.SceneGraph;

using internal Sedulous.Engine.SceneGraph;

class SceneGraphSystem
{
	private readonly List<Scene> mScenes = new .() ~ delete _;

	public void Update()
	{
		for (var scene in mScenes)
		{
			scene.Update();
		}
	}
}