using System;
namespace Sedulous.Imaging.Tests;

// PNG filter tests for completeness
public static class PngFilterTests
{
	[Test] public static void TestSubFilter()
	{
		Console.WriteLine("=== Testing Sub Filter ===");

		// Test data: each pixel affects the next
		var row = scope uint8[](10, 20, 30, 15, 25, 35); // 2 RGB pixels
		var expected = scope uint8[](10, 20, 30, 25, 45, 65); // Second pixel += first pixel

		ApplySubFilter(row, 3); // 3 bytes per pixel

		bool matches = true;
		for (int i = 0; i < row.Count; i++)
		{
			if (row[i] != expected[i])
			{
				matches = false;
				break;
			}
		}
		Test.Assert(matches, "Sub filter should add left pixel values");
	}

	[Test] public static void TestUpFilter()
	{
		Console.WriteLine("\n=== Testing Up Filter ===");

		var row = scope uint8[](10, 20, 30);
		var prevRow = scope uint8[](5, 15, 25);
		var expected = scope uint8[](15, 35, 55);

		ApplyUpFilter(row, prevRow);

		bool matches = true;
		for (int i = 0; i < row.Count; i++)
		{
			if (row[i] != expected[i])
			{
				matches = false;
				break;
			}
		}
		Test.Assert(matches, "Up filter should add upper pixel values");
	}

	[Test] public static void TestAverageFilter()
	{
		Console.WriteLine("\n=== Testing Average Filter ===");

		var row = scope uint8[](10, 20, 30, 5, 10, 15);
		var prevRow = scope uint8[](4, 8, 12, 2, 4, 6);

		ApplyAverageFilter(row, prevRow, 3);

		// First pixel: add average of (0, prevRow) = (0+4)/2, (0+8)/2, (0+12)/2 = 2, 4, 6
		// Second pixel: add average of (firstPixel, prevRow) = (12+2)/2, (24+4)/2, (36+6)/2 = 7, 14, 21
		var expectedFirst = scope uint8[](12, 24, 36); // 10+2, 20+4, 30+6

		Test.Assert(expectedFirst[0] == row[0], "Average filter first pixel R");
		Test.Assert(expectedFirst[1] == row[1], "Average filter first pixel G");
		Test.Assert(expectedFirst[2] == row[2], "Average filter first pixel B");
	}

	[Test] public static void TestPaethFilter()
	{
		Console.WriteLine("\n=== Testing Paeth Filter ===");

		var row = scope uint8[](10, 5);
		var prevRow = scope uint8[](8, 12);

		ApplyPaethFilter(row, prevRow, 1);

		// First pixel: Paeth(0, 8, 0) = 8 (up value is closest), so 10 + 8 = 18
		// Second pixel: Paeth(18, 12, 8) - calculate manually
		Test.Assert(18u == row[0], "Paeth filter first pixel");
	}

	[Test] public static void TestPaethPredictor()
	{
	   Console.WriteLine("\n=== Testing Paeth Predictor ===");
	   // Test case where a is closest
	   uint8 result = PaethPredictor(100, 50, 60);
	   Test.Assert(100u == result, "Paeth should return a when a is closest");
	   // Test case where b is closest
	   result = PaethPredictor(50, 100, 60);
	   Test.Assert(100u == result, "Paeth should return b when b is closest");
	   // Test case where c is closest
	   result = PaethPredictor(10, 20, 15);
	   Test.Assert(15u == result, "Paeth should return c when c is closest");
	}

	// Helper methods (simplified versions of the PNG filter functions)
	private static void ApplySubFilter(Span<uint8> row, int bytesPerPixel)
	{
		for (int i = bytesPerPixel; i < row.Length; i++)
		{
			row[i] = (uint8)(row[i] + row[i - bytesPerPixel]);
		}
	}

	private static void ApplyUpFilter(Span<uint8> row, Span<uint8> prevRow)
	{
		for (int i = 0; i < row.Length; i++)
		{
			row[i] = (uint8)(row[i] + prevRow[i]);
		}
	}

	private static void ApplyAverageFilter(Span<uint8> row, Span<uint8> prevRow, int bytesPerPixel)
	{
		for (int i = 0; i < row.Length; i++)
		{
			uint8 left = (i >= bytesPerPixel) ? row[i - bytesPerPixel] : 0;
			uint8 up = prevRow[i];
			row[i] = (uint8)(row[i] + ((left + up) / 2));
		}
	}

	private static void ApplyPaethFilter(Span<uint8> row, Span<uint8> prevRow, int bytesPerPixel)
	{
		for (int i = 0; i < row.Length; i++)
		{
			uint8 left = (i >= bytesPerPixel) ? row[i - bytesPerPixel] : 0;
			uint8 up = prevRow[i];
			uint8 upLeft = (i >= bytesPerPixel) ? prevRow[i - bytesPerPixel] : 0;

			uint8 paeth = PaethPredictor(left, up, upLeft);
			row[i] = (uint8)(row[i] + paeth);
		}
	}

	private static uint8 PaethPredictor(uint8 a, uint8 b, uint8 c)
	{
		int p = a + b - c;
		int pa = Math.Abs(p - a);
		int pb = Math.Abs(p - b);
		int pc = Math.Abs(p - c);

		if (pa <= pb && pa <= pc)
			return a;
		else if (pb <= pc)
			return b;
		else
			return c;
	}
}