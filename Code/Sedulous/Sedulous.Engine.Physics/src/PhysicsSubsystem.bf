using Sedulous.Engine.Core;
using System;
using Sedulous.Engine.Core.SceneGraph;
using System.Collections;
namespace Sedulous.Engine.Physics;

class PhysicsSubsystem : Subsystem
{
	public override StringView Name => "Physics";

	private IEngine mEngine;

	private IEngine.RegisteredUpdateFunctionInfo? mUpdateFunctionRegistration;

	public this()
	{
	}

	protected override Result<void> OnInitializing(IEngine engine)
	{
		mEngine = engine;
		
		mUpdateFunctionRegistration = engine.RegisterUpdateFunction(.()
			{
				Priority = 1,
				Stage = .FixedUpdate,
				Function = new => OnUpdate
			});

		return base.OnInitializing(engine);
	}

	protected override void OnUnitializing(IEngine engine)
	{
		if (mUpdateFunctionRegistration.HasValue)
		{
			engine.UnregisterUpdateFunction(mUpdateFunctionRegistration.Value);
			delete mUpdateFunctionRegistration.Value.Function;
			mUpdateFunctionRegistration = null;
		}

		base.OnUnitializing(engine);
	}

	private RigidBodyModule mRigidBodyModule = null;
	private CollisionModule mCollisionModule = null;
    protected override void CreateSceneModules(Scene scene, List<SceneModule> modules)
    {
        // Create multiple physics-related modules
        modules.Add(mRigidBodyModule = new RigidBodyModule(this));        // Rigid body simulation
        modules.Add(mCollisionModule = new CollisionModule(this));        // Collision detection
        //modules.Add(new TriggerModule(this));          // Trigger volumes
        //modules.Add(new PhysicsDebugModule(this));     // Debug visualization
    }

    protected override void DestroySceneModules(Scene scene)
    {
		delete mRigidBodyModule;
		delete mCollisionModule;
    }

	private void OnUpdate(IEngine.UpdateInfo info)
	{
	}
}