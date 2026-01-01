namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;
using System.Collections;

using internal Sedulous.GUI;

static class PopupManager
{
	private static List<Popup> sOpenPopups = new .() ~ delete _;

	public static bool HasOpenPopups => !sOpenPopups.IsEmpty;

	public static void Show(Popup popup)
	{
		if (popup != null && !sOpenPopups.Contains(popup))
			sOpenPopups.Add(popup);
	}

	public static void Hide(Popup popup)
	{
		sOpenPopups.Remove(popup);
	}

	public static void CloseAll()
	{
		for (let popup in sOpenPopups)
			popup.[Friend]mIsOpen = false;
		sOpenPopups.Clear();
	}

	public static void UpdateLayout(Size2F viewportSize)
	{
		for (let popup in sOpenPopups)
		{
			if (popup.Child != null)
			{
				popup.Child.Measure(viewportSize);
				let pos = popup.CalculatePosition();
				popup.Child.Arrange(RectangleF(pos.X, pos.Y, popup.Child.DesiredSize.Width, popup.Child.DesiredSize.Height));
			}
		}
	}

	public static void RenderPopups(IUIRenderer renderer)
	{
		for (let popup in sOpenPopups)
		{
			if (popup.Child != null)
			{
				let pos = popup.CalculatePosition();
				renderer.PushTransform(pos);
				popup.Child.Render(renderer);
				renderer.PopTransform();
			}
		}
	}

	public static UIElement HitTestPopups(Point2F point)
	{
		// Check popups in reverse order (topmost first)
		for (var i = sOpenPopups.Count - 1; i >= 0; i--)
		{
			let popup = sOpenPopups[i];
			if (popup.Child != null)
			{
				let pos = popup.CalculatePosition();
				let localPoint = Point2F(point.X - pos.X, point.Y - pos.Y);
				let hit = popup.Child.HitTest(localPoint);
				if (hit != null)
					return hit;
			}
		}
		return null;
	}

	// Close popups that don't stay open when clicking outside
	public static void HandleClickOutside(Point2F point)
	{
		for (var i = sOpenPopups.Count - 1; i >= 0; i--)
		{
			let popup = sOpenPopups[i];
			if (!popup.StaysOpen)
			{
				let pos = popup.CalculatePosition();
				let childSize = popup.Child?.DesiredSize ?? .Zero;
				let bounds = RectangleF(pos.X, pos.Y, childSize.Width, childSize.Height);

				if (!bounds.Contains(point))
				{
					popup.IsOpen = false;
				}
			}
		}
	}
}
