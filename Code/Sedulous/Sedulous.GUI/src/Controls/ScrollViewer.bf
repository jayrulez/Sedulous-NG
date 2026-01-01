namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

class ScrollViewer : FrameworkElement
{
	private UIElement mContent;
	private float mHorizontalOffset;
	private float mVerticalOffset;
	private bool mIsDraggingVScroll;
	private bool mIsDraggingHScroll;
	private float mDragStartOffset;
	private float mDragStartMousePos;

	public UIElement Content
	{
		get => mContent;
		set
		{
			if (mContent != null)
				RemoveVisualChild(mContent);

			mContent = value;

			if (mContent != null)
				AddVisualChild(mContent);

			InvalidateMeasure();
		}
	}

	public float HorizontalOffset
	{
		get => mHorizontalOffset;
		private set => mHorizontalOffset = Math.Clamp(value, 0, Math.Max(0, ExtentWidth - ViewportWidth));
	}

	public float VerticalOffset
	{
		get => mVerticalOffset;
		private set => mVerticalOffset = Math.Clamp(value, 0, Math.Max(0, ExtentHeight - ViewportHeight));
	}

	public float ExtentWidth => mContent?.DesiredSize.Width ?? 0;
	public float ExtentHeight => mContent?.DesiredSize.Height ?? 0;
	public float ViewportWidth => ActualWidth - (ShowVerticalScrollBar ? ScrollBarWidth : 0);
	public float ViewportHeight => ActualHeight - (ShowHorizontalScrollBar ? ScrollBarWidth : 0);

	public ScrollBarVisibility HorizontalScrollBarVisibility = .Auto;
	public ScrollBarVisibility VerticalScrollBarVisibility = .Auto;

	// === Theme Properties ===
	public float ScrollBarWidth => ThemeManager.ScrollViewerTheme?.ScrollBarWidth ?? 12.0f;
	public float MinThumbSize => ThemeManager.ScrollViewerTheme?.MinThumbSize ?? 20.0f;

	private bool ShowHorizontalScrollBar =>
		HorizontalScrollBarVisibility == .Visible ||
		(HorizontalScrollBarVisibility == .Auto && ExtentWidth > ViewportWidth);

	private bool ShowVerticalScrollBar =>
		VerticalScrollBarVisibility == .Visible ||
		(VerticalScrollBarVisibility == .Auto && ExtentHeight > ViewportHeight);

	public this()
	{
		AddHandler(UIElement.MouseWheelEvent, new => OnMouseWheel);
		AddHandler(UIElement.MouseDownEvent, new => OnMouseDown);
		AddHandler(UIElement.MouseMoveEvent, new => OnMouseMove);
		AddHandler(UIElement.MouseUpEvent, new => OnMouseUp);
	}

	private void OnMouseWheel(UIElement sender, RoutedEventArgs e)
	{
		if (let wheelArgs = e as MouseWheelEventArgs)
		{
			ScrollBy(0, -wheelArgs.DeltaY * 40);
			wheelArgs.Handled = true;
		}
	}

	private void OnMouseDown(UIElement sender, RoutedEventArgs e)
	{
		if (let mouseArgs = e as MouseButtonEventArgs)
		{
			if (mouseArgs.Button == .Left)
			{
				let pos = mouseArgs.GetPosition(this);

				// Check if clicking on vertical scrollbar
				if (ShowVerticalScrollBar && pos.X >= ActualWidth - ScrollBarWidth)
				{
					let (thumbY, thumbHeight) = GetVerticalThumbRect();
					if (pos.Y >= thumbY && pos.Y <= thumbY + thumbHeight)
					{
						mIsDraggingVScroll = true;
						mDragStartOffset = mVerticalOffset;
						mDragStartMousePos = pos.Y;
						MouseCapture.Capture(this);
						mouseArgs.Handled = true;
					}
				}
				// Check horizontal scrollbar
				else if (ShowHorizontalScrollBar && pos.Y >= ActualHeight - ScrollBarWidth)
				{
					let (thumbX, thumbWidth) = GetHorizontalThumbRect();
					if (pos.X >= thumbX && pos.X <= thumbX + thumbWidth)
					{
						mIsDraggingHScroll = true;
						mDragStartOffset = mHorizontalOffset;
						mDragStartMousePos = pos.X;
						MouseCapture.Capture(this);
						mouseArgs.Handled = true;
					}
				}
			}
		}
	}

	private void OnMouseMove(UIElement sender, RoutedEventArgs e)
	{
		if (let mouseArgs = e as MouseEventArgs)
		{
			let pos = mouseArgs.GetPosition(this);

			if (mIsDraggingVScroll)
			{
				let trackHeight = ViewportHeight;
				let scrollRange = ExtentHeight - ViewportHeight;
				if (trackHeight > 0 && scrollRange > 0)
				{
					let delta = pos.Y - mDragStartMousePos;
					let ratio = delta / trackHeight;
					VerticalOffset = mDragStartOffset + ratio * scrollRange;
				}
			}
			else if (mIsDraggingHScroll)
			{
				let trackWidth = ViewportWidth;
				let scrollRange = ExtentWidth - ViewportWidth;
				if (trackWidth > 0 && scrollRange > 0)
				{
					let delta = pos.X - mDragStartMousePos;
					let ratio = delta / trackWidth;
					HorizontalOffset = mDragStartOffset + ratio * scrollRange;
				}
			}
		}
	}

	private void OnMouseUp(UIElement sender, RoutedEventArgs e)
	{
		if (mIsDraggingVScroll || mIsDraggingHScroll)
		{
			mIsDraggingVScroll = false;
			mIsDraggingHScroll = false;
			MouseCapture.Release();
		}
	}

	public void ScrollTo(float x, float y)
	{
		HorizontalOffset = x;
		VerticalOffset = y;
	}

	public void ScrollBy(float dx, float dy)
	{
		ScrollTo(mHorizontalOffset + dx, mVerticalOffset + dy);
	}

	public void ScrollToTop() => VerticalOffset = 0;
	public void ScrollToBottom() => VerticalOffset = ExtentHeight - ViewportHeight;

	protected override Size2F MeasureOverride(Size2F availableSize)
	{
		if (mContent != null)
			mContent.Measure(Size2F(float.PositiveInfinity, float.PositiveInfinity));

		return availableSize;
	}

	protected override Size2F ArrangeOverride(Size2F finalSize)
	{
		if (mContent != null)
		{
			let contentWidth = Math.Max(mContent.DesiredSize.Width, ViewportWidth);
			let contentHeight = Math.Max(mContent.DesiredSize.Height, ViewportHeight);

			mContent.Arrange(RectangleF(
				-mHorizontalOffset,
				-mVerticalOffset,
				contentWidth,
				contentHeight
			));
		}
		return finalSize;
	}

	private (float y, float height) GetVerticalThumbRect()
	{
		let trackHeight = ViewportHeight;
		if (ExtentHeight <= 0 || trackHeight <= 0)
			return (0, trackHeight);

		let ratio = trackHeight / ExtentHeight;
		let thumbHeight = Math.Max(MinThumbSize, trackHeight * ratio);
		let scrollRange = ExtentHeight - ViewportHeight;
		let thumbY = scrollRange > 0 ? (mVerticalOffset / scrollRange) * (trackHeight - thumbHeight) : 0;

		return (thumbY, thumbHeight);
	}

	private (float x, float width) GetHorizontalThumbRect()
	{
		let trackWidth = ViewportWidth;
		if (ExtentWidth <= 0 || trackWidth <= 0)
			return (0, trackWidth);

		let ratio = trackWidth / ExtentWidth;
		let thumbWidth = Math.Max(MinThumbSize, trackWidth * ratio);
		let scrollRange = ExtentWidth - ViewportWidth;
		let thumbX = scrollRange > 0 ? (mHorizontalOffset / scrollRange) * (trackWidth - thumbWidth) : 0;

		return (thumbX, thumbWidth);
	}

	protected override void OnRender(IUIRenderer renderer)
	{
		let theme = ThemeManager.ScrollViewerTheme;
		let scrollBarBg = theme?.ScrollBarBackground ?? Color(40, 40, 40, 255);
		let scrollBarThumb = theme?.ScrollBarThumb ?? Color(100, 100, 100, 255);

		// Clip content area
		renderer.PushClipRect(RectangleF(0, 0, ViewportWidth, ViewportHeight));

		// Content is rendered as a child (automatically handled)

		renderer.PopClipRect();

		// Draw vertical scrollbar
		if (ShowVerticalScrollBar)
		{
			let barX = ActualWidth - ScrollBarWidth;
			let barRect = RectangleF(barX, 0, ScrollBarWidth, ViewportHeight);
			renderer.FillRectangle(barRect, scrollBarBg);

			let (thumbY, thumbHeight) = GetVerticalThumbRect();
			let thumbRect = RectangleF(barX + 2, thumbY + 2, ScrollBarWidth - 4, thumbHeight - 4);
			renderer.FillRoundedRectangle(thumbRect, scrollBarThumb, 3);
		}

		// Draw horizontal scrollbar
		if (ShowHorizontalScrollBar)
		{
			let barY = ActualHeight - ScrollBarWidth;
			let barRect = RectangleF(0, barY, ViewportWidth, ScrollBarWidth);
			renderer.FillRectangle(barRect, scrollBarBg);

			let (thumbX, thumbWidth) = GetHorizontalThumbRect();
			let thumbRect = RectangleF(thumbX + 2, barY + 2, thumbWidth - 4, ScrollBarWidth - 4);
			renderer.FillRoundedRectangle(thumbRect, scrollBarThumb, 3);
		}
	}
}
