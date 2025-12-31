using System;
namespace Sedulous.Serialization;

interface ISerializer
{
    // Primitives
    void Write(bool value);
    void Write(int8 value);
    void Write(int16 value);
    void Write(int32 value);
    void Write(int64 value);
    void Write(uint8 value);
    void Write(uint16 value);
    void Write(uint32 value);
    void Write(uint64 value);
    void Write(float value);
    void Write(double value);
    void Write(StringView value);
    
    // Reading
    Result<bool> ReadBool();
    Result<int8> ReadInt8();
    Result<int16> ReadInt16();
    Result<int32> ReadInt32();
    Result<int64> ReadInt64();
    Result<uint8> ReadUInt8();
    Result<uint16> ReadUInt16();
    Result<uint32> ReadUInt32();
    Result<uint64> ReadUInt64();
    Result<float> ReadFloat();
    Result<double> ReadDouble();
    Result<void> ReadString(String outStr);
    
    // Nested objects
    void WriteObject(ISerializable value);
    Result<void> ReadObject(ISerializable value);
}