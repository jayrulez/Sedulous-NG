using System;
// Copyright (c) .NET Foundation and Contributors (https://dotnetfoundation.org/ & https://stride3d.net) and Silicon Studio Corp. (https://www.siliconstudio.co.jp)
// Distributed under the MIT license. See the LICENSE.md file in the project root for more information.
namespace Sedulous.Mathematics.Tests;

public class TestColor
{
    [Test]
    public void TestRGB2HSVConversion()
    {
        Test.Assert(ColorHSV(312, 1, 1, 1) == ColorHSV.FromColor(Color4(1, 0, 0.8f, 1)));
        Test.Assert(ColorHSV(0, 0, 0, 1) == ColorHSV.FromColor(Color.Black));
        Test.Assert(ColorHSV(0, 0, 1, 1) == ColorHSV.FromColor(Color.White));
        Test.Assert(ColorHSV(0, 1, 1, 1) == ColorHSV.FromColor(Color.Red));
        Test.Assert(ColorHSV(120, 1, 1, 1) == ColorHSV.FromColor(Color.Lime));
        Test.Assert(ColorHSV(240, 1, 1, 1) == ColorHSV.FromColor(Color.Blue));
        Test.Assert(ColorHSV(60, 1, 1, 1) == ColorHSV.FromColor(Color.Yellow));
        Test.Assert(ColorHSV(180, 1, 1, 1) == ColorHSV.FromColor(Color.Cyan));
        Test.Assert(ColorHSV(300, 1, 1, 1) == ColorHSV.FromColor(Color.Magenta));
        Test.Assert(ColorHSV(0, 0, 0.7529412f, 1) == ColorHSV.FromColor(Color.Silver));
        Test.Assert(ColorHSV(0, 0, 0.5019608f, 1) == ColorHSV.FromColor(Color.Gray));
        Test.Assert(ColorHSV(0, 1, 0.5019608f, 1) == ColorHSV.FromColor(Color.Maroon));
    }

    [Test]
    public void TestHSV2RGBConversion()
    {
        Test.Assert(Color.Black.ToColor4() == ColorHSV.FromColor(Color.Black).ToColor());
        Test.Assert(Color.White.ToColor4() == ColorHSV.FromColor(Color.White).ToColor());
        Test.Assert(Color.Red.ToColor4() == ColorHSV.FromColor(Color.Red).ToColor());
        Test.Assert(Color.Lime.ToColor4() == ColorHSV.FromColor(Color.Lime).ToColor());
        Test.Assert(Color.Blue.ToColor4() == ColorHSV.FromColor(Color.Blue).ToColor());
        Test.Assert(Color.Silver.ToColor4() == ColorHSV.FromColor(Color.Silver).ToColor());
        Test.Assert(Color.Maroon.ToColor4() == ColorHSV.FromColor(Color.Maroon).ToColor());
        Test.Assert(Color(184, 209, 219, 255).ToRgba() == ColorHSV.FromColor(Color(184, 209, 219, 255)).ToColor().ToRgba());
    }
}
