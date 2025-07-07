using Sedulous.SceneGraph;
using System;
using Sedulous.Utilities;
namespace Sedulous.Engine.Physics;

class CollisionModule : SceneModule
{
    public override StringView Name => "Collision";
    
    private PhysicsSubsystem mPhysicsSubsystem;

	private EntityQuery mCollidersQuery;
    
    public this(PhysicsSubsystem physicsSubsystem)
    {
        mPhysicsSubsystem = physicsSubsystem;
		mCollidersQuery = CreateQuery().With<Collider>();
    }

	public ~this()
	{
		delete mCollidersQuery;
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