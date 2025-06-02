using Sedulous.SceneGraph;
using Sedulous.Mathematics;
namespace Sedulous.Engine.Physics;

class RigidBody : Component
{
    private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<RigidBody>();
    public override ComponentTypeId TypeId => sTypeId;

    public Vector3 Position { get; set; }
    public Quaternion Rotation { get; set; }
    public Vector3 Velocity { get; set; }
    public Vector3 AngularVelocity { get; set; }
    public float Mass { get; set; } = 1.0f;
    public bool IsKinematic { get; set; } = false;
}