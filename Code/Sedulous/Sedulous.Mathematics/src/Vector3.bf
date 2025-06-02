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
/// Represents a three dimensional mathematical vector.
/// </summary>
[CRepr]public struct Vector3 : IEquatable<Vector3>
{
    /// <summary>
    /// The size of the <see cref="Sedulous.Mathematics.Vector3"/> type, in bytes.
    /// </summary>
    public static readonly int32 SizeInBytes = sizeof(Vector3);

    /// <summary>
    /// A <see cref="Sedulous.Mathematics.Vector3"/> with all of its components set to zero.
    /// </summary>
    public static readonly Vector3 Zero = .();

    /// <summary>
    /// The X unit <see cref="Sedulous.Mathematics.Vector3"/> (1, 0, 0).
    /// </summary>
    public static readonly Vector3 UnitX = .(1.0f, 0.0f, 0.0f);

    /// <summary>
    /// The Y unit <see cref="Sedulous.Mathematics.Vector3"/> (0, 1, 0).
    /// </summary>
    public static readonly Vector3 UnitY = .(0.0f, 1.0f, 0.0f);

    /// <summary>
    /// The Z unit <see cref="Sedulous.Mathematics.Vector3"/> (0, 0, 1).
    /// </summary>
    public static readonly Vector3 UnitZ = .(0.0f, 0.0f, 1.0f);

    /// <summary>
    /// A <see cref="Sedulous.Mathematics.Vector3"/> with all of its components set to one.
    /// </summary>
    public static readonly Vector3 One = .(1.0f, 1.0f, 1.0f);

    /// <summary>
    /// Returns a unit vector representing right in a right-handed coordinate system.
    /// </summary>
    public static Vector3 Right
    {
        get { return Vector3(1, 0, 0); }
    }

    /// <summary>
    /// Returns a unit vector representing left in a right-handed coordinate system.
    /// </summary>
    public static Vector3 Left
    {
        get { return Vector3(-1, 0, 0); }
    }

    /// <summary>
    /// Returns a unit vector representing up in a right-handed coordinate system.
    /// </summary>
    public static Vector3 Up
    {
        get { return Vector3(0, 1, 0); }
    }

    /// <summary>
    /// Returns a unit vector representing down in a right-handed coordinate system.
    /// </summary>
    public static Vector3 Down
    {
        get { return Vector3(0, -1, 0); }
    }

    /// <summary>
    /// Returns a unit vector representing backward in a right-handed coordinate system.
    /// </summary>
    public static Vector3 Backward
    {
        get { return Vector3(0, 0, 1); }
    }

    /// <summary>
    /// Returns a unit vector representing forward in a right-handed coordinate system.
    /// </summary>
    public static Vector3 Forward
    {
        get { return Vector3(0, 0, -1); }
    }

    /// <summary>
    /// The X component of the vector.
    /// </summary>
    public float X;

    /// <summary>
    /// The Y component of the vector.
    /// </summary>
    public float Y;

    /// <summary>
    /// The Z component of the vector.
    /// </summary>
    public float Z;

    /// <summary>
    /// Initializes a new instance of the <see cref="Sedulous.Mathematics.Vector3"/> struct.
    /// </summary>
    public this()
    {
		float value = 0;
        X = value;
        Y = value;
        Z = value;
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Sedulous.Mathematics.Vector3"/> struct.
    /// </summary>
    /// <param name="value">The value that will be assigned to all components.</param>
    public this(float value)
    {
        X = value;
        Y = value;
        Z = value;
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Sedulous.Mathematics.Vector3"/> struct.
    /// </summary>
    /// <param name="x">Initial value for the X component of the vector.</param>
    /// <param name="y">Initial value for the Y component of the vector.</param>
    /// <param name="z">Initial value for the Z component of the vector.</param>
    public this(float x, float y, float z)
    {
        X = x;
        Y = y;
        Z = z;
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Sedulous.Mathematics.Vector3"/> struct.
    /// </summary>
    /// <param name="value">A vector containing the values with which to initialize the X and Y components.</param>
    /// <param name="z">Initial value for the Z component of the vector.</param>
    public this(Vector2 value, float z)
    {
        X = value.X;
        Y = value.Y;
        Z = z;
    }

    /// <summary>
    /// Gets a value indicting whether this instance is normalized.
    /// </summary>
    public readonly bool IsNormalized
    {
        get { return Math.Abs((X * X) + (Y * Y) + (Z * Z) - 1f) < MathUtil.ZeroTolerance; }
    }

    /// <summary>
    /// Gets or sets the component at the specified index.
    /// </summary>
    /// <value>The value of the X, Y, or Z component, depending on the index.</value>
    /// <param name="index">The index of the component to access. Use 0 for the X component, 1 for the Y component, and 2 for the Z component.</param>
    /// <returns>The value of the component at the specified index.</returns>
    /// <exception cref="System.ArgumentOutOfRangeException">Thrown when the <paramref name="index"/> is out of the range [0, 2].</exception>
    public float this[int32 index]
    {
        get
        {
            switch (index)
            {
                case 0: return X;
                case 1: return Y;
                case 2: return Z;
            }

            Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(index)}:Indices for Vector3 run from 0 to 2, inclusive.");
        }

        set mut
        {
            switch (index)
            {
                case 0: X = value; break;
                case 1: Y = value; break;
                case 2: Z = value; break;
                default: Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(index)}:Indices for Vector3 run from 0 to 2, inclusive.");
            }
        }
    }

    /// <summary>
    /// Calculates the length of the vector.
    /// </summary>
    /// <returns>The length of the vector.</returns>
    /// <remarks>
    /// <see cref="Sedulous.Mathematics.Vector3.LengthSquared"/> may be preferred when only the relative length is needed
    /// and speed is of the essence.
    /// </remarks>
    [Inline]
    public float Length()
    {
        return Math.Sqrt((X * X) + (Y * Y) + (Z * Z));
    }

    /// <summary>
    /// Calculates the squared length of the vector.
    /// </summary>
    /// <returns>The squared length of the vector.</returns>
    /// <remarks>
    /// This method may be preferred to <see cref="Sedulous.Mathematics.Vector3.Length"/> when only a relative length is needed
    /// and speed is of the essence.
    /// </remarks>
    [Inline]
    public float LengthSquared()
    {
        return (X * X) + (Y * Y) + (Z * Z);
    }

    /// <summary>
    /// Converts the vector into a unit vector.
    /// </summary>
    [Inline]
    public void Normalize() mut
    {
        float length = Length();
        if (length > MathUtil.ZeroTolerance)
        {
            float inv = 1.0f / length;
            X *= inv;
            Y *= inv;
            Z *= inv;
        }
    }

    /// <summary>
    /// Raises the exponent for each components.
    /// </summary>
    /// <param name="exponent">The exponent.</param>
    public void Pow(float exponent) mut
    {
        X = Math.Pow(X, exponent);
        Y = Math.Pow(Y, exponent);
        Z = Math.Pow(Z, exponent);
    }

    /// <summary>
    /// Creates an array containing the elements of the vector.
    /// </summary>
    /// <returns>A three-element array containing the components of the vector.</returns>
    public float[3] ToArray()
    {
        return .(X, Y, Z);
    }

    /// <summary>
    /// Moves the first vector3 to the second one in a straight line.
    /// </summary>
    /// <param name="from">The first point.</param>
    /// <param name="to">The second point.</param>
    /// <param name="maxTravelDistance">The rate at which the first point is going to move towards the second point.</param>
    public static Vector3 MoveTo(in Vector3 from, in Vector3 to, float maxTravelDistance)
    {
        Vector3 distance = Subtract(to, from);

        float length = distance.Length();

        if (maxTravelDistance >= length || length == 0)
            return to;
        else
            return Vector3(from.X + distance.X / length * maxTravelDistance, from.Y + distance.Y / length * maxTravelDistance, from.Z + distance.Z / length * maxTravelDistance);
    }

    /// <summary>
    /// Adds two vectors.
    /// </summary>
    /// <param name="left">The first vector to add.</param>
    /// <param name="right">The second vector to add.</param>
    /// <param name="result">When the method completes, contains the sum of the two vectors.</param>
    [Inline]
    public static void Add(Vector3 left, Vector3 right, out Vector3 result)
    {
        result = Vector3(left.X + right.X, left.Y + right.Y, left.Z + right.Z);
    }

    /// <summary>
    /// Adds two vectors.
    /// </summary>
    /// <param name="left">The first vector to add.</param>
    /// <param name="right">The second vector to add.</param>
    /// <returns>The sum of the two vectors.</returns>
    [Inline]
    public static Vector3 Add(Vector3 left, Vector3 right)
    {
        return Vector3(left.X + right.X, left.Y + right.Y, left.Z + right.Z);
    }

    /// <summary>
    /// Subtracts two vectors.
    /// </summary>
    /// <param name="left">The first vector to subtract.</param>
    /// <param name="right">The second vector to subtract.</param>
    /// <param name="result">When the method completes, contains the difference of the two vectors.</param>
    [Inline]
    public static void Subtract(Vector3 left, Vector3 right, out Vector3 result)
    {
        result = Vector3(left.X - right.X, left.Y - right.Y, left.Z - right.Z);
    }

    /// <summary>
    /// Subtracts two vectors.
    /// </summary>
    /// <param name="left">The first vector to subtract.</param>
    /// <param name="right">The second vector to subtract.</param>
    /// <returns>The difference of the two vectors.</returns>
    [Inline]
    public static Vector3 Subtract(in Vector3 left, in Vector3 right)
    {
        return Vector3(left.X - right.X, left.Y - right.Y, left.Z - right.Z);
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <param name="result">When the method completes, contains the scaled vector.</param>
    [Inline]
    public static void Multiply(Vector3 value, float scale, out Vector3 result)
    {
        result = Vector3(value.X * scale, value.Y * scale, value.Z * scale);
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <returns>The scaled vector.</returns>
    [Inline]
    public static Vector3 Multiply(Vector3 value, float scale)
    {
        return Vector3(value.X * scale, value.Y * scale, value.Z * scale);
    }

    /// <summary>
    /// Modulates a vector with another by performing component-wise multiplication.
    /// </summary>
    /// <param name="left">The first vector to modulate.</param>
    /// <param name="right">The second vector to modulate.</param>
    /// <param name="result">When the method completes, contains the modulated vector.</param>
    [Inline]
    public static void Modulate(Vector3 left, Vector3 right, out Vector3 result)
    {
        result = Vector3(left.X * right.X, left.Y * right.Y, left.Z * right.Z);
    }

    /// <summary>
    /// Modulates a vector with another by performing component-wise multiplication.
    /// </summary>
    /// <param name="left">The first vector to modulate.</param>
    /// <param name="right">The second vector to modulate.</param>
    /// <returns>The modulated vector.</returns>
    [Inline]
    public static Vector3 Modulate(Vector3 left, Vector3 right)
    {
        return Vector3(left.X * right.X, left.Y * right.Y, left.Z * right.Z);
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <param name="result">When the method completes, contains the scaled vector.</param>
    [Inline]
    public static void Divide(Vector3 value, float scale, out Vector3 result)
    {
        result = Vector3(value.X / scale, value.Y / scale, value.Z / scale);
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <returns>The scaled vector.</returns>
    [Inline]
    public static Vector3 Divide(Vector3 value, float scale)
    {
        return Vector3(value.X / scale, value.Y / scale, value.Z / scale);
    }

    /// <summary>
    /// Demodulates a vector with another by performing component-wise division.
    /// </summary>
    /// <param name="left">The first vector to demodulate.</param>
    /// <param name="right">The second vector to demodulate.</param>
    /// <param name="result">When the method completes, contains the demodulated vector.</param>
    [Inline]
    public static void Demodulate(Vector3 left, Vector3 right, out Vector3 result)
    {
        result = Vector3(left.X / right.X, left.Y / right.Y, left.Z / right.Z);
    }

    /// <summary>
    /// Demodulates a vector with another by performing component-wise division.
    /// </summary>
    /// <param name="left">The first vector to demodulate.</param>
    /// <param name="right">The second vector to demodulate.</param>
    /// <returns>The demodulated vector.</returns>
    [Inline]
    public static Vector3 Demodulate(Vector3 left, Vector3 right)
    {
        return Vector3(left.X / right.X, left.Y / right.Y, left.Z / right.Z);
    }

    /// <summary>
    /// Reverses the direction of a given vector.
    /// </summary>
    /// <param name="value">The vector to negate.</param>
    /// <param name="result">When the method completes, contains a vector facing in the opposite direction.</param>
    [Inline]
    public static void Negate(Vector3 value, out Vector3 result)
    {
        result = Vector3(-value.X, -value.Y, -value.Z);
    }

    /// <summary>
    /// Reverses the direction of a given vector.
    /// </summary>
    /// <param name="value">The vector to negate.</param>
    /// <returns>A vector facing in the opposite direction.</returns>
    [Inline]
    public static Vector3 Negate(Vector3 value)
    {
        return Vector3(-value.X, -value.Y, -value.Z);
    }

    /// <summary>
    /// Returns a <see cref="Sedulous.Mathematics.Vector3"/> containing the 3D Cartesian coordinates of a point specified in Barycentric coordinates relative to a 3D triangle.
    /// </summary>
    /// <param name="value1">A <see cref="Sedulous.Mathematics.Vector3"/> containing the 3D Cartesian coordinates of vertex 1 of the triangle.</param>
    /// <param name="value2">A <see cref="Sedulous.Mathematics.Vector3"/> containing the 3D Cartesian coordinates of vertex 2 of the triangle.</param>
    /// <param name="value3">A <see cref="Sedulous.Mathematics.Vector3"/> containing the 3D Cartesian coordinates of vertex 3 of the triangle.</param>
    /// <param name="amount1">Barycentric coordinate b2, which expresses the weighting factor toward vertex 2 (specified in <paramref name="value2"/>).</param>
    /// <param name="amount2">Barycentric coordinate b3, which expresses the weighting factor toward vertex 3 (specified in <paramref name="value3"/>).</param>
    /// <param name="result">When the method completes, contains the 3D Cartesian coordinates of the specified point.</param>
    public static void Barycentric(Vector3 value1, Vector3 value2, Vector3 value3, float amount1, float amount2, out Vector3 result)
    {
        result = Vector3(
            (value1.X + (amount1 * (value2.X - value1.X))) + (amount2 * (value3.X - value1.X)),
            (value1.Y + (amount1 * (value2.Y - value1.Y))) + (amount2 * (value3.Y - value1.Y)),
            (value1.Z + (amount1 * (value2.Z - value1.Z))) + (amount2 * (value3.Z - value1.Z)));
    }

    /// <summary>
    /// Returns a <see cref="Sedulous.Mathematics.Vector3"/> containing the 3D Cartesian coordinates of a point specified in Barycentric coordinates relative to a 3D triangle.
    /// </summary>
    /// <param name="value1">A <see cref="Sedulous.Mathematics.Vector3"/> containing the 3D Cartesian coordinates of vertex 1 of the triangle.</param>
    /// <param name="value2">A <see cref="Sedulous.Mathematics.Vector3"/> containing the 3D Cartesian coordinates of vertex 2 of the triangle.</param>
    /// <param name="value3">A <see cref="Sedulous.Mathematics.Vector3"/> containing the 3D Cartesian coordinates of vertex 3 of the triangle.</param>
    /// <param name="amount1">Barycentric coordinate b2, which expresses the weighting factor toward vertex 2 (specified in <paramref name="value2"/>).</param>
    /// <param name="amount2">Barycentric coordinate b3, which expresses the weighting factor toward vertex 3 (specified in <paramref name="value3"/>).</param>
    /// <returns>A new <see cref="Sedulous.Mathematics.Vector3"/> containing the 3D Cartesian coordinates of the specified point.</returns>
    public static Vector3 Barycentric(Vector3 value1, Vector3 value2, Vector3 value3, float amount1, float amount2)
    {
        Barycentric(value1, value2, value3, amount1, amount2, var result);
        return result;
    }

    /// <summary>
    /// Restricts a value to be within a specified range.
    /// </summary>
    /// <param name="value">The value to clamp.</param>
    /// <param name="min">The minimum value.</param>
    /// <param name="max">The maximum value.</param>
    /// <param name="result">When the method completes, contains the clamped value.</param>
    public static void Clamp(Vector3 value, Vector3 min, Vector3 max, out Vector3 result)
    {
        float x = value.X;
        x = (x > max.X) ? max.X : x;
        x = (x < min.X) ? min.X : x;

        float y = value.Y;
        y = (y > max.Y) ? max.Y : y;
        y = (y < min.Y) ? min.Y : y;

        float z = value.Z;
        z = (z > max.Z) ? max.Z : z;
        z = (z < min.Z) ? min.Z : z;

        result = Vector3(x, y, z);
    }

    /// <summary>
    /// Restricts a value to be within a specified range.
    /// </summary>
    /// <param name="value">The value to clamp.</param>
    /// <param name="min">The minimum value.</param>
    /// <param name="max">The maximum value.</param>
    /// <returns>The clamped value.</returns>
    public static Vector3 Clamp(Vector3 value, Vector3 min, Vector3 max)
    {
        Clamp(value, min, max, var result);
        return result;
    }

    /// <summary>
    /// Calculates the cross product of two vectors.
    /// </summary>
    /// <param name="left">First source vector.</param>
    /// <param name="right">Second source vector.</param>
    /// <param name="result">When the method completes, contains he cross product of the two vectors.</param>
    public static void Cross(Vector3 left, Vector3 right, out Vector3 result)
    {
        result = Vector3(
            (left.Y * right.Z) - (left.Z * right.Y),
            (left.Z * right.X) - (left.X * right.Z),
            (left.X * right.Y) - (left.Y * right.X));
    }

    /// <summary>
    /// Calculates the cross product of two vectors.
    /// </summary>
    /// <param name="left">First source vector.</param>
    /// <param name="right">Second source vector.</param>
    /// <returns>The cross product of the two vectors.</returns>
    public static Vector3 Cross(in Vector3 left, in Vector3 right)
    {
        return Vector3(
            (left.Y * right.Z) - (left.Z * right.Y),
            (left.Z * right.X) - (left.X * right.Z),
            (left.X * right.Y) - (left.Y * right.X));
    }

    /// <summary>
    /// Calculates the distance between two vectors.
    /// </summary>
    /// <param name="value1">The first vector.</param>
    /// <param name="value2">The second vector.</param>
    /// <param name="result">When the method completes, contains the distance between the two vectors.</param>
    /// <remarks>
    /// <see cref="Sedulous.Mathematics.Vector3.DistanceSquared(Vector3, Vector3, out float)"/> may be preferred when only the relative distance is needed
    /// and speed is of the essence.
    /// </remarks>
    public static void Distance(Vector3 value1, Vector3 value2, out float result)
    {
        float x = value1.X - value2.X;
        float y = value1.Y - value2.Y;
        float z = value1.Z - value2.Z;

        result = Math.Sqrt((x * x) + (y * y) + (z * z));
    }

    /// <summary>
    /// Calculates the distance between two vectors.
    /// </summary>
    /// <param name="value1">The first vector.</param>
    /// <param name="value2">The second vector.</param>
    /// <returns>The distance between the two vectors.</returns>
    /// <remarks>
    /// <see cref="Sedulous.Mathematics.Vector3.DistanceSquared(Vector3, Vector3)"/> may be preferred when only the relative distance is needed
    /// and speed is of the essence.
    /// </remarks>
    public static float Distance(Vector3 value1, Vector3 value2)
    {
        float x = value1.X - value2.X;
        float y = value1.Y - value2.Y;
        float z = value1.Z - value2.Z;

        return Math.Sqrt((x * x) + (y * y) + (z * z));
    }

    /// <summary>
    /// Calculates the squared distance between two vectors.
    /// </summary>
    /// <param name="value1">The first vector.</param>
    /// <param name="value2">The second vector.</param>
    /// <param name="result">When the method completes, contains the squared distance between the two vectors.</param>
    /// <remarks>Distance squared is the value before taking the square root. 
    /// Distance squared can often be used in place of distance if relative comparisons are being made. 
    /// For example, consider three points A, B, and C. To determine whether B or C is further from A, 
    /// compare the distance between A and B to the distance between A and C. Calculating the two distances 
    /// involves two square roots, which are computationally expensive. However, using distance squared 
    /// provides the same information and avoids calculating two square roots.
    /// </remarks>
    public static void DistanceSquared(Vector3 value1, Vector3 value2, out float result)
    {
        float x = value1.X - value2.X;
        float y = value1.Y - value2.Y;
        float z = value1.Z - value2.Z;

        result = (x * x) + (y * y) + (z * z);
    }

    /// <summary>
    /// Calculates the squared distance between two vectors.
    /// </summary>
    /// <param name="value1">The first vector.</param>
    /// <param name="value2">The second vector.</param>
    /// <returns>The squared distance between the two vectors.</returns>
    /// <remarks>Distance squared is the value before taking the square root. 
    /// Distance squared can often be used in place of distance if relative comparisons are being made. 
    /// For example, consider three points A, B, and C. To determine whether B or C is further from A, 
    /// compare the distance between A and B to the distance between A and C. Calculating the two distances 
    /// involves two square roots, which are computationally expensive. However, using distance squared 
    /// provides the same information and avoids calculating two square roots.
    /// </remarks>
    public static float DistanceSquared(Vector3 value1, Vector3 value2)
    {
        float x = value1.X - value2.X;
        float y = value1.Y - value2.Y;
        float z = value1.Z - value2.Z;

        return (x * x) + (y * y) + (z * z);
    }

    /// <summary>
    /// Calculates the dot product of two vectors.
    /// </summary>
    /// <param name="left">First source vector.</param>
    /// <param name="right">Second source vector.</param>
    /// <param name="result">When the method completes, contains the dot product of the two vectors.</param>
    [Inline]
    public static void Dot(Vector3 left, Vector3 right, out float result)
    {
        result = (left.X * right.X) + (left.Y * right.Y) + (left.Z * right.Z);
    }

    /// <summary>
    /// Calculates the dot product of two vectors.
    /// </summary>
    /// <param name="left">First source vector.</param>
    /// <param name="right">Second source vector.</param>
    /// <returns>The dot product of the two vectors.</returns>
    [Inline]
    public static float Dot(Vector3 left, Vector3 right)
    {
        return (left.X * right.X) + (left.Y * right.Y) + (left.Z * right.Z);
    }

    /// <summary>
    /// Converts the vector into a unit vector.
    /// </summary>
    /// <param name="value">The vector to normalize.</param>
    /// <param name="result">When the method completes, contains the normalized vector.</param>
    [Inline]
    public static void Normalize(Vector3 value, out Vector3 result)
    {
        result = value;
        result.Normalize();
    }

    /// <summary>
    /// Converts the vector into a unit vector.
    /// </summary>
    /// <param name="value">The vector to normalize.</param>
    /// <returns>The normalized vector.</returns>
    [Inline]
    public static Vector3 Normalize(Vector3 value)
    {
		var value;
        value.Normalize();
        return value;
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
    /// <code>start + (end - start) * amount</code>
    /// Passing <paramref name="amount"/> a value of 0 will cause <paramref name="start"/> to be returned; a value of 1 will cause <paramref name="end"/> to be returned. 
    /// </remarks>
    public static void Lerp(Vector3 start, Vector3 end, float amount, out Vector3 result)
    {
        result.X = start.X + ((end.X - start.X) * amount);
        result.Y = start.Y + ((end.Y - start.Y) * amount);
        result.Z = start.Z + ((end.Z - start.Z) * amount);
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
    /// <code>start + (end - start) * amount</code>
    /// Passing <paramref name="amount"/> a value of 0 will cause <paramref name="start"/> to be returned; a value of 1 will cause <paramref name="end"/> to be returned. 
    /// </remarks>
    public static Vector3 Lerp(Vector3 start, Vector3 end, float amount)
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
    public static void SmoothStep(Vector3 start, Vector3 end, float amount, out Vector3 result)
    {
		var amount;
        amount = (amount > 1.0f) ? 1.0f : ((amount < 0.0f) ? 0.0f : amount);
        amount = (amount * amount) * (3.0f - (2.0f * amount));

        result.X = start.X + ((end.X - start.X) * amount);
        result.Y = start.Y + ((end.Y - start.Y) * amount);
        result.Z = start.Z + ((end.Z - start.Z) * amount);
    }

    /// <summary>
    /// Performs a cubic interpolation between two vectors.
    /// </summary>
    /// <param name="start">Start vector.</param>
    /// <param name="end">End vector.</param>
    /// <param name="amount">Value between 0 and 1 indicating the weight of <paramref name="end"/>.</param>
    /// <returns>The cubic interpolation of the two vectors.</returns>
    public static Vector3 SmoothStep(Vector3 start, Vector3 end, float amount)
    {
        SmoothStep(start, end, amount, var result);
        return result;
    }

    /// <summary>
    /// Performs a Hermite spline interpolation.
    /// </summary>
    /// <param name="value1">First source position vector.</param>
    /// <param name="tangent1">First source tangent vector.</param>
    /// <param name="value2">Second source position vector.</param>
    /// <param name="tangent2">Second source tangent vector.</param>
    /// <param name="amount">Weighting factor.</param>
    /// <param name="result">When the method completes, contains the result of the Hermite spline interpolation.</param>
    public static void Hermite(Vector3 value1, Vector3 tangent1, Vector3 value2, Vector3 tangent2, float amount, out Vector3 result)
    {
        float squared = amount * amount;
        float cubed = amount * squared;
        float part1 = ((2.0f * cubed) - (3.0f * squared)) + 1.0f;
        float part2 = (-2.0f * cubed) + (3.0f * squared);
        float part3 = (cubed - (2.0f * squared)) + amount;
        float part4 = cubed - squared;

        result.X = (((value1.X * part1) + (value2.X * part2)) + (tangent1.X * part3)) + (tangent2.X * part4);
        result.Y = (((value1.Y * part1) + (value2.Y * part2)) + (tangent1.Y * part3)) + (tangent2.Y * part4);
        result.Z = (((value1.Z * part1) + (value2.Z * part2)) + (tangent1.Z * part3)) + (tangent2.Z * part4);
    }

    /// <summary>
    /// Performs a Hermite spline interpolation.
    /// </summary>
    /// <param name="value1">First source position vector.</param>
    /// <param name="tangent1">First source tangent vector.</param>
    /// <param name="value2">Second source position vector.</param>
    /// <param name="tangent2">Second source tangent vector.</param>
    /// <param name="amount">Weighting factor.</param>
    /// <returns>The result of the Hermite spline interpolation.</returns>
    public static Vector3 Hermite(Vector3 value1, Vector3 tangent1, Vector3 value2, Vector3 tangent2, float amount)
    {
        Hermite(value1, tangent1, value2, tangent2, amount, var result);
        return result;
    }

    /// <summary>
    /// Performs a Catmull-Rom interpolation using the specified positions.
    /// </summary>
    /// <param name="value1">The first position in the interpolation.</param>
    /// <param name="value2">The second position in the interpolation.</param>
    /// <param name="value3">The third position in the interpolation.</param>
    /// <param name="value4">The fourth position in the interpolation.</param>
    /// <param name="amount">Weighting factor.</param>
    /// <param name="result">When the method completes, contains the result of the Catmull-Rom interpolation.</param>
    public static void CatmullRom(Vector3 value1, Vector3 value2, Vector3 value3, Vector3 value4, float amount, out Vector3 result)
    {
        float squared = amount * amount;
        float cubed = amount * squared;

        result.X = 0.5f * ((((2.0f * value2.X) + ((-value1.X + value3.X) * amount)) +
        (((((2.0f * value1.X) - (5.0f * value2.X)) + (4.0f * value3.X)) - value4.X) * squared)) +
        ((((-value1.X + (3.0f * value2.X)) - (3.0f * value3.X)) + value4.X) * cubed));

        result.Y = 0.5f * ((((2.0f * value2.Y) + ((-value1.Y + value3.Y) * amount)) +
            (((((2.0f * value1.Y) - (5.0f * value2.Y)) + (4.0f * value3.Y)) - value4.Y) * squared)) +
            ((((-value1.Y + (3.0f * value2.Y)) - (3.0f * value3.Y)) + value4.Y) * cubed));

        result.Z = 0.5f * ((((2.0f * value2.Z) + ((-value1.Z + value3.Z) * amount)) +
            (((((2.0f * value1.Z) - (5.0f * value2.Z)) + (4.0f * value3.Z)) - value4.Z) * squared)) +
            ((((-value1.Z + (3.0f * value2.Z)) - (3.0f * value3.Z)) + value4.Z) * cubed));
    }

    /// <summary>
    /// Performs a Catmull-Rom interpolation using the specified positions.
    /// </summary>
    /// <param name="value1">The first position in the interpolation.</param>
    /// <param name="value2">The second position in the interpolation.</param>
    /// <param name="value3">The third position in the interpolation.</param>
    /// <param name="value4">The fourth position in the interpolation.</param>
    /// <param name="amount">Weighting factor.</param>
    /// <returns>A vector that is the result of the Catmull-Rom interpolation.</returns>
    public static Vector3 CatmullRom(Vector3 value1, Vector3 value2, Vector3 value3, Vector3 value4, float amount)
    {
        CatmullRom(value1, value2, value3, value4, amount, var result);
        return result;
    }

    /// <summary>
    /// Performs mathematical modulo component-wise (see MathUtil.Mod).
    /// </summary>
    /// <param name="left">The first source vector.</param>
    /// <param name="right">The second source vector.</param>
    /// <param name="result">When the method completes, contains an new vector composed of each component's modulo.</param>
    [Inline]
    public static void Mod(Vector3 left, Vector3 right, out Vector3 result)
    {
        result.X = MathUtil.Mod(left.X, right.X);
        result.Y = MathUtil.Mod(left.Y, right.Y);
        result.Z = MathUtil.Mod(left.Z, right.Z);
    }

    /// <summary>
    /// Performs mathematical modulo component-wise (see MathUtil.Mod).
    /// </summary>
    /// <param name="left">The first source vector.</param>
    /// <param name="right">The second source vector.</param>
    /// <returns>When the method completes, contains an new vector composed of each component's modulo.</returns>
    [Inline]
    public static Vector3 Mod(Vector3 left, Vector3 right)
    {
        Mod(left, right, var result);
        return result;
    }

    /// <summary>
    /// Returns a vector containing the largest components of the specified vectors.
    /// </summary>
    /// <param name="left">The first source vector.</param>
    /// <param name="right">The second source vector.</param>
    /// <param name="result">When the method completes, contains an new vector composed of the largest components of the source vectors.</param>
    [Inline]
    public static void Max(Vector3 left, Vector3 right, out Vector3 result)
    {
        result.X = (left.X > right.X) ? left.X : right.X;
        result.Y = (left.Y > right.Y) ? left.Y : right.Y;
        result.Z = (left.Z > right.Z) ? left.Z : right.Z;
    }

    /// <summary>
    /// Returns a vector containing the largest components of the specified vectors.
    /// </summary>
    /// <param name="left">The first source vector.</param>
    /// <param name="right">The second source vector.</param>
    /// <returns>A vector containing the largest components of the source vectors.</returns>
    [Inline]
    public static Vector3 Max(Vector3 left, Vector3 right)
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
    [Inline]
    public static void Min(Vector3 left, Vector3 right, out Vector3 result)
    {
        result.X = (left.X < right.X) ? left.X : right.X;
        result.Y = (left.Y < right.Y) ? left.Y : right.Y;
        result.Z = (left.Z < right.Z) ? left.Z : right.Z;
    }

    /// <summary>
    /// Returns a vector containing the smallest components of the specified vectors.
    /// </summary>
    /// <param name="left">The first source vector.</param>
    /// <param name="right">The second source vector.</param>
    /// <returns>A vector containing the smallest components of the source vectors.</returns>
    [Inline]
    public static Vector3 Min(Vector3 left, Vector3 right)
    {
        Min(left, right, var result);
        return result;
    }

    /// <summary>
    /// Projects a 3D vector from object space into screen space. 
    /// </summary>
    /// <param name="vector">The vector to project.</param>
    /// <param name="x">The X position of the viewport.</param>
    /// <param name="y">The Y position of the viewport.</param>
    /// <param name="width">The width of the viewport.</param>
    /// <param name="height">The height of the viewport.</param>
    /// <param name="minZ">The minimum depth of the viewport.</param>
    /// <param name="maxZ">The maximum depth of the viewport.</param>
    /// <param name="worldViewProjection">The combined world-view-projection matrix.</param>
    /// <param name="result">When the method completes, contains the vector in screen space.</param>
    public static void Project(Vector3 vector, float x, float y, float width, float height, float minZ, float maxZ, Matrix worldViewProjection, out Vector3 result)
    {
        TransformCoordinate(vector, worldViewProjection, var v);

        result = Vector3(((1.0f + v.X) * 0.5f * width) + x, ((1.0f - v.Y) * 0.5f * height) + y, (v.Z * (maxZ - minZ)) + minZ);
    }

    /// <summary>
    /// Projects a 3D vector from object space into screen space. 
    /// </summary>
    /// <param name="vector">The vector to project.</param>
    /// <param name="x">The X position of the viewport.</param>
    /// <param name="y">The Y position of the viewport.</param>
    /// <param name="width">The width of the viewport.</param>
    /// <param name="height">The height of the viewport.</param>
    /// <param name="minZ">The minimum depth of the viewport.</param>
    /// <param name="maxZ">The maximum depth of the viewport.</param>
    /// <param name="worldViewProjection">The combined world-view-projection matrix.</param>
    /// <returns>The vector in screen space.</returns>
    public static Vector3 Project(Vector3 vector, float x, float y, float width, float height, float minZ, float maxZ, Matrix worldViewProjection)
    {
        Project(vector, x, y, width, height, minZ, maxZ, worldViewProjection, var result);
        return result;
    }

    /// <summary>
    /// Projects a 3D vector from screen space into object space. 
    /// </summary>
    /// <param name="vector">The vector to project.</param>
    /// <param name="x">The X position of the viewport.</param>
    /// <param name="y">The Y position of the viewport.</param>
    /// <param name="width">The width of the viewport.</param>
    /// <param name="height">The height of the viewport.</param>
    /// <param name="minZ">The minimum depth of the viewport.</param>
    /// <param name="maxZ">The maximum depth of the viewport.</param>
    /// <param name="worldViewProjection">The combined world-view-projection matrix.</param>
    /// <param name="result">When the method completes, contains the vector in object space.</param>
    public static void Unproject(Vector3 vector, float x, float y, float width, float height, float minZ, float maxZ, Matrix worldViewProjection, out Vector3 result)
    {
        Vector3 v = Vector3();
        Matrix.Invert(worldViewProjection, var matrix);

        v.X = (((vector.X - x) / width) * 2.0f) - 1.0f;
        v.Y = -((((vector.Y - y) / height) * 2.0f) - 1.0f);
        v.Z = (vector.Z - minZ) / (maxZ - minZ);

        TransformCoordinate(v, matrix, out result);
    }

    /// <summary>
    /// Projects a 3D vector from screen space into object space. 
    /// </summary>
    /// <param name="vector">The vector to project.</param>
    /// <param name="x">The X position of the viewport.</param>
    /// <param name="y">The Y position of the viewport.</param>
    /// <param name="width">The width of the viewport.</param>
    /// <param name="height">The height of the viewport.</param>
    /// <param name="minZ">The minimum depth of the viewport.</param>
    /// <param name="maxZ">The maximum depth of the viewport.</param>
    /// <param name="worldViewProjection">The combined world-view-projection matrix.</param>
    /// <returns>The vector in object space.</returns>
    public static Vector3 Unproject(Vector3 vector, float x, float y, float width, float height, float minZ, float maxZ, Matrix worldViewProjection)
    {
        Unproject(vector, x, y, width, height, minZ, maxZ, worldViewProjection, var result);
        return result;
    }

    /// <summary>
    /// Returns the reflection of a vector off a surface that has the specified normal. 
    /// </summary>
    /// <param name="vector">The source vector.</param>
    /// <param name="normal">Normal of the surface.</param>
    /// <param name="result">When the method completes, contains the reflected vector.</param>
    /// <remarks>Reflect only gives the direction of a reflection off a surface, it does not determine 
    /// whether the original vector was close enough to the surface to hit it.</remarks>
    public static void Reflect(Vector3 vector, Vector3 normal, out Vector3 result)
    {
        float dot = (vector.X * normal.X) + (vector.Y * normal.Y) + (vector.Z * normal.Z);

        result.X = vector.X - ((2.0f * dot) * normal.X);
        result.Y = vector.Y - ((2.0f * dot) * normal.Y);
        result.Z = vector.Z - ((2.0f * dot) * normal.Z);
    }

    /// <summary>
    /// Returns the reflection of a vector off a surface that has the specified normal. 
    /// </summary>
    /// <param name="vector">The source vector.</param>
    /// <param name="normal">Normal of the surface.</param>
    /// <returns>The reflected vector.</returns>
    /// <remarks>Reflect only gives the direction of a reflection off a surface, it does not determine 
    /// whether the original vector was close enough to the surface to hit it.</remarks>
    public static Vector3 Reflect(Vector3 vector, Vector3 normal)
    {
        Reflect(vector, normal, var result);
        return result;
    }

    /// <summary>
    /// Orthogonalizes a list of vectors.
    /// </summary>
    /// <param name="destination">The list of orthogonalized vectors.</param>
    /// <param name="source">The list of vectors to orthogonalize.</param>
    /// <remarks>
    /// <para>Orthogonalization is the process of making all vectors orthogonal to each other. This
    /// means that any given vector in the list will be orthogonal to any other given vector in the
    /// list.</para>
    /// <para>Because this method uses the modified Gram-Schmidt process, the resulting vectors
    /// tend to be numerically unstable. The numeric stability decreases according to the vectors
    /// position in the list so that the first vector is the most stable and the last vector is the
    /// least stable.</para>
    /// </remarks>
    /// <exception cref="ArgumentNullException">Thrown when <paramref name="source"/> or <paramref name="destination"/> is <c>null</c>.</exception>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when <paramref name="destination"/> is shorter in length than <paramref name="source"/>.</exception>
    public static void Orthogonalize(Vector3[] destination, params Vector3[] source)
    {
        //Uses the modified Gram-Schmidt process.
        //q1 = m1
        //q2 = m2 - ((q1 ⋅ m2) / (q1 ⋅ q1)) * q1
        //q3 = m3 - ((q1 ⋅ m3) / (q1 ⋅ q1)) * q1 - ((q2 ⋅ m3) / (q2 ⋅ q2)) * q2
        //q4 = m4 - ((q1 ⋅ m4) / (q1 ⋅ q1)) * q1 - ((q2 ⋅ m4) / (q2 ⋅ q2)) * q2 - ((q3 ⋅ m4) / (q3 ⋅ q3)) * q3
        //q5 = ...
		
		if (source == null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(source)}");
		if (destination == null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(destination)}");
        if (destination.Count< source.Count)
            Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(destination)}: The destination array must be of same length or larger length than the source array.");

        for (int32 i = 0; i < source.Count; ++i)
        {
            Vector3 newvector = source[i];

            for (int32 r = 0; r < i; ++r)
            {
                newvector -= (Vector3.Dot(destination[r], newvector) / Vector3.Dot(destination[r], destination[r])) * destination[r];
            }

            destination[i] = newvector;
        }
    }

    /// <summary>
    /// Orthonormalizes a list of vectors.
    /// </summary>
    /// <param name="destination">The list of orthonormalized vectors.</param>
    /// <param name="source">The list of vectors to orthonormalize.</param>
    /// <remarks>
    /// <para>Orthonormalization is the process of making all vectors orthogonal to each
    /// other and making all vectors of unit length. This means that any given vector will
    /// be orthogonal to any other given vector in the list.</para>
    /// <para>Because this method uses the modified Gram-Schmidt process, the resulting vectors
    /// tend to be numerically unstable. The numeric stability decreases according to the vectors
    /// position in the list so that the first vector is the most stable and the last vector is the
    /// least stable.</para>
    /// </remarks>
    /// <exception cref="ArgumentNullException">Thrown when <paramref name="source"/> or <paramref name="destination"/> is <c>null</c>.</exception>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when <paramref name="destination"/> is shorter in length than <paramref name="source"/>.</exception>
    public static void Orthonormalize(Vector3[] destination, params Vector3[] source)
    {
        //Uses the modified Gram-Schmidt process.
        //Because we are making unit vectors, we can optimize the math for orthogonalization
        //and simplify the projection operation to remove the division.
        //q1 = m1 / |m1|
        //q2 = (m2 - (q1 ⋅ m2) * q1) / |m2 - (q1 ⋅ m2) * q1|
        //q3 = (m3 - (q1 ⋅ m3) * q1 - (q2 ⋅ m3) * q2) / |m3 - (q1 ⋅ m3) * q1 - (q2 ⋅ m3) * q2|
        //q4 = (m4 - (q1 ⋅ m4) * q1 - (q2 ⋅ m4) * q2 - (q3 ⋅ m4) * q3) / |m4 - (q1 ⋅ m4) * q1 - (q2 ⋅ m4) * q2 - (q3 ⋅ m4) * q3|
        //q5 = ...
		
		if (source == null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(source)}");
		if (destination == null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(destination)}");
        if (destination.Count< source.Count)
            Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(destination)}: The destination array must be of same length or larger length than the source array.");

        for (int32 i = 0; i < source.Count; ++i)
        {
            Vector3 newvector = source[i];

            for (int32 r = 0; r < i; ++r)
            {
                newvector -= Vector3.Dot(destination[r], newvector) * destination[r];
            }

            newvector.Normalize();
            destination[i] = newvector;
        }
    }

    /// <summary>
    /// Transforms a 3D vector by the given <see cref="Sedulous.Mathematics.Quaternion"/> rotation.
    /// </summary>
    /// <param name="vector">The vector to rotate.</param>
    /// <param name="rotation">The <see cref="Sedulous.Mathematics.Quaternion"/> rotation to apply.</param>
    /// <param name="result">When the method completes, contains the transformed <see cref="Sedulous.Mathematics.Vector4"/>.</param>
    public static void Transform(Vector3 vector, Quaternion rotation, out Vector3 result)
    {
        float x = rotation.X + rotation.X;
        float y = rotation.Y + rotation.Y;
        float z = rotation.Z + rotation.Z;
        float wx = rotation.W * x;
        float wy = rotation.W * y;
        float wz = rotation.W * z;
        float xx = rotation.X * x;
        float xy = rotation.X * y;
        float xz = rotation.X * z;
        float yy = rotation.Y * y;
        float yz = rotation.Y * z;
        float zz = rotation.Z * z;

        result = Vector3(
            ((vector.X * ((1.0f - yy) - zz)) + (vector.Y * (xy - wz))) + (vector.Z * (xz + wy)),
            ((vector.X * (xy + wz)) + (vector.Y * ((1.0f - xx) - zz))) + (vector.Z * (yz - wx)),
            ((vector.X * (xz - wy)) + (vector.Y * (yz + wx))) + (vector.Z * ((1.0f - xx) - yy)));
    }

    /// <summary>
    /// Transforms a 3D vector by the given <see cref="Sedulous.Mathematics.Quaternion"/> rotation.
    /// </summary>
    /// <param name="vector">The vector to rotate.</param>
    /// <param name="rotation">The <see cref="Sedulous.Mathematics.Quaternion"/> rotation to apply.</param>
    /// <returns>The transformed <see cref="Sedulous.Mathematics.Vector4"/>.</returns>
    public static Vector3 Transform(Vector3 vector, Quaternion rotation)
    {
        Transform(vector, rotation, var result);
        return result;
    }

    /// <summary>
    /// Transforms an array of vectors by the given <see cref="Sedulous.Mathematics.Quaternion"/> rotation.
    /// </summary>
    /// <param name="source">The array of vectors to transform.</param>
    /// <param name="rotation">The <see cref="Sedulous.Mathematics.Quaternion"/> rotation to apply.</param>
    /// <param name="destination">The array for which the transformed vectors are stored.
    /// This array may be the same array as <paramref name="source"/>.</param>
    /// <exception cref="ArgumentNullException">Thrown when <paramref name="source"/> or <paramref name="destination"/> is <c>null</c>.</exception>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when <paramref name="destination"/> is shorter in length than <paramref name="source"/>.</exception>
    public static void Transform(Vector3[] source, Quaternion rotation, Vector3[] destination)
    {
        if (source == null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(source)}");
        if (destination == null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(destination)}");
        if (destination.Count< source.Count)
            Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(destination)}: The destination array must be of same length or larger length than the source array.");

        float x = rotation.X + rotation.X;
        float y = rotation.Y + rotation.Y;
        float z = rotation.Z + rotation.Z;
        float wx = rotation.W * x;
        float wy = rotation.W * y;
        float wz = rotation.W * z;
        float xx = rotation.X * x;
        float xy = rotation.X * y;
        float xz = rotation.X * z;
        float yy = rotation.Y * y;
        float yz = rotation.Y * z;
        float zz = rotation.Z * z;

        float num1 = ((1.0f - yy) - zz);
        float num2 = (xy - wz);
        float num3 = (xz + wy);
        float num4 = (xy + wz);
        float num5 = ((1.0f - xx) - zz);
        float num6 = (yz - wx);
        float num7 = (xz - wy);
        float num8 = (yz + wx);
        float num9 = ((1.0f - xx) - yy);

        for (int32 i = 0; i < source.Count; ++i)
        {
            destination[i] = Vector3(
                ((source[i].X * num1) + (source[i].Y * num2)) + (source[i].Z * num3),
                ((source[i].X * num4) + (source[i].Y * num5)) + (source[i].Z * num6),
                ((source[i].X * num7) + (source[i].Y * num8)) + (source[i].Z * num9));
        }
    }

    /// <summary>
    /// Transforms a 3D vector by the given <see cref="Sedulous.Mathematics.Matrix"/>.
    /// </summary>
    /// <param name="vector">The source vector.</param>
    /// <param name="transform">The transformation <see cref="Sedulous.Mathematics.Matrix"/>.</param>
    /// <param name="result">When the method completes, contains the transformed <see cref="Sedulous.Mathematics.Vector4"/>.</param>
    public static void Transform(Vector3 vector, Matrix transform, out Vector4 result)
    {
        result = Vector4(
            (vector.X * transform.M11) + (vector.Y * transform.M21) + (vector.Z * transform.M31) + transform.M41,
            (vector.X * transform.M12) + (vector.Y * transform.M22) + (vector.Z * transform.M32) + transform.M42,
            (vector.X * transform.M13) + (vector.Y * transform.M23) + (vector.Z * transform.M33) + transform.M43,
            (vector.X * transform.M14) + (vector.Y * transform.M24) + (vector.Z * transform.M34) + transform.M44);
    }

    /// <summary>
    /// Transforms a 3D vector by the given <see cref="Sedulous.Mathematics.Matrix"/>.
    /// </summary>
    /// <param name="vector">The source vector.</param>
    /// <param name="transform">The transformation <see cref="Sedulous.Mathematics.Matrix"/>.</param>
    /// <param name="result">When the method completes, contains the transformed <see cref="Sedulous.Mathematics.Vector3"/>.</param>
    public static void Transform(Vector3 vector, Matrix transform, out Vector3 result)
    {
        result = Vector3(
            (vector.X * transform.M11) + (vector.Y * transform.M21) + (vector.Z * transform.M31) + transform.M41,
            (vector.X * transform.M12) + (vector.Y * transform.M22) + (vector.Z * transform.M32) + transform.M42,
            (vector.X * transform.M13) + (vector.Y * transform.M23) + (vector.Z * transform.M33) + transform.M43);
    }

    /// <summary>
    /// Transforms a 3D vector by the given <see cref="Sedulous.Mathematics.Matrix"/>.
    /// </summary>
    /// <param name="vector">The source vector.</param>
    /// <param name="transform">The transformation <see cref="Sedulous.Mathematics.Matrix"/>.</param>
    /// <returns>The transformed <see cref="Sedulous.Mathematics.Vector4"/>.</returns>
    public static Vector4 Transform(Vector3 vector, Matrix transform)
    {
		Vector4 result;
        Transform(vector, transform, out result);
        return result;
    }

    /// <summary>
    /// Transforms an array of 3D vectors by the given <see cref="Sedulous.Mathematics.Matrix"/>.
    /// </summary>
    /// <param name="source">The array of vectors to transform.</param>
    /// <param name="transform">The transformation <see cref="Sedulous.Mathematics.Matrix"/>.</param>
    /// <param name="destination">The array for which the transformed vectors are stored.</param>
    /// <exception cref="ArgumentNullException">Thrown when <paramref name="source"/> or <paramref name="destination"/> is <c>null</c>.</exception>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when <paramref name="destination"/> is shorter in length than <paramref name="source"/>.</exception>
    public static void Transform(Vector3[] source, Matrix transform, Vector4[] destination)
    {
        if (source == null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(source)}");
        if (destination == null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(destination)}");
        if (destination.Count< source.Count)
            Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(destination)}: The destination array must be of same length or larger length than the source array.");

        for (int32 i = 0; i < source.Count; ++i)
        {
            Transform(source[i], transform, out destination[i]);
        }
    }

    /// <summary>
    /// Performs a coordinate transformation using the given <see cref="Sedulous.Mathematics.Matrix"/>.
    /// </summary>
    /// <param name="coordinate">The coordinate vector to transform.</param>
    /// <param name="transform">The transformation <see cref="Sedulous.Mathematics.Matrix"/>.</param>
    /// <param name="result">When the method completes, contains the transformed coordinates.</param>
    /// <remarks>
    /// A coordinate transform performs the transformation with the assumption that the w component
    /// is one. The four dimensional vector obtained from the transformation operation has each
    /// component in the vector divided by the w component. This forces the wcomponent to be one and
    /// therefore makes the vector homogeneous. The homogeneous vector is often prefered when working
    /// with coordinates as the w component can safely be ignored.
    /// </remarks>
    public static void TransformCoordinate(Vector3 coordinate, Matrix transform, out Vector3 result)
    {
        var invW = 1f / ((coordinate.X * transform.M14) + (coordinate.Y * transform.M24) + (coordinate.Z * transform.M34) + transform.M44);
        result = Vector3(
            ((coordinate.X * transform.M11) + (coordinate.Y * transform.M21) + (coordinate.Z * transform.M31) + transform.M41) * invW,
            ((coordinate.X * transform.M12) + (coordinate.Y * transform.M22) + (coordinate.Z * transform.M32) + transform.M42) * invW,
            ((coordinate.X * transform.M13) + (coordinate.Y * transform.M23) + (coordinate.Z * transform.M33) + transform.M43) * invW);
    }

    /// <summary>
    /// Performs a coordinate transformation using the given <see cref="Sedulous.Mathematics.Matrix"/>.
    /// </summary>
    /// <param name="coordinate">The coordinate vector to transform.</param>
    /// <param name="transform">The transformation <see cref="Sedulous.Mathematics.Matrix"/>.</param>
    /// <returns>The transformed coordinates.</returns>
    /// <remarks>
    /// A coordinate transform performs the transformation with the assumption that the w component
    /// is one. The four dimensional vector obtained from the transformation operation has each
    /// component in the vector divided by the w component. This forces the wcomponent to be one and
    /// therefore makes the vector homogeneous. The homogeneous vector is often prefered when working
    /// with coordinates as the w component can safely be ignored.
    /// </remarks>
    public static Vector3 TransformCoordinate(Vector3 coordinate, Matrix transform)
    {
        TransformCoordinate(coordinate, transform, var result);
        return result;
    }

    /// <summary>
    /// Performs a coordinate transformation on an array of vectors using the given <see cref="Sedulous.Mathematics.Matrix"/>.
    /// </summary>
    /// <param name="source">The array of coordinate vectors to trasnform.</param>
    /// <param name="transform">The transformation <see cref="Sedulous.Mathematics.Matrix"/>.</param>
    /// <param name="destination">The array for which the transformed vectors are stored.
    /// This array may be the same array as <paramref name="source"/>.</param>
    /// <exception cref="ArgumentNullException">Thrown when <paramref name="source"/> or <paramref name="destination"/> is <c>null</c>.</exception>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when <paramref name="destination"/> is shorter in length than <paramref name="source"/>.</exception>
    /// <remarks>
    /// A coordinate transform performs the transformation with the assumption that the w component
    /// is one. The four dimensional vector obtained from the transformation operation has each
    /// component in the vector divided by the w component. This forces the wcomponent to be one and
    /// therefore makes the vector homogeneous. The homogeneous vector is often prefered when working
    /// with coordinates as the w component can safely be ignored.
    /// </remarks>
    public static void TransformCoordinate(Vector3[] source, Matrix transform, Vector3[] destination)
    {
        if (source == null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(source)}");
        if (destination == null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(destination)}");
        if (destination.Count< source.Count)
            Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(destination)}: The destination array must be of same length or larger length than the source array.");

        for (int32 i = 0; i < source.Count; ++i)
        {
            TransformCoordinate(source[i], transform, out destination[i]);
        }
    }

    /// <summary>
    /// Performs a normal transformation using the given <see cref="Sedulous.Mathematics.Matrix"/>.
    /// </summary>
    /// <param name="normal">The normal vector to transform.</param>
    /// <param name="transform">The transformation <see cref="Sedulous.Mathematics.Matrix"/>.</param>
    /// <param name="result">When the method completes, contains the transformed normal.</param>
    /// <remarks>
    /// A normal transform performs the transformation with the assumption that the w component
    /// is zero. This causes the fourth row and fourth collumn of the matrix to be unused. The
    /// end result is a vector that is not translated, but all other transformation properties
    /// apply. This is often prefered for normal vectors as normals purely represent direction
    /// rather than location because normal vectors should not be translated.
    /// </remarks>
    public static void TransformNormal(Vector3 normal, Matrix transform, out Vector3 result)
    {
        result = Vector3(
            (normal.X * transform.M11) + (normal.Y * transform.M21) + (normal.Z * transform.M31),
            (normal.X * transform.M12) + (normal.Y * transform.M22) + (normal.Z * transform.M32),
            (normal.X * transform.M13) + (normal.Y * transform.M23) + (normal.Z * transform.M33));
    }

    /// <summary>
    /// Performs a normal transformation using the given <see cref="Sedulous.Mathematics.Matrix"/>.
    /// </summary>
    /// <param name="normal">The normal vector to transform.</param>
    /// <param name="transform">The transformation <see cref="Sedulous.Mathematics.Matrix"/>.</param>
    /// <returns>The transformed normal.</returns>
    /// <remarks>
    /// A normal transform performs the transformation with the assumption that the w component
    /// is zero. This causes the fourth row and fourth collumn of the matrix to be unused. The
    /// end result is a vector that is not translated, but all other transformation properties
    /// apply. This is often prefered for normal vectors as normals purely represent direction
    /// rather than location because normal vectors should not be translated.
    /// </remarks>
    public static Vector3 TransformNormal(Vector3 normal, Matrix transform)
    {
        TransformNormal(normal, transform, var result);
        return result;
    }

    /// <summary>
    /// Performs a normal transformation on an array of vectors using the given <see cref="Sedulous.Mathematics.Matrix"/>.
    /// </summary>
    /// <param name="source">The array of normal vectors to transform.</param>
    /// <param name="transform">The transformation <see cref="Sedulous.Mathematics.Matrix"/>.</param>
    /// <param name="destination">The array for which the transformed vectors are stored.
    /// This array may be the same array as <paramref name="source"/>.</param>
    /// <exception cref="ArgumentNullException">Thrown when <paramref name="source"/> or <paramref name="destination"/> is <c>null</c>.</exception>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when <paramref name="destination"/> is shorter in length than <paramref name="source"/>.</exception>
    /// <remarks>
    /// A normal transform performs the transformation with the assumption that the w component
    /// is zero. This causes the fourth row and fourth collumn of the matrix to be unused. The
    /// end result is a vector that is not translated, but all other transformation properties
    /// apply. This is often prefered for normal vectors as normals purely represent direction
    /// rather than location because normal vectors should not be translated.
    /// </remarks>
    public static void TransformNormal(Vector3[] source, Matrix transform, Vector3[] destination)
    {
        if (source == null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(source)}");
        if (destination == null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(destination)}");
        if (destination.Count< source.Count)
            Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(destination)}: The destination array must be of same length or larger length than the source array.");

        for (int32 i = 0; i < source.Count; ++i)
        {
            TransformNormal(source[i], transform, out destination[i]);
        }
    }

    /// <summary>
    /// Calculate the yaw/pitch/roll rotation equivalent to the provided quaterion.
    /// </summary>
    /// <param name="quaternion">The input rotation as quaternion</param>
    /// <returns>The equivation yaw/pitch/roll rotation</returns>
    public static Vector3 RotationYawPitchRoll(Quaternion quaternion)
    {
        Vector3 yawPitchRoll;
        Quaternion.RotationYawPitchRoll(quaternion, out yawPitchRoll.X, out yawPitchRoll.Y, out yawPitchRoll.Z);
        return yawPitchRoll;
    }

    /// <summary>
    /// Calculate the yaw/pitch/roll rotation equivalent to the provided quaterion. 
    /// </summary>
    /// <param name="quaternion">The input rotation as quaternion</param>
    /// <param name="yawPitchRoll">The equivation yaw/pitch/roll rotation</param>
    public static void RotationYawPitchRoll(Quaternion quaternion, out Vector3 yawPitchRoll)
    {
        Quaternion.RotationYawPitchRoll(quaternion, out yawPitchRoll.X, out yawPitchRoll.Y, out yawPitchRoll.Z);
    }


    /// <summary>
    /// Rotates the source around the target by the rotation angle around the supplied axis. 
    /// </summary>
    /// <param name="source">The position to rotate.</param>
    /// <param name="target">The point to rotate around.</param>
    /// <param name="axis">The axis of rotation.</param>
    /// <param name="angle">The angle to rotate by in radians.</param>
    /// <returns>The rotated vector.</returns>
    public static Vector3 RotateAround(in Vector3 source, in Vector3 target, in Vector3 axis, float angle)
    {
        Vector3 local = source - target;
        Quaternion q = Quaternion.RotationAxis(axis, angle);
        q.Rotate(ref local);
        return target + local;
    }

    /// <summary>
    /// Adds two vectors.
    /// </summary>
    /// <param name="left">The first vector to add.</param>
    /// <param name="right">The second vector to add.</param>
    /// <returns>The sum of the two vectors.</returns>
    [Inline]
    public static Vector3 operator +(in Vector3 left, in Vector3 right)
    {
        return Vector3(left.X + right.X, left.Y + right.Y, left.Z + right.Z);
    }

    /// <summary>
    /// Assert a vector (return it unchanged).
    /// </summary>
    /// <param name="value">The vector to assert (unchange).</param>
    /// <returns>The asserted (unchanged) vector.</returns>
    [Inline]
    public static Vector3 operator +(in Vector3 value)
    {
        return value;
    }

    /// <summary>
    /// Subtracts two vectors.
    /// </summary>
    /// <param name="left">The first vector to subtract.</param>
    /// <param name="right">The second vector to subtract.</param>
    /// <returns>The difference of the two vectors.</returns>
    [Inline]
    public static Vector3 operator -(in Vector3 left, in Vector3 right)
    {
        return Vector3(left.X - right.X, left.Y - right.Y, left.Z - right.Z);
    }

    /// <summary>
    /// Reverses the direction of a given vector.
    /// </summary>
    /// <param name="value">The vector to negate.</param>
    /// <returns>A vector facing in the opposite direction.</returns>
    [Inline]
    public static Vector3 operator -(in Vector3 value)
    {
        return Vector3(-value.X, -value.Y, -value.Z);
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <param name="value">The vector to scale.</param>
    /// <returns>The scaled vector.</returns>
    [Inline]
    public static Vector3 operator *(float scale, in Vector3 value)
    {
        return Vector3(value.X * scale, value.Y * scale, value.Z * scale);
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <returns>The scaled vector.</returns>
    [Inline]
    public static Vector3 operator *(in Vector3 value, float scale)
    {
        return Vector3(value.X * scale, value.Y * scale, value.Z * scale);
    }

    /// <summary>
    /// Modulates a vector with another by performing component-wise multiplication.
    /// </summary>
    /// <param name="left">The first vector to multiply.</param>
    /// <param name="right">The second vector to multiply.</param>
    /// <returns>The multiplication of the two vectors.</returns>
    [Inline]
    public static Vector3 operator *(in Vector3 left, in Vector3 right)
    {
        return Vector3(left.X * right.X, left.Y * right.Y, left.Z * right.Z);
    }

    /// <summary>
    /// Adds a vector with the given value.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <returns>The vector offset.</returns>
    [Inline]
    public static Vector3 operator +(in Vector3 value, float scale)
    {
        return Vector3(value.X + scale, value.Y + scale, value.Z + scale);
    }

    /// <summary>
    /// Substracts a vector by the given value.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <returns>The vector offset.</returns>
    [Inline]
    public static Vector3 operator -(in Vector3 value, float scale)
    {
        return Vector3(value.X - scale, value.Y - scale, value.Z - scale);
    }

    /// <summary>
    /// Divides a numerator by a vector.
    /// </summary>
    /// <param name="numerator">The numerator.</param>
    /// <param name="value">The value.</param>
    /// <returns>The scaled vector.</returns>
    [Inline]
    public static Vector3 operator /(float numerator, in Vector3 value)
    {
        return Vector3(numerator / value.X, numerator / value.Y, numerator / value.Z);
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <returns>The scaled vector.</returns>
    [Inline]
    public static Vector3 operator /(in Vector3 value, float scale)
    {
        return Vector3(value.X / scale, value.Y / scale, value.Z / scale);
    }

    /// <summary>
    /// Divides a vector by the given vector, component-wise.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="by">The by.</param>
    /// <returns>The scaled vector.</returns>
    [Inline]
    public static Vector3 operator /(in Vector3 value, in Vector3 by)
    {
        return Vector3(value.X / by.X, value.Y / by.Y, value.Z / by.Z);
    }

    /// <summary>
    /// Tests for equality between two objects.
    /// </summary>
    /// <remarks> Comparison is not strict, a difference of <see cref="MathUtil.ZeroTolerance"/> will return as equal. </remarks>
    /// <param name="left">The first value to compare.</param>
    /// <param name="right">The second value to compare.</param>
    /// <returns><c>true</c> if <paramref name="left"/> has the same value as <paramref name="right"/>; otherwise, <c>false</c>.</returns>
    public static bool operator ==(Vector3 left, Vector3 right)
    {
        return left.Equals(right);
    }

    /// <summary>
    /// Tests for inequality between two objects.
    /// </summary>
    /// <remarks> Comparison is not strict, a difference of <see cref="MathUtil.ZeroTolerance"/> will return as equal. </remarks>
    /// <param name="left">The first value to compare.</param>
    /// <param name="right">The second value to compare.</param>
    /// <returns><c>true</c> if <paramref name="left"/> has a different value than <paramref name="right"/>; otherwise, <c>false</c>.</returns>
    public static bool operator !=(Vector3 left, Vector3 right)
    {
        return !left.Equals(right);
    }

    /// <summary>
    /// Performs an explicit conversion from <see cref="Sedulous.Mathematics.Vector3"/> to <see cref="Sedulous.Mathematics.Vector2"/>.
    /// </summary>
    /// <param name="value">The value.</param>
    /// <returns>The result of the conversion.</returns>
    public static explicit operator Vector2(in Vector3 value)
    {
        return Vector2(value.X, value.Y);
    }

    /// <summary>
    /// Performs an explicit conversion from <see cref="Sedulous.Mathematics.Vector3"/> to <see cref="Sedulous.Mathematics.Vector4"/>.
    /// </summary>
    /// <param name="value">The value.</param>
    /// <returns>The result of the conversion.</returns>
    public static explicit operator Vector4(in Vector3 value)
    {
        return Vector4(value, 0.0f);
    }

    /// <summary>
    /// Performs an explicit conversion from <see cref="Vector3"/> to <see cref="Int3"/>.
    /// </summary>
    /// <param name="value">The value.</param>
    /// <returns>The result of the conversion.</returns>
    public static explicit operator Int3(in Vector3 value)
    {
        return Int3((int32)value.X, (int32)value.Y, (int32)value.Z);
    }

    /// <summary>
    /// Tests whether one 3D vector is near another 3D vector.
    /// </summary>
    /// <param name="left">The left vector.</param>
    /// <param name="right">The right vector.</param>
    /// <param name="epsilon">The epsilon.</param>
    /// <returns><c>true</c> if left and right are near another 3D, <c>false</c> otherwise</returns>
    public static bool NearEqual(Vector3 left, Vector3 right, Vector3 epsilon)
    {
        return MathUtil.WithinEpsilon(left.X, right.X, epsilon.X) &&
                MathUtil.WithinEpsilon(left.Y, right.Y, epsilon.Y) &&
                MathUtil.WithinEpsilon(left.Z, right.Z, epsilon.Z);
    }
    
    /// <summary>
    /// Returns a <see cref="string"/> that represents this instance.
    /// </summary>
    /// <returns>
    /// A <see cref="string"/> that represents this instance.
    /// </returns>
    public override void ToString(String str) => str.Append( scope $"{{X:{X} Y:{Y} Z:{Z}}}");

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
	        hash = hash * 23 + Z.GetHashCode();
	        return hash;
	    }
	}

    /// <summary>
    /// Determines whether the specified <see cref="Vector3"/> is exactly equal to this instance.
    /// </summary>
    /// <param name="other">The <see cref="Vector3"/> to compare with this instance.</param>
    /// <returns>
    /// <c>true</c> if the specified <see cref="Vector3"/> is exactly equal to this instance; otherwise, <c>false</c>.
    /// </returns>
    public bool EqualsStrict(Vector3 other)
    {
        return other.X == X && other.Y == Y && other.Z == Z;
    }

    /// <summary>
    /// Determines whether the specified <see cref="Sedulous.Mathematics.Vector3"/> is within <see cref="MathUtil.ZeroTolerance"/> for equality to this instance.
    /// </summary>
    /// <param name="other">The <see cref="Sedulous.Mathematics.Vector3"/> to compare with this instance.</param>
    /// <returns>
    /// <c>true</c> if the specified <see cref="Sedulous.Mathematics.Vector3"/> is equal or almost equal to this instance; otherwise, <c>false</c>.
    /// </returns>
    public bool Equals(Vector3 other)
    {
        return Math.Abs(other.X - X) < MathUtil.ZeroTolerance &&
            Math.Abs(other.Y - Y) < MathUtil.ZeroTolerance &&
            Math.Abs(other.Z - Z) < MathUtil.ZeroTolerance;
    }

    /// <summary>
    /// Deconstructs the vector's components into named variables.
    /// </summary>
    /// <param name="x">The X component</param>
    /// <param name="y">The Y component</param>
    /// <param name="z">The Z component</param>
    public void Deconstruct(out float x, out float y, out float z)
    {
        x = X;
        y = Y;
        z = Z;
    }
}
