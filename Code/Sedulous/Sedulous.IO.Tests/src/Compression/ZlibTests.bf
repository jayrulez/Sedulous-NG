using System;
using System.Collections;
using Sedulous.IO.Compression;

namespace Sedulous.Tests;

public static class ZlibTests
{
	[Test] public static void TestAdler32()
	{
		Console.WriteLine("=== Testing Adler-32 ===");

		// Test empty data
		var empty = scope uint8[0];
		var checksum = Adler32.Calculate(empty);
		Test.Assert(1u == checksum, "Empty data Adler-32 should be 1");

		// Test known values
		var helloWorld = scope uint8[](.('H'), .('e'), .('l'), .('l'), .('o'), .(' '), .('W'), .('o'), .('r'), .('l'), .('d'));
		checksum = Adler32.Calculate(helloWorld);
		Test.Assert(checksum > 1, "Hello World should have non-trivial checksum");

		// Test single byte
		var singleByte = scope uint8[](65); // 'A'
		checksum = Adler32.Calculate(singleByte);
		Test.Assert(4325442u == checksum, "Single byte 'A' checksum");

		// Test that different data produces different checksums
		var data1 = scope uint8[](1, 2, 3, 4, 5);
		var data2 = scope uint8[](5, 4, 3, 2, 1);
		var checksum1 = Adler32.Calculate(data1);
		var checksum2 = Adler32.Calculate(data2);
		Test.Assert(checksum1 != checksum2, "Different data should have different checksums");
	}

	[Test] public static void TestEmptyData()
	{
		Console.WriteLine("\n=== Testing Empty Data ===");

		var input = scope uint8[0];
		var compressed = scope List<uint8>();
		var decompressed = scope List<uint8>();

		var compressResult = Zlib.Compress(input, compressed);
		Test.Assert(Zlib.Result.Success == compressResult, "Empty data compression should succeed");

		var decompressResult = Zlib.Decompress(compressed, decompressed);
		Test.Assert(Zlib.Result.Success == decompressResult, "Empty data decompression should succeed");

		Test.Assert(0 == decompressed.Count, "Decompressed empty data should be empty");
	}

	[Test] public static void TestSmallData()
	{
		Console.WriteLine("\n=== Testing Small Data ===");

		var input = scope uint8[](.('H'), .('e'), .('l'), .('l'), .('o'));
		var compressed = scope List<uint8>();
		var decompressed = scope List<uint8>();

		var compressResult = Zlib.Compress(input, compressed);
		Test.Assert(Zlib.Result.Success == compressResult, "Small data compression should succeed");

		Test.Assert(compressed.Count > 6, "Compressed data should include zlib header and checksum");

		var decompressResult = Zlib.Decompress(compressed, decompressed);
		Test.Assert(Zlib.Result.Success == decompressResult, "Small data decompression should succeed");

		Test.Assert(input.Count == decompressed.Count, "Decompressed size should match original");

		// Verify content
		bool contentMatches = true;
		for (int i = 0; i < input.Count; i++)
		{
			if (input[i] != decompressed[i])
			{
				contentMatches = false;
				break;
			}
		}
		Test.Assert(contentMatches, "Decompressed content should match original");
	}

	[Test] public static void TestRepeatingData()
	{
		Console.WriteLine("\n=== Testing Repeating Data ===");

		// Create data with lots of repetition (should compress well)
		var input = scope uint8[1000];
		for (int i = 0; i < input.Count; i++)
			input[i] = (uint8)(i % 10);

		var compressed = scope List<uint8>();
		var decompressed = scope List<uint8>();

		var compressResult = Zlib.Compress(input, compressed);
		Test.Assert(Zlib.Result.Success == compressResult, "Repeating data compression should succeed");

		var decompressResult = Zlib.Decompress(compressed, decompressed);
		Test.Assert(Zlib.Result.Success == decompressResult, "Repeating data decompression should succeed");

		Test.Assert(input.Count == decompressed.Count, "Decompressed size should match original");

		// Verify content
		bool contentMatches = true;
		for (int i = 0; i < input.Count; i++)
		{
			if (input[i] != decompressed[i])
			{
				contentMatches = false;
				break;
			}
		}
		Test.Assert(contentMatches, "Decompressed repeating data should match original");
	}

	[Test] public static void TestRandomData()
	{
		Console.WriteLine("\n=== Testing Random Data ===");

		// Create pseudo-random data
		var input = scope uint8[500];
		uint32 seed = 12345;
		for (int i = 0; i < input.Count; i++)
		{
			seed = seed * 1103515245 + 12345; // Simple LCG
			input[i] = (uint8)(seed >> 16);
		}

		var compressed = scope List<uint8>();
		var decompressed = scope List<uint8>();

		var compressResult = Zlib.Compress(input, compressed);
		Test.Assert(Zlib.Result.Success == compressResult, "Random data compression should succeed");

		var decompressResult = Zlib.Decompress(compressed, decompressed);
		Test.Assert(Zlib.Result.Success == decompressResult, "Random data decompression should succeed");

		Test.Assert(input.Count == decompressed.Count, "Decompressed size should match original");

		// Verify content
		bool contentMatches = true;
		for (int i = 0; i < input.Count; i++)
		{
			if (input[i] != decompressed[i])
			{
				contentMatches = false;
				break;
			}
		}
		Test.Assert(contentMatches, "Decompressed random data should match original");
	}

	[Test] public static void TestLargeData()
	{
		Console.WriteLine("\n=== Testing Large Data ===");

		// Create larger data set (multiple blocks)
		var input = scope uint8[100000];
		for (int i = 0; i < input.Count; i++)
			input[i] = (uint8)(i & 0xFF);

		var compressed = scope List<uint8>();
		var decompressed = scope List<uint8>();

		var compressResult = Zlib.Compress(input, compressed);
		Test.Assert(Zlib.Result.Success == compressResult, "Large data compression should succeed");

		var decompressResult = Zlib.Decompress(compressed, decompressed);
		Test.Assert(Zlib.Result.Success == decompressResult, "Large data decompression should succeed");

		Test.Assert(input.Count == decompressed.Count, "Large decompressed size should match original");

		// Sample check (checking every byte would be slow)
		bool sampleMatches = true;
		for (int i = 0; i < input.Count; i += 1000) // Check every 1000th byte
		{
			if (input[i] != decompressed[i])
			{
				sampleMatches = false;
				break;
			}
		}
		Test.Assert(sampleMatches, "Large decompressed data sample should match original");
	}

	[Test] public static void TestInvalidData()
	{
		Console.WriteLine("\n=== Testing Invalid Data ===");

		var decompressed = scope List<uint8>();

		// Test completely invalid data
		var invalidData = scope uint8[](0xFF, 0xFF, 0xFF, 0xFF);
		var result = Zlib.Decompress(invalidData, decompressed);
		Test.Assert(Zlib.Result.Success != result, "Invalid data should fail decompression");

		// Test data too short
		var tooShort = scope uint8[](0x78, 0x9C); // Just header
		result = Zlib.Decompress(tooShort, decompressed);
		Test.Assert(Zlib.Result.Success != result, "Too short data should fail decompression");

		// Test invalid compression method
		var invalidCM = scope uint8[](0x77, 0x9C, 0x00, 0x00, 0x00, 0x01); // CM=7 instead of 8
		result = Zlib.Decompress(invalidCM, decompressed);
		Test.Assert(Zlib.Result.Success != result, "Invalid compression method should fail");
	}

	[Test] public static void TestCorruptedChecksum()
	{
		Console.WriteLine("\n=== Testing Corrupted Checksum ===");

		// Create valid compressed data
		var input = scope uint8[](.('T'), .('e'), .('s'), .('t'));
		var compressed = scope List<uint8>();
		Zlib.Compress(input, compressed);

		// Corrupt the last byte (part of Adler-32 checksum)
		compressed[compressed.Count - 1] = (uint8)(compressed[compressed.Count - 1] ^ 0xFF);

		var decompressed = scope List<uint8>();
		var result = Zlib.Decompress(compressed, decompressed);
		Test.Assert(Zlib.Result.InvalidChecksum == result, "Corrupted checksum should be detected");
	}

	[Test] public static void TestTruncatedData()
	{
		Console.WriteLine("\n=== Testing Truncated Data ===");

		// Create valid compressed data
		var input = scope uint8[](.('T'), .('e'), .('s'), .('t'), .('i'), .('n'), .('g'));
		var compressed = scope List<uint8>();
		Zlib.Compress(input, compressed);

		// Truncate the data
		var truncated = scope uint8[compressed.Count - 2];
		compressed[0 ..< truncated.Count].CopyTo(truncated);

		var decompressed = scope List<uint8>();
		var result = Zlib.Decompress(truncated, decompressed);
		Test.Assert(Zlib.Result.Success != result, "Truncated data should fail decompression");
	}

	[Test] public static void TestCompressionLevels()
	{
		Console.WriteLine("\n=== Testing Compression Levels ===");

		var input = scope uint8[1000];
		for (int i = 0; i < input.Count; i++)
			input[i] = (uint8)(i % 50); // Some repetition for compression

		var levels = scope Zlib.CompressionLevel[](.NoCompression, .BestSpeed, .Default, .BestCompression);

		for (var level in levels)
		{
			var compressed = scope List<uint8>();
			var decompressed = scope List<uint8>();

			var compressResult = Zlib.Compress(input, compressed, level);
			Test.Assert(Zlib.Result.Success == compressResult, scope $"Compression level {level} should succeed");

			var decompressResult = Zlib.Decompress(compressed, decompressed);
			Test.Assert(Zlib.Result.Success == decompressResult, scope $"Decompression of level {level} should succeed");

			Test.Assert(input.Count == decompressed.Count, scope $"Size should match for level {level}");
		}
	}

	[Test] public static void TestRoundTripVariousPatterns()
	{
		Console.WriteLine("\n=== Testing Various Patterns ===");

		// Test all zeros
		TestPattern("All zeros", scope uint8[100]);

		// Test all ones
		var allOnes = scope uint8[100];
		Internal.MemSet(allOnes.Ptr, 0xFF, allOnes.Count);
		TestPattern("All ones", allOnes);

		// Test alternating pattern
		var alternating = scope uint8[100];
		for (int i = 0; i < alternating.Count; i++)
			alternating[i] = (uint8)((i % 2) == 0 ? 0xAA : 0x55);
		TestPattern("Alternating", alternating);

		// Test gradient
		var gradient = scope uint8[256];
		for (int i = 0; i < gradient.Count; i++)
			gradient[i] = (uint8)i;
		TestPattern("Gradient", gradient);

		// Test single repeated byte
		var repeated = scope uint8[500];
		Internal.MemSet(repeated.Ptr, 42, repeated.Count);
		TestPattern("Single repeated byte", repeated);
	}

	private static void TestPattern(String patternName, Span<uint8> input)
	{
		var compressed = scope List<uint8>();
		var decompressed = scope List<uint8>();

		var compressResult = Zlib.Compress(input, compressed);
		Test.Assert(Zlib.Result.Success == compressResult, scope $"{patternName} compression should succeed");

		var decompressResult = Zlib.Decompress(compressed, decompressed);
		Test.Assert(Zlib.Result.Success == decompressResult, scope $"{patternName} decompression should succeed");

		Test.Assert(input.Length == decompressed.Count, scope $"{patternName} size should match");

		// Verify content
		bool matches = true;
		for (int i = 0; i < input.Length; i++)
		{
			if (input[i] != decompressed[i])
			{
				matches = false;
				break;
			}
		}
		Test.Assert(matches, scope $"{patternName} content should match");
	}
}