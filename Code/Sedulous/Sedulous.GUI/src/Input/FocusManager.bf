namespace Sedulous.GUI;

using System;

using internal Sedulous.GUI;

static class FocusManager
{
	private static UIElement sFocusedElement;

	public static UIElement FocusedElement => sFocusedElement;

	public static void SetFocus(UIElement element)
	{
		if (sFocusedElement == element)
			return;

		let oldFocus = sFocusedElement;
		sFocusedElement = null;

		// Notify old element
		if (oldFocus != null)
		{
			oldFocus.OnLostFocus();
		}

		// Set and notify new element
		if (element != null && element.Focusable && element.IsEnabled && element.IsVisible)
		{
			sFocusedElement = element;
			element.OnGotFocus();
		}
	}

	public static void ClearFocus()
	{
		SetFocus(null);
	}

	public static bool MoveFocus(FocusNavigationDirection direction)
	{
		if (sFocusedElement == null)
			return false;

		let nextElement = FindNextFocusable(sFocusedElement, direction);
		if (nextElement != null)
		{
			SetFocus(nextElement);
			return true;
		}

		return false;
	}

	private static UIElement FindNextFocusable(UIElement current, FocusNavigationDirection direction)
	{
		// Get the root of the visual tree
		var root = current;
		while (root.VisualParent != null)
			root = root.VisualParent;

		// Collect all focusable elements
		let focusables = scope System.Collections.List<UIElement>();
		CollectFocusableElements(root, focusables);

		if (focusables.Count == 0)
			return null;

		// Find current index
		int32 currentIndex = -1;
		for (int32 i = 0; i < focusables.Count; i++)
		{
			if (focusables[i] == current)
			{
				currentIndex = i;
				break;
			}
		}

		if (currentIndex < 0)
			return focusables.Count > 0 ? focusables[0] : null;

		// Find next based on direction
		switch (direction)
		{
		case .Next:
			let nextIndex = (currentIndex + 1) % focusables.Count;
			return focusables[nextIndex];

		case .Previous:
			let prevIndex = (currentIndex - 1 + focusables.Count) % focusables.Count;
			return focusables[prevIndex];

		default:
			// For directional navigation, would need position-based logic
			return null;
		}
	}

	private static void CollectFocusableElements(UIElement element, System.Collections.List<UIElement> list)
	{
		if (!element.IsVisible || !element.IsEnabled)
			return;

		if (element.Focusable)
			list.Add(element);

		for (int32 i = 0; i < element.VisualChildrenCount; i++)
		{
			let child = element.GetVisualChild(i);
			if (child != null)
				CollectFocusableElements(child, list);
		}
	}
}
