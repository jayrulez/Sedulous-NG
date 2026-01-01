namespace Sedulous.GUI;

enum TextAlignment
{
	Left,
	Center,
	Right,
	Justify
}

enum TextWrapping
{
	NoWrap,
	Wrap,
	WrapWholeWords
}

enum HorizontalAlignment
{
	Left,
	Center,
	Right,
	Stretch
}

enum VerticalAlignment
{
	Top,
	Center,
	Bottom,
	Stretch
}

enum Orientation
{
	Horizontal,
	Vertical
}

enum Stretch
{
	None,
	Fill,
	Uniform,
	UniformToFill
}

enum Dock
{
	Left,
	Top,
	Right,
	Bottom
}

enum FontWeight
{
	Thin = 100,
	ExtraLight = 200,
	Light = 300,
	Normal = 400,
	Medium = 500,
	SemiBold = 600,
	Bold = 700,
	ExtraBold = 800,
	Black = 900
}

enum FontStyle
{
	Normal,
	Italic,
	Oblique
}

enum CursorType
{
	Arrow,
	IBeam,
	Hand,
	SizeNS,
	SizeWE,
	SizeNESW,
	SizeNWSE,
	SizeAll,
	Wait,
	No,
	Cross
}

enum GUIMouseButton
{
	None,
	Left,
	Middle,
	Right,
	XButton1,
	XButton2
}

enum GUIKey
{
	None,

	// Navigation
	Tab,
	Return,
	Escape,
	Space,
	Backspace,
	Delete,
	Insert,

	// Arrow keys
	Left,
	Right,
	Up,
	Down,

	// Home/End/Page
	Home,
	End,
	PageUp,
	PageDown,

	// Modifiers
	LeftShift,
	RightShift,
	LeftControl,
	RightControl,
	LeftAlt,
	RightAlt,

	// Letters
	A, B, C, D, E, F, G, H, I, J, K, L, M,
	N, O, P, Q, R, S, T, U, V, W, X, Y, Z,

	// Numbers
	D0, D1, D2, D3, D4, D5, D6, D7, D8, D9,

	// Numpad
	NumPad0, NumPad1, NumPad2, NumPad3, NumPad4,
	NumPad5, NumPad6, NumPad7, NumPad8, NumPad9,
	NumPadAdd, NumPadSubtract, NumPadMultiply, NumPadDivide,
	NumPadDecimal, NumPadEnter,

	// Function keys
	F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12,

	// Punctuation
	Comma,
	Period,
	Slash,
	Semicolon,
	Apostrophe,
	LeftBracket,
	RightBracket,
	Backslash,
	Minus,
	Equals,
	Grave
}

struct GUIModifierKeys
{
	public bool Control;
	public bool Shift;
	public bool Alt;

	public this()
	{
		Control = false;
		Shift = false;
		Alt = false;
	}

	public this(bool control, bool shift, bool alt)
	{
		Control = control;
		Shift = shift;
		Alt = alt;
	}

	public bool None => !Control && !Shift && !Alt;
}

enum FocusNavigationDirection
{
	Next,
	Previous,
	Up,
	Down,
	Left,
	Right
}

enum ScrollBarVisibility
{
	Disabled,
	Auto,
	Hidden,
	Visible
}

enum PlacementMode
{
	Absolute,
	RelativeToTarget,
	Bottom,
	Top,
	Left,
	Right,
	Center
}

enum DialogResult
{
	None,
	OK,
	Cancel,
	Yes,
	No
}
