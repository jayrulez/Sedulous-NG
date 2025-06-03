using Sedulous.SceneGraph;
using System;
using Sedulous.Utilities;
namespace Sedulous.Engine.Physics;

class RigidBodyModule : SceneModule
{
    public override StringView Name => "RigidBody";
    
    private PhysicsSubsystem mPhysicsSubsystem;
    
    public this(PhysicsSubsystem physicsSubsystem)
    {
        mPhysicsSubsystem = physicsSubsystem;
    }
    
    protected override void RegisterComponentInterests()
    {
        RegisterComponentInterest<RigidBody>();
    }
    
    protected override void OnUpdate(Time time)
    {
        // Update rigid body simulation
        for (var entity in TrackedEntities)
        {
            var rigidBody = entity.GetComponent<RigidBody>();
            if (rigidBody != null)
            {
                UpdateRigidBody(entity, rigidBody, time);
            }
        }
    }
    
    private void UpdateRigidBody(Entity entity, RigidBody rigidBody, Time time)
    {
        // Integrate physics
        entity.Transform.Position = rigidBody.Position;
        entity.Transform.Rotation = rigidBody.Rotation;
        entity.Transform.MarkDirty();
    }
}