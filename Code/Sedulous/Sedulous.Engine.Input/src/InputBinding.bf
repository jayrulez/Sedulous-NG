using System;
namespace Sedulous.Engine.Input;

struct InputBinding
{
    public String ActionName;
    public delegate void(float value) Callback;
    public InputContext Context;
    public float LastValue;
    public bool WasActive;

    public this(StringView actionName, delegate void(float value) callback, InputContext context)
    {
        ActionName = new String(actionName);
        Callback = callback;
        Context = context;
        LastValue = 0.0f;
        WasActive = false;
    }

    public void Update(TimeSpan deltaTime) mut
    {
        if (Context != null && Callback != null)
        {
            // Get current value for this action
            var currentValue = Context.GetActionValue(ActionName);
            var isActive = Math.Abs(currentValue) > 0.01f; // Dead zone
            
            // Invoke callback for significant changes or continuous input
            if (isActive || (WasActive && !isActive))
            {
                Callback(currentValue);
            }
            
            LastValue = currentValue;
            WasActive = isActive;
        }
    }
}