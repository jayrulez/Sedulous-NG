namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

class ThemeResources
{
	// === Primary Colors ===
	public Color PrimaryColor = Color(0, 120, 212, 255);       // Accent/primary
	public Color SecondaryColor = Color(100, 100, 100, 255);   // Secondary accent
	public Color BackgroundColor = Color(30, 30, 30, 255);     // Window background
	public Color SurfaceColor = Color(45, 45, 45, 255);        // Panel/card surfaces
	public Color ErrorColor = Color(220, 50, 50, 255);         // Error states

	// === Text Colors ===
	public Color TextPrimary = Color(255, 255, 255, 255);      // Primary text
	public Color TextSecondary = Color(180, 180, 180, 255);    // Secondary/muted text
	public Color TextDisabled = Color(100, 100, 100, 255);     // Disabled text
	public Color TextOnPrimary = Color(255, 255, 255, 255);    // Text on primary color

	// === Control Colors ===
	public Color ControlBackground = Color(60, 60, 60, 255);
	public Color ControlBorder = Color(100, 100, 100, 255);
	public Color ControlBackgroundHover = Color(80, 80, 80, 255);
	public Color ControlBackgroundPressed = Color(50, 50, 50, 255);
	public Color ControlBackgroundDisabled = Color(45, 45, 45, 255);

	// === Focus & Selection ===
	public Color FocusRing = Color(0, 120, 212, 255);
	public Color SelectionBackground = Color(0, 120, 212, 128);
	public Color SelectionText = Color(255, 255, 255, 255);

	// === Scrollbar Colors ===
	public Color ScrollBarBackground = Color(40, 40, 40, 255);
	public Color ScrollBarThumb = Color(100, 100, 100, 255);
	public Color ScrollBarThumbHover = Color(120, 120, 120, 255);

	// === Popup/Dialog Colors ===
	public Color PopupBackground = Color(50, 50, 50, 255);
	public Color PopupBorder = Color(80, 80, 80, 255);
	public Color DialogOverlay = Color(0, 0, 0, 128);

	// === Fonts (to be set by user) ===
	public IFont DefaultFont;
	public IFont HeadingFont;
	public IFont MonospaceFont;

	// === Sizing ===
	public float CornerRadius = 4.0f;
	public float BorderWidth = 1.0f;
	public Thickness ControlPadding = .(8, 4, 8, 4);
	public float ControlSpacing = 4.0f;
	public float FocusRingWidth = 2.0f;

	// === Animation (for future use) ===
	public float TransitionDuration = 0.15f;
}
