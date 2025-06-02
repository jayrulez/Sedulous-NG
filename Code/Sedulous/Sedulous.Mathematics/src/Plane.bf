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
/// Represents a plane in three dimensional space.
/// </summary>
[CRepr]public struct Plane : IEquatable<Plane>, IIntersectableWithRay
{
    /// <summary>
    /// The normal vector of the plane.
    /// </summary>
    public Vector3 Normal;

    /// <summary>
    /// The distance of the plane along its normal from the origin.
    /// </summary>
    public float D;

    /// <summary>
    /// Initializes a new instance of the <see cref="Sedulous.Mathematics.Plane"/> struct.
    /// </summary>
    /// <param name="value">The value that will be assigned to all components.</param>
    public this(float value)
    {
        Normal.X = Normal.Y = Normal.Z = D = value;
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Sedulous.Mathematics.Plane"/> struct.
    /// </summary>
    /// <param name="a">The X component of the normal.</param>
    /// <param name="b">The Y component of the normal.</param>
    /// <param name="c">The Z component of the normal.</param>
    /// <param name="d">The distance of the plane along its normal from the origin.</param>
    public this(float a, float b, float c, float d)
    {
        Normal.X = a;
        Normal.Y = b;
        Normal.Z = c;
        D = d;
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Plane"/> struct.
    /// </summary>
    /// <param name="point">Any point that lies along the plane.</param>
    /// <param name="normal">The normal vector to the plane.</param>
    public this(Vector3 point, Vector3 normal)
    {
        Normal = normal;
        Vector3.Dot(normal, point, out D);
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Sedulous.Mathematics.Plane"/> struct.
    /// </summary>
    /// <param name="value">The normal of the plane.</param>
    /// <param name="d">The distance of the plane along its normal from the origin</param>
    public this(Vector3 value, float d)
    {
        Normal = value;
        D = d;
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Sedulous.Mathematics.Plane"/> struct.
    /// </summary>
    /// <param name="point1">First point of a triangle defining the plane.</param>
    /// <param name="point2">Second point of a triangle defining the plane.</param>
    /// <param name="point3">Third point of a triangle defining the plane.</param>
    public this(Vector3 point1, Vector3 point2, Vector3 point3)
    {
        float x1 = point2.X - point1.X;
        float y1 = point2.Y - point1.Y;
        float z1 = point2.Z - point1.Z;
        float x2 = point3.X - point1.X;
        float y2 = point3.Y - point1.Y;
        float z2 = point3.Z - point1.Z;
        float yz = (y1 * z2) - (z1 * y2);
        float xz = (z1 * x2) - (x1 * z2);
        float xy = (x1 * y2) - (y1 * x2);
        float invPyth = 1.0f / Math.Sqrt((yz * yz) + (xz * xz) + (xy * xy));

        Normal.X = yz * invPyth;
        Normal.Y = xz * invPyth;
        Normal.Z = xy * invPyth;
        D = -((Normal.X * point1.X) + (Normal.Y * point1.Y) + (Normal.Z * point1.Z));
    }

    /// <summary>
    /// Gets or sets the component at the specified index.
    /// </summary>
    /// <value>The value of the A, B, C, or D component, depending on the index.</value>
    /// <param name="index">The index of the component to access. Use 0 for the A component, 1 for the B component, 2 for the C component, and 3 for the D component.</param>
    /// <returns>The value of the component at the specified index.</returns>
    /// <exception cref="System.ArgumentOutOfRangeException">Thrown when the <paramref name="index"/> is out of the range [0, 3].</exception>
    public float this[int32 index]
    {
        get
        {
            switch (index)
            {
                case 0: return Normal.X;
                case 1: return Normal.Y;
                case 2: return Normal.Z;
                case 3: return D;
            }

            Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(index)}:Indices for Plane run from 0 to 3, inclusive.");
        }

        set mut
        {
            switch (index)
            {
                case 0: Normal.X = value; break;
                case 1: Normal.Y = value; break;
                case 2: Normal.Z = value; break;
                case 3: D = value; break;
                default: Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(index)}:Indices for Plane run from 0 to 3, inclusive.");
            }
        }
    }

    /// <summary>
    /// Negates a plane by negating all its coefficients, which result in a plane in opposite direction.
    /// </summary>
    public void Negate() mut
    {
        Normal.X = -Normal.X;
        Normal.Y = -Normal.Y;
        Normal.Z = -Normal.Z;
        D = -D;
    }

    /// <summary>
    /// Changes the coefficients of the normal vector of the plane to make it of unit length.
    /// </summary>
    public void Normalize() mut
    {
        float magnitude = 1.0f / Math.Sqrt((Normal.X * Normal.X) + (Normal.Y * Normal.Y) + (Normal.Z * Normal.Z));

        Normal.X *= magnitude;
        Normal.Y *= magnitude;
        Normal.Z *= magnitude;
        D *= magnitude;
    }

    /// <summary>
    /// Creates an array containing the elements of the plane.
    /// </summary>
    /// <returns>A four-element array containing the components of the plane.</returns>
    public float[4] ToArray()
    {
        return .(Normal.X, Normal.Y, Normal.Z, D);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a point.
    /// </summary>
    /// <param name="point">The point to test.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public PlaneIntersectionType Intersects(Vector3 point)
    {
        return CollisionHelper.PlaneIntersectsPoint(this, point);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a <see cref="Sedulous.Mathematics.Ray"/>.
    /// </summary>
    /// <param name="ray">The ray to test.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public bool Intersects(Ray ray)
    {
        float distance;
        return CollisionHelper.RayIntersectsPlane(ray, this, out distance);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a <see cref="Sedulous.Mathematics.Ray"/>.
    /// </summary>
    /// <param name="ray">The ray to test.</param>
    /// <param name="distance">When the method completes, contains the distance of the intersection,
    /// or 0 if there was no intersection.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public bool Intersects(Ray ray, out float distance)
    {
        return CollisionHelper.RayIntersectsPlane(ray, this, out distance);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a <see cref="Sedulous.Mathematics.Ray"/>.
    /// </summary>
    /// <param name="ray">The ray to test.</param>
    /// <param name="point">When the method completes, contains the point of intersection,
    /// or <see cref="Sedulous.Mathematics.Vector3.Zero"/> if there was no intersection.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public bool Intersects(Ray ray, out Vector3 point)
    {
        return CollisionHelper.RayIntersectsPlane(ray, this, out point);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a <see cref="Sedulous.Mathematics.Plane"/>.
    /// </summary>
    /// <param name="plane">The plane to test.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public bool Intersects(Plane plane)
    {
        return CollisionHelper.PlaneIntersectsPlane(this, plane);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a <see cref="Sedulous.Mathematics.Plane"/>.
    /// </summary>
    /// <param name="plane">The plane to test.</param>
    /// <param name="line">When the method completes, contains the line of intersection
    /// as a <see cref="Sedulous.Mathematics.Ray"/>, or a zero ray if there was no intersection.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public bool Intersects(Plane plane, out Ray line)
    {
        return CollisionHelper.PlaneIntersectsPlane(this, plane, out line);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a triangle.
    /// </summary>
    /// <param name="vertex1">The first vertex of the triangle to test.</param>
    /// <param name="vertex2">The second vertex of the triagnle to test.</param>
    /// <param name="vertex3">The third vertex of the triangle to test.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public PlaneIntersectionType Intersects(Vector3 vertex1, Vector3 vertex2, Vector3 vertex3)
    {
        return CollisionHelper.PlaneIntersectsTriangle(this, vertex1, vertex2, vertex3);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a <see cref="Sedulous.Mathematics.BoundingBox"/>.
    /// </summary>
    /// <param name="box">The box to test.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public PlaneIntersectionType Intersects(BoundingBox @box)
    {
        return CollisionHelper.PlaneIntersectsBox(this, @box);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a <see cref="Sedulous.Mathematics.BoundingSphere"/>.
    /// </summary>
    /// <param name="sphere">The sphere to test.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public PlaneIntersectionType Intersects(BoundingSphere sphere)
    {
        return CollisionHelper.PlaneIntersectsSphere(this, sphere);
    }

    /// <summary>
    /// Scales the plane by the given scaling factor.
    /// </summary>
    /// <param name="value">The plane to scale.</param>
    /// <param name="scale">The amount by which to scale the plane.</param>
    /// <param name="result">When the method completes, contains the scaled plane.</param>
    public static void Multiply(Plane value, float scale, out Plane result)
    {
        result.Normal.X = value.Normal.X * scale;
        result.Normal.Y = value.Normal.Y * scale;
        result.Normal.Z = value.Normal.Z * scale;
        result.D = value.D * scale;
    }

    /// <summary>
    /// Scales the plane by the given scaling factor.
    /// </summary>
    /// <param name="value">The plane to scale.</param>
    /// <param name="scale">The amount by which to scale the plane.</param>
    /// <returns>The scaled plane.</returns>
    public static Plane Multiply(Plane value, float scale)
    {
        return Plane(value.Normal.X * scale, value.Normal.Y * scale, value.Normal.Z * scale, value.D * scale);
    }

    /// <summary>
    /// Calculates the dot product of the specified vector and plane.
    /// </summary>
    /// <param name="left">The source plane.</param>
    /// <param name="right">The source vector.</param>
    /// <param name="result">When the method completes, contains the dot product of the specified plane and vector.</param>
    public static void Dot(Plane left, Vector4 right, out float result)
    {
        result = (left.Normal.X * right.X) + (left.Normal.Y * right.Y) + (left.Normal.Z * right.Z) + (left.D * right.W);
    }

    /// <summary>
    /// Calculates the dot product of the specified vector and plane.
    /// </summary>
    /// <param name="left">The source plane.</param>
    /// <param name="right">The source vector.</param>
    /// <returns>The dot product of the specified plane and vector.</returns>
    public static float Dot(Plane left, Vector4 right)
    {
        return (left.Normal.X * right.X) + (left.Normal.Y * right.Y) + (left.Normal.Z * right.Z) + (left.D * right.W);
    }

    /// <summary>
    /// Calculates the dot product of a specified vector and the normal of the plane plus the distance value of the plane.
    /// </summary>
    /// <param name="left">The source plane.</param>
    /// <param name="right">The source vector.</param>
    /// <param name="result">When the method completes, contains the dot product of a specified vector and the normal of the Plane plus the distance value of the plane.</param>
    public static void DotCoordinate(Plane left, Vector3 right, out float result)
    {
        result = (left.Normal.X * right.X) + (left.Normal.Y * right.Y) + (left.Normal.Z * right.Z) + left.D;
    }

    /// <summary>
    /// Calculates the dot product of a specified vector and the normal of the plane plus the distance value of the plane.
    /// </summary>
    /// <param name="left">The source plane.</param>
    /// <param name="right">The source vector.</param>
    /// <returns>The dot product of a specified vector and the normal of the Plane plus the distance value of the plane.</returns>
    public static float DotCoordinate(Plane left, Vector3 right)
    {
        return (left.Normal.X * right.X) + (left.Normal.Y * right.Y) + (left.Normal.Z * right.Z) + left.D;
    }

    /// <summary>
    /// Calculates the dot product of the specified vector and the normal of the plane.
    /// </summary>
    /// <param name="left">The source plane.</param>
    /// <param name="right">The source vector.</param>
    /// <param name="result">When the method completes, contains the dot product of the specified vector and the normal of the plane.</param>
    public static void DotNormal(Plane left, Vector3 right, out float result)
    {
        result = (left.Normal.X * right.X) + (left.Normal.Y * right.Y) + (left.Normal.Z * right.Z);
    }

    /// <summary>
    /// Calculates the dot product of the specified vector and the normal of the plane.
    /// </summary>
    /// <param name="left">The source plane.</param>
    /// <param name="right">The source vector.</param>
    /// <returns>The dot product of the specified vector and the normal of the plane.</returns>
    public static float DotNormal(Plane left, Vector3 right)
    {
        return (left.Normal.X * right.X) + (left.Normal.Y * right.Y) + (left.Normal.Z * right.Z);
    }

    /// <summary>
    /// Projects a point onto a plane.
    /// </summary>
    /// <param name="plane">The plane to project the point to.</param>
    /// <param name="point">The point to project.</param>
    /// <param name="result">The projected point.</param>
    public static void Project(Plane plane, Vector3 point, out Vector3 result)
    {
        DotCoordinate(plane, point, var distance);

        // compute: point - distance * plane.Normal
        Vector3.Multiply(plane.Normal, distance, out result);
        Vector3.Subtract(point, result, out result);
    }

    /// <summary>
    /// Projects a point onto a plane.
    /// </summary>
    /// <param name="plane">The plane to project the point to.</param>
    /// <param name="point">The point to project.</param>
    /// <returns>The projected point.</returns>
    public static Vector3 Project(Plane plane, Vector3 point)
    {
        Project(plane, point, var result);
        return result;
    }

    /// <summary>
    /// Creates a plane of unit length.
    /// </summary>
    /// <param name="normalX">The X component of the normal.</param>
    /// <param name="normalY">The Y component of the normal.</param>
    /// <param name="normalZ">The Z component of the normal.</param>
    /// <param name="planeD">The distance of the plane along its normal from the origin.</param>
    /// <param name="result">When the method completes, contains the normalized plane.</param>
    public static void Normalize(float normalX, float normalY, float normalZ, float planeD, out Plane result)
    {
        float magnitude = 1.0f / Math.Sqrt((normalX * normalX) + (normalY * normalY) + (normalZ * normalZ));

        result.Normal.X = normalX * magnitude;
        result.Normal.Y = normalY * magnitude;
        result.Normal.Z = normalZ * magnitude;
        result.D = planeD * magnitude;
    }

    /// <summary>
    /// Changes the coefficients of the normal vector of the plane to make it of unit length.
    /// </summary>
    /// <param name="plane">The source plane.</param>
    /// <param name="result">When the method completes, contains the normalized plane.</param>
    public static void Normalize(Plane plane, out Plane result)
    {
        float magnitude = 1.0f / Math.Sqrt((plane.Normal.X * plane.Normal.X) + (plane.Normal.Y * plane.Normal.Y) + (plane.Normal.Z * plane.Normal.Z));

        result.Normal.X = plane.Normal.X * magnitude;
        result.Normal.Y = plane.Normal.Y * magnitude;
        result.Normal.Z = plane.Normal.Z * magnitude;
        result.D = plane.D * magnitude;
    }

    /// <summary>
    /// Changes the coefficients of the normal vector of the plane to make it of unit length.
    /// </summary>
    /// <param name="plane">The source plane.</param>
    /// <returns>The normalized plane.</returns>
    public static Plane Normalize(Plane plane)
    {
        float magnitude = 1.0f / Math.Sqrt((plane.Normal.X * plane.Normal.X) + (plane.Normal.Y * plane.Normal.Y) + (plane.Normal.Z * plane.Normal.Z));
        return Plane(plane.Normal.X * magnitude, plane.Normal.Y * magnitude, plane.Normal.Z * magnitude, plane.D * magnitude);
    }

    /// <summary>
    /// Negates a plane by negating all its coefficients, which result in a plane in opposite direction.
    /// </summary>
    /// <param name="plane">The source plane.</param>
    /// <param name="result">When the method completes, contains the flipped plane.</param>
    public static void Negate(Plane plane, out Plane result)
    {
        result.Normal.X = -plane.Normal.X;
        result.Normal.Y = -plane.Normal.Y;
        result.Normal.Z = -plane.Normal.Z;
        result.D = -plane.D;
    }

    /// <summary>
    /// Negates a plane by negating all its coefficients, which result in a plane in opposite direction.
    /// </summary>
    /// <param name="plane">The source plane.</param>
    /// <returns>The flipped plane.</returns>
    public static Plane Negate(Plane plane)
    {
        float magnitude = 1.0f / Math.Sqrt((plane.Normal.X * plane.Normal.X) + (plane.Normal.Y * plane.Normal.Y) + (plane.Normal.Z * plane.Normal.Z));
        return Plane(plane.Normal.X * magnitude, plane.Normal.Y * magnitude, plane.Normal.Z * magnitude, plane.D * magnitude);
    }

    /// <summary>
    /// Transforms a normalized plane by a quaternion rotation.
    /// </summary>
    /// <param name="plane">The normalized source plane.</param>
    /// <param name="rotation">The quaternion rotation.</param>
    /// <param name="result">When the method completes, contains the transformed plane.</param>
    public static void Transform(Plane plane, Quaternion rotation, out Plane result)
    {
        float x2 = rotation.X + rotation.X;
        float y2 = rotation.Y + rotation.Y;
        float z2 = rotation.Z + rotation.Z;
        float wx = rotation.W * x2;
        float wy = rotation.W * y2;
        float wz = rotation.W * z2;
        float xx = rotation.X * x2;
        float xy = rotation.X * y2;
        float xz = rotation.X * z2;
        float yy = rotation.Y * y2;
        float yz = rotation.Y * z2;
        float zz = rotation.Z * z2;

        float x = plane.Normal.X;
        float y = plane.Normal.Y;
        float z = plane.Normal.Z;

        result.Normal.X = ((x * ((1.0f - yy) - zz)) + (y * (xy - wz))) + (z * (xz + wy));
        result.Normal.Y = ((x * (xy + wz)) + (y * ((1.0f - xx) - zz))) + (z * (yz - wx));
        result.Normal.Z = ((x * (xz - wy)) + (y * (yz + wx))) + (z * ((1.0f - xx) - yy));
        result.D = plane.D;
    }

    /// <summary>
    /// Transforms a normalized plane by a quaternion rotation.
    /// </summary>
    /// <param name="plane">The normalized source plane.</param>
    /// <param name="rotation">The quaternion rotation.</param>
    /// <returns>The transformed plane.</returns>
    public static Plane Transform(Plane plane, Quaternion rotation)
    {
        Plane result;
        float x2 = rotation.X + rotation.X;
        float y2 = rotation.Y + rotation.Y;
        float z2 = rotation.Z + rotation.Z;
        float wx = rotation.W * x2;
        float wy = rotation.W * y2;
        float wz = rotation.W * z2;
        float xx = rotation.X * x2;
        float xy = rotation.X * y2;
        float xz = rotation.X * z2;
        float yy = rotation.Y * y2;
        float yz = rotation.Y * z2;
        float zz = rotation.Z * z2;

        float x = plane.Normal.X;
        float y = plane.Normal.Y;
        float z = plane.Normal.Z;

        result.Normal.X = ((x * ((1.0f - yy) - zz)) + (y * (xy - wz))) + (z * (xz + wy));
        result.Normal.Y = ((x * (xy + wz)) + (y * ((1.0f - xx) - zz))) + (z * (yz - wx));
        result.Normal.Z = ((x * (xz - wy)) + (y * (yz + wx))) + (z * ((1.0f - xx) - yy));
        result.D = plane.D;

        return result;
    }

    /// <summary>
    /// Transforms an array of normalized planes by a quaternion rotation.
    /// </summary>
    /// <param name="planes">The array of normalized planes to transform.</param>
    /// <param name="rotation">The quaternion rotation.</param>
    /// <exception cref="ArgumentNullException">Thrown when <paramref name="planes"/> is <c>null</c>.</exception>
    public static void Transform(Plane[] planes, Quaternion rotation)
    {
        if (planes == null)
            Runtime.FatalError(scope $"ArgumentNullException - {nameof(planes)}");

        float x2 = rotation.X + rotation.X;
        float y2 = rotation.Y + rotation.Y;
        float z2 = rotation.Z + rotation.Z;
        float wx = rotation.W * x2;
        float wy = rotation.W * y2;
        float wz = rotation.W * z2;
        float xx = rotation.X * x2;
        float xy = rotation.X * y2;
        float xz = rotation.X * z2;
        float yy = rotation.Y * y2;
        float yz = rotation.Y * z2;
        float zz = rotation.Z * z2;

        for (int32 i = 0; i < planes.Count; ++i)
        {
            float x = planes[i].Normal.X;
            float y = planes[i].Normal.Y;
            float z = planes[i].Normal.Z;

            /*
             * Note:
             * Factor common arithmetic out of loop.
            */
            planes[i].Normal.X = ((x * ((1.0f - yy) - zz)) + (y * (xy - wz))) + (z * (xz + wy));
            planes[i].Normal.Y = ((x * (xy + wz)) + (y * ((1.0f - xx) - zz))) + (z * (yz - wx));
            planes[i].Normal.Z = ((x * (xz - wy)) + (y * (yz + wx))) + (z * ((1.0f - xx) - yy));
        }
    }

    /// <summary>
    /// Transforms a normalized plane by a matrix.
    /// </summary>
    /// <param name="plane">The normalized source plane.</param>
    /// <param name="transformation">The transformation matrix.</param>
    /// <param name="result">When the method completes, contains the transformed plane.</param>
    public static void Transform(Plane plane, Matrix transformation, out Plane result)
    {
        float x = plane.Normal.X;
        float y = plane.Normal.Y;
        float z = plane.Normal.Z;
        float d = plane.D;

        Matrix.Invert(transformation, var inverse);

        result.Normal.X = (((x * inverse.M11) + (y * inverse.M12)) + (z * inverse.M13)) + (d * inverse.M14);
        result.Normal.Y = (((x * inverse.M21) + (y * inverse.M22)) + (z * inverse.M23)) + (d * inverse.M24);
        result.Normal.Z = (((x * inverse.M31) + (y * inverse.M32)) + (z * inverse.M33)) + (d * inverse.M34);
        result.D = (((x * inverse.M41) + (y * inverse.M42)) + (z * inverse.M43)) + (d * inverse.M44);
    }

    /// <summary>
    /// Transforms a normalized plane by a matrix.
    /// </summary>
    /// <param name="plane">The normalized source plane.</param>
    /// <param name="transformation">The transformation matrix.</param>
    /// <returns>When the method completes, contains the transformed plane.</returns>
    public static Plane Transform(Plane plane, Matrix transformation)
    {
		var transformation;
        Plane result;
        float x = plane.Normal.X;
        float y = plane.Normal.Y;
        float z = plane.Normal.Z;
        float d = plane.D;

        transformation.Invert();
        result.Normal.X = (((x * transformation.M11) + (y * transformation.M12)) + (z * transformation.M13)) + (d * transformation.M14);
        result.Normal.Y = (((x * transformation.M21) + (y * transformation.M22)) + (z * transformation.M23)) + (d * transformation.M24);
        result.Normal.Z = (((x * transformation.M31) + (y * transformation.M32)) + (z * transformation.M33)) + (d * transformation.M34);
        result.D = (((x * transformation.M41) + (y * transformation.M42)) + (z * transformation.M43)) + (d * transformation.M44);

        return result;
    }

    /// <summary>
    /// Transforms an array of normalized planes by a matrix.
    /// </summary>
    /// <param name="planes">The array of normalized planes to transform.</param>
    /// <param name="transformation">The transformation matrix.</param>
    /// <exception cref="ArgumentNullException">Thrown when <paramref name="planes"/> is <c>null</c>.</exception>
    public static void Transform(Plane[] planes, Matrix transformation)
    {
        if (planes == null)
            Runtime.FatalError(scope $"ArgumentNullException - {nameof(planes)}");

        Matrix inverse;
        Matrix.Invert(transformation, out inverse);

        for (int32 i = 0; i < planes.Count; ++i)
        {
            Transform(planes[i], transformation, out planes[i]);
        }
    }

    /// <summary>
    /// Scales a plane by the given value.
    /// </summary>
    /// <param name="scale">The amount by which to scale the plane.</param>
    /// <param name="plane">The plane to scale.</param>
    /// <returns>The scaled plane.</returns>
    public static Plane operator *(float scale, Plane plane)
    {
        return Plane(plane.Normal.X * scale, plane.Normal.Y * scale, plane.Normal.Z * scale, plane.D * scale);
    }

    /// <summary>
    /// Scales a plane by the given value.
    /// </summary>
    /// <param name="plane">The plane to scale.</param>
    /// <param name="scale">The amount by which to scale the plane.</param>
    /// <returns>The scaled plane.</returns>
    public static Plane operator *(Plane plane, float scale)
    {
        return Plane(plane.Normal.X * scale, plane.Normal.Y * scale, plane.Normal.Z * scale, plane.D * scale);
    }

    /// <summary>
    /// Negates a plane by negating all its coefficients, which result in a plane in opposite direction.
    /// </summary>
    /// <returns>The negated plane.</returns>
    public static Plane operator -(Plane plane)
    {
        return Plane(-plane.Normal.X, -plane.Normal.Y, -plane.Normal.Z, -plane.D);
    }

    /// <summary>
    /// Tests for equality between two objects.
    /// </summary>
    /// <param name="left">The first value to compare.</param>
    /// <param name="right">The second value to compare.</param>
    /// <returns><c>true</c> if <paramref name="left"/> has the same value as <paramref name="right"/>; otherwise, <c>false</c>.</returns>
    public static bool operator ==(Plane left, Plane right)
    {
        return left.Equals(right);
    }

    /// <summary>
    /// Tests for inequality between two objects.
    /// </summary>
    /// <param name="left">The first value to compare.</param>
    /// <param name="right">The second value to compare.</param>
    /// <returns><c>true</c> if <paramref name="left"/> has a different value than <paramref name="right"/>; otherwise, <c>false</c>.</returns>
    public static bool operator !=(Plane left, Plane right)
    {
        return !left.Equals(right);
    }

    /// <summary>
    /// Returns a <see cref="string"/> that represents this instance.
    /// </summary>
    /// <returns>
    /// A <see cref="string"/> that represents this instance.
    /// </returns>
	public override void ToString(String str) => str.Append(scope $"{{Normal:{Normal} D:{D}}}");

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
	        hash = hash * 23 + Normal.GetHashCode();
	        hash = hash * 23 + D.GetHashCode();
	        return hash;
	    }
	}

    /// <summary>
    /// Determines whether the specified <see cref="Sedulous.Mathematics.Vector4"/> is equal to this instance.
    /// </summary>
    /// <param name="value">The <see cref="Sedulous.Mathematics.Vector4"/> to compare with this instance.</param>
    /// <returns>
    /// <c>true</c> if the specified <see cref="Sedulous.Mathematics.Vector4"/> is equal to this instance; otherwise, <c>false</c>.
    /// </returns>
    public bool Equals(Plane value)
    {
        return Normal == value.Normal && D == value.D;
    }
}
