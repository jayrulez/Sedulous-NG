using Sedulous.Platform.Core.Input;
using System;
namespace Sedulous.Engine.Input;

class KeyAction : InputAction
{
    private KeyboardDevice mKeyboard;
    private Key mKey;

    public this(KeyboardDevice keyboard, Key key)
    {
        mKeyboard = keyboard;
        mKey = key;
    }

    public override bool IsPressed() => mKeyboard.IsKeyPressed(mKey);
    public override bool IsHeld() => mKeyboard.IsKeyDown(mKey);
    public override void Update(TimeSpan deltaTime) { }
}