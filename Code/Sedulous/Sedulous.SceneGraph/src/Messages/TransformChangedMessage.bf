using Sedulous.Mathematics;
using Sedulous.Messaging;
namespace Sedulous.SceneGraph;

class TransformChangedMessage : Message
{
    public Entity Entity { get; private set; }

    public this(Entity entity)
    {
        Entity = entity;
    }
}