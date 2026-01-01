namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

abstract class FrameworkElement : UIElement
{
	// === Layout Properties ===
	public Thickness Margin;
	public HorizontalAlignment HorizontalAlignment = .Stretch;
	public VerticalAlignment VerticalAlignment = .Stretch;

	private float mWidth = float.NaN;
	private float mHeight = float.NaN;
	private float mMinWidth = 0;
	private float mMinHeight = 0;
	private float mMaxWidth = float.PositiveInfinity;
	private float mMaxHeight = float.PositiveInfinity;

	public float Width
	{
		get => mWidth;
		set
		{
			if (mWidth != value)
			{
				mWidth = value;
				InvalidateMeasure();
			}
		}
	}

	public float Height
	{
		get => mHeight;
		set
		{
			if (mHeight != value)
			{
				mHeight = value;
				InvalidateMeasure();
			}
		}
	}

	public float MinWidth
	{
		get => mMinWidth;
		set
		{
			if (mMinWidth != value)
			{
				mMinWidth = Math.Max(0, value);
				InvalidateMeasure();
			}
		}
	}

	public float MinHeight
	{
		get => mMinHeight;
		set
		{
			if (mMinHeight != value)
			{
				mMinHeight = Math.Max(0, value);
				InvalidateMeasure();
			}
		}
	}

	public float MaxWidth
	{
		get => mMaxWidth;
		set
		{
			if (mMaxWidth != value)
			{
				mMaxWidth = Math.Max(0, value);
				InvalidateMeasure();
			}
		}
	}

	public float MaxHeight
	{
		get => mMaxHeight;
		set
		{
			if (mMaxHeight != value)
			{
				mMaxHeight = Math.Max(0, value);
				InvalidateMeasure();
			}
		}
	}

	// === Data Context (for simple property passing) ===
	public Object DataContext;

	// === Tag (for user data) ===
	public Object Tag;

	// === Constructor ===
	public this() : base()
	{
	}

	// === Layout Implementation ===
	protected override Size2F MeasureCore(Size2F availableSize)
	{
		// Apply margin
		let marginSize = Margin.Size;
		var constrainedSize = Size2F(
			Math.Max(0, availableSize.Width - marginSize.Width),
			Math.Max(0, availableSize.Height - marginSize.Height)
		);

		// Apply explicit size constraints
		if (!mWidth.IsNaN)
			constrainedSize.Width = Math.Min(constrainedSize.Width, mWidth);
		if (!mHeight.IsNaN)
			constrainedSize.Height = Math.Min(constrainedSize.Height, mHeight);

		// Apply min/max constraints
		constrainedSize.Width = Math.Clamp(constrainedSize.Width, mMinWidth, mMaxWidth);
		constrainedSize.Height = Math.Clamp(constrainedSize.Height, mMinHeight, mMaxHeight);

		// Measure content
		var desiredSize = MeasureOverride(constrainedSize);

		// Apply explicit sizes
		if (!mWidth.IsNaN)
			desiredSize.Width = mWidth;
		if (!mHeight.IsNaN)
			desiredSize.Height = mHeight;

		// Apply min/max to desired size
		desiredSize.Width = Math.Clamp(desiredSize.Width, mMinWidth, mMaxWidth);
		desiredSize.Height = Math.Clamp(desiredSize.Height, mMinHeight, mMaxHeight);

		// Add margin back
		desiredSize.Width += marginSize.Width;
		desiredSize.Height += marginSize.Height;

		return desiredSize;
	}

	protected virtual Size2F MeasureOverride(Size2F availableSize)
	{
		return .Zero;
	}

	protected override RectangleF ArrangeCore(RectangleF finalRect)
	{
		// Apply margin
		let arrangeRect = RectangleF(
			finalRect.X + Margin.Left,
			finalRect.Y + Margin.Top,
			Math.Max(0, finalRect.Width - Margin.Left - Margin.Right),
			Math.Max(0, finalRect.Height - Margin.Top - Margin.Bottom)
		);

		// Calculate actual size based on alignment
		let contentDesiredWidth = mDesiredSize.Width - Margin.Size.Width;
		let contentDesiredHeight = mDesiredSize.Height - Margin.Size.Height;

		var actualWidth = HorizontalAlignment == .Stretch
			? arrangeRect.Width
			: Math.Min(contentDesiredWidth, arrangeRect.Width);

		var actualHeight = VerticalAlignment == .Stretch
			? arrangeRect.Height
			: Math.Min(contentDesiredHeight, arrangeRect.Height);

		// Apply explicit sizes
		if (!mWidth.IsNaN)
			actualWidth = Math.Min(mWidth, arrangeRect.Width);
		if (!mHeight.IsNaN)
			actualHeight = Math.Min(mHeight, arrangeRect.Height);

		// Apply min/max constraints
		actualWidth = Math.Clamp(actualWidth, mMinWidth, Math.Min(mMaxWidth, arrangeRect.Width));
		actualHeight = Math.Clamp(actualHeight, mMinHeight, Math.Min(mMaxHeight, arrangeRect.Height));

		// Calculate position based on alignment
		var x = arrangeRect.X;
		var y = arrangeRect.Y;

		switch (HorizontalAlignment)
		{
		case .Center:
			x += (arrangeRect.Width - actualWidth) / 2;
		case .Right:
			x += arrangeRect.Width - actualWidth;
		default:
		}

		switch (VerticalAlignment)
		{
		case .Center:
			y += (arrangeRect.Height - actualHeight) / 2;
		case .Bottom:
			y += arrangeRect.Height - actualHeight;
		default:
		}

		// Call ArrangeOverride
		let arrangedSize = ArrangeOverride(Size2F(actualWidth, actualHeight));

		return RectangleF(x, y, arrangedSize.Width, arrangedSize.Height);
	}

	protected virtual Size2F ArrangeOverride(Size2F finalSize)
	{
		return finalSize;
	}
}
