using Sedulous.SceneGraph;
using System;
using Sedulous.Utilities;
using System.Collections;
namespace Sedulous.Engine.Core;

class BehaviourModule : SceneModule
{
	private readonly List<Behaviour> mBehaviours = new .() ~ delete _;

	public override StringView Name => nameof(BehaviourModule);

	protected override void RegisterComponentInterests()
	{
		RegisterComponentInterest<Behaviour>();
	}

	protected override bool ShouldTrackEntity(Entity entity)
	{
		return entity.HasComponent<Behaviour>();
	}

	internal void OnVariableUpdate(Time time){}
	internal void OnFixedUpdate(Time time){}
	internal void OnPreUpdate(Time time){}
	internal void OnPostUpdate(Time time){}
}