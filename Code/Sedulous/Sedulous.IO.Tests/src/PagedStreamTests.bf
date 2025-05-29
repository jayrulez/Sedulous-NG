using System;
namespace Sedulous.IO.Tests;


class PagedStreamTests
{
	[Test]
	public static void OutputPagedStream_BasicWrite()
	{
		let output = scope OutputPagedStream();

		// Write some data
		Test.Assert(output.Write<int32>(42));
		Test.Assert(output.Write<float>(3.14f));
		Test.Assert(output.Write<uint64>(0x123456789ABCDEF0));

		// Create input stream and verify
		let input = scope InputPagedStream(output);
		Test.Assert(input.Size == 16);

		Test.Assert(input.Read<int32>() == 42);
		Test.Assert(input.Read<float>() == 3.14f);
		Test.Assert(input.Read<uint64>() == 0x123456789ABCDEF0);
		Test.Assert(input.IsEnd);
	}

	[Test]
	public static void OutputPagedStream_LargeWrite()
	{
		let output = scope OutputPagedStream();

		// Write enough data to span multiple pages
		// Page size is 4096 - sizeof(Page*) - sizeof(int)
		const int32 dataSize = 10000;
		uint8* testData = new uint8[dataSize]*;
		defer delete testData;

		// Fill with pattern
		for (int32 i = 0; i < dataSize; i++)
		{
			testData[i] = (uint8)(i & 0xFF);
		}

		Test.Assert(output.Write(testData, dataSize));

		// Verify through input stream
		let input = scope InputPagedStream(output);
		Test.Assert(input.Size == dataSize);

		uint8* readBuffer = new uint8[dataSize]*;
		defer delete readBuffer;

		Test.Assert(input.Read(readBuffer, dataSize));

		// Verify pattern
		for (int32 i = 0; i < dataSize; i++)
		{
			Test.Assert(readBuffer[i] == (uint8)(i & 0xFF));
		}
		Test.Assert(input.IsEnd);
	}

	[Test]
	public static void InputPagedStream_PartialReads()
	{
		let output = scope OutputPagedStream();

		// Write data
		for (int32 i = 0; i < 100; i++)
		{
			output.Write<int32>(i);
		}

		let input = scope InputPagedStream(output);

		// Read in chunks
		int32[10] buffer = .();
		for (int chunk = 0; chunk < 10; chunk++)
		{
			Test.Assert(input.Read(&buffer, 40)); // 10 ints
			for (int i = 0; i < 10; i++)
			{
				Test.Assert(buffer[i] == chunk * 10 + i);
			}
		}
		Test.Assert(input.IsEnd);
	}

	[Test]
	public static void InputPagedStream_ReadPastEnd()
	{
		let output = scope OutputPagedStream();
		output.Write<int32>(42);

		let input = scope InputPagedStream(output);
		Test.Assert(input.Read<int32>() == 42);
		Test.Assert(input.IsEnd);

		// Try to read past end
		int32 value = 0;
		Test.Assert(!input.Read(&value, 4));
		Test.Assert(input.IsEnd);
	}

	[Test]
	public static void PagedStream_StringReadWrite()
	{
		let output = scope OutputPagedStream();

		String str1 = "Hello, World!";
		String str2 = "Testing paged streams";

		Test.Assert(output.Write(str1));
		Test.Assert(output.Write(str2));

		let input = scope InputPagedStream(output);

		uint8[100] buffer1 = .();
		uint8[100] buffer2 = .();

		Test.Assert(input.Read(&buffer1, str1.Length));
		Test.Assert(input.Read(&buffer2, str2.Length));

		Test.Assert(StringView((char8*)&buffer1, str1.Length) == str1);
		Test.Assert(StringView((char8*)&buffer2, str2.Length) == str2);
	}
	struct TestStruct
	{
		public int32 id;
		public float value;
		public uint8[8] data;
	}

	[Test]
	public static void PagedStream_MixedTypes()
	{
		let output = scope OutputPagedStream();

		// Write mixed data
		output.Write<uint8>(0xFF);
		output.Write<int16>(0x1234);

		TestStruct ts = .();
		ts.id = 42;
		ts.value = 3.14f;
		for (int i = 0; i < 8; i++)
			ts.data[i] = (uint8)i;
		output.Write<TestStruct>(ts);

		output.Write<double>(2.71828);

		// Read back
		let input = scope InputPagedStream(output);

		Test.Assert(input.Read<uint8>() == 0xFF);
		Test.Assert(input.Read<int16>() == 0x1234);

		TestStruct readTs = input.Read<TestStruct>();
		Test.Assert(readTs.id == 42);
		Test.Assert(readTs.value == 3.14f);
		for (int i = 0; i < 8; i++)
			Test.Assert(readTs.data[i] == (uint8)i);

		Test.Assert(input.Read<double>() == 2.71828);
		Test.Assert(input.IsEnd);
	}

	[Test]
	public static void InputPagedStream_EmptyStream()
	{
		let output = scope OutputPagedStream();
		let input = scope InputPagedStream(output);

		Test.Assert(input.Size == 0);
		Test.Assert(input.IsEnd);

		int32 value = 0;
		Test.Assert(!input.Read(&value, 4));
	}
}