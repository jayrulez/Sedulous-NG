namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

struct GlyphMetrics
{
	public float Advance;      // Horizontal advance to next glyph
	public float BearingX;     // Offset from cursor to left edge of glyph
	public float BearingY;     // Offset from baseline to top edge of glyph
	public float Width;        // Width of the glyph bitmap
	public float Height;       // Height of the glyph bitmap

	public this()
	{
		Advance = 0;
		BearingX = 0;
		BearingY = 0;
		Width = 0;
		Height = 0;
	}

	public this(float advance, float bearingX, float bearingY, float width, float height)
	{
		Advance = advance;
		BearingX = bearingX;
		BearingY = bearingY;
		Width = width;
		Height = height;
	}
}

struct FontMetrics
{
	public float LineHeight;   // Total height of a line (ascender - descender + lineGap)
	public float Ascender;     // Height above baseline
	public float Descender;    // Depth below baseline (typically negative)
	public float UnitsPerEm;   // Font design units per em

	public this()
	{
		LineHeight = 0;
		Ascender = 0;
		Descender = 0;
		UnitsPerEm = 0;
	}

	public this(float lineHeight, float ascender, float descender, float unitsPerEm = 1.0f)
	{
		LineHeight = lineHeight;
		Ascender = ascender;
		Descender = descender;
		UnitsPerEm = unitsPerEm;
	}
}

interface IFont
{
	StringView FamilyName { get; }
	float Size { get; }
	FontMetrics Metrics { get; }

	GlyphMetrics GetGlyphMetrics(char32 codepoint);
	Size2F MeasureString(StringView text);
	Size2F MeasureString(StringView text, float maxWidth, TextWrapping wrapping);
	float GetKerning(char32 left, char32 right);
}

interface IFontProvider
{
	Result<IFont> GetFont(StringView familyName, float size, FontWeight weight = .Normal, FontStyle style = .Normal);
	IFont DefaultFont { get; }
}
