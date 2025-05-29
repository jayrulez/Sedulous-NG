using System;
using System.Collections;
namespace Sedulous.IO.Tests;


class InputMemoryStreamTests
{
    [Test]
    public static void Constructor_WithPointerAndSize()
    {
        uint8[100] buffer = .();
        let stream = scope InputMemoryStream(&buffer, 100);
        
        Test.Assert(stream.Size == 100);
        Test.Assert(stream.Position == 0);
        Test.Assert(stream.Remaining == 100);
        Test.Assert(!stream.HasOverflow);
    }

    [Test]
    public static void Constructor_WithSpan()
    {
        uint8[50] buffer = .();
        Span<uint8> span = .(&buffer[0], 50);
        let stream = scope InputMemoryStream(span);
        
        Test.Assert(stream.Size == 50);
        Test.Assert(stream.Position == 0);
    }

    [Test]
    public static void Read_BasicTypes()
    {
        uint8[20] buffer = .();
        *(int32*)&buffer[0] = 42;
        *(float*)&buffer[4] = 3.14f;
        *(uint64*)&buffer[8] = 0x123456789ABCDEF0;
        
        let stream = scope InputMemoryStream(&buffer, 20);
        
        int32 intVal = stream.Read<int32>();
        Test.Assert(intVal == 42);
        Test.Assert(stream.Position == 4);
        
        float floatVal = stream.Read<float>();
        Test.Assert(floatVal == 3.14f);
        Test.Assert(stream.Position == 8);
        
        uint64 longVal = stream.Read<uint64>();
        Test.Assert(longVal == 0x123456789ABCDEF0);
        Test.Assert(stream.Position == 16);
    }

    [Test]
    public static void Read_Array()
    {
        uint8[100] buffer = .();
        *(int*)&buffer[0] = 3; // count
        *(int32*)&buffer[8] = 10;
        *(int32*)&buffer[12] = 20;
        *(int32*)&buffer[16] = 30;
        
        var stream = scope InputMemoryStream(&buffer, 100);
        var values = scope List<int32>();
        
        stream.ReadList<int32>(values);
        Test.Assert(values.Count == 3);
        Test.Assert(values[0] == 10);
        Test.Assert(values[1] == 20);
        Test.Assert(values[2] == 30);
    }

    [Test]
    public static void Read_Overflow()
    {
        uint8[4] buffer = .();
        let stream = scope InputMemoryStream(&buffer, 4);
        
        uint64 val = 0;
        bool result = stream.Read(&val, 8);
        
        Test.Assert(!result);
        Test.Assert(stream.HasOverflow);
        Test.Assert(val == 0); // Should be zeroed on overflow
    }

    [Test]
    public static void Skip()
    {
        uint8[20] buffer = .();
        let stream = scope InputMemoryStream(&buffer, 20);
        
        void* ptr = stream.Skip(10);
        Test.Assert(ptr == &buffer[0]);
        Test.Assert(stream.Position == 10);
        Test.Assert(stream.Remaining == 10);
        
        // Skip past end should set overflow
        stream.Skip(15);
        Test.Assert(stream.HasOverflow);
        Test.Assert(stream.Position == 20);
    }

    [Test]
    public static void ReadString()
    {
        uint8[20] buffer = .();
        String testStr = "Hello";
        Internal.MemCpy(&buffer[0], testStr.Ptr, testStr.Length);
        buffer[testStr.Length] = 0; // null terminator
        
        let stream = scope InputMemoryStream(&buffer, 20);
        char8* str = stream.ReadString();
        
        Test.Assert(StringView(str) == "Hello");
        Test.Assert(stream.Position == 6); // "Hello" + null
    }

    [Test]
    public static void Set_ResetsStream()
    {
        uint8[10] oldBuffer = .();
        uint8[20] newBuffer = .();
        
        let stream = scope InputMemoryStream(&oldBuffer, 10);
        stream.Skip(5);
        Test.Assert(stream.Position == 5);
        
        stream.Set(&newBuffer, 20);
        Test.Assert(stream.Size == 20);
        Test.Assert(stream.Position == 0);
        Test.Assert(!stream.HasOverflow);
    }
        struct TestStruct
        {
            public int32 a;
            public float b;
        }

    [Test]
    public static void GetAs()
    {
        
        uint8[100] buffer = .();
        TestStruct* ts = (TestStruct*)&buffer[10];
        ts.a = 42;
        ts.b = 3.14f;
        
        let stream = scope InputMemoryStream(&buffer, 100);
        stream.Position = 10;
        
        TestStruct result = stream.GetAs<TestStruct>();
        Test.Assert(result.a == 42);
        Test.Assert(result.b == 3.14f);
    }
}