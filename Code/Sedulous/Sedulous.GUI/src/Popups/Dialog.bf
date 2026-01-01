namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;
using System.Collections;

delegate void DialogClosedHandler(Dialog dialog, DialogResult result);

class Dialog : Border
{
	public Event<DialogClosedHandler> Closed /*~ _.Dispose()*/;

	private TextBlock mTitleBlock /*~ delete _*/;
	private StackPanel mContentArea /*~ delete _*/;
	private StackPanel mButtonArea /*~ delete _*/;
	private StackPanel mMainPanel /*~ delete _*/;
	private List<delegate void(Button)> mButtonClickHandlers = new .() /*~ DeleteContainerAndItems!(_)*/~ delete _;

	public DialogResult Result { get; private set; } = .None;

	public StringView Title
	{
		get => mTitleBlock.Text;
		set => mTitleBlock.Text = value;
	}

	public Color OverlayColor = Color(0, 0, 0, 128);

	public this()
	{
		// Apply dialog theme
		let theme = ThemeManager.DialogTheme;
		if (theme != null)
		{
			BackgroundOverride = theme.Background;
			BorderBrushOverride = theme.BorderColor;
			BorderThicknessOverride = theme.BorderThickness;
			CornerRadiusOverride = theme.CornerRadius;
			PaddingOverride = theme.Padding;
			OverlayColor = theme.OverlayColor;
		}
		else
		{
			BackgroundOverride = Color(50, 50, 50, 255);
			BorderBrushOverride = Color(80, 80, 80, 255);
			BorderThicknessOverride = .(1);
			CornerRadiusOverride = 8;
			PaddingOverride = .(16);
		}

		// Build dialog structure
		mTitleBlock = new TextBlock();
		mTitleBlock.ForegroundOverride = ThemeManager.DialogTheme?.TitleColor ?? Color(255, 255, 255, 255);
		mTitleBlock.Margin = .(0, 0, 0, 12);

		mContentArea = new StackPanel();
		mContentArea.Margin = .(0, 0, 0, 16);

		mButtonArea = new StackPanel();
		mButtonArea.Orientation = .Horizontal;
		mButtonArea.HorizontalAlignment = .Right;
		mButtonArea.Spacing = 8;

		mMainPanel = new StackPanel();
		mMainPanel.AddChild(mTitleBlock);
		mMainPanel.AddChild(mContentArea);
		mMainPanel.AddChild(mButtonArea);

		Child = mMainPanel;
	}

	public void SetContent(UIElement content)
	{
		mContentArea.ClearChildren();
		if (content != null)
			mContentArea.AddChild(content);
	}

	public Button AddButton(StringView text, DialogResult result)
	{
		let button = new Button();
		let textBlock = new TextBlock();
		textBlock.Text = text;
		button.Child = textBlock;
		button.MinWidth = 80;

		delegate void(Button) clickHandler = new [=result, &](btn) =>
		{
			Result = result;
			Close();
		};
		mButtonClickHandlers.Add(clickHandler);
		button.Click.Add(clickHandler);

		mButtonArea.AddChild(button);
		return button;
	}

	public void Show()
	{
		Result = .None;
		DialogManager.Show(this);
	}

	public void Close()
	{
		// Release mouse capture and focus if held by any element in this dialog
		// This prevents crashes when dialog is deleted while an element has capture/focus
		MouseCapture.ReleaseIfCapturedByOrDescendantOf(this);
		FocusManager.ClearFocusIfDescendantOf(this);

		DialogManager.Close(this);
		Closed.Invoke(this, Result);
	}
}
