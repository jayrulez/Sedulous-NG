using System;
namespace Sedulous.IO;

class OutputMemoryStream : OutputStream
{
	private uint8* mData = null;
	private int mCapacity = 0;
	private int mSize = 0;
	private bool mOwnsData = false;

	public uint8* Data => mData;
	public int Capacity => mCapacity;
	public int Size => mSize;
	public bool Empty => mSize == 0;

	public static implicit operator Span<uint8>(Self self) => Span<uint8>(self.mData, self.mSize);

	public ref uint8 this[int index]
	{
		get
		{
			Runtime.Assert(index < mSize);
			return ref mData[index];
		}
	}

	public this()
	{
		mOwnsData = true;
	}

	public this(void* data, int capacity)
	{
		mData = (uint8*)data;
		mCapacity = capacity;
	}

	public this(OutputMemoryStream other)
	{
		mSize = other.mSize;
		if (other.mCapacity > 0)
		{
			mData = new uint8[other.mCapacity]*;
			Internal.MemCpy(mData, other.mData, other.mCapacity);
			mCapacity = other.mCapacity;
			mOwnsData = true;
		} else
		{
			mData = null;
			mCapacity = 0;
		}
	}

	public this(InputMemoryStream stream)
	{
		mSize = stream.Size;

		if (stream.Size > 0)
		{
			mData = new uint8[stream.Size]*;
			Internal.MemCpy(mData, stream.Data, stream.Size);
			mCapacity = stream.Size;
			mOwnsData = true;
		} else
		{
			mData = null;
			mCapacity = 0;
		}
	}

	public ~this()
	{
		if (mOwnsData && mData != null)
		{
			delete mData;
			mData = null;
		}
	}

	public override bool Write(void* buffer, int size)
	{
		if(size == 0)
			return true;

		if(mSize + size > mCapacity)
		{
			Reserve((mSize + size) << 1);
		}

		Internal.MemCpy((uint8*)mData + mSize, buffer, size);
		mSize += size;

		return true;
	}

	public Span<uint8> ReleaseOwnership()
	{
		Span<uint8> data = .((uint8*)mData, mCapacity);
		mData = null;
		mSize = mCapacity;
		return data;
	}

	public void Resize(int size)
	{
		mSize = size;
		if(size <= mCapacity) return;

		Runtime.Assert(mOwnsData);

		uint8* temp = new uint8[size]*;
		Internal.MemCpy(temp, mData, mCapacity);
		delete mData;
		mData = temp;
		mCapacity = size;
	}

	public void Reserve(int size)
	{
		if(size <= mCapacity) return;

		Runtime.Assert(mOwnsData);

		uint8* temp = new uint8[size]*;
		Internal.MemCpy(temp, mData, mCapacity);
		delete mData;
		mData = temp;
		mCapacity = size;
	}

	public bool Write(String str)
	{
		int size = str.Length + 1;
		Write(str.Ptr, size -1);
		Write<char8>(0);
		return true;
	}

	public void Clear()
	{
		mSize = 0;
	}

	public void* Skip(int size)
	{
		Runtime.Assert(size > 0 || mCapacity > 0);

		if (mSize + size > mCapacity)
		{
			Reserve((mSize + size) << 1);
		}

		void* position = (uint8*)mData + mSize;
		mSize += size;
		return position;
	}

	public void Free()
	{
		delete mData;
		mSize = 0;
		mCapacity = 0;
		mData = null;
	}
}