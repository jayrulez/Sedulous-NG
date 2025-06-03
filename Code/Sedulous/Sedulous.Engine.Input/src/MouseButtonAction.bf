using Sedulous.Platform.Core.Input;
using System;
using Sedulous.Utilities;
namespace Sedulous.Engine.Input;

class MouseButtonAction : InputAction
{
    private MouseDevice mMouse;
    private MouseButton mButton;

    public this(MouseDevice mouse, MouseButton button)
    {
        mMouse = mouse;
        mButton = button;
    }

    public override bool IsPressed() => mMouse.IsButtonPressed(mButton);
    public override bool IsHeld() => mMouse.IsButtonDown(mButton);
    public override void Update(Time time) { }
}