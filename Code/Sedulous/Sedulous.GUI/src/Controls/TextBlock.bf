namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

class TextBlock : FrameworkElement
{
	private String mText = new .() ~ delete _;
	private IFont mFont;

	// === Appearance (Overrides) ===
	public Color? ForegroundOverride;

	// === Properties ===
	public StringView Text
	{
		get => mText;
		set
		{
			mText.Set(value);
			InvalidateMeasure();
		}
	}

	public IFont Font
	{
		get => mFont != null ? mFont : ThemeManager.GetDefaultFont();
		set
		{
			mFont = value;
			InvalidateMeasure();
		}
	}

	public Color Foreground
	{
		get
		{
			if (ForegroundOverride.HasValue)
				return ForegroundOverride.Value;
			if (!IsEnabled)
				return ThemeManager.GetTextDisabledColor();
			return ThemeManager.TextBlockTheme?.Foreground ?? ThemeManager.GetTextColor();
		}
	}

	public TextAlignment TextAlignment = .Left;
	public TextWrapping TextWrapping = .NoWrap;
	public float LineHeight = 0; // 0 = use font's line height

	// === Layout ===
	protected override Size2F MeasureOverride(Size2F availableSize)
	{
		if (mText == null || mText.IsEmpty)
			return .Zero;

		let font = Font;
		if (font == null)
			return .Zero;

		if (TextWrapping != .NoWrap)
		{
			return font.MeasureString(mText, availableSize.Width, TextWrapping);
		}
		else
		{
			return font.MeasureString(mText);
		}
	}

	// === Rendering ===
	protected override void OnRender(IUIRenderer renderer)
	{
		if (mText == null || mText.IsEmpty)
			return;

		let font = Font;
		if (font == null)
			return;

		let bounds = RectangleF(0, 0, ActualWidth, ActualHeight);
		renderer.DrawText(mText, font, bounds, Foreground, TextAlignment, TextWrapping);
	}
}
