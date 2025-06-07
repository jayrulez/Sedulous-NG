using System;
namespace Sedulous.IO.Compression;

// Adler-32 checksum implementation
public static class Adler32
{
    private const uint32 BASE = 65521;
    
    public static uint32 Calculate(Span<uint8> data)
    {
        uint32 a = 1;
        uint32 b = 0;
        
        for (var byte in data)
        {
            a = (a + byte) % BASE;
            b = (b + a) % BASE;
        }
        
        return (b << 16) | a;
    }
}