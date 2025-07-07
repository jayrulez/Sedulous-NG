using System;
using System.Collections;
using System.IO;
using Sedulous.IO.Compression;
using Sedulous.Mathematics;

namespace Sedulous.Imaging;

// Enhanced PNG Loader with comprehensive format support
public class PngLoader : ImageLoader
{
	private const uint32 PNG_SIGNATURE = 0x474E5089; // PNG signature bytes

	[CRepr]
	private struct PngChunk
	{
		public uint32 Length;
		public uint32 Type;
		public uint8* Data;
		public uint32 CRC;
	}

	[CRepr]
	private struct PngHeader
	{
		public uint32 Width;
		public uint32 Height;
		public uint8 BitDepth;
		public uint8 ColorType;
		public uint8 CompressionMethod;
		public uint8 FilterMethod;
		public uint8 InterlaceMethod;
	}

	private struct PaletteEntry
	{
		public uint8 R, G, B, A;

		public this(uint8 r, uint8 g, uint8 b, uint8 a = 255)
		{
			R = r; G = g; B = b; A = a;
		}
	}

	private struct TransparencyInfo
	{
		public uint16 GrayTransparent; // For grayscale
		public uint16 RedTransparent; // For RGB
		public uint16 GreenTransparent;
		public uint16 BlueTransparent;
		public uint8[] PaletteAlpha; // For palette ~ delete _;

		public this()
		{
			GrayTransparent = 0;
			RedTransparent = 0;
			GreenTransparent = 0;
			BlueTransparent = 0;
			PaletteAlpha = null;
		}
	}

	private struct GammaInfo
	{
		public float Gamma;
		public bool HasGamma;
		public bool IsSRGB;

		public this()
		{
			Gamma = 2.2f;
			HasGamma = false;
			IsSRGB = false;
		}
	}

	public override bool SupportsExtension(StringView @extension)
	{
		var ext = scope String(@extension);
		ext.ToLower();
		return ext == ".png";
	}

	public override void GetSupportedExtensions(List<String> outExtensions)
	{
		outExtensions.Add(new String(".png"));
	}

	public override Result<LoadInfo> LoadFromFile(StringView filePath)
	{
		var fileStream = scope FileStream();
		if (fileStream.Open(filePath, .Read) case .Err)
		{
			var loadInfo = LoadInfo();
			loadInfo.Result = .FileNotFound;
			loadInfo.ErrorMessage = new String("Failed to open file");
			return loadInfo;
		}

		defer fileStream.Close();

		// Read entire file into memory
		var fileSize = fileStream.Length;
		if (fileSize <= 0 || fileSize >= int.MaxValue)
		{
			var loadInfo = LoadInfo();
			loadInfo.Result = .InvalidDimensions;
			loadInfo.ErrorMessage = new String("Invalid file size");
			return loadInfo;
		}

		var buffer = new uint8[fileSize];
		defer delete buffer;

		if (fileStream.TryRead(buffer) case .Err)
		{
			var loadInfo = LoadInfo();
			loadInfo.Result = .CorruptedData;
			loadInfo.ErrorMessage = new String("Failed to read file data");
			return loadInfo;
		}

		return LoadFromMemory(buffer);
	}

	public override Result<LoadInfo> LoadFromMemory(Span<uint8> data)
	{
		var loadInfo = LoadInfo();

		// Verify PNG signature
		if (data.Length < 8 || !VerifyPngSignature(data))
		{
			loadInfo.Result = .UnsupportedFormat;
			loadInfo.ErrorMessage = new String("Invalid PNG signature");
			return loadInfo;
		}

		// Parse PNG chunks
		var chunks = scope List<PngChunk>();
		var offset = 8; // Skip signature

		while (offset < data.Length)
		{
			if (offset + 12 > data.Length) // Minimum chunk size
				break;

			var chunk = PngChunk();
			chunk.Length = ReadBigEndianUInt32(data, offset);
			chunk.Type = ReadBigEndianUInt32(data, offset + 4);

			if (offset + 12 + chunk.Length > data.Length)
				break;

			chunk.Data = &data[offset + 8];
			chunk.CRC = ReadBigEndianUInt32(data, offset + 8 + (int)chunk.Length);

			chunks.Add(chunk);
			offset += 12 + (int)chunk.Length;

			// Break after IEND chunk
			if (chunk.Type == 0x49454E44) // "IEND"
				break;
		}

		// Find IHDR chunk
		PngHeader? header = null;
		for (var chunk in chunks)
		{
			if (chunk.Type == 0x49484452) // "IHDR"
			{
				if (chunk.Length >= 13)
				{
					header = ParseIHDR(chunk);
					break;
				}
			}
		}

		if (header == null)
		{
			loadInfo.Result = .CorruptedData;
			loadInfo.ErrorMessage = new String("Missing or invalid IHDR chunk");
			return loadInfo;
		}

		var hdr = header.Value;

		// Validate header
		if (hdr.Width == 0 || hdr.Height == 0 || hdr.Width > 65535 || hdr.Height > 65535)
		{
			loadInfo.Result = .InvalidDimensions;
			loadInfo.ErrorMessage = new String("Invalid image dimensions");
			return loadInfo;
		}

		// Validate bit depth and color type combination
		bool validCombination = false;
		switch (hdr.ColorType)
		{
		case 0: // Grayscale
		    validCombination = (hdr.BitDepth == 1 || hdr.BitDepth == 2 || hdr.BitDepth == 4 || hdr.BitDepth == 8 || hdr.BitDepth == 16);
		case 2: // RGB
		    validCombination = (hdr.BitDepth == 8 || hdr.BitDepth == 16);
		case 3: // Palette
		    validCombination = (hdr.BitDepth == 1 || hdr.BitDepth == 2 || hdr.BitDepth == 4 || hdr.BitDepth == 8);
		case 4: // Grayscale + Alpha
		    validCombination = (hdr.BitDepth == 8 || hdr.BitDepth == 16);
		case 6: // RGBA
		    validCombination = (hdr.BitDepth == 8 || hdr.BitDepth == 16);
		default:
		    validCombination = false;
		}

		if (!validCombination)
		{
		    loadInfo.Result = .UnsupportedFormat;
		    loadInfo.ErrorMessage = new String("Invalid bit depth for color type combination");
		    return loadInfo;
		}

		// Parse palette if present (PLTE chunk)
		var palette = scope List<PaletteEntry>();
		for (var chunk in chunks)
		{
			if (chunk.Type == 0x504C5445) // "PLTE"
			{
				if (ParsePalette(chunk, palette) case .Err)
				{
					loadInfo.Result = .CorruptedData;
					loadInfo.ErrorMessage = new String("Invalid palette data");
					return loadInfo;
				}
				break;
			}
		}

		// Parse transparency info (tRNS chunk)
		var transparency = scope TransparencyInfo();
		defer { delete transparency.PaletteAlpha;
		}
		for (var chunk in chunks)
		{
			if (chunk.Type == 0x74524E53) // "tRNS"
			{
				if (ParseTransparency(chunk, hdr.ColorType, transparency, palette) case .Err)
				{
					loadInfo.Result = .CorruptedData;
					loadInfo.ErrorMessage = new String("Invalid transparency data");
					return loadInfo;
				}
				break;
			}
		}

		// Parse gamma info (gAMA, sRGB chunks)
		var gamma = scope GammaInfo();
		for (var chunk in chunks)
		{
			if (chunk.Type == 0x67414D41) // "gAMA"
			{
				if (chunk.Length == 4)
				{
					uint32 gammaInt = ReadBigEndianUInt32(Span<uint8>(chunk.Data, 4), 0);
					gamma.Gamma = 100000.0f / gammaInt;
					gamma.HasGamma = true;
				}
			}
			else if (chunk.Type == 0x73524742) // "sRGB"
			{
				gamma.IsSRGB = true;
				gamma.Gamma = 2.2f; // Standard sRGB gamma
				gamma.HasGamma = true;
			}
		}

		// Determine output pixel format
		if (DetermineOutputFormat(hdr, palette, transparency, var pixelFormat, var outputBytesPerPixel) case .Err)
		{
			loadInfo.Result = .UnsupportedFormat;
			loadInfo.ErrorMessage = new String("Unsupported PNG format combination");
			return loadInfo;
		}

		// Collect IDAT chunks
		var idatData = scope List<uint8>();
		for (var chunk in chunks)
		{
			if (chunk.Type == 0x49444154) // "IDAT"
			{
				for (int i = 0; i < chunk.Length; i++)
				{
					idatData.Add(chunk.Data[i]);
				}
			}
		}

		if (idatData.Count == 0)
		{
			loadInfo.Result = .CorruptedData;
			loadInfo.ErrorMessage = new String("No image data found");
			return loadInfo;
		}

		// Decompress and process image data
		var decompressResult = DecompressAndProcessImageData(idatData, hdr, palette, transparency, gamma,
			pixelFormat, outputBytesPerPixel);
		if (decompressResult case .Err)
		{
			loadInfo.Result = .CorruptedData;
			loadInfo.ErrorMessage = new String("Failed to decompress image data");
			return loadInfo;
		}

		var imageData = decompressResult.Value;

		// Set up load info
		loadInfo.Width = hdr.Width;
		loadInfo.Height = hdr.Height;
		loadInfo.Format = pixelFormat;
		loadInfo.Data = imageData;
		loadInfo.Result = .Success;

		return loadInfo;
	}

	private bool VerifyPngSignature(Span<uint8> data)
	{
		uint8[8] pngSig = .(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A);

		for (int i = 0; i < 8; i++)
		{
			if (data[i] != pngSig[i])
				return false;
		}
		return true;
	}

	private uint32 ReadBigEndianUInt32(Span<uint8> data, int offset)
	{
		return ((uint32)data[offset] << 24) |
			((uint32)data[offset + 1] << 16) |
			((uint32)data[offset + 2] << 8) |
			(uint32)data[offset + 3];
	}

	private uint16 ReadBigEndianUInt16(Span<uint8> data, int offset)
	{
		return (uint16)(((uint16)data[offset] << 8) | (uint16)data[offset + 1]);
	}

	private PngHeader ParseIHDR(PngChunk chunk)
	{
		var header = PngHeader();
		header.Width = ReadBigEndianUInt32(Span<uint8>(chunk.Data, (int)chunk.Length), 0);
		header.Height = ReadBigEndianUInt32(Span<uint8>(chunk.Data, (int)chunk.Length), 4);
		header.BitDepth = chunk.Data[8];
		header.ColorType = chunk.Data[9];
		header.CompressionMethod = chunk.Data[10];
		header.FilterMethod = chunk.Data[11];
		header.InterlaceMethod = chunk.Data[12];
		return header;
	}

	private Result<void> ParsePalette(PngChunk chunk, List<PaletteEntry> palette)
	{
		if (chunk.Length % 3 != 0 || chunk.Length > 768) // Max 256 colors * 3 bytes
			return .Err;

		int colorCount = (int)chunk.Length / 3;
		for (int i = 0; i < colorCount; i++)
		{
			var entry = PaletteEntry(
				chunk.Data[i * 3], // R
				chunk.Data[i * 3 + 1], // G
				chunk.Data[i * 3 + 2], // B
				255 // A (default opaque)
				);
			palette.Add(entry);
		}

		return .Ok;
	}

	private Result<void> ParseTransparency(PngChunk chunk, uint8 colorType, TransparencyInfo* transparency, List<PaletteEntry> palette)
	{
		var chunkData = Span<uint8>(chunk.Data, (int)chunk.Length);

		switch (colorType)
		{
		case 0: // Grayscale
			if (chunk.Length != 2) return .Err;
			transparency.GrayTransparent = ReadBigEndianUInt16(chunkData, 0);

		case 2: // RGB
			if (chunk.Length != 6) return .Err;
			transparency.RedTransparent = ReadBigEndianUInt16(chunkData, 0);
			transparency.GreenTransparent = ReadBigEndianUInt16(chunkData, 2);
			transparency.BlueTransparent = ReadBigEndianUInt16(chunkData, 4);

		case 3: // Palette
			if (chunk.Length > palette.Count) return .Err;
			transparency.PaletteAlpha = new uint8[palette.Count];

			// Copy alpha values from tRNS
			for (int i = 0; i < chunk.Length; i++)
				transparency.PaletteAlpha[i] = chunk.Data[i];

			// Fill remaining with opaque
			for (int i = (int)chunk.Length; i < palette.Count; i++)
				transparency.PaletteAlpha[i] = 255;

			// Update palette entries with alpha
			for (int i = 0; i < palette.Count; i++)
				palette[i].A = transparency.PaletteAlpha[i];

		default:
			return .Err; // tRNS not valid for other color types
		}

		return .Ok;
	}

	private Result<void> DetermineOutputFormat(PngHeader hdr, List<PaletteEntry> palette, TransparencyInfo* transparency,
		out Image.PixelFormat pixelFormat, out int bytesPerPixel)
	{
		pixelFormat = .RGBA8; // Default
		bytesPerPixel = 4;

		bool hasTransparency = (transparency.PaletteAlpha != null) ||
			(hdr.ColorType == 0 && transparency.GrayTransparent != 0) ||
			(hdr.ColorType == 2 && (transparency.RedTransparent != 0 ||
			transparency.GreenTransparent != 0 || transparency.BlueTransparent != 0));

		switch (hdr.ColorType)
		{
		case 0: // Grayscale
			if (hdr.BitDepth == 16)
			{
				pixelFormat = hasTransparency ? .RG16F : .R16F;
				bytesPerPixel = hasTransparency ? 4 : 2;
			}
			else
			{
				pixelFormat = hasTransparency ? .RG8 : .R8;
				bytesPerPixel = hasTransparency ? 2 : 1;
			}

		case 2: // RGB
			if (hdr.BitDepth == 16)
			{
				pixelFormat = hasTransparency ? .RGBA16F : .RGB16F;
				bytesPerPixel = hasTransparency ? 8 : 6;
			}
			else
			{
				pixelFormat = hasTransparency ? .RGBA8 : .RGB8;
				bytesPerPixel = hasTransparency ? 4 : 3;
			}

		case 3: // Palette
			// Always convert palette to RGBA8 for simplicity
			pixelFormat = .RGBA8;
			bytesPerPixel = 4;

		case 4: // Grayscale + Alpha
			if (hdr.BitDepth == 16)
			{
				pixelFormat = .RG16F;
				bytesPerPixel = 4;
			}
			else
			{
				pixelFormat = .RG8;
				bytesPerPixel = 2;
			}

		case 6: // RGBA
			if (hdr.BitDepth == 16)
			{
				pixelFormat = .RGBA16F;
				bytesPerPixel = 8;
			}
			else
			{
				pixelFormat = .RGBA8;
				bytesPerPixel = 4;
			}

		default:
			return .Err;
		}

		return .Ok;
	}

	private Result<uint8[]> DecompressAndProcessImageData(List<uint8> compressedData, PngHeader hdr,
		List<PaletteEntry> palette, TransparencyInfo* transparency,
		GammaInfo* gamma, Image.PixelFormat outputFormat,
		int outputBytesPerPixel)
	{
		// Decompress using zlib
		var decompressed = scope List<uint8>();
		var zlibResult = Zlib.Decompress(compressedData, decompressed);

		if (zlibResult != .Success)
			return .Err;

		// Calculate input format info
		int inputBytesPerPixel = GetInputBytesPerPixel(hdr.ColorType, hdr.BitDepth);
		int inputBitsPerPixel = GetInputBitsPerPixel(hdr.ColorType, hdr.BitDepth);

		// Handle interlacing
		if (hdr.InterlaceMethod == 1) // Adam7
		{
			Console.WriteLine($"Before deinterlace: {decompressed.Count} bytes");
			if (DeinterlaceAdam7(decompressed, hdr, inputBytesPerPixel) case .Err)
			    return .Err;
			Console.WriteLine($"After deinterlace: {decompressed.Count} bytes");
		}
		else
		{
			Console.WriteLine($"Non-interlaced: {decompressed.Count} bytes");
			// Validate non-interlaced size
			int rowSize = ((int)hdr.Width * inputBitsPerPixel + 7) / 8 + 1; // +1 for filter byte
			int expectedSize = (int)hdr.Height * rowSize;
			Console.WriteLine($"Expected size: {expectedSize}, actual: {decompressed.Count}");

			if (decompressed.Count != expectedSize)
			    return .Err;
		}

		// Apply row filters
		if (ApplyRowFilters(decompressed, hdr, inputBytesPerPixel) case .Err)
			return .Err;

		// Convert to output format
		return ConvertToOutputFormat(decompressed, hdr, palette, transparency, gamma,
			outputFormat, outputBytesPerPixel, inputBytesPerPixel, inputBitsPerPixel);
	}

	private int GetInputBytesPerPixel(uint8 colorType, uint8 bitDepth)
	{
		switch (colorType)
		{
		case 0: return Math.Max(1, bitDepth / 8); // Grayscale
		case 2: return (bitDepth / 8) * 3; // RGB
		case 3: return Math.Max(1, bitDepth / 8); // Palette
		case 4: return (bitDepth / 8) * 2; // Grayscale + Alpha
		case 6: return (bitDepth / 8) * 4; // RGBA
		default: return 1;
		}
	}

	private int GetInputBitsPerPixel(uint8 colorType, uint8 bitDepth)
	{
		switch (colorType)
		{
		case 0: return bitDepth; // Grayscale
		case 2: return bitDepth * 3; // RGB
		case 3: return bitDepth; // Palette
		case 4: return bitDepth * 2; // Grayscale + Alpha
		case 6: return bitDepth * 4; // RGBA
		default: return 8;
		}
	}

	private Result<void> DeinterlaceAdam7(List<uint8> data, PngHeader hdr, int bytesPerPixel)
	{
		// Adam7 interlacing pattern
		int[7] startX = .(0, 4, 0, 2, 0, 1, 0);
		int[7] startY = .(0, 0, 4, 0, 2, 0, 1);
		int[7] stepX = .(8, 8, 4, 4, 2, 2, 1);
		int[7] stepY = .(8, 8, 8, 4, 4, 2, 2);

		var deinterlaced = scope List<uint8>();
		int outputRowSize = (int)hdr.Width * bytesPerPixel;

		// Initialize output with zeros
		for (int y = 0; y < hdr.Height; y++)
		{
			for (int x = 0; x < outputRowSize; x++)
			{
				deinterlaced.Add(0);
			}
		}

		int inputOffset = 0;

		// Process each Adam7 pass
		for (int pass = 0; pass < 7; pass++)
		{
			int passWidth = (int)(hdr.Width - startX[pass] + stepX[pass] - 1) / stepX[pass];
			int passHeight = (int)(hdr.Height - startY[pass] + stepY[pass] - 1) / stepY[pass];

			if (passWidth <= 0 || passHeight <= 0)
				continue;

			int passRowSize = passWidth * bytesPerPixel + 1; // +1 for filter byte
			
			// Extract pass data and apply filters
			var passData = scope List<uint8>();
			for (int i = 0; i < passHeight * passRowSize; i++)
			{
				if (inputOffset >= data.Count)
					return .Err;
				passData.Add(data[inputOffset++]);
			}

			// Apply row filters to this pass
			if (ApplyRowFiltersToPass(passData, passWidth, passHeight, bytesPerPixel) case .Err)
				return .Err;

			// Copy pass data to final positions
			int passDataOffset = 0;
			for (int y = startY[pass]; y < hdr.Height; y += stepY[pass])
			{
				for (int x = startX[pass]; x < hdr.Width; x += stepX[pass])
				{
					int outputOffset = (int)(y * hdr.Width + x) * bytesPerPixel;
					for (int b = 0; b < bytesPerPixel; b++)
					{
						deinterlaced[outputOffset + b] = passData[passDataOffset++];
					}
				}
			}
		}

		// Replace original data with deinterlaced data
		data.Clear();
		data.AddRange(deinterlaced);

		return .Ok;
	}

	private Result<void> ApplyRowFilters(List<uint8> data, PngHeader hdr, int bytesPerPixel)
	{
	    return ApplyRowFiltersToPass(data, (int)hdr.Width, (int)hdr.Height, bytesPerPixel);
	}

	private Result<void> ApplyRowFiltersToPass(List<uint8> data, int width, int height, int bytesPerPixel)
	{
	    var filteredData = scope uint8[data.Count];
	    data.CopyTo(filteredData);
	    
	    // Calculate actual row size based on the data we have
	    int actualRowSize = data.Count / height;
	    int bytesInRow = actualRowSize - 1; // Exclude filter byte
	    
	    for (int y = 0; y < height; y++)
	    {
	        int rowStart = y * actualRowSize;
	        uint8 filterType = filteredData[rowStart];
	        var rowData = Span<uint8>(&filteredData[rowStart + 1], bytesInRow);
	        
	        // Apply reverse filter
	        switch (filterType)
	        {
	        case 0: // None
	            break;
	        case 1: // Sub
	            ApplySubFilter(rowData, Math.Max(1, bytesPerPixel));
	        case 2: // Up
	            if (y > 0)
	            {
	                var prevRowStart = (y - 1) * actualRowSize + 1;
	                var prevRowData = Span<uint8>(&filteredData[prevRowStart], bytesInRow);
	                ApplyUpFilter(rowData, prevRowData);
	            }
	        case 3: // Average
	            if (y > 0)
	            {
	                var prevRowStart = (y - 1) * actualRowSize + 1;
	                var prevRowData = Span<uint8>(&filteredData[prevRowStart], bytesInRow);
	                ApplyAverageFilter(rowData, prevRowData, Math.Max(1, bytesPerPixel));
	            }
	            else
	            {
	                ApplySubFilter(rowData, Math.Max(1, bytesPerPixel));
	            }
	        case 4: // Paeth
	            if (y > 0)
	            {
	                var prevRowStart = (y - 1) * actualRowSize + 1;
	                var prevRowData = Span<uint8>(&filteredData[prevRowStart], bytesInRow);
	                ApplyPaethFilter(rowData, prevRowData, Math.Max(1, bytesPerPixel));
	            }
	            else
	            {
	                ApplySubFilter(rowData, Math.Max(1, bytesPerPixel));
	            }
	        default:
	            return .Err;
	        }
	    }
	    
	    // Remove filter bytes and copy back
	    data.Clear();
	    for (int y = 0; y < height; y++)
	    {
	        int rowStart = y * actualRowSize + 1; // Skip filter byte
	        for (int x = 0; x < bytesInRow; x++)
	        {
	            data.Add(filteredData[rowStart + x]);
	        }
	    }
	    
	    return .Ok;
	}

	private Result<uint8[]> ConvertToOutputFormat(List<uint8> rawData, PngHeader hdr, List<PaletteEntry> palette,
		TransparencyInfo* transparency, GammaInfo* gamma,
		Image.PixelFormat outputFormat, int outputBytesPerPixel,
		int inputBytesPerPixel, int inputBitsPerPixel)
	{
		int outputSize = (int)(hdr.Width * hdr.Height * outputBytesPerPixel);
		var output = new uint8[outputSize];

		int inputOffset = 0;
		int outputOffset = 0;

		for (uint32 y = 0; y < hdr.Height; y++)
		{
			for (uint32 x = 0; x < hdr.Width; x++)
			{
				// Read input pixel based on bit depth and color type
				var pixel = ReadPixel(rawData, inputOffset, hdr, inputBitsPerPixel, palette);

				// Convert pixel to RGBA
				var rgba = ConvertPixelToRGBA(pixel, hdr, palette, transparency);

				// Apply gamma correction if needed
				if (gamma.HasGamma && !gamma.IsSRGB)
				{
					rgba = ApplyGammaCorrection(rgba, gamma.Gamma);
				}
				else if (gamma.IsSRGB)
				{
					rgba = ApplySRGBCorrection(rgba);
				}

				// Write output pixel in target format
				WritePixel(output, outputOffset, rgba, outputFormat);

				inputOffset += Math.Max(1, inputBytesPerPixel);
				outputOffset += outputBytesPerPixel;
			}
		}

		return output;
	}

	private Vector4 ReadPixel(List<uint8> data, int offset, PngHeader hdr, int bitsPerPixel, List<PaletteEntry> palette)
	{
		var pixel = Vector4(0, 0, 0, 1); // Default RGBA

		switch (hdr.ColorType)
		{
		case 0: // Grayscale
			if (hdr.BitDepth == 16)
			{
				uint16 gray = ((uint16)data[offset] << 8) | data[offset + 1];
				float grayF = gray / 65535.0f;
				pixel = Vector4(grayF, grayF, grayF, 1.0f);
			}
			else if (hdr.BitDepth == 8)
			{
				float gray = data[offset] / 255.0f;
				pixel = Vector4(gray, gray, gray, 1.0f);
			}
			else if (hdr.BitDepth < 8)
			{
				// Handle 1, 2, 4 bit grayscale
				int pixelsPerByte = 8 / hdr.BitDepth;
				int byteOffset = offset / pixelsPerByte;
				int bitOffset = (offset % pixelsPerByte) * hdr.BitDepth;
				uint8 mask = (uint8)((1 << hdr.BitDepth) - 1);
				uint8 value = (uint8)((data[byteOffset] >> (8 - hdr.BitDepth - bitOffset)) & mask);
				float gray = value / (float)((1 << hdr.BitDepth) - 1);
				pixel = Vector4(gray, gray, gray, 1.0f);
			}

		case 2: // RGB
			if (hdr.BitDepth == 16)
			{
				uint16 r = ((uint16)data[offset] << 8) | data[offset + 1];
				uint16 g = ((uint16)data[offset + 2] << 8) | data[offset + 3];
				uint16 b = ((uint16)data[offset + 4] << 8) | data[offset + 5];
				pixel = Vector4(r / 65535.0f, g / 65535.0f, b / 65535.0f, 1.0f);
			}
			else
			{
				pixel = Vector4(data[offset] / 255.0f, data[offset + 1] / 255.0f, data[offset + 2] / 255.0f, 1.0f);
			}

		case 3: // Palette
			uint8 paletteIndex;
			if (hdr.BitDepth == 8)
			{
				paletteIndex = data[offset];
			}
			else if (hdr.BitDepth < 8)
			{
				// Handle 1, 2, 4 bit palette indices
				int pixelsPerByte = 8 / hdr.BitDepth;
				int byteOffset = offset / pixelsPerByte;
				int bitOffset = (offset % pixelsPerByte) * hdr.BitDepth;
				uint8 mask = (uint8)((1 << hdr.BitDepth) - 1);
				paletteIndex = (uint8)((data[byteOffset] >> (8 - hdr.BitDepth - bitOffset)) & mask);
			}
			else
			{
				paletteIndex = 0; // Fallback
			}

			if (paletteIndex < palette.Count)
			{
				var entry = palette[paletteIndex];
				pixel = Vector4(entry.R / 255.0f, entry.G / 255.0f, entry.B / 255.0f, entry.A / 255.0f);
			}

		case 4: // Grayscale + Alpha
			if (hdr.BitDepth == 16)
			{
				uint16 gray = ((uint16)data[offset] << 8) | data[offset + 1];
				uint16 alpha = ((uint16)data[offset + 2] << 8) | data[offset + 3];
				float grayF = gray / 65535.0f;
				float alphaF = alpha / 65535.0f;
				pixel = Vector4(grayF, grayF, grayF, alphaF);
			}
			else
			{
				float gray = data[offset] / 255.0f;
				float alpha = data[offset + 1] / 255.0f;
				pixel = Vector4(gray, gray, gray, alpha);
			}

		case 6: // RGBA
			if (hdr.BitDepth == 16)
			{
				uint16 r = ((uint16)data[offset] << 8) | data[offset + 1];
				uint16 g = ((uint16)data[offset + 2] << 8) | data[offset + 3];
				uint16 b = ((uint16)data[offset + 4] << 8) | data[offset + 5];
				uint16 a = ((uint16)data[offset + 6] << 8) | data[offset + 7];
				pixel = Vector4(r / 65535.0f, g / 65535.0f, b / 65535.0f, a / 65535.0f);
			}
			else
			{
				pixel = Vector4(data[offset] / 255.0f, data[offset + 1] / 255.0f,
					data[offset + 2] / 255.0f, data[offset + 3] / 255.0f);
			}
		}

		return pixel;
	}

	private Vector4 ConvertPixelToRGBA(Vector4 pixel, PngHeader hdr, List<PaletteEntry> palette, TransparencyInfo* transparency)
	{
		var rgba = pixel;

		// Apply transparency based on color type
		switch (hdr.ColorType)
		{
		case 0: // Grayscale with tRNS
			if (transparency.GrayTransparent != 0)
			{
				uint16 grayValue = (uint16)(pixel.X * ((1 << hdr.BitDepth) - 1));
				if (grayValue == transparency.GrayTransparent)
					rgba.W = 0.0f; // Transparent
			}

		case 2: // RGB with tRNS
			if (transparency.RedTransparent != 0 || transparency.GreenTransparent != 0 || transparency.BlueTransparent != 0)
			{
				uint16 r = (uint16)(pixel.X * ((1 << hdr.BitDepth) - 1));
				uint16 g = (uint16)(pixel.Y * ((1 << hdr.BitDepth) - 1));
				uint16 b = (uint16)(pixel.Z * ((1 << hdr.BitDepth) - 1));

				if (r == transparency.RedTransparent &&
					g == transparency.GreenTransparent &&
					b == transparency.BlueTransparent)
				{
					rgba.W = 0.0f; // Transparent
				}
			}
		}

		return rgba;
	}

	private Vector4 ApplyGammaCorrection(Vector4 rgba, float gamma)
	{
		float invGamma = 1.0f / gamma;
		return Vector4(
			Math.Pow(rgba.X, invGamma),
			Math.Pow(rgba.Y, invGamma),
			Math.Pow(rgba.Z, invGamma),
			rgba.W // Alpha not affected by gamma
			);
	}

	private Vector4 ApplySRGBCorrection(Vector4 rgba)
	{
		// Convert from sRGB to linear
		var linear = Vector4(
			SRGBToLinear(rgba.X),
			SRGBToLinear(rgba.Y),
			SRGBToLinear(rgba.Z),
			rgba.W
			);
		return linear;
	}

	private float SRGBToLinear(float srgb)
	{
		if (srgb <= 0.04045f)
			return srgb / 12.92f;
		else
			return Math.Pow((srgb + 0.055f) / 1.055f, 2.4f);
	}

	private void WritePixel(uint8[] output, int offset, Vector4 rgba, Image.PixelFormat format)
	{
		switch (format)
		{
		case .R8:
			output[offset] = (uint8)(Math.Clamp(rgba.X * 255.0f, 0, 255));

		case .RG8:
			output[offset] = (uint8)(Math.Clamp(rgba.X * 255.0f, 0, 255));
			output[offset + 1] = (uint8)(Math.Clamp(rgba.W * 255.0f, 0, 255)); // Alpha in G channel

		case .RGB8:
			output[offset] = (uint8)(Math.Clamp(rgba.X * 255.0f, 0, 255));
			output[offset + 1] = (uint8)(Math.Clamp(rgba.Y * 255.0f, 0, 255));
			output[offset + 2] = (uint8)(Math.Clamp(rgba.Z * 255.0f, 0, 255));

		case .RGBA8:
			output[offset] = (uint8)(Math.Clamp(rgba.X * 255.0f, 0, 255));
			output[offset + 1] = (uint8)(Math.Clamp(rgba.Y * 255.0f, 0, 255));
			output[offset + 2] = (uint8)(Math.Clamp(rgba.Z * 255.0f, 0, 255));
			output[offset + 3] = (uint8)(Math.Clamp(rgba.W * 255.0f, 0, 255));

		case .R16F:
			var r16 = (uint16)(Math.Clamp(rgba.X * 65535.0f, 0, 65535));
			output[offset] = (uint8)(r16 >> 8);
			output[offset + 1] = (uint8)(r16 & 0xFF);

		case .RG16F:
			var r16f = (uint16)(Math.Clamp(rgba.X * 65535.0f, 0, 65535));
			var a16f = (uint16)(Math.Clamp(rgba.W * 65535.0f, 0, 65535));
			output[offset] = (uint8)(r16f >> 8);
			output[offset + 1] = (uint8)(r16f & 0xFF);
			output[offset + 2] = (uint8)(a16f >> 8);
			output[offset + 3] = (uint8)(a16f & 0xFF);

		case .RGB16F:
			var r16rgb = (uint16)(Math.Clamp(rgba.X * 65535.0f, 0, 65535));
			var g16rgb = (uint16)(Math.Clamp(rgba.Y * 65535.0f, 0, 65535));
			var b16rgb = (uint16)(Math.Clamp(rgba.Z * 65535.0f, 0, 65535));
			output[offset] = (uint8)(r16rgb >> 8);
			output[offset + 1] = (uint8)(r16rgb & 0xFF);
			output[offset + 2] = (uint8)(g16rgb >> 8);
			output[offset + 3] = (uint8)(g16rgb & 0xFF);
			output[offset + 4] = (uint8)(b16rgb >> 8);
			output[offset + 5] = (uint8)(b16rgb & 0xFF);

		case .RGBA16F:
			var r16rgba = (uint16)(Math.Clamp(rgba.X * 65535.0f, 0, 65535));
			var g16rgba = (uint16)(Math.Clamp(rgba.Y * 65535.0f, 0, 65535));
			var b16rgba = (uint16)(Math.Clamp(rgba.Z * 65535.0f, 0, 65535));
			var a16rgba = (uint16)(Math.Clamp(rgba.W * 65535.0f, 0, 65535));
			output[offset] = (uint8)(r16rgba >> 8);
			output[offset + 1] = (uint8)(r16rgba & 0xFF);
			output[offset + 2] = (uint8)(g16rgba >> 8);
			output[offset + 3] = (uint8)(g16rgba & 0xFF);
			output[offset + 4] = (uint8)(b16rgba >> 8);
			output[offset + 5] = (uint8)(b16rgba & 0xFF);
			output[offset + 6] = (uint8)(a16rgba >> 8);
			output[offset + 7] = (uint8)(a16rgba & 0xFF);

		default:
			// Fallback to RGBA8
			output[offset] = (uint8)(Math.Clamp(rgba.X * 255.0f, 0, 255));
			output[offset + 1] = (uint8)(Math.Clamp(rgba.Y * 255.0f, 0, 255));
			output[offset + 2] = (uint8)(Math.Clamp(rgba.Z * 255.0f, 0, 255));
			output[offset + 3] = (uint8)(Math.Clamp(rgba.W * 255.0f, 0, 255));
		}
	}

	private void ApplySubFilter(Span<uint8> row, int bytesPerPixel)
	{
		for (int i = bytesPerPixel; i < row.Length; i++)
		{
			row[i] = (uint8)(row[i] + row[i - bytesPerPixel]);
		}
	}

	private void ApplyUpFilter(Span<uint8> row, Span<uint8> prevRow)
	{
		for (int i = 0; i < row.Length; i++)
		{
			row[i] = (uint8)(row[i] + prevRow[i]);
		}
	}

	private void ApplyAverageFilter(Span<uint8> row, Span<uint8> prevRow, int bytesPerPixel)
	{
		for (int i = 0; i < row.Length; i++)
		{
			uint8 left = (i >= bytesPerPixel) ? row[i - bytesPerPixel] : 0;
			uint8 up = prevRow[i];
			row[i] = (uint8)(row[i] + ((left + up) / 2));
		}
	}

	private void ApplyPaethFilter(Span<uint8> row, Span<uint8> prevRow, int bytesPerPixel)
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

	private uint8 PaethPredictor(uint8 a, uint8 b, uint8 c)
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