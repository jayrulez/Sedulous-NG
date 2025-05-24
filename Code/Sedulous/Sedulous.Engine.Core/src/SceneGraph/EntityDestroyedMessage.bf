using Sedulous.Messaging;
namespace Sedulous.Engine.Core.SceneGraph;

class EntityDestroyedMessage : Message
{
    public EntityId EntityId { get; private set; }
    public Scene Scene { get; private set; }

    public this(EntityId entityId, Scene scene)
    {
        EntityId = entityId;
        Scene = scene;
    }
}