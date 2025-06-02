using System;
// Copyright (c) .NET Foundation and Contributors (https://dotnetfoundation.org/ & https://stride3d.net)
// Distributed under the MIT license. See the LICENSE.md file in the project root for more information.

namespace Sedulous.Mathematics.Tests;

public class TestQuaternion
{
    /* Note: As seen in the TestCompose* tests, we check both expectedQuat == decompedQuat and expectedQuat == -decompedQuat
     * This is because different combinations of yaw/pitch/roll can result in the same *orientation*, which is what we're actually testing.
     * This means that decomposing a rotation matrix or quaternion can actually have multiple answers, but we arbitrarily pick
     * one result, and this may not have actually been the original yaw/pitch/roll the user chose.
     */

    [Test]
    public static void TestDecomposeYawPitchRollFromQuaternionYPR(float yawDegrees, float pitchDegrees, float rollDegrees)
    {
        var yawRadians = MathUtil.DegreesToRadians(yawDegrees);
        var pitchRadians = MathUtil.DegreesToRadians(pitchDegrees);
        var rollRadians = MathUtil.DegreesToRadians(rollDegrees);

        var rotQuat = Quaternion.RotationYawPitchRoll(yawRadians, pitchRadians, rollRadians);
		float decomposedYaw;
		float decomposedPitch;
		float decomposedRoll;
        Quaternion.RotationYawPitchRoll(rotQuat, out decomposedYaw, out decomposedPitch, out decomposedRoll);

        var expectedQuat = rotQuat;
        var decompedQuat = Quaternion.RotationYawPitchRoll(decomposedYaw, decomposedPitch, decomposedRoll);
        Test.Assert(expectedQuat == decompedQuat || expectedQuat == -decompedQuat/*, $"Quat not equals: Expected: {expectedQuat} - Actual: {decompedQuat}"*/);
    }

    [Test]
    public static void TestDecomposeYawPitchRollFromQuaternionYXZ(float yawDegrees, float pitchDegrees, float rollDegrees)
    {
        var yawRadians = MathUtil.DegreesToRadians(yawDegrees);
        var pitchRadians = MathUtil.DegreesToRadians(pitchDegrees);
        var rollRadians = MathUtil.DegreesToRadians(rollDegrees);

        var rotX = Quaternion.RotationX(pitchRadians);
        var rotY = Quaternion.RotationY(yawRadians);
        var rotZ = Quaternion.RotationZ(rollRadians);
        // Yaw-Pitch-Roll is the intrinsic rotation order, so extrinsic is the reverse (ie. Z-X-Y)
        var rotQuat = rotZ * rotX * rotY;
		float decomposedYaw;
		float decomposedPitch;
		float decomposedRoll;
        Quaternion.RotationYawPitchRoll(rotQuat, out decomposedYaw, out decomposedPitch, out decomposedRoll);

        var expectedQuat = rotQuat;
        var decompRotX = Quaternion.RotationX(decomposedPitch);
        var decompRotY = Quaternion.RotationY(decomposedYaw);
        var decompRotZ = Quaternion.RotationZ(decomposedRoll);
        var decompedQuat = decompRotZ * decompRotX * decompRotY;
        Test.Assert(expectedQuat == decompedQuat || expectedQuat == -decompedQuat/*, $"Quat not equals: Expected: {expectedQuat} - Actual: {decompedQuat}"*/);
    }
}
