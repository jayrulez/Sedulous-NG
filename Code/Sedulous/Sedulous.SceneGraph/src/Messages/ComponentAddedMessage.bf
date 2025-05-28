using Sedulous.Messaging;
namespace Sedulous.Engine.Core.SceneGraph;

class ComponentAddedMessage : Message
{
    public Entity Entity { get; private set; }
    public IComponent Component { get; private set; }

    public this(Entity entity, IComponent component)
    {
        Entity = entity;
        Component = component;
    }
}