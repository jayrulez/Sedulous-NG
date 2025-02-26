using Sedulous.Engine.Core;
using System;
namespace Sedulous.Engine.Navigation;

class NavigationSubsystem : Subsystem
{
	public override StringView Name => "Navigation";

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

	private void OnUpdate(IEngine.UpdateInfo info)
	{
	}
}