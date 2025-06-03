using Sedulous.Platform.Core.Input;
using System;
using Sedulous.Utilities;
namespace Sedulous.Engine.Input;

class GamePadAxisAction : InputAction
{
    private GamePadDevice mGamePad;
    private GamePadAxis mAxis;
    private float mDeadzone;

    public this(GamePadDevice gamePad, GamePadAxis axis, float deadzone = 0.1f)
    {
        mGamePad = gamePad;
        mAxis = axis;
        mDeadzone = deadzone;
    }

    public override bool IsPressed() => Math.Abs(GetValue()) > mDeadzone;
    public override bool IsHeld() => IsPressed();

    public override float GetValue()
    {
        var value = mGamePad.GetAxisValue(mAxis);
        return Math.Abs(value) > mDeadzone ? value : 0.0f;
    }

    public override void Update(Time time) { }
}