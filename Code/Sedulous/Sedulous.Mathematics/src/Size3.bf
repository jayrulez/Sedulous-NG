using System;
// Copyright (c) .NET Foundation and Contributors (https://dotnetfoundation.org/ & https://stride3d.net) and Silicon Studio Corp. (https://www.siliconstudio.co.jp)
// Distributed under the MIT license. See the LICENSE.md file in the project root for more information.
//
// Copyright (c) 2010-2013 SharpDX - Alexandre Mutel
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
/// Structure providing Width, Height and Depth.
/// </summary>
public struct Size3 : IEquatable<Size3>
{
    /// <summary>
    /// A zero size with (width, height, depth) = (0,0,0)
    /// </summary>
    public static readonly Size3 Zero = .(0, 0, 0);

    /// <summary>
    /// A one size with (width, height, depth) = (1,1,1)
    /// </summary>
    public static readonly Size3 One = .(1, 1, 1);

    /// <summary>
    /// A zero size with (width, height, depth) = (0,0,0)
    /// </summary>
    public static readonly Size3 Empty = Zero;

    /// <summary>
    /// Initializes a new instance of the <see cref="Size3" /> struct.
    /// </summary>
    /// <param name="width">The x.</param>
    /// <param name="height">The y.</param>
    /// <param name="depth">The depth.</param>
    public this(int32 width, int32 height, int32 depth)
    {
        Width = width;
        Height = height;
        Depth = depth;
    }

    /// <summary>
    /// Width.
    /// </summary>
    public int32 Width;

    /// <summary>
    /// Height.
    /// </summary>
    public int32 Height;

    /// <summary>
    /// Height.
    /// </summary>
    public int32 Depth;

    /// <summary>
    /// Gets a volume size.
    /// </summary>
    private readonly int64 VolumeSize
    {
        get
        {
            return (int64)Width * Height * Depth;
        }
    }

    /// <inheritdoc/>
    public bool Equals(Size3 other)
    {
        return Width == other.Width && Height == other.Height && Depth == other.Depth;
    }

    /// <inheritdoc/>
    public int GetHashCode()
    {
		int hash = 17;
		hash = HashCode.Mix(hash, Width);
		hash = HashCode.Mix(hash, Height);
		hash = HashCode.Mix(hash, Depth);
        return hash;
    }

    /// <inheritdoc/>
    public int CompareTo(Size3 other)
    {
        return Math.Sign(this.VolumeSize - other.VolumeSize);
    }

    /// <inheritdoc/>
    public override void ToString(String strBuffer) => strBuffer.Append("TODO");

    /// <summary>
    /// Implements the &lt;.
    /// </summary>
    /// <param name="left">The left.</param>
    /// <param name="right">The right.</param>
    /// <returns>The result of the operator.</returns>
    public static bool operator <(Size3 left, Size3 right)
    {
        return left.CompareTo(right) < 0;
    }

    /// <summary>
    /// Implements the &lt;.
    /// </summary>
    /// <param name="left">The left.</param>
    /// <param name="right">The right.</param>
    /// <returns>The result of the operator.</returns>
    public static bool operator <=(Size3 left, Size3 right)
    {
        return left.CompareTo(right) <= 0;
    }

    /// <summary>
    /// Implements the &lt; or ==.
    /// </summary>
    /// <param name="left">The left.</param>
    /// <param name="right">The right.</param>
    /// <returns>The result of the operator.</returns>
    public static bool operator >(Size3 left, Size3 right)
    {
        return left.CompareTo(right) > 0;
    }

    /// <summary>
    /// Implements the &gt; or ==.
    /// </summary>
    /// <param name="left">The left.</param>
    /// <param name="right">The right.</param>
    /// <returns>The result of the operator.</returns>
    public static bool operator >=(Size3 left, Size3 right)
    {
        return left.CompareTo(right) >= 0;
    }

    /// <summary>
    /// Implements the ==.
    /// </summary>
    /// <param name="left">The left.</param>
    /// <param name="right">The right.</param>
    /// <returns>The result of the operator.</returns>
    public static bool operator ==(Size3 left, Size3 right)
    {
        return left.Equals(right);
    }

    /// <summary>
    /// Implements the !=.
    /// </summary>
    /// <param name="left">The left.</param>
    /// <param name="right">The right.</param>
    /// <returns>The result of the operator.</returns>
    public static bool operator !=(Size3 left, Size3 right)
    {
        return !left.Equals(right);
    }

    /// <summary>
    /// Calculates the next up mip-level (*2) of this size.
    /// </summary>
    /// <returns>A next up mip-level Size3.</returns>
    public Size3 Up2(int32 count = 1)
    {
        if (count < 0)
        {
            Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(count)}: Must be >= 0");
        }

        return Size3(Math.Max(1, Width << count), Math.Max(1, Height << count), Math.Max(1, Depth << count));
    }

    /// <summary>
    /// Calculates the next down mip-level (/2) of this size.
    /// </summary>
    /// <param name="count">The count.</param>
    /// <returns>A next down mip-level Size3.</returns>
    public Size3 Down2(int32 count = 1)
    {
        if (count < 0)
        {
            Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(count)}: Must be >= 0");
        }

        return Size3(Math.Max(1, Width >> count), Math.Max(1, Height >> count), Math.Max(1, Depth >> count));
    }

    /// <summary>
    /// Calculates the mip size based on a direction.
    /// </summary>
    /// <param name="direction">The direction &lt; 0 then <see cref="Down2"/>, &gt; 0  then <see cref="Up2"/>, else this unchanged.</param>
    /// <returns>Size3.</returns>
    public Size3 Mip(int32 direction)
    {
        return direction == 0 ? this : direction < 0 ? Down2() : Up2();
    }

    /// <summary>
    /// Deconstructs the vector's components into named variables.
    /// </summary>
    /// <param name="width">The Width component</param>
    /// <param name="height">The Height component</param>
    /// <param name="depth">The Depth component</param>
    public void Deconstruct(out int32 width, out int32 height, out int32 depth)
    {
        width = Width;
        height = Height;
        depth = Depth;
    }
}
