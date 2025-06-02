using System;
// Copyright (c) .NET Foundation and Contributors (https://dotnetfoundation.org/ & https://stride3d.net) and Silicon Studio Corp. (https://www.siliconstudio.co.jp)
// Distributed under the MIT license. See the LICENSE.md file in the project root for more information.

namespace Sedulous.Mathematics;

/// <summary>
/// Represents a color in the form of Hue, Saturation, Value, Alpha.
/// </summary>
[CRepr]public struct ColorHSV : IEquatable<ColorHSV>
{
    /// <summary>
    /// The Hue of the color.
    /// </summary>
    public float H;

    /// <summary>
    /// The Saturation of the color.
    /// </summary>
    public float S;

    /// <summary>
    /// The Value of the color.
    /// </summary>
    public float V;

    /// <summary>
    /// The alpha component of the color.
    /// </summary>
    public float A;

    /// <summary>
    /// Initializes a new instance of the <see cref="ColorHSV"/> struct.
    /// </summary>
    /// <param name="h">The h.</param>
    /// <param name="s">The s.</param>
    /// <param name="v">The v.</param>
    /// <param name="a">A.</param>
    public this(float h, float s, float v, float a)
    {
        H = h;
        S = s;
        V = v;
        A = a;
    }

    /// <summary>
    /// Converts the color into a three component vector.
    /// </summary>
    /// <returns>A three component vector containing the red, green, and blue components of the color.</returns>
    public Color4 ToColor()
    {
        float hdiv = H / 60;
        int32 hi = (int32)hdiv;
        float f = hdiv - hi;

        float p = V * (1 - S);
        float q = V * (1 - (S * f));
        float t = V * (1 - (S * (1 - f)));

		switch (hi)
		{
		    case 0: return Color4(V, t, p, A);
		    case 1: return Color4(q, V, p, A);
		    case 2: return Color4(p, V, t, A);
		    case 3: return Color4(p, q, V, A);
		    case 4: return Color4(t, p, V, A);
		    default: return Color4(V, p, q, A);
		}
    }

    /// <summary>
    /// Converts the color into a HSV color.
    /// </summary>
    /// <param name="color">The color.</param>
    /// <returns>A HSV color</returns>
    public static ColorHSV FromColor(Color4 color)
    {
        float max = Math.Max(color.R, Math.Max(color.G, color.B));
        float min = Math.Min(color.R, Math.Min(color.G, color.B));

        float delta = max - min;
        float h = 0.0f;

        if (delta > 0.0f)
        {
            if (color.R >= max)
                h = (color.G - color.B) / delta;
            else if (color.G >= max)
                h = ((color.B - color.R) / delta) + 2.0f;
            else
                h = ((color.R - color.G) / delta) + 4.0f;
            h *= 60.0f;

            if (h < 0)
                h += 360f;
        }

        float s = MathUtil.IsZero(max) ? 0.0f : delta / max;

        return ColorHSV(h, s, max, color.A);
    }

    /// <inheritdoc/>
    public bool Equals(ColorHSV other)
    {
        return other.H.Equals(H) && other.S.Equals(S) && other.V.Equals(V) && other.A.Equals(A);
    }

    /// <inheritdoc/>
    public int GetHashCode()
    {
		int hash = 17;
		hash = HashCode.Mix(hash, H.GetHashCode());
		hash = HashCode.Mix(hash, S.GetHashCode());
		hash = HashCode.Mix(hash, V.GetHashCode());
		hash = HashCode.Mix(hash, A.GetHashCode());
        return hash;
    }
    
    /// <summary>
    /// Returns a <see cref="string"/> that represents this instance.
    /// </summary>
    /// <returns>
    /// A <see cref="string"/> that represents this instance.
    /// </returns>
    public override void ToString(String strBuffer) => strBuffer.Append("TODO");

    /// <summary>
    /// Deconstructs the vector's components into named variables.
    /// </summary>
    /// <param name="h">The H component</param>
    /// <param name="s">The S component</param>
    /// <param name="v">The V component</param>
    /// <param name="a">The A component</param>
    public void Deconstruct(out float h, out float s, out float v, out float a)
    {
        h = H;
        s = S;
        v = V;
        a = A;
    }
}
