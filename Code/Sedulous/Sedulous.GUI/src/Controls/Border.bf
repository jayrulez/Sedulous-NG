namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

class Border : FrameworkElement
{
	private UIElement mChild;

	// === Appearance (Overrides) ===
	public Color? BackgroundOverride;
	public Color? BorderBrushOverride;
	public Thickness? BorderThicknessOverride;
	public float? CornerRadiusOverride;
	public Thickness? PaddingOverride;

	// === Themed Properties ===
	public Color Background
	{
		get
		{
			if (BackgroundOverride.HasValue)
				return BackgroundOverride.Value;
			return ThemeManager.BorderTheme?.Background ?? Color(0, 0, 0, 0);
		}
	}

	public Color BorderBrush
	{
		get
		{
			if (BorderBrushOverride.HasValue)
				return BorderBrushOverride.Value;
			return ThemeManager.BorderTheme?.BorderColor ?? Color(100, 100, 100, 255);
		}
	}

	public Thickness BorderThickness
	{
		get
		{
			if (BorderThicknessOverride.HasValue)
				return BorderThicknessOverride.Value;
			return ThemeManager.BorderTheme?.BorderThickness ?? .Zero;
		}
	}

	public float CornerRadius
	{
		get
		{
			if (CornerRadiusOverride.HasValue)
				return CornerRadiusOverride.Value;
			return ThemeManager.BorderTheme?.CornerRadius ?? 0;
		}
	}

	public Thickness Padding
	{
		get
		{
			if (PaddingOverride.HasValue)
				return PaddingOverride.Value;
			return ThemeManager.BorderTheme?.Padding ?? .Zero;
		}
	}

	// === Content ===
	public UIElement Child
	{
		get => mChild;
		set
		{
			if (mChild != null)
			{
				RemoveVisualChild(mChild);
			}

			mChild = value;

			if (mChild != null)
			{
				AddVisualChild(mChild);
			}

			InvalidateMeasure();
		}
	}

	// === Layout ===
	protected override Size2F MeasureOverride(Size2F availableSize)
	{
		let borderSize = BorderThickness;
		let paddingSize = Padding;

		let totalInset = Thickness(
			borderSize.Left + paddingSize.Left,
			borderSize.Top + paddingSize.Top,
			borderSize.Right + paddingSize.Right,
			borderSize.Bottom + paddingSize.Bottom
		);

		var childConstraint = Size2F(
			Math.Max(0, availableSize.Width - totalInset.HorizontalThickness),
			Math.Max(0, availableSize.Height - totalInset.VerticalThickness)
		);

		if (mChild != null)
		{
			mChild.Measure(childConstraint);
			return Size2F(
				mChild.DesiredSize.Width + totalInset.HorizontalThickness,
				mChild.DesiredSize.Height + totalInset.VerticalThickness
			);
		}

		return totalInset.Size;
	}

	protected override Size2F ArrangeOverride(Size2F finalSize)
	{
		if (mChild != null)
		{
			let borderSize = BorderThickness;
			let paddingSize = Padding;

			let childRect = RectangleF(
				borderSize.Left + paddingSize.Left,
				borderSize.Top + paddingSize.Top,
				Math.Max(0, finalSize.Width - borderSize.HorizontalThickness - paddingSize.HorizontalThickness),
				Math.Max(0, finalSize.Height - borderSize.VerticalThickness - paddingSize.VerticalThickness)
			);

			mChild.Arrange(childRect);
		}

		return finalSize;
	}

	// === Rendering ===
	protected override void OnRender(IUIRenderer renderer)
	{
		let rect = RectangleF(0, 0, ActualWidth, ActualHeight);
		let bg = Background;
		let border = BorderBrush;
		let borderT = BorderThickness;
		let radius = CornerRadius;

		// Draw background
		if (bg.A > 0)
		{
			if (radius > 0)
				renderer.FillRoundedRectangle(rect, bg, radius);
			else
				renderer.FillRectangle(rect, bg);
		}

		// Draw border
		let hasBorder = border.A > 0 && (borderT.Left > 0 || borderT.Top > 0 || borderT.Right > 0 || borderT.Bottom > 0);
		if (hasBorder)
		{
			if (radius > 0)
			{
				// For rounded rectangles, use a single stroke
				let avgThickness = (borderT.Left + borderT.Top + borderT.Right + borderT.Bottom) / 4;
				renderer.DrawRoundedRectangle(rect, border, radius, avgThickness);
			}
			else
			{
				// Draw individual borders for non-rounded
				if (borderT.Top > 0)
					renderer.FillRectangle(.(0, 0, ActualWidth, borderT.Top), border);
				if (borderT.Bottom > 0)
					renderer.FillRectangle(.(0, ActualHeight - borderT.Bottom, ActualWidth, borderT.Bottom), border);
				if (borderT.Left > 0)
					renderer.FillRectangle(.(0, borderT.Top, borderT.Left, ActualHeight - borderT.Top - borderT.Bottom), border);
				if (borderT.Right > 0)
					renderer.FillRectangle(.(ActualWidth - borderT.Right, borderT.Top, borderT.Right, ActualHeight - borderT.Top - borderT.Bottom), border);
			}
		}
	}
}
