using Sedulous.Engine.Core.SceneGraph;
using System;
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
    
    protected override void Update(TimeSpan deltaTime)
    {
        // Perform collision detection
        PerformCollisionDetection();
    }
    
    private void PerformCollisionDetection()
    {
        // Broad phase and narrow phase collision detection
    }
}