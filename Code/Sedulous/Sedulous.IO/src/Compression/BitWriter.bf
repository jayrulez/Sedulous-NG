using System;
using System.Collections;
namespace Sedulous.IO.Compression;

// Bit writer utility
public class BitWriter
{
    private List<uint8> mOutput;
    private uint8 mCurrentByte;
    private int mBitPos;
    
    public this(List<uint8> output)
    {
        mOutput = output;
        mCurrentByte = 0;
        mBitPos = 0;
    }
    
    public void WriteBits(uint32 value, int count)
    {
        for (int i = 0; i < count; i++)
        {
            if (((value >> i) & 1) != 0)
                mCurrentByte |= (uint8)(1 << mBitPos);
            
            mBitPos++;
            if (mBitPos >= 8)
            {
                mOutput.Add(mCurrentByte);
                mCurrentByte = 0;
                mBitPos = 0;
            }
        }
    }
    
    public void WriteBytes(Span<uint8> data)
    {
        AlignToByte();
        for (var b in data)
            mOutput.Add(b);
    }
    
    public void AlignToByte()
    {
        if (mBitPos > 0)
        {
            mOutput.Add(mCurrentByte);
            mCurrentByte = 0;
            mBitPos = 0;
        }
    }
}