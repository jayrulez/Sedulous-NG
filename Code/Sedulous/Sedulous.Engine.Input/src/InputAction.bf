using System;
namespace Sedulous.Engine.Input;

abstract class InputAction
{
    public abstract bool IsPressed();
    public abstract bool IsHeld();
    public virtual float GetValue() => IsHeld() ? 1.0f : 0.0f;
    public abstract void Update(TimeSpan deltaTime);
}