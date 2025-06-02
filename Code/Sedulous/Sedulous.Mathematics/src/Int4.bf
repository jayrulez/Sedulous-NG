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
///   Represents a four dimensional mathematical vector.
/// </summary>
[CRepr]public struct Int4 : IEquatable<Int4>
{
    /// <summary>
    ///   The size of the <see cref = "Int4" /> type, in bytes.
    /// </summary>
    public static readonly int32 SizeInBytes = sizeof(Int4);

    /// <summary>
    ///   A <see cref = "Int4" /> with all of its components set to zero.
    /// </summary>
    public static readonly Int4 Zero = .();

    /// <summary>
    ///   The X unit <see cref = "Int4" /> (1, 0, 0, 0).
    /// </summary>
    public static readonly Int4 UnitX = .(1, 0, 0, 0);

    /// <summary>
    ///   The Y unit <see cref = "Int4" /> (0, 1, 0, 0).
    /// </summary>
    public static readonly Int4 UnitY = .(0, 1, 0, 0);

    /// <summary>
    ///   The Z unit <see cref = "Int4" /> (0, 0, 1, 0).
    /// </summary>
    public static readonly Int4 UnitZ = .(0, 0, 1, 0);

    /// <summary>
    ///   The W unit <see cref = "Int4" /> (0, 0, 0, 1).
    /// </summary>
    public static readonly Int4 UnitW = .(0, 0, 0, 1);

    /// <summary>
    ///   A <see cref = "Int4" /> with all of its components set to one.
    /// </summary>
    public static readonly Int4 One = .(1, 1, 1, 1);

    /// <summary>
    ///   The X component of the vector.
    /// </summary>
    public int32 X;

    /// <summary>
    ///   The Y component of the vector.
    /// </summary>
    public int32 Y;

    /// <summary>
    ///   The Z component of the vector.
    /// </summary>
    public int32 Z;

    /// <summary>
    ///   The W component of the vector.
    /// </summary>
    public int32 W;

    /// <summary>
    ///   Initializes a new instance of the <see cref = "Int4" /> struct.
    /// </summary>
    public this()
    {
		int32 value = 0;
        X = value;
        Y = value;
        Z = value;
        W = value;
    }

    /// <summary>
    ///   Initializes a new instance of the <see cref = "Int4" /> struct.
    /// </summary>
    /// <param name = "value">The value that will be assigned to all components.</param>
    public this(int32 value)
    {
        X = value;
        Y = value;
        Z = value;
        W = value;
    }

    /// <summary>
    ///   Initializes a new instance of the <see cref = "Int4" /> struct.
    /// </summary>
    /// <param name = "x">Initial value for the X component of the vector.</param>
    /// <param name = "y">Initial value for the Y component of the vector.</param>
    /// <param name = "z">Initial value for the Z component of the vector.</param>
    /// <param name = "w">Initial value for the W component of the vector.</param>
    public this(int32 x, int32 y, int32 z, int32 w)
    {
        X = x;
        Y = y;
        Z = z;
        W = w;
    }

    /// <summary>
    ///   Gets or sets the component at the specified index.
    /// </summary>
    /// <value>The value of the X, Y, Z, or W component, depending on the index.</value>
    /// <param name = "index">The index of the component to access. Use 0 for the X component, 1 for the Y component, 2 for the Z component, and 3 for the W component.</param>
    /// <returns>The value of the component at the specified index.</returns>
    /// <exception cref = "ArgumentOutOfRangeException">Thrown when the <paramref name = "index" /> is out of the range [0, 3].</exception>
    public int32 this[int32 index]
    {
		get
		{
		    switch (index)
		    {
		        case 0: return X;
		        case 1: return Y;
		        case 2: return Z;
		        case 3: return W;
		        default:
		            Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(index)}: Indices for Int4 run from 0 to 3, inclusive.");
		    }
		}


        set mut
        {
            switch (index)
            {
                case 0:
                    X = value;
                    break;
                case 1:
                    Y = value;
                    break;
                case 2:
                    Z = value;
                    break;
                case 3:
                    W = value;
                    break;
                default:
                    Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(index)}:Indices for Int4 run from 0 to 3, inclusive.");
            }
        }
    }

    /// <summary>
    /// Calculates the length of the vector.
    /// </summary>
    /// <returns>The length of the vector.</returns>
    /// <remarks>
    /// <see cref="LengthSquared"/> may be preferred when only the relative length is needed
    /// and speed is of the essence.
    /// </remarks>
    public int32 Length()
    {
        return (int32)Math.Sqrt((X * X) + (Y * Y) + (Z * Z) + (W * W));
    }

    /// <summary>
    /// Calculates the squared length of the vector.
    /// </summary>
    /// <returns>The squared length of the vector.</returns>
    /// <remarks>
    /// This method may be preferred to <see cref="Length"/> when only a relative length is needed
    /// and speed is of the essence.
    /// </remarks>
    public int32 LengthSquared()
    {
        return (X * X) + (Y * Y) + (Z * Z) + (W * W);
    }

    /// <summary>
    ///   Creates an array containing the elements of the vector.
    /// </summary>
    /// <returns>A four-element array containing the components of the vector.</returns>
    public int32[4] ToArray()
    {
        return .(X, Y, Z, W);
    }

    /// <summary>
    ///   Adds two vectors.
    /// </summary>
    /// <param name = "left">The first vector to add.</param>
    /// <param name = "right">The second vector to add.</param>
    /// <param name = "result">When the method completes, contains the sum of the two vectors.</param>
    public static void Add(Int4 left, Int4 right, out Int4 result)
    {
        result = Int4(left.X + right.X, left.Y + right.Y, left.Z + right.Z, left.W + right.W);
    }

    /// <summary>
    ///   Adds two vectors.
    /// </summary>
    /// <param name = "left">The first vector to add.</param>
    /// <param name = "right">The second vector to add.</param>
    /// <returns>The sum of the two vectors.</returns>
    public static Int4 Add(Int4 left, Int4 right)
    {
        return Int4(left.X + right.X, left.Y + right.Y, left.Z + right.Z, left.W + right.W);
    }

    /// <summary>
    ///   Subtracts two vectors.
    /// </summary>
    /// <param name = "left">The first vector to subtract.</param>
    /// <param name = "right">The second vector to subtract.</param>
    /// <param name = "result">When the method completes, contains the difference of the two vectors.</param>
    public static void Subtract(Int4 left, Int4 right, out Int4 result)
    {
        result = Int4(left.X - right.X, left.Y - right.Y, left.Z - right.Z, left.W - right.W);
    }

    /// <summary>
    ///   Subtracts two vectors.
    /// </summary>
    /// <param name = "left">The first vector to subtract.</param>
    /// <param name = "right">The second vector to subtract.</param>
    /// <returns>The difference of the two vectors.</returns>
    public static Int4 Subtract(Int4 left, Int4 right)
    {
        return Int4(left.X - right.X, left.Y - right.Y, left.Z - right.Z, left.W - right.W);
    }

    /// <summary>
    ///   Scales a vector by the given value.
    /// </summary>
    /// <param name = "value">The vector to scale.</param>
    /// <param name = "scale">The amount by which to scale the vector.</param>
    /// <param name = "result">When the method completes, contains the scaled vector.</param>
    public static void Multiply(Int4 value, int32 scale, out Int4 result)
    {
        result = Int4(value.X * scale, value.Y * scale, value.Z * scale, value.W * scale);
    }

    /// <summary>
    ///   Scales a vector by the given value.
    /// </summary>
    /// <param name = "value">The vector to scale.</param>
    /// <param name = "scale">The amount by which to scale the vector.</param>
    /// <returns>The scaled vector.</returns>
    public static Int4 Multiply(Int4 value, int32 scale)
    {
        return Int4(value.X * scale, value.Y * scale, value.Z * scale, value.W * scale);
    }

    /// <summary>
    ///   Modulates a vector with another by performing component-wise multiplication.
    /// </summary>
    /// <param name = "left">The first vector to modulate.</param>
    /// <param name = "right">The second vector to modulate.</param>
    /// <param name = "result">When the method completes, contains the modulated vector.</param>
    public static void Modulate(Int4 left, Int4 right, out Int4 result)
    {
        result = Int4(left.X * right.X, left.Y * right.Y, left.Z * right.Z, left.W * right.W);
    }

    /// <summary>
    ///   Modulates a vector with another by performing component-wise multiplication.
    /// </summary>
    /// <param name = "left">The first vector to modulate.</param>
    /// <param name = "right">The second vector to modulate.</param>
    /// <returns>The modulated vector.</returns>
    public static Int4 Modulate(Int4 left, Int4 right)
    {
        return Int4(left.X * right.X, left.Y * right.Y, left.Z * right.Z, left.W * right.W);
    }

    /// <summary>
    ///   Scales a vector by the given value.
    /// </summary>
    /// <param name = "value">The vector to scale.</param>
    /// <param name = "scale">The amount by which to scale the vector.</param>
    /// <param name = "result">When the method completes, contains the scaled vector.</param>
    public static void Divide(Int4 value, int32 scale, out Int4 result)
    {
        result = Int4(value.X / scale, value.Y / scale, value.Z / scale, value.W / scale);
    }

    /// <summary>
    ///   Scales a vector by the given value.
    /// </summary>
    /// <param name = "value">The vector to scale.</param>
    /// <param name = "scale">The amount by which to scale the vector.</param>
    /// <returns>The scaled vector.</returns>
    public static Int4 Divide(Int4 value, int32 scale)
    {
        return Int4(value.X / scale, value.Y / scale, value.Z / scale, value.W / scale);
    }

    /// <summary>
    ///   Reverses the direction of a given vector.
    /// </summary>
    /// <param name = "value">The vector to negate.</param>
    /// <param name = "result">When the method completes, contains a vector facing in the opposite direction.</param>
    public static void Negate(Int4 value, out Int4 result)
    {
        result = Int4(-value.X, -value.Y, -value.Z, -value.W);
    }

    /// <summary>
    ///   Reverses the direction of a given vector.
    /// </summary>
    /// <param name = "value">The vector to negate.</param>
    /// <returns>A vector facing in the opposite direction.</returns>
    public static Int4 Negate(Int4 value)
    {
        return Int4(-value.X, -value.Y, -value.Z, -value.W);
    }

    /// <summary>
    ///   Restricts a value to be within a specified range.
    /// </summary>
    /// <param name = "value">The value to clamp.</param>
    /// <param name = "min">The minimum value.</param>
    /// <param name = "max">The maximum value.</param>
    /// <param name = "result">When the method completes, contains the clamped value.</param>
    public static void Clamp(Int4 value, Int4 min, Int4 max, out Int4 result)
    {
        int32 x = value.X;
        x = (x > max.X) ? max.X : x;
        x = (x < min.X) ? min.X : x;

        int32 y = value.Y;
        y = (y > max.Y) ? max.Y : y;
        y = (y < min.Y) ? min.Y : y;

        int32 z = value.Z;
        z = (z > max.Z) ? max.Z : z;
        z = (z < min.Z) ? min.Z : z;

        int32 w = value.W;
        w = (w > max.W) ? max.W : w;
        w = (w < min.W) ? min.W : w;

        result = Int4(x, y, z, w);
    }

    /// <summary>
    ///   Restricts a value to be within a specified range.
    /// </summary>
    /// <param name = "value">The value to clamp.</param>
    /// <param name = "min">The minimum value.</param>
    /// <param name = "max">The maximum value.</param>
    /// <returns>The clamped value.</returns>
    public static Int4 Clamp(Int4 value, Int4 min, Int4 max)
    {
        Clamp(value, min, max, var result);
        return result;
    }

    /// <summary>
    ///   Returns a vector containing the smallest components of the specified vectors.
    /// </summary>
    /// <param name = "left">The first source vector.</param>
    /// <param name = "right">The second source vector.</param>
    /// <param name = "result">When the method completes, contains an new vector composed of the largest components of the source vectors.</param>
    public static void Max(Int4 left, Int4 right, out Int4 result)
    {
        result.X = (left.X > right.X) ? left.X : right.X;
        result.Y = (left.Y > right.Y) ? left.Y : right.Y;
        result.Z = (left.Z > right.Z) ? left.Z : right.Z;
        result.W = (left.W > right.W) ? left.W : right.W;
    }

    /// <summary>
    ///   Returns a vector containing the largest components of the specified vectors.
    /// </summary>
    /// <param name = "left">The first source vector.</param>
    /// <param name = "right">The second source vector.</param>
    /// <returns>A vector containing the largest components of the source vectors.</returns>
    public static Int4 Max(Int4 left, Int4 right)
    {
        Max(left, right, var result);
        return result;
    }

    /// <summary>
    ///   Returns a vector containing the smallest components of the specified vectors.
    /// </summary>
    /// <param name = "left">The first source vector.</param>
    /// <param name = "right">The second source vector.</param>
    /// <param name = "result">When the method completes, contains an new vector composed of the smallest components of the source vectors.</param>
    public static void Min(Int4 left, Int4 right, out Int4 result)
    {
        result.X = (left.X < right.X) ? left.X : right.X;
        result.Y = (left.Y < right.Y) ? left.Y : right.Y;
        result.Z = (left.Z < right.Z) ? left.Z : right.Z;
        result.W = (left.W < right.W) ? left.W : right.W;
    }

    /// <summary>
    ///   Returns a vector containing the smallest components of the specified vectors.
    /// </summary>
    /// <param name = "left">The first source vector.</param>
    /// <param name = "right">The second source vector.</param>
    /// <returns>A vector containing the smallest components of the source vectors.</returns>
    public static Int4 Min(Int4 left, Int4 right)
    {
        Min(left, right, var result);
        return result;
    }

    /// <summary>
    ///   Adds two vectors.
    /// </summary>
    /// <param name = "left">The first vector to add.</param>
    /// <param name = "right">The second vector to add.</param>
    /// <returns>The sum of the two vectors.</returns>
    public static Int4 operator +(Int4 left, Int4 right)
    {
        return Int4(left.X + right.X, left.Y + right.Y, left.Z + right.Z, left.W + right.W);
    }

    /// <summary>
    ///   Assert a vector (return it unchanged).
    /// </summary>
    /// <param name = "value">The vector to assert (unchange).</param>
    /// <returns>The asserted (unchanged) vector.</returns>
    public static Int4 operator +(Int4 value)
    {
        return value;
    }

    /// <summary>
    ///   Subtracts two vectors.
    /// </summary>
    /// <param name = "left">The first vector to subtract.</param>
    /// <param name = "right">The second vector to subtract.</param>
    /// <returns>The difference of the two vectors.</returns>
    public static Int4 operator -(Int4 left, Int4 right)
    {
        return Int4(left.X - right.X, left.Y - right.Y, left.Z - right.Z, left.W - right.W);
    }

    /// <summary>
    ///   Reverses the direction of a given vector.
    /// </summary>
    /// <param name = "value">The vector to negate.</param>
    /// <returns>A vector facing in the opposite direction.</returns>
    public static Int4 operator -(Int4 value)
    {
        return Int4(-value.X, -value.Y, -value.Z, -value.W);
    }

    /// <summary>
    ///   Scales a vector by the given value.
    /// </summary>
    /// <param name = "scale">The amount by which to scale the vector.</param>
    /// <param name = "value">The vector to scale.</param>
    /// <returns>The scaled vector.</returns>
    public static Int4 operator *(int32 scale, Int4 value)
    {
        return Int4(value.X * scale, value.Y * scale, value.Z * scale, value.W * scale);
    }

    /// <summary>
    ///   Scales a vector by the given value.
    /// </summary>
    /// <param name = "value">The vector to scale.</param>
    /// <param name = "scale">The amount by which to scale the vector.</param>
    /// <returns>The scaled vector.</returns>
    public static Int4 operator *(Int4 value, int32 scale)
    {
        return Int4(value.X * scale, value.Y * scale, value.Z * scale, value.W * scale);
    }

    /// <summary>
    ///   Scales a vector by the given value.
    /// </summary>
    /// <param name = "value">The vector to scale.</param>
    /// <param name = "scale">The amount by which to scale the vector.</param>
    /// <returns>The scaled vector.</returns>
    public static Int4 operator /(Int4 value, int32 scale)
    {
        return Int4(value.X / scale, value.Y / scale, value.Z / scale, value.W / scale);
    }

    /// <summary>
    ///   Tests for equality between two objects.
    /// </summary>
    /// <param name = "left">The first value to compare.</param>
    /// <param name = "right">The second value to compare.</param>
    /// <returns><c>true</c> if <paramref name = "left" /> has the same value as <paramref name = "right" />; otherwise, <c>false</c>.</returns>
    public static bool operator ==(Int4 left, Int4 right)
    {
        return left.Equals(right);
    }

    /// <summary>
    ///   Tests for inequality between two objects.
    /// </summary>
    /// <param name = "left">The first value to compare.</param>
    /// <param name = "right">The second value to compare.</param>
    /// <returns><c>true</c> if <paramref name = "left" /> has a different value than <paramref name = "right" />; otherwise, <c>false</c>.</returns>
    public static bool operator !=(Int4 left, Int4 right)
    {
        return !left.Equals(right);
    }

    /// <summary>
    ///   Performs an explicit conversion from <see cref = "Int4" /> to <see cref = "Vector2" />.
    /// </summary>
    /// <param name = "value">The value.</param>
    /// <returns>The result of the conversion.</returns>
    public static explicit operator Vector2(Int4 value)
    {
        return Vector2(value.X, value.Y);
    }

    /// <summary>
    ///   Performs an explicit conversion from <see cref = "Int4" /> to <see cref = "Vector3" />.
    /// </summary>
    /// <param name = "value">The value.</param>
    /// <returns>The result of the conversion.</returns>
    public static explicit operator Vector3(Int4 value)
    {
        return Vector3(value.X, value.Y, value.Z);
    }

    /// <summary>
    ///   Performs an explicit conversion from <see cref = "Int4" /> to <see cref = "Vector4" />.
    /// </summary>
    /// <param name = "value">The value.</param>
    /// <returns>The result of the conversion.</returns>
    public static explicit operator Vector4(Int4 value)
    {
        return Vector4(value.X, value.Y, value.Z, value.W);
    }
    
    /// <summary>
    /// Returns a <see cref="string"/> that represents this instance.
    /// </summary>
    /// <returns>
    /// A <see cref="string"/> that represents this instance.
    /// </returns>
    public override void ToString(String str) => str.Append(scope $"{{X:{X} Y:{Y} Z:{Z} W:{W}}}");

    /// <summary>
    ///   Returns a hash code for this instance.
    /// </summary>
    /// <returns>
    ///   A hash code for this instance, suitable for use in hashing algorithms and data structures like a hash table.
    /// </returns>
    public int GetHashCode()
	{
	    unchecked
	    {
	        var hash = 17;
	        hash = hash * 23 + X.GetHashCode();
	        hash = hash * 23 + Y.GetHashCode();
	        hash = hash * 23 + Z.GetHashCode();
	        hash = hash * 23 + W.GetHashCode();
	        return hash;
	    }
	}

    /// <summary>
    ///   Determines whether the specified <see cref = "Int4" /> is equal to this instance.
    /// </summary>
    /// <param name = "other">The <see cref = "Int4" /> to compare with this instance.</param>
    /// <returns>
    ///   <c>true</c> if the specified <see cref = "Int4" /> is equal to this instance; otherwise, <c>false</c>.
    /// </returns>
    public bool Equals(Int4 other)
    {
        return other.X == X && other.Y == Y && other.Z == Z && other.W == W;
    }

    /// <summary>
    /// Deconstructs the vector's components into named variables.
    /// </summary>
    /// <param name="x">The X component</param>
    /// <param name="y">The Y component</param>
    /// <param name="z">The Z component</param>
    /// <param name="w">The W component</param>
    public void Deconstruct(out int32 x, out int32 y, out int32 z, out int32 w)
    {
        x = X;
        y = Y;
        z = Z;
        w = W;
    }
}
