namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

using internal Sedulous.GUI;

class InputRouter
{
	private UIElement mRoot;
	private IInputProvider mInput;
	private UIElement mMouseOver;
	private UIElement mMouseDirectlyOver;

	private GUIMouseButtonEventHandler mMouseButtonPressed = null /*~ delete _*/;
	private GUIMouseButtonEventHandler mMouseButtonReleased = null /*~ delete _*/;
	private GUIMouseMoveEventHandler mMouseMoved = null /*~ delete _*/;
	private GUIMouseWheelEventHandler mMouseWheel = null /*~ delete _*/;
	private GUIKeyEventHandler mKeyPressed = null /*~ delete _*/;
	private GUIKeyEventHandler mKeyReleased = null /*~ delete _*/;
	private GUITextInputEventHandler mTextInput = null /*~ delete _*/;

	public this(UIElement root, IInputProvider input)
	{
		mRoot = root;
		mInput = input;

		// Subscribe to input events
		mInput.MouseButtonPressed.Subscribe(mMouseButtonPressed = new => OnMouseButtonPressed);
		mInput.MouseButtonReleased.Subscribe(mMouseButtonReleased = new => OnMouseButtonReleased);
		mInput.MouseMoved.Subscribe(mMouseMoved = new => OnMouseMoved);
		mInput.MouseWheelScrolled.Subscribe(mMouseWheel = new => OnMouseWheel);
		mInput.KeyPressed.Subscribe(mKeyPressed = new => OnKeyPressed);
		mInput.KeyReleased.Subscribe(mKeyReleased = new => OnKeyReleased);
		mInput.TextInput.Subscribe(mTextInput = new => OnTextInput);
	}

	public ~this()
	{
		// Unsubscribe from events
		// Note: In a real implementation, would need to store delegates to unsubscribe
	}

	public void SetRoot(UIElement root)
	{
		mRoot = root;
	}

	/// Transforms screen coordinates to root-local coordinates for hit testing
	private Point2F ScreenToRootLocal(Point2F screenPosition)
	{
		if (mRoot == null)
			return screenPosition;
		// Subtract root's position since rendering pushes root.Bounds as initial transform
		return .(screenPosition.X - mRoot.Bounds.X, screenPosition.Y - mRoot.Bounds.Y);
	}

	private void OnMouseMoved(Point2F position, Point2F delta)
	{
		if (mRoot == null)
			return;

		// Determine target (captured or hit test)
		UIElement target = MouseCapture.CapturedElement;
		if (target == null)
		{
			// Check dialogs first (they're rendered on top and block input)
			target = DialogManager.HitTestDialogs(position);
			if (target == null)
				target = mRoot.HitTest(ScreenToRootLocal(position));
		}

		// Handle mouse enter/leave
		UpdateMouseOver(target, position);

		// Raise mouse move events
		if (target != null)
		{
			let args = scope MouseEventArgs(UIElement.PreviewMouseMoveEvent);
			args.ScreenPosition = position;
			args.Position = target.TransformFromRoot(position);
			args.Modifiers = mInput.CurrentModifiers;

			EventManager.RaiseRoutedEvent(target, UIElement.PreviewMouseMoveEvent, UIElement.MouseMoveEvent, args);
		}
	}

	private void OnMouseButtonPressed(Point2F position, GUIMouseButton button, GUIModifierKeys modifiers)
	{
		if (mRoot == null)
			return;

		// Determine target
		UIElement target = MouseCapture.CapturedElement;
		if (target == null)
		{
			// Check dialogs first (they're rendered on top and block input)
			target = DialogManager.HitTestDialogs(position);
			if (target == null)
				target = mRoot.HitTest(ScreenToRootLocal(position));
		}

		if (target == null)
			return;

		// Set focus on click
		if (button == .Left && target.Focusable)
		{
			FocusManager.SetFocus(target);
		}

		// Raise events
		let args = scope MouseButtonEventArgs(UIElement.PreviewMouseDownEvent);
		args.ScreenPosition = position;
		args.Position = target.TransformFromRoot(position);
		args.Button = button;
		args.Modifiers = modifiers;
		args.ClickCount = 1; // TODO: Track double-clicks

		EventManager.RaiseRoutedEvent(target, UIElement.PreviewMouseDownEvent, UIElement.MouseDownEvent, args);
	}

	private void OnMouseButtonReleased(Point2F position, GUIMouseButton button, GUIModifierKeys modifiers)
	{
		if (mRoot == null)
			return;

		// Determine target
		UIElement target = MouseCapture.CapturedElement;
		if (target == null)
		{
			// Check dialogs first (they're rendered on top and block input)
			target = DialogManager.HitTestDialogs(position);
			if (target == null)
				target = mRoot.HitTest(ScreenToRootLocal(position));
		}

		if (target == null)
			return;

		// Raise events
		let args = scope MouseButtonEventArgs(UIElement.PreviewMouseUpEvent);
		args.ScreenPosition = position;
		args.Position = target.TransformFromRoot(position);
		args.Button = button;
		args.Modifiers = modifiers;

		EventManager.RaiseRoutedEvent(target, UIElement.PreviewMouseUpEvent, UIElement.MouseUpEvent, args);
	}

	private void OnMouseWheel(Point2F position, float deltaX, float deltaY)
	{
		if (mRoot == null)
			return;

		UIElement target = MouseCapture.CapturedElement;
		if (target == null)
		{
			// Check dialogs first (they're rendered on top and block input)
			target = DialogManager.HitTestDialogs(position);
			if (target == null)
				target = mRoot.HitTest(ScreenToRootLocal(position));
		}

		if (target == null)
			return;

		let args = scope MouseWheelEventArgs(UIElement.PreviewMouseWheelEvent);
		args.ScreenPosition = position;
		args.Position = target.TransformFromRoot(position);
		args.DeltaX = deltaX;
		args.DeltaY = deltaY;
		args.Modifiers = mInput.CurrentModifiers;

		EventManager.RaiseRoutedEvent(target, UIElement.PreviewMouseWheelEvent, UIElement.MouseWheelEvent, args);
	}

	private void OnKeyPressed(GUIKey key, GUIModifierKeys modifiers, bool isRepeat)
	{
		let target = FocusManager.FocusedElement;
		if (target == null)
			return;

		// Handle Tab navigation
		if (key == .Tab && !isRepeat)
		{
			let direction = modifiers.Shift ? FocusNavigationDirection.Previous : FocusNavigationDirection.Next;
			if (FocusManager.MoveFocus(direction))
				return;
		}

		let args = scope KeyEventArgs(UIElement.PreviewKeyDownEvent);
		args.Key = key;
		args.Modifiers = modifiers;
		args.IsRepeat = isRepeat;

		EventManager.RaiseRoutedEvent(target, UIElement.PreviewKeyDownEvent, UIElement.KeyDownEvent, args);
	}

	private void OnKeyReleased(GUIKey key, GUIModifierKeys modifiers, bool isRepeat)
	{
		let target = FocusManager.FocusedElement;
		if (target == null)
			return;

		let args = scope KeyEventArgs(UIElement.PreviewKeyUpEvent);
		args.Key = key;
		args.Modifiers = modifiers;
		args.IsRepeat = false;

		EventManager.RaiseRoutedEvent(target, UIElement.PreviewKeyUpEvent, UIElement.KeyUpEvent, args);
	}

	private void OnTextInput(StringView text)
	{
		let target = FocusManager.FocusedElement;
		if (target == null)
			return;

		let args = scope TextInputEventArgs(UIElement.PreviewTextInputEvent, text);

		EventManager.RaiseRoutedEvent(target, UIElement.PreviewTextInputEvent, UIElement.TextInputEvent, args);
	}

	private void UpdateMouseOver(UIElement newTarget, Point2F position)
	{
		if (newTarget == mMouseDirectlyOver)
			return;

		let oldDirectlyOver = mMouseDirectlyOver;
		mMouseDirectlyOver = newTarget;

		// Update IsMouseDirectlyOver
		if (oldDirectlyOver != null)
			oldDirectlyOver.IsMouseDirectlyOver = false;
		if (newTarget != null)
			newTarget.IsMouseDirectlyOver = true;

		// Build ancestor chains
		let oldChain = scope System.Collections.List<UIElement>();
		let newChain = scope System.Collections.List<UIElement>();

		var current = oldDirectlyOver;
		while (current != null)
		{
			oldChain.Add(current);
			current = current.VisualParent;
		}

		current = newTarget;
		while (current != null)
		{
			newChain.Add(current);
			current = current.VisualParent;
		}

		// Raise MouseLeave for elements no longer under mouse
		for (let element in oldChain)
		{
			if (!newChain.Contains(element))
			{
				let args = scope MouseEventArgs(UIElement.MouseLeaveEvent);
				args.ScreenPosition = position;
				args.Position = element.TransformFromRoot(position);
				element.OnMouseLeave(args);
				element.RaiseEvent(args);
			}
		}

		// Raise MouseEnter for newly entered elements
		for (var i = newChain.Count - 1; i >= 0; i--)
		{
			let element = newChain[i];
			if (!oldChain.Contains(element))
			{
				let args = scope MouseEventArgs(UIElement.MouseEnterEvent);
				args.ScreenPosition = position;
				args.Position = element.TransformFromRoot(position);
				element.OnMouseEnter(args);
				element.RaiseEvent(args);
			}
		}
	}
}
