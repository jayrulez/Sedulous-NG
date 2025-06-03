using System;
using System.Collections;
using Sedulous.Utilities;
namespace Sedulous.Engine.Input;

class InputContext
{
    internal Dictionary<String, InputAction> mActions = new .() ~ DeleteDictionaryAndKeysAndValues!(_);
    private List<InputBinding> mBindings = new .() ~ delete _;

	public~this()
	{
		for(var binding in mBindings)
		{
			binding.Dispose();
		}
	}

    public void BindAction(StringView actionName, InputAction action)
    {
        String key = new .(actionName);
        mActions[key] = action;
    }

    public void AddBinding(StringView actionName, delegate void(float value) callback)
    {
        mBindings.Add(InputBinding(actionName, callback, this));
    }

    public void Update(Time time)
    {
        for (var action in mActions.Values)
        {
            action.Update(time);
        }

        // Process bindings
        for (var binding in ref mBindings)
        {
            binding.Update(time);
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

    public float GetActionValue(StringView actionName)
    {
        if (mActions.TryGetValue(scope String(actionName), var action))
        {
            return action.GetValue();
        }
        return 0.0f;
    }
}