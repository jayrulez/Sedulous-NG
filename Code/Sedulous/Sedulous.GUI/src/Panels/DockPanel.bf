namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;
using System.Collections;

class DockPanel : Panel
{
	public bool LastChildFill = true;

	private Dictionary<UIElement, Dock> mDockPositions = new .() ~ delete _;

	public void SetDock(UIElement child, Dock dock)
	{
		mDockPositions[child] = dock;
		InvalidateMeasure();
	}

	public Dock GetDock(UIElement child)
	{
		return mDockPositions.TryGetValue(child, let value) ? value : Dock.Left;
	}

	protected override Size2F MeasureOverride(Size2F availableSize)
	{
		var remaining = availableSize;
		var desiredSize = Size2F.Zero;

		let lastIndex = LastChildFill ? (int32)mChildren.Count - 1 : (int32)mChildren.Count;

		for (var i < lastIndex)
		{
			let child = mChildren[i];
			if (!child.IsVisible)
				continue;

			let dock = GetDock(child);
			child.Measure(remaining);

			switch (dock)
			{
			case .Left, .Right:
				remaining.Width = Math.Max(0, remaining.Width - child.DesiredSize.Width);
				desiredSize.Width += child.DesiredSize.Width;
				desiredSize.Height = Math.Max(desiredSize.Height, child.DesiredSize.Height);

			case .Top, .Bottom:
				remaining.Height = Math.Max(0, remaining.Height - child.DesiredSize.Height);
				desiredSize.Height += child.DesiredSize.Height;
				desiredSize.Width = Math.Max(desiredSize.Width, child.DesiredSize.Width);
			}
		}

		// Measure last child if it fills
		if (LastChildFill && mChildren.Count > 0)
		{
			let lastChild = mChildren[mChildren.Count - 1];
			if (lastChild.IsVisible)
			{
				lastChild.Measure(remaining);
				desiredSize.Width = Math.Max(desiredSize.Width, lastChild.DesiredSize.Width);
				desiredSize.Height = Math.Max(desiredSize.Height, lastChild.DesiredSize.Height);
			}
		}

		return desiredSize;
	}

	protected override Size2F ArrangeOverride(Size2F finalSize)
	{
		var left = 0.0f;
		var top = 0.0f;
		var right = finalSize.Width;
		var bottom = finalSize.Height;

		let lastIndex = LastChildFill ? (int32)mChildren.Count - 1 : (int32)mChildren.Count;

		for (var i < lastIndex)
		{
			let child = mChildren[i];
			if (!child.IsVisible)
				continue;

			let dock = GetDock(child);
			var rect = RectangleF(Point2F.Zero, .Zero);

			switch (dock)
			{
			case .Left:
				rect = .(left, top, child.DesiredSize.Width, bottom - top);
				left += child.DesiredSize.Width;

			case .Top:
				rect = .(left, top, right - left, child.DesiredSize.Height);
				top += child.DesiredSize.Height;

			case .Right:
				rect = .(right - child.DesiredSize.Width, top, child.DesiredSize.Width, bottom - top);
				right -= child.DesiredSize.Width;

			case .Bottom:
				rect = .(left, bottom - child.DesiredSize.Height, right - left, child.DesiredSize.Height);
				bottom -= child.DesiredSize.Height;
			}

			child.Arrange(rect);
		}

		// Fill last child
		if (LastChildFill && mChildren.Count > 0)
		{
			let lastChild = mChildren[mChildren.Count - 1];
			if (lastChild.IsVisible)
			{
				lastChild.Arrange(RectangleF(left, top, right - left, bottom - top));
			}
		}

		return finalSize;
	}
}
