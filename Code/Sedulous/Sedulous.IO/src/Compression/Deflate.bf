using System.Collections;
using System;
using internal Sedulous.IO.Compression;
namespace Sedulous.IO.Compression;

// Deflate compression/decompression implementation
public static class Deflate
{
    public const int MAX_BITS = 15;
    private const int MAX_MATCH_LENGTH = 258;
    private const int MIN_MATCH_LENGTH = 3;
    public const int WINDOW_SIZE = 32768;
    
    public static Zlib.Result Compress(Span<uint8> input, List<uint8> output, Zlib.CompressionLevel level)
    {
        var compressor = scope DeflateCompressor();
        return compressor.Compress(input, output, level);
    }
    
    public static Zlib.Result Decompress(Span<uint8> input, List<uint8> output)
    {
        var decompressor = scope DeflateDecompressor();
        return decompressor.Decompress(input, output);
    }
}