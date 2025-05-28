using Sedulous.Messaging;
namespace Sedulous.SceneGraph;

class SceneCreatedMessage : Message
{
    public Scene Scene { get; private set; }

    public this(Scene scene)
    {
        Scene = scene;
    }
}