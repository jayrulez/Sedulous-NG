namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;
using System.Collections;

abstract class UIElement
{
	// === Static Routed Events ===
	public static readonly RoutedEvent PreviewMouseDownEvent = RoutedEvent.Register<UIElement>("PreviewMouseDown", .Tunnel);
	public static readonly RoutedEvent MouseDownEvent = RoutedEvent.Register<UIElement>("MouseDown", .Bubble);
	public static readonly RoutedEvent PreviewMouseUpEvent = RoutedEvent.Register<UIElement>("PreviewMouseUp", .Tunnel);
	public static readonly RoutedEvent MouseUpEvent = RoutedEvent.Register<UIElement>("MouseUp", .Bubble);
	public static readonly RoutedEvent PreviewMouseMoveEvent = RoutedEvent.Register<UIElement>("PreviewMouseMove", .Tunnel);
	public static readonly RoutedEvent MouseMoveEvent = RoutedEvent.Register<UIElement>("MouseMove", .Bubble);
	public static readonly RoutedEvent MouseEnterEvent = RoutedEvent.Register<UIElement>("MouseEnter", .Direct);
	public static readonly RoutedEvent MouseLeaveEvent = RoutedEvent.Register<UIElement>("MouseLeave", .Direct);
	public static readonly RoutedEvent PreviewMouseWheelEvent = RoutedEvent.Register<UIElement>("PreviewMouseWheel", .Tunnel);
	public static readonly RoutedEvent MouseWheelEvent = RoutedEvent.Register<UIElement>("MouseWheel", .Bubble);

	public static readonly RoutedEvent PreviewKeyDownEvent = RoutedEvent.Register<UIElement>("PreviewKeyDown", .Tunnel);
	public static readonly RoutedEvent KeyDownEvent = RoutedEvent.Register<UIElement>("KeyDown", .Bubble);
	public static readonly RoutedEvent PreviewKeyUpEvent = RoutedEvent.Register<UIElement>("PreviewKeyUp", .Tunnel);
	public static readonly RoutedEvent KeyUpEvent = RoutedEvent.Register<UIElement>("KeyUp", .Bubble);
	public static readonly RoutedEvent PreviewTextInputEvent = RoutedEvent.Register<UIElement>("PreviewTextInput", .Tunnel);
	public static readonly RoutedEvent TextInputEvent = RoutedEvent.Register<UIElement>("TextInput", .Bubble);

	public static readonly RoutedEvent GotFocusEvent = RoutedEvent.Register<UIElement>("GotFocus", .Bubble);
	public static readonly RoutedEvent LostFocusEvent = RoutedEvent.Register<UIElement>("LostFocus", .Bubble);

	// === Visual Tree ===
	protected UIElement mVisualParent;
	protected List<UIElement> mVisualChildren = new .() ~ delete _;

	// === Layout State ===
	protected Size2F mDesiredSize;
	protected RectangleF mArrangedBounds;
	protected Size2F mPreviousAvailableSize;
	protected bool mMeasureInvalid = true;
	protected bool mArrangeInvalid = true;

	// === Visibility and Interaction ===
	private bool mIsVisible = true;
	private bool mIsEnabled = true;
	private bool mIsHitTestVisible = true;
	private float mOpacity = 1.0f;
	private bool mFocusable = false;
	private bool mIsDisposed = false;

	// === Event Handlers ===
	protected Dictionary<RoutedEvent, List<Delegate>> mEventHandlers ~ {
		if (_ != null)
		{
			for (let pair in _)
			{
				DeleteContainerAndItems!(pair.value);
			}
			delete _;
		}
	};

	// === Properties ===
	public UIElement VisualParent => mVisualParent;
	public int32 VisualChildrenCount => (int32)mVisualChildren.Count;
	public Size2F DesiredSize => mDesiredSize;
	public float ActualWidth => mArrangedBounds.Width;
	public float ActualHeight => mArrangedBounds.Height;
	public RectangleF Bounds => mArrangedBounds;

	public bool IsVisible
	{
		get => mIsVisible;
		set
		{
			if (mIsVisible != value)
			{
				mIsVisible = value;
				InvalidateMeasure();
			}
		}
	}

	public bool IsEnabled
	{
		get => mIsEnabled;
		set
		{
			if (mIsEnabled != value)
			{
				mIsEnabled = value;
				OnIsEnabledChanged();
			}
		}
	}

	public bool IsHitTestVisible
	{
		get => mIsHitTestVisible;
		set => mIsHitTestVisible = value;
	}

	public float Opacity
	{
		get => mOpacity;
		set => mOpacity = Math.Clamp(value, 0.0f, 1.0f);
	}

	public bool Focusable
	{
		get => mFocusable;
		set => mFocusable = value;
	}

	public bool IsFocused => FocusManager.FocusedElement == this;

	public bool IsDisposed => mIsDisposed;

	// === Constructor/Destructor ===
	public this()
	{
	}

	public ~this()
	{
		mIsDisposed = true;

		// Delete all visual children (we own them)
		for (let child in mVisualChildren)
			delete child;
	}

	// === Layout Methods ===
	public void Measure(Size2F availableSize)
	{
		if (!mIsVisible)
		{
			mDesiredSize = .Zero;
			return;
		}

		if (!mMeasureInvalid && mPreviousAvailableSize == availableSize)
			return;

		mDesiredSize = MeasureCore(availableSize);
		mPreviousAvailableSize = availableSize;
		mMeasureInvalid = false;
	}

	protected virtual Size2F MeasureCore(Size2F availableSize)
	{
		return .Zero;
	}

	public void Arrange(RectangleF finalRect)
	{
		if (!mIsVisible)
		{
			mArrangedBounds = .(finalRect.X, finalRect.Y, 0, 0);
			return;
		}

		mArrangedBounds = ArrangeCore(finalRect);
		mArrangeInvalid = false;
	}

	protected virtual RectangleF ArrangeCore(RectangleF finalRect)
	{
		return finalRect;
	}

	public void InvalidateMeasure()
	{
		if (mMeasureInvalid)
			return;

		mMeasureInvalid = true;
		mArrangeInvalid = true;
		mVisualParent?.InvalidateMeasure();
	}

	public void InvalidateArrange()
	{
		if (mArrangeInvalid)
			return;

		mArrangeInvalid = true;
		mVisualParent?.InvalidateArrange();
	}

	// === Visual Tree Methods ===
	public UIElement GetVisualChild(int32 index)
	{
		if (index < 0 || index >= mVisualChildren.Count)
			return null;
		return mVisualChildren[index];
	}

	protected void AddVisualChild(UIElement child)
	{
		if (child == null || child.mVisualParent != null)
			return;

		child.mVisualParent = this;
		mVisualChildren.Add(child);
		InvalidateMeasure();
	}

	protected void RemoveVisualChild(UIElement child)
	{
		if (child == null || child.mVisualParent != this)
			return;

		child.mVisualParent = null;
		mVisualChildren.Remove(child);
		InvalidateMeasure();
	}

	protected void ClearVisualChildren()
	{
		for (let child in mVisualChildren)
			child.mVisualParent = null;
		mVisualChildren.Clear();
		InvalidateMeasure();
	}

	// === Rendering ===
	public void Render(IUIRenderer renderer)
	{
		if (!mIsVisible || mOpacity <= 0)
			return;

		OnRender(renderer);

		for (let child in mVisualChildren)
		{
			renderer.PushTransform(.(child.mArrangedBounds.X, child.mArrangedBounds.Y));
			child.Render(renderer);
			renderer.PopTransform();
		}
	}

	protected virtual void OnRender(IUIRenderer renderer)
	{
	}

	// === Hit Testing ===
	public UIElement HitTest(Point2F point)
	{
		if (!mIsVisible || !mIsHitTestVisible)
			return null;

		// Check children in reverse order (topmost first)
		for (var i = mVisualChildren.Count - 1; i >= 0; i--)
		{
			let child = mVisualChildren[i];
			let localPoint = Point2F(point.X - child.mArrangedBounds.X, point.Y - child.mArrangedBounds.Y);

			let hit = child.HitTest(localPoint);
			if (hit != null)
				return hit;
		}

		// Check self
		if (HitTestCore(point))
			return this;

		return null;
	}

	protected virtual bool HitTestCore(Point2F point)
	{
		return point.X >= 0 && point.Y >= 0 &&
			   point.X < mArrangedBounds.Width && point.Y < mArrangedBounds.Height;
	}

	// === Coordinate Transforms ===
	public Point2F TransformToRoot(Point2F localPoint)
	{
		var result = Point2F(mArrangedBounds.X + localPoint.X, mArrangedBounds.Y + localPoint.Y);
		if (mVisualParent != null)
			result = mVisualParent.TransformToRoot(result);
		return result;
	}

	public Point2F TransformFromRoot(Point2F rootPoint)
	{
		var local = rootPoint;
		if (mVisualParent != null)
			local = mVisualParent.TransformFromRoot(rootPoint);
		return Point2F(local.X - mArrangedBounds.X, local.Y - mArrangedBounds.Y);
	}

	public Point2F TransformToAncestor(Point2F localPoint, UIElement ancestor)
	{
		var result = localPoint;
		var current = this;

		while (current != null && current != ancestor)
		{
			result.X += current.mArrangedBounds.X;
			result.Y += current.mArrangedBounds.Y;
			current = current.mVisualParent;
		}

		return result;
	}

	// === Event Handling ===
	public void AddHandler(RoutedEvent routedEvent, RoutedEventHandler handler)
	{
		if (routedEvent == null || handler == null)
			return;

		if (mEventHandlers == null)
			mEventHandlers = new .();

		if (!mEventHandlers.TryGetValue(routedEvent, var handlers))
		{
			handlers = new List<Delegate>();
			mEventHandlers[routedEvent] = handlers;
		}

		handlers.Add(handler);
	}

	public void RemoveHandler(RoutedEvent routedEvent, RoutedEventHandler handler)
	{
		if (routedEvent == null || handler == null || mEventHandlers == null)
			return;

		if (mEventHandlers.TryGetValue(routedEvent, let handlers))
		{
			handlers.Remove(handler);
		}
	}

	internal void InvokeEventHandlers(RoutedEventArgs args)
	{
		if (args.RoutedEvent == null || mEventHandlers == null)
			return;

		if (mEventHandlers.TryGetValue(args.RoutedEvent, let handlers))
		{
			for (let handler in handlers)
			{
				if (let typedHandler = handler as RoutedEventHandler)
				{
					typedHandler(this, args);
				}
			}
		}
	}

	public void RaiseEvent(RoutedEventArgs args)
	{
		EventManager.RaiseEvent(this, args);
	}

	// === Focus ===
	public bool Focus()
	{
		if (!mFocusable || !mIsEnabled || !mIsVisible)
			return false;

		FocusManager.SetFocus(this);
		return true;
	}

	protected internal virtual void OnGotFocus()
	{
		let args = scope FocusEventArgs(GotFocusEvent);
		RaiseEvent(args);
	}

	protected internal virtual void OnLostFocus()
	{
		let args = scope FocusEventArgs(LostFocusEvent);
		RaiseEvent(args);
	}

	protected virtual void OnIsEnabledChanged()
	{
		// Propagate to children
		for (let child in mVisualChildren)
		{
			child.OnIsEnabledChanged();
		}
	}

	// === Mouse State (for controls) ===
	public bool IsMouseOver { get; internal set; }
	public bool IsMouseDirectlyOver { get; internal set; }

	protected internal virtual void OnMouseEnter(MouseEventArgs args)
	{
		IsMouseOver = true;
	}

	protected internal virtual void OnMouseLeave(MouseEventArgs args)
	{
		IsMouseOver = false;
		IsMouseDirectlyOver = false;
	}
}
