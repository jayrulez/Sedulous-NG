using System;
namespace Sedulous.IO.Compression;

// Bit reader utility
internal class BitReader
{
    private Span<uint8> mData;
    private int mBytePos;
    private int mBitPos;
    
    public this(Span<uint8> data)
    {
        mData = data;
        mBytePos = 0;
        mBitPos = 0;
    }
    
    public Result<uint32> ReadBits(int count)
    {
        if (count <= 0 || count > 32)
            return .Err;
        
        uint32 result = 0;
        
        for (int i = 0; i < count; i++)
        {
            if (mBytePos >= mData.Length)
                return .Err;
            
            uint32 bit = (uint32)((mData[mBytePos] >> mBitPos) & 1);
            result |= (bit << i);
            
            mBitPos++;
            if (mBitPos >= 8)
            {
                mBitPos = 0;
                mBytePos++;
            }
        }
        
        return result;
    }
    
    public Result<Span<uint8>> ReadBytes(int count)
    {
        if (mBytePos + count > mData.Length)
            return .Err;
        
        var result = mData.Slice(mBytePos, count);
        mBytePos += count;
        return result;
    }
    
    public void AlignToByte()
    {
        if (mBitPos > 0)
        {
            mBitPos = 0;
            mBytePos++;
        }
    }
}