namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

delegate void ThemeChangedHandler();

static class ThemeManager
{
	private static Theme sCurrentTheme;
	private static Event<ThemeChangedHandler> sThemeChanged = .() ~ _.Dispose();

	public static Theme CurrentTheme
	{
		get => sCurrentTheme;
		set
		{
			if (sCurrentTheme != value)
			{
				sCurrentTheme = value;
				OnThemeChanged();
			}
		}
	}

	public static ref Event<ThemeChangedHandler> ThemeChanged => ref sThemeChanged;

	private static void OnThemeChanged()
	{
		sThemeChanged.Invoke();
	}

	// === Convenience Accessors ===

	public static ThemeResources Resources => sCurrentTheme?.Resources;

	public static ButtonTheme ButtonTheme => sCurrentTheme?.ButtonTheme;
	public static TextBoxTheme TextBoxTheme => sCurrentTheme?.TextBoxTheme;
	public static CheckBoxTheme CheckBoxTheme => sCurrentTheme?.CheckBoxTheme;
	public static SliderTheme SliderTheme => sCurrentTheme?.SliderTheme;
	public static ScrollViewerTheme ScrollViewerTheme => sCurrentTheme?.ScrollViewerTheme;
	public static DialogTheme DialogTheme => sCurrentTheme?.DialogTheme;
	public static ControlTheme BorderTheme => sCurrentTheme?.BorderTheme;
	public static ControlTheme TextBlockTheme => sCurrentTheme?.TextBlockTheme;
	public static ControlTheme PanelTheme => sCurrentTheme?.PanelTheme;

	// === Resource Helpers ===

	public static Color GetPrimaryColor()
	{
		return sCurrentTheme?.Resources?.PrimaryColor ?? Color(0, 120, 212, 255);
	}

	public static Color GetBackgroundColor()
	{
		return sCurrentTheme?.Resources?.BackgroundColor ?? Color(30, 30, 30, 255);
	}

	public static Color GetTextColor()
	{
		return sCurrentTheme?.Resources?.TextPrimary ?? Color(255, 255, 255, 255);
	}

	public static Color GetTextSecondaryColor()
	{
		return sCurrentTheme?.Resources?.TextSecondary ?? Color(180, 180, 180, 255);
	}

	public static Color GetTextDisabledColor()
	{
		return sCurrentTheme?.Resources?.TextDisabled ?? Color(100, 100, 100, 255);
	}

	public static IFont GetDefaultFont()
	{
		return sCurrentTheme?.Resources?.DefaultFont;
	}

	public static float GetCornerRadius()
	{
		return sCurrentTheme?.Resources?.CornerRadius ?? 4.0f;
	}

	public static float GetBorderWidth()
	{
		return sCurrentTheme?.Resources?.BorderWidth ?? 1.0f;
	}

	// === Initialize Default Theme ===

	public static void Initialize()
	{
		if (sCurrentTheme == null)
		{
			sCurrentTheme = Theme.CreateDark();
		}
	}

	public static void Shutdown()
	{
		delete sCurrentTheme;
		sCurrentTheme = null;
	}
}
