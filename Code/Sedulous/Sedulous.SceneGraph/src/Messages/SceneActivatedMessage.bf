using Sedulous.Messaging;
namespace Sedulous.SceneGraph;

class SceneActivatedMessage : Message
{
    public Scene Scene { get; private set; }

    public this(Scene scene)
    {
        Scene = scene;
    }
}