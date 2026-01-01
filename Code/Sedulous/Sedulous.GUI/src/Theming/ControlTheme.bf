namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

struct ControlStateStyle
{
	public Color? Background;
	public Color? Foreground;
	public Color? BorderColor;

	public this()
	{
		Background = null;
		Foreground = null;
		BorderColor = null;
	}

	public this(Color? background, Color? foreground = null, Color? borderColor = null)
	{
		Background = background;
		Foreground = foreground;
		BorderColor = borderColor;
	}
}

class ControlTheme
{
	// === Base Style ===
	public Color Background;
	public Color Foreground;
	public Color BorderColor;
	public Thickness BorderThickness;
	public Thickness Padding;
	public Thickness Margin;
	public float CornerRadius;
	public IFont Font;

	// === Visual States ===
	public ControlStateStyle Normal;
	public ControlStateStyle Hover;
	public ControlStateStyle Pressed;
	public ControlStateStyle Disabled;
	public ControlStateStyle Focused;
	public ControlStateStyle Checked;        // For toggle controls
	public ControlStateStyle CheckedHover;   // For toggle controls

	public this()
	{
		Background = Color(60, 60, 60, 255);
		Foreground = Color(255, 255, 255, 255);
		BorderColor = Color(100, 100, 100, 255);
		BorderThickness = .(1);
		Padding = .(8, 4, 8, 4);
		Margin = .Zero;
		CornerRadius = 4.0f;
	}

	public Color GetBackground(bool isEnabled, bool isHovered, bool isPressed, bool isFocused, bool isChecked = false)
	{
		if (!isEnabled)
			return Disabled.Background ?? Background;

		if (isChecked)
		{
			if (isHovered)
				return CheckedHover.Background ?? Checked.Background ?? Hover.Background ?? Background;
			return Checked.Background ?? Background;
		}

		if (isPressed)
			return Pressed.Background ?? Background;

		if (isHovered)
			return Hover.Background ?? Background;

		if (isFocused)
			return Focused.Background ?? Background;

		return Normal.Background ?? Background;
	}

	public Color GetForeground(bool isEnabled, bool isHovered, bool isPressed, bool isFocused, bool isChecked = false)
	{
		if (!isEnabled)
			return Disabled.Foreground ?? Foreground;

		if (isChecked)
		{
			if (isHovered)
				return CheckedHover.Foreground ?? Checked.Foreground ?? Foreground;
			return Checked.Foreground ?? Foreground;
		}

		if (isPressed)
			return Pressed.Foreground ?? Foreground;

		if (isHovered)
			return Hover.Foreground ?? Foreground;

		if (isFocused)
			return Focused.Foreground ?? Foreground;

		return Normal.Foreground ?? Foreground;
	}

	public Color GetBorderColor(bool isEnabled, bool isHovered, bool isPressed, bool isFocused, bool isChecked = false)
	{
		if (!isEnabled)
			return Disabled.BorderColor ?? BorderColor;

		if (isFocused)
			return Focused.BorderColor ?? BorderColor;

		if (isChecked)
			return Checked.BorderColor ?? BorderColor;

		if (isPressed)
			return Pressed.BorderColor ?? BorderColor;

		if (isHovered)
			return Hover.BorderColor ?? BorderColor;

		return Normal.BorderColor ?? BorderColor;
	}
}

// === Specialized Control Themes ===

class ButtonTheme : ControlTheme
{
	public this() : base()
	{
	}
}

class TextBoxTheme : ControlTheme
{
	public Color CaretColor = Color(255, 255, 255, 255);
	public Color SelectionColor = Color(0, 120, 212, 128);
	public Color PlaceholderColor = Color(128, 128, 128, 255);

	public this() : base()
	{
		Padding = .(6, 4, 6, 4);
	}
}

class CheckBoxTheme : ControlTheme
{
	public float BoxSize = 16.0f;
	public float Spacing = 6.0f;
	public Color CheckColor = Color(255, 255, 255, 255);

	public this() : base()
	{
		Padding = .Zero;
	}
}

class SliderTheme : ControlTheme
{
	public float TrackThickness = 4.0f;
	public float ThumbSize = 16.0f;
	public Color TrackColor = Color(60, 60, 60, 255);
	public Color FillColor = Color(0, 120, 212, 255);
	public Color ThumbColor = Color(200, 200, 200, 255);
	public Color ThumbHoverColor = Color(230, 230, 230, 255);

	public this() : base()
	{
	}
}

class ScrollViewerTheme : ControlTheme
{
	public float ScrollBarWidth = 12.0f;
	public float MinThumbSize = 20.0f;
	public Color ScrollBarBackground = Color(40, 40, 40, 255);
	public Color ScrollBarThumb = Color(100, 100, 100, 255);
	public Color ScrollBarThumbHover = Color(120, 120, 120, 255);
	public Color ScrollBarThumbPressed = Color(90, 90, 90, 255);

	public this() : base()
	{
	}
}

class DialogTheme : ControlTheme
{
	public Color OverlayColor = Color(0, 0, 0, 128);
	public Color TitleColor = Color(255, 255, 255, 255);
	public float TitleFontScale = 1.2f;

	public this() : base()
	{
		CornerRadius = 8.0f;
		Padding = .(16);
	}
}
