using Sedulous.Engine.Core.SceneGraph;
using Sedulous.Foundation.Mathematics;
namespace Sedulous.Engine.Physics;

class Collider : Component
{
    private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<Collider>();
    public override ComponentTypeId TypeId => sTypeId;
    
    public enum ColliderType { Box, Sphere, Capsule, Mesh }
    
    public ColliderType Type { get; set; } = .Box;
    public Vector3 Size { get; set; } = Vector3.One;
    public bool IsTrigger { get; set; } = false;
}