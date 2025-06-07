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
        
        // Test invalid color type (7) - not defined in PNG spec
        {
            var pngData = CreateMinimalPng(10, 10, 7, 8, .. scope .());
            var result = loader.LoadFromMemory(pngData);
            if (result case .Ok(var loadInfo))
            {
                Test.Assert(loadInfo.Result == .UnsupportedFormat,
                    "Invalid color type should be unsupported");
                loadInfo.Dispose();
            }
        }
        
        // Test invalid color type (5) - not defined in PNG spec
        {
            var pngData = CreateMinimalPng(10, 10, 5, 8, .. scope .());
            var result = loader.LoadFromMemory(pngData);
            if (result case .Ok(var loadInfo))
            {
                Test.Assert(loadInfo.Result == .UnsupportedFormat,
                    "Invalid color type 5 should be unsupported");
                loadInfo.Dispose();
            }
        }
    }

    [Test] public static void TestUnsupportedBitDepth()
    {
        Console.WriteLine("=== Testing Unsupported Bit Depth ===");
        
        var loader = scope PngLoader();
        
        // Test invalid bit depth (3) - not valid in PNG spec
        {
            var pngData = CreateMinimalPng(10, 10, 2, 3, .. scope .()); // RGB, 3-bit (invalid)
            var result = loader.LoadFromMemory(pngData);
            if (result case .Ok(var loadInfo))
            {
                Test.Assert(loadInfo.Result == .UnsupportedFormat,
                    "Invalid bit depth should be unsupported");
                loadInfo.Dispose();
            }
        }
        
        // Test invalid bit depth (32) - not valid in PNG spec
        {
            var pngData = CreateMinimalPng(10, 10, 0, 32, .. scope .()); // Grayscale, 32-bit (invalid)
            var result = loader.LoadFromMemory(pngData);
            if (result case .Ok(var loadInfo))
            {
                Test.Assert(loadInfo.Result == .UnsupportedFormat,
                    "32-bit depth should be unsupported");
                loadInfo.Dispose();
            }
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

    [Test] public static void TestGrayscale8Png()
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

    [Test] public static void TestGrayscaleAlpha8Png()
    {
        Console.WriteLine("=== Testing Grayscale+Alpha PNG ===");
        
        var loader = scope PngLoader();
        var pngData = CreateValidPng(1, 1, 4, 8, scope uint8[](0, 128, 200), .. scope .()); // Gray+Alpha
        
        var result = loader.LoadFromMemory(pngData);
        if (result case .Ok(var loadInfo))
        {
            Test.Assert(loadInfo.Result == .Success, "Grayscale+Alpha PNG should succeed");
            Test.Assert(loadInfo.Format == .RG8, "Should be RG8 format");
            Test.Assert(loadInfo.Data.Count == 2, "Should have 2 bytes for grayscale+alpha");
            loadInfo.Dispose();
        }
    }

    [Test] public static void TestPalette8Png()
    {
        Console.WriteLine("=== Testing 8-bit Palette PNG ===");
        
        var loader = scope PngLoader();
        
        // Create a simple 2x1 palette PNG with 2 colors
        var pngData = scope List<uint8>();
        AddPngSignature(pngData);
        
        // Add IHDR for palette
        var ihdrData = scope List<uint8>();
        WriteBigEndian32(ihdrData, 2); // Width
        WriteBigEndian32(ihdrData, 1); // Height
        ihdrData.Add(8); // 8-bit depth
        ihdrData.Add(3); // Palette color type
        ihdrData.Add(0); // Compression
        ihdrData.Add(0); // Filter
        ihdrData.Add(0); // Interlace
        AddChunk(pngData, "IHDR", ihdrData);
        
        // Add palette (2 colors: red, blue)
        var paletteData = scope uint8[](255, 0, 0,  0, 0, 255); // Red, Blue
        AddChunk(pngData, "PLTE", paletteData);
        
        // Add pixel data (indices 0, 1)
        var pixelData = scope uint8[](0, 0, 1); // Filter + 2 indices
        var idatData = CreateValidDeflateStreamForPixelData(pixelData, .. scope .());
        AddChunk(pngData, "IDAT", idatData);
        
        AddChunk(pngData, "IEND", scope uint8[0]);
        
        var result = loader.LoadFromMemory(pngData);
        if (result case .Ok(var loadInfo))
        {
            Test.Assert(loadInfo.Result == .Success, "8-bit Palette PNG should succeed");
            Test.Assert(loadInfo.Format == .RGBA8, "Palette should convert to RGBA8");
            Test.Assert(loadInfo.Data.Count == 8, "Should have 8 bytes for 2 RGBA pixels");
            loadInfo.Dispose();
        }
    }

    [Test] public static void TestPalette1BitPng()
    {
        Console.WriteLine("=== Testing 1-bit Palette PNG ===");
        
        var loader = scope PngLoader();
        
        // Create a 8x1 1-bit palette PNG (8 pixels in 1 byte)
        var pngData = scope List<uint8>();
        AddPngSignature(pngData);
        
        // Add IHDR for 1-bit palette
        var ihdrData = scope List<uint8>();
        WriteBigEndian32(ihdrData, 8); // Width
        WriteBigEndian32(ihdrData, 1); // Height
        ihdrData.Add(1); // 1-bit depth
        ihdrData.Add(3); // Palette color type
        ihdrData.Add(0); // Compression
        ihdrData.Add(0); // Filter
        ihdrData.Add(0); // Interlace
        AddChunk(pngData, "IHDR", ihdrData);
        
        // Add palette (2 colors: black, white)
        var paletteData = scope uint8[](0, 0, 0,  255, 255, 255); // Black, White
        AddChunk(pngData, "PLTE", paletteData);
        
        // Add pixel data (8 pixels packed in 1 byte)
        var pixelData = scope uint8[](0, 0xAA); // Filter + packed bits (10101010)
        var idatData = CreateValidDeflateStreamForPixelData(pixelData, .. scope .());
        AddChunk(pngData, "IDAT", idatData);
        
        AddChunk(pngData, "IEND", scope uint8[0]);
        
        var result = loader.LoadFromMemory(pngData);
        if (result case .Ok(var loadInfo))
        {
            Test.Assert(loadInfo.Result == .Success, "1-bit Palette PNG should succeed");
            Test.Assert(loadInfo.Format == .RGBA8, "Palette should convert to RGBA8");
            Test.Assert(loadInfo.Data.Count == 32, "Should have 32 bytes for 8 RGBA pixels");
            loadInfo.Dispose();
        }
    }

    [Test] public static void TestGrayscale16BitPng()
    {
        Console.WriteLine("=== Testing 16-bit Grayscale PNG ===");
        
        var loader = scope PngLoader();
        
        // Create 1x1 16-bit grayscale
        var pngData = scope List<uint8>();
        AddPngSignature(pngData);
        
        var ihdrData = scope List<uint8>();
        WriteBigEndian32(ihdrData, 1); // Width
        WriteBigEndian32(ihdrData, 1); // Height
        ihdrData.Add(16); // 16-bit depth
        ihdrData.Add(0);  // Grayscale
        ihdrData.Add(0); // Compression
        ihdrData.Add(0); // Filter
        ihdrData.Add(0); // Interlace
        AddChunk(pngData, "IHDR", ihdrData);
        
        // 16-bit pixel data (filter + 2 bytes for 16-bit gray)
        var pixelData = scope uint8[](0, 0x80, 0x00); // Filter + 16-bit gray value
        var idatData = CreateValidDeflateStreamForPixelData(pixelData, .. scope .());
        AddChunk(pngData, "IDAT", idatData);
        
        AddChunk(pngData, "IEND", scope uint8[0]);
        
        var result = loader.LoadFromMemory(pngData);
        if (result case .Ok(var loadInfo))
        {
            Test.Assert(loadInfo.Result == .Success, "16-bit Grayscale PNG should succeed");
            Test.Assert(loadInfo.Format == .R16F, "Should be R16F format");
            Test.Assert(loadInfo.Data.Count == 2, "Should have 2 bytes for 16-bit grayscale");
            loadInfo.Dispose();
        }
    }

    [Test] public static void TestRgb16BitPng()
    {
        Console.WriteLine("=== Testing 16-bit RGB PNG ===");
        
        var loader = scope PngLoader();
        
        // Create 1x1 16-bit RGB
        var pngData = scope List<uint8>();
        AddPngSignature(pngData);
        
        var ihdrData = scope List<uint8>();
        WriteBigEndian32(ihdrData, 1); // Width
        WriteBigEndian32(ihdrData, 1); // Height
        ihdrData.Add(16); // 16-bit depth
        ihdrData.Add(2);  // RGB
        ihdrData.Add(0); // Compression
        ihdrData.Add(0); // Filter
        ihdrData.Add(0); // Interlace
        AddChunk(pngData, "IHDR", ihdrData);
        
        // 16-bit RGB pixel data (filter + 6 bytes for RGB)
        var pixelData = scope uint8[](0, 0xFF, 0x00, 0x80, 0x00, 0x40, 0x00); // Filter + RGB16
        var idatData = CreateValidDeflateStreamForPixelData(pixelData, .. scope .());
        AddChunk(pngData, "IDAT", idatData);
        
        AddChunk(pngData, "IEND", scope uint8[0]);
        
        var result = loader.LoadFromMemory(pngData);
        if (result case .Ok(var loadInfo))
        {
            Test.Assert(loadInfo.Result == .Success, "16-bit RGB PNG should succeed");
            Test.Assert(loadInfo.Format == .RGB16F, "Should be RGB16F format");
            Test.Assert(loadInfo.Data.Count == 6, "Should have 6 bytes for 16-bit RGB");
            loadInfo.Dispose();
        }
    }

    [Test] public static void TestRgba16BitPng()
    {
        Console.WriteLine("=== Testing 16-bit RGBA PNG ===");
        
        var loader = scope PngLoader();
        
        // Create 1x1 16-bit RGBA
        var pngData = scope List<uint8>();
        AddPngSignature(pngData);
        
        var ihdrData = scope List<uint8>();
        WriteBigEndian32(ihdrData, 1); // Width
        WriteBigEndian32(ihdrData, 1); // Height
        ihdrData.Add(16); // 16-bit depth
        ihdrData.Add(6);  // RGBA
        ihdrData.Add(0); // Compression
        ihdrData.Add(0); // Filter
        ihdrData.Add(0); // Interlace
        AddChunk(pngData, "IHDR", ihdrData);
        
        // 16-bit RGBA pixel data (filter + 8 bytes for RGBA)
        var pixelData = scope uint8[](0, 0xFF, 0x00, 0x80, 0x00, 0x40, 0x00, 0xFF, 0xFF); // Filter + RGBA16
        var idatData = CreateValidDeflateStreamForPixelData(pixelData, .. scope .());
        AddChunk(pngData, "IDAT", idatData);
        
        AddChunk(pngData, "IEND", scope uint8[0]);
        
        var result = loader.LoadFromMemory(pngData);
        if (result case .Ok(var loadInfo))
        {
            Test.Assert(loadInfo.Result == .Success, "16-bit RGBA PNG should succeed");
            Test.Assert(loadInfo.Format == .RGBA16F, "Should be RGBA16F format");
            Test.Assert(loadInfo.Data.Count == 8, "Should have 8 bytes for 16-bit RGBA");
            loadInfo.Dispose();
        }
    }

    [Test] public static void TestGrayscaleAlpha16BitPng()
    {
        Console.WriteLine("=== Testing 16-bit Grayscale+Alpha PNG ===");
        
        var loader = scope PngLoader();
        
        // Create 1x1 16-bit grayscale+alpha
        var pngData = scope List<uint8>();
        AddPngSignature(pngData);
        
        var ihdrData = scope List<uint8>();
        WriteBigEndian32(ihdrData, 1); // Width
        WriteBigEndian32(ihdrData, 1); // Height
        ihdrData.Add(16); // 16-bit depth
        ihdrData.Add(4);  // Grayscale+Alpha
        ihdrData.Add(0); // Compression
        ihdrData.Add(0); // Filter
        ihdrData.Add(0); // Interlace
        AddChunk(pngData, "IHDR", ihdrData);
        
        // 16-bit grayscale+alpha pixel data (filter + 4 bytes)
        var pixelData = scope uint8[](0, 0x80, 0x00, 0xFF, 0xFF); // Filter + Gray16 + Alpha16
        var idatData = CreateValidDeflateStreamForPixelData(pixelData, .. scope .());
        AddChunk(pngData, "IDAT", idatData);
        
        AddChunk(pngData, "IEND", scope uint8[0]);
        
        var result = loader.LoadFromMemory(pngData);
        if (result case .Ok(var loadInfo))
        {
            Test.Assert(loadInfo.Result == .Success, "16-bit Grayscale+Alpha PNG should succeed");
            Test.Assert(loadInfo.Format == .RG16F, "Should be RG16F format");
            Test.Assert(loadInfo.Data.Count == 4, "Should have 4 bytes for 16-bit grayscale+alpha");
            loadInfo.Dispose();
        }
    }

    [Test] public static void TestTransparencyRgbPng()
    {
        Console.WriteLine("=== Testing RGB PNG with tRNS Transparency ===");
        
        var loader = scope PngLoader();
        
        // Create 2x1 RGB PNG with transparency
        var pngData = scope List<uint8>();
        AddPngSignature(pngData);
        
        var ihdrData = scope List<uint8>();
        WriteBigEndian32(ihdrData, 2); // Width
        WriteBigEndian32(ihdrData, 1); // Height
        ihdrData.Add(8); // 8-bit depth
        ihdrData.Add(2); // RGB
        ihdrData.Add(0); // Compression
        ihdrData.Add(0); // Filter
        ihdrData.Add(0); // Interlace
        AddChunk(pngData, "IHDR", ihdrData);
        
        // Add transparency chunk - make pure red (255,0,0) transparent
        var trnsData = scope uint8[](0xFF, 0x00, 0x00, 0x00, 0x00, 0x00); // Red=255, Green=0, Blue=0
        AddChunk(pngData, "tRNS", trnsData);
        
        // Add pixel data: red (transparent), blue (opaque)
        var pixelData = scope uint8[](0, 255, 0, 0, 0, 0, 255); // Filter + Red + Blue
        var idatData = CreateValidDeflateStreamForPixelData(pixelData, .. scope .());
        AddChunk(pngData, "IDAT", idatData);
        
        AddChunk(pngData, "IEND", scope uint8[0]);
        
        var result = loader.LoadFromMemory(pngData);
        if (result case .Ok(var loadInfo))
        {
            Test.Assert(loadInfo.Result == .Success, "RGB PNG with transparency should succeed");
            Test.Assert(loadInfo.Format == .RGBA8, "Should convert to RGBA8 format");
            Test.Assert(loadInfo.Data.Count == 8, "Should have 8 bytes for 2 RGBA pixels");
            loadInfo.Dispose();
        }
    }

    [Test] public static void TestTransparencyPalettePng()
    {
        Console.WriteLine("=== Testing Palette PNG with tRNS Transparency ===");
        
        var loader = scope PngLoader();
        
        // Create 2x1 palette PNG with transparency
        var pngData = scope List<uint8>();
        AddPngSignature(pngData);
        
        var ihdrData = scope List<uint8>();
        WriteBigEndian32(ihdrData, 2); // Width
        WriteBigEndian32(ihdrData, 1); // Height
        ihdrData.Add(8); // 8-bit depth
        ihdrData.Add(3); // Palette
        ihdrData.Add(0); // Compression
        ihdrData.Add(0); // Filter
        ihdrData.Add(0); // Interlace
        AddChunk(pngData, "IHDR", ihdrData);
        
        // Add palette (red, blue)
        var paletteData = scope uint8[](255, 0, 0,  0, 0, 255); // Red, Blue
        AddChunk(pngData, "PLTE", paletteData);
        
        // Add transparency - make first color (red) transparent, second opaque
        var trnsData = scope uint8[](0, 255); // Index 0 = transparent, Index 1 = opaque
        AddChunk(pngData, "tRNS", trnsData);
        
        // Add pixel data (indices 0, 1)
        var pixelData = scope uint8[](0, 0, 1); // Filter + 2 indices
        var idatData = CreateValidDeflateStreamForPixelData(pixelData, .. scope .());
        AddChunk(pngData, "IDAT", idatData);
        
        AddChunk(pngData, "IEND", scope uint8[0]);
        
        var result = loader.LoadFromMemory(pngData);
        if (result case .Ok(var loadInfo))
        {
            Test.Assert(loadInfo.Result == .Success, "Palette PNG with transparency should succeed");
            Test.Assert(loadInfo.Format == .RGBA8, "Should be RGBA8 format");
            Test.Assert(loadInfo.Data.Count == 8, "Should have 8 bytes for 2 RGBA pixels");
            loadInfo.Dispose();
        }
    }

    [Test] public static void TestGammaCorrectionPng()
    {
        Console.WriteLine("=== Testing PNG with Gamma Correction ===");
        
        var loader = scope PngLoader();
        
        // Create simple RGB PNG with gamma chunk
        var pngData = scope List<uint8>();
        AddPngSignature(pngData);
        
        var ihdrData = scope List<uint8>();
        WriteBigEndian32(ihdrData, 1); // Width
        WriteBigEndian32(ihdrData, 1); // Height
        ihdrData.Add(8); // 8-bit depth
        ihdrData.Add(2); // RGB
        ihdrData.Add(0); // Compression
        ihdrData.Add(0); // Filter
        ihdrData.Add(0); // Interlace
        AddChunk(pngData, "IHDR", ihdrData);
        
        // Add gamma chunk (gamma = 2.2, stored as 100000/gamma = 45455)
        var gammaData = scope uint8[4];
        WriteBigEndian32(scope List<uint8>(gammaData), 45455);
        AddChunk(pngData, "gAMA", gammaData);
        
        // Add pixel data
        var pixelData = scope uint8[](0, 128, 128, 128); // Filter + gray RGB
        var idatData = CreateValidDeflateStreamForPixelData(pixelData, .. scope .());
        AddChunk(pngData, "IDAT", idatData);
        
        AddChunk(pngData, "IEND", scope uint8[0]);
        
        var result = loader.LoadFromMemory(pngData);
        if (result case .Ok(var loadInfo))
        {
            Test.Assert(loadInfo.Result == .Success, "PNG with gamma should succeed");
            Test.Assert(loadInfo.Format == .RGB8, "Should be RGB8 format");
            loadInfo.Dispose();
        }
    }

    [Test] public static void TestSRgbPng()
    {
        Console.WriteLine("=== Testing PNG with sRGB Chunk ===");
        
        var loader = scope PngLoader();
        
        // Create RGB PNG with sRGB chunk
        var pngData = scope List<uint8>();
        AddPngSignature(pngData);
        
        var ihdrData = scope List<uint8>();
        WriteBigEndian32(ihdrData, 1); // Width
        WriteBigEndian32(ihdrData, 1); // Height
        ihdrData.Add(8); // 8-bit depth
        ihdrData.Add(2); // RGB
        ihdrData.Add(0); // Compression
        ihdrData.Add(0); // Filter
        ihdrData.Add(0); // Interlace
        AddChunk(pngData, "IHDR", ihdrData);
        
        // Add sRGB chunk (rendering intent = 0 - perceptual)
        var srgbData = scope uint8[](0);
        AddChunk(pngData, "sRGB", srgbData);
        
        // Add pixel data
        var pixelData = scope uint8[](0, 200, 100, 50); // Filter + RGB
        var idatData = CreateValidDeflateStreamForPixelData(pixelData, .. scope .());
        AddChunk(pngData, "IDAT", idatData);
        
        AddChunk(pngData, "IEND", scope uint8[0]);
        
        var result = loader.LoadFromMemory(pngData);
        if (result case .Ok(var loadInfo))
        {
            Test.Assert(loadInfo.Result == .Success, "PNG with sRGB should succeed");
            Test.Assert(loadInfo.Format == .RGB8, "Should be RGB8 format");
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

    //[Test]
	public static void TestInterlacedPng()
	{
	    Console.WriteLine("=== Testing Interlaced PNG (Adam7) ===");

		Console.WriteLine("=== Testing Interlaced PNG (Adam7) ===");

		// First, let's test what zlib compression produces
		var originalData = scope uint8[](0, 128); // Filter + pixel
		var zlibCompressed = scope List<uint8>();
		var zlibResult = Zlib.Compress(originalData, zlibCompressed);
		Console.WriteLine($"Zlib compress result: {zlibResult}");
		Console.WriteLine($"Original data: {originalData.Count} bytes");
		Console.WriteLine($"Compressed data: {zlibCompressed.Count} bytes");

		var zlibDecompressed = scope List<uint8>();
		var decompressResult = Zlib.Decompress(zlibCompressed, zlibDecompressed);
		Console.WriteLine($"Zlib decompress result: {decompressResult}");
		Console.WriteLine($"Decompressed data: {zlibDecompressed.Count} bytes");

		if (zlibDecompressed.Count != 2)
		{
		    Console.WriteLine("ERROR: Zlib round-trip failed!");
		    Test.Assert(false, "Zlib should preserve data");
		    return;
		}
	    
	    var loader = scope PngLoader();
	    
	    // Create simple 1x1 interlaced grayscale PNG (simpler case)
	    var pngData = scope List<uint8>();
	    AddPngSignature(pngData);
	    
	    var ihdrData = scope List<uint8>();
	    WriteBigEndian32(ihdrData, 1); // Width
	    WriteBigEndian32(ihdrData, 1); // Height
	    ihdrData.Add(8); // 8-bit depth
	    ihdrData.Add(0); // Grayscale
	    ihdrData.Add(0); // Compression
	    ihdrData.Add(0); // Filter
	    ihdrData.Add(1); // Adam7 interlace
	    AddChunk(pngData, "IHDR", ihdrData);
	    
	    // For 1x1 Adam7, only pass 1 has data: 1 pixel at (0,0)
	    var pixelData = scope uint8[](0, 128); // Filter + 1 pixel
	    var idatData = CreateValidDeflateStreamForPixelData(pixelData, .. scope .());
	    AddChunk(pngData, "IDAT", idatData);
	    
	    AddChunk(pngData, "IEND", scope uint8[0]);
	    
	    var result = loader.LoadFromMemory(pngData);
	    if (result case .Ok(var loadInfo))
	    {
	        Test.Assert(loadInfo.Result == .Success, "Interlaced PNG should succeed");
	        Test.Assert(loadInfo.Format == .R8, "Should be R8 format");
	        Test.Assert(loadInfo.Data.Count == 1, "Should have 1 byte for 1x1 grayscale");
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

    [Test] public static void TestComplexPngFeatures()
    {
        Console.WriteLine("=== Testing Complex PNG with Multiple Features ===");
        
        var loader = scope PngLoader();
        
        // Create palette PNG with transparency, gamma, and extra chunks
        var pngData = scope List<uint8>();
        AddPngSignature(pngData);
        
        var ihdrData = scope List<uint8>();
        WriteBigEndian32(ihdrData, 3); // Width
        WriteBigEndian32(ihdrData, 1); // Height
        ihdrData.Add(4); // 4-bit depth
        ihdrData.Add(3); // Palette
        ihdrData.Add(0); // Compression
        ihdrData.Add(0); // Filter
        ihdrData.Add(0); // Interlace
        AddChunk(pngData, "IHDR", ihdrData);
        
        // Add gamma
        var gammaData = scope uint8[4];
        WriteBigEndian32(gammaData, 45455); // gamma 2.2
        AddChunk(pngData, "gAMA", gammaData);
        
        // Add palette (4 colors)
        var paletteData = scope uint8[](
            255, 0, 0,    // Red
            0, 255, 0,    // Green  
            0, 0, 255,    // Blue
            255, 255, 0   // Yellow
        );
        AddChunk(pngData, "PLTE", paletteData);
        
        // Add transparency (make red and blue semi-transparent)
        var trnsData = scope uint8[](128, 255, 64, 200); // Alpha values for palette
        AddChunk(pngData, "tRNS", trnsData);
        
        // Add background color
        var bkgdData = scope uint8[](1); // Use palette index 1 (green) as background
        AddChunk(pngData, "bKGD", bkgdData);
        
        // Add text chunk
        var textData = scope uint8[](.('T'), .('e'), .('s'), .('t'), 0, .('I'), .('m'), .('a'), .('g'), .('e'));
        AddChunk(pngData, "tEXt", textData);
        
        // Add pixel data (3 pixels, 4-bit each, packed into 2 bytes)
        var pixelData = scope uint8[](0, 0x01, 0x23); // Filter + packed indices 0,1,2,3 (but only 3 pixels)
        var idatData = CreateValidDeflateStreamForPixelData(pixelData, .. scope .());
        AddChunk(pngData, "IDAT", idatData);
        
        AddChunk(pngData, "IEND", scope uint8[0]);
        
        var result = loader.LoadFromMemory(pngData);
        if (result case .Ok(var loadInfo))
        {
            Test.Assert(loadInfo.Result == .Success, "Complex PNG should succeed");
            Test.Assert(loadInfo.Format == .RGBA8, "Should be RGBA8 format");
            Test.Assert(loadInfo.Data.Count == 12, "Should have 12 bytes for 3 RGBA pixels");
            loadInfo.Dispose();
        }
    }

    [Test] public static void TestBitDepthEdgeCases()
    {
        Console.WriteLine("=== Testing Bit Depth Edge Cases ===");
        
        var loader = scope PngLoader();
        
        // Test 2-bit grayscale
        {
            var pngData = scope List<uint8>();
            AddPngSignature(pngData);
            
            var ihdrData = scope List<uint8>();
            WriteBigEndian32(ihdrData, 4); // Width (4 pixels fit in 1 byte at 2-bit)
            WriteBigEndian32(ihdrData, 1); // Height
            ihdrData.Add(2); // 2-bit depth
            ihdrData.Add(0); // Grayscale
            ihdrData.Add(0); // Compression
            ihdrData.Add(0); // Filter
            ihdrData.Add(0); // Interlace
            AddChunk(pngData, "IHDR", ihdrData);
            
            // 2-bit pixel data (4 pixels: 0,1,2,3 packed in 1 byte = 0x1B)
            var pixelData = scope uint8[](0, 0x1B); // Filter + packed pixels
            var idatData = CreateValidDeflateStreamForPixelData(pixelData, .. scope .());
            AddChunk(pngData, "IDAT", idatData);
            
            AddChunk(pngData, "IEND", scope uint8[0]);
            
            var result = loader.LoadFromMemory(pngData);
            if (result case .Ok(var loadInfo))
            {
                Test.Assert(loadInfo.Result == .Success, "2-bit Grayscale PNG should succeed");
                Test.Assert(loadInfo.Format == .R8, "Should be R8 format");
                Test.Assert(loadInfo.Data.Count == 4, "Should have 4 bytes for 4 grayscale pixels");
                loadInfo.Dispose();
            }
        }
        
        // Test 4-bit grayscale
        {
            var pngData = scope List<uint8>();
            AddPngSignature(pngData);
            
            var ihdrData = scope List<uint8>();
            WriteBigEndian32(ihdrData, 2); // Width (2 pixels fit in 1 byte at 4-bit)
            WriteBigEndian32(ihdrData, 1); // Height
            ihdrData.Add(4); // 4-bit depth
            ihdrData.Add(0); // Grayscale
            ihdrData.Add(0); // Compression
            ihdrData.Add(0); // Filter
            ihdrData.Add(0); // Interlace
            AddChunk(pngData, "IHDR", ihdrData);
            
            // 4-bit pixel data (2 pixels: 5,10 packed in 1 byte = 0x5A)
            var pixelData = scope uint8[](0, 0x5A); // Filter + packed pixels
            var idatData = CreateValidDeflateStreamForPixelData(pixelData, .. scope .());
            AddChunk(pngData, "IDAT", idatData);
            
            AddChunk(pngData, "IEND", scope uint8[0]);
            
            var result = loader.LoadFromMemory(pngData);
            if (result case .Ok(var loadInfo))
            {
                Test.Assert(loadInfo.Result == .Success, "4-bit Grayscale PNG should succeed");
                Test.Assert(loadInfo.Format == .R8, "Should be R8 format");
                Test.Assert(loadInfo.Data.Count == 2, "Should have 2 bytes for 2 grayscale pixels");
                loadInfo.Dispose();
            }
        }
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

    private static void WriteBigEndian32(Span<uint8> data, uint32 value)
    {
        data[0] = (uint8)(value >> 24);
        data[1] = (uint8)(value >> 16);
        data[2] = (uint8)(value >> 8);
        data[3] = (uint8)value;
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