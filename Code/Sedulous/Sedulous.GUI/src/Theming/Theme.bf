namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

class Theme
{
	public String Name ~ delete _;
	public ThemeResources Resources ~ delete _;

	// === Control Themes ===
	public ButtonTheme ButtonTheme ~ delete _;
	public TextBoxTheme TextBoxTheme ~ delete _;
	public CheckBoxTheme CheckBoxTheme ~ delete _;
	public SliderTheme SliderTheme ~ delete _;
	public ScrollViewerTheme ScrollViewerTheme ~ delete _;
	public DialogTheme DialogTheme ~ delete _;
	public ControlTheme BorderTheme ~ delete _;
	public ControlTheme TextBlockTheme ~ delete _;
	public ControlTheme PanelTheme ~ delete _;

	public this(StringView name)
	{
		Name = new .(name);
		Resources = new .();
		ButtonTheme = new .();
		TextBoxTheme = new .();
		CheckBoxTheme = new .();
		SliderTheme = new .();
		ScrollViewerTheme = new .();
		DialogTheme = new .();
		BorderTheme = new .();
		TextBlockTheme = new .();
		PanelTheme = new .();
	}

	// === Factory Methods ===
	public static Theme CreateDark()
	{
		let theme = new Theme("Dark");

		// Resources
		theme.Resources.PrimaryColor = Color(0, 120, 212, 255);
		theme.Resources.BackgroundColor = Color(30, 30, 30, 255);
		theme.Resources.SurfaceColor = Color(45, 45, 45, 255);
		theme.Resources.TextPrimary = Color(255, 255, 255, 255);
		theme.Resources.TextSecondary = Color(180, 180, 180, 255);
		theme.Resources.TextDisabled = Color(100, 100, 100, 255);
		theme.Resources.ControlBackground = Color(60, 60, 60, 255);
		theme.Resources.ControlBorder = Color(100, 100, 100, 255);

		// Button
		theme.ButtonTheme.Background = Color(60, 60, 60, 255);
		theme.ButtonTheme.Foreground = Color(255, 255, 255, 255);
		theme.ButtonTheme.BorderColor = Color(100, 100, 100, 255);
		theme.ButtonTheme.Hover = .(Color(80, 80, 80, 255));
		theme.ButtonTheme.Pressed = .(Color(50, 50, 50, 255));
		theme.ButtonTheme.Disabled = .(Color(45, 45, 45, 255), Color(100, 100, 100, 255));
		theme.ButtonTheme.Focused = .(null, null, Color(0, 120, 212, 255));

		// TextBox
		theme.TextBoxTheme.Background = Color(40, 40, 40, 255);
		theme.TextBoxTheme.Foreground = Color(255, 255, 255, 255);
		theme.TextBoxTheme.BorderColor = Color(100, 100, 100, 255);
		theme.TextBoxTheme.CaretColor = Color(255, 255, 255, 255);
		theme.TextBoxTheme.SelectionColor = Color(0, 120, 212, 128);
		theme.TextBoxTheme.PlaceholderColor = Color(128, 128, 128, 255);
		theme.TextBoxTheme.Focused = .(null, null, Color(0, 120, 212, 255));

		// CheckBox
		theme.CheckBoxTheme.Background = Color(40, 40, 40, 255);
		theme.CheckBoxTheme.Foreground = Color(255, 255, 255, 255);
		theme.CheckBoxTheme.BorderColor = Color(100, 100, 100, 255);
		theme.CheckBoxTheme.CheckColor = Color(255, 255, 255, 255);
		theme.CheckBoxTheme.Checked = .(Color(0, 120, 212, 255), null, Color(0, 120, 212, 255));
		theme.CheckBoxTheme.CheckedHover = .(Color(30, 140, 230, 255));
		theme.CheckBoxTheme.Hover = .(Color(60, 60, 60, 255));

		// Slider
		theme.SliderTheme.TrackColor = Color(60, 60, 60, 255);
		theme.SliderTheme.FillColor = Color(0, 120, 212, 255);
		theme.SliderTheme.ThumbColor = Color(200, 200, 200, 255);
		theme.SliderTheme.ThumbHoverColor = Color(230, 230, 230, 255);

		// ScrollViewer
		theme.ScrollViewerTheme.ScrollBarBackground = Color(40, 40, 40, 255);
		theme.ScrollViewerTheme.ScrollBarThumb = Color(100, 100, 100, 255);
		theme.ScrollViewerTheme.ScrollBarThumbHover = Color(120, 120, 120, 255);

		// Dialog
		theme.DialogTheme.Background = Color(50, 50, 50, 255);
		theme.DialogTheme.BorderColor = Color(80, 80, 80, 255);
		theme.DialogTheme.OverlayColor = Color(0, 0, 0, 128);
		theme.DialogTheme.TitleColor = Color(255, 255, 255, 255);

		// TextBlock (no background by default)
		theme.TextBlockTheme.Background = Color(0, 0, 0, 0);
		theme.TextBlockTheme.Foreground = Color(255, 255, 255, 255);

		// Panel
		theme.PanelTheme.Background = Color(0, 0, 0, 0);

		return theme;
	}

	public static Theme CreateLight()
	{
		let theme = new Theme("Light");

		// Resources
		theme.Resources.PrimaryColor = Color(0, 120, 212, 255);
		theme.Resources.BackgroundColor = Color(243, 243, 243, 255);
		theme.Resources.SurfaceColor = Color(255, 255, 255, 255);
		theme.Resources.TextPrimary = Color(0, 0, 0, 255);
		theme.Resources.TextSecondary = Color(80, 80, 80, 255);
		theme.Resources.TextDisabled = Color(160, 160, 160, 255);
		theme.Resources.ControlBackground = Color(255, 255, 255, 255);
		theme.Resources.ControlBorder = Color(200, 200, 200, 255);

		// Button
		theme.ButtonTheme.Background = Color(255, 255, 255, 255);
		theme.ButtonTheme.Foreground = Color(0, 0, 0, 255);
		theme.ButtonTheme.BorderColor = Color(200, 200, 200, 255);
		theme.ButtonTheme.Hover = .(Color(240, 240, 240, 255));
		theme.ButtonTheme.Pressed = .(Color(220, 220, 220, 255));
		theme.ButtonTheme.Disabled = .(Color(245, 245, 245, 255), Color(160, 160, 160, 255));
		theme.ButtonTheme.Focused = .(null, null, Color(0, 120, 212, 255));

		// TextBox
		theme.TextBoxTheme.Background = Color(255, 255, 255, 255);
		theme.TextBoxTheme.Foreground = Color(0, 0, 0, 255);
		theme.TextBoxTheme.BorderColor = Color(200, 200, 200, 255);
		theme.TextBoxTheme.CaretColor = Color(0, 0, 0, 255);
		theme.TextBoxTheme.SelectionColor = Color(0, 120, 212, 128);
		theme.TextBoxTheme.PlaceholderColor = Color(160, 160, 160, 255);
		theme.TextBoxTheme.Focused = .(null, null, Color(0, 120, 212, 255));

		// CheckBox
		theme.CheckBoxTheme.Background = Color(255, 255, 255, 255);
		theme.CheckBoxTheme.Foreground = Color(0, 0, 0, 255);
		theme.CheckBoxTheme.BorderColor = Color(200, 200, 200, 255);
		theme.CheckBoxTheme.CheckColor = Color(255, 255, 255, 255);
		theme.CheckBoxTheme.Checked = .(Color(0, 120, 212, 255), null, Color(0, 120, 212, 255));
		theme.CheckBoxTheme.CheckedHover = .(Color(30, 140, 230, 255));

		// Slider
		theme.SliderTheme.TrackColor = Color(200, 200, 200, 255);
		theme.SliderTheme.FillColor = Color(0, 120, 212, 255);
		theme.SliderTheme.ThumbColor = Color(0, 120, 212, 255);
		theme.SliderTheme.ThumbHoverColor = Color(30, 140, 230, 255);

		// ScrollViewer
		theme.ScrollViewerTheme.ScrollBarBackground = Color(240, 240, 240, 255);
		theme.ScrollViewerTheme.ScrollBarThumb = Color(180, 180, 180, 255);
		theme.ScrollViewerTheme.ScrollBarThumbHover = Color(160, 160, 160, 255);

		// Dialog
		theme.DialogTheme.Background = Color(255, 255, 255, 255);
		theme.DialogTheme.BorderColor = Color(200, 200, 200, 255);
		theme.DialogTheme.OverlayColor = Color(0, 0, 0, 100);
		theme.DialogTheme.TitleColor = Color(0, 0, 0, 255);

		// TextBlock
		theme.TextBlockTheme.Background = Color(0, 0, 0, 0);
		theme.TextBlockTheme.Foreground = Color(0, 0, 0, 255);

		// Panel
		theme.PanelTheme.Background = Color(0, 0, 0, 0);

		return theme;
	}
}
