using System.Collections;
using System;
namespace Sedulous.Serialization;

class BinarySerializer : ISerializer
{
    private List<uint8> mBuffer = new .() ~ delete _;
    private int mReadPos = 0;
    
    public this() { }
    
    public this(Span<uint8> data)
    {
        mBuffer.AddRange(data);
    }
    
    public Span<uint8> Data => mBuffer;
    public int Position => mReadPos;
    
    public void Reset()
    {
        mReadPos = 0;
    }
    
    public void Clear()
    {
        mBuffer.Clear();
        mReadPos = 0;
    }
    
    // Write primitives (little-endian)
    public void Write(bool value)
    {
        mBuffer.Add(value ? 1 : 0);
    }
    
    public void Write(int8 value)
    {
		var value;
        mBuffer.Add(*(uint8*)&value);
    }
    
    public void Write(int16 value)
    {
        mBuffer.Add((uint8)(value & 0xFF));
        mBuffer.Add((uint8)((value >> 8) & 0xFF));
    }
    
    public void Write(int32 value)
    {
        for (int i = 0; i < 4; i++)
            mBuffer.Add((uint8)((value >> (i * 8)) & 0xFF));
    }
    
    public void Write(int64 value)
    {
        for (int i = 0; i < 8; i++)
            mBuffer.Add((uint8)((value >> (i * 8)) & 0xFF));
    }
    
    public void Write(uint8 value)
    {
        mBuffer.Add(value);
    }
    
    public void Write(uint16 value)
    {
        mBuffer.Add((uint8)(value & 0xFF));
        mBuffer.Add((uint8)((value >> 8) & 0xFF));
    }
    
    public void Write(uint32 value)
    {
        for (int i = 0; i < 4; i++)
            mBuffer.Add((uint8)((value >> (i * 8)) & 0xFF));
    }
    
    public void Write(uint64 value)
    {
        for (int i = 0; i < 8; i++)
            mBuffer.Add((uint8)((value >> (i * 8)) & 0xFF));
    }
    
    public void Write(float value)
    {
		var value;
        Write(*(int32*)&value);
    }
    
    public void Write(double value)
    {
		var value;
        Write(*(int64*)&value);
    }
    
    public void Write(StringView value)
    {
        Write((int32)value.Length);
        for (let c in value.RawChars)
            mBuffer.Add((uint8)c);
    }
    
    // Read primitives
    public Result<bool> ReadBool()
    {
        if (mReadPos >= mBuffer.Count)
            return .Err;
        return mBuffer[mReadPos++] != 0;
    }
    
    public Result<int8> ReadInt8()
    {
        if (mReadPos >= mBuffer.Count)
            return .Err;
        return *(int8*)&mBuffer[mReadPos++];
    }
    
    public Result<int16> ReadInt16()
    {
        if (mReadPos + 2 > mBuffer.Count)
            return .Err;
        int16 value = (int16)mBuffer[mReadPos] | ((int16)mBuffer[mReadPos + 1] << 8);
        mReadPos += 2;
        return value;
    }
    
    public Result<int32> ReadInt32()
    {
        if (mReadPos + 4 > mBuffer.Count)
            return .Err;
        int32 value = 0;
        for (int i = 0; i < 4; i++)
            value |= (int32)mBuffer[mReadPos + i] << (i * 8);
        mReadPos += 4;
        return value;
    }
    
    public Result<int64> ReadInt64()
    {
        if (mReadPos + 8 > mBuffer.Count)
            return .Err;
        int64 value = 0;
        for (int i = 0; i < 8; i++)
            value |= (int64)mBuffer[mReadPos + i] << (i * 8);
        mReadPos += 8;
        return value;
    }
    
    public Result<uint8> ReadUInt8()
    {
        if (mReadPos >= mBuffer.Count)
            return .Err;
        return mBuffer[mReadPos++];
    }
    
    public Result<uint16> ReadUInt16()
    {
        if (mReadPos + 2 > mBuffer.Count)
            return .Err;
        uint16 value = (uint16)mBuffer[mReadPos] | ((uint16)mBuffer[mReadPos + 1] << 8);
        mReadPos += 2;
        return value;
    }
    
    public Result<uint32> ReadUInt32()
    {
        if (mReadPos + 4 > mBuffer.Count)
            return .Err;
        uint32 value = 0;
        for (int i = 0; i < 4; i++)
            value |= (uint32)mBuffer[mReadPos + i] << (i * 8);
        mReadPos += 4;
        return value;
    }
    
    public Result<uint64> ReadUInt64()
    {
        if (mReadPos + 8 > mBuffer.Count)
            return .Err;
        uint64 value = 0;
        for (int i = 0; i < 8; i++)
            value |= (uint64)mBuffer[mReadPos + i] << (i * 8);
        mReadPos += 8;
        return value;
    }
    
    public Result<float> ReadFloat()
    {
        var intVal = Try!(ReadInt32());
        return *(float*)&intVal;
    }
    
    public Result<double> ReadDouble()
    {
        var intVal = Try!(ReadInt64());
        return *(double*)&intVal;
    }
    
    public Result<void> ReadString(String outStr)
    {
        let length = Try!(ReadInt32());
        if (mReadPos + length > mBuffer.Count)
            return .Err;
        for (int i = 0; i < length; i++)
            outStr.Append((char8)mBuffer[mReadPos++]);
        return .Ok;
    }
    
    // Object serialization
    public void WriteObject(ISerializable value)
    {
        value.Serialize(this);
    }
    
    public Result<void> ReadObject(ISerializable value)
    {
        value.Deserialize(this);
        return .Ok;
    }
}