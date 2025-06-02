// Copyright (c) .NET Foundation and Contributors (https://dotnetfoundation.org/ & https://stride3d.net) and Silicon Studio Corp. (https://www.siliconstudio.co.jp)
// Distributed under the MIT license. See the LICENSE.md file in the project root for more information.

using System;

namespace Sedulous.Mathematics;

/// <summary>
/// Represents a 32-bit color (4 bytes) in the form of RGBA (in uint8 order: R, G, B, A).
/// </summary>
[CRepr] public struct Color : IEquatable<Color>
{
	/// <summary>
	/// The red component of the color.
	/// </summary>
	public uint8 R;

	/// <summary>
	/// The green component of the color.
	/// </summary>
	public uint8 G;

	/// <summary>
	/// The blue component of the color.
	/// </summary>
	public uint8 B;

	/// <summary>
	/// The alpha component of the color.
	/// </summary>
	public uint8 A;

	/// <summary>
	/// Initializes a new instance of the <see cref="Color"/> struct.
	/// </summary>
	/// <param name="value">The value that will be assigned to all components.</param>
	public this(uint8 value)
	{
		R = value;
		G = value;
		B = value;
		A = value;
	}

	/// <summary>
	/// Initializes a new instance of the <see cref="Color"/> struct.
	/// </summary>
	/// <param name="value">The value that will be assigned to all components.</param>
	public this(float value) : this(ToByte(value))
	{
	}

	/// <summary>
	/// Initializes a new instance of the <see cref="Color"/> struct.
	/// </summary>
	/// <param name="red">The red component of the color.</param>
	/// <param name="green">The green component of the color.</param>
	/// <param name="blue">The blue component of the color.</param>
	/// <param name="alpha">The alpha component of the color.</param>
	public this(uint8 red, uint8 green, uint8 blue, uint8 alpha)
	{
		R = red;
		G = green;
		B = blue;
		A = alpha;
	}

	/// <summary>
	/// Initializes a new instance of the <see cref="Color"/> struct.  Alpha is set to 255.
	/// </summary>
	/// <param name="red">The red component of the color.</param>
	/// <param name="green">The green component of the color.</param>
	/// <param name="blue">The blue component of the color.</param>
	public this(uint8 red, uint8 green, uint8 blue)
	{
		R = red;
		G = green;
		B = blue;
		A = 255;
	}

	/// <summary>
	/// Initializes a new instance of the <see cref="Color"/> struct.
	/// </summary>
	/// <param name="red">The red component of the color.</param>
	/// <param name="green">The green component of the color.</param>
	/// <param name="blue">The blue component of the color.</param>
	/// <param name="alpha">The alpha component of the color.</param>
	public this(float red, float green, float blue, float alpha)
	{
		R = ToByte(red);
		G = ToByte(green);
		B = ToByte(blue);
		A = ToByte(alpha);
	}

	/// <summary>
	/// Initializes a new instance of the <see cref="Color"/> struct.  Alpha is set to 255.
	/// </summary>
	/// <param name="red">The red component of the color.</param>
	/// <param name="green">The green component of the color.</param>
	/// <param name="blue">The blue component of the color.</param>
	public this(float red, float green, float blue)
	{
		R = ToByte(red);
		G = ToByte(green);
		B = ToByte(blue);
		A = 255;
	}

	/// <summary>
	/// Initializes a new instance of the <see cref="Color"/> struct.
	/// </summary>
	/// <param name="value">The red, green, blue, and alpha components of the color.</param>
	public this(Vector4 value)
	{
		R = ToByte(value.X);
		G = ToByte(value.Y);
		B = ToByte(value.Z);
		A = ToByte(value.W);
	}

	/// <summary>
	/// Initializes a new instance of the <see cref="Color"/> struct.
	/// </summary>
	/// <param name="value">The red, green, and blue components of the color.</param>
	/// <param name="alpha">The alpha component of the color.</param>
	public this(Vector3 value, float alpha)
	{
		R = ToByte(value.X);
		G = ToByte(value.Y);
		B = ToByte(value.Z);
		A = ToByte(alpha);
	}

	/// <summary>
	/// Initializes a new instance of the <see cref="Color"/> struct. Alpha is set to 255.
	/// </summary>
	/// <param name="value">The red, green, and blue components of the color.</param>
	public this(Vector3 value)
	{
		R = ToByte(value.X);
		G = ToByte(value.Y);
		B = ToByte(value.Z);
		A = 255;
	}

	/// <summary>
	/// Initializes a new instance of the <see cref="Color"/> struct.
	/// </summary>
	/// <param name="rgba">A packed integer containing all four color components in RGBA order.</param>
	public this(uint32 rgba)
	{
		A = (uint8)((rgba >> 24) & 255);
		B = (uint8)((rgba >> 16) & 255);
		G = (uint8)((rgba >> 8) & 255);
		R = (uint8)(rgba & 255);
	}

	/// <summary>
	/// Initializes a new instance of the <see cref="Color"/> struct.
	/// </summary>
	/// <param name="rgba">A packed integer containing all four color components in RGBA order.</param>
	public this(int32 rgba)
	{
		A = (uint8)((rgba >> 24) & 255);
		B = (uint8)((rgba >> 16) & 255);
		G = (uint8)((rgba >> 8) & 255);
		R = (uint8)(rgba & 255);
	}

	/// <summary>
	/// Gets or sets the component at the specified index.
	/// </summary>
	/// <value>The value of the red, green, blue, or alpha component, depending on the index.</value>
	/// <param name="index">The index of the component to access. Use 0 for the red(R) component, 1 for the green(G) component, 2 for the blue(B) component, and 3 for the alpha(A) component.</param>
	/// <returns>The value of the component at the specified index.</returns>
	/// <exception cref="System.ArgumentOutOfRangeException">Thrown when the <paramref name="index"/> is out of the range [0, 3].</exception>
	public uint8 this[int32 index]
	{
		get
		{
			switch (index)
			{
			case 0: return R;
			case 1: return G;
			case 2: return B;
			case 3: return A;
			default:
				Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(index)}: Indices for Color run from 0 to 3, inclusive.");
			}
		}

		set mut
		{
			switch (index)
			{
			case 0: R = value; break;
			case 1: G = value; break;
			case 2: B = value; break;
			case 3: A = value; break;
			default: Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(index)}:Indices for Color run from 0 to 3, inclusive.");
			}
		}
	}

	/// <summary>
	/// Converts the color into a packed integer.
	/// </summary>
	/// <returns>A packed integer containing all four color components.</returns>
	public int32 ToBgra()
	{
		int32 value = B;
		value |= (int32)G << 8;
		value |= (int32)R << 16;
		value |= (int32)A << 24;

		return value;
	}

	/// <summary>
	/// Converts the color into a packed integer.
	/// </summary>
	/// <returns>A packed integer containing all four color components.</returns>
	public int32 ToRgba()
	{
		int32 value = R;
		value |= (int32)G << 8;
		value |= (int32)B << 16;
		value |= (int32)A << 24;

		return value;
	}

	/// <summary>
	/// Converts the color into a packed integer.
	/// </summary>
	/// <returns>A packed integer containing all four color components.</returns>
	public int32 ToArgb()
	{
		int32 value = A;
		value |= (int32)R << 8;
		value |= (int32)G << 16;
		value |= (int32)B << 24;

		return value;
	}

	/// <summary>
	/// Converts the color into a packed integer.
	/// </summary>
	/// <returns>A packed integer containing all four color components.</returns>
	public int32 ToAbgr()
	{
		int32 value = A;
		value |= (int32)B << 8;
		value |= (int32)G << 16;
		value |= (int32)R << 24;

		return value;
	}

	/// <summary>
	/// Converts the color into a three component vector.
	/// </summary>
	/// <returns>A three component vector containing the red, green, and blue components of the color.</returns>
	public Vector3 ToVector3()
	{
		return Vector3(R / 255.0f, G / 255.0f, B / 255.0f);
	}

	/// <summary>
	/// Converts the color into a three component color.
	/// </summary>
	/// <returns>A three component color containing the red, green, and blue components of the color.</returns>
	public Color3 ToColor3()
	{
		return Color3(R / 255.0f, G / 255.0f, B / 255.0f);
	}

	/// <summary>
	/// Converts the color into a four component vector.
	/// </summary>
	/// <returns>A four component vector containing all four color components.</returns>
	public Vector4 ToVector4()
	{
		return Vector4(R / 255.0f, G / 255.0f, B / 255.0f, A / 255.0f);
	}

	/// <summary>
	/// Creates an array containing the elements of the color.
	/// </summary>
	/// <returns>A four-element array containing the components of the color in RGBA order.</returns>
	public uint8[4] ToArray()
	{
		return .(R, G, B, A);
	}

	/// <summary>
	/// Gets the brightness.
	/// </summary>
	/// <returns>The Hue-Saturation-Brightness (HSB) saturation for this <see cref="Color"/></returns>
	public float GetBrightness()
	{
		float r = R / 255.0f;
		float g = G / 255.0f;
		float b = B / 255.0f;

		float max, min;

		max = r;
		min = r;

		if (g > max) max = g;
		if (b > max) max = b;

		if (g < min) min = g;
		if (b < min) min = b;

		return (max + min) / 2;
	}

	/// <summary>
	/// Gets the hue.
	/// </summary>
	/// <returns>The Hue-Saturation-Brightness (HSB) saturation for this <see cref="Color"/></returns>
	public float GetHue()
	{
		if (R == G && G == B)
			return 0; // 0 makes as good an UNDEFINED value as any

		float r = R / 255.0f;
		float g = G / 255.0f;
		float b = B / 255.0f;

		float max, min;
		float delta;
		float hue = 0.0f;

		max = r;
		min = r;

		if (g > max) max = g;
		if (b > max) max = b;

		if (g < min) min = g;
		if (b < min) min = b;

		delta = max - min;

		if (r == max)
		{
			hue = (g - b) / delta;
		}
		else if (g == max)
		{
			hue = 2 + ((b - r) / delta);
		}
		else if (b == max)
		{
			hue = 4 + ((r - g) / delta);
		}
		hue *= 60;

		if (hue < 0.0f)
		{
			hue += 360.0f;
		}
		return hue;
	}

	/// <summary>
	/// Gets the saturation.
	/// </summary>
	/// <returns>The Hue-Saturation-Brightness (HSB) saturation for this <see cref="Color"/></returns>
	public float GetSaturation()
	{
		float r = R / 255.0f;
		float g = G / 255.0f;
		float b = B / 255.0f;

		float max, min;
		float l, s = 0;

		max = r;
		min = r;

		if (g > max) max = g;
		if (b > max) max = b;

		if (g < min) min = g;
		if (b < min) min = b;

		// if max == min, then there is no color and
		// the saturation is zero.
		if (max != min)
		{
			l = (max + min) / 2;

			if (l <= 0.5)
			{
				s = (max - min) / (max + min);
			}
			else
			{
				s = (max - min) / (2 - max - min);
			}
		}
		return s;
	}

	/// <summary>
	/// Adds two colors.
	/// </summary>
	/// <param name="left">The first color to add.</param>
	/// <param name="right">The second color to add.</param>
	/// <param name="result">When the method completes, completes the sum of the two colors.</param>
	public static void Add(Color left, Color right, out Color result)
	{
		result.A = (uint8)(left.A + right.A);
		result.R = (uint8)(left.R + right.R);
		result.G = (uint8)(left.G + right.G);
		result.B = (uint8)(left.B + right.B);
	}

	/// <summary>
	/// Adds two colors.
	/// </summary>
	/// <param name="left">The first color to add.</param>
	/// <param name="right">The second color to add.</param>
	/// <returns>The sum of the two colors.</returns>
	public static Color Add(Color left, Color right)
	{
		return Color((uint8)(left.R + right.R), (uint8)(left.G + right.G), (uint8)(left.B + right.B), (uint8)(left.A + right.A));
	}

	/// <summary>
	/// Subtracts two colors.
	/// </summary>
	/// <param name="left">The first color to subtract.</param>
	/// <param name="right">The second color to subtract.</param>
	/// <param name="result">WHen the method completes, contains the difference of the two colors.</param>
	public static void Subtract(Color left, Color right, out Color result)
	{
		result.A = (uint8)(left.A - right.A);
		result.R = (uint8)(left.R - right.R);
		result.G = (uint8)(left.G - right.G);
		result.B = (uint8)(left.B - right.B);
	}

	/// <summary>
	/// Subtracts two colors.
	/// </summary>
	/// <param name="left">The first color to subtract.</param>
	/// <param name="right">The second color to subtract</param>
	/// <returns>The difference of the two colors.</returns>
	public static Color Subtract(Color left, Color right)
	{
		return Color((uint8)(left.R - right.R), (uint8)(left.G - right.G), (uint8)(left.B - right.B), (uint8)(left.A - right.A));
	}

	/// <summary>
	/// Modulates two colors.
	/// </summary>
	/// <param name="left">The first color to modulate.</param>
	/// <param name="right">The second color to modulate.</param>
	/// <param name="result">When the method completes, contains the modulated color.</param>
	public static void Modulate(Color left, Color right, out Color result)
	{
		result.A = (uint8)(left.A * right.A / 255);
		result.R = (uint8)(left.R * right.R / 255);
		result.G = (uint8)(left.G * right.G / 255);
		result.B = (uint8)(left.B * right.B / 255);
	}

	/// <summary>
	/// Modulates two colors.
	/// </summary>
	/// <param name="left">The first color to modulate.</param>
	/// <param name="right">The second color to modulate.</param>
	/// <returns>The modulated color.</returns>
	public static Color Modulate(Color left, Color right)
	{
		return Color((uint8)(left.R * right.R / 255), (uint8)(left.G * right.G / 255), (uint8)(left.B * right.B / 255), (uint8)(left.A * right.A / 255));
	}

	/// <summary>
	/// Scales a color.
	/// </summary>
	/// <param name="value">The color to scale.</param>
	/// <param name="scale">The amount by which to scale.</param>
	/// <param name="result">When the method completes, contains the scaled color.</param>
	public static void Scale(Color value, float scale, out Color result)
	{
		result.A = (uint8)(value.A * scale);
		result.R = (uint8)(value.R * scale);
		result.G = (uint8)(value.G * scale);
		result.B = (uint8)(value.B * scale);
	}

	/// <summary>
	/// Scales a color.
	/// </summary>
	/// <param name="value">The color to scale.</param>
	/// <param name="scale">The amount by which to scale.</param>
	/// <returns>The scaled color.</returns>
	public static Color Scale(Color value, float scale)
	{
		return Color((uint8)(value.R * scale), (uint8)(value.G * scale), (uint8)(value.B * scale), (uint8)(value.A * scale));
	}

	/// <summary>
	/// Negates a color.
	/// </summary>
	/// <param name="value">The color to negate.</param>
	/// <param name="result">When the method completes, contains the negated color.</param>
	public static void Negate(Color value, out Color result)
	{
		result.A = (uint8)(255 - value.A);
		result.R = (uint8)(255 - value.R);
		result.G = (uint8)(255 - value.G);
		result.B = (uint8)(255 - value.B);
	}

	/// <summary>
	/// Negates a color.
	/// </summary>
	/// <param name="value">The color to negate.</param>
	/// <returns>The negated color.</returns>
	public static Color Negate(Color value)
	{
		return Color((uint8)(255 - value.R), (uint8)(255 - value.G), (uint8)(255 - value.B), (uint8)(255 - value.A));
	}

	/// <summary>
	/// Restricts a value to be within a specified range.
	/// </summary>
	/// <param name="value">The value to clamp.</param>
	/// <param name="min">The minimum value.</param>
	/// <param name="max">The maximum value.</param>
	/// <param name="result">When the method completes, contains the clamped value.</param>
	public static void Clamp(Color value, Color min, Color max, out Color result)
	{
		uint8 alpha = value.A;
		alpha = (alpha > max.A) ? max.A : alpha;
		alpha = (alpha < min.A) ? min.A : alpha;

		uint8 red = value.R;
		red = (red > max.R) ? max.R : red;
		red = (red < min.R) ? min.R : red;

		uint8 green = value.G;
		green = (green > max.G) ? max.G : green;
		green = (green < min.G) ? min.G : green;

		uint8 blue = value.B;
		blue = (blue > max.B) ? max.B : blue;
		blue = (blue < min.B) ? min.B : blue;

		result = Color(red, green, blue, alpha);
	}

	/// <summary>
	/// Converts the color from a packed BGRA integer.
	/// </summary>
	/// <param name="color">A packed integer containing all four color components in BGRA order</param>
	/// <returns>A color.</returns>
	public static Color FromBgra(int32 color)
	{
		return Color((uint8)((color >> 16) & 255), (uint8)((color >> 8) & 255), (uint8)(color & 255), (uint8)((color >> 24) & 255));
	}

	/// <summary>
	/// Converts the color from a packed BGRA integer.
	/// </summary>
	/// <param name="color">A packed integer containing all four color components in BGRA order</param>
	/// <returns>A color.</returns>
	public static Color FromBgra(uint32 color)
	{
		return FromBgra(((int32)color));
	}

	/// <summary>
	/// Converts the color from a packed ABGR integer.
	/// </summary>
	/// <param name="color">A packed integer containing all four color components in ABGR order</param>
	/// <returns>A color.</returns>
	public static Color FromAbgr(int32 color)
	{
		return Color((uint8)(color >> 24), (uint8)(color >> 16), (uint8)(color >> 8), (uint8)color);
	}

	/// <summary>
	/// Converts the color from a packed ABGR integer.
	/// </summary>
	/// <param name="color">A packed integer containing all four color components in ABGR order</param>
	/// <returns>A color.</returns>
	public static Color FromAbgr(uint32 color)
	{
		return FromAbgr(((int32)color));
	}

	/// <summary>
	/// Converts the color from a packed RGBA integer.
	/// </summary>
	/// <param name="color">A packed integer containing all four color components in RGBA order</param>
	/// <returns>A color.</returns>
	public static Color FromRgba(int32 color)
	{
		return Color(color);
	}

	/// <summary>
	/// Converts the color from a packed RGBA integer.
	/// </summary>
	/// <param name="color">A packed integer containing all four color components in RGBA order</param>
	/// <returns>A color.</returns>
	public static Color FromRgba(uint32 color)
	{
		return Color(color);
	}

	public uint32 ToPackedRGBA()
	{
		return ((uint32)R << 24)
			| ((uint32)G << 16)
			| ((uint32)B <<  8)
			|  (uint32)A;
	}

	/// <summary>
	/// Restricts a value to be within a specified range.
	/// </summary>
	/// <param name="value">The value to clamp.</param>
	/// <param name="min">The minimum value.</param>
	/// <param name="max">The maximum value.</param>
	/// <returns>The clamped value.</returns>
	public static Color Clamp(Color value, Color min, Color max)
	{
		Clamp(value, min, max, var result);
		return result;
	}

	/// <summary>
	/// Performs a linear interpolation between two colors.
	/// </summary>
	/// <param name="start">Start color.</param>
	/// <param name="end">End color.</param>
	/// <param name="amount">Value between 0 and 1 indicating the weight of <paramref name="end"/>.</param>
	/// <param name="result">When the method completes, contains the linear interpolation of the two colors.</param>
	/// <remarks>
	/// Passing <paramref name="amount"/> a value of 0 will cause <paramref name="start"/> to be returned; a value of 1 will cause <paramref name="end"/> to be returned.
	/// </remarks>
	public static void Lerp(Color start, Color end, float amount, out Color result)
	{
		result.R = MathUtil.Lerp(start.R, end.R, amount);
		result.G = MathUtil.Lerp(start.G, end.G, amount);
		result.B = MathUtil.Lerp(start.B, end.B, amount);
		result.A = MathUtil.Lerp(start.A, end.A, amount);
	}

	/// <summary>
	/// Performs a linear interpolation between two colors.
	/// </summary>
	/// <param name="start">Start color.</param>
	/// <param name="end">End color.</param>
	/// <param name="amount">Value between 0 and 1 indicating the weight of <paramref name="end"/>.</param>
	/// <returns>The linear interpolation of the two colors.</returns>
	/// <remarks>
	/// Passing <paramref name="amount"/> a value of 0 will cause <paramref name="start"/> to be returned; a value of 1 will cause <paramref name="end"/> to be returned.
	/// </remarks>
	public static Color Lerp(Color start, Color end, float amount)
	{
		Lerp(start, end, amount, var result);
		return result;
	}

	/// <summary>
	/// Performs a cubic interpolation between two colors.
	/// </summary>
	/// <param name="start">Start color.</param>
	/// <param name="end">End color.</param>
	/// <param name="amount">Value between 0 and 1 indicating the weight of <paramref name="end"/>.</param>
	/// <param name="result">When the method completes, contains the cubic interpolation of the two colors.</param>
	public static void SmoothStep(Color start, Color end, float amount, out Color result)
	{
		var amount;
		amount = MathUtil.SmoothStep(amount);
		Lerp(start, end, amount, out result);
	}

	/// <summary>
	/// Performs a cubic interpolation between two colors.
	/// </summary>
	/// <param name="start">Start color.</param>
	/// <param name="end">End color.</param>
	/// <param name="amount">Value between 0 and 1 indicating the weight of <paramref name="end"/>.</param>
	/// <returns>The cubic interpolation of the two colors.</returns>
	public static Color SmoothStep(Color start, Color end, float amount)
	{
		SmoothStep(start, end, amount, var result);
		return result;
	}

	/// <summary>
	/// Returns a color containing the smallest components of the specified colors.
	/// </summary>
	/// <param name="left">The first source color.</param>
	/// <param name="right">The second source color.</param>
	/// <param name="result">When the method completes, contains an new color composed of the largest components of the source colors.</param>
	public static void Max(Color left, Color right, out Color result)
	{
		result.A = (left.A > right.A) ? left.A : right.A;
		result.R = (left.R > right.R) ? left.R : right.R;
		result.G = (left.G > right.G) ? left.G : right.G;
		result.B = (left.B > right.B) ? left.B : right.B;
	}

	/// <summary>
	/// Returns a color containing the largest components of the specified colorss.
	/// </summary>
	/// <param name="left">The first source color.</param>
	/// <param name="right">The second source color.</param>
	/// <returns>A color containing the largest components of the source colors.</returns>
	public static Color Max(Color left, Color right)
	{
		Max(left, right, var result);
		return result;
	}

	/// <summary>
	/// Returns a color containing the smallest components of the specified colors.
	/// </summary>
	/// <param name="left">The first source color.</param>
	/// <param name="right">The second source color.</param>
	/// <param name="result">When the method completes, contains an new color composed of the smallest components of the source colors.</param>
	public static void Min(Color left, Color right, out Color result)
	{
		result.A = (left.A < right.A) ? left.A : right.A;
		result.R = (left.R < right.R) ? left.R : right.R;
		result.G = (left.G < right.G) ? left.G : right.G;
		result.B = (left.B < right.B) ? left.B : right.B;
	}

	/// <summary>
	/// Returns a color containing the smallest components of the specified colors.
	/// </summary>
	/// <param name="left">The first source color.</param>
	/// <param name="right">The second source color.</param>
	/// <returns>A color containing the smallest components of the source colors.</returns>
	public static Color Min(Color left, Color right)
	{
		Min(left, right, var result);
		return result;
	}

	/// <summary>
	/// Adjusts the contrast of a color.
	/// </summary>
	/// <param name="value">The color whose contrast is to be adjusted.</param>
	/// <param name="contrast">The amount by which to adjust the contrast.</param>
	/// <param name="result">When the method completes, contains the adjusted color.</param>
	public static void AdjustContrast(Color value, float contrast, out Color result)
	{
		result.A = value.A;
		result.R = ToByte(0.5f + (contrast * ((value.R / 255.0f) - 0.5f)));
		result.G = ToByte(0.5f + (contrast * ((value.G / 255.0f) - 0.5f)));
		result.B = ToByte(0.5f + (contrast * ((value.B / 255.0f) - 0.5f)));
	}

	/// <summary>
	/// Adjusts the contrast of a color.
	/// </summary>
	/// <param name="value">The color whose contrast is to be adjusted.</param>
	/// <param name="contrast">The amount by which to adjust the contrast.</param>
	/// <returns>The adjusted color.</returns>
	public static Color AdjustContrast(Color value, float contrast)
	{
		return Color(
			ToByte(0.5f + (contrast * ((value.R / 255.0f) - 0.5f))),
			ToByte(0.5f + (contrast * ((value.G / 255.0f) - 0.5f))),
			ToByte(0.5f + (contrast * ((value.B / 255.0f) - 0.5f))),
			value.A);
	}

	/// <summary>
	/// Adjusts the saturation of a color.
	/// </summary>
	/// <param name="value">The color whose saturation is to be adjusted.</param>
	/// <param name="saturation">The amount by which to adjust the saturation.</param>
	/// <param name="result">When the method completes, contains the adjusted color.</param>
	public static void AdjustSaturation(Color value, float saturation, out Color result)
	{
		float grey = (value.R / 255.0f * 0.2125f) + (value.G / 255.0f * 0.7154f) + (value.B / 255.0f * 0.0721f);

		result.A = value.A;
		result.R = ToByte(grey + (saturation * ((value.R / 255.0f) - grey)));
		result.G = ToByte(grey + (saturation * ((value.G / 255.0f) - grey)));
		result.B = ToByte(grey + (saturation * ((value.B / 255.0f) - grey)));
	}

	/// <summary>
	/// Adjusts the saturation of a color.
	/// </summary>
	/// <param name="value">The color whose saturation is to be adjusted.</param>
	/// <param name="saturation">The amount by which to adjust the saturation.</param>
	/// <returns>The adjusted color.</returns>
	public static Color AdjustSaturation(Color value, float saturation)
	{
		float grey = (value.R / 255.0f * 0.2125f) + (value.G / 255.0f * 0.7154f) + (value.B / 255.0f * 0.0721f);

		return Color(
			ToByte(grey + (saturation * ((value.R / 255.0f) - grey))),
			ToByte(grey + (saturation * ((value.G / 255.0f) - grey))),
			ToByte(grey + (saturation * ((value.B / 255.0f) - grey))),
			value.A);
	}

	/// <summary>
	/// Adds two colors.
	/// </summary>
	/// <param name="left">The first color to add.</param>
	/// <param name="right">The second color to add.</param>
	/// <returns>The sum of the two colors.</returns>
	public static Color operator +(Color left, Color right)
	{
		return Color((uint8)(left.R + right.R), (uint8)(left.G + right.G), (uint8)(left.B + right.B), (uint8)(left.A + right.A));
	}

	/// <summary>
	/// Assert a color (return it unchanged).
	/// </summary>
	/// <param name="value">The color to assert (unchanged).</param>
	/// <returns>The asserted (unchanged) color.</returns>
	public static Color operator +(Color value)
	{
		return value;
	}

	/// <summary>
	/// Subtracts two colors.
	/// </summary>
	/// <param name="left">The first color to subtract.</param>
	/// <param name="right">The second color to subtract.</param>
	/// <returns>The difference of the two colors.</returns>
	public static Color operator -(Color left, Color right)
	{
		return Color((uint8)(left.R - right.R), (uint8)(left.G - right.G), (uint8)(left.B - right.B), (uint8)(left.A - right.A));
	}

	/// <summary>
	/// Negates a color.
	/// </summary>
	/// <param name="value">The color to negate.</param>
	/// <returns>A negated color.</returns>
	public static Color operator -(Color value)
	{
		return Color(-value.R, -value.G, -value.B, -value.A);
	}

	/// <summary>
	/// Scales a color.
	/// </summary>
	/// <param name="scale">The factor by which to scale the color.</param>
	/// <param name="value">The color to scale.</param>
	/// <returns>The scaled color.</returns>
	public static Color operator *(float scale, Color value)
	{
		return Color((uint8)(value.R * scale), (uint8)(value.G * scale), (uint8)(value.B * scale), (uint8)(value.A * scale));
	}

	/// <summary>
	/// Scales a color.
	/// </summary>
	/// <param name="value">The factor by which to scale the color.</param>
	/// <param name="scale">The color to scale.</param>
	/// <returns>The scaled color.</returns>
	public static Color operator *(Color value, float scale)
	{
		return Color((uint8)(value.R * scale), (uint8)(value.G * scale), (uint8)(value.B * scale), (uint8)(value.A * scale));
	}

	/// <summary>
	/// Modulates two colors.
	/// </summary>
	/// <param name="left">The first color to modulate.</param>
	/// <param name="right">The second color to modulate.</param>
	/// <returns>The modulated color.</returns>
	public static Color operator *(Color left, Color right)
	{
		return Color((uint8)(left.R * right.R / 255.0f), (uint8)(left.G * right.G / 255.0f), (uint8)(left.B * right.B / 255.0f), (uint8)(left.A * right.A / 255.0f));
	}

	/// <summary>
	/// Tests for equality between two objects.
	/// </summary>
	/// <param name="left">The first value to compare.</param>
	/// <param name="right">The second value to compare.</param>
	/// <returns><c>true</c> if <paramref name="left"/> has the same value as <paramref name="right"/>; otherwise, <c>false</c>.</returns>
	public static bool operator ==(Color left, Color right)
	{
		return left.Equals(right);
	}

	/// <summary>
	/// Tests for inequality between two objects.
	/// </summary>
	/// <param name="left">The first value to compare.</param>
	/// <param name="right">The second value to compare.</param>
	/// <returns><c>true</c> if <paramref name="left"/> has a different value than <paramref name="right"/>; otherwise, <c>false</c>.</returns>
	public static bool operator !=(Color left, Color right)
	{
		return !left.Equals(right);
	}

	/// <summary>
	/// Performs an explicit conversion from <see cref="Color"/> to <see cref="Color3"/>.
	/// </summary>
	/// <param name="value">The value.</param>
	/// <returns>The result of the conversion.</returns>
	public static explicit operator Color3(Color value)
	{
		return value.ToColor3();
	}

	/// <summary>
	/// Performs an explicit conversion from <see cref="Color"/> to <see cref="Vector3"/>.
	/// </summary>
	/// <param name="value">The value.</param>
	/// <returns>The result of the conversion.</returns>
	public static explicit operator Vector3(Color value)
	{
		return Vector3(value.R / 255.0f, value.G / 255.0f, value.B / 255.0f);
	}

	/// <summary>
	/// Performs an explicit conversion from <see cref="Color"/> to <see cref="Vector4"/>.
	/// </summary>
	/// <param name="value">The value.</param>
	/// <returns>The result of the conversion.</returns>
	public static explicit operator Vector4(Color value)
	{
		return Vector4(value.R / 255.0f, value.G / 255.0f, value.B / 255.0f, value.A / 255.0f);
	}

	/// <summary>
	/// Convert this instance to a <see cref="Color4"/>
	/// </summary>
	/// <returns>The result of the conversion.</returns>
	public Color4 ToColor4()
	{
		return Color4(R / 255.0f, G / 255.0f, B / 255.0f, A / 255.0f);
	}

	/// <summary>
	/// Performs an implicit conversion from <see cref="Color"/> to <see cref="Color4"/>.
	/// </summary>
	/// <param name="value">The value.</param>
	/// <returns>The result of the conversion.</returns>
	public static implicit operator Color4(Color value)
	{
		return value.ToColor4();
	}

	/// <summary>
	/// Performs an explicit conversion from <see cref="Vector3"/> to <see cref="Color"/>.
	/// </summary>
	/// <param name="value">The value.</param>
	/// <returns>The result of the conversion.</returns>
	public static explicit operator Color(Vector3 value)
	{
		return Color(value.X, value.Y, value.Z, 1.0f);
	}

	/// <summary>
	/// Performs an explicit conversion from <see cref="Color3"/> to <see cref="Color"/>.
	/// </summary>
	/// <param name="value">The value.</param>
	/// <returns>The result of the conversion.</returns>
	public static explicit operator Color(Color3 value)
	{
		return Color(value.R, value.G, value.B, 1.0f);
	}

	/// <summary>
	/// Performs an explicit conversion from <see cref="Vector4"/> to <see cref="Color"/>.
	/// </summary>
	/// <param name="value">The value.</param>
	/// <returns>The result of the conversion.</returns>
	public static explicit operator Color(Vector4 value)
	{
		return Color(value.X, value.Y, value.Z, value.W);
	}

	/// <summary>
	/// Performs an explicit conversion from <see cref="Color4"/> to <see cref="Color"/>.
	/// </summary>
	/// <param name="value">The value.</param>
	/// <returns>The result of the conversion.</returns>
	public static explicit operator Color(Color4 value)
	{
		return Color(value.R, value.G, value.B, value.A);
	}

	/// <summary>
	/// Performs an explicit conversion from <see cref="int32"/> to <see cref="Color"/>.
	/// </summary>
	/// <param name="value">The value.</param>
	/// <returns>
	/// The result of the conversion.
	/// </returns>
	public static explicit operator int32(Color value)
	{
		return value.ToRgba();
	}

	/// <summary>
	/// Performs an explicit conversion from <see cref="int32"/> to <see cref="Color"/>.
	/// </summary>
	/// <param name="value">The value.</param>
	/// <returns>
	/// The result of the conversion.
	/// </returns>
	public static explicit operator Color(int32 value)
	{
		return Color(value);
	}

	/// <summary>
	/// Returns a <see cref="string"/> that represents this instance.
	/// </summary>
	/// <returns>
	/// A <see cref="string"/> that represents this instance.
	/// </returns>
	public override void ToString(String str)
	{
		ColorExtensions.RgbaToString(ToRgba(), str);
	}

	/// <summary>
	/// Returns a hash code for this instance.
	/// </summary>
	/// <returns>
	/// A hash code for this instance, suitable for use in hashing algorithms and data structures like a hash table.
	/// </returns>
	public int GetHashCode()
	{
		var hash = 17;
		hash = HashCode.Mix(hash, A);
		hash = HashCode.Mix(hash, R);
		hash = HashCode.Mix(hash, G);
		hash = HashCode.Mix(hash, B);
		return hash;
	}

	/// <summary>
	/// Determines whether the specified <see cref="Color"/> is equal to this instance.
	/// </summary>
	/// <param name="other">The <see cref="Color"/> to compare with this instance.</param>
	/// <returns>
	/// <c>true</c> if the specified <see cref="Color"/> is equal to this instance; otherwise, <c>false</c>.
	/// </returns>
	public bool Equals(Color other)
	{
		return R == other.R && G == other.G && B == other.B && A == other.A;
	}

	private static uint8 ToByte(float component)
	{
		var value = (int32)(component * 255.0f);
		return (uint8)(value < 0 ? 0 : value > 255 ? 255 : value);
	}
}
