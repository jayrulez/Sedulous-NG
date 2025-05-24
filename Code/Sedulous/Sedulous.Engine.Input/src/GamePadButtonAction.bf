using Sedulous.Platform.Core.Input;
using System;
namespace Sedulous.Engine.Input;

class GamePadButtonAction : InputAction
{
    private GamePadDevice mGamePad;
    private GamePadButton mButton;

    public this(GamePadDevice gamePad, GamePadButton button)
    {
        mGamePad = gamePad;
        mButton = button;
    }

    public override bool IsPressed() => mGamePad.IsButtonPressed(mButton);
    public override bool IsHeld() => mGamePad.IsButtonDown(mButton);
    public override void Update(TimeSpan deltaTime) { }
}