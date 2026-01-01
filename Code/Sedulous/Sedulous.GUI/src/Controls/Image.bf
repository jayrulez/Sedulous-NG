namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

class Image : FrameworkElement
{
	private IUITexture mSource;

	public IUITexture Source
	{
		get => mSource;
		set
		{
			mSource = value;
			InvalidateMeasure();
		}
	}

	public Stretch Stretch = .Uniform;
	public Color Tint = .White;

	protected override Size2F MeasureOverride(Size2F availableSize)
	{
		if (mSource == null)
			return .Zero;

		let imageSize = mSource.Size;

		switch (Stretch)
		{
		case .None:
			// Natural size, constrained by available
			return Size2F(
				Math.Min(imageSize.Width, availableSize.Width),
				Math.Min(imageSize.Height, availableSize.Height)
			);

		case .Fill:
			// Fill available space
			return availableSize;

		case .Uniform:
			// Scale uniformly to fit within available
			if (imageSize.Width <= 0 || imageSize.Height <= 0)
				return .Zero;

			let scaleX = availableSize.Width / imageSize.Width;
			let scaleY = availableSize.Height / imageSize.Height;
			let scale = Math.Min(scaleX, scaleY);

			return Size2F(imageSize.Width * scale, imageSize.Height * scale);

		case .UniformToFill:
			// Scale uniformly to fill available (may clip)
			if (imageSize.Width <= 0 || imageSize.Height <= 0)
				return .Zero;

			let scaleX2 = availableSize.Width / imageSize.Width;
			let scaleY2 = availableSize.Height / imageSize.Height;
			let scale2 = Math.Max(scaleX2, scaleY2);

			return Size2F(
				Math.Min(imageSize.Width * scale2, availableSize.Width),
				Math.Min(imageSize.Height * scale2, availableSize.Height)
			);
		}
	}

	protected override void OnRender(IUIRenderer renderer)
	{
		if (mSource == null)
			return;

		let destRect = RectangleF(0, 0, ActualWidth, ActualHeight);
		renderer.DrawImage(mSource, destRect, Tint);
	}
}
