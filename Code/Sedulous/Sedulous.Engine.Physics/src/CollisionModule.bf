using Sedulous.SceneGraph;
using System;
using Sedulous.Utilities;
namespace Sedulous.Engine.Physics;

class CollisionModule : SceneModule
{
    public override StringView Name => "Collision";
    
    private PhysicsSubsystem mPhysicsSubsystem;
    
    public this(PhysicsSubsystem physicsSubsystem)
    {
        mPhysicsSubsystem = physicsSubsystem;
    }
    
    protected override void RegisterComponentInterests()
    {
        RegisterComponentInterest<Collider>();
    }
    
    protected override void OnUpdate(Time time)
    {
        // Perform collision detection
        PerformCollisionDetection();
    }
    
    private void PerformCollisionDetection()
    {
        // Broad phase and narrow phase collision detection
    }
}