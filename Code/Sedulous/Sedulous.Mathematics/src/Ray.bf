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
/// Represents a three dimensional line based on a point in space and a direction.
/// </summary>
public struct Ray : IEquatable<Ray>
{
    /// <summary>
    /// The position in three dimensional space where the ray starts.
    /// </summary>
    public Vector3 Position;

    /// <summary>
    /// The normalized direction in which the ray points.
    /// </summary>
    public Vector3 Direction;

    /// <summary>
    /// Initializes a new instance of the <see cref="Sedulous.Mathematics.Ray"/> struct.
    /// </summary>
    /// <param name="position">The position in three dimensional space of the origin of the ray.</param>
    /// <param name="direction">The normalized direction of the ray.</param>
    public this(Vector3 position, Vector3 direction)
    {
        this.Position = position;
        this.Direction = direction;
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a point.
    /// </summary>
    /// <param name="point">The point to test.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public bool Intersects(Vector3 point)
    {
        return CollisionHelper.RayIntersectsPoint(this, point);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a <see cref="Sedulous.Mathematics.Ray"/>.
    /// </summary>
    /// <param name="ray">The ray to test.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public bool Intersects(Ray ray)
    {
        Vector3 point;
        return CollisionHelper.RayIntersectsRay(this, ray, out point);
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
        return CollisionHelper.RayIntersectsRay(this, ray, out point);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a <see cref="Sedulous.Mathematics.Plane"/>.
    /// </summary>
    /// <param name="plane">The plane to test</param>
    /// <returns>Whether the two objects intersected.</returns>
    public bool Intersects(Plane plane)
    {
        float distance;
        return CollisionHelper.RayIntersectsPlane(this, plane, out distance);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a <see cref="Sedulous.Mathematics.Plane"/>.
    /// </summary>
    /// <param name="plane">The plane to test.</param>
    /// <param name="distance">When the method completes, contains the distance of the intersection,
    /// or 0 if there was no intersection.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public bool Intersects(Plane plane, out float distance)
    {
        return CollisionHelper.RayIntersectsPlane(this, plane, out distance);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a <see cref="Sedulous.Mathematics.Plane"/>.
    /// </summary>
    /// <param name="plane">The plane to test.</param>
    /// <param name="point">When the method completes, contains the point of intersection,
    /// or <see cref="Sedulous.Mathematics.Vector3.Zero"/> if there was no intersection.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public bool Intersects(Plane plane, out Vector3 point)
    {
        return CollisionHelper.RayIntersectsPlane(this, plane, out point);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a triangle.
    /// </summary>
    /// <param name="vertex1">The first vertex of the triangle to test.</param>
    /// <param name="vertex2">The second vertex of the triangle to test.</param>
    /// <param name="vertex3">The third vertex of the triangle to test.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public bool Intersects(Vector3 vertex1, Vector3 vertex2, Vector3 vertex3)
    {
        float distance;
        return CollisionHelper.RayIntersectsTriangle(this, vertex1, vertex2, vertex3, out distance);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a triangle.
    /// </summary>
    /// <param name="vertex1">The first vertex of the triangle to test.</param>
    /// <param name="vertex2">The second vertex of the triangle to test.</param>
    /// <param name="vertex3">The third vertex of the triangle to test.</param>
    /// <param name="distance">When the method completes, contains the distance of the intersection,
    /// or 0 if there was no intersection.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public bool Intersects(Vector3 vertex1, Vector3 vertex2, Vector3 vertex3, out float distance)
    {
        return CollisionHelper.RayIntersectsTriangle(this, vertex1, vertex2, vertex3, out distance);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a triangle.
    /// </summary>
    /// <param name="vertex1">The first vertex of the triangle to test.</param>
    /// <param name="vertex2">The second vertex of the triangle to test.</param>
    /// <param name="vertex3">The third vertex of the triangle to test.</param>
    /// <param name="point">When the method completes, contains the point of intersection,
    /// or <see cref="Sedulous.Mathematics.Vector3.Zero"/> if there was no intersection.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public bool Intersects(Vector3 vertex1, Vector3 vertex2, Vector3 vertex3, out Vector3 point)
    {
        return CollisionHelper.RayIntersectsTriangle(this, vertex1, vertex2, vertex3, out point);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a <see cref="Sedulous.Mathematics.BoundingBox"/>.
    /// </summary>
    /// <param name="box">The box to test.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public bool Intersects(BoundingBox @box)
    {
        float distance;
        return CollisionHelper.RayIntersectsBox(this, @box, out distance);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a <see cref="Sedulous.Mathematics.BoundingBox"/>.
    /// </summary>
    /// <param name="box">The box to test.</param>
    /// <param name="distance">When the method completes, contains the distance of the intersection,
    /// or 0 if there was no intersection.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public bool Intersects(BoundingBox @box, out float distance)
    {
        return CollisionHelper.RayIntersectsBox(this, @box, out distance);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a <see cref="Sedulous.Mathematics.BoundingBox"/>.
    /// </summary>
    /// <param name="box">The box to test.</param>
    /// <param name="point">When the method completes, contains the point of intersection,
    /// or <see cref="Sedulous.Mathematics.Vector3.Zero"/> if there was no intersection.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public bool Intersects(BoundingBox @box, out Vector3 point)
    {
        return CollisionHelper.RayIntersectsBox(this, @box, out point);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a <see cref="Sedulous.Mathematics.BoundingSphere"/>.
    /// </summary>
    /// <param name="sphere">The sphere to test.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public bool Intersects(BoundingSphere sphere)
    {
        float distance;
        return CollisionHelper.RayIntersectsSphere(this, sphere, out distance);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a <see cref="Sedulous.Mathematics.BoundingSphere"/>.
    /// </summary>
    /// <param name="sphere">The sphere to test.</param>
    /// <param name="distance">When the method completes, contains the distance of the intersection,
    /// or 0 if there was no intersection.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public bool Intersects(BoundingSphere sphere, out float distance)
    {
        return CollisionHelper.RayIntersectsSphere(this, sphere, out distance);
    }

    /// <summary>
    /// Determines if there is an intersection between the current object and a <see cref="Sedulous.Mathematics.BoundingSphere"/>.
    /// </summary>
    /// <param name="sphere">The sphere to test.</param>
    /// <param name="point">When the method completes, contains the point of intersection,
    /// or <see cref="Sedulous.Mathematics.Vector3.Zero"/> if there was no intersection.</param>
    /// <returns>Whether the two objects intersected.</returns>
    public bool Intersects(BoundingSphere sphere, out Vector3 point)
    {
        return CollisionHelper.RayIntersectsSphere(this, sphere, out point);
    }

    /// <summary>
    /// Tests for equality between two objects.
    /// </summary>
    /// <param name="left">The first value to compare.</param>
    /// <param name="right">The second value to compare.</param>
    /// <returns><c>true</c> if <paramref name="left"/> has the same value as <paramref name="right"/>; otherwise, <c>false</c>.</returns>
    public static bool operator ==(Ray left, Ray right)
    {
        return left.Equals(right);
    }

    /// <summary>
    /// Tests for inequality between two objects.
    /// </summary>
    /// <param name="left">The first value to compare.</param>
    /// <param name="right">The second value to compare.</param>
    /// <returns><c>true</c> if <paramref name="left"/> has a different value than <paramref name="right"/>; otherwise, <c>false</c>.</returns>
    public static bool operator !=(Ray left, Ray right)
    {
        return !left.Equals(right);
    }

    /// <summary>
    /// Returns a <see cref="string"/> that represents this instance.
    /// </summary>
    /// <returns>
    /// A <see cref="string"/> that represents this instance.
    /// </returns>
    public override void ToString(String str) => str.Append( scope $"{{Position:{Position} Direction:{Direction}}}");

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
            hash = hash * 23 + Position.GetHashCode();
            hash = hash * 23 + Direction.GetHashCode();
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
    public bool Equals(Ray value)
    {
        return Position == value.Position && Direction == value.Direction;
    }
}
