using Sedulous.Foundation.Mathematics;
using Sedulous.Messaging;
namespace Sedulous.Engine.Core.SceneGraph;

class TransformChangedMessage : Message
{
    public Entity Entity { get; private set; }
    public Matrix NewWorldMatrix { get; private set; }

    public this(Entity entity, Matrix newWorldMatrix)
    {
        Entity = entity;
        NewWorldMatrix = newWorldMatrix;
    }
}