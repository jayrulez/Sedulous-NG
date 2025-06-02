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
/// Represents a unit independant angle using a single-precision floating-point
/// internal representation.
/// </summary>
[CRepr]public struct AngleSingle : IEquatable<AngleSingle>
{
    /// <summary>
    /// A value that specifies the size of a single degree.
    /// </summary>
    public const float Degree = 0.002777777777777778f;

    /// <summary>
    /// A value that specifies the size of a single minute.
    /// </summary>
    public const float Minute = 0.000046296296296296f;

    /// <summary>
    /// A value that specifies the size of a single second.
    /// </summary>
    public const float Second = 0.000000771604938272f;

    /// <summary>
    /// A value that specifies the size of a single radian.
    /// </summary>
    public const float Radian = 0.159154943091895336f;

    /// <summary>
    /// A value that specifies the size of a single milliradian.
    /// </summary>
    public const float Milliradian = 0.0001591549431f;

    /// <summary>
    /// A value that specifies the size of a single gradian.
    /// </summary>
    public const float Gradian = 0.0025f;

    /// <summary>
    /// Initializes a new instance of the <see cref="AngleSingle"/> struct with the
    /// given unit dependant angle and unit type.
    /// </summary>
    /// <param name="angle">A unit dependant measure of the angle.</param>
    /// <param name="type">The type of unit the angle argument is.</param>
    public this(float angle, AngleType type)
    {
		switch(type)
		{
			case AngleType.Revolution: Radians = MathUtil.RevolutionsToRadians(angle); break;
			case AngleType.Degree: Radians = MathUtil.DegreesToRadians(angle); break;
			case AngleType.Radian: Radians = angle; break;
			case AngleType.Gradian: Radians = MathUtil.GradiansToRadians(angle); break;
			default: Radians = 0.0f; break;
		}
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="AngleSingle"/> struct using the
    /// arc length formula (θ = s/r).
    /// </summary>
    /// <param name="arcLength">The measure of the arc.</param>
    /// <param name="radius">The radius of the circle.</param>
    public this(float arcLength, float radius)
    {
        Radians = arcLength / radius;
    }

    /// <summary>
    /// Wraps this Sedulous.Mathematics.AngleSingle to be in the range [π, -π].
    /// </summary>
    public void Wrap() mut
    {
        float newangle = Math.IEEERemainder(Radians, MathUtil.TwoPi);

        if (newangle <= -MathUtil.Pi)
            newangle += MathUtil.TwoPi;
        else if (newangle > MathUtil.Pi)
            newangle -= MathUtil.TwoPi;

        Radians = newangle;
    }

    /// <summary>
    /// Wraps this Sedulous.Mathematics.AngleSingle to be in the range [0, 2π).
    /// </summary>
    public void WrapPositive() mut
    {
        float newangle = Radians % MathUtil.TwoPi;

        if (newangle < 0.0)
            newangle += MathUtil.TwoPi;

        Radians = newangle;
    }

    /// <summary>
    /// Gets or sets the total number of revolutions this Sedulous.Mathematics.AngleSingle represents.
    /// </summary>
    public float Revolutions
    {
        get { return MathUtil.RadiansToRevolutions(Radians); }
        set mut { Radians = MathUtil.RevolutionsToRadians(value); }
    }

    /// <summary>
    /// Gets or sets the total number of degrees this Sedulous.Mathematics.AngleSingle represents.
    /// </summary>
    public float Degrees
    {
        get { return MathUtil.RadiansToDegrees(Radians); }
        set mut { Radians = MathUtil.DegreesToRadians(value); }
    }

    /// <summary>
    /// Gets or sets the minutes component of the degrees this Sedulous.Mathematics.AngleSingle represents.
    /// When setting the minutes, if the value is in the range (-60, 60) the whole degrees are
    /// not changed; otherwise, the whole degrees may be changed. Fractional values may set
    /// the seconds component.
    /// </summary>
    public float Minutes
    {
        get
        {
            float degrees = MathUtil.RadiansToDegrees(Radians);

            if (degrees < 0)
            {
                float degreesfloor = Math.Ceiling(degrees);
                return (degrees - degreesfloor) * 60.0f;
            }
            else
            {
                float degreesfloor = Math.Floor(degrees);
                return (degrees - degreesfloor) * 60.0f;
            }
        }
        set mut
        {
            float degrees = MathUtil.RadiansToDegrees(Radians);
            float degreesfloor = Math.Floor(degrees);

            degreesfloor += value / 60.0f;
            Radians = MathUtil.DegreesToRadians(degreesfloor);
        }
    }

    /// <summary>
    /// Gets or sets the seconds of the degrees this Sedulous.Mathematics.AngleSingle represents.
    /// When setting te seconds, if the value is in the range (-60, 60) the whole minutes
    /// or whole degrees are not changed; otherwise, the whole minutes or whole degrees
    /// may be changed.
    /// </summary>
    public float Seconds
    {
        get
        {
            float degrees = MathUtil.RadiansToDegrees(Radians);

            if (degrees < 0)
            {
                float degreesfloor = Math.Ceiling(degrees);

                float minutes = (degrees - degreesfloor) * 60.0f;
                float minutesfloor = Math.Ceiling(minutes);

                return (minutes - minutesfloor) * 60.0f;
            }
            else
            {
                float degreesfloor = Math.Floor(degrees);

                float minutes = (degrees - degreesfloor) * 60.0f;
                float minutesfloor = Math.Floor(minutes);

                return (minutes - minutesfloor) * 60.0f;
            }
        }
        set mut
        {
            float degrees = MathUtil.RadiansToDegrees(Radians);
            float degreesfloor = Math.Floor(degrees);

            float minutes = (degrees - degreesfloor) * 60.0f;
            float minutesfloor = Math.Floor(minutes);

            minutesfloor += value / 60.0f;
            degreesfloor += minutesfloor / 60.0f;
            Radians = MathUtil.DegreesToRadians(degreesfloor);
        }
    }

    /// <summary>
    /// Gets or sets the total number of radians this Sedulous.Mathematics.AngleSingle represents.
    /// </summary>
    public float Radians { get; set mut; }

    /// <summary>
    /// Gets or sets the total number of milliradians this Sedulous.Mathematics.AngleSingle represents.
    /// One milliradian is equal to 1/(2000π).
    /// </summary>
    public float Milliradians
    {
        get { return Radians / (Milliradian * MathUtil.TwoPi); }
        set mut { Radians = value * (Milliradian * MathUtil.TwoPi); }
    }

    /// <summary>
    /// Gets or sets the total number of gradians this Sedulous.Mathematics.AngleSingle represents.
    /// </summary>
    public float Gradians
    {
        get { return MathUtil.RadiansToGradians(Radians); }
        set mut { Radians = MathUtil.GradiansToRadians(value); }
    }

    /// <summary>
    /// Gets a System.Boolean that determines whether this Sedulous.Mathematics.Angle
    /// is a right angle (i.e. 90° or π/2).
    /// </summary>
    public readonly bool IsRight
    {
        get { return Radians == MathUtil.PiOverTwo; }
    }

    /// <summary>
    /// Gets a System.Boolean that determines whether this Sedulous.Mathematics.Angle
    /// is a straight angle (i.e. 180° or π).
    /// </summary>
    public readonly bool IsStraight
    {
        get { return Radians == MathUtil.Pi; }
    }

    /// <summary>
    /// Gets a System.Boolean that determines whether this Sedulous.Mathematics.Angle
    /// is a full rotation angle (i.e. 360° or 2π).
    /// </summary>
    public readonly bool IsFullRotation
    {
        get { return Radians == MathUtil.TwoPi; }
    }

    /// <summary>
    /// Gets a System.Boolean that determines whether this Sedulous.Mathematics.Angle
    /// is an oblique angle (i.e. is not 90° or a multiple of 90°).
    /// </summary>
    public readonly bool IsOblique
    {
        get { return WrapPositive(this).Radians != MathUtil.PiOverTwo; }
    }

    /// <summary>
    /// Gets a System.Boolean that determines whether this Sedulous.Mathematics.Angle
    /// is an acute angle (i.e. less than 90° but greater than 0°).
    /// </summary>
    public readonly bool IsAcute
    {
        get { return Radians > 0.0f && Radians < MathUtil.PiOverTwo; }
    }

    /// <summary>
    /// Gets a System.Boolean that determines whether this Sedulous.Mathematics.Angle
    /// is an obtuse angle (i.e. greater than 90° but less than 180°).
    /// </summary>
    public readonly bool IsObtuse
    {
        get { return Radians > MathUtil.PiOverTwo && Radians < MathUtil.Pi; }
    }

    /// <summary>
    /// Gets a System.Boolean that determines whether this Sedulous.Mathematics.Angle
    /// is a reflex angle (i.e. greater than 180° but less than 360°).
    /// </summary>
    public readonly bool IsReflex
    {
        get { return Radians > MathUtil.Pi && Radians < MathUtil.TwoPi; }
    }

    /// <summary>
    /// Gets a Sedulous.Mathematics.AngleSingle instance that complements this angle (i.e. the two angles add to 90°).
    /// </summary>
    public readonly AngleSingle Complement
    {
        get { return AngleSingle(MathUtil.PiOverTwo - Radians, AngleType.Radian); }
    }

    /// <summary>
    /// Gets a Sedulous.Mathematics.AngleSingle instance that supplements this angle (i.e. the two angles add to 180°).
    /// </summary>
    public readonly AngleSingle Supplement
    {
        get { return AngleSingle(MathUtil.Pi - Radians, AngleType.Radian); }
    }

    /// <summary>
    /// Wraps the Sedulous.Mathematics.AngleSingle given in the value argument to be in the range [π, -π].
    /// </summary>
    /// <param name="value">A Sedulous.Mathematics.AngleSingle to wrap.</param>
    /// <returns>The Sedulous.Mathematics.AngleSingle that is wrapped.</returns>
    public static AngleSingle Wrap(AngleSingle value)
    {
		var value;
        value.Wrap();
        return value;
    }

    /// <summary>
    /// Wraps the Sedulous.Mathematics.AngleSingle given in the value argument to be in the range [0, 2π).
    /// </summary>
    /// <param name="value">A Sedulous.Mathematics.AngleSingle to wrap.</param>
    /// <returns>The Sedulous.Mathematics.AngleSingle that is wrapped.</returns>
    public static AngleSingle WrapPositive(AngleSingle value)
    {
		var value;
        value.WrapPositive();
        return value;
    }

    /// <summary>
    /// Compares two Sedulous.Mathematics.AngleSingle instances and returns the smaller angle.
    /// </summary>
    /// <param name="left">The first Sedulous.Mathematics.AngleSingle instance to compare.</param>
    /// <param name="right">The second Sedulous.Mathematics.AngleSingle instance to compare.</param>
    /// <returns>The smaller of the two given Sedulous.Mathematics.AngleSingle instances.</returns>
    public static AngleSingle Min(AngleSingle left, AngleSingle right)
    {
        if (left.Radians < right.Radians)
            return left;

        return right;
    }

    /// <summary>
    /// Compares two Sedulous.Mathematics.AngleSingle instances and returns the greater angle.
    /// </summary>
    /// <param name="left">The first Sedulous.Mathematics.AngleSingle instance to compare.</param>
    /// <param name="right">The second Sedulous.Mathematics.AngleSingle instance to compare.</param>
    /// <returns>The greater of the two given Sedulous.Mathematics.AngleSingle instances.</returns>
    public static AngleSingle Max(AngleSingle left, AngleSingle right)
    {
        if (left.Radians > right.Radians)
            return left;

        return right;
    }

    /// <summary>
    /// Adds two Sedulous.Mathematics.AngleSingle objects and returns the result.
    /// </summary>
    /// <param name="left">The first object to add.</param>
    /// <param name="right">The second object to add.</param>
    /// <returns>The value of the two objects added together.</returns>
    public static AngleSingle Add(AngleSingle left, AngleSingle right)
    {
        return AngleSingle(left.Radians + right.Radians, AngleType.Radian);
    }

    /// <summary>
    /// Subtracts two Sedulous.Mathematics.AngleSingle objects and returns the result.
    /// </summary>
    /// <param name="left">The first object to subtract.</param>
    /// <param name="right">The second object to subtract.</param>
    /// <returns>The value of the two objects subtracted.</returns>
    public static AngleSingle Subtract(AngleSingle left, AngleSingle right)
    {
        return AngleSingle(left.Radians - right.Radians, AngleType.Radian);
    }

    /// <summary>
    /// Multiplies two Sedulous.Mathematics.AngleSingle objects and returns the result.
    /// </summary>
    /// <param name="left">The first object to multiply.</param>
    /// <param name="right">The second object to multiply.</param>
    /// <returns>The value of the two objects multiplied together.</returns>
    public static AngleSingle Multiply(AngleSingle left, AngleSingle right)
    {
        return AngleSingle(left.Radians * right.Radians, AngleType.Radian);
    }

    /// <summary>
    /// Divides two Sedulous.Mathematics.AngleSingle objects and returns the result.
    /// </summary>
    /// <param name="left">The numerator object.</param>
    /// <param name="right">The denominator object.</param>
    /// <returns>The value of the two objects divided.</returns>
    public static AngleSingle Divide(AngleSingle left, AngleSingle right)
    {
        return AngleSingle(left.Radians / right.Radians, AngleType.Radian);
    }

    /// <summary>
    /// Gets a new Sedulous.Mathematics.AngleSingle instance that represents the zero angle (i.e. 0°).
    /// </summary>
    public static AngleSingle ZeroAngle
    {
        get { return AngleSingle(0.0f, AngleType.Radian); }
    }

    /// <summary>
    /// Gets a new Sedulous.Mathematics.AngleSingle instance that represents the right angle (i.e. 90° or π/2).
    /// </summary>
    public static AngleSingle RightAngle
    {
        get { return AngleSingle(MathUtil.PiOverTwo, AngleType.Radian); }
    }

    /// <summary>
    /// Gets a new Sedulous.Mathematics.AngleSingle instance that represents the straight angle (i.e. 180° or π).
    /// </summary>
    public static AngleSingle StraightAngle
    {
        get { return AngleSingle(MathUtil.Pi, AngleType.Radian); }
    }

    /// <summary>
    /// Gets a new Sedulous.Mathematics.AngleSingle instance that represents the full rotation angle (i.e. 360° or 2π).
    /// </summary>
    public static AngleSingle FullRotationAngle
    {
        get { return AngleSingle(MathUtil.TwoPi, AngleType.Radian); }
    }

    /// <summary>
    /// Returns a System.Boolean that indicates whether the values of two Sedulous.Mathematics.Angle
    /// objects are equal.
    /// </summary>
    /// <param name="left">The first object to compare.</param>
    /// <param name="right">The second object to compare.</param>
    /// <returns>True if the left and right parameters have the same value; otherwise, false.</returns>
    public static bool operator ==(AngleSingle left, AngleSingle right)
    {
        return left.Radians == right.Radians;
    }

    /// <summary>
    /// Returns a System.Boolean that indicates whether the values of two Sedulous.Mathematics.Angle
    /// objects are not equal.
    /// </summary>
    /// <param name="left">The first object to compare.</param>
    /// <param name="right">The second object to compare.</param>
    /// <returns>True if the left and right parameters do not have the same value; otherwise, false.</returns>
    public static bool operator !=(AngleSingle left, AngleSingle right)
    {
        return left.Radians != right.Radians;
    }

    /// <summary>
    /// Returns a System.Boolean that indicates whether a Sedulous.Mathematics.Angle
    /// object is less than another Sedulous.Mathematics.AngleSingle object.
    /// </summary>
    /// <param name="left">The first object to compare.</param>
    /// <param name="right">The second object to compare.</param>
    /// <returns>True if left is less than right; otherwise, false.</returns>
    public static bool operator <(AngleSingle left, AngleSingle right)
    {
        return left.Radians < right.Radians;
    }

    /// <summary>
    /// Returns a System.Boolean that indicates whether a Sedulous.Mathematics.Angle
    /// object is greater than another Sedulous.Mathematics.AngleSingle object.
    /// </summary>
    /// <param name="left">The first object to compare.</param>
    /// <param name="right">The second object to compare.</param>
    /// <returns>True if left is greater than right; otherwise, false.</returns>
    public static bool operator >(AngleSingle left, AngleSingle right)
    {
        return left.Radians > right.Radians;
    }

    /// <summary>
    /// Returns a System.Boolean that indicates whether a Sedulous.Mathematics.Angle
    /// object is less than or equal to another Sedulous.Mathematics.AngleSingle object.
    /// </summary>
    /// <param name="left">The first object to compare.</param>
    /// <param name="right">The second object to compare.</param>
    /// <returns>True if left is less than or equal to right; otherwise, false.</returns>
    public static bool operator <=(AngleSingle left, AngleSingle right)
    {
        return left.Radians <= right.Radians;
    }

    /// <summary>
    /// Returns a System.Boolean that indicates whether a Sedulous.Mathematics.Angle
    /// object is greater than or equal to another Sedulous.Mathematics.AngleSingle object.
    /// </summary>
    /// <param name="left">The first object to compare.</param>
    /// <param name="right">The second object to compare.</param>
    /// <returns>True if left is greater than or equal to right; otherwise, false.</returns>
    public static bool operator >=(AngleSingle left, AngleSingle right)
    {
        return left.Radians >= right.Radians;
    }

    /// <summary>
    /// Returns the value of the Sedulous.Mathematics.AngleSingle operand. (The sign of
    /// the operand is unchanged.)
    /// </summary>
    /// <param name="value">A Sedulous.Mathematics.AngleSingle object.</param>
    /// <returns>The value of the value parameter.</returns>
    public static AngleSingle operator +(AngleSingle value)
    {
        return value;
    }

    /// <summary>
    /// Returns the negated value of the Sedulous.Mathematics.AngleSingle operand.
    /// </summary>
    /// <param name="value">A Sedulous.Mathematics.AngleSingle object.</param>
    /// <returns>The negated value of the value parameter.</returns>
    public static AngleSingle operator -(AngleSingle value)
    {
        return AngleSingle(-value.Radians, AngleType.Radian);
    }

    /// <summary>
    /// Adds two Sedulous.Mathematics.AngleSingle objects and returns the result.
    /// </summary>
    /// <param name="left">The first object to add.</param>
    /// <param name="right">The second object to add.</param>
    /// <returns>The value of the two objects added together.</returns>
    public static AngleSingle operator +(AngleSingle left, AngleSingle right)
    {
        return AngleSingle(left.Radians + right.Radians, AngleType.Radian);
    }

    /// <summary>
    /// Subtracts two Sedulous.Mathematics.AngleSingle objects and returns the result.
    /// </summary>
    /// <param name="left">The first object to subtract</param>
    /// <param name="right">The second object to subtract.</param>
    /// <returns>The value of the two objects subtracted.</returns>
    public static AngleSingle operator -(AngleSingle left, AngleSingle right)
    {
        return AngleSingle(left.Radians - right.Radians, AngleType.Radian);
    }

    /// <summary>
    /// Multiplies two Sedulous.Mathematics.AngleSingle objects and returns the result.
    /// </summary>
    /// <param name="left">The first object to multiply.</param>
    /// <param name="right">The second object to multiply.</param>
    /// <returns>The value of the two objects multiplied together.</returns>
    public static AngleSingle operator *(AngleSingle left, AngleSingle right)
    {
        return AngleSingle(left.Radians * right.Radians, AngleType.Radian);
    }

    /// <summary>
    /// Divides two Sedulous.Mathematics.AngleSingle objects and returns the result.
    /// </summary>
    /// <param name="left">The numerator object.</param>
    /// <param name="right">The denominator object.</param>
    /// <returns>The value of the two objects divided.</returns>
    public static AngleSingle operator /(AngleSingle left, AngleSingle right)
    {
        return AngleSingle(left.Radians / right.Radians, AngleType.Radian);
    }

    /// <summary>
    /// Compares this instance to a specified object and returns an integer that
    /// indicates whether the value of this instance is less than, equal to, or greater
    /// than the value of the specified object.
    /// </summary>
    /// <param name="other">The object to compare.</param>
    /// <returns>
    /// A signed integer that indicates the relationship of the current instance
    /// to the obj parameter. If the value is less than zero, the current instance
    /// is less than the other. If the value is zero, the current instance is equal
    /// to the other. If the value is greater than zero, the current instance is
    /// greater than the other.
    /// </returns>

	public static int operator <=>(Self lhs, Self rhs)
	{
        if (lhs.Radians > rhs.Radians)
            return 1;

        if (lhs.Radians < rhs.Radians)
            return -1;

        return 0;
	}

    /// <summary>
    /// Compares this instance to a second Sedulous.Mathematics.AngleSingle and returns
    /// an integer that indicates whether the value of this instance is less than,
    /// equal to, or greater than the value of the specified object.
    /// </summary>
    /// <param name="other">The object to compare.</param>
    /// <returns>
    /// A signed integer that indicates the relationship of the current instance
    /// to the obj parameter. If the value is less than zero, the current instance
    /// is less than the other. If the value is zero, the current instance is equal
    /// to the other. If the value is greater than zero, the current instance is
    /// greater than the other.
    /// </returns>
    public int CompareTo(AngleSingle other)
    {
        if (this.Radians > other.Radians)
            return 1;

        if (this.Radians < other.Radians)
            return -1;

        return 0;
    }

    /// <summary>
    /// Returns a value that indicates whether the current instance and a specified
    /// Sedulous.Mathematics.AngleSingle object have the same value.
    /// </summary>
    /// <param name="other">The object to compare.</param>
    /// <returns>
    /// Returns true if this Sedulous.Mathematics.AngleSingle object and another have the same value;
    /// otherwise, false.
    /// </returns>
    public bool Equals(AngleSingle other)
    {
        return this == other;
    }

    /// <summary>
    /// Returns a <see cref="string"/> that represents this instance.
    /// </summary>
    /// <returns>
    /// A <see cref="string"/> that represents this instance.
    /// </returns>
    public override void ToString(String strBuffer) => strBuffer.Append("TODO");

    /// <summary>
    /// Returns a hash code for this Sedulous.Mathematics.AngleSingle instance.
    /// </summary>
    /// <returns>A 32-bit signed integer hash code.</returns>
    public int GetHashCode()
    {
        return Radians.GetHashCode();
    }
}
