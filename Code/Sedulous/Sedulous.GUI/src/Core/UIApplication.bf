namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

class UIApplication
{
	private UIElement mRoot;
	private IUIRenderer mRenderer;
	private IInputProvider mInput;
	private IFontProvider mFontProvider;
	private InputRouter mInputRouter ~ delete _;

	// === Properties ===
	public IUIRenderer Renderer => mRenderer;
	public IInputProvider Input => mInput;
	public IFontProvider FontProvider => mFontProvider;
	public UIElement Root => mRoot;

	// === Constructor ===
	public this(IUIRenderer renderer, IInputProvider input, IFontProvider fontProvider)
	{
		mRenderer = renderer;
		mInput = input;
		mFontProvider = fontProvider;

		// Initialize theme if not already done
		ThemeManager.Initialize();
	}

	public ~this()
	{
	}

	// === Root Element ===
	public void SetRoot(UIElement root)
	{
		mRoot = root;

		if (mInputRouter != null)
			delete mInputRouter;

		if (mRoot != null && mInput != null)
			mInputRouter = new InputRouter(mRoot, mInput);
	}

	// === Update ===
	public void Update(float deltaTime)
	{
		if (mRoot == null || mRenderer == null)
			return;

		// Layout pass
		let viewportSize = mRenderer.ViewportSize;
		mRoot.Measure(viewportSize);
		mRoot.Arrange(RectangleF(0, 0, viewportSize.Width, viewportSize.Height));

		// Update popups layout
		PopupManager.UpdateLayout(viewportSize);

		// Update dialogs layout
		DialogManager.UpdateLayout(viewportSize);
	}

	// === Render ===
	public void Render()
	{
		if (mRoot == null || mRenderer == null)
			return;

		mRenderer.BeginFrame();

		// Render main visual tree (push root's position as initial transform)
		mRenderer.PushTransform(.(mRoot.Bounds.X, mRoot.Bounds.Y));
		mRoot.Render(mRenderer);
		mRenderer.PopTransform();

		// Render popups
		PopupManager.RenderPopups(mRenderer);

		// Render dialogs (modal, on top)
		DialogManager.RenderDialogs(mRenderer, mRenderer.ViewportSize);

		mRenderer.EndFrame();
	}

	// === Hit Testing ===
	public UIElement HitTest(Point2F point)
	{
		// Check dialogs first (topmost)
		let dialogHit = DialogManager.HitTestDialogs(point);
		if (dialogHit != null)
			return dialogHit;

		// Check popups
		let popupHit = PopupManager.HitTestPopups(point);
		if (popupHit != null)
			return popupHit;

		// Check main visual tree
		if (mRoot != null)
			return mRoot.HitTest(point);

		return null;
	}
}
