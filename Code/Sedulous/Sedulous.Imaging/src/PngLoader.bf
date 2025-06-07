using System;
using System.Collections;
using System.IO;
using Sedulous.IO.Compression;
namespace Sedulous.Imaging;

// PNG Loader implementation using simple PNG parsing
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
        if (fileSize <= 0 || fileSize > int.MaxValue)
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
		    Console.WriteLine($"Found chunk type: 0x{chunk.Type:X8}, length: {chunk.Length}");
		    if (chunk.Type == 0x49484452) // "IHDR"
		    {
		        Console.WriteLine("Found IHDR chunk!");
		        if (chunk.Length >= 13)
		        {
		            Console.WriteLine("IHDR chunk length is valid");
		            header = ParseIHDR(chunk);
		            Console.WriteLine($"ParseIHDR returned: {header != null}");
		            break;
		        }
		        else
		        {
		            Console.WriteLine($"IHDR chunk too short: {chunk.Length}");
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
        
        // Determine pixel format based on color type and bit depth
        Image.PixelFormat pixelFormat;
        int bytesPerPixel;
        
        switch (hdr.ColorType)
        {
        case 0: // Grayscale
            pixelFormat = .R8;
            bytesPerPixel = 1;
        case 2: // RGB
            pixelFormat = .RGB8;
            bytesPerPixel = 3;
        case 6: // RGBA
            pixelFormat = .RGBA8;
            bytesPerPixel = 4;
        default:
            loadInfo.Result = .UnsupportedFormat;
            loadInfo.ErrorMessage = new String("Unsupported PNG color type");
            return loadInfo;
        }
        
        // For this simple implementation, we only support 8-bit depth
        if (hdr.BitDepth != 8)
        {
            loadInfo.Result = .UnsupportedFormat;
            loadInfo.ErrorMessage = new String("Only 8-bit PNG files are supported");
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
        
        // Decompress IDAT data (simplified - in real implementation you'd use zlib)
        // For this example, we'll create a placeholder that assumes uncompressed data
        var decompressResult = DecompressImageData(idatData, hdr.Width, hdr.Height, bytesPerPixel);
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
    
    // Decompress IDAT data and apply PNG row filters
	private Result<uint8[]> DecompressImageData(List<uint8> compressedData, uint32 width, uint32 height, int bytesPerPixel)
	{
	    // Decompress using zlib
	    var decompressed = scope List<uint8>();
	    var zlibResult = Zlib.Decompress(compressedData, decompressed);
	    
	    if (zlibResult != .Success)
	        return .Err;
	    
	    // Calculate expected sizes
	    var rowSize = (int)width * bytesPerPixel + 1; // +1 for filter byte
	    var expectedSize = (int)height * rowSize;
	    
	    if (decompressed.Count != expectedSize)
	        return .Err;
	    
	    // Apply PNG row filters
	    var filteredData = scope uint8[decompressed.Count];
	    decompressed.CopyTo(filteredData);
	    
	    var outputSize = (int)(width * height * bytesPerPixel);
	    var output = new uint8[outputSize];
	    var outputPos = 0;
	    
	    for (uint32 y = 0; y < height; y++)
	    {
	        var rowStart = (int)y * rowSize;
	        var filterType = filteredData[rowStart];
	        var rowData = Span<uint8>(&filteredData[rowStart + 1], (int)width * bytesPerPixel);
	        
	        // Apply reverse filter
	        switch (filterType)
	        {
	        case 0: // None
	            break;
	        case 1: // Sub
	            ApplySubFilter(rowData, bytesPerPixel);
	        case 2: // Up
	            if (y > 0)
	            {
	                var prevRowStart = (int)(y - 1) * rowSize + 1;
	                var prevRowData = Span<uint8>(&filteredData[prevRowStart], (int)width * bytesPerPixel);
	                ApplyUpFilter(rowData, prevRowData);
	            }
	        case 3: // Average
	            if (y > 0)
	            {
	                var prevRowStart = (int)(y - 1) * rowSize + 1;
	                var prevRowData = Span<uint8>(&filteredData[prevRowStart], (int)width * bytesPerPixel);
	                ApplyAverageFilter(rowData, prevRowData, bytesPerPixel);
	            }
	            else
	            {
	                ApplySubFilter(rowData, bytesPerPixel);
	            }
	        case 4: // Paeth
	            if (y > 0)
	            {
	                var prevRowStart = (int)(y - 1) * rowSize + 1;
	                var prevRowData = Span<uint8>(&filteredData[prevRowStart], (int)width * bytesPerPixel);
	                ApplyPaethFilter(rowData, prevRowData, bytesPerPixel);
	            }
	            else
	            {
	                ApplySubFilter(rowData, bytesPerPixel);
	            }
	        default:
	            // Unknown filter type
	            delete output;
	            return .Err;
	        }
	        
	        // Copy filtered row to output
	        rowData.CopyTo(Span<uint8>(&output[outputPos], rowData.Length));
	        outputPos += rowData.Length;
	    }
	    
	    return output;
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