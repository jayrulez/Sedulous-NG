namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

class Popup : FrameworkElement
{
	private UIElement mChild;
	private bool mIsOpen;

	public UIElement Child
	{
		get => mChild;
		set
		{
			if (mChild != null)
				RemoveVisualChild(mChild);

			mChild = value;

			if (mChild != null)
				AddVisualChild(mChild);

			InvalidateMeasure();
		}
	}

	public bool IsOpen
	{
		get => mIsOpen;
		set
		{
			if (mIsOpen != value)
			{
				mIsOpen = value;
				if (mIsOpen)
					PopupManager.Show(this);
				else
					PopupManager.Hide(this);
			}
		}
	}

	public UIElement PlacementTarget;
	public PlacementMode Placement = .Bottom;
	public Point2F Offset;
	public bool StaysOpen = true;

	internal Point2F CalculatePosition()
	{
		if (PlacementTarget == null)
			return Offset;

		let targetBounds = PlacementTarget.Bounds;
		let targetPos = PlacementTarget.TransformToRoot(Point2F.Zero);
		let childSize = mChild?.DesiredSize ?? .Zero;

		switch (Placement)
		{
		case .Absolute:
			return Offset;

		case .RelativeToTarget:
			return Point2F(targetPos.X + Offset.X, targetPos.Y + Offset.Y);

		case .Bottom:
			return Point2F(targetPos.X + Offset.X, targetPos.Y + targetBounds.Height + Offset.Y);

		case .Top:
			return Point2F(targetPos.X + Offset.X, targetPos.Y - childSize.Height + Offset.Y);

		case .Left:
			return Point2F(targetPos.X - childSize.Width + Offset.X, targetPos.Y + Offset.Y);

		case .Right:
			return Point2F(targetPos.X + targetBounds.Width + Offset.X, targetPos.Y + Offset.Y);

		case .Center:
			return Point2F(
				targetPos.X + (targetBounds.Width - childSize.Width) / 2 + Offset.X,
				targetPos.Y + (targetBounds.Height - childSize.Height) / 2 + Offset.Y
			);
		}
	}

	protected override Size2F MeasureOverride(Size2F availableSize)
	{
		if (mChild != null)
		{
			mChild.Measure(availableSize);
			return mChild.DesiredSize;
		}
		return .Zero;
	}

	protected override Size2F ArrangeOverride(Size2F finalSize)
	{
		if (mChild != null)
		{
			mChild.Arrange(RectangleF(0, 0, finalSize.Width, finalSize.Height));
		}
		return finalSize;
	}
}
