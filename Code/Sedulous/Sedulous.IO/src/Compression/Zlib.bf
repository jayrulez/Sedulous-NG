using System;
using System.Collections;

using internal Sedulous.IO.Compression;

namespace Sedulous.IO.Compression;

public static class Zlib
{
    public enum CompressionLevel
    {
        NoCompression = 0,
        BestSpeed = 1,
        Default = 6,
        BestCompression = 9
    }
    
    public enum Result
    {
        Success,
        InvalidData,
        InvalidChecksum,
        BufferTooSmall,
        OutOfMemory
    }
    
    // Compress data using zlib format
    public static Result Compress(Span<uint8> input, List<uint8> output, CompressionLevel level = .Default)
    {
        output.Clear();
        
        // Zlib header (2 bytes)
        uint8 cmf = 0x78; // CM=8 (deflate), CINFO=7 (32K window)
        uint8 flg = 0x9C; // FCHECK, FDICT=0, FLEVEL=2 (default)
        
        // Adjust FLG based on compression level
        switch (level)
        {
        case .NoCompression, .BestSpeed:
            flg = 0x01;
        case .Default:
            flg = 0x9C;
        case .BestCompression:
            flg = 0xDA;
        }
        
        // Ensure (CMF*256 + FLG) % 31 == 0
        uint16 check = (uint16)(cmf * 256 + flg);
        flg = (uint8)(flg + (31 - (check % 31)) % 31);
        
        output.Add(cmf);
        output.Add(flg);
        
        // Compress the data using deflate
        var deflateResult = Deflate.Compress(input, output, level);
        if (deflateResult != .Success)
            return deflateResult;
        
        // Add Adler-32 checksum (4 bytes, big-endian)
        uint32 adler = Adler32.Calculate(input);
        output.Add((uint8)(adler >> 24));
        output.Add((uint8)(adler >> 16));
        output.Add((uint8)(adler >> 8));
        output.Add((uint8)adler);
        
        return .Success;
    }
    
    // Decompress zlib data
    public static Result Decompress(Span<uint8> input, List<uint8> output)
    {
        output.Clear();
        
        if (input.Length < 6) // Minimum: 2 header + 4 checksum
            return .InvalidData;
        
        // Parse zlib header
        uint8 cmf = input[0];
        uint8 flg = input[1];
        
        // Verify header checksum
        if (((cmf * 256 + flg) % 31) != 0)
            return .InvalidData;
        
        // Check compression method
        if ((cmf & 0x0F) != 8) // Must be deflate
            return .InvalidData;
        
        // Check for preset dictionary (not supported)
        if ((flg & 0x20) != 0)
            return .InvalidData;
        
        // Extract compressed data (excluding header and checksum)
        var compressedData = input.Slice(2, input.Length - 6);
        
        // Decompress using deflate
        var deflateResult = Deflate.Decompress(compressedData, output);
        if (deflateResult != .Success)
            return deflateResult;
        
        // Verify Adler-32 checksum
        uint32 expectedAdler = ((uint32)input[input.Length - 4] << 24) |
                              ((uint32)input[input.Length - 3] << 16) |
                              ((uint32)input[input.Length - 2] << 8) |
                               (uint32)input[input.Length - 1];
        
        uint32 actualAdler = Adler32.Calculate(output);
        if (actualAdler != expectedAdler)
            return .InvalidChecksum;
        
        return .Success;
    }
}











