namespace Sedulous.GUI;

using System;
using System.Collections;

static class EventManager
{
	public static void RaiseEvent(UIElement target, RoutedEventArgs args)
	{
		if (target == null || args == null || args.RoutedEvent == null)
			return;

		args.OriginalSource = target;

		switch (args.RoutedEvent.Strategy)
		{
		case .Tunnel:
			RaiseTunnelEvent(target, args);

		case .Bubble:
			RaiseBubbleEvent(target, args);

		case .Direct:
			RaiseDirectEvent(target, args);
		}
	}

	private static void RaiseTunnelEvent(UIElement target, RoutedEventArgs args)
	{
		// Build path from root to target
		let path = scope List<UIElement>();
		var current = target;

		while (current != null)
		{
			path.Add(current);
			current = current.VisualParent;
		}

		// Invoke handlers from root to target (reverse order)
		for (var i = path.Count - 1; i >= 0 && !args.Handled; i--)
		{
			let element = path[i];
			// Stop if element was disposed during event handling
			if (element.IsDisposed)
				break;
			args.Source = element;
			element.[Friend]InvokeEventHandlers(args);
		}
	}

	private static void RaiseBubbleEvent(UIElement target, RoutedEventArgs args)
	{
		// Invoke handlers from target to root
		var current = target;

		while (current != null && !args.Handled)
		{
			// Stop if element was disposed during event handling
			if (current.IsDisposed)
				break;
			// Save parent before invoking handlers (element may be deleted during handling)
			let parent = current.VisualParent;
			args.Source = current;
			current.[Friend]InvokeEventHandlers(args);
			current = parent;
		}
	}

	private static void RaiseDirectEvent(UIElement target, RoutedEventArgs args)
	{
		args.Source = target;
		target.[Friend]InvokeEventHandlers(args);
	}

	// Raise paired tunnel+bubble events (e.g., PreviewMouseDown + MouseDown)
	public static void RaiseRoutedEvent(UIElement target, RoutedEvent tunnelEvent, RoutedEvent bubbleEvent, RoutedEventArgs args)
	{
		if (target == null || args == null)
			return;

		args.OriginalSource = target;

		// First, raise tunnel event (Preview)
		if (tunnelEvent != null)
		{
			args.RoutedEvent = tunnelEvent;
			RaiseTunnelEvent(target, args);
		}

		// Then, raise bubble event if not handled
		if (!args.Handled && bubbleEvent != null)
		{
			args.RoutedEvent = bubbleEvent;
			RaiseBubbleEvent(target, args);
		}
	}
}
