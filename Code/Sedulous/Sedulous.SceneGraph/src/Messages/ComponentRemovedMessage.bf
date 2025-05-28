using Sedulous.Messaging;
namespace Sedulous.SceneGraph;

class ComponentRemovedMessage : Message
{
    public Entity Entity { get; private set; }
    public ComponentTypeId ComponentTypeId { get; private set; }

    public this(Entity entity, ComponentTypeId componentTypeId)
    {
        Entity = entity;
        ComponentTypeId = componentTypeId;
    }
}