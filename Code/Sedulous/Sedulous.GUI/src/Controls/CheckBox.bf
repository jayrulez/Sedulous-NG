namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

delegate void CheckBoxCheckedChangedHandler(CheckBox sender, bool isChecked);

class CheckBox : FrameworkElement
{
	private UIElement mContent;
	private bool mIsChecked;

	public Event<CheckBoxCheckedChangedHandler> CheckedChanged ~ _.Dispose();

	public bool IsChecked
	{
		get => mIsChecked;
		set
		{
			if (mIsChecked != value)
			{
				mIsChecked = value;
				CheckedChanged.Invoke(this, mIsChecked);
			}
		}
	}

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

	// === Theme Properties ===
	public float BoxSize => ThemeManager.CheckBoxTheme?.BoxSize ?? 16.0f;
	public float Spacing => ThemeManager.CheckBoxTheme?.Spacing ?? 6.0f;

	public this()
	{
		Focusable = true;

		AddHandler(UIElement.MouseDownEvent, new => OnMouseDown);
		AddHandler(UIElement.KeyDownEvent, new => OnKeyDown);
	}

	private void OnMouseDown(UIElement sender, RoutedEventArgs e)
	{
		if (let mouseArgs = e as MouseButtonEventArgs)
		{
			if (mouseArgs.Button == .Left && IsEnabled)
			{
				IsChecked = !IsChecked;
				Focus();
			}
		}
	}

	private void OnKeyDown(UIElement sender, RoutedEventArgs e)
	{
		if (let keyArgs = e as KeyEventArgs)
		{
			if (keyArgs.Key == .Space && IsEnabled && !keyArgs.IsRepeat)
			{
				IsChecked = !IsChecked;
				keyArgs.Handled = true;
			}
		}
	}

	protected override Size2F MeasureOverride(Size2F availableSize)
	{
		let boxSize = BoxSize;
		let spacing = Spacing;

		var contentSize = Size2F.Zero;
		if (mContent != null)
		{
			mContent.Measure(Size2F(availableSize.Width - boxSize - spacing, availableSize.Height));
			contentSize = mContent.DesiredSize;
		}

		return Size2F(boxSize + spacing + contentSize.Width, Math.Max(boxSize, contentSize.Height));
	}

	protected override Size2F ArrangeOverride(Size2F finalSize)
	{
		if (mContent != null)
		{
			let boxSize = BoxSize;
			let spacing = Spacing;

			let contentRect = RectangleF(
				boxSize + spacing,
				0,
				finalSize.Width - boxSize - spacing,
				finalSize.Height
			);
			mContent.Arrange(contentRect);
		}
		return finalSize;
	}

	protected override void OnRender(IUIRenderer renderer)
	{
		let theme = ThemeManager.CheckBoxTheme;
		let boxSize = BoxSize;

		let boxRect = RectangleF(0, (ActualHeight - boxSize) / 2, boxSize, boxSize);

		// Get colors based on state
		let bg = theme?.GetBackground(IsEnabled, IsMouseOver, false, IsFocused, mIsChecked)
			?? (mIsChecked ? Color(0, 120, 212, 255) : Color(40, 40, 40, 255));
		let border = theme?.GetBorderColor(IsEnabled, IsMouseOver, false, IsFocused, mIsChecked)
			?? Color(100, 100, 100, 255);
		let checkColor = theme?.CheckColor ?? Color(255, 255, 255, 255);
		let cornerRadius = theme?.CornerRadius ?? 3.0f;

		// Draw box background
		if (cornerRadius > 0)
			renderer.FillRoundedRectangle(boxRect, bg, cornerRadius);
		else
			renderer.FillRectangle(boxRect, bg);

		// Draw border
		if (cornerRadius > 0)
			renderer.DrawRoundedRectangle(boxRect, border, cornerRadius, 1);
		else
			renderer.DrawRectangle(boxRect, border, 1);

		// Draw checkmark
		if (mIsChecked)
		{
			let checkRect = RectangleF(boxRect.X + 4, boxRect.Y + 4, boxSize - 8, boxSize - 8);
			renderer.FillRectangle(checkRect, checkColor);
		}

		// Focus ring
		if (IsFocused)
		{
			let focusColor = ThemeManager.Resources?.FocusRing ?? Color(0, 120, 212, 255);
			let focusRect = RectangleF(boxRect.X - 2, boxRect.Y - 2, boxSize + 4, boxSize + 4);
			if (cornerRadius > 0)
				renderer.DrawRoundedRectangle(focusRect, focusColor, cornerRadius + 2, 2);
			else
				renderer.DrawRectangle(focusRect, focusColor, 2);
		}
	}
}
