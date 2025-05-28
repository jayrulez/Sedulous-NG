using Sedulous.Messaging;
namespace Sedulous.Engine.Core.SceneGraph;

class SceneDestroyedMessage : Message
{
    public Scene Scene { get; private set; }

    public this(Scene scene)
    {
        Scene = scene;
    }
}