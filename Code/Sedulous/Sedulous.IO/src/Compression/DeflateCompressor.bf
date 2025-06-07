using System;
using System.Collections;

using internal Sedulous.IO.Compression;

namespace Sedulous.IO.Compression;

// Simple deflate compressor (basic implementation)
internal class DeflateCompressor
{
    public Zlib.Result Compress(Span<uint8> input, List<uint8> output, Zlib.CompressionLevel level)
    {
        var writer = scope BitWriter(output);

		// Handle empty input - still need to write a block
		if (input.Length == 0)
		{
		    // Write a single empty uncompressed block
		    writer.WriteBits(1u, 1); // Last block = true
		    writer.WriteBits(0u, 2); // Uncompressed block
		    writer.AlignToByte();
		    
		    // Write length (0) as 2 bytes
			uint16 blockSize = 0;
			writer.WriteBytes(Span<uint8>((uint8*)&blockSize, 2));

		    // Write complement (0xFFFF) as 2 bytes  
			uint16 nlen = 0xFFFF;
			writer.WriteBytes(Span<uint8>((uint8*)&nlen, 2));
		    
		    // No data to write
		    return .Success;
		}

		// For simplicity, use uncompressed blocks
		int remaining = input.Length;
		int pos = 0;
        
        while (remaining > 0)
        {
            int blockSize = Math.Min(remaining, 65535);
            bool isLast = (remaining <= 65535);
            
            // Write block header
            writer.WriteBits(isLast ? 1u : 0u, 1);
            writer.WriteBits(0u, 2); // Uncompressed block
            
            // Align to byte boundary
            writer.AlignToByte();
            
            // Write length and complement
            writer.WriteBytes(Span<uint8>((uint8*)&blockSize, 2));
            uint16 nlen = (uint16)(~blockSize);
            writer.WriteBytes(Span<uint8>((uint8*)&nlen, 2));
            
            // Write data
            writer.WriteBytes(input.Slice(pos, blockSize));
            
            pos += blockSize;
            remaining -= blockSize;
        }
        
        return .Success;
    }
}