namespace GUITest;

using Sedulous.GUI;
using Sedulous.Mathematics;
using System;

class DummyFont : IFont
{
	private float mSize;
	private float mCharWidth;

	public this(float size)
	{
		mSize = size;
		mCharWidth = size * 0.6f; // Approximate monospace character width
	}

	public StringView FamilyName => "Dummy";
	public float Size => mSize;

	public FontMetrics Metrics => .(mSize, mSize * 0.8f, -mSize * 0.2f, 1.0f);

	public GlyphMetrics GetGlyphMetrics(char32 codepoint)
	{
		return .(mCharWidth, 0, mSize * 0.8f, mCharWidth, mSize);
	}

	public Size2F MeasureString(StringView text)
	{
		return .(text.Length * mCharWidth, mSize);
	}

	public Size2F MeasureString(StringView text, float maxWidth, TextWrapping wrapping)
	{
		if (wrapping == .NoWrap)
			return MeasureString(text);

		// Simple word wrapping calculation
		let charsPerLine = (int)(maxWidth / mCharWidth);
		if (charsPerLine <= 0)
			return .(maxWidth, mSize);

		let lines = (text.Length + charsPerLine - 1) / charsPerLine;
		return .(Math.Min(text.Length * mCharWidth, maxWidth), lines * mSize);
	}

	public float GetKerning(char32 left, char32 right)
	{
		return 0; // No kerning for dummy font
	}
}

class DummyFontProvider : IFontProvider
{
	private DummyFont mDefaultFont ~ delete _;

	public this()
	{
		mDefaultFont = new DummyFont(14);
	}

	public Result<IFont> GetFont(StringView familyName, float size, FontWeight weight = .Normal, FontStyle style = .Normal)
	{
		// Return a new font with the requested size
		return .Ok(new DummyFont(size));
	}

	public IFont DefaultFont => mDefaultFont;
}
