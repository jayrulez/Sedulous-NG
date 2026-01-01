namespace Sedulous.GUI;

using System;

static class MouseCapture
{
	private static UIElement sCapturedElement;

	public static UIElement CapturedElement => sCapturedElement;

	public static bool IsCaptured => sCapturedElement != null;

	public static void Capture(UIElement element)
	{
		if (sCapturedElement == element)
			return;

		let oldCapture = sCapturedElement;
		sCapturedElement = element;

		if (oldCapture != null)
		{
			OnLostCapture(oldCapture);
		}

		if (element != null)
		{
			OnGotCapture(element);
		}
	}

	public static void Release()
	{
		Capture(null);
	}

	public static void ReleaseIfCapturedBy(UIElement element)
	{
		if (sCapturedElement == element)
			Release();
	}

	private static void OnGotCapture(UIElement element)
	{
		// Can raise a GotMouseCapture event if needed
	}

	private static void OnLostCapture(UIElement element)
	{
		// Can raise a LostMouseCapture event if needed
	}
}
