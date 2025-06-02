using System;

namespace Sedulous.Mathematics.Tests;

public class TestPoint
{
    static readonly Point testPoint1 = .(5, 5);
    static readonly Point testPoint2 = .(10, 10);
    static readonly Point testPoint3 = .(5, 5);

    [Test]
    public void TestPointsNotEqual()
    {
        Test.Assert(testPoint1 != testPoint2);
    }

    [Test]
    public void TestPointsEqual()
    {
        Test.Assert(testPoint1 == testPoint3);
    }
}
