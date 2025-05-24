using Sedulous.Messaging;
namespace Sedulous.Engine.Core.SceneGraph;

class EntityCreatedMessage : Message
{
    public Entity Entity { get; private set; }
    public Scene Scene { get; private set; }

    public this(Entity entity, Scene scene)
    {
        Entity = entity;
        Scene = scene;
    }
}