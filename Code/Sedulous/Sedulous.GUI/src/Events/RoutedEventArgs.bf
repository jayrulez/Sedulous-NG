namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

class RoutedEventArgs
{
	public RoutedEvent RoutedEvent;
	public UIElement Source;           // Current element in the route
	public UIElement OriginalSource;   // Deepest element that raised the event
	public bool Handled;

	public this()
	{
	}

	public this(RoutedEvent routedEvent)
	{
		RoutedEvent = routedEvent;
	}
}

class MouseEventArgs : RoutedEventArgs
{
	public Point2F Position;           // Position relative to Source element
	public Point2F ScreenPosition;     // Absolute screen/window position
	public GUIMouseButton Button;
	public GUIModifierKeys Modifiers;
	public int32 ClickCount;

	public this() : base()
	{
	}

	public this(RoutedEvent routedEvent) : base(routedEvent)
	{
	}

	public Point2F GetPosition(UIElement relativeTo)
	{
		if (relativeTo == null)
			return ScreenPosition;
		return relativeTo.TransformFromRoot(ScreenPosition);
	}
}

class MouseWheelEventArgs : MouseEventArgs
{
	public float DeltaX;
	public float DeltaY;

	public this() : base()
	{
	}

	public this(RoutedEvent routedEvent) : base(routedEvent)
	{
	}
}

class MouseButtonEventArgs : MouseEventArgs
{
	public this() : base()
	{
	}

	public this(RoutedEvent routedEvent) : base(routedEvent)
	{
	}
}

class KeyEventArgs : RoutedEventArgs
{
	public GUIKey Key;
	public GUIModifierKeys Modifiers;
	public bool IsRepeat;

	public this() : base()
	{
	}

	public this(RoutedEvent routedEvent) : base(routedEvent)
	{
	}
}

class TextInputEventArgs : RoutedEventArgs
{
	public String Text ~ delete _;

	public this() : base()
	{
		Text = new .();
	}

	public this(RoutedEvent routedEvent) : base(routedEvent)
	{
		Text = new .();
	}

	public this(RoutedEvent routedEvent, StringView text) : base(routedEvent)
	{
		Text = new .(text);
	}
}

class FocusEventArgs : RoutedEventArgs
{
	public UIElement OtherElement; // The element that lost/gained focus

	public this() : base()
	{
	}

	public this(RoutedEvent routedEvent) : base(routedEvent)
	{
	}
}
