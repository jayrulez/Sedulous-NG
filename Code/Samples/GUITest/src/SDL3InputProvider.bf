namespace GUITest;

using Sedulous.GUI;
using Sedulous.Mathematics;
using Sedulous.Platform.SDL3;
using Sedulous.Platform.SDL3.Input;
using Sedulous.Platform.Core.Input;
using Sedulous.Foundation.Core;
using System;

class SDL3InputProvider : IInputProvider
{
	private InputSystem mInputSystem;
	private MouseDevice mMouse;
	private KeyboardDevice mKeyboard;
	private Point2F mMousePosition;
	private GUIModifierKeys mModifiers;

	private EventAccessor<GUIMouseButtonEventHandler> mMouseButtonPressed = new .() ~ delete _;
	private EventAccessor<GUIMouseButtonEventHandler> mMouseButtonReleased = new .() ~ delete _;
	private EventAccessor<GUIMouseMoveEventHandler> mMouseMoved = new .() ~ delete _;
	private EventAccessor<GUIMouseWheelEventHandler> mMouseWheelScrolled = new .() ~ delete _;
	private EventAccessor<GUIKeyEventHandler> mKeyPressed = new .() ~ delete _;
	private EventAccessor<GUIKeyEventHandler> mKeyReleased = new .() ~ delete _;
	private EventAccessor<GUITextInputEventHandler> mTextInput = new .() ~ delete _;

	
	private MouseButtonEventHandler mOnMouseButtonPressed  = null;
	private MouseButtonEventHandler mOnMouseButtonReleased  = null;
	private MouseMoveEventHandler mOnMouseMoved  = null;
	private MouseWheelEventHandler mOnMouseWheelScrolled  = null;
	private KeyPressedEventHandler mOnKeyPressed  = null;
	private KeyReleasedEventHandler mOnKeyReleased  = null;
	private TextInputEventHandler mOnTextInput  = null;

	public this(InputSystem inputSystem)
	{
		mInputSystem = inputSystem;
		mMouse = inputSystem.GetMouse();
		mKeyboard = inputSystem.GetKeyboard();

		// Subscribe to platform input events
		mMouse.ButtonPressed.Subscribe(mOnMouseButtonPressed = new => OnMouseButtonPressed);
		mMouse.ButtonReleased.Subscribe(mOnMouseButtonReleased = new => OnMouseButtonReleased);
		mMouse.Moved.Subscribe(mOnMouseMoved = new => OnMouseMoved);
		mMouse.WheelScrolled.Subscribe(mOnMouseWheelScrolled = new => OnMouseWheel);
		mKeyboard.KeyPressed.Subscribe(mOnKeyPressed = new => OnKeyPressed);
		mKeyboard.KeyReleased.Subscribe(mOnKeyReleased = new => OnKeyReleased);
		mKeyboard.TextInput.Subscribe(mOnTextInput = new => OnTextInput);
	}

	public ~this()
	{
		mMouse.ButtonPressed.Unsubscribe(mOnMouseButtonPressed);
		mMouse.ButtonReleased.Unsubscribe(mOnMouseButtonReleased);
		mMouse.Moved.Unsubscribe(mOnMouseMoved);
		mMouse.WheelScrolled.Unsubscribe(mOnMouseWheelScrolled);
		mKeyboard.KeyPressed.Unsubscribe(mOnKeyPressed);
		mKeyboard.KeyReleased.Unsubscribe(mOnKeyReleased);
		mKeyboard.TextInput.Unsubscribe(mOnTextInput);
	}

	// === IInputProvider Implementation ===

	public Point2F MousePosition => mMousePosition;

	public bool IsMouseButtonDown(GUIMouseButton button)
	{
		return mMouse.IsButtonDown(MapMouseButton(button));
	}

	public bool IsKeyDown(GUIKey key)
	{
		return mKeyboard.IsKeyDown(MapKey(key));
	}

	public GUIModifierKeys CurrentModifiers => mModifiers;

	public EventAccessor<GUIMouseButtonEventHandler> MouseButtonPressed => mMouseButtonPressed;
	public EventAccessor<GUIMouseButtonEventHandler> MouseButtonReleased => mMouseButtonReleased;
	public EventAccessor<GUIMouseMoveEventHandler> MouseMoved => mMouseMoved;
	public EventAccessor<GUIMouseWheelEventHandler> MouseWheelScrolled => mMouseWheelScrolled;
	public EventAccessor<GUIKeyEventHandler> KeyPressed => mKeyPressed;
	public EventAccessor<GUIKeyEventHandler> KeyReleased => mKeyReleased;
	public EventAccessor<GUITextInputEventHandler> TextInput => mTextInput;

	public Result<void> SetClipboardText(StringView text)
	{
		// TODO: Implement clipboard
		return .Ok;
	}

	public Result<void> GetClipboardText(String outText)
	{
		// TODO: Implement clipboard
		return .Ok;
	}

	public void SetCursor(CursorType cursor)
	{
		// TODO: Implement cursor change
	}

	// === Event Handlers ===

	private void OnMouseButtonPressed(Sedulous.Platform.Core.Window window, MouseDevice device, MouseButton button)
	{
		UpdateModifiers();
		mMouseButtonPressed.[Friend]Invoke(mMousePosition, MapMouseButton(button), mModifiers);
	}

	private void OnMouseButtonReleased(Sedulous.Platform.Core.Window window, MouseDevice device, MouseButton button)
	{
		UpdateModifiers();
		mMouseButtonReleased.[Friend]Invoke(mMousePosition, MapMouseButton(button), mModifiers);
	}

	private void OnMouseMoved(Sedulous.Platform.Core.Window window, MouseDevice device, float x, float y, float dx, float dy)
	{
		mMousePosition = .(x, y);
		mMouseMoved.[Friend]Invoke(mMousePosition, .(dx, dy));
	}

	private void OnMouseWheel(Sedulous.Platform.Core.Window window, MouseDevice device, float x, float y)
	{
		mMouseWheelScrolled.[Friend]Invoke(mMousePosition, x, y);
	}

	private void OnKeyPressed(Sedulous.Platform.Core.Window window, KeyboardDevice device, Key key, bool ctrl, bool alt, bool shift, bool @repeat)
	{
		mModifiers = .(ctrl, shift, alt);
		mKeyPressed.[Friend]Invoke(MapKey(key), mModifiers, @repeat);
	}

	private void OnKeyReleased(Sedulous.Platform.Core.Window window, KeyboardDevice device, Key key)
	{
		UpdateModifiers();
		mKeyReleased.[Friend]Invoke(MapKey(key), mModifiers, false);
	}

	private void OnTextInput(Sedulous.Platform.Core.Window window, KeyboardDevice device)
	{
		String text = scope .();
		device.GetTextInput(text);
		if (!text.IsEmpty)
			mTextInput.[Friend]Invoke(text);
	}

	private void UpdateModifiers()
	{
		mModifiers = .(
			mKeyboard.IsControlDown,
			mKeyboard.IsShiftDown,
			mKeyboard.IsAltDown
		);
	}

	// === Key/Button Mapping ===

	private static GUIMouseButton MapMouseButton(MouseButton button)
	{
		switch (button)
		{
		case .Left: return .Left;
		case .Right: return .Right;
		case .Middle: return .Middle;
		case .XButton1: return .XButton1;
		case .XButton2: return .XButton2;
		default: return .None;
		}
	}

	private static MouseButton MapMouseButton(GUIMouseButton button)
	{
		switch (button)
		{
		case .Left: return .Left;
		case .Right: return .Right;
		case .Middle: return .Middle;
		case .XButton1: return .XButton1;
		case .XButton2: return .XButton2;
		default: return .None;
		}
	}

	private static GUIKey MapKey(Key key)
	{
		switch (key)
		{
		case .Tab: return .Tab;
		case .Return: return .Return;
		case .Escape: return .Escape;
		case .Space: return .Space;
		case .Backspace: return .Backspace;
		case .Delete: return .Delete;
		case .Insert: return .Insert;
		case .Left: return .Left;
		case .Right: return .Right;
		case .Up: return .Up;
		case .Down: return .Down;
		case .Home: return .Home;
		case .End: return .End;
		case .PageUp: return .PageUp;
		case .PageDown: return .PageDown;
		case .LeftShift: return .LeftShift;
		case .RightShift: return .RightShift;
		case .LeftControl: return .LeftControl;
		case .RightControl: return .RightControl;
		case .LeftAlt: return .LeftAlt;
		case .RightAlt: return .RightAlt;
		case .A: return .A;
		case .B: return .B;
		case .C: return .C;
		case .D: return .D;
		case .E: return .E;
		case .F: return .F;
		case .G: return .G;
		case .H: return .H;
		case .I: return .I;
		case .J: return .J;
		case .K: return .K;
		case .L: return .L;
		case .M: return .M;
		case .N: return .N;
		case .O: return .O;
		case .P: return .P;
		case .Q: return .Q;
		case .R: return .R;
		case .S: return .S;
		case .T: return .T;
		case .U: return .U;
		case .V: return .V;
		case .W: return .W;
		case .X: return .X;
		case .Y: return .Y;
		case .Z: return .Z;
		case .D0: return .D0;
		case .D1: return .D1;
		case .D2: return .D2;
		case .D3: return .D3;
		case .D4: return .D4;
		case .D5: return .D5;
		case .D6: return .D6;
		case .D7: return .D7;
		case .D8: return .D8;
		case .D9: return .D9;
		case .F1: return .F1;
		case .F2: return .F2;
		case .F3: return .F3;
		case .F4: return .F4;
		case .F5: return .F5;
		case .F6: return .F6;
		case .F7: return .F7;
		case .F8: return .F8;
		case .F9: return .F9;
		case .F10: return .F10;
		case .F11: return .F11;
		case .F12: return .F12;
		default: return .None;
		}
	}

	private static Key MapKey(GUIKey key)
	{
		switch (key)
		{
		case .Tab: return .Tab;
		case .Return: return .Return;
		case .Escape: return .Escape;
		case .Space: return .Space;
		case .Backspace: return .Backspace;
		case .Delete: return .Delete;
		case .Insert: return .Insert;
		case .Left: return .Left;
		case .Right: return .Right;
		case .Up: return .Up;
		case .Down: return .Down;
		case .Home: return .Home;
		case .End: return .End;
		case .PageUp: return .PageUp;
		case .PageDown: return .PageDown;
		case .LeftShift: return .LeftShift;
		case .RightShift: return .RightShift;
		case .LeftControl: return .LeftControl;
		case .RightControl: return .RightControl;
		case .LeftAlt: return .LeftAlt;
		case .RightAlt: return .RightAlt;
		case .A: return .A;
		case .B: return .B;
		case .C: return .C;
		case .D: return .D;
		case .E: return .E;
		case .F: return .F;
		case .G: return .G;
		case .H: return .H;
		case .I: return .I;
		case .J: return .J;
		case .K: return .K;
		case .L: return .L;
		case .M: return .M;
		case .N: return .N;
		case .O: return .O;
		case .P: return .P;
		case .Q: return .Q;
		case .R: return .R;
		case .S: return .S;
		case .T: return .T;
		case .U: return .U;
		case .V: return .V;
		case .W: return .W;
		case .X: return .X;
		case .Y: return .Y;
		case .Z: return .Z;
		case .D0: return .D0;
		case .D1: return .D1;
		case .D2: return .D2;
		case .D3: return .D3;
		case .D4: return .D4;
		case .D5: return .D5;
		case .D6: return .D6;
		case .D7: return .D7;
		case .D8: return .D8;
		case .D9: return .D9;
		case .F1: return .F1;
		case .F2: return .F2;
		case .F3: return .F3;
		case .F4: return .F4;
		case .F5: return .F5;
		case .F6: return .F6;
		case .F7: return .F7;
		case .F8: return .F8;
		case .F9: return .F9;
		case .F10: return .F10;
		case .F11: return .F11;
		case .F12: return .F12;
		default: return .None;
		}
	}
}
