using Sedulous.SceneGraph;
using System;
using Sedulous.Utilities;
using System.Collections;
namespace Sedulous.Engine.Physics;

class RigidBodyModule : SceneModule
{
	public override StringView Name => "RigidBody";

	private PhysicsSubsystem mPhysicsSubsystem;

	private EntityQuery mRigidBodiesQuery;

	public this(PhysicsSubsystem physicsSubsystem)
	{
		mPhysicsSubsystem = physicsSubsystem;

		mRigidBodiesQuery = CreateQuery().With<RigidBody>();
	}

	public ~this()
	{
		DestroyQuery(mRigidBodiesQuery);
	}

	protected override void OnUpdate(Time time)
	{
		// Update rigid body simulation
		List<Entity> entities = mRigidBodiesQuery.GetEntities(Scene, .. scope .());
		for (var entity in entities)
		{
			if (let rigidBody = entity.GetComponent<RigidBody>())
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
	}
}