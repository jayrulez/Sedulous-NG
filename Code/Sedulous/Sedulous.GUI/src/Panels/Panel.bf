namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;
using System.Collections;

abstract class Panel : FrameworkElement
{
	protected List<UIElement> mChildren = new .() ~ delete _;

	// === Appearance ===
	private Color? mBackgroundOverride;

	public Color? BackgroundOverride
	{
		get => mBackgroundOverride;
		set => mBackgroundOverride = value;
	}

	public Color Background
	{
		get
		{
			if (mBackgroundOverride.HasValue)
				return mBackgroundOverride.Value;
			return ThemeManager.PanelTheme?.Background ?? Color(0, 0, 0, 0);
		}
	}

	// === Children ===
	public int32 ChildCount => (int32)mChildren.Count;

	public List<UIElement>.Enumerator Children => mChildren.GetEnumerator();

	public UIElement GetChild(int32 index)
	{
		if (index < 0 || index >= mChildren.Count)
			return null;
		return mChildren[index];
	}

	public void AddChild(UIElement child)
	{
		if (child == null)
			return;

		mChildren.Add(child);
		AddVisualChild(child);
	}

	public void InsertChild(int32 index, UIElement child)
	{
		if (child == null)
			return;

		mChildren.Insert(Math.Clamp(index, 0, (int32)mChildren.Count), child);
		AddVisualChild(child);
	}

	public void RemoveChild(UIElement child)
	{
		if (child == null)
			return;

		mChildren.Remove(child);
		RemoveVisualChild(child);
	}

	public void RemoveChildAt(int32 index)
	{
		if (index < 0 || index >= mChildren.Count)
			return;

		let child = mChildren[index];
		mChildren.RemoveAt(index);
		RemoveVisualChild(child);
	}

	public void ClearChildren()
	{
		mChildren.Clear();
		ClearVisualChildren();
	}

	// === Rendering ===
	protected override void OnRender(IUIRenderer renderer)
	{
		let bg = Background;
		if (bg.A > 0)
		{
			renderer.FillRectangle(RectangleF(0, 0, ActualWidth, ActualHeight), bg);
		}
	}
}
