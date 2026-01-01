namespace Sedulous.GUI;

using Sedulous.Mathematics;
using Sedulous.Foundation.Core;
using System;

delegate void GUIMouseButtonEventHandler(Point2F position, GUIMouseButton button, GUIModifierKeys modifiers);
delegate void GUIMouseMoveEventHandler(Point2F position, Point2F delta);
delegate void GUIMouseWheelEventHandler(Point2F position, float deltaX, float deltaY);
delegate void GUIKeyEventHandler(GUIKey key, GUIModifierKeys modifiers, bool isRepeat);
delegate void GUITextInputEventHandler(StringView text);

interface IInputProvider
{
	// Current state
	Point2F MousePosition { get; }
	bool IsMouseButtonDown(GUIMouseButton button);
	bool IsKeyDown(GUIKey key);
	GUIModifierKeys CurrentModifiers { get; }

	// Mouse events
	EventAccessor<GUIMouseButtonEventHandler> MouseButtonPressed { get; }
	EventAccessor<GUIMouseButtonEventHandler> MouseButtonReleased { get; }
	EventAccessor<GUIMouseMoveEventHandler> MouseMoved { get; }
	EventAccessor<GUIMouseWheelEventHandler> MouseWheelScrolled { get; }

	// Keyboard events
	EventAccessor<GUIKeyEventHandler> KeyPressed { get; }
	EventAccessor<GUIKeyEventHandler> KeyReleased { get; }
	EventAccessor<GUITextInputEventHandler> TextInput { get; }

	// Clipboard
	Result<void> SetClipboardText(StringView text);
	Result<void> GetClipboardText(String outText);

	// Cursor
	void SetCursor(CursorType cursor);
}
