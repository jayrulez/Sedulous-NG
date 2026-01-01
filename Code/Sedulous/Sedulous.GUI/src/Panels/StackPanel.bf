namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

class StackPanel : Panel
{
	public Orientation Orientation = .Vertical;
	public float Spacing = 0;

	protected override Size2F MeasureOverride(Size2F availableSize)
	{
		var desiredSize = Size2F.Zero;
		let isHorizontal = Orientation == .Horizontal;

		for (var i < mChildren.Count)
		{
			let child = mChildren[i];
			if (!child.IsVisible)
				continue;

			child.Measure(availableSize);

			if (isHorizontal)
			{
				desiredSize.Width += child.DesiredSize.Width;
				desiredSize.Height = Math.Max(desiredSize.Height, child.DesiredSize.Height);
				if (i > 0)
					desiredSize.Width += Spacing;
			}
			else
			{
				desiredSize.Width = Math.Max(desiredSize.Width, child.DesiredSize.Width);
				desiredSize.Height += child.DesiredSize.Height;
				if (i > 0)
					desiredSize.Height += Spacing;
			}
		}

		return desiredSize;
	}

	protected override Size2F ArrangeOverride(Size2F finalSize)
	{
		let isHorizontal = Orientation == .Horizontal;
		var offset = 0.0f;
		var visibleIndex = 0;

		for (let child in mChildren)
		{
			if (!child.IsVisible)
				continue;

			if (isHorizontal)
			{
				if (visibleIndex > 0)
					offset += Spacing;

				let childRect = RectangleF(offset, 0, child.DesiredSize.Width, finalSize.Height);
				child.Arrange(childRect);
				offset += child.DesiredSize.Width;
			}
			else
			{
				if (visibleIndex > 0)
					offset += Spacing;

				let childRect = RectangleF(0, offset, finalSize.Width, child.DesiredSize.Height);
				child.Arrange(childRect);
				offset += child.DesiredSize.Height;
			}

			visibleIndex++;
		}

		return finalSize;
	}
}
