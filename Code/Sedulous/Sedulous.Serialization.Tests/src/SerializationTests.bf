namespace Sedulous.Serialization.Tests;

namespace Serialization.Tests;

using System;
using Sedulous.Serialization;

class BinarySerializerTests
{
    // === Boolean Tests ===
    
    [Test]
    static void WriteBool_True_ReadsBackTrue()
    {
        var serializer = scope BinarySerializer();
        serializer.Write(true);
        serializer.Reset();
        
        let result = serializer.ReadBool();
        Test.Assert(result case .Ok(true));
    }
    
    [Test]
    static void WriteBool_False_ReadsBackFalse()
    {
        var serializer = scope BinarySerializer();
        serializer.Write(false);
        serializer.Reset();
        
        let result = serializer.ReadBool();
        Test.Assert(result case .Ok(false));
    }
    
    // === Integer Tests ===
    
    [Test]
    static void WriteInt8_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        serializer.Write((int8)-42);
        serializer.Reset();
        
        let result = serializer.ReadInt8();
        Test.Assert(result case .Ok(-42));
    }
    
    [Test]
    static void WriteInt8_MinMax_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        serializer.Write(int8.MinValue);
        serializer.Write(int8.MaxValue);
        serializer.Reset();
        
        Test.Assert(serializer.ReadInt8() case .Ok(int8.MinValue));
        Test.Assert(serializer.ReadInt8() case .Ok(int8.MaxValue));
    }
    
    [Test]
    static void WriteInt16_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        serializer.Write((int16)-12345);
        serializer.Reset();
        
        let result = serializer.ReadInt16();
        Test.Assert(result case .Ok(-12345));
    }
    
    [Test]
    static void WriteInt16_MinMax_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        serializer.Write(int16.MinValue);
        serializer.Write(int16.MaxValue);
        serializer.Reset();
        
        Test.Assert(serializer.ReadInt16() case .Ok(int16.MinValue));
        Test.Assert(serializer.ReadInt16() case .Ok(int16.MaxValue));
    }
    
    [Test]
    static void WriteInt32_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        serializer.Write((int32)-1234567890);
        serializer.Reset();
        
        let result = serializer.ReadInt32();
        Test.Assert(result case .Ok(-1234567890));
    }
    
    [Test]
    static void WriteInt32_MinMax_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        serializer.Write(int32.MinValue);
        serializer.Write(int32.MaxValue);
        serializer.Reset();
        
        Test.Assert(serializer.ReadInt32() case .Ok(int32.MinValue));
        Test.Assert(serializer.ReadInt32() case .Ok(int32.MaxValue));
    }
    
    [Test]
    static void WriteInt64_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        serializer.Write((int64)-1234567890123456789);
        serializer.Reset();
        
        let result = serializer.ReadInt64();
        Test.Assert(result case .Ok(-1234567890123456789));
    }
    
    [Test]
    static void WriteInt64_MinMax_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        serializer.Write(int64.MinValue);
        serializer.Write(int64.MaxValue);
        serializer.Reset();
        
        Test.Assert(serializer.ReadInt64() case .Ok(int64.MinValue));
        Test.Assert(serializer.ReadInt64() case .Ok(int64.MaxValue));
    }
    
    // === Unsigned Integer Tests ===
    
    [Test]
    static void WriteUInt8_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        serializer.Write((uint8)255);
        serializer.Reset();
        
        let result = serializer.ReadUInt8();
        Test.Assert(result case .Ok(255));
    }
    
    [Test]
    static void WriteUInt16_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        serializer.Write((uint16)65535);
        serializer.Reset();
        
        let result = serializer.ReadUInt16();
        Test.Assert(result case .Ok(65535));
    }
    
    [Test]
    static void WriteUInt32_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        serializer.Write((uint32)4294967295);
        serializer.Reset();
        
        let result = serializer.ReadUInt32();
        Test.Assert(result case .Ok(4294967295));
    }
    
    [Test]
    static void WriteUInt64_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        serializer.Write(uint64.MaxValue);
        serializer.Reset();
        
        let result = serializer.ReadUInt64();
        Test.Assert(result case .Ok(uint64.MaxValue));
    }
    
    // === Floating Point Tests ===
    
    [Test]
    static void WriteFloat_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        serializer.Write(3.14159f);
        serializer.Reset();
        
        let result = serializer.ReadFloat();
        Test.Assert(result case .Ok(let val));
        Test.Assert(Math.Abs(val - 3.14159f) < 0.00001f);
    }
    
    [Test]
    static void WriteFloat_Negative_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        serializer.Write(-123.456f);
        serializer.Reset();
        
        let result = serializer.ReadFloat();
        Test.Assert(result case .Ok(let val));
        Test.Assert(Math.Abs(val - (-123.456f)) < 0.001f);
    }
    
    [Test]
    static void WriteFloat_Zero_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        serializer.Write(0.0f);
        serializer.Reset();
        
        let result = serializer.ReadFloat();
        Test.Assert(result case .Ok(0.0f));
    }
    
    [Test]
    static void WriteDouble_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        serializer.Write(3.141592653589793);
        serializer.Reset();
        
        let result = serializer.ReadDouble();
        Test.Assert(result case .Ok(let val));
        Test.Assert(Math.Abs(val - 3.141592653589793) < 0.000000000001);
    }
    
    [Test]
    static void WriteDouble_VerySmall_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        serializer.Write(1.0e-300);
        serializer.Reset();
        
        let result = serializer.ReadDouble();
        Test.Assert(result case .Ok(let val));
        Test.Assert(Math.Abs(val - 1.0e-300) < 1.0e-310);
    }
    
    // === String Tests ===
    
    [Test]
    static void WriteString_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        serializer.Write("Hello, World!");
        serializer.Reset();
        
        var result = scope String();
        Test.Assert(serializer.ReadString(result) case .Ok);
        Test.Assert(result == "Hello, World!");
    }
    
    [Test]
    static void WriteString_Empty_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        serializer.Write("");
        serializer.Reset();
        
        var result = scope String();
        Test.Assert(serializer.ReadString(result) case .Ok);
        Test.Assert(result.IsEmpty);
    }
    
    [Test]
    static void WriteString_LongString_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        var longString = scope String();
        for (int i = 0; i < 1000; i++)
            longString.Append("ABCDEFGHIJ");
        
        serializer.Write(longString);
        serializer.Reset();
        
        var result = scope String();
        Test.Assert(serializer.ReadString(result) case .Ok);
        Test.Assert(result == longString);
    }
    
    [Test]
    static void WriteString_SpecialChars_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        serializer.Write("Tab:\tNewline:\nNull:\0End");
        serializer.Reset();
        
        var result = scope String();
        Test.Assert(serializer.ReadString(result) case .Ok);
        Test.Assert(result == "Tab:\tNewline:\nNull:\0End");
    }
    
    // === Multiple Values Tests ===
    
    [Test]
    static void WriteMultipleValues_ReadsBackInOrder()
    {
        var serializer = scope BinarySerializer();
        serializer.Write(true);
        serializer.Write((int32)42);
        serializer.Write(3.14f);
        serializer.Write("test");
        serializer.Reset();
        
        Test.Assert(serializer.ReadBool() case .Ok(true));
        Test.Assert(serializer.ReadInt32() case .Ok(42));
        
        let floatResult = serializer.ReadFloat();
        Test.Assert(floatResult case .Ok(let val));
        Test.Assert(Math.Abs(val - 3.14f) < 0.001f);
        
        var str = scope String();
        Test.Assert(serializer.ReadString(str) case .Ok);
        Test.Assert(str == "test");
    }
    
    // === Error Handling Tests ===
    
    [Test]
    static void ReadBool_EmptyBuffer_ReturnsError()
    {
        var serializer = scope BinarySerializer();
        Test.Assert(serializer.ReadBool() case .Err);
    }
    
    [Test]
    static void ReadInt32_InsufficientData_ReturnsError()
    {
        var serializer = scope BinarySerializer();
        serializer.Write((uint8)1);  // Only 1 byte
        serializer.Reset();
        
        Test.Assert(serializer.ReadInt32() case .Err);  // Needs 4 bytes
    }
    
    [Test]
    static void ReadInt64_InsufficientData_ReturnsError()
    {
        var serializer = scope BinarySerializer();
        serializer.Write((int32)1);  // Only 4 bytes
        serializer.Reset();
        
        Test.Assert(serializer.ReadInt64() case .Err);  // Needs 8 bytes
    }
    
    [Test]
    static void ReadString_InsufficientData_ReturnsError()
    {
        var serializer = scope BinarySerializer();
        serializer.Write((int32)100);  // Says string is 100 bytes
        serializer.Write((uint8)'A');  // But only 1 byte of data
        serializer.Reset();
        
        var str = scope String();
        Test.Assert(serializer.ReadString(str) case .Err);
    }
    
    // === Buffer State Tests ===
    
    [Test]
    static void Reset_AllowsReread()
    {
        var serializer = scope BinarySerializer();
        serializer.Write((int32)42);
        serializer.Reset();
        
        Test.Assert(serializer.ReadInt32() case .Ok(42));
        
        serializer.Reset();
        Test.Assert(serializer.ReadInt32() case .Ok(42));
    }
    
    [Test]
    static void Clear_EmptiesBuffer()
    {
        var serializer = scope BinarySerializer();
        serializer.Write((int32)42);
        serializer.Clear();
        
        Test.Assert(serializer.Data.Length == 0);
        Test.Assert(serializer.Position == 0);
    }
    
    [Test]
    static void Position_TracksReadProgress()
    {
        var serializer = scope BinarySerializer();
        serializer.Write((int32)1);
        serializer.Write((int32)2);
        serializer.Reset();
        
        Test.Assert(serializer.Position == 0);
        serializer.ReadInt32();
        Test.Assert(serializer.Position == 4);
        serializer.ReadInt32();
        Test.Assert(serializer.Position == 8);
    }
    
    [Test]
    static void Data_ReturnsCorrectSize()
    {
        var serializer = scope BinarySerializer();
        serializer.Write((int32)42);      // 4 bytes
        serializer.Write((int16)10);      // 2 bytes
        serializer.Write(true);            // 1 byte
        
        Test.Assert(serializer.Data.Length == 7);
    }
    
    // === Constructor with Data Tests ===
    
    [Test]
    static void ConstructorWithData_CanReadImmediately()
    {
        // Create initial data
        var writer = scope BinarySerializer();
        writer.Write((int32)12345);
        writer.Write("hello");
        
        // Create new serializer from that data
        var reader = scope BinarySerializer(writer.Data);
        
        Test.Assert(reader.ReadInt32() case .Ok(12345));
        var str = scope String();
        Test.Assert(reader.ReadString(str) case .Ok);
        Test.Assert(str == "hello");
    }
}

// === ISerializable Object Tests ===

class TestPlayer : ISerializable
{
    public String Name = new .() ~ delete _;
    public int32 Health;
    public float X, Y;
    public bool IsAlive;
    
    public void Serialize(ISerializer s)
    {
        s.Write(Name);
        s.Write(Health);
        s.Write(X);
        s.Write(Y);
        s.Write(IsAlive);
    }
    
    public void Deserialize(ISerializer s)
    {
        s.ReadString(Name);
        Health = s.ReadInt32();
        X = s.ReadFloat();
        Y = s.ReadFloat();
        IsAlive = s.ReadBool();
    }
}

class NestedObject : ISerializable
{
    public int32 Value;
    public TestPlayer Player = new .() ~ delete _;
    
    public void Serialize(ISerializer s)
    {
        s.Write(Value);
        s.WriteObject(Player);
    }
    
    public void Deserialize(ISerializer s)
    {
        Value = s.ReadInt32();
        s.ReadObject(Player);
    }
}

class SerializableObjectTests
{
    [Test]
    static void SerializePlayer_DeserializesCorrectly()
    {
        var serializer = scope BinarySerializer();
        
        var player = scope TestPlayer();
        player.Name.Set("TestHero");
        player.Health = 100;
        player.X = 10.5f;
        player.Y = 20.75f;
        player.IsAlive = true;
        
        player.Serialize(serializer);
        serializer.Reset();
        
        var loaded = scope TestPlayer();
        loaded.Deserialize(serializer);
        
        Test.Assert(loaded.Name == "TestHero");
        Test.Assert(loaded.Health == 100);
        Test.Assert(Math.Abs(loaded.X - 10.5f) < 0.001f);
        Test.Assert(Math.Abs(loaded.Y - 20.75f) < 0.001f);
        Test.Assert(loaded.IsAlive == true);
    }
    
    [Test]
    static void SerializePlayer_DeadPlayer_DeserializesCorrectly()
    {
        var serializer = scope BinarySerializer();
        
        var player = scope TestPlayer();
        player.Name.Set("FallenHero");
        player.Health = 0;
        player.X = -5.0f;
        player.Y = -10.0f;
        player.IsAlive = false;
        
        player.Serialize(serializer);
        serializer.Reset();
        
        var loaded = scope TestPlayer();
        loaded.Deserialize(serializer);
        
        Test.Assert(loaded.Name == "FallenHero");
        Test.Assert(loaded.Health == 0);
        Test.Assert(loaded.IsAlive == false);
    }
    
    [Test]
    static void WriteObject_ReadsBackCorrectly()
    {
        var serializer = scope BinarySerializer();
        
        var player = scope TestPlayer();
        player.Name.Set("Hero");
        player.Health = 50;
        player.X = 1.0f;
        player.Y = 2.0f;
        player.IsAlive = true;
        
        serializer.WriteObject(player);
        serializer.Reset();
        
        var loaded = scope TestPlayer();
        Test.Assert(serializer.ReadObject(loaded) case .Ok);
        Test.Assert(loaded.Name == "Hero");
        Test.Assert(loaded.Health == 50);
    }
    
    [Test]
    static void NestedObject_SerializesAndDeserializes()
    {
        var serializer = scope BinarySerializer();
        
        var nested = scope NestedObject();
        nested.Value = 999;
        nested.Player.Name.Set("NestedPlayer");
        nested.Player.Health = 75;
        nested.Player.X = 100.0f;
        nested.Player.Y = 200.0f;
        nested.Player.IsAlive = true;
        
        nested.Serialize(serializer);
        serializer.Reset();
        
        var loaded = scope NestedObject();
        loaded.Deserialize(serializer);
        
        Test.Assert(loaded.Value == 999);
        Test.Assert(loaded.Player.Name == "NestedPlayer");
        Test.Assert(loaded.Player.Health == 75);
        Test.Assert(Math.Abs(loaded.Player.X - 100.0f) < 0.001f);
        Test.Assert(Math.Abs(loaded.Player.Y - 200.0f) < 0.001f);
        Test.Assert(loaded.Player.IsAlive == true);
    }
    
    [Test]
    static void MultipleObjects_SerializeInSequence()
    {
        var serializer = scope BinarySerializer();
        
        var player1 = scope TestPlayer();
        player1.Name.Set("Player1");
        player1.Health = 100;
        player1.X = 0; player1.Y = 0;
        player1.IsAlive = true;
        
        var player2 = scope TestPlayer();
        player2.Name.Set("Player2");
        player2.Health = 80;
        player2.X = 10; player2.Y = 20;
        player2.IsAlive = true;
        
        serializer.WriteObject(player1);
        serializer.WriteObject(player2);
        serializer.Reset();
        
        var loaded1 = scope TestPlayer();
        var loaded2 = scope TestPlayer();
        
        serializer.ReadObject(loaded1);
        serializer.ReadObject(loaded2);
        
        Test.Assert(loaded1.Name == "Player1");
        Test.Assert(loaded1.Health == 100);
        Test.Assert(loaded2.Name == "Player2");
        Test.Assert(loaded2.Health == 80);
    }
}

// === Edge Case Tests ===

class EdgeCaseTests
{
    [Test]
    static void LargeNumberOfWrites_HandledCorrectly()
    {
        var serializer = scope BinarySerializer();
        
        for (int32 i = 0; i < 10000; i++)
            serializer.Write(i);
        
        serializer.Reset();
        
        for (int32 i = 0; i < 10000; i++)
            Test.Assert(serializer.ReadInt32() case .Ok(i));
    }
    
    [Test]
    static void AlternatingTypes_MaintainsAlignment()
    {
        var serializer = scope BinarySerializer();
        
        serializer.Write((uint8)1);
        serializer.Write((int32)2);
        serializer.Write((uint8)3);
        serializer.Write((int64)4);
        serializer.Write((uint8)5);
        
        serializer.Reset();
        
        Test.Assert(serializer.ReadUInt8() case .Ok(1));
        Test.Assert(serializer.ReadInt32() case .Ok(2));
        Test.Assert(serializer.ReadUInt8() case .Ok(3));
        Test.Assert(serializer.ReadInt64() case .Ok(4));
        Test.Assert(serializer.ReadUInt8() case .Ok(5));
    }
    
    [Test]
    static void FloatSpecialValues_Handled()
    {
        var serializer = scope BinarySerializer();
        
        serializer.Write(float.PositiveInfinity);
        serializer.Write(float.NegativeInfinity);
        // Note: NaN comparison is tricky, skipping for now
        
        serializer.Reset();
        
        Test.Assert(serializer.ReadFloat() case .Ok(float.PositiveInfinity));
        Test.Assert(serializer.ReadFloat() case .Ok(float.NegativeInfinity));
    }
    
    [Test]
    static void DoubleSpecialValues_Handled()
    {
        var serializer = scope BinarySerializer();
        
        serializer.Write(double.PositiveInfinity);
        serializer.Write(double.NegativeInfinity);
        
        serializer.Reset();
        
        Test.Assert(serializer.ReadDouble() case .Ok(double.PositiveInfinity));
        Test.Assert(serializer.ReadDouble() case .Ok(double.NegativeInfinity));
    }
}