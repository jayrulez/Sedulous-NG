using System;
// Copyright (c) .NET Foundation and Contributors (https://dotnetfoundation.org/ & https://stride3d.net) and Silicon Studio Corp. (https://www.siliconstudio.co.jp)
// Distributed under the MIT license. See the LICENSE.md file in the project root for more information.
//
// -----------------------------------------------------------------------------
// Original code from SlimMath project. http://code.google.com/p/slimmath/
// Greetings to SlimDX Group. Original code published with the following license:
// -----------------------------------------------------------------------------
/*
* Copyright (c) 2007-2011 SlimDX Group
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

namespace Sedulous.Mathematics;

/// <summary>
/// Represents a two dimensional mathematical vector.
/// </summary>
public struct Int2 : IEquatable<Int2>
{
    /// <summary>
    /// The size of the <see cref="Int2"/> type, in bytes.
    /// </summary>
    public static readonly int32 SizeInBytes = sizeof(Int2);

    /// <summary>
    /// A <see cref="Int2"/> with all of its components set to zero.
    /// </summary>
    public static readonly Int2 Zero = .();

    /// <summary>
    /// The X unit <see cref="Int2"/> (1, 0, 0).
    /// </summary>
    public static readonly Int2 UnitX = .(1, 0);

    /// <summary>
    /// The Y unit <see cref="Int2"/> (0, 1, 0).
    /// </summary>
    public static readonly Int2 UnitY = .(0, 1);

    /// <summary>
    /// A <see cref="Int2"/> with all of its components set to one.
    /// </summary>
    public static readonly Int2 One = .(1, 1);

    /// <summary>
    /// The X component of the vector.
    /// </summary>
    public int32 X;

    /// <summary>
    /// The Y component of the vector.
    /// </summary>
    public int32 Y;

    /// <summary>
    /// Initializes a new instance of the <see cref="Int2"/> struct.
    /// </summary>
    public this()
    {
		int32 value= 0;
        X = value;
        Y = value;
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Int2"/> struct.
    /// </summary>
    /// <param name="value">The value that will be assigned to all components.</param>
    public this(int32 value)
    {
        X = value;
        Y = value;
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Int2"/> struct.
    /// </summary>
    /// <param name="x">Initial value for the X component of the vector.</param>
    /// <param name="y">Initial value for the Y component of the vector.</param>
    public this(int32 x, int32 y)
    {
        X = x;
        Y = y;
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Int2"/> struct.
    /// </summary>
    /// <param name="value">A vector containing the values with which to initialize the X and Y components.</param>
    public this(Vector2 value)
    {
        X = (int32)value.X;
        Y = (int32)value.Y;
    }

    /// <summary>
    /// Gets or sets the component at the specified index.
    /// </summary>
    /// <value>The value of the X or Y component, depending on the index.</value>
    /// <param name="index">The index of the component to access. Use 0 for the X component and 1 for the Y component.</param>
    /// <returns>The value of the component at the specified index.</returns>
    /// <exception cref="System.ArgumentOutOfRangeException">Thrown when the <paramref name="index"/> is out of the range [0, 1].</exception>
    public int32 this[int32 index]
    {
        get
        {
			switch (index)
			{
			    case 0: return X;
			    case 1: return Y;
			    default:
			        Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(index)}: Indices for Int2 run from 0 to 1, inclusive.");
			}

        }

        set mut
        {
            switch (index)
            {
                case 0: X = value; break;
                case 1: Y = value; break;
                default: Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(index)}:Indices for Int2 run from 0 to 1, inclusive.");
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
        return (int32)Math.Sqrt((X * X) + (Y * Y));
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
        return (X * X) + (Y * Y);
    }

    /// <summary>
    /// Raises the exponent for each components.
    /// </summary>
    /// <param name="exponent">The exponent.</param>
    public void Pow(int32 exponent) mut
    {
        X = (int32)Math.Pow(X, exponent);
        Y = (int32)Math.Pow(Y, exponent);
    }

    /// <summary>
    /// Creates an array containing the elements of the vector.
    /// </summary>
    /// <returns>A two-element array containing the components of the vector.</returns>
    public int32[2] ToArray()
    {
        return .(X, Y);
    }

    /// <summary>
    /// Adds two vectors.
    /// </summary>
    /// <param name="left">The first vector to add.</param>
    /// <param name="right">The second vector to add.</param>
    /// <param name="result">When the method completes, contains the sum of the two vectors.</param>
    public static void Add(Int2 left, Int2 right, out Int2 result)
    {
        result = Int2(left.X + right.X, left.Y + right.Y);
    }

    /// <summary>
    /// Adds two vectors.
    /// </summary>
    /// <param name="left">The first vector to add.</param>
    /// <param name="right">The second vector to add.</param>
    /// <returns>The sum of the two vectors.</returns>
    public static Int2 Add(Int2 left, Int2 right)
    {
        return Int2(left.X + right.X, left.Y + right.Y);
    }

    /// <summary>
    /// Subtracts two vectors.
    /// </summary>
    /// <param name="left">The first vector to subtract.</param>
    /// <param name="right">The second vector to subtract.</param>
    /// <param name="result">When the method completes, contains the difference of the two vectors.</param>
    public static void Subtract(Int2 left, Int2 right, out Int2 result)
    {
        result = Int2(left.X - right.X, left.Y - right.Y);
    }

    /// <summary>
    /// Subtracts two vectors.
    /// </summary>
    /// <param name="left">The first vector to subtract.</param>
    /// <param name="right">The second vector to subtract.</param>
    /// <returns>The difference of the two vectors.</returns>
    public static Int2 Subtract(Int2 left, Int2 right)
    {
        return Int2(left.X - right.X, left.Y - right.Y);
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <param name="result">When the method completes, contains the scaled vector.</param>
    public static void Multiply(Int2 value, int32 scale, out Int2 result)
    {
        result = Int2(value.X * scale, value.Y * scale);
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <returns>The scaled vector.</returns>
    public static Int2 Multiply(Int2 value, int32 scale)
    {
        return Int2(value.X * scale, value.Y * scale);
    }

    /// <summary>
    /// Modulates a vector with another by performing component-wise multiplication.
    /// </summary>
    /// <param name="left">The first vector to modulate.</param>
    /// <param name="right">The second vector to modulate.</param>
    /// <param name="result">When the method completes, contains the modulated vector.</param>
    public static void Modulate(Int2 left, Int2 right, out Int2 result)
    {
        result = Int2(left.X * right.X, left.Y * right.Y);
    }

    /// <summary>
    /// Modulates a vector with another by performing component-wise multiplication.
    /// </summary>
    /// <param name="left">The first vector to modulate.</param>
    /// <param name="right">The second vector to modulate.</param>
    /// <returns>The modulated vector.</returns>
    public static Int2 Modulate(Int2 left, Int2 right)
    {
        return Int2(left.X * right.X, left.Y * right.Y);
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <param name="result">When the method completes, contains the scaled vector.</param>
    public static void Divide(Int2 value, int32 scale, out Int2 result)
    {
        result = Int2(value.X / scale, value.Y / scale);
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <returns>The scaled vector.</returns>
    public static Int2 Divide(Int2 value, int32 scale)
    {
        return Int2(value.X / scale, value.Y / scale);
    }

    /// <summary>
    /// Reverses the direction of a given vector.
    /// </summary>
    /// <param name="value">The vector to negate.</param>
    /// <param name="result">When the method completes, contains a vector facing in the opposite direction.</param>
    public static void Negate(Int2 value, out Int2 result)
    {
        result = Int2(-value.X, -value.Y);
    }

    /// <summary>
    /// Reverses the direction of a given vector.
    /// </summary>
    /// <param name="value">The vector to negate.</param>
    /// <returns>A vector facing in the opposite direction.</returns>
    public static Int2 Negate(Int2 value)
    {
        return Int2(-value.X, -value.Y);
    }

    /// <summary>
    /// Restricts a value to be within a specified range.
    /// </summary>
    /// <param name="value">The value to clamp.</param>
    /// <param name="min">The minimum value.</param>
    /// <param name="max">The maximum value.</param>
    /// <param name="result">When the method completes, contains the clamped value.</param>
    public static void Clamp(Int2 value, Int2 min, Int2 max, out Int2 result)
    {
        int32 x = value.X;
        x = (x > max.X) ? max.X : x;
        x = (x < min.X) ? min.X : x;

        int32 y = value.Y;
        y = (y > max.Y) ? max.Y : y;
        y = (y < min.Y) ? min.Y : y;

        result = Int2(x, y);
    }

    /// <summary>
    /// Restricts a value to be within a specified range.
    /// </summary>
    /// <param name="value">The value to clamp.</param>
    /// <param name="min">The minimum value.</param>
    /// <param name="max">The maximum value.</param>
    /// <returns>The clamped value.</returns>
    public static Int2 Clamp(Int2 value, Int2 min, Int2 max)
    {
        Clamp(value, min, max, var result);
        return result;
    }

    /// <summary>
    /// Calculates the dot product of two vectors.
    /// </summary>
    /// <param name="left">First source vector.</param>
    /// <param name="right">Second source vector.</param>
    /// <param name="result">When the method completes, contains the dot product of the two vectors.</param>
    public static void Dot(Int2 left, Int2 right, out int32 result)
    {
        result = (left.X * right.X) + (left.Y * right.Y);
    }

    /// <summary>
    /// Calculates the dot product of two vectors.
    /// </summary>
    /// <param name="left">First source vector.</param>
    /// <param name="right">Second source vector.</param>
    /// <returns>The dot product of the two vectors.</returns>
    public static int32 Dot(Int2 left, Int2 right)
    {
        return (left.X * right.X) + (left.Y * right.Y);
    }

    /// <summary>
    /// Performs a linear interpolation between two vectors.
    /// </summary>
    /// <param name="start">Start vector.</param>
    /// <param name="end">End vector.</param>
    /// <param name="amount">Value between 0 and 1 indicating the weight of <paramref name="end"/>.</param>
    /// <param name="result">When the method completes, contains the linear interpolation of the two vectors.</param>
    /// <remarks>
    /// This method performs the linear interpolation based on the following formula.
    /// <c>start + (end - start) * amount</c>
    /// Passing <paramref name="amount"/> a value of 0 will cause <paramref name="start"/> to be returned; a value of 1 will cause <paramref name="end"/> to be returned. 
    /// </remarks>
    public static void Lerp(Int2 start, Int2 end, float amount, out Int2 result)
    {
        result.X = (int32)(start.X + ((end.X - start.X) * amount));
        result.Y = (int32)(start.Y + ((end.Y - start.Y) * amount));
    }

    /// <summary>
    /// Performs a linear interpolation between two vectors.
    /// </summary>
    /// <param name="start">Start vector.</param>
    /// <param name="end">End vector.</param>
    /// <param name="amount">Value between 0 and 1 indicating the weight of <paramref name="end"/>.</param>
    /// <returns>The linear interpolation of the two vectors.</returns>
    /// <remarks>
    /// This method performs the linear interpolation based on the following formula.
    /// <c>start + (end - start) * amount</c>
    /// Passing <paramref name="amount"/> a value of 0 will cause <paramref name="start"/> to be returned; a value of 1 will cause <paramref name="end"/> to be returned. 
    /// </remarks>
    public static Int2 Lerp(Int2 start, Int2 end, float amount)
    {
        Lerp(start, end, amount, var result);
        return result;
    }

    /// <summary>
    /// Performs a cubic interpolation between two vectors.
    /// </summary>
    /// <param name="start">Start vector.</param>
    /// <param name="end">End vector.</param>
    /// <param name="amount">Value between 0 and 1 indicating the weight of <paramref name="end"/>.</param>
    /// <param name="result">When the method completes, contains the cubic interpolation of the two vectors.</param>
    public static void SmoothStep(Int2 start, Int2 end, float amount, out Int2 result)
    {
		var amount;
        amount = (amount > 1) ? 1 : ((amount < 0) ? 0 : amount);
        amount = amount * amount * (3 - (2 * amount));

        result.X = (int32)(start.X + ((end.X - start.X) * amount));
        result.Y = (int32)(start.Y + ((end.Y - start.Y) * amount));
    }

    /// <summary>
    /// Performs a cubic interpolation between two vectors.
    /// </summary>
    /// <param name="start">Start vector.</param>
    /// <param name="end">End vector.</param>
    /// <param name="amount">Value between 0 and 1 indicating the weight of <paramref name="end"/>.</param>
    /// <returns>The cubic interpolation of the two vectors.</returns>
    public static Int2 SmoothStep(Int2 start, Int2 end, float amount)
    {
        SmoothStep(start, end, amount, var result);
        return result;
    }

    /// <summary>
    /// Returns a vector containing the smallest components of the specified vectors.
    /// </summary>
    /// <param name="left">The first source vector.</param>
    /// <param name="right">The second source vector.</param>
    /// <param name="result">When the method completes, contains an new vector composed of the largest components of the source vectors.</param>
    public static void Max(Int2 left, Int2 right, out Int2 result)
    {
        result.X = (left.X > right.X) ? left.X : right.X;
        result.Y = (left.Y > right.Y) ? left.Y : right.Y;
    }

    /// <summary>
    /// Returns a vector containing the largest components of the specified vectors.
    /// </summary>
    /// <param name="left">The first source vector.</param>
    /// <param name="right">The second source vector.</param>
    /// <returns>A vector containing the largest components of the source vectors.</returns>
    public static Int2 Max(Int2 left, Int2 right)
    {
        Max(left, right, var result);
        return result;
    }

    /// <summary>
    /// Returns a vector containing the smallest components of the specified vectors.
    /// </summary>
    /// <param name="left">The first source vector.</param>
    /// <param name="right">The second source vector.</param>
    /// <param name="result">When the method completes, contains an new vector composed of the smallest components of the source vectors.</param>
    public static void Min(Int2 left, Int2 right, out Int2 result)
    {
        result.X = (left.X < right.X) ? left.X : right.X;
        result.Y = (left.Y < right.Y) ? left.Y : right.Y;
    }

    /// <summary>
    /// Returns a vector containing the smallest components of the specified vectors.
    /// </summary>
    /// <param name="left">The first source vector.</param>
    /// <param name="right">The second source vector.</param>
    /// <returns>A vector containing the smallest components of the source vectors.</returns>
    public static Int2 Min(Int2 left, Int2 right)
    {
        Min(left, right, var result);
        return result;
    }

    /// <summary>
    /// Adds two vectors.
    /// </summary>
    /// <param name="left">The first vector to add.</param>
    /// <param name="right">The second vector to add.</param>
    /// <returns>The sum of the two vectors.</returns>
    public static Int2 operator +(Int2 left, Int2 right)
    {
        return Int2(left.X + right.X, left.Y + right.Y);
    }

    /// <summary>
    /// Assert a vector (return it unchanged).
    /// </summary>
    /// <param name="value">The vector to assert (unchange).</param>
    /// <returns>The asserted (unchanged) vector.</returns>
    public static Int2 operator +(Int2 value)
    {
        return value;
    }

    /// <summary>
    /// Subtracts two vectors.
    /// </summary>
    /// <param name="left">The first vector to subtract.</param>
    /// <param name="right">The second vector to subtract.</param>
    /// <returns>The difference of the two vectors.</returns>
    public static Int2 operator -(Int2 left, Int2 right)
    {
        return Int2(left.X - right.X, left.Y - right.Y);
    }

    /// <summary>
    /// Reverses the direction of a given vector.
    /// </summary>
    /// <param name="value">The vector to negate.</param>
    /// <returns>A vector facing in the opposite direction.</returns>
    public static Int2 operator -(Int2 value)
    {
        return Int2(-value.X, -value.Y);
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <param name="value">The vector to scale.</param>
    /// <returns>The scaled vector.</returns>
    public static Int2 operator *(float scale, Int2 value)
    {
        return Int2((int32)(value.X * scale), (int32)(value.Y * scale));
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <returns>The scaled vector.</returns>
    public static Int2 operator *(Int2 value, float scale)
    {
        return Int2((int32)(value.X * scale), (int32)(value.Y * scale));
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <returns>The scaled vector.</returns>
    public static Int2 operator /(Int2 value, float scale)
    {
        return Int2((int32)(value.X / scale), (int32)(value.Y / scale));
    }

    /// <summary>
    /// Tests for equality between two objects.
    /// </summary>
    /// <param name="left">The first value to compare.</param>
    /// <param name="right">The second value to compare.</param>
    /// <returns><c>true</c> if <paramref name="left"/> has the same value as <paramref name="right"/>; otherwise, <c>false</c>.</returns>
    public static bool operator ==(Int2 left, Int2 right)
    {
        return left.Equals(right);
    }

    /// <summary>
    /// Tests for inequality between two objects.
    /// </summary>
    /// <param name="left">The first value to compare.</param>
    /// <param name="right">The second value to compare.</param>
    /// <returns><c>true</c> if <paramref name="left"/> has a different value than <paramref name="right"/>; otherwise, <c>false</c>.</returns>
    public static bool operator !=(Int2 left, Int2 right)
    {
        return !left.Equals(right);
    }

    /// <summary>
    /// Performs an explicit conversion from <see cref="Int2"/> to <see cref="Vector2"/>.
    /// </summary>
    /// <param name="value">The value.</param>
    /// <returns>The result of the conversion.</returns>
    public static explicit operator Vector2(Int2 value)
    {
        return Vector2(value.X, value.Y);
    }

    /// <summary>
    /// Performs an explicit conversion from <see cref="Int2"/> to <see cref="Vector4"/>.
    /// </summary>
    /// <param name="value">The value.</param>
    /// <returns>The result of the conversion.</returns>
    public static explicit operator Vector4(Int2 value)
    {
        return Vector4(value.X, value.Y, 0, 0);
    }
    
    /// <summary>
    /// Returns a <see cref="string"/> that represents this instance.
    /// </summary>
    /// <returns>
    /// A <see cref="string"/> that represents this instance.
    /// </returns>
    public override void ToString(String str) => str.Append( scope $"{{X:{X} Y:{Y}}}");

    /// <summary>
    /// Returns a hash code for this instance.
    /// </summary>
    /// <returns>
    /// A hash code for this instance, suitable for use in hashing algorithms and data structures like a hash table. 
    /// </returns>
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
    /// Determines whether the specified <see cref="Int2"/> is equal to this instance.
    /// </summary>
    /// <param name="other">The <see cref="Int2"/> to compare with this instance.</param>
    /// <returns>
    /// <c>true</c> if the specified <see cref="Int2"/> is equal to this instance; otherwise, <c>false</c>.
    /// </returns>
    public bool Equals(Int2 other)
    {
        return Math.Abs(other.X - X) < MathUtil.ZeroTolerance &&
            Math.Abs(other.Y - Y) < MathUtil.ZeroTolerance;
    }

    /// <summary>
    /// Deconstructs the vector's components into named variables.
    /// </summary>
    /// <param name="x">The X component</param>
    /// <param name="y">The Y component</param>
    public void Deconstruct(out int32 x, out int32 y)
    {
        x = X;
        y = Y;
    }
}
