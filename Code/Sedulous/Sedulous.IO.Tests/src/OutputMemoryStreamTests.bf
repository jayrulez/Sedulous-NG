using System;
using System.Collections;
namespace Sedulous.IO.Tests;


class OutputMemoryStreamTests
{
    [Test]
    public static void Constructor_Default()
    {
        let stream = scope OutputMemoryStream();
        Test.Assert(stream.Size == 0);
        Test.Assert(stream.Capacity == 0);
        Test.Assert(stream.Empty);
    }

    [Test]
    public static void Constructor_WithBuffer()
    {
        uint8[100] buffer = .();
        let stream = scope OutputMemoryStream(&buffer, 100);
        Test.Assert(stream.Size == 0);
        Test.Assert(stream.Capacity == 100);
        Test.Assert(stream.Empty);
    }

    [Test]
    public static void Write_BasicTypes()
    {
        let stream = scope OutputMemoryStream();
        
        Test.Assert(stream.Write<int32>(42));
        Test.Assert(stream.Write<float>(3.14f));
        Test.Assert(stream.Write<uint64>(0x123456789ABCDEF0));
        
        Test.Assert(stream.Size == 16);
        Test.Assert(!stream.Empty);
        
        // Verify data
        int32* intPtr = (int32*)stream.Data;
        Test.Assert(*intPtr == 42);
        float* floatPtr = (float*)(stream.Data + 4);
        Test.Assert(*floatPtr == 3.14f);
        uint64* longPtr = (uint64*)(stream.Data + 8);
        Test.Assert(*longPtr == 0x123456789ABCDEF0);
    }

    [Test]
    public static void Write_Array()
    {
        let stream = scope OutputMemoryStream();
        let values = scope List<int32>();
        values.Add(10);
        values.Add(20);
        values.Add(30);
        
        Test.Assert(stream.WriteList<int32>(values));
        
        // Should write count first, then values
        Test.Assert(stream.Size == sizeof(int) + 12); // (4 or 8) + (3 * 4)
        var data = stream.Data;
        Test.Assert(*(int*)(void*)data == 3); // count
        Test.Assert((int32)*(int*)(void*)(data + sizeof(int) + 0) == 10);
        Test.Assert((int32)*(int*)(void*)(data + sizeof(int) + 4) == 20);
        Test.Assert((int32)*(int*)(void*)(data + sizeof(int) + 8) == 30);
    }

    [Test]
    public static void Write_String()
    {
        let stream = scope OutputMemoryStream();
        String str = "Hello";
        
        Test.Assert(stream.Write(str));
        Test.Assert(stream.Size == 6); // "Hello" + null
        
        char8* data = (char8*)stream.Data;
        Test.Assert(StringView(data) == "Hello");
        Test.Assert(data[5] == 0); // null terminator
    }

    [Test]
    public static void Reserve_GrowsCapacity()
    {
        let stream = scope OutputMemoryStream();
        Test.Assert(stream.Capacity == 0);
        
        stream.Reserve(100);
        Test.Assert(stream.Capacity >= 100);
        Test.Assert(stream.Size == 0); // Size shouldn't change
        
        // Data should be preserved
        stream.Write<int32>(42);
        int oldCapacity = stream.Capacity;
        stream.Reserve(200);
        Test.Assert(stream.Capacity >= 200);
        Test.Assert(*(int32*)stream.Data == 42);
    }

    [Test]
    public static void Resize()
    {
        let stream = scope OutputMemoryStream();
        stream.Write<int32>(42);
        Test.Assert(stream.Size == 4);
        
        stream.Resize(10);
        Test.Assert(stream.Size == 10);
        Test.Assert(*(int32*)stream.Data == 42); // Data preserved
        
        stream.Resize(2);
        Test.Assert(stream.Size == 2);
    }

    [Test]
    public static void Clear()
    {
        let stream = scope OutputMemoryStream();
        stream.Write<int32>(42);
        stream.Write<int32>(84);
        Test.Assert(stream.Size == 8);
        
        stream.Clear();
        Test.Assert(stream.Size == 0);
        Test.Assert(stream.Empty);
        // Capacity should remain
        Test.Assert(stream.Capacity >= 8);
    }

    [Test]
    public static void Skip()
    {
        let stream = scope OutputMemoryStream();
        
        void* ptr = stream.Skip(8);
        Test.Assert(stream.Size == 8);
        
        // Write directly to skipped area
        *(int32*)ptr = 42;
        *(int32*)((uint8*)ptr + 4) = 84;
        
        int32* data = (int32*)stream.Data;
        Test.Assert(data[0] == 42);
        Test.Assert(data[1] == 84);
    }

    [Test]
    public static void IndexOperator()
    {
        let stream = scope OutputMemoryStream();
        stream.Write<uint8>(10);
        stream.Write<uint8>(20);
        stream.Write<uint8>(30);
        
        Test.Assert(stream[0] == 10);
        Test.Assert(stream[1] == 20);
        Test.Assert(stream[2] == 30);
        
        stream[1] = 25;
        Test.Assert(stream[1] == 25);
    }

    [Test]
    public static void CopyConstructor()
    {
        let stream1 = scope OutputMemoryStream();
        stream1.Write<int32>(42);
        stream1.Write<float>(3.14f);
        
        let stream2 = scope OutputMemoryStream(stream1);
        Test.Assert(stream2.Size == stream1.Size);
        Test.Assert(*(int32*)stream2.Data == 42);
        Test.Assert(*(float*)(stream2.Data + 4) == 3.14f);
        
        // Modifying stream2 shouldn't affect stream1
        stream2.Write<int32>(100);
        Test.Assert(stream1.Size == 8);
        Test.Assert(stream2.Size == 12);
    }
}