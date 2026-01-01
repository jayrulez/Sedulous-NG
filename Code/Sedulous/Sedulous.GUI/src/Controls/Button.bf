namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

delegate void ButtonClickHandler(Button sender);

class Button : Border
{
	private bool mIsPressed;

	public Event<ButtonClickHandler> Click ~ _.Dispose();

	// === State ===
	public bool IsPressed => mIsPressed;

	// === Constructor ===
	public this()
	{
		Focusable = true;

		// Set default padding
		PaddingOverride = .(8, 4, 8, 4);
		CornerRadiusOverride = ThemeManager.GetCornerRadius();
		BorderThicknessOverride = .(1);

		// Register event handlers
		AddHandler(UIElement.PreviewMouseDownEvent, new => OnPreviewMouseDown);
		AddHandler(UIElement.PreviewMouseUpEvent, new => OnPreviewMouseUp);
		AddHandler(UIElement.MouseLeaveEvent, new => OnMouseLeaveHandler);
		AddHandler(UIElement.KeyDownEvent, new => OnKeyDown);
	}

	// === Themed Appearance ===
	public new Color Background
	{
		get
		{
			if (BackgroundOverride.HasValue)
				return BackgroundOverride.Value;

			let theme = ThemeManager.ButtonTheme;
			if (theme == null)
				return Color(60, 60, 60, 255);

			return theme.GetBackground(IsEnabled, IsMouseOver, mIsPressed, IsFocused);
		}
	}

	public new Color BorderBrush
	{
		get
		{
			if (BorderBrushOverride.HasValue)
				return BorderBrushOverride.Value;

			let theme = ThemeManager.ButtonTheme;
			if (theme == null)
				return Color(100, 100, 100, 255);

			return theme.GetBorderColor(IsEnabled, IsMouseOver, mIsPressed, IsFocused);
		}
	}

	public Color Foreground
	{
		get
		{
			let theme = ThemeManager.ButtonTheme;
			if (theme == null)
				return IsEnabled ? Color(255, 255, 255, 255) : Color(100, 100, 100, 255);

			return theme.GetForeground(IsEnabled, IsMouseOver, mIsPressed, IsFocused);
		}
	}

	// === Event Handlers ===
	private void OnPreviewMouseDown(UIElement sender, RoutedEventArgs e)
	{
		if (let mouseArgs = e as MouseButtonEventArgs)
		{
			if (mouseArgs.Button == .Left && IsEnabled)
			{
				mIsPressed = true;
				MouseCapture.Capture(this);
			}
		}
	}

	private void OnPreviewMouseUp(UIElement sender, RoutedEventArgs e)
	{
		if (let mouseArgs = e as MouseButtonEventArgs)
		{
			if (mouseArgs.Button == .Left && mIsPressed)
			{
				MouseCapture.Release();
				mIsPressed = false;

				// Click only if still over the button
				if (IsMouseOver && IsEnabled)
				{
					OnClick();
				}
			}
		}
	}

	private void OnMouseLeaveHandler(UIElement sender, RoutedEventArgs e)
	{
		if (mIsPressed && !MouseCapture.IsCaptured)
		{
			mIsPressed = false;
		}
	}

	private void OnKeyDown(UIElement sender, RoutedEventArgs e)
	{
		if (let keyArgs = e as KeyEventArgs)
		{
			if ((keyArgs.Key == .Space || keyArgs.Key == .Return) && IsEnabled && !keyArgs.IsRepeat)
			{
				OnClick();
				keyArgs.Handled = true;
			}
		}
	}

	protected virtual void OnClick()
	{
		Click.Invoke(this);
	}

	// === Rendering ===
	protected override void OnRender(IUIRenderer renderer)
	{
		let rect = RectangleF(0, 0, ActualWidth, ActualHeight);
		let bg = Background;
		let border = BorderBrush;
		let borderT = BorderThickness;
		let radius = CornerRadius;

		// Draw background
		if (bg.A > 0)
		{
			if (radius > 0)
				renderer.FillRoundedRectangle(rect, bg, radius);
			else
				renderer.FillRectangle(rect, bg);
		}

		// Draw border
		if (border.A > 0 && (borderT.Left > 0 || borderT.Top > 0 || borderT.Right > 0 || borderT.Bottom > 0))
		{
			let avgThickness = (borderT.Left + borderT.Top + borderT.Right + borderT.Bottom) / 4;
			if (radius > 0)
				renderer.DrawRoundedRectangle(rect, border, radius, avgThickness);
			else
				renderer.DrawRectangle(rect, border, avgThickness);
		}

		// Draw focus ring
		if (IsFocused)
		{
			let focusColor = ThemeManager.Resources?.FocusRing ?? Color(0, 120, 212, 255);
			let focusWidth = ThemeManager.Resources?.FocusRingWidth ?? 2.0f;
			let focusRect = RectangleF(-focusWidth, -focusWidth, ActualWidth + focusWidth * 2, ActualHeight + focusWidth * 2);

			if (radius > 0)
				renderer.DrawRoundedRectangle(focusRect, focusColor, radius + focusWidth, focusWidth);
			else
				renderer.DrawRectangle(focusRect, focusColor, focusWidth);
		}
	}
}
