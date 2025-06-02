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
/// Represents a 4x4 mathematical matrix.
/// </summary>
public struct Matrix : IEquatable<Matrix>
{
    /// <summary> Are matrix row or column major </summary>
    /// <remarks>
    /// Dotnet's <see cref="System.Numerics.Matrix4x4"/> are row major.
    /// </remarks>
    public const bool LayoutIsRowMajor = false;

    /// <summary>
    /// The size of the <see cref="Matrix"/> type, in bytes.
    /// </summary>
    public static readonly int32 SizeInBytes = sizeof(Matrix);

    /// <summary>
    /// A <see cref="Matrix"/> with all of its components set to zero.
    /// </summary>
    public static readonly Matrix Zero = .();

    /// <summary>
    /// The identity <see cref="Matrix"/>.
    /// </summary>
    public static readonly Matrix Identity = .() { M11 = 1.0f, M22 = 1.0f, M33 = 1.0f, M44 = 1.0f };

    /// <summary>
    /// Value at row 1 column 1 of the matrix.
    /// </summary>
    public float M11;

    /// <summary>
    /// Value at row 2 column 1 of the matrix.
    /// </summary>
    public float M21;

    /// <summary>
    /// Value at row 3 column 1 of the matrix.
    /// </summary>
    public float M31;

    /// <summary>
    /// Value at row 4 column 1 of the matrix.
    /// </summary>
    public float M41;

    /// <summary>
    /// Value at row 1 column 2 of the matrix.
    /// </summary>
    public float M12;

    /// <summary>
    /// Value at row 2 column 2 of the matrix.
    /// </summary>
    public float M22;

    /// <summary>
    /// Value at row 3 column 2 of the matrix.
    /// </summary>
    public float M32;

    /// <summary>
    /// Value at row 4 column 2 of the matrix.
    /// </summary>
    public float M42;

    /// <summary>
    /// Value at row 1 column 3 of the matrix.
    /// </summary>
    public float M13;

    /// <summary>
    /// Value at row 2 column 3 of the matrix.
    /// </summary>
    public float M23;

    /// <summary>
    /// Value at row 3 column 3 of the matrix.
    /// </summary>
    public float M33;

    /// <summary>
    /// Value at row 4 column 3 of the matrix.
    /// </summary>
    public float M43;

    /// <summary>
    /// Value at row 1 column 4 of the matrix.
    /// </summary>
    public float M14;

    /// <summary>
    /// Value at row 2 column 4 of the matrix.
    /// </summary>
    public float M24;

    /// <summary>
    /// Value at row 3 column 4 of the matrix.
    /// </summary>
    public float M34;

    /// <summary>
    /// Value at row 4 column 4 of the matrix.
    /// </summary>
    public float M44;

    /// <summary>
    /// Initializes a new instance of the <see cref="Matrix"/> struct.
    /// </summary>
    public this()
    {
		float value= 0;
        M11 = M21 = M31 = M41 =
        M12 = M22 = M32 = M42 =
        M13 = M23 = M33 = M43 =
        M14 = M24 = M34 = M44 = value;
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Matrix"/> struct.
    /// </summary>
    /// <param name="value">The value that will be assigned to all components.</param>
    public this(float value)
    {
        M11 = M21 = M31 = M41 =
        M12 = M22 = M32 = M42 =
        M13 = M23 = M33 = M43 =
        M14 = M24 = M34 = M44 = value;
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Matrix"/> struct.
    /// </summary>
    /// <param name="M11">The value to assign at row 1 column 1 of the matrix.</param>
    /// <param name="M12">The value to assign at row 1 column 2 of the matrix.</param>
    /// <param name="M13">The value to assign at row 1 column 3 of the matrix.</param>
    /// <param name="M14">The value to assign at row 1 column 4 of the matrix.</param>
    /// <param name="M21">The value to assign at row 2 column 1 of the matrix.</param>
    /// <param name="M22">The value to assign at row 2 column 2 of the matrix.</param>
    /// <param name="M23">The value to assign at row 2 column 3 of the matrix.</param>
    /// <param name="M24">The value to assign at row 2 column 4 of the matrix.</param>
    /// <param name="M31">The value to assign at row 3 column 1 of the matrix.</param>
    /// <param name="M32">The value to assign at row 3 column 2 of the matrix.</param>
    /// <param name="M33">The value to assign at row 3 column 3 of the matrix.</param>
    /// <param name="M34">The value to assign at row 3 column 4 of the matrix.</param>
    /// <param name="M41">The value to assign at row 4 column 1 of the matrix.</param>
    /// <param name="M42">The value to assign at row 4 column 2 of the matrix.</param>
    /// <param name="M43">The value to assign at row 4 column 3 of the matrix.</param>
    /// <param name="M44">The value to assign at row 4 column 4 of the matrix.</param>
    public this(float M11, float M12, float M13, float M14,
        float M21, float M22, float M23, float M24,
        float M31, float M32, float M33, float M34,
        float M41, float M42, float M43, float M44)
    {
        this.M11 = M11; this.M12 = M12; this.M13 = M13; this.M14 = M14;
        this.M21 = M21; this.M22 = M22; this.M23 = M23; this.M24 = M24;
        this.M31 = M31; this.M32 = M32; this.M33 = M33; this.M34 = M34;
        this.M41 = M41; this.M42 = M42; this.M43 = M43; this.M44 = M44;
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="Matrix"/> struct.
    /// </summary>
    /// <param name="values">The values to assign to the components of the matrix. This must be an array with sixteen elements.</param>
    /// <exception cref="ArgumentNullException">Thrown when <paramref name="values"/> is <c>null</c>.</exception>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when <paramref name="values"/> contains more or less than sixteen elements.</exception>
    public this(float[] values)
    {
		if(values == null) Runtime.FatalError(scope $"ArgumentNullException - {nameof(values)}");
		if(values.Count != 16) Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(values)}");

        M11 = values[0];
        M12 = values[1];
        M13 = values[2];
        M14 = values[3];

        M21 = values[4];
        M22 = values[5];
        M23 = values[6];
        M24 = values[7];

        M31 = values[8];
        M32 = values[9];
        M33 = values[10];
        M34 = values[11];

        M41 = values[12];
        M42 = values[13];
        M43 = values[14];
        M44 = values[15];
    }

    /// <summary>
    /// Gets or sets the first row in the matrix; that is M11, M12, M13, and M14.
    /// </summary>
    public Vector4 Row1
    {
        get { return Vector4(M11, M12, M13, M14); }
        set mut { M11 = value.X; M12 = value.Y; M13 = value.Z; M14 = value.W; }
    }

    /// <summary>
    /// Gets or sets the second row in the matrix; that is M21, M22, M23, and M24.
    /// </summary>
    public Vector4 Row2
    {
        get { return Vector4(M21, M22, M23, M24); }
        set mut { M21 = value.X; M22 = value.Y; M23 = value.Z; M24 = value.W; }
    }

    /// <summary>
    /// Gets or sets the third row in the matrix; that is M31, M32, M33, and M34.
    /// </summary>
    public Vector4 Row3
    {
        get { return Vector4(M31, M32, M33, M34); }
        set mut { M31 = value.X; M32 = value.Y; M33 = value.Z; M34 = value.W; }
    }

    /// <summary>
    /// Gets or sets the fourth row in the matrix; that is M41, M42, M43, and M44.
    /// </summary>
    public Vector4 Row4
    {
        get { return Vector4(M41, M42, M43, M44); }
        set mut { M41 = value.X; M42 = value.Y; M43 = value.Z; M44 = value.W; }
    }

    /// <summary>
    /// Gets or sets the first column in the matrix; that is M11, M21, M31, and M41.
    /// </summary>
    public Vector4 Column1
    {
        get { return Vector4(M11, M21, M31, M41); }
        set mut { M11 = value.X; M21 = value.Y; M31 = value.Z; M41 = value.W; }
    }

    /// <summary>
    /// Gets or sets the second column in the matrix; that is M12, M22, M32, and M42.
    /// </summary>
    public Vector4 Column2
    {
        get { return Vector4(M12, M22, M32, M42); }
        set mut { M12 = value.X; M22 = value.Y; M32 = value.Z; M42 = value.W; }
    }

    /// <summary>
    /// Gets or sets the third column in the matrix; that is M13, M23, M33, and M43.
    /// </summary>
    public Vector4 Column3
    {
        get { return Vector4(M13, M23, M33, M43); }
        set mut { M13 = value.X; M23 = value.Y; M33 = value.Z; M43 = value.W; }
    }

    /// <summary>
    /// Gets or sets the fourth column in the matrix; that is M14, M24, M34, and M44.
    /// </summary>
    public Vector4 Column4
    {
        get { return Vector4(M14, M24, M34, M44); }
        set mut { M14 = value.X; M24 = value.Y; M34 = value.Z; M44 = value.W; }
    }

    /// <summary>
    /// Gets or sets the translation of the matrix; that is M41, M42, and M43.
    /// </summary>
    public Vector3 TranslationVector
    {
        get { return Vector3(M41, M42, M43); }
        set mut { M41 = value.X; M42 = value.Y; M43 = value.Z; }
    }

    /// <summary>
    /// Gets or sets the scale of the matrix; that is M11, M22, and M33.
    /// </summary>
    /// <remarks>This property does not do any computation and will return a correct scale vector only if the matrix is a scale matrix.</remarks>
    public Vector3 ScaleVector
    {
        get { return Vector3(M11, M22, M33); }
        set mut { M11 = value.X; M22 = value.Y; M33 = value.Z; }
    }

    /// <summary>
    /// Gets or sets the up <see cref="Vector3"/> of the matrix; that is M21, M22, and M23.
    /// </summary>
    public Vector3 Up
    {
        get { return Vector3(M21, M22, M23); }
        set mut { M21 = value.X; M22 = value.Y; M23 = value.Z; }
    }

    /// <summary>
    /// Gets or sets the down <see cref="Vector3"/> of the matrix; that is -M21, -M22, and -M23.
    /// </summary>
    public Vector3 Down
    {
        get { return Vector3(-M21, -M22, -M23); }
        set mut { M21 = -value.X; M22 = -value.Y; M23 = -value.Z; }
    }

    /// <summary>
    /// Gets or sets the right <see cref="Vector3"/> of the matrix; that is M11, M12, and M13.
    /// </summary>
    public Vector3 Right
    {
        get { return Vector3(M11, M12, M13); }
        set mut { M11 = value.X; M12 = value.Y; M13 = value.Z; }
    }

    /// <summary>
    /// Gets or sets the left <see cref="Vector3"/> of the matrix; that is -M11, -M12, and -M13.
    /// </summary>
    public Vector3 Left
    {
        get { return Vector3(-M11, -M12, -M13); }
        set mut { M11 = -value.X; M12 = -value.Y; M13 = -value.Z; }
    }

    /// <summary>
    /// Gets or sets the forward <see cref="Vector3"/> of the matrix; that is -M31, -M32, and -M33.
    /// </summary>
    public Vector3 Forward
    {
        get { return Vector3(-M31, -M32, -M33); }
        set mut { M31 = -value.X; M32 = -value.Y; M33 = -value.Z; }
    }

    /// <summary>
    /// Gets or sets the backward <see cref="Vector3"/> of the matrix; that is M31, M32, and M33.
    /// </summary>
    public Vector3 Backward
    {
        get { return Vector3(M31, M32, M33); }
        set  mut { M31 = value.X; M32 = value.Y; M33 = value.Z; }
    }

    /// <summary>
    /// Gets a value indicating whether this instance is an identity matrix.
    /// </summary>
    /// <value>
    /// <c>true</c> if this instance is an identity matrix; otherwise, <c>false</c>.
    /// </value>
    public readonly bool IsIdentity
    {
        get { return this.Equals(Identity); }
    }

    /// <summary>
    /// Gets or sets the component at the specified index.
    /// </summary>
    /// <value>The value of the matrix component, depending on the index.</value>
    /// <param name="index">The zero-based index of the component to access.</param>
    /// <returns>The value of the component at the specified index.</returns>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when the <paramref name="index"/> is out of the range [0, 15].</exception>
    public float this[int32 index]
    {
        get
        {
			switch (index)
			{
			    case 0: return M11;
			    case 1: return M12;
			    case 2: return M13;
			    case 3: return M14;
			    case 4: return M21;
			    case 5: return M22;
			    case 6: return M23;
			    case 7: return M24;
			    case 8: return M31;
			    case 9: return M32;
			    case 10: return M33;
			    case 11: return M34;
			    case 12: return M41;
			    case 13: return M42;
			    case 14: return M43;
			    case 15: return M44;
			    default:
			        Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(index)}: Indices for Matrix run from 0 to 15, inclusive.");
			}
        }

        set mut
        {
            switch (index)
            {
                case 0: M11 = value; break;
                case 1: M12 = value; break;
                case 2: M13 = value; break;
                case 3: M14 = value; break;
                case 4: M21 = value; break;
                case 5: M22 = value; break;
                case 6: M23 = value; break;
                case 7: M24 = value; break;
                case 8: M31 = value; break;
                case 9: M32 = value; break;
                case 10: M33 = value; break;
                case 11: M34 = value; break;
                case 12: M41 = value; break;
                case 13: M42 = value; break;
                case 14: M43 = value; break;
                case 15: M44 = value; break;
                default: Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(index)}: Indices for Matrix run from 0 to 15, inclusive.");
            }
        }
    }

    /// <summary>
    /// Gets or sets the component at the specified index.
    /// </summary>
    /// <value>The value of the matrix component, depending on the index.</value>
    /// <param name="row">The row of the matrix to access.</param>
    /// <param name="column">The column of the matrix to access.</param>
    /// <returns>The value of the component at the specified index.</returns>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when the <paramref name="row"/> or <paramref name="column"/>is out of the range [0, 3].</exception>
    public float this[int32 row, int32 column]
    {
        get
        {
			if(row < 0 || row > 3)
				Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(row)}");
			if(column < 0 || column > 3)
				Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(column)}");

            return this[(row * 4) + column];
        }

        set mut
        {
			if(row < 0 || row > 3)
				Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(row)}");
			if(column < 0 || column > 3)
				Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(column)}");

            this[(row * 4) + column] = value;
        }
    }

    /// <summary>
    /// Calculates the determinant of the matrix.
    /// </summary>
    /// <returns>The determinant of the matrix.</returns>
    public float Determinant()
    {
        float temp1 = (M33 * M44) - (M34 * M43);
        float temp2 = (M32 * M44) - (M34 * M42);
        float temp3 = (M32 * M43) - (M33 * M42);
        float temp4 = (M31 * M44) - (M34 * M41);
        float temp5 = (M31 * M43) - (M33 * M41);
        float temp6 = (M31 * M42) - (M32 * M41);

        return (M11 * ((M22 * temp1) - (M23 * temp2) + (M24 * temp3)))
            - (M12 * ((M21 * temp1) - (M23 * temp4) + (M24 * temp5)))
            + (M13 * ((M21 * temp2) - (M22 * temp4) + (M24 * temp6)))
            - (M14 * ((M21 * temp3) - (M22 * temp5) + (M23 * temp6)));
    }

    /// <summary>
    /// Inverts the matrix.
    /// If the matrix cannot be inverted (eg. Determinant was zero), then the matrix will be set equivalent to <see cref="Zero"/>.
    /// </summary>
    public void Invert() mut
    {
        Invert(this, out this);
    }

    /// <summary>
    /// Transposes the matrix.
    /// </summary>
    public void Transpose() mut
    {
        (M21, M12) = (M12, M21);
        (M31, M13) = (M13, M31);
        (M41, M14) = (M14, M41);

        (M32, M23) = (M23, M32);
        (M42, M24) = (M24, M42);

        (M43, M34) = (M34, M43);
    }

    /// <summary>
    /// Orthogonalizes the specified matrix.
    /// </summary>
    /// <remarks>
    /// <para>Orthogonalization is the process of making all rows orthogonal to each other. This
    /// means that any given row in the matrix will be orthogonal to any other given row in the
    /// matrix.</para>
    /// <para>Because this method uses the modified Gram-Schmidt process, the resulting matrix
    /// tends to be numerically unstable. The numeric stability decreases according to the rows
    /// so that the first row is the most stable and the last row is the least stable.</para>
    /// <para>This operation is performed on the rows of the matrix rather than the columns.
    /// If you wish for this operation to be performed on the columns, first transpose the
    /// input and then transpose the output.</para>
    /// </remarks>
    public void Orthogonalize() mut
    {
        Orthogonalize(this, out this);
    }

    /// <summary>
    /// Orthonormalizes the specified matrix.
    /// </summary>
    /// <remarks>
    /// <para>Orthonormalization is the process of making all rows and columns orthogonal to each
    /// other and making all rows and columns of unit length. This means that any given row will
    /// be orthogonal to any other given row and any given column will be orthogonal to any other
    /// given column. Any given row will not be orthogonal to any given column. Every row and every
    /// column will be of unit length.</para>
    /// <para>Because this method uses the modified Gram-Schmidt process, the resulting matrix
    /// tends to be numerically unstable. The numeric stability decreases according to the rows
    /// so that the first row is the most stable and the last row is the least stable.</para>
    /// <para>This operation is performed on the rows of the matrix rather than the columns.
    /// If you wish for this operation to be performed on the columns, first transpose the
    /// input and then transpose the output.</para>
    /// </remarks>
    public void Orthonormalize() mut
    {
        Orthonormalize(this, out this);
    }

    /// <summary>
    /// Decomposes a matrix into an orthonormalized matrix Q and a right triangular matrix R.
    /// </summary>
    /// <param name="Q">When the method completes, contains the orthonormalized matrix of the decomposition.</param>
    /// <param name="R">When the method completes, contains the right triangular matrix of the decomposition.</param>
    public void DecomposeQR(out Matrix Q, out Matrix R)
    {
        Matrix temp = this;
        temp.Transpose();
        Orthonormalize(temp, out Q);
        Q.Transpose();

        R = Matrix
        {
            M11 = Vector4.Dot(Q.Column1, Column1),
            M12 = Vector4.Dot(Q.Column1, Column2),
            M13 = Vector4.Dot(Q.Column1, Column3),
            M14 = Vector4.Dot(Q.Column1, Column4),

            M22 = Vector4.Dot(Q.Column2, Column2),
            M23 = Vector4.Dot(Q.Column2, Column3),
            M24 = Vector4.Dot(Q.Column2, Column4),

            M33 = Vector4.Dot(Q.Column3, Column3),
            M34 = Vector4.Dot(Q.Column3, Column4),

            M44 = Vector4.Dot(Q.Column4, Column4)
        };
    }

    /// <summary>
    /// Decomposes a matrix into a lower triangular matrix L and an orthonormalized matrix Q.
    /// </summary>
    /// <param name="L">When the method completes, contains the lower triangular matrix of the decomposition.</param>
    /// <param name="Q">When the method completes, contains the orthonormalized matrix of the decomposition.</param>
    public void DecomposeLQ(out Matrix L, out Matrix Q)
    {
        Orthonormalize(this, out Q);

        L = Matrix
        {
            M11 = Vector4.Dot(Q.Row1, Row1),

            M21 = Vector4.Dot(Q.Row1, Row2),
            M22 = Vector4.Dot(Q.Row2, Row2),

            M31 = Vector4.Dot(Q.Row1, Row3),
            M32 = Vector4.Dot(Q.Row2, Row3),
            M33 = Vector4.Dot(Q.Row3, Row3),

            M41 = Vector4.Dot(Q.Row1, Row4),
            M42 = Vector4.Dot(Q.Row2, Row4),
            M43 = Vector4.Dot(Q.Row3, Row4),
            M44 = Vector4.Dot(Q.Row4, Row4)
        };
    }

    /// <summary>
    /// Decomposes a rotation matrix with the specified yaw, pitch, roll value (angles in radians).
    /// </summary>
    /// <param name="yaw">The yaw component in radians.</param>
    /// <param name="pitch">The pitch component in radians.</param>
    /// <param name="roll">The roll component in radians.</param>
    /// <remarks>
    /// This rotation matrix can be represented by <b>intrinsic</b> rotations in the order <paramref name="yaw"/>, <paramref name="pitch"/>, then <paramref name="roll"/>.
    /// <br/>
    /// Therefore, the <b>extrinsic</b> rotations to achieve this matrix is the reversed order of operations,
    /// i.e. Matrix.RotationZ(roll) * Matrix.RotationX(pitch) * Matrix.RotationY(yaw)
    /// </remarks>
    public void Decompose(out float yaw, out float pitch, out float roll)
    {
        // Adapted from 'Euler Angle Formulas' by David Eberly - https://www.geometrictools.com/Documentation/EulerAngles.pdf
        // 2.3 Factor as Ry Rx Rz
        // License under CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/)
        //
        // Note the Stride's matrix row/column ordering is swapped, indices starts at one,
        // and the if-statement ordering is written to minimize the number of operations to get to
        // the common case, and made to handle the +/- 1 cases better due to low precision in floats
        if (MathUtil.IsOne(Math.Abs(M32)))
        {
            if (M32 >= 0)
            {
                // Edge case where M32 == +1
                pitch = -MathUtil.PiOverTwo;
                yaw = Math.Atan2(-M21, M11);
                roll = 0;
            }
            else
            {
                // Edge case where M32 == -1
                pitch = MathUtil.PiOverTwo;
                yaw = -Math.Atan2(-M21, M11);
                roll = 0;
            }
        }
        else
        {
            // Common case
            pitch = Math.Asin(-M32);
            yaw = Math.Atan2(M31, M33);
            roll = Math.Atan2(M12, M22);
        }
    }

    /// <summary>
    /// Decomposes a rotation matrix with the specified X, Y and Z euler angles in radians.
    /// Matrix.RotationX(rotation.X) * Matrix.RotationY(rotation.Y) * Matrix.RotationZ(rotation.Z) should represent the same rotation.
    /// </summary>
    /// <param name="rotation">The vector containing the 3 rotations angles to be applied in order.</param>
    public void DecomposeXYZ(out Vector3 rotation)
    {
        // Adapted from 'Euler Angle Formulas' by David Eberly - https://www.geometrictools.com/Documentation/EulerAngles.pdf
        // 2.6 Factor as Rz Ry Rx
        // License under CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/)
        //
        // Note the Stride's matrix row/column ordering is swapped, indices starts at one,
        // and the if-statement ordering is written to minimize the number of operations to get to
        // the common case, and made to handle the +/- 1 cases better due to low precision in floats.
        // The above documentation implies the *extrinsic* rotation order is X-Y-Z,
        // so the *intrinsic* rotation is Z-Y-X which is the formula to use here
        if (MathUtil.IsOne(Math.Abs(M13)))
        {
            if (M13 >= 0)
            {
                // Edge case where M13 == +1
                rotation.Y = -MathUtil.PiOverTwo;
                rotation.Z = Math.Atan2(-M32, M22);
                rotation.X = 0;
            }
            else
            {
                // Edge case where M13 == -1
                rotation.Y = MathUtil.PiOverTwo;
                rotation.Z = -Math.Atan2(-M32, M22);
                rotation.X = 0;
            }
        }
        else
        {
            // Common case
            rotation.Y = Math.Asin(-M13);
            rotation.Z = Math.Atan2(M12, M11);
            rotation.X = Math.Atan2(M23, M33);
        }
    }

    /// <summary>
    /// Decomposes a matrix into a scale, rotation, and translation.
    /// </summary>
    /// <param name="scale">When the method completes, contains the scaling component of the decomposed matrix.</param>
    /// <param name="translation">When the method completes, contains the translation component of the decomposed matrix.</param>
    /// <returns><c>true</c> if a rotation exist for this matrix, <c>false</c> otherwise.</returns>
    /// <remarks>This method is designed to decompose an SRT transformation matrix only.</remarks>
    public bool Decompose(out Vector3 scale, out Vector3 translation)
    {
        //Source: Unknown
        //References: http://www.gamedev.net/community/forums/topic.asp?topic_id=441695

        //Get the translation.
        translation.X = this.M41;
        translation.Y = this.M42;
        translation.Z = this.M43;

        //Scaling is the length of the rows.
        scale.X = Math.Sqrt((M11 * M11) + (M12 * M12) + (M13 * M13));
        scale.Y = Math.Sqrt((M21 * M21) + (M22 * M22) + (M23 * M23));
        scale.Z = Math.Sqrt((M31 * M31) + (M32 * M32) + (M33 * M33));

        //If any of the scaling factors are zero, than the rotation matrix can not exist.
        return Math.Abs(scale.X) >= MathUtil.ZeroTolerance &&
            Math.Abs(scale.Y) >= MathUtil.ZeroTolerance &&
            Math.Abs(scale.Z) >= MathUtil.ZeroTolerance;
    }

    /// <summary>
    /// Decomposes a matrix into a scale, rotation, and translation.
    /// </summary>
    /// <param name="scale">When the method completes, contains the scaling component of the decomposed matrix.</param>
    /// <param name="rotation">When the method completes, contains the rotation component of the decomposed matrix.</param>
    /// <param name="translation">When the method completes, contains the translation component of the decomposed matrix.</param>
    /// <remarks>
    /// This method is designed to decompose an SRT transformation matrix only.
    /// </remarks>
    public bool Decompose(out Vector3 scale, out Quaternion rotation, out Vector3 translation)
    {
		Matrix rotationMatrix = default;
        Decompose(out scale, out rotationMatrix, out translation);
        Quaternion.RotationMatrix(rotationMatrix, out rotation);
        return true;
    }

    /// <summary>
    /// Decomposes a matrix into a scale, rotation, and translation.
    /// </summary>
    /// <param name="scale">When the method completes, contains the scaling component of the decomposed matrix.</param>
    /// <param name="rotation">When the method completes, contains the rotation component of the decomposed matrix.</param>
    /// <param name="translation">When the method completes, contains the translation component of the decomposed matrix.</param>
    /// <remarks>
    /// This method is designed to decompose an SRT transformation matrix only.
    /// </remarks>
    public bool Decompose(out Vector3 scale, out Matrix rotation, out Vector3 translation)
    {
        //Source: Unknown
        //References: http://www.gamedev.net/community/forums/topic.asp?topic_id=441695

        //Get the translation.
        translation.X = this.M41;
        translation.Y = this.M42;
        translation.Z = this.M43;

        //Scaling is the length of the rows.
        scale.X = Math.Sqrt((M11 * M11) + (M12 * M12) + (M13 * M13));
        scale.Y = Math.Sqrt((M21 * M21) + (M22 * M22) + (M23 * M23));
        scale.Z = Math.Sqrt((M31 * M31) + (M32 * M32) + (M33 * M33));

        //If any of the scaling factors are zero, then the rotation matrix can not exist.
        if (Math.Abs(scale.X) < MathUtil.ZeroTolerance ||
            Math.Abs(scale.Y) < MathUtil.ZeroTolerance ||
            Math.Abs(scale.Z) < MathUtil.ZeroTolerance)
        {
            rotation = Identity;
            return false;
        }

        // Calculate a perfect orthonormal matrix (no reflections)
        var at = Vector3(M31 / scale.Z, M32 / scale.Z, M33 / scale.Z);
        var up = Vector3.Cross(at, Vector3(M11 / scale.X, M12 / scale.X, M13 / scale.X));
        var right = Vector3.Cross(up, at);

        rotation = Identity;
        rotation.Right = right;
        rotation.Up = up;
        rotation.Backward = at;

        // In case of reflexions
        scale.X = Vector3.Dot(right, Right) > 0.0f ? scale.X : -scale.X;
        scale.Y = Vector3.Dot(up, Up) > 0.0f ? scale.Y : -scale.Y;
        scale.Z = Vector3.Dot(at, Backward) > 0.0f ? scale.Z : -scale.Z;

        return true;
    }

    /// <summary>
    /// Exchanges two rows in the matrix.
    /// </summary>
    /// <param name="firstRow">The first row to exchange. This is an index of the row starting at zero.</param>
    /// <param name="secondRow">The second row to exchange. This is an index of the row starting at zero.</param>
    public void ExchangeRows(int32 firstRow, int32 secondRow) mut
    {
			if(firstRow < 0 || firstRow > 3)
				Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(firstRow)}");
			if(secondRow < 0 || secondRow > 3)
				Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(secondRow)}");

        if (firstRow == secondRow)
            return;

        float temp0 = this[secondRow, 0];
        float temp1 = this[secondRow, 1];
        float temp2 = this[secondRow, 2];
        float temp3 = this[secondRow, 3];

        this[secondRow, 0] = this[firstRow, 0];
        this[secondRow, 1] = this[firstRow, 1];
        this[secondRow, 2] = this[firstRow, 2];
        this[secondRow, 3] = this[firstRow, 3];

        this[firstRow, 0] = temp0;
        this[firstRow, 1] = temp1;
        this[firstRow, 2] = temp2;
        this[firstRow, 3] = temp3;
    }

    /// <summary>
    /// Exchange columns.
    /// </summary>
    /// <param name="firstColumn">The first column to exchange.</param>
    /// <param name="secondColumn">The second column to exchange.</param>
    public void ExchangeColumns(int32 firstColumn, int32 secondColumn) mut
    {
		if(firstColumn < 0 || firstColumn > 3)
			Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(firstColumn)}");
		if(secondColumn < 0 || secondColumn > 3)
			Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(secondColumn)}");

        if (firstColumn == secondColumn)
            return;

        float temp0 = this[0, secondColumn];
        float temp1 = this[1, secondColumn];
        float temp2 = this[2, secondColumn];
        float temp3 = this[3, secondColumn];

        this[0, secondColumn] = this[0, firstColumn];
        this[1, secondColumn] = this[1, firstColumn];
        this[2, secondColumn] = this[2, firstColumn];
        this[3, secondColumn] = this[3, firstColumn];

        this[0, firstColumn] = temp0;
        this[1, firstColumn] = temp1;
        this[2, firstColumn] = temp2;
        this[3, firstColumn] = temp3;
    }

    /// <summary>
    /// Creates an array containing the elements of the matrix.
    /// </summary>
    /// <returns>A sixteen-element array containing the components of the matrix.</returns>
    public float[16] ToArray()
    {
        return .(M11, M12, M13, M14, M21, M22, M23, M24, M31, M32, M33, M34, M41, M42, M43, M44);
    }

    /// <summary>
    /// Determines the sum of two matrices.
    /// </summary>
    /// <param name="left">The first matrix to add.</param>
    /// <param name="right">The second matrix to add.</param>
    /// <param name="result">When the method completes, contains the sum of the two matrices.</param>
    public static void Add(Matrix left, Matrix right, out Matrix result)
    {
        result.M11 = left.M11 + right.M11;
        result.M21 = left.M21 + right.M21;
        result.M31 = left.M31 + right.M31;
        result.M41 = left.M41 + right.M41;
        result.M12 = left.M12 + right.M12;
        result.M22 = left.M22 + right.M22;
        result.M32 = left.M32 + right.M32;
        result.M42 = left.M42 + right.M42;
        result.M13 = left.M13 + right.M13;
        result.M23 = left.M23 + right.M23;
        result.M33 = left.M33 + right.M33;
        result.M43 = left.M43 + right.M43;
        result.M14 = left.M14 + right.M14;
        result.M24 = left.M24 + right.M24;
        result.M34 = left.M34 + right.M34;
        result.M44 = left.M44 + right.M44;
    }

    /// <summary>
    /// Determines the sum of two matrices.
    /// </summary>
    /// <param name="left">The first matrix to add.</param>
    /// <param name="right">The second matrix to add.</param>
    /// <returns>The sum of the two matrices.</returns>
    public static Matrix Add(Matrix left, Matrix right)
    {
        Add(left, right, var result);
        return result;
    }

    /// <summary>
    /// Determines the difference between two matrices.
    /// </summary>
    /// <param name="left">The first matrix to subtract.</param>
    /// <param name="right">The second matrix to subtract.</param>
    /// <param name="result">When the method completes, contains the difference between the two matrices.</param>
    public static void Subtract(Matrix left, Matrix right, out Matrix result)
    {
        result.M11 = left.M11 - right.M11;
        result.M21 = left.M21 - right.M21;
        result.M31 = left.M31 - right.M31;
        result.M41 = left.M41 - right.M41;
        result.M12 = left.M12 - right.M12;
        result.M22 = left.M22 - right.M22;
        result.M32 = left.M32 - right.M32;
        result.M42 = left.M42 - right.M42;
        result.M13 = left.M13 - right.M13;
        result.M23 = left.M23 - right.M23;
        result.M33 = left.M33 - right.M33;
        result.M43 = left.M43 - right.M43;
        result.M14 = left.M14 - right.M14;
        result.M24 = left.M24 - right.M24;
        result.M34 = left.M34 - right.M34;
        result.M44 = left.M44 - right.M44;
    }

    /// <summary>
    /// Determines the difference between two matrices.
    /// </summary>
    /// <param name="left">The first matrix to subtract.</param>
    /// <param name="right">The second matrix to subtract.</param>
    /// <returns>The difference between the two matrices.</returns>
    public static Matrix Subtract(Matrix left, Matrix right)
    {
        Subtract(left, right, var result);
        return result;
    }

    /// <summary>
    /// Scales a matrix by the given value.
    /// </summary>
    /// <param name="left">The matrix to scale.</param>
    /// <param name="right">The amount by which to scale.</param>
    /// <param name="result">When the method completes, contains the scaled matrix.</param>
    public static void Multiply(Matrix left, float right, out Matrix result)
    {
        result.M11 = left.M11 * right;
        result.M21 = left.M21 * right;
        result.M31 = left.M31 * right;
        result.M41 = left.M41 * right;
        result.M12 = left.M12 * right;
        result.M22 = left.M22 * right;
        result.M32 = left.M32 * right;
        result.M42 = left.M42 * right;
        result.M13 = left.M13 * right;
        result.M23 = left.M23 * right;
        result.M33 = left.M33 * right;
        result.M43 = left.M43 * right;
        result.M14 = left.M14 * right;
        result.M24 = left.M24 * right;
        result.M34 = left.M34 * right;
        result.M44 = left.M44 * right;
    }

    /// <summary>
    /// Scales a matrix by the given value.
    /// </summary>
    /// <param name="left">The matrix to scale.</param>
    /// <param name="right">The amount by which to scale.</param>
    /// <returns>The scaled matrix.</returns>
    public static Matrix Multiply(Matrix left, float right)
    {
        Multiply(left, right, var result);
        return result;
    }

    /// <summary>
    /// Determines the product of two matrices.
    /// Variables passed as <paramref name="left"/> or <paramref name="right"/> must not be used as the out parameter
    /// <paramref name="result"/>, because <paramref name="result"/> is calculated in-place.
    /// </summary>
    /// <param name="left">The first matrix to multiply.</param>
    /// <param name="right">The second matrix to multiply.</param>
    /// <param name="result">The product of the two matrices.</param>
    public static void Multiply(Matrix left, Matrix right, out Matrix result)
    {
        result = LayoutIsRowMajor
		    ? MultiplyRowMajor(left, right)
		    : MultiplyRowMajor(right, left);
    }

    /// <summary>
    /// Determines the product of two matrices.
    /// Variables passed as <paramref name="left"/> or <paramref name="right"/> must not be used as the out parameter
    /// <paramref name="result"/>, because <paramref name="result"/> is calculated in-place.
    /// </summary>
    /// <param name="left">The first matrix to multiply.</param>
    /// <param name="right">The second matrix to multiply.</param>
    /// <param name="result">The product of the two matrices.</param>
    public static void MultiplyIn(in Matrix left, in Matrix right, out Matrix result)
    {
        result = LayoutIsRowMajor
		    ? MultiplyRowMajor(left, right)
		    : MultiplyRowMajor(right, left);
    }

    /// <summary>
    /// Determines the product of two matrices, equivalent to the '*' operator.
    /// </summary>
    /// <param name="left">The first matrix to multiply.</param>
    /// <param name="right">The second matrix to multiply.</param>
    /// <returns>The product of the two matrices.</returns>
    public static Matrix Multiply(in Matrix left, in Matrix right) => left * right;

    /// <summary>
    /// Scales a matrix by the given value.
    /// </summary>
    /// <param name="left">The matrix to scale.</param>
    /// <param name="right">The amount by which to scale.</param>
    /// <param name="result">When the method completes, contains the scaled matrix.</param>
    public static void Divide(Matrix left, float right, out Matrix result)
    {
        float inv = 1.0f / right;

        result.M11 = left.M11 * inv;
        result.M21 = left.M21 * inv;
        result.M31 = left.M31 * inv;
        result.M41 = left.M41 * inv;
        result.M12 = left.M12 * inv;
        result.M22 = left.M22 * inv;
        result.M32 = left.M32 * inv;
        result.M42 = left.M42 * inv;
        result.M13 = left.M13 * inv;
        result.M23 = left.M23 * inv;
        result.M33 = left.M33 * inv;
        result.M43 = left.M43 * inv;
        result.M14 = left.M14 * inv;
        result.M24 = left.M24 * inv;
        result.M34 = left.M34 * inv;
        result.M44 = left.M44 * inv;
    }

    /// <summary>
    /// Scales a matrix by the given value.
    /// </summary>
    /// <param name="left">The matrix to scale.</param>
    /// <param name="right">The amount by which to scale.</param>
    /// <returns>The scaled matrix.</returns>
    public static Matrix Divide(Matrix left, float right)
    {
        Divide(left, right, var result);
        return result;
    }

    /// <summary>
    /// Determines the quotient of two matrices.
    /// </summary>
    /// <param name="left">The first matrix to divide.</param>
    /// <param name="right">The second matrix to divide.</param>
    /// <param name="result">When the method completes, contains the quotient of the two matrices.</param>
    public static void Divide(Matrix left, Matrix right, out Matrix result)
    {
        result.M11 = left.M11 / right.M11;
        result.M21 = left.M21 / right.M21;
        result.M31 = left.M31 / right.M31;
        result.M41 = left.M41 / right.M41;
        result.M12 = left.M12 / right.M12;
        result.M22 = left.M22 / right.M22;
        result.M32 = left.M32 / right.M32;
        result.M42 = left.M42 / right.M42;
        result.M13 = left.M13 / right.M13;
        result.M23 = left.M23 / right.M23;
        result.M33 = left.M33 / right.M33;
        result.M43 = left.M43 / right.M43;
        result.M14 = left.M14 / right.M14;
        result.M24 = left.M24 / right.M24;
        result.M34 = left.M34 / right.M34;
        result.M44 = left.M44 / right.M44;
    }

    /// <summary>
    /// Determines the quotient of two matrices.
    /// </summary>
    /// <param name="left">The first matrix to divide.</param>
    /// <param name="right">The second matrix to divide.</param>
    /// <returns>The quotient of the two matrices.</returns>
    public static Matrix Divide(Matrix left, Matrix right)
    {
        Divide(left, right, var result);
        return result;
    }

    /// <summary>
    /// Performs the exponential operation on a matrix.
    /// </summary>
    /// <param name="value">The matrix to perform the operation on.</param>
    /// <param name="exponent">The exponent to raise the matrix to.</param>
    /// <param name="result">When the method completes, contains the exponential matrix.</param>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when the <paramref name="exponent"/> is negative.</exception>
    public static void Exponent(Matrix value, int32 exponent, out Matrix result)
    {
		var exponent;
        //Source: http://rosettacode.org
        //Refrence: http://rosettacode.org/wiki/Matrix-exponentiation_operator

		if(exponent < 0)
			Runtime.FatalError(scope $"ArgumentOutOfRangeException - {nameof(exponent)}");

        if (exponent == 0)
        {
            result = Identity;
            return;
        }

        if (exponent == 1)
        {
            result = value;
            return;
        }

        Matrix identity = Identity;
        Matrix temp = value;

        while (true)
        {
            if ((exponent & 1) != 0)
                identity *= temp;

            exponent /= 2;

            if (exponent > 0)
                temp *= temp;
            else
                break;
        }

        result = identity;
    }

    /// <summary>
    /// Performs the exponential operation on a matrix.
    /// </summary>
    /// <param name="value">The matrix to perform the operation on.</param>
    /// <param name="exponent">The exponent to raise the matrix to.</param>
    /// <returns>The exponential matrix.</returns>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when the <paramref name="exponent"/> is negative.</exception>
    public static Matrix Exponent(Matrix value, int32 exponent)
    {
        Exponent(value, exponent, var result);
        return result;
    }

    /// <summary>
    /// Negates a matrix.
    /// </summary>
    /// <param name="value">The matrix to be negated.</param>
    /// <param name="result">When the method completes, contains the negated matrix.</param>
    public static void Negate(Matrix value, out Matrix result)
    {
        result.M11 = -value.M11;
        result.M21 = -value.M21;
        result.M31 = -value.M31;
        result.M41 = -value.M41;
        result.M12 = -value.M12;
        result.M22 = -value.M22;
        result.M32 = -value.M32;
        result.M42 = -value.M42;
        result.M13 = -value.M13;
        result.M23 = -value.M23;
        result.M33 = -value.M33;
        result.M43 = -value.M43;
        result.M14 = -value.M14;
        result.M24 = -value.M24;
        result.M34 = -value.M34;
        result.M44 = -value.M44;
    }

    /// <summary>
    /// Negates a matrix.
    /// </summary>
    /// <param name="value">The matrix to be negated.</param>
    /// <returns>The negated matrix.</returns>
    public static Matrix Negate(Matrix value)
    {
        Negate(value, var result);
        return result;
    }

    /// <summary>
    /// Performs a linear interpolation between two matrices.
    /// </summary>
    /// <param name="start">Start matrix.</param>
    /// <param name="end">End matrix.</param>
    /// <param name="amount">Value between 0 and 1 indicating the weight of <paramref name="end"/>.</param>
    /// <param name="result">When the method completes, contains the linear interpolation of the two matrices.</param>
    /// <remarks>
    /// This method performs the linear interpolation based on the following formula.
    /// <c>start + (end - start) * amount</c>
    /// Passing <paramref name="amount"/> a value of 0 will cause <paramref name="start"/> to be returned; a value of 1 will cause <paramref name="end"/> to be returned.
    /// </remarks>
    public static void Lerp(Matrix start, Matrix end, float amount, out Matrix result)
    {
        result.M11 = start.M11 + ((end.M11 - start.M11) * amount);
        result.M21 = start.M21 + ((end.M21 - start.M21) * amount);
        result.M31 = start.M31 + ((end.M31 - start.M31) * amount);
        result.M41 = start.M41 + ((end.M41 - start.M41) * amount);
        result.M12 = start.M12 + ((end.M12 - start.M12) * amount);
        result.M22 = start.M22 + ((end.M22 - start.M22) * amount);
        result.M32 = start.M32 + ((end.M32 - start.M32) * amount);
        result.M42 = start.M42 + ((end.M42 - start.M42) * amount);
        result.M13 = start.M13 + ((end.M13 - start.M13) * amount);
        result.M23 = start.M23 + ((end.M23 - start.M23) * amount);
        result.M33 = start.M33 + ((end.M33 - start.M33) * amount);
        result.M43 = start.M43 + ((end.M43 - start.M43) * amount);
        result.M14 = start.M14 + ((end.M14 - start.M14) * amount);
        result.M24 = start.M24 + ((end.M24 - start.M24) * amount);
        result.M34 = start.M34 + ((end.M34 - start.M34) * amount);
        result.M44 = start.M44 + ((end.M44 - start.M44) * amount);
    }

    /// <summary>
    /// Performs a linear interpolation between two matrices.
    /// </summary>
    /// <param name="start">Start matrix.</param>
    /// <param name="end">End matrix.</param>
    /// <param name="amount">Value between 0 and 1 indicating the weight of <paramref name="end"/>.</param>
    /// <returns>The linear interpolation of the two matrices.</returns>
    /// <remarks>
    /// This method performs the linear interpolation based on the following formula.
    /// <c>start + (end - start) * amount</c>
    /// Passing <paramref name="amount"/> a value of 0 will cause <paramref name="start"/> to be returned; a value of 1 will cause <paramref name="end"/> to be returned.
    /// </remarks>
    public static Matrix Lerp(Matrix start, Matrix end, float amount)
    {
        Lerp(start, end, amount, var result);
        return result;
    }

    /// <summary>
    /// Performs a cubic interpolation between two matrices.
    /// </summary>
    /// <param name="start">Start matrix.</param>
    /// <param name="end">End matrix.</param>
    /// <param name="amount">Value between 0 and 1 indicating the weight of <paramref name="end"/>.</param>
    /// <param name="result">When the method completes, contains the cubic interpolation of the two matrices.</param>
    public static void SmoothStep(Matrix start, Matrix end, float amount, out Matrix result)
    {
		var amount;
        amount = (amount > 1.0f) ? 1.0f : ((amount < 0.0f) ? 0.0f : amount);
        amount = amount * amount * (3.0f - (2.0f * amount));

        result.M11 = start.M11 + ((end.M11 - start.M11) * amount);
        result.M21 = start.M21 + ((end.M21 - start.M21) * amount);
        result.M31 = start.M31 + ((end.M31 - start.M31) * amount);
        result.M41 = start.M41 + ((end.M41 - start.M41) * amount);
        result.M12 = start.M12 + ((end.M12 - start.M12) * amount);
        result.M22 = start.M22 + ((end.M22 - start.M22) * amount);
        result.M32 = start.M32 + ((end.M32 - start.M32) * amount);
        result.M42 = start.M42 + ((end.M42 - start.M42) * amount);
        result.M13 = start.M13 + ((end.M13 - start.M13) * amount);
        result.M23 = start.M23 + ((end.M23 - start.M23) * amount);
        result.M33 = start.M33 + ((end.M33 - start.M33) * amount);
        result.M43 = start.M43 + ((end.M43 - start.M43) * amount);
        result.M14 = start.M14 + ((end.M14 - start.M14) * amount);
        result.M24 = start.M24 + ((end.M24 - start.M24) * amount);
        result.M34 = start.M34 + ((end.M34 - start.M34) * amount);
        result.M44 = start.M44 + ((end.M44 - start.M44) * amount);
    }

    /// <summary>
    /// Performs a cubic interpolation between two matrices.
    /// </summary>
    /// <param name="start">Start matrix.</param>
    /// <param name="end">End matrix.</param>
    /// <param name="amount">Value between 0 and 1 indicating the weight of <paramref name="end"/>.</param>
    /// <returns>The cubic interpolation of the two matrices.</returns>
    public static Matrix SmoothStep(Matrix start, Matrix end, float amount)
    {
        SmoothStep(start, end, amount, var result);
        return result;
    }

    /// <summary>
    /// Calculates the transpose of the specified matrix.
    /// </summary>
    /// <param name="value">The matrix whose transpose is to be calculated.</param>
    /// <param name="result">When the method completes, contains the transpose of the specified matrix.</param>
    public static void Transpose(Matrix value, out Matrix result)
    {
        result = Matrix(
            value.M11,
            value.M21,
            value.M31,
            value.M41,
            value.M12,
            value.M22,
            value.M32,
            value.M42,
            value.M13,
            value.M23,
            value.M33,
            value.M43,
            value.M14,
            value.M24,
            value.M34,
            value.M44);
    }

    /// <summary>
    /// Calculates the transpose of the specified matrix.
    /// </summary>
    /// <param name="value">The matrix whose transpose is to be calculated.</param>
    /// <returns>The transpose of the specified matrix.</returns>
    public static Matrix Transpose(in Matrix value)
    {
		var value;
        value.Transpose();
        return value;
    }

    /// <summary>
    /// Calculates the inverse of the specified matrix.
    /// If the matrix cannot be inverted (eg. Determinant was zero), then <paramref name="result"/> will be <see cref="Zero"/>.
    /// </summary>
    /// <param name="value">The matrix whose inverse is to be calculated.</param>
    /// <param name="result">When the method completes, contains the inverse of the specified matrix.</param>
	public static void Invert(Matrix value, out Matrix result)
	{
	    float a11 = value.M11, a12 = value.M12, a13 = value.M13, a14 = value.M14;
	    float a21 = value.M21, a22 = value.M22, a23 = value.M23, a24 = value.M24;
	    float a31 = value.M31, a32 = value.M32, a33 = value.M33, a34 = value.M34;
	    float a41 = value.M41, a42 = value.M42, a43 = value.M43, a44 = value.M44;

	    float b00 = a11 * a22 - a12 * a21;
	    float b01 = a11 * a23 - a13 * a21;
	    float b02 = a11 * a24 - a14 * a21;
	    float b03 = a12 * a23 - a13 * a22;
	    float b04 = a12 * a24 - a14 * a22;
	    float b05 = a13 * a24 - a14 * a23;
	    float b06 = a31 * a42 - a32 * a41;
	    float b07 = a31 * a43 - a33 * a41;
	    float b08 = a31 * a44 - a34 * a41;
	    float b09 = a32 * a43 - a33 * a42;
	    float b10 = a32 * a44 - a34 * a42;
	    float b11 = a33 * a44 - a34 * a43;

	    float det =
	        b00 * b11 - b01 * b10 + b02 * b09 +
	        b03 * b08 - b04 * b07 + b05 * b06;

	    if (Math.Abs(det) < float.Epsilon)
	    {
	        result = Zero;
	        return;
	    }

	    float invDet = 1.0f / det;

	    result.M11 = (a22 * b11 - a23 * b10 + a24 * b09) * invDet;
	    result.M12 = (-a12 * b11 + a13 * b10 - a14 * b09) * invDet;
	    result.M13 = (a42 * b05 - a43 * b04 + a44 * b03) * invDet;
	    result.M14 = (-a32 * b05 + a33 * b04 - a34 * b03) * invDet;

	    result.M21 = (-a21 * b11 + a23 * b08 - a24 * b07) * invDet;
	    result.M22 = (a11 * b11 - a13 * b08 + a14 * b07) * invDet;
	    result.M23 = (-a41 * b05 + a43 * b02 - a44 * b01) * invDet;
	    result.M24 = (a31 * b05 - a33 * b02 + a34 * b01) * invDet;

	    result.M31 = (a21 * b10 - a22 * b08 + a24 * b06) * invDet;
	    result.M32 = (-a11 * b10 + a12 * b08 - a14 * b06) * invDet;
	    result.M33 = (a41 * b04 - a42 * b02 + a44 * b00) * invDet;
	    result.M34 = (-a31 * b04 + a32 * b02 - a34 * b00) * invDet;

	    result.M41 = (-a21 * b09 + a22 * b07 - a23 * b06) * invDet;
	    result.M42 = (a11 * b09 - a12 * b07 + a13 * b06) * invDet;
	    result.M43 = (-a41 * b03 + a42 * b01 - a43 * b00) * invDet;
	    result.M44 = (a31 * b03 - a32 * b01 + a33 * b00) * invDet;
	}


    /// <summary>
    /// Calculates the inverse of the specified matrix.
    /// If the matrix cannot be inverted (eg. Determinant was zero), then the returning matrix will be <see cref="Zero"/>.
    /// </summary>
    /// <param name="value">The matrix whose inverse is to be calculated.</param>
    /// <returns>The inverse of the specified matrix.</returns>
    public static Matrix Invert(Matrix value)
    {
		var value;
        value.Invert();
        return value;
    }

    /// <summary>
    /// Orthogonalizes the specified matrix.
    /// </summary>
    /// <param name="value">The matrix to orthogonalize.</param>
    /// <param name="result">When the method completes, contains the orthogonalized matrix.</param>
    /// <remarks>
    /// <para>Orthogonalization is the process of making all rows orthogonal to each other. This
    /// means that any given row in the matrix will be orthogonal to any other given row in the
    /// matrix.</para>
    /// <para>Because this method uses the modified Gram-Schmidt process, the resulting matrix
    /// tends to be numerically unstable. The numeric stability decreases according to the rows
    /// so that the first row is the most stable and the last row is the least stable.</para>
    /// <para>This operation is performed on the rows of the matrix rather than the columns.
    /// If you wish for this operation to be performed on the columns, first transpose the
    /// input and than transpose the output.</para>
    /// </remarks>
    public static void Orthogonalize(Matrix value, out Matrix result)
    {
        //Uses the modified Gram-Schmidt process.
        //q1 = m1
        //q2 = m2 - ((q1 ⋅ m2) / (q1 ⋅ q1)) * q1
        //q3 = m3 - ((q1 ⋅ m3) / (q1 ⋅ q1)) * q1 - ((q2 ⋅ m3) / (q2 ⋅ q2)) * q2
        //q4 = m4 - ((q1 ⋅ m4) / (q1 ⋅ q1)) * q1 - ((q2 ⋅ m4) / (q2 ⋅ q2)) * q2 - ((q3 ⋅ m4) / (q3 ⋅ q3)) * q3

        //By separating the above algorithm into multiple lines, we actually increase accuracy.
        result = value;

        var row1 = result.Row1;
        var row2 = result.Row2;
        var row3 = result.Row3;
        var row4 = result.Row4;

        row2 -= Vector4.Dot(row1, row2) / Vector4.Dot(row1, row1) * row1;

        row3 -= Vector4.Dot(row1, row3) / Vector4.Dot(row1, row1) * row1;
        row3 -= Vector4.Dot(row2, row3) / Vector4.Dot(row2, row2) * row2;

        row4 -= Vector4.Dot(row1, row4) / Vector4.Dot(row1, row1) * row1;
        row4 -= Vector4.Dot(row2, row4) / Vector4.Dot(row2, row2) * row2;
        row4 -= Vector4.Dot(row3, row4) / Vector4.Dot(row3, row3) * row3;

        result.Row2 = row2;
        result.Row3 = row3;
        result.Row4 = row4;
    }

    /// <summary>
    /// Orthogonalizes the specified matrix.
    /// </summary>
    /// <param name="value">The matrix to orthogonalize.</param>
    /// <returns>The orthogonalized matrix.</returns>
    /// <remarks>
    /// <para>Orthogonalization is the process of making all rows orthogonal to each other. This
    /// means that any given row in the matrix will be orthogonal to any other given row in the
    /// matrix.</para>
    /// <para>Because this method uses the modified Gram-Schmidt process, the resulting matrix
    /// tends to be numerically unstable. The numeric stability decreases according to the rows
    /// so that the first row is the most stable and the last row is the least stable.</para>
    /// <para>This operation is performed on the rows of the matrix rather than the columns.
    /// If you wish for this operation to be performed on the columns, first transpose the
    /// input and than transpose the output.</para>
    /// </remarks>
    public static Matrix Orthogonalize(Matrix value)
    {
        Orthogonalize(value, var result);
        return result;
    }

    /// <summary>
    /// Orthonormalizes the specified matrix.
    /// </summary>
    /// <param name="value">The matrix to orthonormalize.</param>
    /// <param name="result">When the method completes, contains the orthonormalized matrix.</param>
    /// <remarks>
    /// <para>Orthonormalization is the process of making all rows and columns orthogonal to each
    /// other and making all rows and columns of unit length. This means that any given row will
    /// be orthogonal to any other given row and any given column will be orthogonal to any other
    /// given column. Any given row will not be orthogonal to any given column. Every row and every
    /// column will be of unit length.</para>
    /// <para>Because this method uses the modified Gram-Schmidt process, the resulting matrix
    /// tends to be numerically unstable. The numeric stability decreases according to the rows
    /// so that the first row is the most stable and the last row is the least stable.</para>
    /// <para>This operation is performed on the rows of the matrix rather than the columns.
    /// If you wish for this operation to be performed on the columns, first transpose the
    /// input and than transpose the output.</para>
    /// </remarks>
    public static void Orthonormalize(Matrix value, out Matrix result)
    {
        //Uses the modified Gram-Schmidt process.
        //Because we are making unit vectors, we can optimize the math for orthogonalization
        //and simplify the projection operation to remove the division.
        //q1 = m1 / |m1|
        //q2 = (m2 - (q1 ⋅ m2) * q1) / |m2 - (q1 ⋅ m2) * q1|
        //q3 = (m3 - (q1 ⋅ m3) * q1 - (q2 ⋅ m3) * q2) / |m3 - (q1 ⋅ m3) * q1 - (q2 ⋅ m3) * q2|
        //q4 = (m4 - (q1 ⋅ m4) * q1 - (q2 ⋅ m4) * q2 - (q3 ⋅ m4) * q3) / |m4 - (q1 ⋅ m4) * q1 - (q2 ⋅ m4) * q2 - (q3 ⋅ m4) * q3|

        //By separating the above algorithm into multiple lines, we actually increase accuracy.
        var row1 = value.Row1;
        var row2 = value.Row2;
        var row3 = value.Row3;
        var row4 = value.Row4;

        row1.Normalize();

        row2 -= Vector4.Dot(row1, row2) * row1;
        row2.Normalize();

        row3 -= Vector4.Dot(row1, row3) * row1;
        row3 -= Vector4.Dot(row2, row3) * row2;
        row3.Normalize();

        row4 -= Vector4.Dot(row1, row4) * row1;
        row4 -= Vector4.Dot(row2, row4) * row2;
        row4 -= Vector4.Dot(row3, row4) * row3;
        row4.Normalize();

        result = default;
        result.Row1 = row1;
        result.Row2 = row2;
        result.Row3 = row3;
        result.Row4 = row4;
    }

    /// <summary>
    /// Orthonormalizes the specified matrix.
    /// </summary>
    /// <param name="value">The matrix to orthonormalize.</param>
    /// <returns>The orthonormalized matrix.</returns>
    /// <remarks>
    /// <para>Orthonormalization is the process of making all rows and columns orthogonal to each
    /// other and making all rows and columns of unit length. This means that any given row will
    /// be orthogonal to any other given row and any given column will be orthogonal to any other
    /// given column. Any given row will not be orthogonal to any given column. Every row and every
    /// column will be of unit length.</para>
    /// <para>Because this method uses the modified Gram-Schmidt process, the resulting matrix
    /// tends to be numerically unstable. The numeric stability decreases according to the rows
    /// so that the first row is the most stable and the last row is the least stable.</para>
    /// <para>This operation is performed on the rows of the matrix rather than the columns.
    /// If you wish for this operation to be performed on the columns, first transpose the
    /// input and than transpose the output.</para>
    /// </remarks>
    public static Matrix Orthonormalize(Matrix value)
    {
        Orthonormalize(value, var result);
        return result;
    }

    /// <summary>
    /// Brings the matrix into upper triangular form using elementry row operations.
    /// </summary>
    /// <param name="value">The matrix to put into upper triangular form.</param>
    /// <param name="result">When the method completes, contains the upper triangular matrix.</param>
    /// <remarks>
    /// If the matrix is not invertable (i.e. its determinant is zero) than the result of this
    /// method may produce Single.Nan and Single.Inf values. When the matrix represents a system
    /// of linear equations, than this often means that either no solution exists or an infinite
    /// number of solutions exist.
    /// </remarks>
    public static void UpperTriangularForm(Matrix value, out Matrix result)
    {
        //Adapted from the row echelon code.
        result = value;
        int32 lead = 0;
        const int32 rowcount = 4;
        const int32 columncount = 4;

        for (int32 r = 0; r < rowcount; ++r)
        {
            if (columncount <= lead)
                return;

            int32 i = r;

            while (Math.Abs(result[i, lead]) < MathUtil.ZeroTolerance)
            {
                i++;

                if (i == rowcount)
                {
                    i = r;
                    lead++;

                    if (lead == columncount)
                        return;
                }
            }

            if (i != r)
            {
                result.ExchangeRows(i, r);
            }

            float multiplier = 1f / result[r, lead];

            for (; i < rowcount; ++i)
            {
                if (i != r)
                {
                    result[i, 0] -= result[r, 0] * multiplier * result[i, lead];
                    result[i, 1] -= result[r, 1] * multiplier * result[i, lead];
                    result[i, 2] -= result[r, 2] * multiplier * result[i, lead];
                    result[i, 3] -= result[r, 3] * multiplier * result[i, lead];
                }
            }

            lead++;
        }
    }

    /// <summary>
    /// Brings the matrix into upper triangular form using elementry row operations.
    /// </summary>
    /// <param name="value">The matrix to put into upper triangular form.</param>
    /// <returns>The upper triangular matrix.</returns>
    /// <remarks>
    /// If the matrix is not invertable (i.e. its determinant is zero) than the result of this
    /// method may produce Single.Nan and Single.Inf values. When the matrix represents a system
    /// of linear equations, than this often means that either no solution exists or an infinite
    /// number of solutions exist.
    /// </remarks>
    public static Matrix UpperTriangularForm(Matrix value)
    {
        UpperTriangularForm(value, var result);
        return result;
    }

    /// <summary>
    /// Brings the matrix into lower triangular form using elementry row operations.
    /// </summary>
    /// <param name="value">The matrix to put into lower triangular form.</param>
    /// <param name="result">When the method completes, contains the lower triangular matrix.</param>
    /// <remarks>
    /// If the matrix is not invertable (i.e. its determinant is zero) than the result of this
    /// method may produce Single.Nan and Single.Inf values. When the matrix represents a system
    /// of linear equations, than this often means that either no solution exists or an infinite
    /// number of solutions exist.
    /// </remarks>
    public static void LowerTriangularForm(Matrix value, out Matrix result)
    {
        //Adapted from the row echelon code.
        Matrix temp = value;
        Transpose(temp, out result);

        int32 lead = 0;
        const int32 rowcount = 4;
        const int32 columncount = 4;

        for (int32 r = 0; r < rowcount; ++r)
        {
            if (columncount <= lead)
                return;

            int32 i = r;

            while (Math.Abs(result[i, lead]) < MathUtil.ZeroTolerance)
            {
                i++;

                if (i == rowcount)
                {
                    i = r;
                    lead++;

                    if (lead == columncount)
                        return;
                }
            }

            if (i != r)
            {
                result.ExchangeRows(i, r);
            }

            float multiplier = 1f / result[r, lead];

            for (; i < rowcount; ++i)
            {
                if (i != r)
                {
                    result[i, 0] -= result[r, 0] * multiplier * result[i, lead];
                    result[i, 1] -= result[r, 1] * multiplier * result[i, lead];
                    result[i, 2] -= result[r, 2] * multiplier * result[i, lead];
                    result[i, 3] -= result[r, 3] * multiplier * result[i, lead];
                }
            }

            lead++;
        }

        Transpose(result, out result);
    }

    /// <summary>
    /// Brings the matrix into lower triangular form using elementry row operations.
    /// </summary>
    /// <param name="value">The matrix to put into lower triangular form.</param>
    /// <returns>The lower triangular matrix.</returns>
    /// <remarks>
    /// If the matrix is not invertable (i.e. its determinant is zero) than the result of this
    /// method may produce Single.Nan and Single.Inf values. When the matrix represents a system
    /// of linear equations, than this often means that either no solution exists or an infinite
    /// number of solutions exist.
    /// </remarks>
    public static Matrix LowerTriangularForm(Matrix value)
    {
        LowerTriangularForm(value, var result);
        return result;
    }

    /// <summary>
    /// Brings the matrix into row echelon form using elementry row operations;
    /// </summary>
    /// <param name="value">The matrix to put into row echelon form.</param>
    /// <param name="result">When the method completes, contains the row echelon form of the matrix.</param>
    public static void RowEchelonForm(Matrix value, out Matrix result)
    {
        //Source: Wikipedia psuedo code
        //Reference: http://en.wikipedia.org/wiki/Row_echelon_form#Pseudocode

        result = value;
        int32 lead = 0;
        const int32 rowcount = 4;
        const int32 columncount = 4;

        for (int32 r = 0; r < rowcount; ++r)
        {
            if (columncount <= lead)
                return;

            int32 i = r;

            while (Math.Abs(result[i, lead]) < MathUtil.ZeroTolerance)
            {
                i++;

                if (i == rowcount)
                {
                    i = r;
                    lead++;

                    if (lead == columncount)
                        return;
                }
            }

            if (i != r)
            {
                result.ExchangeRows(i, r);
            }

            float multiplier = 1f / result[r, lead];
            result[r, 0] *= multiplier;
            result[r, 1] *= multiplier;
            result[r, 2] *= multiplier;
            result[r, 3] *= multiplier;

            for (; i < rowcount; ++i)
            {
                if (i != r)
                {
                    result[i, 0] -= result[r, 0] * result[i, lead];
                    result[i, 1] -= result[r, 1] * result[i, lead];
                    result[i, 2] -= result[r, 2] * result[i, lead];
                    result[i, 3] -= result[r, 3] * result[i, lead];
                }
            }

            lead++;
        }
    }

    /// <summary>
    /// Brings the matrix into row echelon form using elementry row operations;
    /// </summary>
    /// <param name="value">The matrix to put into row echelon form.</param>
    /// <returns>When the method completes, contains the row echelon form of the matrix.</returns>
    public static Matrix RowEchelonForm(Matrix value)
    {
        RowEchelonForm(value, var result);
        return result;
    }

    /// <summary>
    /// Brings the matrix into reduced row echelon form using elementry row operations.
    /// </summary>
    /// <param name="value">The matrix to put into reduced row echelon form.</param>
    /// <param name="augment">The fifth column of the matrix.</param>
    /// <param name="result">When the method completes, contains the resultant matrix after the operation.</param>
    /// <param name="augmentResult">When the method completes, contains the resultant fifth column of the matrix.</param>
    /// <remarks>
    /// <para>The fifth column is often called the agumented part of the matrix. This is because the fifth
    /// column is really just an extension of the matrix so that there is a place to put all of the
    /// non-zero components after the operation is complete.</para>
    /// <para>Often times the resultant matrix will the identity matrix or a matrix similar to the identity
    /// matrix. Sometimes, however, that is not possible and numbers other than zero and one may appear.</para>
    /// <para>This method can be used to solve systems of linear equations. Upon completion of this method,
    /// the <paramref name="augmentResult"/> will contain the solution for the system. It is up to the user
    /// to analyze both the input and the result to determine if a solution really exists.</para>
    /// </remarks>
    public static void ReducedRowEchelonForm(Matrix value, Vector4 augment, out Matrix result, out Vector4 augmentResult)
    {
        //Source: http://rosettacode.org
        //Reference: http://rosettacode.org/wiki/Reduced_row_echelon_form

        float[,] matrix = new float[4, 5];

        matrix[0, 0] = value[0, 0];
        matrix[0, 1] = value[0, 1];
        matrix[0, 2] = value[0, 2];
        matrix[0, 3] = value[0, 3];
        matrix[0, 4] = augment[0];

        matrix[1, 0] = value[1, 0];
        matrix[1, 1] = value[1, 1];
        matrix[1, 2] = value[1, 2];
        matrix[1, 3] = value[1, 3];
        matrix[1, 4] = augment[1];

        matrix[2, 0] = value[2, 0];
        matrix[2, 1] = value[2, 1];
        matrix[2, 2] = value[2, 2];
        matrix[2, 3] = value[2, 3];
        matrix[2, 4] = augment[2];

        matrix[3, 0] = value[3, 0];
        matrix[3, 1] = value[3, 1];
        matrix[3, 2] = value[3, 2];
        matrix[3, 3] = value[3, 3];
        matrix[3, 4] = augment[3];

        int32 lead = 0;
        const int32 rowcount = 4;
        const int32 columncount = 5;

        for (int32 r = 0; r < rowcount; r++)
        {
            if (columncount <= lead)
                break;

            int32 i = r;

            while (matrix[i, lead] == 0)
            {
                i++;

                if (i == rowcount)
                {
                    i = r;
                    lead++;

                    if (columncount == lead)
                        break;
                }
            }

            for (int32 j = 0; j < columncount; j++)
            {
                (matrix[r, j], matrix[i, j]) = (matrix[i, j], matrix[r, j]);
            }

            float div = matrix[r, lead];

            for (int32 j = 0; j < columncount; j++)
            {
                matrix[r, j] /= div;
            }

            for (int32 j = 0; j < rowcount; j++)
            {
                if (j != r)
                {
                    float sub = matrix[j, lead];
                    for (int32 k = 0; k < columncount; k++) matrix[j, k] -= (sub * matrix[r, k]);
                }
            }

            lead++;
        }

        result.M11 = matrix[0, 0];
        result.M12 = matrix[0, 1];
        result.M13 = matrix[0, 2];
        result.M14 = matrix[0, 3];

        result.M21 = matrix[1, 0];
        result.M22 = matrix[1, 1];
        result.M23 = matrix[1, 2];
        result.M24 = matrix[1, 3];

        result.M31 = matrix[2, 0];
        result.M32 = matrix[2, 1];
        result.M33 = matrix[2, 2];
        result.M34 = matrix[2, 3];

        result.M41 = matrix[3, 0];
        result.M42 = matrix[3, 1];
        result.M43 = matrix[3, 2];
        result.M44 = matrix[3, 3];

        augmentResult.X = matrix[0, 4];
        augmentResult.Y = matrix[1, 4];
        augmentResult.Z = matrix[2, 4];
        augmentResult.W = matrix[3, 4];
    }

    /// <summary>
    /// Creates a spherical billboard that rotates around a specified object position.
    /// </summary>
    /// <param name="objectPosition">The position of the object around which the billboard will rotate.</param>
    /// <param name="cameraPosition">The position of the camera.</param>
    /// <param name="cameraUpVector">The up vector of the camera.</param>
    /// <param name="cameraForwardVector">The forward vector of the camera.</param>
    /// <param name="result">When the method completes, contains the created billboard matrix.</param>
    public static void Billboard(Vector3 objectPosition, Vector3 cameraPosition, Vector3 cameraUpVector, Vector3 cameraForwardVector, out Matrix result)
    {
        Vector3 difference = objectPosition - cameraPosition;

        float lengthSq = difference.LengthSquared();
        if (lengthSq < MathUtil.ZeroTolerance)
            difference = -cameraForwardVector;
        else
            difference *= 1.0f / Math.Sqrt(lengthSq);

        Vector3.Cross(cameraUpVector, difference, var crossed);
        crossed.Normalize();
        Vector3.Cross(difference, crossed, var final);

        result.M11 = crossed.X;
        result.M12 = crossed.Y;
        result.M13 = crossed.Z;
        result.M14 = 0.0f;
        result.M21 = final.X;
        result.M22 = final.Y;
        result.M23 = final.Z;
        result.M24 = 0.0f;
        result.M31 = difference.X;
        result.M32 = difference.Y;
        result.M33 = difference.Z;
        result.M34 = 0.0f;
        result.M41 = objectPosition.X;
        result.M42 = objectPosition.Y;
        result.M43 = objectPosition.Z;
        result.M44 = 1.0f;
    }

    /// <summary>
    /// Creates a spherical billboard that rotates around a specified object position.
    /// </summary>
    /// <param name="objectPosition">The position of the object around which the billboard will rotate.</param>
    /// <param name="cameraPosition">The position of the camera.</param>
    /// <param name="cameraUpVector">The up vector of the camera.</param>
    /// <param name="cameraForwardVector">The forward vector of the camera.</param>
    /// <returns>The created billboard matrix.</returns>
    public static Matrix Billboard(Vector3 objectPosition, Vector3 cameraPosition, Vector3 cameraUpVector, Vector3 cameraForwardVector)
    {
        Billboard(objectPosition, cameraPosition, cameraUpVector, cameraForwardVector, var result);
        return result;
    }

    /// <summary>
    /// Creates a left-handed, look-at matrix.
    /// </summary>
    /// <param name="eye">The position of the viewer's eye.</param>
    /// <param name="target">The camera look-at target.</param>
    /// <param name="up">The camera's up vector.</param>
    /// <param name="result">When the method completes, contains the created look-at matrix.</param>
    public static void LookAtLH(Vector3 eye, Vector3 target, Vector3 up, out Matrix result)
    {
        Vector3.Subtract(target, eye, var zaxis); zaxis.Normalize();
        Vector3.Cross(up, zaxis, var xaxis); xaxis.Normalize();
        Vector3.Cross(zaxis, xaxis, var yaxis);

        result = Identity;
        result.M11 = xaxis.X; result.M21 = xaxis.Y; result.M31 = xaxis.Z;
        result.M12 = yaxis.X; result.M22 = yaxis.Y; result.M32 = yaxis.Z;
        result.M13 = zaxis.X; result.M23 = zaxis.Y; result.M33 = zaxis.Z;

        Vector3.Dot(xaxis, eye, out result.M41);
        Vector3.Dot(yaxis, eye, out result.M42);
        Vector3.Dot(zaxis, eye, out result.M43);

        result.M41 = -result.M41;
        result.M42 = -result.M42;
        result.M43 = -result.M43;
    }

    /// <summary>
    /// Creates a left-handed, look-at matrix.
    /// </summary>
    /// <param name="eye">The position of the viewer's eye.</param>
    /// <param name="target">The camera look-at target.</param>
    /// <param name="up">The camera's up vector.</param>
    /// <returns>The created look-at matrix.</returns>
    public static Matrix LookAtLH(Vector3 eye, Vector3 target, Vector3 up)
    {
        LookAtLH(eye, target, up, var result);
        return result;
    }

    /// <summary>
    /// Creates a right-handed, look-at matrix.
    /// </summary>
    /// <param name="eye">The position of the viewer's eye.</param>
    /// <param name="target">The camera look-at target.</param>
    /// <param name="up">The camera's up vector.</param>
    /// <param name="result">When the method completes, contains the created look-at matrix.</param>
    public static void LookAtRH(Vector3 eye, Vector3 target, Vector3 up, out Matrix result)
    {
        Vector3.Subtract(eye, target, var zaxis); zaxis.Normalize();
        Vector3.Cross(up, zaxis, var xaxis); xaxis.Normalize();
        Vector3.Cross(zaxis, xaxis, var yaxis);

        result = Identity;
        result.M11 = xaxis.X; result.M21 = xaxis.Y; result.M31 = xaxis.Z;
        result.M12 = yaxis.X; result.M22 = yaxis.Y; result.M32 = yaxis.Z;
        result.M13 = zaxis.X; result.M23 = zaxis.Y; result.M33 = zaxis.Z;

        Vector3.Dot(xaxis, eye, out result.M41);
        Vector3.Dot(yaxis, eye, out result.M42);
        Vector3.Dot(zaxis, eye, out result.M43);

        result.M41 = -result.M41;
        result.M42 = -result.M42;
        result.M43 = -result.M43;
    }

    /// <summary>
    /// Creates a right-handed, look-at matrix.
    /// </summary>
    /// <param name="eye">The position of the viewer's eye.</param>
    /// <param name="target">The camera look-at target.</param>
    /// <param name="up">The camera's up vector.</param>
    /// <returns>The created look-at matrix.</returns>
    public static Matrix LookAtRH(Vector3 eye, Vector3 target, Vector3 up)
    {
        LookAtRH(eye, target, up, var result);
        return result;
    }

    /// <summary>
    /// Creates a left-handed, orthographic projection matrix.
    /// </summary>
    /// <param name="width">Width of the viewing volume.</param>
    /// <param name="height">Height of the viewing volume.</param>
    /// <param name="znear">Minimum z-value of the viewing volume.</param>
    /// <param name="zfar">Maximum z-value of the viewing volume.</param>
    /// <param name="result">When the method completes, contains the created projection matrix.</param>
    public static void OrthoLH(float width, float height, float znear, float zfar, out Matrix result)
    {
        float halfWidth = width * 0.5f;
        float halfHeight = height * 0.5f;

        OrthoOffCenterLH(-halfWidth, halfWidth, -halfHeight, halfHeight, znear, zfar, out result);
    }

    /// <summary>
    /// Creates a left-handed, orthographic projection matrix.
    /// </summary>
    /// <param name="width">Width of the viewing volume.</param>
    /// <param name="height">Height of the viewing volume.</param>
    /// <param name="znear">Minimum z-value of the viewing volume.</param>
    /// <param name="zfar">Maximum z-value of the viewing volume.</param>
    /// <returns>The created projection matrix.</returns>
    public static Matrix OrthoLH(float width, float height, float znear, float zfar)
    {
        OrthoLH(width, height, znear, zfar, var result);
        return result;
    }

    /// <summary>
    /// Creates a right-handed, orthographic projection matrix.
    /// </summary>
    /// <param name="width">Width of the viewing volume.</param>
    /// <param name="height">Height of the viewing volume.</param>
    /// <param name="znear">Minimum z-value of the viewing volume.</param>
    /// <param name="zfar">Maximum z-value of the viewing volume.</param>
    /// <param name="result">When the method completes, contains the created projection matrix.</param>
    public static void OrthoRH(float width, float height, float znear, float zfar, out Matrix result)
    {
        float halfWidth = width * 0.5f;
        float halfHeight = height * 0.5f;

        OrthoOffCenterRH(-halfWidth, halfWidth, -halfHeight, halfHeight, znear, zfar, out result);
    }

    /// <summary>
    /// Creates a right-handed, orthographic projection matrix.
    /// </summary>
    /// <param name="width">Width of the viewing volume.</param>
    /// <param name="height">Height of the viewing volume.</param>
    /// <param name="znear">Minimum z-value of the viewing volume.</param>
    /// <param name="zfar">Maximum z-value of the viewing volume.</param>
    /// <returns>The created projection matrix.</returns>
    public static Matrix OrthoRH(float width, float height, float znear, float zfar)
    {
        OrthoRH(width, height, znear, zfar, var result);
        return result;
    }

    /// <summary>
    /// Creates a left-handed, customized orthographic projection matrix.
    /// </summary>
    /// <param name="left">Minimum x-value of the viewing volume.</param>
    /// <param name="right">Maximum x-value of the viewing volume.</param>
    /// <param name="bottom">Minimum y-value of the viewing volume.</param>
    /// <param name="top">Maximum y-value of the viewing volume.</param>
    /// <param name="znear">Minimum z-value of the viewing volume.</param>
    /// <param name="zfar">Maximum z-value of the viewing volume.</param>
    /// <param name="result">When the method completes, contains the created projection matrix.</param>
    public static void OrthoOffCenterLH(float left, float right, float bottom, float top, float znear, float zfar, out Matrix result)
    {
        float zRange = 1.0f / (zfar - znear);

        result = Identity;
        result.M11 = 2.0f / (right - left);
        result.M22 = 2.0f / (top - bottom);
        result.M33 = zRange;
        result.M41 = (left + right) / (left - right);
        result.M42 = (top + bottom) / (bottom - top);
        result.M43 = -znear * zRange;
    }

    /// <summary>
    /// Creates a left-handed, customized orthographic projection matrix.
    /// </summary>
    /// <param name="left">Minimum x-value of the viewing volume.</param>
    /// <param name="right">Maximum x-value of the viewing volume.</param>
    /// <param name="bottom">Minimum y-value of the viewing volume.</param>
    /// <param name="top">Maximum y-value of the viewing volume.</param>
    /// <param name="znear">Minimum z-value of the viewing volume.</param>
    /// <param name="zfar">Maximum z-value of the viewing volume.</param>
    /// <returns>The created projection matrix.</returns>
    public static Matrix OrthoOffCenterLH(float left, float right, float bottom, float top, float znear, float zfar)
    {
        OrthoOffCenterLH(left, right, bottom, top, znear, zfar, var result);
        return result;
    }

    /// <summary>
    /// Creates a right-handed, customized orthographic projection matrix.
    /// </summary>
    /// <param name="left">Minimum x-value of the viewing volume.</param>
    /// <param name="right">Maximum x-value of the viewing volume.</param>
    /// <param name="bottom">Minimum y-value of the viewing volume.</param>
    /// <param name="top">Maximum y-value of the viewing volume.</param>
    /// <param name="znear">Minimum z-value of the viewing volume.</param>
    /// <param name="zfar">Maximum z-value of the viewing volume.</param>
    /// <param name="result">When the method completes, contains the created projection matrix.</param>
    public static void OrthoOffCenterRH(float left, float right, float bottom, float top, float znear, float zfar, out Matrix result)
    {
        OrthoOffCenterLH(left, right, bottom, top, znear, zfar, out result);
        result.M33 *= -1.0f;
    }

    /// <summary>
    /// Creates a right-handed, customized orthographic projection matrix.
    /// </summary>
    /// <param name="left">Minimum x-value of the viewing volume.</param>
    /// <param name="right">Maximum x-value of the viewing volume.</param>
    /// <param name="bottom">Minimum y-value of the viewing volume.</param>
    /// <param name="top">Maximum y-value of the viewing volume.</param>
    /// <param name="znear">Minimum z-value of the viewing volume.</param>
    /// <param name="zfar">Maximum z-value of the viewing volume.</param>
    /// <returns>The created projection matrix.</returns>
    public static Matrix OrthoOffCenterRH(float left, float right, float bottom, float top, float znear, float zfar)
    {
        OrthoOffCenterRH(left, right, bottom, top, znear, zfar, var result);
        return result;
    }

    /// <summary>
    /// Creates a left-handed, perspective projection matrix.
    /// </summary>
    /// <param name="width">Width of the viewing volume.</param>
    /// <param name="height">Height of the viewing volume.</param>
    /// <param name="znear">Minimum z-value of the viewing volume.</param>
    /// <param name="zfar">Maximum z-value of the viewing volume.</param>
    /// <param name="result">When the method completes, contains the created projection matrix.</param>
    public static void PerspectiveLH(float width, float height, float znear, float zfar, out Matrix result)
    {
        float halfWidth = width * 0.5f;
        float halfHeight = height * 0.5f;

        PerspectiveOffCenterLH(-halfWidth, halfWidth, -halfHeight, halfHeight, znear, zfar, out result);
    }

    /// <summary>
    /// Creates a left-handed, perspective projection matrix.
    /// </summary>
    /// <param name="width">Width of the viewing volume.</param>
    /// <param name="height">Height of the viewing volume.</param>
    /// <param name="znear">Minimum z-value of the viewing volume.</param>
    /// <param name="zfar">Maximum z-value of the viewing volume.</param>
    /// <returns>The created projection matrix.</returns>
    public static Matrix PerspectiveLH(float width, float height, float znear, float zfar)
    {
        PerspectiveLH(width, height, znear, zfar, var result);
        return result;
    }

    /// <summary>
    /// Creates a right-handed, perspective projection matrix.
    /// </summary>
    /// <param name="width">Width of the viewing volume.</param>
    /// <param name="height">Height of the viewing volume.</param>
    /// <param name="znear">Minimum z-value of the viewing volume.</param>
    /// <param name="zfar">Maximum z-value of the viewing volume.</param>
    /// <param name="result">When the method completes, contains the created projection matrix.</param>
    public static void PerspectiveRH(float width, float height, float znear, float zfar, out Matrix result)
    {
        float halfWidth = width * 0.5f;
        float halfHeight = height * 0.5f;

        PerspectiveOffCenterRH(-halfWidth, halfWidth, -halfHeight, halfHeight, znear, zfar, out result);
    }

    /// <summary>
    /// Creates a right-handed, perspective projection matrix.
    /// </summary>
    /// <param name="width">Width of the viewing volume.</param>
    /// <param name="height">Height of the viewing volume.</param>
    /// <param name="znear">Minimum z-value of the viewing volume.</param>
    /// <param name="zfar">Maximum z-value of the viewing volume.</param>
    /// <returns>The created projection matrix.</returns>
    public static Matrix PerspectiveRH(float width, float height, float znear, float zfar)
    {
        PerspectiveRH(width, height, znear, zfar, var result);
        return result;
    }

    /// <summary>
    /// Creates a left-handed, perspective projection matrix based on a field of view.
    /// </summary>
    /// <param name="fov">Field of view in the y direction, in radians.</param>
    /// <param name="aspect">Aspect ratio, defined as view space width divided by height.</param>
    /// <param name="znear">Minimum z-value of the viewing volume.</param>
    /// <param name="zfar">Maximum z-value of the viewing volume.</param>
    /// <param name="result">When the method completes, contains the created projection matrix.</param>
    public static void PerspectiveFovLH(float fov, float aspect, float znear, float zfar, out Matrix result)
    {
        float yScale = (float)(1.0 / Math.Tan(fov * 0.5f));
        float xScale = yScale / aspect;

        float halfWidth = znear / xScale;
        float halfHeight = znear / yScale;

        PerspectiveOffCenterLH(-halfWidth, halfWidth, -halfHeight, halfHeight, znear, zfar, out result);
    }

    /// <summary>
    /// Creates a left-handed, perspective projection matrix based on a field of view.
    /// </summary>
    /// <param name="fov">Field of view in the y direction, in radians.</param>
    /// <param name="aspect">Aspect ratio, defined as view space width divided by height.</param>
    /// <param name="znear">Minimum z-value of the viewing volume.</param>
    /// <param name="zfar">Maximum z-value of the viewing volume.</param>
    /// <returns>The created projection matrix.</returns>
    public static Matrix PerspectiveFovLH(float fov, float aspect, float znear, float zfar)
    {
        PerspectiveFovLH(fov, aspect, znear, zfar, var result);
        return result;
    }

    /// <summary>
    /// Creates a right-handed, perspective projection matrix based on a field of view.
    /// </summary>
    /// <param name="fov">Field of view in the y direction, in radians.</param>
    /// <param name="aspect">Aspect ratio, defined as view space width divided by height.</param>
    /// <param name="znear">Minimum z-value of the viewing volume.</param>
    /// <param name="zfar">Maximum z-value of the viewing volume.</param>
    /// <param name="result">When the method completes, contains the created projection matrix.</param>
    public static void PerspectiveFovRH(float fov, float aspect, float znear, float zfar, out Matrix result)
    {
        float yScale = (float)(1.0 / Math.Tan(fov * 0.5f));
        float xScale = yScale / aspect;

        float halfWidth = znear / xScale;
        float halfHeight = znear / yScale;

        PerspectiveOffCenterRH(-halfWidth, halfWidth, -halfHeight, halfHeight, znear, zfar, out result);
    }

    /// <summary>
    /// Creates a right-handed, perspective projection matrix based on a field of view.
    /// </summary>
    /// <param name="fov">Field of view in the y direction, in radians.</param>
    /// <param name="aspect">Aspect ratio, defined as view space width divided by height.</param>
    /// <param name="znear">Minimum z-value of the viewing volume.</param>
    /// <param name="zfar">Maximum z-value of the viewing volume.</param>
    /// <returns>The created projection matrix.</returns>
    public static Matrix PerspectiveFovRH(float fov, float aspect, float znear, float zfar)
    {
        PerspectiveFovRH(fov, aspect, znear, zfar, var result);
        return result;
    }

    /// <summary>
    /// Creates a left-handed, customized perspective projection matrix.
    /// </summary>
    /// <param name="left">Minimum x-value of the viewing volume.</param>
    /// <param name="right">Maximum x-value of the viewing volume.</param>
    /// <param name="bottom">Minimum y-value of the viewing volume.</param>
    /// <param name="top">Maximum y-value of the viewing volume.</param>
    /// <param name="znear">Minimum z-value of the viewing volume.</param>
    /// <param name="zfar">Maximum z-value of the viewing volume.</param>
    /// <param name="result">When the method completes, contains the created projection matrix.</param>
    public static void PerspectiveOffCenterLH(float left, float right, float bottom, float top, float znear, float zfar, out Matrix result)
    {
        float zRange = zfar / (zfar - znear);

        result = Matrix
        {
            M11 = 2.0f * znear / (right - left),
            M22 = 2.0f * znear / (top - bottom),
            M31 = (left + right) / (left - right),
            M32 = (top + bottom) / (bottom - top),
            M33 = zRange,
            M34 = 1.0f,
            M43 = -znear * zRange
        };
    }

    /// <summary>
    /// Creates a left-handed, customized perspective projection matrix.
    /// </summary>
    /// <param name="left">Minimum x-value of the viewing volume.</param>
    /// <param name="right">Maximum x-value of the viewing volume.</param>
    /// <param name="bottom">Minimum y-value of the viewing volume.</param>
    /// <param name="top">Maximum y-value of the viewing volume.</param>
    /// <param name="znear">Minimum z-value of the viewing volume.</param>
    /// <param name="zfar">Maximum z-value of the viewing volume.</param>
    /// <returns>The created projection matrix.</returns>
    public static Matrix PerspectiveOffCenterLH(float left, float right, float bottom, float top, float znear, float zfar)
    {
        PerspectiveOffCenterLH(left, right, bottom, top, znear, zfar, var result);
        return result;
    }

    /// <summary>
    /// Creates a right-handed, customized perspective projection matrix.
    /// </summary>
    /// <param name="left">Minimum x-value of the viewing volume.</param>
    /// <param name="right">Maximum x-value of the viewing volume.</param>
    /// <param name="bottom">Minimum y-value of the viewing volume.</param>
    /// <param name="top">Maximum y-value of the viewing volume.</param>
    /// <param name="znear">Minimum z-value of the viewing volume.</param>
    /// <param name="zfar">Maximum z-value of the viewing volume.</param>
    /// <param name="result">When the method completes, contains the created projection matrix.</param>
    public static void PerspectiveOffCenterRH(float left, float right, float bottom, float top, float znear, float zfar, out Matrix result)
    {
        PerspectiveOffCenterLH(left, right, bottom, top, znear, zfar, out result);
        result.M31 *= -1.0f;
        result.M32 *= -1.0f;
        result.M33 *= -1.0f;
        result.M34 *= -1.0f;
    }

    /// <summary>
    /// Creates a right-handed, customized perspective projection matrix.
    /// </summary>
    /// <param name="left">Minimum x-value of the viewing volume.</param>
    /// <param name="right">Maximum x-value of the viewing volume.</param>
    /// <param name="bottom">Minimum y-value of the viewing volume.</param>
    /// <param name="top">Maximum y-value of the viewing volume.</param>
    /// <param name="znear">Minimum z-value of the viewing volume.</param>
    /// <param name="zfar">Maximum z-value of the viewing volume.</param>
    /// <returns>The created projection matrix.</returns>
    public static Matrix PerspectiveOffCenterRH(float left, float right, float bottom, float top, float znear, float zfar)
    {
        PerspectiveOffCenterRH(left, right, bottom, top, znear, zfar, var result);
        return result;
    }

    /// <summary>
    /// Builds a matrix that can be used to reflect vectors about a plane.
    /// </summary>
    /// <param name="plane">The plane for which the reflection occurs. This parameter is assumed to be normalized.</param>
    /// <param name="result">When the method completes, contains the reflection matrix.</param>
    public static void Reflection(Plane plane, out Matrix result)
    {
        float x = plane.Normal.X;
        float y = plane.Normal.Y;
        float z = plane.Normal.Z;
        float x2 = -2.0f * x;
        float y2 = -2.0f * y;
        float z2 = -2.0f * z;

        result.M11 = (x2 * x) + 1.0f;
        result.M12 = y2 * x;
        result.M13 = z2 * x;
        result.M14 = 0.0f;
        result.M21 = x2 * y;
        result.M22 = (y2 * y) + 1.0f;
        result.M23 = z2 * y;
        result.M24 = 0.0f;
        result.M31 = x2 * z;
        result.M32 = y2 * z;
        result.M33 = (z2 * z) + 1.0f;
        result.M34 = 0.0f;
        result.M41 = x2 * plane.D;
        result.M42 = y2 * plane.D;
        result.M43 = z2 * plane.D;
        result.M44 = 1.0f;
    }

    /// <summary>
    /// Builds a matrix that can be used to reflect vectors about a plane.
    /// </summary>
    /// <param name="plane">The plane for which the reflection occurs. This parameter is assumed to be normalized.</param>
    /// <returns>The reflection matrix.</returns>
    public static Matrix Reflection(Plane plane)
    {
        Reflection(plane, var result);
        return result;
    }

    /// <summary>
    /// Creates a matrix that flattens geometry into a shadow.
    /// </summary>
    /// <param name="light">The light direction. If the W component is 0, the light is directional light; if the
    /// W component is 1, the light is a point light.</param>
    /// <param name="plane">The plane onto which to project the geometry as a shadow. This parameter is assumed to be normalized.</param>
    /// <param name="result">When the method completes, contains the shadow matrix.</param>
    public static void Shadow(Vector4 light, Plane plane, out Matrix result)
    {
        float dot = (plane.Normal.X * light.X) + (plane.Normal.Y * light.Y) + (plane.Normal.Z * light.Z) + (plane.D * light.W);
        float x = -plane.Normal.X;
        float y = -plane.Normal.Y;
        float z = -plane.Normal.Z;
        float d = -plane.D;

        result.M11 = (x * light.X) + dot;
        result.M21 = y * light.X;
        result.M31 = z * light.X;
        result.M41 = d * light.X;
        result.M12 = x * light.Y;
        result.M22 = (y * light.Y) + dot;
        result.M32 = z * light.Y;
        result.M42 = d * light.Y;
        result.M13 = x * light.Z;
        result.M23 = y * light.Z;
        result.M33 = (z * light.Z) + dot;
        result.M43 = d * light.Z;
        result.M14 = x * light.W;
        result.M24 = y * light.W;
        result.M34 = z * light.W;
        result.M44 = (d * light.W) + dot;
    }

    /// <summary>
    /// Creates a matrix that flattens geometry into a shadow.
    /// </summary>
    /// <param name="light">The light direction. If the W component is 0, the light is directional light; if the
    /// W component is 1, the light is a point light.</param>
    /// <param name="plane">The plane onto which to project the geometry as a shadow. This parameter is assumed to be normalized.</param>
    /// <returns>The shadow matrix.</returns>
    public static Matrix Shadow(Vector4 light, Plane plane)
    {
        Shadow(light, plane, var result);
        return result;
    }

    /// <summary>
    /// Creates a matrix that scales along the x-axis, y-axis, and y-axis.
    /// </summary>
    /// <param name="scale">Scaling factor for all three axes.</param>
    /// <param name="result">When the method completes, contains the created scaling matrix.</param>
    public static void Scaling(Vector3 scale, out Matrix result)
    {
        Scaling(scale.X, scale.Y, scale.Z, out result);
    }

    /// <summary>
    /// Creates a matrix that scales along the x-axis, y-axis, and y-axis.
    /// </summary>
    /// <param name="scale">Scaling factor for all three axes.</param>
    /// <returns>The created scaling matrix.</returns>
    public static Matrix Scaling(Vector3 scale)
    {
        Scaling(scale, var result);
        return result;
    }

    /// <summary>
    /// Creates a matrix that scales along the x-axis, y-axis, and y-axis.
    /// </summary>
    /// <param name="x">Scaling factor that is applied along the x-axis.</param>
    /// <param name="y">Scaling factor that is applied along the y-axis.</param>
    /// <param name="z">Scaling factor that is applied along the z-axis.</param>
    /// <param name="result">When the method completes, contains the created scaling matrix.</param>
    public static void Scaling(float x, float y, float z, out Matrix result)
    {
        result = Identity;
        result.M11 = x;
        result.M22 = y;
        result.M33 = z;
    }

    /// <summary>
    /// Creates a matrix that scales along the x-axis, y-axis, and y-axis.
    /// </summary>
    /// <param name="x">Scaling factor that is applied along the x-axis.</param>
    /// <param name="y">Scaling factor that is applied along the y-axis.</param>
    /// <param name="z">Scaling factor that is applied along the z-axis.</param>
    /// <returns>The created scaling matrix.</returns>
    public static Matrix Scaling(float x, float y, float z)
    {
        Scaling(x, y, z, var result);
        return result;
    }

    /// <summary>
    /// Creates a matrix that uniformally scales along all three axis.
    /// </summary>
    /// <param name="scale">The uniform scale that is applied along all axis.</param>
    /// <param name="result">When the method completes, contains the created scaling matrix.</param>
    public static void Scaling(float scale, out Matrix result)
    {
        result = Identity;
        result.M11 = result.M22 = result.M33 = scale;
    }

    /// <summary>
    /// Creates a matrix that uniformally scales along all three axis.
    /// </summary>
    /// <param name="scale">The uniform scale that is applied along all axis.</param>
    /// <returns>The created scaling matrix.</returns>
    public static Matrix Scaling(float scale)
    {
        Scaling(scale, var result);
        return result;
    }

    /// <summary>
    /// Creates a matrix that rotates around the x-axis.
    /// </summary>
    /// <param name="angle">Angle of rotation in radians. Angles are measured clockwise when looking along the rotation axis toward the origin.</param>
    /// <param name="result">When the method completes, contains the created rotation matrix.</param>
    public static void RotationX(float angle, out Matrix result)
    {
        float cos = Math.Cos(angle);
        float sin = Math.Sin(angle);

        result = Identity;
        result.M22 = cos;
        result.M23 = sin;
        result.M32 = -sin;
        result.M33 = cos;
    }

    /// <summary>
    /// Creates a matrix that rotates around the x-axis.
    /// </summary>
    /// <param name="angle">Angle of rotation in radians. Angles are measured clockwise when looking along the rotation axis toward the origin.</param>
    /// <returns>The created rotation matrix.</returns>
    public static Matrix RotationX(float angle)
    {
        RotationX(angle, var result);
        return result;
    }

    /// <summary>
    /// Creates a matrix that rotates around the y-axis.
    /// </summary>
    /// <param name="angle">Angle of rotation in radians. Angles are measured clockwise when looking along the rotation axis toward the origin.</param>
    /// <param name="result">When the method completes, contains the created rotation matrix.</param>
    public static void RotationY(float angle, out Matrix result)
    {
        float cos = Math.Cos(angle);
        float sin = Math.Sin(angle);

        result = Identity;
        result.M11 = cos;
        result.M13 = -sin;
        result.M31 = sin;
        result.M33 = cos;
    }

    /// <summary>
    /// Creates a matrix that rotates around the y-axis.
    /// </summary>
    /// <param name="angle">Angle of rotation in radians. Angles are measured clockwise when looking along the rotation axis toward the origin.</param>
    /// <returns>The created rotation matrix.</returns>
    public static Matrix RotationY(float angle)
    {
        RotationY(angle, var result);
        return result;
    }

    /// <summary>
    /// Creates a matrix that rotates around the z-axis.
    /// </summary>
    /// <param name="angle">Angle of rotation in radians. Angles are measured clockwise when looking along the rotation axis toward the origin.</param>
    /// <param name="result">When the method completes, contains the created rotation matrix.</param>
    public static void RotationZ(float angle, out Matrix result)
    {
        float cos = Math.Cos(angle);
        float sin = Math.Sin(angle);

        result = Identity;
        result.M11 = cos;
        result.M12 = sin;
        result.M21 = -sin;
        result.M22 = cos;
    }

    /// <summary>
    /// Creates a matrix that rotates around the z-axis.
    /// </summary>
    /// <param name="angle">Angle of rotation in radians. Angles are measured clockwise when looking along the rotation axis toward the origin.</param>
    /// <returns>The created rotation matrix.</returns>
    public static Matrix RotationZ(float angle)
    {
        RotationZ(angle, var result);
        return result;
    }

    /// <summary>
    /// Creates a matrix that rotates around an arbitary axis.
    /// </summary>
    /// <param name="axis">The axis around which to rotate. This parameter is assumed to be normalized.</param>
    /// <param name="angle">Angle of rotation in radians. Angles are measured clockwise when looking along the rotation axis toward the origin.</param>
    /// <param name="result">When the method completes, contains the created rotation matrix.</param>
    public static void RotationAxis(Vector3 axis, float angle, out Matrix result)
    {
        float x = axis.X;
        float y = axis.Y;
        float z = axis.Z;
        float cos = Math.Cos(angle);
        float sin = Math.Sin(angle);
        float xx = x * x;
        float yy = y * y;
        float zz = z * z;
        float xy = x * y;
        float xz = x * z;
        float yz = y * z;

        result = Identity;
        result.M11 = xx + (cos * (1.0f - xx));
        result.M12 = xy - (cos * xy) + (sin * z);
        result.M13 = xz - (cos * xz) - (sin * y);
        result.M21 = xy - (cos * xy) - (sin * z);
        result.M22 = yy + (cos * (1.0f - yy));
        result.M23 = yz - (cos * yz) + (sin * x);
        result.M31 = xz - (cos * xz) + (sin * y);
        result.M32 = yz - (cos * yz) - (sin * x);
        result.M33 = zz + (cos * (1.0f - zz));
    }

    /// <summary>
    /// Creates a matrix that rotates around an arbitary axis.
    /// </summary>
    /// <param name="axis">The axis around which to rotate. This parameter is assumed to be normalized.</param>
    /// <param name="angle">Angle of rotation in radians. Angles are measured clockwise when looking along the rotation axis toward the origin.</param>
    /// <returns>The created rotation matrix.</returns>
    public static Matrix RotationAxis(Vector3 axis, float angle)
    {
        RotationAxis(axis, angle, var result);
        return result;
    }

    /// <summary>
    /// Creates a rotation matrix from a quaternion.
    /// </summary>
    /// <param name="rotation">The quaternion to use to build the matrix.</param>
    /// <param name="result">The created rotation matrix.</param>
    public static void RotationQuaternion(Quaternion rotation, out Matrix result)
    {
        float xx = rotation.X * rotation.X;
        float yy = rotation.Y * rotation.Y;
        float zz = rotation.Z * rotation.Z;
        float xy = rotation.X * rotation.Y;
        float zw = rotation.Z * rotation.W;
        float zx = rotation.Z * rotation.X;
        float yw = rotation.Y * rotation.W;
        float yz = rotation.Y * rotation.Z;
        float xw = rotation.X * rotation.W;

        result = Identity;
        result.M11 = 1.0f - (2.0f * (yy + zz));
        result.M12 = 2.0f * (xy + zw);
        result.M13 = 2.0f * (zx - yw);
        result.M21 = 2.0f * (xy - zw);
        result.M22 = 1.0f - (2.0f * (zz + xx));
        result.M23 = 2.0f * (yz + xw);
        result.M31 = 2.0f * (zx + yw);
        result.M32 = 2.0f * (yz - xw);
        result.M33 = 1.0f - (2.0f * (yy + xx));
    }

    /// <summary>
    /// Creates a matrix that contains both the X, Y and Z rotation, as well as scaling and translation. Note: This function is NOT thead safe.
    /// </summary>
    /// <param name="scaling">The scaling.</param>
    /// <param name="rotation">Angle of rotation in radians. Angles are measured clockwise when looking along the rotation axis toward the origin.</param>
    /// <param name="translation">The translation.</param>
    /// <param name="result">When the method completes, contains the created rotation matrix.</param>
    public static void Transformation(Vector3 scaling, Quaternion rotation, Vector3 translation, out Matrix result)
    {
        // Equivalent to:
        //result =
        //    Matrix.Scaling(scaling)
        //    *Matrix.RotationX(rotation.X)
        //    *Matrix.RotationY(rotation.Y)
        //    *Matrix.RotationZ(rotation.Z)
        //    *Matrix.Position(translation);

        // Rotation
        float xx = rotation.X * rotation.X;
        float yy = rotation.Y * rotation.Y;
        float zz = rotation.Z * rotation.Z;
        float xy = rotation.X * rotation.Y;
        float zw = rotation.Z * rotation.W;
        float zx = rotation.Z * rotation.X;
        float yw = rotation.Y * rotation.W;
        float yz = rotation.Y * rotation.Z;
        float xw = rotation.X * rotation.W;

        result.M11 = 1.0f - (2.0f * (yy + zz));
        result.M12 = 2.0f * (xy + zw);
        result.M13 = 2.0f * (zx - yw);
        result.M21 = 2.0f * (xy - zw);
        result.M22 = 1.0f - (2.0f * (zz + xx));
        result.M23 = 2.0f * (yz + xw);
        result.M31 = 2.0f * (zx + yw);
        result.M32 = 2.0f * (yz - xw);
        result.M33 = 1.0f - (2.0f * (yy + xx));

        // Position
        result.M41 = translation.X;
        result.M42 = translation.Y;
        result.M43 = translation.Z;

        // Scale
        if (scaling.X != 1.0f)
        {
            result.M11 *= scaling.X;
            result.M12 *= scaling.X;
            result.M13 *= scaling.X;
        }
        if (scaling.Y != 1.0f)
        {
            result.M21 *= scaling.Y;
            result.M22 *= scaling.Y;
            result.M23 *= scaling.Y;
        }
        if (scaling.Z != 1.0f)
        {
            result.M31 *= scaling.Z;
            result.M32 *= scaling.Z;
            result.M33 *= scaling.Z;
        }

        result.M14 = 0.0f;
        result.M24 = 0.0f;
        result.M34 = 0.0f;
        result.M44 = 1.0f;
    }

    /// <summary>
    /// Creates a rotation matrix from a quaternion.
    /// </summary>
    /// <param name="rotation">The quaternion to use to build the matrix.</param>
    /// <returns>The created rotation matrix.</returns>
    public static Matrix RotationQuaternion(Quaternion rotation)
    {
        RotationQuaternion(rotation, var result);
        return result;
    }

    /// <summary>
    /// Creates a rotation matrix with a specified yaw, pitch, and roll value (angles in radians).
    /// </summary>
    /// <param name="yaw">Yaw around the y-axis, in radians.</param>
    /// <param name="pitch">Pitch around the x-axis, in radians.</param>
    /// <param name="roll">Roll around the z-axis, in radians.</param>
    /// <param name="result">When the method completes, contains the created rotation matrix.</param>
    public static void RotationYawPitchRoll(float yaw, float pitch, float roll, out Matrix result)
    {
        Quaternion.RotationYawPitchRoll(yaw, pitch, roll, var quaternion);
        RotationQuaternion(quaternion, out result);
    }

    /// <summary>
    /// Creates a rotation matrix with a specified yaw, pitch, and roll value (angles in radians).
    /// </summary>
    /// <param name="yaw">Yaw around the y-axis, in radians.</param>
    /// <param name="pitch">Pitch around the x-axis, in radians.</param>
    /// <param name="roll">Roll around the z-axis, in radians.</param>
    /// <returns>The created rotation matrix.</returns>
    public static Matrix RotationYawPitchRoll(float yaw, float pitch, float roll)
    {
        RotationYawPitchRoll(yaw, pitch, roll, var result);
        return result;
    }

    /// <summary>
    /// Creates a translation matrix using the specified offsets.
    /// </summary>
    /// <param name="value">The offset for all three coordinate planes.</param>
    /// <param name="result">When the method completes, contains the created translation matrix.</param>
    public static void Translation(Vector3 value, out Matrix result)
    {
        Translation(value.X, value.Y, value.Z, out result);
    }

    /// <summary>
    /// Creates a translation matrix using the specified offsets.
    /// </summary>
    /// <param name="value">The offset for all three coordinate planes.</param>
    /// <returns>The created translation matrix.</returns>
    public static Matrix Translation(Vector3 value)
    {
        Translation(value, var result);
        return result;
    }

    /// <summary>
    /// Creates a translation matrix using the specified offsets.
    /// </summary>
    /// <param name="x">X-coordinate offset.</param>
    /// <param name="y">Y-coordinate offset.</param>
    /// <param name="z">Z-coordinate offset.</param>
    /// <param name="result">When the method completes, contains the created translation matrix.</param>
    public static void Translation(float x, float y, float z, out Matrix result)
    {
        result = Identity;
        result.M41 = x;
        result.M42 = y;
        result.M43 = z;
    }

    /// <summary>
    /// Creates a translation matrix using the specified offsets.
    /// </summary>
    /// <param name="x">X-coordinate offset.</param>
    /// <param name="y">Y-coordinate offset.</param>
    /// <param name="z">Z-coordinate offset.</param>
    /// <returns>The created translation matrix.</returns>
    public static Matrix Translation(float x, float y, float z)
    {
        Translation(x, y, z, var result);
        return result;
    }

    /// <summary>
    /// Creates a 3D affine transformation matrix.
    /// </summary>
    /// <param name="scaling">Scaling factor.</param>
    /// <param name="rotation">The rotation of the transformation.</param>
    /// <param name="translation">The translation factor of the transformation.</param>
    /// <param name="result">When the method completes, contains the created affine transformation matrix.</param>
    public static void AffineTransformation(float scaling, Quaternion rotation, Vector3 translation, out Matrix result)
    {
        result = Scaling(scaling) * RotationQuaternion(rotation) * Translation(translation);
    }

    /// <summary>
    /// Creates a 3D affine transformation matrix.
    /// </summary>
    /// <param name="scaling">Scaling factor.</param>
    /// <param name="rotation">The rotation of the transformation.</param>
    /// <param name="translation">The translation factor of the transformation.</param>
    /// <returns>The created affine transformation matrix.</returns>
    public static Matrix AffineTransformation(float scaling, Quaternion rotation, Vector3 translation)
    {
        AffineTransformation(scaling, rotation, translation, var result);
        return result;
    }

    /// <summary>
    /// Creates a 3D affine transformation matrix.
    /// </summary>
    /// <param name="scaling">Scaling factor.</param>
    /// <param name="rotationCenter">The center of the rotation.</param>
    /// <param name="rotation">The rotation of the transformation.</param>
    /// <param name="translation">The translation factor of the transformation.</param>
    /// <param name="result">When the method completes, contains the created affine transformation matrix.</param>
    public static void AffineTransformation(float scaling, Vector3 rotationCenter, Quaternion rotation, Vector3 translation, out Matrix result)
    {
        result = Scaling(scaling) * Translation(-rotationCenter) * RotationQuaternion(rotation) *
            Translation(rotationCenter) * Translation(translation);
    }

    /// <summary>
    /// Creates a 3D affine transformation matrix.
    /// </summary>
    /// <param name="scaling">Scaling factor.</param>
    /// <param name="rotationCenter">The center of the rotation.</param>
    /// <param name="rotation">The rotation of the transformation.</param>
    /// <param name="translation">The translation factor of the transformation.</param>
    /// <returns>The created affine transformation matrix.</returns>
    public static Matrix AffineTransformation(float scaling, Vector3 rotationCenter, Quaternion rotation, Vector3 translation)
    {
        AffineTransformation(scaling, rotationCenter, rotation, translation, var result);
        return result;
    }

    /// <summary>
    /// Creates a 2D affine transformation matrix.
    /// </summary>
    /// <param name="scaling">Scaling factor.</param>
    /// <param name="rotation">The rotation of the transformation.</param>
    /// <param name="translation">The translation factor of the transformation.</param>
    /// <param name="result">When the method completes, contains the created affine transformation matrix.</param>
    public static void AffineTransformation2D(float scaling, float rotation, Vector2 translation, out Matrix result)
    {
        result = Scaling(scaling, scaling, 1.0f) * RotationZ(rotation) * Translation((Vector3)translation);
    }

    /// <summary>
    /// Creates a 2D affine transformation matrix.
    /// </summary>
    /// <param name="scaling">Scaling factor.</param>
    /// <param name="rotation">The rotation of the transformation.</param>
    /// <param name="translation">The translation factor of the transformation.</param>
    /// <returns>The created affine transformation matrix.</returns>
    public static Matrix AffineTransformation2D(float scaling, float rotation, Vector2 translation)
    {
        AffineTransformation2D(scaling, rotation, translation, var result);
        return result;
    }

    /// <summary>
    /// Creates a 2D affine transformation matrix.
    /// </summary>
    /// <param name="scaling">Scaling factor.</param>
    /// <param name="rotationCenter">The center of the rotation.</param>
    /// <param name="rotation">The rotation of the transformation.</param>
    /// <param name="translation">The translation factor of the transformation.</param>
    /// <param name="result">When the method completes, contains the created affine transformation matrix.</param>
    public static void AffineTransformation2D(float scaling, Vector2 rotationCenter, float rotation, Vector2 translation, out Matrix result)
    {
        result = Scaling(scaling, scaling, 1.0f) * Translation((Vector3)(-rotationCenter)) * RotationZ(rotation) *
            Translation((Vector3)rotationCenter) * Translation((Vector3)translation);
    }

    /// <summary>
    /// Creates a 2D affine transformation matrix.
    /// </summary>
    /// <param name="scaling">Scaling factor.</param>
    /// <param name="rotationCenter">The center of the rotation.</param>
    /// <param name="rotation">The rotation of the transformation.</param>
    /// <param name="translation">The translation factor of the transformation.</param>
    /// <returns>The created affine transformation matrix.</returns>
    public static Matrix AffineTransformation2D(float scaling, Vector2 rotationCenter, float rotation, Vector2 translation)
    {
        AffineTransformation2D(scaling, rotationCenter, rotation, translation, var result);
        return result;
    }

    /// <summary>
    /// Creates a transformation matrix.
    /// </summary>
    /// <param name="scalingCenter">Center point of the scaling operation.</param>
    /// <param name="scalingRotation">Scaling rotation amount.</param>
    /// <param name="scaling">Scaling factor.</param>
    /// <param name="rotationCenter">The center of the rotation.</param>
    /// <param name="rotation">The rotation of the transformation.</param>
    /// <param name="translation">The translation factor of the transformation.</param>
    /// <param name="result">When the method completes, contains the created transformation matrix.</param>
    public static void Transformation(Vector3 scalingCenter, Quaternion scalingRotation, Vector3 scaling, Vector3 rotationCenter, Quaternion rotation, Vector3 translation, out Matrix result)
    {
        Matrix sr = RotationQuaternion(scalingRotation);

        result = Translation(-scalingCenter) * Transpose(sr) * Scaling(scaling) * sr * Translation(scalingCenter) * Translation(-rotationCenter) *
            RotationQuaternion(rotation) * Translation(rotationCenter) * Translation(translation);
    }

    /// <summary>
    /// Creates a transformation matrix.
    /// </summary>
    /// <param name="scalingCenter">Center point of the scaling operation.</param>
    /// <param name="scalingRotation">Scaling rotation amount.</param>
    /// <param name="scaling">Scaling factor.</param>
    /// <param name="rotationCenter">The center of the rotation.</param>
    /// <param name="rotation">The rotation of the transformation.</param>
    /// <param name="translation">The translation factor of the transformation.</param>
    /// <returns>The created transformation matrix.</returns>
    public static Matrix Transformation(Vector3 scalingCenter, Quaternion scalingRotation, Vector3 scaling, Vector3 rotationCenter, Quaternion rotation, Vector3 translation)
    {
        Transformation(scalingCenter, scalingRotation, scaling, rotationCenter, rotation, translation, var result);
        return result;
    }

    /// <summary>
    /// Creates a 2D transformation matrix.
    /// </summary>
    /// <param name="scalingCenter">Center point of the scaling operation.</param>
    /// <param name="scalingRotation">Scaling rotation amount.</param>
    /// <param name="scaling">Scaling factor.</param>
    /// <param name="rotationCenter">The center of the rotation.</param>
    /// <param name="rotation">The rotation of the transformation.</param>
    /// <param name="translation">The translation factor of the transformation.</param>
    /// <param name="result">When the method completes, contains the created transformation matrix.</param>
    public static void Transformation2D(Vector2 scalingCenter, float scalingRotation, Vector2 scaling, Vector2 rotationCenter, float rotation, Vector2 translation, out Matrix result)
    {
        result = Translation((Vector3)(-scalingCenter)) * RotationZ(-scalingRotation) * Scaling((Vector3)scaling) * RotationZ(scalingRotation) * Translation((Vector3)scalingCenter) *
            Translation((Vector3)(-rotationCenter)) * RotationZ(rotation) * Translation((Vector3)rotationCenter) * Translation((Vector3)translation);

        result.M33 = 1f;
        result.M44 = 1f;
    }

    /// <summary>
    /// Creates a 2D transformation matrix.
    /// </summary>
    /// <param name="scalingCenter">Center point of the scaling operation.</param>
    /// <param name="scalingRotation">Scaling rotation amount.</param>
    /// <param name="scaling">Scaling factor.</param>
    /// <param name="rotationCenter">The center of the rotation.</param>
    /// <param name="rotation">The rotation of the transformation.</param>
    /// <param name="translation">The translation factor of the transformation.</param>
    /// <returns>The created transformation matrix.</returns>
    public static Matrix Transformation2D(Vector2 scalingCenter, float scalingRotation, Vector2 scaling, Vector2 rotationCenter, float rotation, Vector2 translation)
    {
        Transformation2D(scalingCenter, scalingRotation, scaling, rotationCenter, rotation, translation, var result);
        return result;
    }

    /// <summary>
    /// Copies a nxm matrix to this instance.
    /// </summary>
    /// <param name="src">The source matrix.</param>
    /// <param name="columns">The number of columns.</param>
    /// <param name="rows">The number of rows.</param>
    public void CopyMatrixFrom(float* src, int32 columns, int32 rows) mut
    {
		var src;
        void* pDest = &this;
        {
            var dest = (float*)pDest;
            for (int32 i = 0; i < rows; ++i)
            {
                for (int32 j = 0; j < columns; ++j)
                {
                    dest[j] = src[j];
                }
                dest += 4;
                src += rows;
            }
        }
    }

    /// <summary>
    /// Transposes a nmx matrix to this instance.
    /// </summary>
    /// <param name="src">The SRC.</param>
    /// <param name="columns">The columns.</param>
    /// <param name="rows">The rows.</param>
    public void TransposeMatrixFrom(float* src, int32 columns, int32 rows) mut
    {
        void* pDest = &this;
        {
            var dest = (float*)pDest;
            for (int32 i = 0; i < rows; ++i)
            {
                int32 sourceIndex = i;
                for (int32 j = 0; j < columns; ++j)
                {
                    dest[j] = src[sourceIndex];
                    sourceIndex += rows;
                }
                dest += 4;
            }
        }
    }

    /// <summary>
    /// Adds two matrices.
    /// </summary>
    /// <param name="left">The first matrix to add.</param>
    /// <param name="right">The second matrix to add.</param>
    /// <returns>The sum of the two matrices.</returns>
    public static Matrix operator +(in Matrix left, in Matrix right)
    {
        Add(left, right, var result);
        return result;
    }

    /// <summary>
    /// Assert a matrix (return it unchanged).
    /// </summary>
    /// <param name="value">The matrix to assert (unchange).</param>
    /// <returns>The asserted (unchanged) matrix.</returns>
    public static Matrix operator +(in Matrix value)
    {
        return value;
    }

    /// <summary>
    /// Subtracts two matrices.
    /// </summary>
    /// <param name="left">The first matrix to subtract.</param>
    /// <param name="right">The second matrix to subtract.</param>
    /// <returns>The difference between the two matrices.</returns>
    public static Matrix operator -(in Matrix left, in Matrix right)
    {
        Subtract(left, right, var result);
        return result;
    }

    /// <summary>
    /// Negates a matrix.
    /// </summary>
    /// <param name="value">The matrix to negate.</param>
    /// <returns>The negated matrix.</returns>
    public static Matrix operator -(in Matrix value)
    {
        Negate(value, var result);
        return result;
    }

    /// <summary>
    /// Scales a matrix by a given value.
    /// </summary>
    /// <param name="left">The amount by which to scale.</param>
    /// <param name="right">The matrix to scale.</param>
    /// <returns>The scaled matrix.</returns>
    public static Matrix operator *(float left, in Matrix right)
    {
        Multiply(right, left, var result);
        return result;
    }

    /// <summary>
    /// Scales a matrix by a given value.
    /// </summary>
    /// <param name="left">The matrix to scale.</param>
    /// <param name="right">The amount by which to scale.</param>
    /// <returns>The scaled matrix.</returns>
    public static Matrix operator *(in Matrix left, float right)
    {
        Multiply(left, right, var result);
        return result;
    }

    /// <summary>
    /// Multiplies two matrices.
    /// </summary>
    /// <param name="left">The first matrix to multiply.</param>
    /// <param name="right">The second matrix to multiply.</param>
    /// <returns>The product of the two matrices.</returns>
    public static Matrix operator *(in Matrix left, in Matrix right)
	{
	    return LayoutIsRowMajor
	        ? MultiplyRowMajor(left, right)
	        : MultiplyRowMajor(right, left);
	}

	private static Matrix MultiplyRowMajor(in Matrix left, in Matrix right)
	{
	    Matrix result;

	    result.M11 = left.M11 * right.M11 + left.M12 * right.M21 + left.M13 * right.M31 + left.M14 * right.M41;
	    result.M12 = left.M11 * right.M12 + left.M12 * right.M22 + left.M13 * right.M32 + left.M14 * right.M42;
	    result.M13 = left.M11 * right.M13 + left.M12 * right.M23 + left.M13 * right.M33 + left.M14 * right.M43;
	    result.M14 = left.M11 * right.M14 + left.M12 * right.M24 + left.M13 * right.M34 + left.M14 * right.M44;

	    result.M21 = left.M21 * right.M11 + left.M22 * right.M21 + left.M23 * right.M31 + left.M24 * right.M41;
	    result.M22 = left.M21 * right.M12 + left.M22 * right.M22 + left.M23 * right.M32 + left.M24 * right.M42;
	    result.M23 = left.M21 * right.M13 + left.M22 * right.M23 + left.M23 * right.M33 + left.M24 * right.M43;
	    result.M24 = left.M21 * right.M14 + left.M22 * right.M24 + left.M23 * right.M34 + left.M24 * right.M44;

	    result.M31 = left.M31 * right.M11 + left.M32 * right.M21 + left.M33 * right.M31 + left.M34 * right.M41;
	    result.M32 = left.M31 * right.M12 + left.M32 * right.M22 + left.M33 * right.M32 + left.M34 * right.M42;
	    result.M33 = left.M31 * right.M13 + left.M32 * right.M23 + left.M33 * right.M33 + left.M34 * right.M43;
	    result.M34 = left.M31 * right.M14 + left.M32 * right.M24 + left.M33 * right.M34 + left.M34 * right.M44;

	    result.M41 = left.M41 * right.M11 + left.M42 * right.M21 + left.M43 * right.M31 + left.M44 * right.M41;
	    result.M42 = left.M41 * right.M12 + left.M42 * right.M22 + left.M43 * right.M32 + left.M44 * right.M42;
	    result.M43 = left.M41 * right.M13 + left.M42 * right.M23 + left.M43 * right.M33 + left.M44 * right.M43;
	    result.M44 = left.M41 * right.M14 + left.M42 * right.M24 + left.M43 * right.M34 + left.M44 * right.M44;

	    return result;
	}

    /// <summary>
    /// Scales a matrix by a given value.
    /// </summary>
    /// <param name="left">The matrix to scale.</param>
    /// <param name="right">The amount by which to scale.</param>
    /// <returns>The scaled matrix.</returns>
    public static Matrix operator /(in Matrix left, in float right)
    {
        Divide(left, right, var result);
        return result;
    }

    /// <summary>
    /// Divides two matrices.
    /// </summary>
    /// <param name="left">The first matrix to divide.</param>
    /// <param name="right">The second matrix to divide.</param>
    /// <returns>The quotient of the two matrices.</returns>
    public static Matrix operator /(in Matrix left, in Matrix right)
    {
        Divide(left, right, var result);
        return result;
    }

    /// <summary>
    /// Tests for equality between two objects.
    /// </summary>
    /// <param name="left">The first value to compare.</param>
    /// <param name="right">The second value to compare.</param>
    /// <returns><c>true</c> if <paramref name="left"/> has the same value as <paramref name="right"/>; otherwise, <c>false</c>.</returns>
    public static bool operator ==(in Matrix left, in Matrix right)
    {
        return left.Equals(right);
    }

    /// <summary>
    /// Tests for inequality between two objects.
    /// </summary>
    /// <param name="left">The first value to compare.</param>
    /// <param name="right">The second value to compare.</param>
    /// <returns><c>true</c> if <paramref name="left"/> has a different value than <paramref name="right"/>; otherwise, <c>false</c>.</returns>
    public static bool operator !=(in Matrix left, in Matrix right)
    {
        return !left.Equals(right);
    }

    /// <summary>
    /// Returns a <see cref="string"/> that represents this instance.
    /// </summary>
    /// <returns>
    /// A <see cref="string"/> that represents this instance.
    /// </returns>
    public override void ToString(String str) =>
        str.Append( scope $"{{ {{M11:{M11} M12:{M12} M13:{M13} M14:{M14}}} {{M21:{M21} M22:{M22} M23:{M23} M24:{M24}}} {{M31:{M31} M32:{M32} M33:{M33} M34:{M34}}} {{M41:{M41} M42:{M42} M43:{M43} M44:{M44}}} }}");

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
            hash = hash * 23 + M11.GetHashCode();
            hash = hash * 23 + M12.GetHashCode();
            hash = hash * 23 + M13.GetHashCode();
            hash = hash * 23 + M14.GetHashCode();
            hash = hash * 23 + M21.GetHashCode();
            hash = hash * 23 + M22.GetHashCode();
            hash = hash * 23 + M23.GetHashCode();
            hash = hash * 23 + M24.GetHashCode();
            hash = hash * 23 + M31.GetHashCode();
            hash = hash * 23 + M32.GetHashCode();
            hash = hash * 23 + M33.GetHashCode();
            hash = hash * 23 + M34.GetHashCode();
            hash = hash * 23 + M41.GetHashCode();
            hash = hash * 23 + M42.GetHashCode();
            hash = hash * 23 + M43.GetHashCode();
            hash = hash * 23 + M44.GetHashCode();
            return hash;
        }
    }

    /// <summary>
    /// Determines whether the specified <see cref="Matrix"/> is equal to this instance.
    /// </summary>
    /// <param name="other">The <see cref="Matrix"/> to compare with this instance.</param>
    /// <returns>
    /// <c>true</c> if the specified <see cref="Matrix"/> is equal to this instance; otherwise, <c>false</c>.
    /// </returns>
    public bool Equals(Matrix other)
    {
        return Math.Abs(other.M11 - M11) < MathUtil.ZeroTolerance &&
            Math.Abs(other.M12 - M12) < MathUtil.ZeroTolerance &&
            Math.Abs(other.M13 - M13) < MathUtil.ZeroTolerance &&
            Math.Abs(other.M14 - M14) < MathUtil.ZeroTolerance &&

            Math.Abs(other.M21 - M21) < MathUtil.ZeroTolerance &&
            Math.Abs(other.M22 - M22) < MathUtil.ZeroTolerance &&
            Math.Abs(other.M23 - M23) < MathUtil.ZeroTolerance &&
            Math.Abs(other.M24 - M24) < MathUtil.ZeroTolerance &&

            Math.Abs(other.M31 - M31) < MathUtil.ZeroTolerance &&
            Math.Abs(other.M32 - M32) < MathUtil.ZeroTolerance &&
            Math.Abs(other.M33 - M33) < MathUtil.ZeroTolerance &&
            Math.Abs(other.M34 - M34) < MathUtil.ZeroTolerance &&

            Math.Abs(other.M41 - M41) < MathUtil.ZeroTolerance &&
            Math.Abs(other.M42 - M42) < MathUtil.ZeroTolerance &&
            Math.Abs(other.M43 - M43) < MathUtil.ZeroTolerance &&
            Math.Abs(other.M44 - M44) < MathUtil.ZeroTolerance;
    }
}
