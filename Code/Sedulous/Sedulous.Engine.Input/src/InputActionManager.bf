using System.Collections;
using System;
using Sedulous.Utilities;
namespace Sedulous.Engine.Input;

class InputActionManager
{
	private Dictionary<String, InputAction> mActions = new .() ~ delete _;
	private List<InputContext> mContextStack = new .() ~ delete _;

	public ~this()
	{
		for (var entry in mActions)
		{
			delete entry.key;
			delete entry.value;
		}

		mActions.Clear();

		for (var entry in mContextStack)
		{
			delete entry;
		}

		mContextStack.Clear();
	}

	public void RegisterAction(StringView name, InputAction action)
	{
		String key = new .(name);
		mActions[key] = action;
	}

	public void PushContext(InputContext context)
	{
		mContextStack.Add(context);
	}

	public void PopContext()
	{
		if (mContextStack.Count > 0)
		{
			delete mContextStack[mContextStack.Count - 1];
			mContextStack.RemoveAt(mContextStack.Count - 1);
		}
	}

	public void Update(Time time)
	{
		// Update all actions in current contexts
		for (var context in mContextStack)
		{
			context.Update(time);
		}
	}

	public bool IsActionPressed(StringView actionName)
	{
		if (mActions.TryGetValue(scope String(actionName), var action))
		{
			return action.IsPressed();
		}
		return false;
	}

	public bool IsActionHeld(StringView actionName)
	{
		if (mActions.TryGetValue(scope String(actionName), var action))
		{
			return action.IsHeld();
		}
		return false;
	}

	public float GetActionValue(StringView actionName)
	{
		if (mActions.TryGetValue(scope String(actionName), var action))
		{
			return action.GetValue();
		}
		return 0.0f;
	}
}