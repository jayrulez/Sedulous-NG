using System;
namespace Sedulous.IO.Tests;

class StreamInteropTests
{
    [Test]
    public static void MemoryToPagedStream()
    {
        // Write to memory stream
        let memStream = scope OutputMemoryStream();
        memStream.Write<int32>(42);
        memStream.Write<float>(3.14f);
        
        // Copy to paged stream
        let pagedStream = scope OutputPagedStream();
        pagedStream.Write(memStream.Data, memStream.Size);
        
        // Read from paged stream
        let input = scope InputPagedStream(pagedStream);
        Test.Assert(input.Read<int32>() == 42);
        Test.Assert(input.Read<float>() == 3.14f);
    }

    [Test]
    public static void InputMemoryFromOutputMemory()
    {
        let output = scope OutputMemoryStream();
        output.Write<int32>(100);
        output.Write<int32>(200);
        
        let input = scope InputMemoryStream(output);
        Test.Assert(input.Size == 8);
        Test.Assert(input.Read<int32>() == 100);
        Test.Assert(input.Read<int32>() == 200);
    }
	
	[Test]
    public static void TestRoundtripMemory() 
    {
        let output = scope OutputMemoryStream();
        
        // Write all supported types
        output.Write((uint)42);
        output.Write<int>((int)-42);
        output.Write((uint64)0x123456789ABCDEF0);
        output.Write((int64)-0x123456789ABCDEF0);
        output.Write((uint32)0x12345678);
        output.Write((int32)-0x12345678);
        output.Write((float)3.14f);
        output.Write((double)2.71828);
        output.Write(StringView("Hello"));
        
        // Create appropriate input stream
        InputMemoryStream input = scope:: InputMemoryStream((OutputMemoryStream)output);
        
        // Read back and verify
        Test.Assert(input.Read<uint>() == 42);
        Test.Assert(input.Read<int>() == -42);
        Test.Assert(input.Read<uint64>() == 0x123456789ABCDEF0);
        Test.Assert(input.Read<int64>() == -0x123456789ABCDEF0);
        Test.Assert(input.Read<uint32>() == 0x12345678);
        Test.Assert(input.Read<int32>() == -0x12345678);
        Test.Assert(Math.Abs(input.Read<float>() - 3.14f) < 0.0001f);
        Test.Assert(Math.Abs(input.Read<double>() - 2.71828) < 0.000001);
        
        uint8[10] strBuffer = .();
        input.Read(&strBuffer, 5);
        Test.Assert(StringView((char8*)&strBuffer, 5) == "Hello");
    }
	
	[Test]
    public static void TestRoundtripPaged()
    {
        let output = scope OutputPagedStream();
        
        // Write all supported types
        output.Write((uint)42);
        output.Write<int>((int)-42);
        output.Write((uint64)0x123456789ABCDEF0);
        output.Write((int64)-0x123456789ABCDEF0);
        output.Write((uint32)0x12345678);
        output.Write((int32)-0x12345678);
        output.Write((float)3.14f);
        output.Write((double)2.71828);
        output.Write(StringView("Hello"));
        
        // Create appropriate input stream
        InputPagedStream input = scope:: InputPagedStream((OutputPagedStream)output);
        
        // Read back and verify
        Test.Assert(input.Read<uint>() == 42);
        Test.Assert(input.Read<int>() == -42);
        Test.Assert(input.Read<uint64>() == 0x123456789ABCDEF0);
        Test.Assert(input.Read<int64>() == -0x123456789ABCDEF0);
        Test.Assert(input.Read<uint32>() == 0x12345678);
        Test.Assert(input.Read<int32>() == -0x12345678);
        Test.Assert(Math.Abs(input.Read<float>() - 3.14f) < 0.0001f);
        Test.Assert(Math.Abs(input.Read<double>() - 2.71828) < 0.000001);
        
        uint8[10] strBuffer = .();
        input.Read(&strBuffer, 5);
        Test.Assert(StringView((char8*)&strBuffer, 5) == "Hello");
    }
}