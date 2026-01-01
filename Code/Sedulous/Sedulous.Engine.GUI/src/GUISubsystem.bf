using Sedulous.Engine.Core;
using System;
namespace Sedulous.Engine.GUI;

class GUISubsystem : Subsystem
{
	public override StringView Name => "GUI";

	private IEngine mEngine;

	public this()
	{
	}

	protected override Result<void> OnInitializing(IEngine engine)
	{
		mEngine = engine;

		return base.OnInitializing(engine);
	}

	protected override void OnUnitializing(IEngine engine)
	{
		base.OnUnitializing(engine);
	}
}