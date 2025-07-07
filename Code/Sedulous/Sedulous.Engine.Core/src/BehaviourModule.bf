using Sedulous.SceneGraph;
using System;
using Sedulous.Utilities;
using System.Collections;
namespace Sedulous.Engine.Core;

class BehaviourModule : SceneModule
{
	private readonly List<Behaviour> mBehaviours = new .() ~ delete _;

	public override StringView Name => nameof(BehaviourModule);

	private EntityQuery mbehaviours;

	public this()
	{
		mbehaviours = CreateQuery().With<Behaviour>();
	}

	public ~this()
	{
		DestroyQuery(mbehaviours);
	}

	internal void OnVariableUpdate(Time time){}
	internal void OnFixedUpdate(Time time){}
	internal void OnPreUpdate(Time time){}
	internal void OnPostUpdate(Time time){}
}