using Sedulous.Engine.Core.SceneGraph;
using System;
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
    
    protected override void Update(TimeSpan deltaTime)
    {
        // Update rigid body simulation
        for (var entity in TrackedEntities)
        {
            var rigidBody = entity.GetComponent<RigidBody>();
            if (rigidBody != null)
            {
                UpdateRigidBody(entity, rigidBody, deltaTime);
            }
        }
    }
    
    private void UpdateRigidBody(Entity entity, RigidBody rigidBody, TimeSpan deltaTime)
    {
        // Integrate physics
        entity.Transform.Position = rigidBody.Position;
        entity.Transform.Rotation = rigidBody.Rotation;
        entity.Transform.MarkDirty();
    }
}