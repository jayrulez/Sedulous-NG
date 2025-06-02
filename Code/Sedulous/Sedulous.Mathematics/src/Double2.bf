using System;
// Copyright (c) .NET Foundation and Contributors (https://dotnetfoundation.org/ & https://stride3d.net)
// Distributed under the MIT license. See the LICENSE.md file in the project root for more information.

namespace Sedulous.Mathematics;

/// <summary>
/// Represents a two dimensional mathematical vector with double-precision floats.
/// </summary>
public struct Double2 : IEquatable<Double2>
{
    /// <summary>
    /// The size of the <see cref="Double2"/> type, in bytes.
    /// </summary>
    public static readonly int32 SizeInBytes = sizeof(Double2);

    /// <summary>
    /// A <see cref="Double2"/> with all of its components set to zero.
    /// </summary>
    public static readonly Double2 Zero = .();

    /// <summary>
    /// The X unit <see cref="Double2"/> (1, 0).
    /// </summary>
    public static readonly Double2 UnitX = .(1.0, 0.0);

    /// <summary>
    /// The Y unit <see cref="Double2"/> (0, 1).
    /// </summary>
    public static readonly Double2 UnitY = .(0.0, 1.0);

    /// <summary>
    /// A <see cref="Double2"/> with all of its components set to one.
    /// </summary>
    public static readonly Double2 One = .(1.0, 1.0);

    /// <summary>
    /// The X component of the vector.
    /// </summary>
    public double X;

    /// <summary>
    /// The Y component of the vector.
    /// </summary>
    public double Y;

    /// <summary>
    /// Initializes a new instance of the <see cref="Double2"/> struct.
    /// </summary>
    public this()
    {
		double value = 0;
        X = value;
        Y = value;
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Double2"/> struct.
    /// </summary>
    /// <param name="value">The value that will be assigned to all components.</param>
    public this(double value)
    {
        X = value;
        Y = value;
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Double2"/> struct.
    /// </summary>
    /// <param name="x">Initial value for the X component of the vector.</param>
    /// <param name="y">Initial value for the Y component of the vector.</param>
    public this(double x, double y)
    {
        X = x;
        Y = y;
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Double2"/> struct.
    /// </summary>
    /// <param name="v">The Vector2 to construct the Double2 from.</param>
    public this(Vector2 v)
    {
        X = v.X;
        Y = v.Y;
    }

    /// <summary>
    /// Gets a value indicting whether this instance is normalized.
    /// </summary>
    public readonly bool IsNormalized
    {
        get { return Math.Abs((X * X) + (Y * Y) - 1f) < MathUtil.ZeroTolerance; }
    }

    /// <summary>
    /// Gets or sets the component at the specified index.
    /// </summary>
    /// <value>The value of the X or Y component, depending on the index.</value>
    /// <param name="index">The index of the component to access. Use 0 for the X component and 1 for the Y component.</param>
    /// <returns>The value of the component at the specified index.</returns>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when the <paramref name="index"/> is out of the range [0, 1].</exception>
    public double this[int32 index]
    {
        get
        {
			switch (index)
			{
			    case 0: return X;
			    case 1: return Y;
			    default:
			        Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(index)}: Indices for Double2 run from 0 to 1, inclusive.");
			}

        }

        set mut
        {
            switch (index)
            {
                case 0: X = value; break;
                case 1: Y = value; break;
                default: Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(index)}:Indices for Double2 run from 0 to 1, inclusive.");
            }
        }
    }

    /// <summary>
    /// Calculates the length of the vector.
    /// </summary>
    /// <returns>The length of the vector.</returns>
    /// <remarks>
    /// <see cref="Sedulous.Mathematics.Double2.LengthSquared"/> may be preferred when only the relative length is needed
    /// and speed is of the essence.
    /// </remarks>
    [Inline]
    public double Length()
    {
        return (double)Math.Sqrt((X * X) + (Y * Y));
    }

    /// <summary>
    /// Calculates the squared length of the vector.
    /// </summary>
    /// <returns>The squared length of the vector.</returns>
    /// <remarks>
    /// This method may be preferred to <see cref="Sedulous.Mathematics.Double2.Length"/> when only a relative length is needed
    /// and speed is of the essence.
    /// </remarks>
    [Inline]
    public double LengthSquared()
    {
        return (X * X) + (Y * Y);
    }

    /// <summary>
    /// Converts the vector into a unit vector.
    /// </summary>
    [Inline]
    public void Normalize() mut
    {
        double length = Length();
        if (length > MathUtil.ZeroTolerance)
        {
            double inv = 1.0 / length;
            X *= inv;
            Y *= inv;
        }
    }

    /// <summary>
    /// Creates an array containing the elements of the vector.
    /// </summary>
    /// <returns>A two-element array containing the components of the vector.</returns>
    public double[2] ToArray()
    {
        return .(X, Y);
    }

    /// <summary>
    /// Adds two vectors.
    /// </summary>
    /// <param name="left">The first vector to add.</param>
    /// <param name="right">The second vector to add.</param>
    /// <param name="result">When the method completes, contains the sum of the two vectors.</param>
    [Inline]
    public static void Add(Double2 left, Double2 right, out Double2 result)
    {
        result = Double2(left.X + right.X, left.Y + right.Y);
    }

    /// <summary>
    /// Adds two vectors.
    /// </summary>
    /// <param name="left">The first vector to add.</param>
    /// <param name="right">The second vector to add.</param>
    /// <returns>The sum of the two vectors.</returns>
    [Inline]
    public static Double2 Add(Double2 left, Double2 right)
    {
        return Double2(left.X + right.X, left.Y + right.Y);
    }

    /// <summary>
    /// Subtracts two vectors.
    /// </summary>
    /// <param name="left">The first vector to subtract.</param>
    /// <param name="right">The second vector to subtract.</param>
    /// <param name="result">When the method completes, contains the difference of the two vectors.</param>
    [Inline]
    public static void Subtract(Double2 left, Double2 right, out Double2 result)
    {
        result = Double2(left.X - right.X, left.Y - right.Y);
    }

    /// <summary>
    /// Subtracts two vectors.
    /// </summary>
    /// <param name="left">The first vector to subtract.</param>
    /// <param name="right">The second vector to subtract.</param>
    /// <returns>The difference of the two vectors.</returns>
    [Inline]
    public static Double2 Subtract(Double2 left, Double2 right)
    {
        return Double2(left.X - right.X, left.Y - right.Y);
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <param name="result">When the method completes, contains the scaled vector.</param>
    [Inline]
    public static void Multiply(Double2 value, double scale, out Double2 result)
    {
        result = Double2(value.X * scale, value.Y * scale);
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <returns>The scaled vector.</returns>
    [Inline]
    public static Double2 Multiply(Double2 value, double scale)
    {
        return Double2(value.X * scale, value.Y * scale);
    }

    /// <summary>
    /// Modulates a vector with another by performing component-wise multiplication.
    /// </summary>
    /// <param name="left">The first vector to modulate.</param>
    /// <param name="right">The second vector to modulate.</param>
    /// <param name="result">When the method completes, contains the modulated vector.</param>
    [Inline]
    public static void Modulate(Double2 left, Double2 right, out Double2 result)
    {
        result = Double2(left.X * right.X, left.Y * right.Y);
    }

    /// <summary>
    /// Modulates a vector with another by performing component-wise multiplication.
    /// </summary>
    /// <param name="left">The first vector to modulate.</param>
    /// <param name="right">The second vector to modulate.</param>
    /// <returns>The modulated vector.</returns>
    [Inline]
    public static Double2 Modulate(Double2 left, Double2 right)
    {
        return Double2(left.X * right.X, left.Y * right.Y);
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <param name="result">When the method completes, contains the scaled vector.</param>
    [Inline]
    public static void Divide(Double2 value, double scale, out Double2 result)
    {
        result = Double2(value.X / scale, value.Y / scale);
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <returns>The scaled vector.</returns>
    [Inline]
    public static Double2 Divide(Double2 value, double scale)
    {
        return Double2(value.X / scale, value.Y / scale);
    }

    /// <summary>
    /// Demodulates a vector with another by performing component-wise division.
    /// </summary>
    /// <param name="left">The first vector to demodulate.</param>
    /// <param name="right">The second vector to demodulate.</param>
    /// <param name="result">When the method completes, contains the demodulated vector.</param>
    [Inline]
    public static void Demodulate(Double2 left, Double2 right, out Double2 result)
    {
        result = Double2(left.X / right.X, left.Y / right.Y);
    }

    /// <summary>
    /// Demodulates a vector with another by performing component-wise division.
    /// </summary>
    /// <param name="left">The first vector to demodulate.</param>
    /// <param name="right">The second vector to demodulate.</param>
    /// <returns>The demodulated vector.</returns>
    [Inline]
    public static Double2 Demodulate(Double2 left, Double2 right)
    {
        return Double2(left.X / right.X, left.Y / right.Y);
    }

    /// <summary>
    /// Reverses the direction of a given vector.
    /// </summary>
    /// <param name="value">The vector to negate.</param>
    /// <param name="result">When the method completes, contains a vector facing in the opposite direction.</param>
    [Inline]
    public static void Negate(Double2 value, out Double2 result)
    {
        result = Double2(-value.X, -value.Y);
    }

    /// <summary>
    /// Reverses the direction of a given vector.
    /// </summary>
    /// <param name="value">The vector to negate.</param>
    /// <returns>A vector facing in the opposite direction.</returns>
    [Inline]
    public static Double2 Negate(Double2 value)
    {
        return Double2(-value.X, -value.Y);
    }

    /// <summary>
    /// Returns a <see cref="Double2"/> containing the 2D Cartesian coordinates of a point specified in Barycentric coordinates relative to a 2D triangle.
    /// </summary>
    /// <param name="value1">A <see cref="Double2"/> containing the 2D Cartesian coordinates of vertex 1 of the triangle.</param>
    /// <param name="value2">A <see cref="Double2"/> containing the 2D Cartesian coordinates of vertex 2 of the triangle.</param>
    /// <param name="value3">A <see cref="Double2"/> containing the 2D Cartesian coordinates of vertex 3 of the triangle.</param>
    /// <param name="amount1">Barycentric coordinate b2, which expresses the weighting factor toward vertex 2 (specified in <paramref name="value2"/>).</param>
    /// <param name="amount2">Barycentric coordinate b3, which expresses the weighting factor toward vertex 3 (specified in <paramref name="value3"/>).</param>
    /// <param name="result">When the method completes, contains the 2D Cartesian coordinates of the specified point.</param>
    public static void Barycentric(Double2 value1, Double2 value2, Double2 value3, double amount1, double amount2, out Double2 result)
    {
        result = Double2(value1.X + (amount1 * (value2.X - value1.X)) + (amount2 * (value3.X - value1.X)),
            value1.Y + (amount1 * (value2.Y - value1.Y)) + (amount2 * (value3.Y - value1.Y)));
    }

    /// <summary>
    /// Returns a <see cref="Double2"/> containing the 2D Cartesian coordinates of a point specified in Barycentric coordinates relative to a 2D triangle.
    /// </summary>
    /// <param name="value1">A <see cref="Double2"/> containing the 2D Cartesian coordinates of vertex 1 of the triangle.</param>
    /// <param name="value2">A <see cref="Double2"/> containing the 2D Cartesian coordinates of vertex 2 of the triangle.</param>
    /// <param name="value3">A <see cref="Double2"/> containing the 2D Cartesian coordinates of vertex 3 of the triangle.</param>
    /// <param name="amount1">Barycentric coordinate b2, which expresses the weighting factor toward vertex 2 (specified in <paramref name="value2"/>).</param>
    /// <param name="amount2">Barycentric coordinate b3, which expresses the weighting factor toward vertex 3 (specified in <paramref name="value3"/>).</param>
    /// <returns>A new <see cref="Double2"/> containing the 2D Cartesian coordinates of the specified point.</returns>
    public static Double2 Barycentric(Double2 value1, Double2 value2, Double2 value3, double amount1, double amount2)
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
    public static void Clamp(Double2 value, Double2 min, Double2 max, out Double2 result)
    {
        double x = value.X;
        x = (x > max.X) ? max.X : x;
        x = (x < min.X) ? min.X : x;

        double y = value.Y;
        y = (y > max.Y) ? max.Y : y;
        y = (y < min.Y) ? min.Y : y;

        result = Double2(x, y);
    }

    /// <summary>
    /// Restricts a value to be within a specified range.
    /// </summary>
    /// <param name="value">The value to clamp.</param>
    /// <param name="min">The minimum value.</param>
    /// <param name="max">The maximum value.</param>
    /// <returns>The clamped value.</returns>
    public static Double2 Clamp(Double2 value, Double2 min, Double2 max)
    {
        Clamp(value, min, max, var result);
        return result;
    }

    /// <summary>
    /// Calculates the distance between two vectors.
    /// </summary>
    /// <param name="value1">The first vector.</param>
    /// <param name="value2">The second vector.</param>
    /// <param name="result">When the method completes, contains the distance between the two vectors.</param>
    /// <remarks>
    /// <see cref="DistanceSquared(Double2, Double2, out double)"/> may be preferred when only the relative distance is needed
    /// and speed is of the essence.
    /// </remarks>
    public static void Distance(Double2 value1, Double2 value2, out double result)
    {
        double x = value1.X - value2.X;
        double y = value1.Y - value2.Y;

        result = (double)Math.Sqrt((x * x) + (y * y));
    }

    /// <summary>
    /// Calculates the distance between two vectors.
    /// </summary>
    /// <param name="value1">The first vector.</param>
    /// <param name="value2">The second vector.</param>
    /// <returns>The distance between the two vectors.</returns>
    /// <remarks>
    /// <see cref="DistanceSquared(Double2, Double2)"/> may be preferred when only the relative distance is needed
    /// and speed is of the essence.
    /// </remarks>
    public static double Distance(Double2 value1, Double2 value2)
    {
        double x = value1.X - value2.X;
        double y = value1.Y - value2.Y;

        return (double)Math.Sqrt((x * x) + (y * y));
    }

    /// <summary>
    /// Calculates the squared distance between two vectors.
    /// </summary>
    /// <param name="value1">The first vector.</param>
    /// <param name="value2">The second vector</param>
    /// <param name="result">When the method completes, contains the squared distance between the two vectors.</param>
    /// <remarks>Distance squared is the value before taking the square root.
    /// Distance squared can often be used in place of distance if relative comparisons are being made.
    /// For example, consider three points A, B, and C. To determine whether B or C is further from A,
    /// compare the distance between A and B to the distance between A and C. Calculating the two distances
    /// involves two square roots, which are computationally expensive. However, using distance squared
    /// provides the same information and avoids calculating two square roots.
    /// </remarks>
    public static void DistanceSquared(Double2 value1, Double2 value2, out double result)
    {
        double x = value1.X - value2.X;
        double y = value1.Y - value2.Y;

        result = (x * x) + (y * y);
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
    public static double DistanceSquared(Double2 value1, Double2 value2)
    {
        double x = value1.X - value2.X;
        double y = value1.Y - value2.Y;

        return (x * x) + (y * y);
    }

    /// <summary>
    /// Calculates the dot product of two vectors.
    /// </summary>
    /// <param name="left">First source vector.</param>
    /// <param name="right">Second source vector.</param>
    /// <param name="result">When the method completes, contains the dot product of the two vectors.</param>
    [Inline]
    public static void Dot(Double2 left, Double2 right, out double result)
    {
        result = (left.X * right.X) + (left.Y * right.Y);
    }

    /// <summary>
    /// Calculates the dot product of two vectors.
    /// </summary>
    /// <param name="left">First source vector.</param>
    /// <param name="right">Second source vector.</param>
    /// <returns>The dot product of the two vectors.</returns>
    [Inline]
    public static double Dot(Double2 left, Double2 right)
    {
        return (left.X * right.X) + (left.Y * right.Y);
    }

    /// <summary>
    /// Converts the vector into a unit vector.
    /// </summary>
    /// <param name="value">The vector to normalize.</param>
    /// <param name="result">When the method completes, contains the normalized vector.</param>
    [Inline]
    public static void Normalize(Double2 value, out Double2 result)
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
    public static Double2 Normalize(Double2 value)
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
    /// <c>start + (end - start) * amount</c>
    /// Passing <paramref name="amount"/> a value of 0 will cause <paramref name="start"/> to be returned; a value of 1 will cause <paramref name="end"/> to be returned.
    /// </remarks>
    public static void Lerp(Double2 start, Double2 end, double amount, out Double2 result)
    {
        result.X = start.X + ((end.X - start.X) * amount);
        result.Y = start.Y + ((end.Y - start.Y) * amount);
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
    public static Double2 Lerp(Double2 start, Double2 end, double amount)
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
    public static void SmoothStep(Double2 start, Double2 end, double amount, out Double2 result)
    {
		var amount;
        amount = (amount > 1.0) ? 1.0 : ((amount < 0.0) ? 0.0 : amount);
        amount = amount * amount * (3.0f - (2.0f * amount));

        result.X = start.X + ((end.X - start.X) * amount);
        result.Y = start.Y + ((end.Y - start.Y) * amount);
    }

    /// <summary>
    /// Performs a cubic interpolation between two vectors.
    /// </summary>
    /// <param name="start">Start vector.</param>
    /// <param name="end">End vector.</param>
    /// <param name="amount">Value between 0 and 1 indicating the weight of <paramref name="end"/>.</param>
    /// <returns>The cubic interpolation of the two vectors.</returns>
    public static Double2 SmoothStep(Double2 start, Double2 end, double amount)
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
    public static void Hermite(Double2 value1, Double2 tangent1, Double2 value2, Double2 tangent2, double amount, out Double2 result)
    {
        double squared = amount * amount;
        double cubed = amount * squared;
        double part1 = ((2.0f * cubed) - (3.0f * squared)) + 1.0;
        double part2 = (-2.0f * cubed) + (3.0f * squared);
        double part3 = (cubed - (2.0f * squared)) + amount;
        double part4 = cubed - squared;

        result.X = (value1.X * part1) + (value2.X * part2) + (tangent1.X * part3) + (tangent2.X * part4);
        result.Y = (value1.Y * part1) + (value2.Y * part2) + (tangent1.Y * part3) + (tangent2.Y * part4);
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
    public static Double2 Hermite(Double2 value1, Double2 tangent1, Double2 value2, Double2 tangent2, double amount)
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
    public static void CatmullRom(Double2 value1, Double2 value2, Double2 value3, Double2 value4, double amount, out Double2 result)
    {
        double squared = amount * amount;
        double cubed = amount * squared;

        result.X = 0.5f * ((2.0f * value2.X) + ((-value1.X + value3.X) * amount) +
        (((2.0f * value1.X) - (5.0f * value2.X) + (4.0f * value3.X) - value4.X) * squared) +
        ((-value1.X + (3.0f * value2.X) - (3.0f * value3.X) + value4.X) * cubed));

        result.Y = 0.5f * ((2.0f * value2.Y) + ((-value1.Y + value3.Y) * amount) +
            (((2.0f * value1.Y) - (5.0f * value2.Y) + (4.0f * value3.Y) - value4.Y) * squared) +
            ((-value1.Y + (3.0f * value2.Y) - (3.0f * value3.Y) + value4.Y) * cubed));
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
    public static Double2 CatmullRom(Double2 value1, Double2 value2, Double2 value3, Double2 value4, double amount)
    {
        CatmullRom(value1, value2, value3, value4, amount, var result);
        return result;
    }

    /// <summary>
    /// Returns a vector containing the smallest components of the specified vectors.
    /// </summary>
    /// <param name="left">The first source vector.</param>
    /// <param name="right">The second source vector.</param>
    /// <param name="result">When the method completes, contains an new vector composed of the largest components of the source vectors.</param>
    [Inline]
    public static void Max(Double2 left, Double2 right, out Double2 result)
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
    [Inline]
    public static Double2 Max(Double2 left, Double2 right)
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
    public static void Min(Double2 left, Double2 right, out Double2 result)
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
    [Inline]
    public static Double2 Min(Double2 left, Double2 right)
    {
        Min(left, right, var result);
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
    public static void Reflect(Double2 vector, Double2 normal, out Double2 result)
    {
        double dot = (vector.X * normal.X) + (vector.Y * normal.Y);

        result.X = vector.X - (2.0f * dot * normal.X);
        result.Y = vector.Y - (2.0f * dot * normal.Y);
    }

    /// <summary>
    /// Returns the reflection of a vector off a surface that has the specified normal.
    /// </summary>
    /// <param name="vector">The source vector.</param>
    /// <param name="normal">Normal of the surface.</param>
    /// <returns>The reflected vector.</returns>
    /// <remarks>Reflect only gives the direction of a reflection off a surface, it does not determine
    /// whether the original vector was close enough to the surface to hit it.</remarks>
    public static Double2 Reflect(Double2 vector, Double2 normal)
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
    public static void Orthogonalize(Double2[] destination, params Double2[] source)
    {
        //Uses the modified Gram-Schmidt process.
        //q1 = m1
        //q2 = m2 - ((q1 ⋅ m2) / (q1 ⋅ q1)) * q1
        //q3 = m3 - ((q1 ⋅ m3) / (q1 ⋅ q1)) * q1 - ((q2 ⋅ m3) / (q2 ⋅ q2)) * q2
        //q4 = m4 - ((q1 ⋅ m4) / (q1 ⋅ q1)) * q1 - ((q2 ⋅ m4) / (q2 ⋅ q2)) * q2 - ((q3 ⋅ m4) / (q3 ⋅ q3)) * q3
        //q5 = ...

        if(source== null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(source)}");
        if(destination== null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(destination)}");
        if (destination.Count< source.Count)
            Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(destination)}: The destination array must be of same length or larger length than the source array.");

        for (int32 i = 0; i < source.Count; ++i)
        {
            Double2 newvector = source[i];

            for (int32 r = 0; r < i; ++r)
            {
                newvector -= Dot(destination[r], newvector) / Dot(destination[r], destination[r]) * destination[r];
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
    public static void Orthonormalize(Double2[] destination, params Double2[] source)
    {
        //Uses the modified Gram-Schmidt process.
        //Because we are making unit vectors, we can optimize the math for orthogonalization
        //and simplify the projection operation to remove the division.
        //q1 = m1 / |m1|
        //q2 = (m2 - (q1 ⋅ m2) * q1) / |m2 - (q1 ⋅ m2) * q1|
        //q3 = (m3 - (q1 ⋅ m3) * q1 - (q2 ⋅ m3) * q2) / |m3 - (q1 ⋅ m3) * q1 - (q2 ⋅ m3) * q2|
        //q4 = (m4 - (q1 ⋅ m4) * q1 - (q2 ⋅ m4) * q2 - (q3 ⋅ m4) * q3) / |m4 - (q1 ⋅ m4) * q1 - (q2 ⋅ m4) * q2 - (q3 ⋅ m4) * q3|
        //q5 = ...

        if(source== null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(source)}");
        if(destination== null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(destination)}");
        if (destination.Count< source.Count)
            Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(destination)}: The destination array must be of same length or larger length than the source array.");

        for (int32 i = 0; i < source.Count; ++i)
        {
            Double2 newvector = source[i];

            for (int32 r = 0; r < i; ++r)
            {
                newvector -= Dot(destination[r], newvector) * destination[r];
            }

            newvector.Normalize();
            destination[i] = newvector;
        }
    }

    /// <summary>
    /// Transforms a 2D vector by the given <see cref="Quaternion"/> rotation.
    /// </summary>
    /// <param name="vector">The vector to rotate.</param>
    /// <param name="rotation">The <see cref="Quaternion"/> rotation to apply.</param>
    /// <param name="result">When the method completes, contains the transformed <see cref="Double4"/>.</param>
    public static void Transform(Double2 vector, Quaternion rotation, out Double2 result)
    {
        double x = rotation.X + rotation.X;
        double y = rotation.Y + rotation.Y;
        double z = rotation.Z + rotation.Z;
        double wz = rotation.W * z;
        double xx = rotation.X * x;
        double xy = rotation.X * y;
        double yy = rotation.Y * y;
        double zz = rotation.Z * z;

        result = Double2((vector.X * (1.0 - yy - zz)) + (vector.Y * (xy - wz)), (vector.X * (xy + wz)) + (vector.Y * (1.0 - xx - zz)));
    }

    /// <summary>
    /// Transforms a 2D vector by the given <see cref="Quaternion"/> rotation.
    /// </summary>
    /// <param name="vector">The vector to rotate.</param>
    /// <param name="rotation">The <see cref="Quaternion"/> rotation to apply.</param>
    /// <returns>The transformed <see cref="Double4"/>.</returns>
    public static Double2 Transform(Double2 vector, Quaternion rotation)
    {
        Transform(vector, rotation, var result);
        return result;
    }

    /// <summary>
    /// Transforms an array of vectors by the given <see cref="Quaternion"/> rotation.
    /// </summary>
    /// <param name="source">The array of vectors to transform.</param>
    /// <param name="rotation">The <see cref="Quaternion"/> rotation to apply.</param>
    /// <param name="destination">The array for which the transformed vectors are stored.
    /// This array may be the same array as <paramref name="source"/>.</param>
    /// <exception cref="ArgumentNullException">Thrown when <paramref name="source"/> or <paramref name="destination"/> is <c>null</c>.</exception>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when <paramref name="destination"/> is shorter in length than <paramref name="source"/>.</exception>
    public static void Transform(Double2[] source, Quaternion rotation, Double2[] destination)
    {
        if(source== null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(source)}");
        if(destination== null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(destination)}");
        if (destination.Count< source.Count)
            Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(destination)}: The destination array must be of same length or larger length than the source array.");

        double x = rotation.X + rotation.X;
        double y = rotation.Y + rotation.Y;
        double z = rotation.Z + rotation.Z;
        double wz = rotation.W * z;
        double xx = rotation.X * x;
        double xy = rotation.X * y;
        double yy = rotation.Y * y;
        double zz = rotation.Z * z;

        double num1 = 1.0 - yy - zz;
        double num2 = xy - wz;
        double num3 = xy + wz;
        double num4 = 1.0 - xx - zz;

        for (int32 i = 0; i < source.Count; ++i)
        {
            destination[i] = Double2(
                (source[i].X * num1) + (source[i].Y * num2),
                (source[i].X * num3) + (source[i].Y * num4));
        }
    }

    /// <summary>
    /// Transforms a 2D vector by the given <see cref="Matrix"/>.
    /// </summary>
    /// <param name="vector">The source vector.</param>
    /// <param name="transform">The transformation <see cref="Matrix"/>.</param>
    /// <param name="result">When the method completes, contains the transformed <see cref="Double4"/>.</param>
    public static void Transform(Double2 vector, Matrix transform, out Double4 result)
    {
        result = Double4(
            (vector.X * transform.M11) + (vector.Y * transform.M21) + transform.M41,
            (vector.X * transform.M12) + (vector.Y * transform.M22) + transform.M42,
            (vector.X * transform.M13) + (vector.Y * transform.M23) + transform.M43,
            (vector.X * transform.M14) + (vector.Y * transform.M24) + transform.M44);
    }

    /// <summary>
    /// Transforms a 2D vector by the given <see cref="Matrix"/>.
    /// </summary>
    /// <param name="vector">The source vector.</param>
    /// <param name="transform">The transformation <see cref="Matrix"/>.</param>
    /// <returns>The transformed <see cref="Double4"/>.</returns>
    public static Double4 Transform(Double2 vector, Matrix transform)
    {
        Transform(vector, transform, var result);
        return result;
    }

    /// <summary>
    /// Transforms an array of 2D vectors by the given <see cref="Matrix"/>.
    /// </summary>
    /// <param name="source">The array of vectors to transform.</param>
    /// <param name="transform">The transformation <see cref="Matrix"/>.</param>
    /// <param name="destination">The array for which the transformed vectors are stored.</param>
    /// <exception cref="ArgumentNullException">Thrown when <paramref name="source"/> or <paramref name="destination"/> is <c>null</c>.</exception>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when <paramref name="destination"/> is shorter in length than <paramref name="source"/>.</exception>
    public static void Transform(Double2[] source, Matrix transform, Double4[] destination)
    {
        if(source== null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(source)}");
        if(destination== null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(destination)}");
        if (destination.Count< source.Count)
            Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(destination)}: The destination array must be of same length or larger length than the source array.");

        for (int32 i = 0; i < source.Count; ++i)
        {
            Transform(source[i], transform, out destination[i]);
        }
    }

    /// <summary>
    /// Performs a coordinate transformation using the given <see cref="Matrix"/>.
    /// </summary>
    /// <param name="coordinate">The coordinate vector to transform.</param>
    /// <param name="transform">The transformation <see cref="Matrix"/>.</param>
    /// <param name="result">When the method completes, contains the transformed coordinates.</param>
    /// <remarks>
    /// A coordinate transform performs the transformation with the assumption that the w component
    /// is one. The four dimensional vector obtained from the transformation operation has each
    /// component in the vector divided by the w component. This forces the wcomponent to be one and
    /// therefore makes the vector homogeneous. The homogeneous vector is often prefered when working
    /// with coordinates as the w component can safely be ignored.
    /// </remarks>
    public static void TransformCoordinate(Double2 coordinate, Matrix transform, out Double2 result)
    {
        Double4 vector = Double4
        {
            X = (coordinate.X * transform.M11) + (coordinate.Y * transform.M21) + transform.M41,
            Y = (coordinate.X * transform.M12) + (coordinate.Y * transform.M22) + transform.M42,
            Z = (coordinate.X * transform.M13) + (coordinate.Y * transform.M23) + transform.M43,
            W = 1f / ((coordinate.X * transform.M14) + (coordinate.Y * transform.M24) + transform.M44)
        };

        result = Double2(vector.X * vector.W, vector.Y * vector.W);
    }

    /// <summary>
    /// Performs a coordinate transformation using the given <see cref="Matrix"/>.
    /// </summary>
    /// <param name="coordinate">The coordinate vector to transform.</param>
    /// <param name="transform">The transformation <see cref="Matrix"/>.</param>
    /// <returns>The transformed coordinates.</returns>
    /// <remarks>
    /// A coordinate transform performs the transformation with the assumption that the w component
    /// is one. The four dimensional vector obtained from the transformation operation has each
    /// component in the vector divided by the w component. This forces the wcomponent to be one and
    /// therefore makes the vector homogeneous. The homogeneous vector is often prefered when working
    /// with coordinates as the w component can safely be ignored.
    /// </remarks>
    public static Double2 TransformCoordinate(Double2 coordinate, Matrix transform)
    {
        TransformCoordinate(coordinate, transform, var result);
        return result;
    }

    /// <summary>
    /// Performs a coordinate transformation on an array of vectors using the given <see cref="Matrix"/>.
    /// </summary>
    /// <param name="source">The array of coordinate vectors to trasnform.</param>
    /// <param name="transform">The transformation <see cref="Matrix"/>.</param>
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
    public static void TransformCoordinate(Double2[] source, Matrix transform, Double2[] destination)
    {
        if(source== null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(source)}");
        if(destination== null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(destination)}");
        if (destination.Count< source.Count)
            Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(destination)}: The destination array must be of same length or larger length than the source array.");

        for (int32 i = 0; i < source.Count; ++i)
        {
            TransformCoordinate(source[i], transform, out destination[i]);
        }
    }

    /// <summary>
    /// Performs a normal transformation using the given <see cref="Matrix"/>.
    /// </summary>
    /// <param name="normal">The normal vector to transform.</param>
    /// <param name="transform">The transformation <see cref="Matrix"/>.</param>
    /// <param name="result">When the method completes, contains the transformed normal.</param>
    /// <remarks>
    /// A normal transform performs the transformation with the assumption that the w component
    /// is zero. This causes the fourth row and fourth collumn of the matrix to be unused. The
    /// end result is a vector that is not translated, but all other transformation properties
    /// apply. This is often prefered for normal vectors as normals purely represent direction
    /// rather than location because normal vectors should not be translated.
    /// </remarks>
    public static void TransformNormal(Double2 normal, Matrix transform, out Double2 result)
    {
        result = Double2(
            (normal.X * transform.M11) + (normal.Y * transform.M21),
            (normal.X * transform.M12) + (normal.Y * transform.M22));
    }

    /// <summary>
    /// Performs a normal transformation using the given <see cref="Matrix"/>.
    /// </summary>
    /// <param name="normal">The normal vector to transform.</param>
    /// <param name="transform">The transformation <see cref="Matrix"/>.</param>
    /// <returns>The transformed normal.</returns>
    /// <remarks>
    /// A normal transform performs the transformation with the assumption that the w component
    /// is zero. This causes the fourth row and fourth collumn of the matrix to be unused. The
    /// end result is a vector that is not translated, but all other transformation properties
    /// apply. This is often prefered for normal vectors as normals purely represent direction
    /// rather than location because normal vectors should not be translated.
    /// </remarks>
    public static Double2 TransformNormal(Double2 normal, Matrix transform)
    {
        TransformNormal(normal, transform, var result);
        return result;
    }

    /// <summary>
    /// Performs a normal transformation on an array of vectors using the given <see cref="Matrix"/>.
    /// </summary>
    /// <param name="source">The array of normal vectors to transform.</param>
    /// <param name="transform">The transformation <see cref="Matrix"/>.</param>
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
    public static void TransformNormal(Double2[] source, Matrix transform, Double2[] destination)
    {
        if(source== null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(source)}");
        if(destination== null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(destination)}");
        if (destination.Count< source.Count)
            Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(destination)}: The destination array must be of same length or larger length than the source array.");

        for (int32 i = 0; i < source.Count; ++i)
        {
            TransformNormal(source[i], transform, out destination[i]);
        }
    }

    /// <summary>
    /// Adds two vectors.
    /// </summary>
    /// <param name="left">The first vector to add.</param>
    /// <param name="right">The second vector to add.</param>
    /// <returns>The sum of the two vectors.</returns>
    [Inline]
    public static Double2 operator +(Double2 left, Double2 right)
    {
        return Double2(left.X + right.X, left.Y + right.Y);
    }

    /// <summary>
    /// Assert a vector (return it unchanged).
    /// </summary>
    /// <param name="value">The vector to assert (unchange).</param>
    /// <returns>The asserted (unchanged) vector.</returns>
    [Inline]
    public static Double2 operator +(Double2 value)
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
    public static Double2 operator -(Double2 left, Double2 right)
    {
        return Double2(left.X - right.X, left.Y - right.Y);
    }

    /// <summary>
    /// Reverses the direction of a given vector.
    /// </summary>
    /// <param name="value">The vector to negate.</param>
    /// <returns>A vector facing in the opposite direction.</returns>
    [Inline]
    public static Double2 operator -(Double2 value)
    {
        return Double2(-value.X, -value.Y);
    }

    /// <summary>
    /// Modulates a vector with another by performing component-wise multiplication.
    /// </summary>
    /// <param name="left">The first vector to multiply.</param>
    /// <param name="right">The second vector to multiply.</param>
    /// <returns>The multiplication of the two vectors.</returns>
    [Inline]
    public static Double2 operator *(Double2 left, Double2 right)
    {
        return Double2(left.X * right.X, left.Y * right.Y);
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <param name="value">The vector to scale.</param>
    /// <returns>The scaled vector.</returns>
    [Inline]
    public static Double2 operator *(double scale, Double2 value)
    {
        return Double2(value.X * scale, value.Y * scale);
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <returns>The scaled vector.</returns>
    [Inline]
    public static Double2 operator *(Double2 value, double scale)
    {
        return Double2(value.X * scale, value.Y * scale);
    }

    /// <summary>
    /// Scales a vector by the given value.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="scale">The amount by which to scale the vector.</param>
    /// <returns>The scaled vector.</returns>
    [Inline]
    public static Double2 operator /(Double2 value, double scale)
    {
        return Double2(value.X / scale, value.Y / scale);
    }

    /// <summary>
    /// Divides a numerator by a vector.
    /// </summary>
    /// <param name="numerator">The numerator.</param>
    /// <param name="value">The value.</param>
    /// <returns>The scaled vector.</returns>
    [Inline]
    public static Double2 operator /(double numerator, Double2 value)
    {
        return Double2(numerator / value.X, numerator / value.Y);
    }

    /// <summary>
    /// Divides a vector by the given vector, component-wise.
    /// </summary>
    /// <param name="value">The vector to scale.</param>
    /// <param name="by">The by.</param>
    /// <returns>The scaled vector.</returns>
    [Inline]
    public static Double2 operator /(Double2 value, Double2 by)
    {
        return Double2(value.X / by.X, value.Y / by.Y);
    }

    /// <summary>
    /// Tests for equality between two objects.
    /// </summary>
    /// <param name="left">The first value to compare.</param>
    /// <param name="right">The second value to compare.</param>
    /// <returns><c>true</c> if <paramref name="left"/> has the same value as <paramref name="right"/>; otherwise, <c>false</c>.</returns>
    public static bool operator ==(Double2 left, Double2 right)
    {
        return left.Equals(right);
    }

    /// <summary>
    /// Tests for inequality between two objects.
    /// </summary>
    /// <param name="left">The first value to compare.</param>
    /// <param name="right">The second value to compare.</param>
    /// <returns><c>true</c> if <paramref name="left"/> has a different value than <paramref name="right"/>; otherwise, <c>false</c>.</returns>
    public static bool operator !=(Double2 left, Double2 right)
    {
        return !left.Equals(right);
    }

    /// <summary>
    /// Performs an explicit conversion from <see cref="Sedulous.Mathematics.Double2"/> to <see cref="Sedulous.Mathematics.Vector2"/>.
    /// </summary>
    /// <param name="value">The value.</param>
    /// <returns>The result of the conversion.</returns>
    public static explicit operator Vector2(Double2 value)
    {
        return Vector2((float)value.X, (float)value.Y);
    }

    /// <summary>
    /// Performs an implicit conversion from <see cref="Sedulous.Mathematics.Vector2"/> to <see cref="Sedulous.Mathematics.Double2"/>.
    /// </summary>
    /// <param name="value">The value.</param>
    /// <returns>The result of the conversion.</returns>
    public static implicit operator Double2(Vector2 value)
    {
        return Double2(value);
    }

    /// <summary>
    /// Performs an explicit conversion from <see cref="Double2"/> to <see cref="Half2"/>.
    /// </summary>
    /// <param name="value">The value.</param>
    /// <returns>The result of the conversion.</returns>
    public static explicit operator Half2(Double2 value)
    {
        return Half2((Half)value.X, (Half)value.Y);
    }

    /// <summary>
    /// Performs an explicit conversion from <see cref="Half2"/> to <see cref="Double2"/>.
    /// </summary>
    /// <param name="value">The value.</param>
    /// <returns>The result of the conversion.</returns>
    public static explicit operator Double2(Half2 value)
    {
        return Double2(value.X, value.Y);
    }

    /// <summary>
    /// Performs an explicit conversion from <see cref="Sedulous.Mathematics.Double2"/> to <see cref="Sedulous.Mathematics.Double3"/>.
    /// </summary>
    /// <param name="value">The value.</param>
    /// <returns>The result of the conversion.</returns>
    public static explicit operator Double3(Double2 value)
    {
        return Double3(value, 0.0);
    }

    /// <summary>
    /// Performs an explicit conversion from <see cref="Sedulous.Mathematics.Double2"/> to <see cref="Sedulous.Mathematics.Double4"/>.
    /// </summary>
    /// <param name="value">The value.</param>
    /// <returns>The result of the conversion.</returns>
    public static explicit operator Double4(Double2 value)
    {
        return Double4(value, 0.0, 0.0);
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
    /// Determines whether the specified <see cref="Sedulous.Mathematics.Double2"/> is equal to this instance.
    /// </summary>
    /// <param name="other">The <see cref="Sedulous.Mathematics.Double2"/> to compare with this instance.</param>
    /// <returns>
    /// 	<c>true</c> if the specified <see cref="Sedulous.Mathematics.Double2"/> is equal to this instance; otherwise, <c>false</c>.
    /// </returns>
    public bool Equals(Double2 other)
    {
        return (double)Math.Abs(other.X - X) < MathUtil.ZeroTolerance &&
            (double)Math.Abs(other.Y - Y) < MathUtil.ZeroTolerance;
    }

    /// <summary>
    /// Deconstructs the vector's components into named variables.
    /// </summary>
    /// <param name="x">The X component</param>
    /// <param name="y">The Y component</param>
    public void Deconstruct(out double x, out double y)
    {
        x = X;
        y = Y;
    }
}
