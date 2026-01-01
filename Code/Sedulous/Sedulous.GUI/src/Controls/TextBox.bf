namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

delegate void TextBoxTextChangedHandler(TextBox sender, StringView text);

class TextBox : FrameworkElement
{
	private String mText = new .() ~ delete _;
	private int32 mCaretPosition = 0;
	private int32 mSelectionStart = -1;
	private int32 mSelectionEnd = -1;
	private float mCaretBlinkTime = 0;
	private bool mCaretVisible = true;
	private float mScrollOffset = 0;

	public Event<TextBoxTextChangedHandler> TextChanged ~ _.Dispose();

	public StringView Text
	{
		get => mText;
		set
		{
			mText.Set(value);
			mCaretPosition = Math.Min(mCaretPosition, (int32)mText.Length);
			ClearSelection();
			TextChanged.Invoke(this, mText);
			InvalidateMeasure();
		}
	}

	public IFont Font => ThemeManager.GetDefaultFont();
	public bool IsReadOnly = false;
	public int32 MaxLength = -1; // -1 = unlimited

	public String PlaceholderText ~ delete _;

	// === Theme Properties ===
	public Color Background => ThemeManager.TextBoxTheme?.GetBackground(IsEnabled, IsMouseOver, false, IsFocused) ?? Color(40, 40, 40, 255);
	public Color Foreground => ThemeManager.TextBoxTheme?.GetForeground(IsEnabled, IsMouseOver, false, IsFocused) ?? Color(255, 255, 255, 255);
	public Color BorderColor => ThemeManager.TextBoxTheme?.GetBorderColor(IsEnabled, IsMouseOver, false, IsFocused) ?? Color(100, 100, 100, 255);
	public Color CaretColor => ThemeManager.TextBoxTheme?.CaretColor ?? Color(255, 255, 255, 255);
	public Color SelectionColor => ThemeManager.TextBoxTheme?.SelectionColor ?? Color(0, 120, 212, 128);
	public Color PlaceholderColor => ThemeManager.TextBoxTheme?.PlaceholderColor ?? Color(128, 128, 128, 255);
	public Thickness Padding => ThemeManager.TextBoxTheme?.Padding ?? .(6, 4, 6, 4);

	public this()
	{
		Focusable = true;

		AddHandler(UIElement.MouseDownEvent, new => OnMouseDown);
		AddHandler(UIElement.KeyDownEvent, new => OnKeyDown);
		AddHandler(UIElement.TextInputEvent, new => OnTextInput);
	}

	private void OnMouseDown(UIElement sender, RoutedEventArgs e)
	{
		if (let mouseArgs = e as MouseButtonEventArgs)
		{
			if (mouseArgs.Button == .Left)
			{
				Focus();
				let pos = mouseArgs.GetPosition(this);
				mCaretPosition = GetCharacterIndexAtPosition(pos);
				ClearSelection();
				mCaretVisible = true;
				mCaretBlinkTime = 0;
			}
		}
	}

	private void OnKeyDown(UIElement sender, RoutedEventArgs e)
	{
		if (let keyArgs = e as KeyEventArgs)
		{
			mCaretVisible = true;
			mCaretBlinkTime = 0;

			switch (keyArgs.Key)
			{
			case .Left:
				if (mCaretPosition > 0)
					mCaretPosition--;
				if (!keyArgs.Modifiers.Shift)
					ClearSelection();
				keyArgs.Handled = true;

			case .Right:
				if (mCaretPosition < mText.Length)
					mCaretPosition++;
				if (!keyArgs.Modifiers.Shift)
					ClearSelection();
				keyArgs.Handled = true;

			case .Home:
				mCaretPosition = 0;
				if (!keyArgs.Modifiers.Shift)
					ClearSelection();
				keyArgs.Handled = true;

			case .End:
				mCaretPosition = (int32)mText.Length;
				if (!keyArgs.Modifiers.Shift)
					ClearSelection();
				keyArgs.Handled = true;

			case .Backspace:
				if (!IsReadOnly)
				{
					if (HasSelection)
						DeleteSelection();
					else if (mCaretPosition > 0)
					{
						mText.Remove(mCaretPosition - 1, 1);
						mCaretPosition--;
						TextChanged.Invoke(this, mText);
					}
				}
				keyArgs.Handled = true;

			case .Delete:
				if (!IsReadOnly)
				{
					if (HasSelection)
						DeleteSelection();
					else if (mCaretPosition < mText.Length)
					{
						mText.Remove(mCaretPosition, 1);
						TextChanged.Invoke(this, mText);
					}
				}
				keyArgs.Handled = true;

			case .A:
				if (keyArgs.Modifiers.Control)
				{
					mSelectionStart = 0;
					mSelectionEnd = (int32)mText.Length;
					mCaretPosition = (int32)mText.Length;
					keyArgs.Handled = true;
				}

			case .C:
				if (keyArgs.Modifiers.Control && HasSelection)
				{
					// Copy selection to clipboard (if input provider supports it)
					keyArgs.Handled = true;
				}

			case .V:
				if (keyArgs.Modifiers.Control && !IsReadOnly)
				{
					// Paste from clipboard (if input provider supports it)
					keyArgs.Handled = true;
				}

			case .X:
				if (keyArgs.Modifiers.Control && HasSelection && !IsReadOnly)
				{
					// Cut selection
					DeleteSelection();
					keyArgs.Handled = true;
				}

			default:
			}
		}
	}

	private void OnTextInput(UIElement sender, RoutedEventArgs e)
	{
		if (IsReadOnly)
			return;

		if (let textArgs = e as TextInputEventArgs)
		{
			if (HasSelection)
				DeleteSelection();

			if (MaxLength >= 0 && mText.Length + textArgs.Text.Length > MaxLength)
				return;

			mText.Insert(mCaretPosition, textArgs.Text);
			mCaretPosition += (int32)textArgs.Text.Length;
			TextChanged.Invoke(this, mText);
			textArgs.Handled = true;
		}
	}

	private bool HasSelection => mSelectionStart >= 0 && mSelectionEnd >= 0 && mSelectionStart != mSelectionEnd;

	private void ClearSelection()
	{
		mSelectionStart = -1;
		mSelectionEnd = -1;
	}

	private void DeleteSelection()
	{
		if (!HasSelection)
			return;

		let start = Math.Min(mSelectionStart, mSelectionEnd);
		let end = Math.Max(mSelectionStart, mSelectionEnd);
		mText.Remove(start, end - start);
		mCaretPosition = start;
		ClearSelection();
		TextChanged.Invoke(this, mText);
	}

	private int32 GetCharacterIndexAtPosition(Point2F pos)
	{
		let font = Font;
		if (font == null)
			return 0;

		let padding = Padding;
		let x = pos.X - padding.Left + mScrollOffset;
		var totalWidth = 0.0f;

		for (var i < mText.Length)
		{
			let charWidth = font.GetGlyphMetrics(mText[i]).Advance;
			if (x < totalWidth + charWidth / 2)
				return (int32)i;
			totalWidth += charWidth;
		}

		return (int32)mText.Length;
	}

	private float GetCaretXPosition()
	{
		let font = Font;
		if (font == null || mCaretPosition == 0)
			return 0;

		return font.MeasureString(StringView(mText, 0, mCaretPosition)).Width;
	}

	protected override Size2F MeasureOverride(Size2F availableSize)
	{
		let font = Font;
		let padding = Padding;

		if (font == null)
			return Size2F(100, 20 + padding.VerticalThickness);

		return Size2F(
			availableSize.Width,
			font.Metrics.LineHeight + padding.VerticalThickness
		);
	}

	protected override void OnRender(IUIRenderer renderer)
	{
		let padding = Padding;
		let font = Font;
		let cornerRadius = ThemeManager.TextBoxTheme?.CornerRadius ?? 4.0f;

		// Background
		let rect = RectangleF(0, 0, ActualWidth, ActualHeight);
		if (cornerRadius > 0)
			renderer.FillRoundedRectangle(rect, Background, cornerRadius);
		else
			renderer.FillRectangle(rect, Background);

		// Border
		if (cornerRadius > 0)
			renderer.DrawRoundedRectangle(rect, BorderColor, cornerRadius, 1);
		else
			renderer.DrawRectangle(rect, BorderColor, 1);

		// Clip content area
		let contentRect = RectangleF(padding.Left, padding.Top,
			ActualWidth - padding.HorizontalThickness,
			ActualHeight - padding.VerticalThickness);
		renderer.PushClipRect(contentRect);

		// Selection background
		if (HasSelection && font != null)
		{
			let start = Math.Min(mSelectionStart, mSelectionEnd);
			let end = Math.Max(mSelectionStart, mSelectionEnd);
			let startX = font.MeasureString(StringView(mText, 0, start)).Width - mScrollOffset;
			let endX = font.MeasureString(StringView(mText, 0, end)).Width - mScrollOffset;

			renderer.FillRectangle(
				RectangleF(padding.Left + startX, padding.Top, endX - startX, font.Metrics.LineHeight),
				SelectionColor
			);
		}

		// Text or placeholder
		if (font != null)
		{
			let textPos = Point2F(padding.Left - mScrollOffset, padding.Top);

			if (mText.IsEmpty && PlaceholderText != null && !IsFocused)
			{
				renderer.DrawText(PlaceholderText, font, Point2F(padding.Left, padding.Top), PlaceholderColor);
			}
			else
			{
				renderer.DrawText(mText, font, textPos, Foreground);
			}
		}

		// Caret
		if (IsFocused && mCaretVisible && font != null)
		{
			let caretX = padding.Left + GetCaretXPosition() - mScrollOffset;
			renderer.FillRectangle(
				RectangleF(caretX, padding.Top, 1, font.Metrics.LineHeight),
				CaretColor
			);
		}

		renderer.PopClipRect();
	}
}
