// Copyright (c) .NET Foundation and Contributors (https://dotnetfoundation.org/ & https://stride3d.net)
// Distributed under the MIT license. See the LICENSE.md file in the project root for more information.

using System.Collections;
using System;

namespace Sedulous.Mathematics.Tests;

public static class TestRotationsData
{
    private static readonly float[] PrimaryAnglesToTest = new
    .(
        // +/-90 are the singularities, but test other angles for coverage
        -180, -90, -30, 0f, 30, 90, 180
    ) ~ delete _;

    public class YRPTestData : IEnumerable<Object[]>
    {
        public IEnumerator<Object[]> GetEnumerator()
        {
            var result = new List<Object[]>();
            for (var pitchDegrees in PrimaryAnglesToTest)
            {
                // For yaw/pitch/roll tests, the second rotation axis contains the singularity issue (ie. pitch/X-axis)
                // Yaw & Roll are arbitrary non-zero values to ensure the rotation are working correctly
                const float yawDegrees = 45;
                const float rollDegrees = -90;
                result.Add(new .(yawDegrees, pitchDegrees, rollDegrees));
            }
            // For completeness, also test the pitch rotation at singularities by itself
            result.Add(new .(0, -90, 0));
            result.Add(new .(0, 90, 0));

            return new box result.GetEnumerator();
        }
    }

    public class XYZTestData : IEnumerable<Object[]>
    {
        public IEnumerator<Object[]> GetEnumerator()
        {
            var result = new List<Object[]>();
            for (var yawDegrees in PrimaryAnglesToTest)
            {
                // For XYZ tests, the second rotation axis contains the singularity issue (ie. yaw/Y-axis)
                // Pitch & Roll are arbitrary non-zero values to ensure the rotation are working correctly
                const float pitchDegrees = 45;
                const float rollDegrees = -90;
                result.Add(new .(yawDegrees, pitchDegrees, rollDegrees));
            }
            // For completeness, also test the yaw rotation at singularities by itself
            result.Add(new .(-90, 0, 0));
            result.Add(new .(90, 0, 0));

            return new box result.GetEnumerator();
        }
    }
}
