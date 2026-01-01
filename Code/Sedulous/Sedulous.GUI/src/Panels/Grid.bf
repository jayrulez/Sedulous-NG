namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;
using System.Collections;

enum GridUnitType
{
	Auto,
	Pixel,
	Star
}

struct GridLength
{
	public float Value;
	public GridUnitType UnitType;

	public static GridLength Auto => .(1, .Auto);
	public static GridLength Star(float value = 1) => .(value, .Star);
	public static GridLength Pixel(float value) => .(value, .Pixel);

	public this(float value, GridUnitType unitType)
	{
		Value = value;
		UnitType = unitType;
	}

	public bool IsAuto => UnitType == .Auto;
	public bool IsStar => UnitType == .Star;
	public bool IsPixel => UnitType == .Pixel;
}

class ColumnDefinition
{
	public GridLength Width = .Star(1);
	public float MinWidth = 0;
	public float MaxWidth = float.PositiveInfinity;
	public float ActualWidth;
}

class RowDefinition
{
	public GridLength Height = .Star(1);
	public float MinHeight = 0;
	public float MaxHeight = float.PositiveInfinity;
	public float ActualHeight;
}

class Grid : Panel
{
	public List<ColumnDefinition> ColumnDefinitions = new .() ~ DeleteContainerAndItems!(_);
	public List<RowDefinition> RowDefinitions = new .() ~ DeleteContainerAndItems!(_);

	// Attached properties storage
	private Dictionary<UIElement, int32> mChildColumns = new .() ~ delete _;
	private Dictionary<UIElement, int32> mChildRows = new .() ~ delete _;
	private Dictionary<UIElement, int32> mChildColumnSpans = new .() ~ delete _;
	private Dictionary<UIElement, int32> mChildRowSpans = new .() ~ delete _;

	public void SetColumn(UIElement child, int32 column)
	{
		mChildColumns[child] = column;
		InvalidateMeasure();
	}

	public void SetRow(UIElement child, int32 row)
	{
		mChildRows[child] = row;
		InvalidateMeasure();
	}

	public void SetColumnSpan(UIElement child, int32 span)
	{
		mChildColumnSpans[child] = Math.Max(1, span);
		InvalidateMeasure();
	}

	public void SetRowSpan(UIElement child, int32 span)
	{
		mChildRowSpans[child] = Math.Max(1, span);
		InvalidateMeasure();
	}

	public int32 GetColumn(UIElement child) => mChildColumns.TryGetValue(child, let value) ? value : 0;
	public int32 GetRow(UIElement child) => mChildRows.TryGetValue(child, let value) ? value : 0;
	public int32 GetColumnSpan(UIElement child) => mChildColumnSpans.TryGetValue(child, let value) ? value : 1;
	public int32 GetRowSpan(UIElement child) => mChildRowSpans.TryGetValue(child, let value) ? value : 1;

	protected override Size2F MeasureOverride(Size2F availableSize)
	{
		// Ensure at least one row and column
		let numCols = Math.Max(1, (int32)ColumnDefinitions.Count);
		let numRows = Math.Max(1, (int32)RowDefinitions.Count);

		// Calculate column widths
		let colWidths = scope float[numCols];
		let rowHeights = scope float[numRows];

		// First pass: measure Auto and Pixel sizes
		for (int32 c = 0; c < numCols; c++)
		{
			if (c < ColumnDefinitions.Count)
			{
				let def = ColumnDefinitions[c];
				if (def.Width.IsPixel)
					colWidths[c] = Math.Clamp(def.Width.Value, def.MinWidth, def.MaxWidth);
				else if (def.Width.IsAuto)
					colWidths[c] = 0; // Will be determined by content
			}
		}

		for (int32 r = 0; r < numRows; r++)
		{
			if (r < RowDefinitions.Count)
			{
				let def = RowDefinitions[r];
				if (def.Height.IsPixel)
					rowHeights[r] = Math.Clamp(def.Height.Value, def.MinHeight, def.MaxHeight);
				else if (def.Height.IsAuto)
					rowHeights[r] = 0;
			}
		}

		// Measure children to determine Auto sizes
		for (let child in mChildren)
		{
			if (!child.IsVisible)
				continue;

			let col = Math.Clamp(GetColumn(child), 0, numCols - 1);
			let row = Math.Clamp(GetRow(child), 0, numRows - 1);

			child.Measure(availableSize);

			// Update Auto columns
			if (col < ColumnDefinitions.Count && ColumnDefinitions[col].Width.IsAuto)
			{
				colWidths[col] = Math.Max(colWidths[col], child.DesiredSize.Width);
			}

			// Update Auto rows
			if (row < RowDefinitions.Count && RowDefinitions[row].Height.IsAuto)
			{
				rowHeights[row] = Math.Max(rowHeights[row], child.DesiredSize.Height);
			}
		}

		// Calculate Star sizes
		float totalStarWidth = 0;
		float totalStarHeight = 0;
		float usedWidth = 0;
		float usedHeight = 0;

		for (int32 c = 0; c < numCols; c++)
		{
			if (c < ColumnDefinitions.Count && ColumnDefinitions[c].Width.IsStar)
				totalStarWidth += ColumnDefinitions[c].Width.Value;
			else
				usedWidth += colWidths[c];
		}

		for (int32 r = 0; r < numRows; r++)
		{
			if (r < RowDefinitions.Count && RowDefinitions[r].Height.IsStar)
				totalStarHeight += RowDefinitions[r].Height.Value;
			else
				usedHeight += rowHeights[r];
		}

		let remainingWidth = Math.Max(0, availableSize.Width - usedWidth);
		let remainingHeight = Math.Max(0, availableSize.Height - usedHeight);

		for (int32 c = 0; c < numCols; c++)
		{
			if (c < ColumnDefinitions.Count && ColumnDefinitions[c].Width.IsStar && totalStarWidth > 0)
			{
				let def = ColumnDefinitions[c];
				colWidths[c] = Math.Clamp((def.Width.Value / totalStarWidth) * remainingWidth, def.MinWidth, def.MaxWidth);
			}
		}

		for (int32 r = 0; r < numRows; r++)
		{
			if (r < RowDefinitions.Count && RowDefinitions[r].Height.IsStar && totalStarHeight > 0)
			{
				let def = RowDefinitions[r];
				rowHeights[r] = Math.Clamp((def.Height.Value / totalStarHeight) * remainingHeight, def.MinHeight, def.MaxHeight);
			}
		}

		// Store actual sizes
		for (int32 c = 0; c < numCols && c < ColumnDefinitions.Count; c++)
			ColumnDefinitions[c].ActualWidth = colWidths[c];

		for (int32 r = 0; r < numRows && r < RowDefinitions.Count; r++)
			RowDefinitions[r].ActualHeight = rowHeights[r];

		// Calculate total size
		float totalWidth = 0;
		float totalHeight = 0;

		for (int32 c = 0; c < numCols; c++)
			totalWidth += colWidths[c];
		for (int32 r = 0; r < numRows; r++)
			totalHeight += rowHeights[r];

		return Size2F(totalWidth, totalHeight);
	}

	protected override Size2F ArrangeOverride(Size2F finalSize)
	{
		let numCols = Math.Max(1, (int32)ColumnDefinitions.Count);
		let numRows = Math.Max(1, (int32)RowDefinitions.Count);

		// Calculate column offsets
		let colOffsets = scope float[numCols + 1];
		let rowOffsets = scope float[numRows + 1];

		colOffsets[0] = 0;
		for (int32 c = 0; c < numCols; c++)
		{
			let width = c < ColumnDefinitions.Count ? ColumnDefinitions[c].ActualWidth : (finalSize.Width / numCols);
			colOffsets[c + 1] = colOffsets[c] + width;
		}

		rowOffsets[0] = 0;
		for (int32 r = 0; r < numRows; r++)
		{
			let height = r < RowDefinitions.Count ? RowDefinitions[r].ActualHeight : (finalSize.Height / numRows);
			rowOffsets[r + 1] = rowOffsets[r] + height;
		}

		// Arrange children
		for (let child in mChildren)
		{
			if (!child.IsVisible)
				continue;

			let col = Math.Clamp(GetColumn(child), 0, numCols - 1);
			let row = Math.Clamp(GetRow(child), 0, numRows - 1);
			let colSpan = Math.Clamp(GetColumnSpan(child), 1, numCols - col);
			let rowSpan = Math.Clamp(GetRowSpan(child), 1, numRows - row);

			let x = colOffsets[col];
			let y = rowOffsets[row];
			let width = colOffsets[col + colSpan] - x;
			let height = rowOffsets[row + rowSpan] - y;

			child.Arrange(RectangleF(x, y, width, height));
		}

		return finalSize;
	}
}
