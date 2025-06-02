using System;
// Copyright (c) .NET Foundation and Contributors (https://dotnetfoundation.org/ & https://stride3d.net) and Silicon Studio Corp. (https://www.siliconstudio.co.jp)
// Distributed under the MIT license. See the LICENSE.md file in the project root for more information.
//
// Copyright (c) 2010-2011 SharpDX - Alexandre Mutel
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

namespace Sedulous.Mathematics;

/// <summary>
/// Represents a two dimensional mathematical vector with half-precision floats.
/// </summary>
[CRepr]public struct Half2 : IEquatable<Half2>
{
    /// <summary>
    /// The size of the <see cref="Half2"/> type, in bytes.
    /// </summary>
    public static readonly int32 SizeInBytes = sizeof(Half2);

    /// <summary>
    /// A <see cref="Half2"/> with all of its components set to zero.
    /// </summary>
    public static readonly Half2 Zero = .();

    /// <summary>
    /// The X unit <see cref="Half2"/> (1, 0).
    /// </summary>
    public static readonly Half2 UnitX = .(1.0f, 0.0f);

    /// <summary>
    /// The Y unit <see cref="Half2"/> (0, 1).
    /// </summary>
    public static readonly Half2 UnitY = .(0.0f, 1.0f);

    /// <summary>
    /// A <see cref="Half2"/> with all of its components set to one.
    /// </summary>
    public static readonly Half2 One = .(1.0f, 1.0f);

    /// <summary>
    /// Gets or sets the X component of the vector.
    /// </summary>
    /// <value>The X component of the vector.</value>
    public Half X;

    /// <summary>
    /// Gets or sets the Y component of the vector.
    /// </summary>
    /// <value>The Y component of the vector.</value>
    public Half Y;

    /// <summary>
    /// Initializes a new instance of the <see cref="Half2"/> structure.
    /// </summary>
    public this()
    {
        X = .(0);
        Y = .(0);
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Half2"/> structure.
    /// </summary>
    /// <param name="x">The X component.</param>
    /// <param name="y">The Y component.</param>
    public this(Half x, Half y)
    {
        X = x;
        Y = y;
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Half2"/> structure.
    /// </summary>
    /// <param name="value">The value to set for both the X and Y components.</param>
    public this(Half value)
    {
        X = value;
        Y = value;
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Half2"/> structure.
    /// </summary>
    /// <param name="x">The X component.</param>
    /// <param name="y">The Y component.</param>
    public this(float x, float y)
    {
        X = (Half)x;
        Y = (Half)y;
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Half2"/> structure.
    /// </summary>
    /// <param name="value">The value to set for both the X and Y components.</param>
    public this(float value)
    {
        X = (Half)value;
        Y = (Half)value;
    }

    /// <summary>
    /// Tests for equality between two objects.
    /// </summary>
    /// <param name="left">The first value to compare.</param>
    /// <param name="right">The second value to compare.</param>
    /// <returns>
    /// <c>true</c> if <paramref name="left" /> has the same value as <paramref name="right" />; otherwise, <c>false</c>.</returns>
    public static bool operator ==(Half2 left, Half2 right)
    {
        return Equals(left, right);
    }

    /// <summary>
    /// Tests for inequality between two objects.
    /// </summary>
    /// <param name="left">The first value to compare.</param>
    /// <param name="right">The second value to compare.</param>
    /// <returns>
    /// <c>true</c> if <paramref name="left" /> has a different value than <paramref name="right" />; otherwise, <c>false</c>.</returns>
    public static bool operator !=(Half2 left, Half2 right)
    {
        return !Equals(left, right);
    }
    
    /// <summary>
    /// Returns a <see cref="string"/> that represents this instance.
    /// </summary>
    /// <returns>
    /// A <see cref="string"/> that represents this instance.
    /// </returns>
    public override void ToString(String str) => str.Append( scope $"{{X:{X} Y:{Y}}}");

    /// <summary>
    /// Returns the hash code for this instance.
    /// </summary>
    /// <returns>A 32-bit signed integer hash code.</returns>
    public int GetHashCode()
	{
	    unchecked
	    {
	        var hash = 17;
	        hash = hash * 23 + X.GetHashCode();
	        hash = hash * 23 + Y.GetHashCode();
	        return hash;
	    }
	}

    /// <summary>
    /// Determines whether the specified object instances are considered equal.
    /// </summary>
    /// <param name="value1">The first value.</param>
    /// <param name="value2">The second value.</param>
    /// <returns>
    /// <c>true</c> if <paramref name="value1" /> is the same instance as <paramref name="value2" /> or
    /// if both are <c>null</c> references or if <c>value1.Equals(value2)</c> returns <c>true</c>; otherwise, <c>false</c>.</returns>
    public static bool Equals(Half2 value1, Half2 value2)
    {
        return (value1.X == value2.X) && (value1.Y == value2.Y);
    }

    /// <summary>
    /// Returns a value that indicates whether the current instance is equal to the specified object.
    /// </summary>
    /// <param name="other">Object to make the comparison with.</param>
    /// <returns>
    /// <c>true</c> if the current instance is equal to the specified object; <c>false</c> otherwise.</returns>
    public bool Equals(Half2 other)
    {
        return (X == other.X) && (Y == other.Y);
    }

    /// <summary>
    /// Performs an explicit conversion from <see cref="Vector2"/> to <see cref="Half2"/>.
    /// </summary>
    /// <param name="value">The value.</param>
    /// <returns>The result of the conversion.</returns>
    public static explicit operator Half2(Vector2 value)
    {
        return Half2((Half)value.X, (Half)value.Y);
    }

    /// <summary>
    /// Performs an explicit conversion from <see cref="Half2"/> to <see cref="Vector2"/>.
    /// </summary>
    /// <param name="value">The value.</param>
    /// <returns>The result of the conversion.</returns>
    public static explicit operator Vector2(Half2 value)
    {
        return Vector2(value.X, value.Y);
    }

    /// <summary>
    /// Deconstructs the vector's components into named variables.
    /// </summary>
    /// <param name="x">The X component</param>
    /// <param name="y">The Y component</param>
    public void Deconstruct(out Half x, out Half y)
    {
        x = X;
        y = Y;
    }
}
