namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;
using System.Collections;

static class DialogManager
{
	private static List<Dialog> sOpenDialogs = new .() ~ delete _;

	public static bool HasOpenDialogs => !sOpenDialogs.IsEmpty;

	public static Dialog TopDialog => sOpenDialogs.IsEmpty ? null : sOpenDialogs[sOpenDialogs.Count - 1];

	public static void Show(Dialog dialog)
	{
		if (dialog != null && !sOpenDialogs.Contains(dialog))
			sOpenDialogs.Add(dialog);
	}

	public static void Close(Dialog dialog)
	{
		sOpenDialogs.Remove(dialog);
	}

	public static void CloseAll()
	{
		while (!sOpenDialogs.IsEmpty)
		{
			let dialog = sOpenDialogs[sOpenDialogs.Count - 1];
			dialog.[Friend]Result = .Cancel;
			dialog.Close();
		}
	}

	public static void UpdateLayout(Size2F viewportSize)
	{
		for (let dialog in sOpenDialogs)
		{
			dialog.Measure(viewportSize);

			// Center dialog
			let dialogX = (viewportSize.Width - dialog.DesiredSize.Width) / 2;
			let dialogY = (viewportSize.Height - dialog.DesiredSize.Height) / 2;

			dialog.Arrange(RectangleF(dialogX, dialogY, dialog.DesiredSize.Width, dialog.DesiredSize.Height));
		}
	}

	public static void RenderDialogs(IUIRenderer renderer, Size2F viewportSize)
	{
		for (let dialog in sOpenDialogs)
		{
			// Render overlay
			renderer.FillRectangle(RectangleF(0, 0, viewportSize.Width, viewportSize.Height), dialog.OverlayColor);

			// Render dialog
			renderer.PushTransform(Point2F(dialog.Bounds.X, dialog.Bounds.Y));
			dialog.Render(renderer);
			renderer.PopTransform();
		}
	}

	public static UIElement HitTestDialogs(Point2F point)
	{
		if (sOpenDialogs.IsEmpty)
			return null;

		// Only topmost dialog is interactive; clicking overlay doesn't pass through
		let dialog = sOpenDialogs[sOpenDialogs.Count - 1];
		let localPoint = Point2F(point.X - dialog.Bounds.X, point.Y - dialog.Bounds.Y);

		let hit = dialog.HitTest(localPoint);
		if (hit != null)
			return hit;

		// Return the dialog itself to block input to elements below
		// (clicking on overlay should not pass through)
		return dialog;
	}
}
