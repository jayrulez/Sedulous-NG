namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

interface IUIRenderer
{
	// Viewport
	Size2F ViewportSize { get; }

	// Frame management
	void BeginFrame();
	void EndFrame();

	// Clipping
	void PushClipRect(RectangleF rect);
	void PopClipRect();

	// Transform (for popup positioning)
	void PushTransform(Point2F offset);
	void PopTransform();

	// Primitive drawing
	void DrawLine(Point2F start, Point2F end, Color color, float thickness = 1.0f);
	void DrawRectangle(RectangleF rect, Color color, float thickness = 1.0f);
	void FillRectangle(RectangleF rect, Color color);
	void DrawRoundedRectangle(RectangleF rect, Color color, float cornerRadius, float thickness = 1.0f);
	void FillRoundedRectangle(RectangleF rect, Color color, float cornerRadius);

	// Text rendering
	void DrawText(StringView text, IFont font, Point2F position, Color color);
	void DrawText(StringView text, IFont font, RectangleF bounds, Color color,
				  TextAlignment alignment = .Left, TextWrapping wrapping = .NoWrap);

	// Image rendering
	void DrawImage(IUITexture texture, RectangleF destRect, Color tint = .White);
	void DrawImage(IUITexture texture, RectangleF destRect, RectangleF sourceRect, Color tint = .White);

	// Nine-slice rendering for scalable borders
	void DrawNineSlice(IUITexture texture, RectangleF destRect, Thickness sliceMargins, Color tint = .White);
}
