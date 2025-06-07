using System;
using System.Collections;
using Sedulous.Imaging;
using Sedulous.Mathematics;
using Sedulous.IO.Compression;

namespace Sedulous.Imaging.Tests;

public static class PngLoaderTests
{
	[Test] public static void TestPngSignatureValidation()
	{
		Console.WriteLine("=== Testing PNG Signature Validation ===");

		var loader = scope PngLoader();

		// Valid PNG signature
		var validSig = scope uint8[](0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A);
		var result = loader.LoadFromMemory(validSig);
		if (result case .Ok(var loadInfo))
		{
			Test.Assert(loadInfo.Result != .UnsupportedFormat,
				"Valid signature should not fail with UnsupportedFormat");
			loadInfo.Dispose();
		}
	}

	[Test] public static void TestInvalidPngSignature()
	{
		Console.WriteLine("=== Testing Invalid PNG Signature ===");

		var loader = scope PngLoader();

		// Invalid signature
		{
			var invalidSig = scope uint8[](0x00, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A);
			var result = loader.LoadFromMemory(invalidSig);
			if (result case .Ok(var loadInfo))
			{
				Test.Assert(loadInfo.Result == .UnsupportedFormat,
					"Invalid signature should fail with UnsupportedFormat");
				loadInfo.Dispose();
			}
		}

		// Too short for signature
		{
			var tooShort = scope uint8[](0x89, 0x50, 0x4E);
			var result = loader.LoadFromMemory(tooShort);
			if (result case .Ok(var loadInfo))
			{
				Test.Assert(loadInfo.Result != .Success, "Too short data should fail");
				loadInfo.Dispose();
			}
		}
	}

	[Test] public static void TestMissingIHDRChunk()
	{
		Console.WriteLine("=== Testing Missing IHDR Chunk ===");

		var pngData = scope List<uint8>();
		AddPngSignature(pngData);

		// Add a non-IHDR chunk
		AddChunk(pngData, "tEXt", scope uint8[](.('H'), .('i')));
		AddChunk(pngData, "IEND", scope uint8[0]);

		var loader = scope PngLoader();
		var result = loader.LoadFromMemory(pngData);
		if (result case .Ok(var loadInfo))
		{
			Test.Assert(loadInfo.Result == .CorruptedData,
				"Missing IHDR should fail with CorruptedData");
			loadInfo.Dispose();
		}
	}

	[Test] public static void TestInvalidImageDimensions()
	{
		Console.WriteLine("=== Testing Invalid Image Dimensions ===");

		var loader = scope PngLoader();

		// Test zero width
		{
			var pngData = CreateMinimalPng(0, 100, 2, 8, .. scope .()); // RGB, 8-bit
			var result = loader.LoadFromMemory(pngData);
			if (result case .Ok(var loadInfo))
			{
				Test.Assert(loadInfo.Result == .InvalidDimensions, "Zero width should fail");
				loadInfo.Dispose();
			}
		}

		// Test zero height
		{
			var pngData = CreateMinimalPng(100, 0, 2, 8, .. scope .()); // RGB, 8-bit
			var result = loader.LoadFromMemory(pngData);
			if (result case .Ok(var loadInfo))
			{
				Test.Assert(loadInfo.Result == .InvalidDimensions, "Zero height should fail");
				loadInfo.Dispose();
			}
		}
	}

	[Test] public static void TestUnsupportedColorTypes()
	{
		Console.WriteLine("=== Testing Unsupported Color Types ===");

		var loader = scope PngLoader();

		// Test palette color type (3) - not supported
		{
			var pngData = CreateMinimalPng(10, 10, 3, 8, .. scope .());
			var result = loader.LoadFromMemory(pngData);
			if (result case .Ok(var loadInfo))
			{
				Test.Assert(loadInfo.Result == .UnsupportedFormat,
					"Palette color type should be unsupported");
				loadInfo.Dispose();
			}
		}

		// Test grayscale+alpha color type (4) - not supported
		{
			var pngData = CreateMinimalPng(10, 10, 4, 8, .. scope .());
			var result = loader.LoadFromMemory(pngData);
			if (result case .Ok(var loadInfo))
			{
				Test.Assert(loadInfo.Result == .UnsupportedFormat,
					"Grayscale+alpha color type should be unsupported");
				loadInfo.Dispose();
			}
		}
	}

	[Test] public static void TestUnsupportedBitDepth()
	{
		Console.WriteLine("=== Testing Unsupported Bit Depth ===");

		var loader = scope PngLoader();

		// Test 16-bit depth
		{
			var pngData = CreateMinimalPng(10, 10, 2, 16, .. scope .()); // RGB, 16-bit
			var result = loader.LoadFromMemory(pngData);
			if (result case .Ok(var loadInfo))
			{
				Test.Assert(loadInfo.Result == .UnsupportedFormat,
					"16-bit depth should be unsupported");
				loadInfo.Dispose();
			}
		}

		// Test 1-bit depth
		{
			var pngData = CreateMinimalPng(10, 10, 0, 1, .. scope .()); // Grayscale, 1-bit
			var result = loader.LoadFromMemory(pngData);
			if (result case .Ok(var loadInfo))
			{
				Test.Assert(loadInfo.Result == .UnsupportedFormat,
					"1-bit depth should be unsupported");
				loadInfo.Dispose();
			}
		}
	}

	[Test] public static void TestMinimalValidPng()
	{
		Console.WriteLine("=== Testing Minimal Valid PNG ===");

		var loader = scope PngLoader();

		// Create minimal valid RGB PNG
		var pngData = CreateValidPng(2, 2, 2, 8, scope uint8[](
		    0,           // Row 1 filter byte
		    255, 0, 0,   // Pixel 1: Red
		    0, 255, 0,   // Pixel 2: Green
		    0,           // Row 2 filter byte  
		    0, 0, 0,     // Pixel 3: Black
		    255, 255, 255 // Pixel 4: White
		), .. scope .());

		var result = loader.LoadFromMemory(pngData);
		if (result case .Ok(var loadInfo))
		{
			Test.Assert(loadInfo.Result == .Success, "Valid PNG should load successfully");
			Test.Assert(loadInfo.Width == 2, "Width should be 2");
			Test.Assert(loadInfo.Height == 2, "Height should be 2");
			Test.Assert(loadInfo.Format == .RGB8, "Format should be RGB8");
			Test.Assert(loadInfo.Data != null, "Data should not be null");
			Test.Assert(loadInfo.Data.Count == 12, "Should have 12 bytes (2x2x3)");
			loadInfo.Dispose();
		}
		else
		{
			Test.Assert(false, "Should successfully parse valid PNG");
		}
	}

	[Test] public static void TestRgb8Png()
	{
		Console.WriteLine("=== Testing RGB8 PNG ===");

		var loader = scope PngLoader();
		var pngData = CreateValidPng(1, 1, 2, 8, scope uint8[](0, 255, 128, 64), .. scope .()); // 1 pixel RGB

		var result = loader.LoadFromMemory(pngData);
		if (result case .Ok(var loadInfo))
		{
			Test.Assert(loadInfo.Result == .Success, "RGB8 PNG should succeed");
			Test.Assert(loadInfo.Format == .RGB8, "Should be RGB8 format");
			Test.Assert(loadInfo.Data.Count == 3, "Should have 3 bytes for 1 RGB pixel");
			loadInfo.Dispose();
		}
	}

	[Test] public static void TestRgba8Png()
	{
		Console.WriteLine("=== Testing RGBA8 PNG ===");

		var loader = scope PngLoader();
		var pngData = CreateValidPng(1, 1, 6, 8, scope uint8[](0, 255, 128, 64, 200), .. scope .()); // 1 pixel RGBA

		var result = loader.LoadFromMemory(pngData);
		if (result case .Ok(var loadInfo))
		{
			Test.Assert(loadInfo.Result == .Success, "RGBA8 PNG should succeed");
			Test.Assert(loadInfo.Format == .RGBA8, "Should be RGBA8 format");
			Test.Assert(loadInfo.Data.Count == 4, "Should have 4 bytes for 1 RGBA pixel");
			loadInfo.Dispose();
		}
	}

	[Test] public static void TestGrayscalePng()
	{
		Console.WriteLine("=== Testing Grayscale PNG ===");

		var loader = scope PngLoader();
		var pngData = CreateValidPng(2, 1, 0, 8, scope uint8[](0, 128, 255), .. scope .()); // 2 grayscale pixels

		var result = loader.LoadFromMemory(pngData);
		if (result case .Ok(var loadInfo))
		{
			Test.Assert(loadInfo.Result == .Success, "Grayscale PNG should succeed");
			Test.Assert(loadInfo.Format == .R8, "Should be R8 format");
			Test.Assert(loadInfo.Data.Count == 2, "Should have 2 bytes for 2 grayscale pixels");
			loadInfo.Dispose();
		}
	}

	[Test] public static void TestChunkParsing()
	{
	    Console.WriteLine("=== Testing Chunk Parsing ===");

	    var pngData = scope List<uint8>();
	    AddPngSignature(pngData);

	    // Add IHDR for 1x1 grayscale (easier to create valid data for)
	    var ihdrData = scope List<uint8>();
	    WriteBigEndian32(ihdrData, 1); // Width = 1
	    WriteBigEndian32(ihdrData, 1); // Height = 1
	    ihdrData.Add(8); // Bit depth
	    ihdrData.Add(0); // Color type grayscale (1 byte per pixel)
	    ihdrData.Add(0); // Compression
	    ihdrData.Add(0); // Filter
	    ihdrData.Add(0); // Interlace
	    AddChunk(pngData, "IHDR", ihdrData);

	    // Add some other chunks that should be ignored
	    AddChunk(pngData, "tEXt", scope uint8[](.('H'), .('i')));
	    AddChunk(pngData, "bKGD", scope uint8[](255, 255, 255));

	    // Add IDAT with data for 1x1 grayscale pixel
	    var pixelData = scope uint8[](0, 128); // Filter byte + 1 grayscale pixel
	    var idatData = CreateValidDeflateStreamForPixelData(pixelData, .. scope .());
	    AddChunk(pngData, "IDAT", idatData);

	    // Add IEND
	    AddChunk(pngData, "IEND", scope uint8[0]);

	    var loader = scope PngLoader();
	    var result = loader.LoadFromMemory(pngData);
	    if (result case .Ok(var loadInfo))
	    {
	        // Should parse successfully even with extra chunks
	        Test.Assert(loadInfo.Result == .Success, "Should handle extra chunks gracefully");
	        loadInfo.Dispose();
	    }
	}

	[Test] public static void TestMultipleIdatChunks()
	{
		Console.WriteLine("=== Testing Multiple IDAT Chunks ===");

		var pngData = scope List<uint8>();
		AddPngSignature(pngData);

		// Add IHDR
		var ihdrData = scope List<uint8>();
		WriteBigEndian32(ihdrData, 1); // Width
		WriteBigEndian32(ihdrData, 1); // Height
		ihdrData.Add(8); // Bit depth
		ihdrData.Add(0); // Color type grayscale
		ihdrData.Add(0); // Compression
		ihdrData.Add(0); // Filter
		ihdrData.Add(0); // Interlace
		AddChunk(pngData, "IHDR", ihdrData);

		// Split IDAT data across multiple chunks
		var fullIdatData = CreateValidDeflateStreamForPixelData(scope uint8[](0, 128), .. scope .()); // 1 grayscale pixel
		
		// Split the data
		int splitPoint = fullIdatData.Count / 2;
		AddChunk(pngData, "IDAT", fullIdatData[0 ..< splitPoint]);
		AddChunk(pngData, "IDAT", fullIdatData[splitPoint...]);

		AddChunk(pngData, "IEND", scope uint8[0]);

		var loader = scope PngLoader();
		var result = loader.LoadFromMemory(pngData);
		if (result case .Ok(var loadInfo))
		{
			Test.Assert(loadInfo.Result == .Success, "Should handle multiple IDAT chunks");
			loadInfo.Dispose();
		}
	}

	[Test] public static void TestTruncatedPng()
	{
		Console.WriteLine("=== Testing Truncated PNG ===");

		var pngData = CreateMinimalPng(10, 10, 2, 8, .. scope .());

		// Truncate the data
		var truncated = scope uint8[pngData.Count - 10];
		pngData[0 ..< truncated.Count].CopyTo(truncated);

		var loader = scope PngLoader();
		var result = loader.LoadFromMemory(truncated);
		if (result case .Ok(var loadInfo))
		{
			Test.Assert(loadInfo.Result != .Success, "Truncated PNG should fail");
			loadInfo.Dispose();
		}
	}

	[Test] public static void TestCorruptedIdat()
	{
		Console.WriteLine("=== Testing Corrupted IDAT ===");

		var pngData = scope List<uint8>();
		AddPngSignature(pngData);

		// Add IHDR for 1x1 grayscale
		var ihdrData = scope List<uint8>();
		WriteBigEndian32(ihdrData, 1); // Width
		WriteBigEndian32(ihdrData, 1); // Height
		ihdrData.Add(8); // Bit depth
		ihdrData.Add(0); // Color type grayscale
		ihdrData.Add(0); // Compression
		ihdrData.Add(0); // Filter
		ihdrData.Add(0); // Interlace
		AddChunk(pngData, "IHDR", ihdrData);

		// Add corrupted IDAT
		AddChunk(pngData, "IDAT", scope uint8[](0xFF, 0xFF, 0xFF, 0xFF));
		AddChunk(pngData, "IEND", scope uint8[0]);

		var loader = scope PngLoader();
		var result = loader.LoadFromMemory(pngData);
		if (result case .Ok(var loadInfo))
		{
			Test.Assert(loadInfo.Result == .CorruptedData, "Corrupted IDAT should fail");
			loadInfo.Dispose();
		}
	}

	[Test] public static void TestMissingIdat()
	{
		Console.WriteLine("=== Testing Missing IDAT ===");

		var pngData = scope List<uint8>();
		AddPngSignature(pngData);

		// Add IHDR
		var ihdrData = scope List<uint8>();
		WriteBigEndian32(ihdrData, 1); // Width
		WriteBigEndian32(ihdrData, 1); // Height
		ihdrData.Add(8); // Bit depth
		ihdrData.Add(0); // Color type grayscale
		ihdrData.Add(0); // Compression
		ihdrData.Add(0); // Filter
		ihdrData.Add(0); // Interlace
		AddChunk(pngData, "IHDR", ihdrData);

		// No IDAT chunk
		AddChunk(pngData, "IEND", scope uint8[0]);

		var loader = scope PngLoader();
		var result = loader.LoadFromMemory(pngData);
		if (result case .Ok(var loadInfo))
		{
			Test.Assert(loadInfo.Result == .CorruptedData, "Missing IDAT should fail");
			loadInfo.Dispose();
		}
	}

	[Test] public static void TestImageLoaderFactory()
	{
		Console.WriteLine("=== Testing ImageLoaderFactory ===");

		// Test extension support
		var extensions = scope List<String>();
		ImageLoaderFactory.GetSupportedExtensions(extensions);

		bool foundPng = false;
		for (var ext in extensions)
		{
			if (ext == ".png")
			{
				foundPng = true;
				break;
			}
		}
		Test.Assert(foundPng, "Factory should support .png extension");

		// Cleanup
		for (var ext in extensions)
			delete ext;
	}

	[Test] public static void TestFileExtensionSupport()
	{
		Console.WriteLine("=== Testing File Extension Support ===");

		var loader = scope PngLoader();

		Test.Assert(loader.SupportsExtension(".png"), "Should support .png extension");
		Test.Assert(loader.SupportsExtension(".PNG"), "Should support .PNG extension (case insensitive)");
		Test.Assert(!loader.SupportsExtension(".jpg"), "Should not support .jpg extension");
		Test.Assert(!loader.SupportsExtension(".bmp"), "Should not support .bmp extension");
		Test.Assert(!loader.SupportsExtension(""), "Should not support empty extension");
	}

	// Helper methods for creating test PNG data
	private static void AddPngSignature(List<uint8> data)
	{
		data.Add(0x89);
		data.Add(0x50);
		data.Add(0x4E);
		data.Add(0x47);
		data.Add(0x0D);
		data.Add(0x0A);
		data.Add(0x1A);
		data.Add(0x0A);
	}

	private static void WriteBigEndian32(List<uint8> data, uint32 value)
	{
		data.Add((uint8)(value >> 24));
		data.Add((uint8)(value >> 16));
		data.Add((uint8)(value >> 8));
		data.Add((uint8)value);
	}

	private static uint32 CalculateCRC32(StringView type, Span<uint8> data)
	{
		// Simple CRC32 implementation for testing
		uint32 crc = 0xFFFFFFFF;

		// Process type
		for (var c in type)
		{
			crc ^= (uint32)c;
			for (int i = 0; i < 8; i++)
			{
				if ((crc & 1) != 0)
					crc = (crc >> 1) ^ 0xEDB88320;
				else
					crc >>= 1;
			}
		}

		// Process data
		for (var b in data)
		{
			crc ^= (uint32)b;
			for (int i = 0; i < 8; i++)
			{
				if ((crc & 1) != 0)
					crc = (crc >> 1) ^ 0xEDB88320;
				else
					crc >>= 1;
			}
		}

		return ~crc;
	}

	private static void AddChunk(List<uint8> pngData, StringView type, Span<uint8> data)
	{
		// Length
		WriteBigEndian32(pngData, (uint32)data.Length);

		// Type
		for (var c in type)
			pngData.Add((uint8)c);

		// Data
		for (var b in data)
			pngData.Add(b);

		// CRC
		uint32 crc = CalculateCRC32(type, data);
		WriteBigEndian32(pngData, crc);
	}

	private static void CreateMinimalPng(uint32 width, uint32 height, uint8 colorType, uint8 bitDepth, List<uint8> result)
	{
		var pngData = scope List<uint8>();
		AddPngSignature(pngData);

		// Add IHDR
		var ihdrData = scope List<uint8>();
		WriteBigEndian32(ihdrData, width);
		WriteBigEndian32(ihdrData, height);
		ihdrData.Add(bitDepth);
		ihdrData.Add(colorType);
		ihdrData.Add(0); // Compression
		ihdrData.Add(0); // Filter
		ihdrData.Add(0); // Interlace
		AddChunk(pngData, "IHDR", ihdrData);

		// Add empty IDAT
		var idatData = CreateEmptyDeflateStream(.. scope .());
		AddChunk(pngData, "IDAT", idatData);

		// Add IEND
		AddChunk(pngData, "IEND", scope uint8[0]);

		pngData.CopyTo(result);
	}

	private static void CreateValidPng(uint32 width, uint32 height, uint8 colorType, uint8 bitDepth, Span<uint8> pixelData, List<uint8> result)
	{
		var pngData = scope List<uint8>();
		AddPngSignature(pngData);

		// Add IHDR
		var ihdrData = scope List<uint8>();
		WriteBigEndian32(ihdrData, width);
		WriteBigEndian32(ihdrData, height);
		ihdrData.Add(bitDepth);
		ihdrData.Add(colorType);
		ihdrData.Add(0); // Compression
		ihdrData.Add(0); // Filter
		ihdrData.Add(0); // Interlace
		AddChunk(pngData, "IHDR", ihdrData);

		// Add IDAT with pixel data
		var idatData = CreateValidDeflateStreamForPixelData(pixelData, .. scope .());
		AddChunk(pngData, "IDAT", idatData);

		// Add IEND
		AddChunk(pngData, "IEND", scope uint8[0]);

		pngData.CopyTo(result);
	}

	private static void CreateEmptyDeflateStream(List<uint8> result)
	{
		var deflateData = scope List<uint8>();

		// Create minimal valid deflate stream
		var writer = scope BitWriter(deflateData);
		writer.WriteBits(1u, 1); // Last block = true
		writer.WriteBits(0u, 2); // Uncompressed block
		writer.AlignToByte();

		// Length = 0, ~Length = 0xFFFF
		uint16 length = 0;
		uint16 nlength = 0xFFFF;
		writer.WriteBytes(Span<uint8>((uint8*)&length, 2));
		writer.WriteBytes(Span<uint8>((uint8*)&nlength, 2));

		// Compress with zlib wrapper
		var zlibData = scope List<uint8>();
		Zlib.Compress(scope uint8[0], zlibData);

		zlibData.CopyTo(result);
	}

	private static void CreateValidDeflateStreamForPixelData(Span<uint8> pixelData, List<uint8> result)
	{
		var zlibData = scope List<uint8>();
		Zlib.Compress(pixelData, zlibData);

		zlibData.CopyTo(result);
	}
}