namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

delegate void SliderValueChangedHandler(Slider sender, float value);

class Slider : FrameworkElement
{
	private float mValue = 0;
	private bool mIsDragging;

	public Event<SliderValueChangedHandler> ValueChanged ~ _.Dispose();

	public float Value
	{
		get => mValue;
		set
		{
			let clamped = Math.Clamp(value, Minimum, Maximum);
			if (mValue != clamped)
			{
				mValue = clamped;
				ValueChanged.Invoke(this, mValue);
			}
		}
	}

	public float Minimum = 0;
	public float Maximum = 100;
	public float Step = 1;
	public Orientation Orientation = .Horizontal;

	// === Theme Properties ===
	public float TrackThickness => ThemeManager.SliderTheme?.TrackThickness ?? 4.0f;
	public float ThumbSize => ThemeManager.SliderTheme?.ThumbSize ?? 16.0f;

	public this()
	{
		Focusable = true;

		AddHandler(UIElement.MouseDownEvent, new => OnMouseDown);
		AddHandler(UIElement.MouseMoveEvent, new => OnMouseMove);
		AddHandler(UIElement.MouseUpEvent, new => OnMouseUp);
		AddHandler(UIElement.KeyDownEvent, new => OnKeyDown);
	}

	private void OnMouseDown(UIElement sender, RoutedEventArgs e)
	{
		if (let mouseArgs = e as MouseButtonEventArgs)
		{
			if (mouseArgs.Button == .Left && IsEnabled)
			{
				mIsDragging = true;
				MouseCapture.Capture(this);
				Focus();
				UpdateValueFromPosition(mouseArgs.GetPosition(this));
			}
		}
	}

	private void OnMouseMove(UIElement sender, RoutedEventArgs e)
	{
		if (mIsDragging)
		{
			if (let mouseArgs = e as MouseEventArgs)
			{
				UpdateValueFromPosition(mouseArgs.GetPosition(this));
			}
		}
	}

	private void OnMouseUp(UIElement sender, RoutedEventArgs e)
	{
		if (mIsDragging)
		{
			mIsDragging = false;
			MouseCapture.Release();
		}
	}

	private void OnKeyDown(UIElement sender, RoutedEventArgs e)
	{
		if (let keyArgs = e as KeyEventArgs)
		{
			if (!IsEnabled)
				return;

			float delta = 0;
			if (Orientation == .Horizontal)
			{
				if (keyArgs.Key == .Left)
					delta = -Step;
				else if (keyArgs.Key == .Right)
					delta = Step;
			}
			else
			{
				if (keyArgs.Key == .Up)
					delta = Step;
				else if (keyArgs.Key == .Down)
					delta = -Step;
			}

			if (delta != 0)
			{
				Value = mValue + delta;
				keyArgs.Handled = true;
			}
		}
	}

	private void UpdateValueFromPosition(Point2F pos)
	{
		let thumbSize = ThumbSize;
		float ratio;

		if (Orientation == .Horizontal)
			ratio = Math.Clamp((pos.X - thumbSize / 2) / (ActualWidth - thumbSize), 0, 1);
		else
			ratio = 1 - Math.Clamp((pos.Y - thumbSize / 2) / (ActualHeight - thumbSize), 0, 1);

		Value = Minimum + ratio * (Maximum - Minimum);
	}

	protected override Size2F MeasureOverride(Size2F availableSize)
	{
		let thumbSize = ThumbSize;

		if (Orientation == .Horizontal)
			return Size2F(availableSize.Width, thumbSize);
		else
			return Size2F(thumbSize, availableSize.Height);
	}

	protected override void OnRender(IUIRenderer renderer)
	{
		let theme = ThemeManager.SliderTheme;
		let trackThickness = TrackThickness;
		let thumbSize = ThumbSize;

		let ratio = (Maximum > Minimum) ? (mValue - Minimum) / (Maximum - Minimum) : 0;

		let trackColor = theme?.TrackColor ?? Color(60, 60, 60, 255);
		let fillColor = theme?.FillColor ?? Color(0, 120, 212, 255);
		let thumbColor = (IsMouseOver || mIsDragging)
			? (theme?.ThumbHoverColor ?? Color(230, 230, 230, 255))
			: (theme?.ThumbColor ?? Color(200, 200, 200, 255));

		if (Orientation == .Horizontal)
		{
			let trackY = (ActualHeight - trackThickness) / 2;
			let thumbX = (ActualWidth - thumbSize) * ratio;

			// Track background
			renderer.FillRoundedRectangle(
				RectangleF(0, trackY, ActualWidth, trackThickness),
				trackColor, trackThickness / 2
			);

			// Filled portion
			if (ratio > 0)
			{
				renderer.FillRoundedRectangle(
					RectangleF(0, trackY, thumbX + thumbSize / 2, trackThickness),
					fillColor, trackThickness / 2
				);
			}

			// Thumb
			renderer.FillRoundedRectangle(
				RectangleF(thumbX, 0, thumbSize, thumbSize),
				thumbColor, thumbSize / 2
			);

			// Focus ring on thumb
			if (IsFocused)
			{
				let focusColor = ThemeManager.Resources?.FocusRing ?? Color(0, 120, 212, 255);
				renderer.DrawRoundedRectangle(
					RectangleF(thumbX - 2, -2, thumbSize + 4, thumbSize + 4),
					focusColor, thumbSize / 2 + 2, 2
				);
			}
		}
		else
		{
			let trackX = (ActualWidth - trackThickness) / 2;
			let thumbY = (ActualHeight - thumbSize) * (1 - ratio);

			// Track background
			renderer.FillRoundedRectangle(
				RectangleF(trackX, 0, trackThickness, ActualHeight),
				trackColor, trackThickness / 2
			);

			// Filled portion
			if (ratio > 0)
			{
				renderer.FillRoundedRectangle(
					RectangleF(trackX, thumbY + thumbSize / 2, trackThickness, ActualHeight - thumbY - thumbSize / 2),
					fillColor, trackThickness / 2
				);
			}

			// Thumb
			renderer.FillRoundedRectangle(
				RectangleF(0, thumbY, thumbSize, thumbSize),
				thumbColor, thumbSize / 2
			);

			// Focus ring
			if (IsFocused)
			{
				let focusColor = ThemeManager.Resources?.FocusRing ?? Color(0, 120, 212, 255);
				renderer.DrawRoundedRectangle(
					RectangleF(-2, thumbY - 2, thumbSize + 4, thumbSize + 4),
					focusColor, thumbSize / 2 + 2, 2
				);
			}
		}
	}
}
