namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

struct Thickness
{
	public float Left;
	public float Top;
	public float Right;
	public float Bottom;

	public this()
	{
		Left = 0;
		Top = 0;
		Right = 0;
		Bottom = 0;
	}

	public this(float uniform)
	{
		Left = uniform;
		Top = uniform;
		Right = uniform;
		Bottom = uniform;
	}

	public this(float horizontal, float vertical)
	{
		Left = horizontal;
		Right = horizontal;
		Top = vertical;
		Bottom = vertical;
	}

	public this(float left, float top, float right, float bottom)
	{
		Left = left;
		Top = top;
		Right = right;
		Bottom = bottom;
	}

	public Size2F Size => Size2F(Left + Right, Top + Bottom);

	public float HorizontalThickness => Left + Right;
	public float VerticalThickness => Top + Bottom;

	public static Thickness Zero => .(0);

	public static bool operator ==(Thickness a, Thickness b)
	{
		return a.Left == b.Left && a.Top == b.Top && a.Right == b.Right && a.Bottom == b.Bottom;
	}

	public static bool operator !=(Thickness a, Thickness b)
	{
		return !(a == b);
	}

	public static Thickness operator +(Thickness a, Thickness b)
	{
		return .(a.Left + b.Left, a.Top + b.Top, a.Right + b.Right, a.Bottom + b.Bottom);
	}

	public static Thickness operator -(Thickness a, Thickness b)
	{
		return .(a.Left - b.Left, a.Top - b.Top, a.Right - b.Right, a.Bottom - b.Bottom);
	}

	public override void ToString(String strBuffer)
	{
		strBuffer.AppendF("{},{},{},{}", Left, Top, Right, Bottom);
	}
}
