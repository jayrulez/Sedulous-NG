using System;
namespace Sedulous.IO;

class InputMemoryStream : InputStream
{
	private bool mHasOverflow = false;
	private uint8* mData = null;
	private int mSize = 0;
	private int mPosition = 0;

	public override int Size => mSize;

	public void* Data => mData;

	public int Remaining => mSize - mPosition;

	public int Position {
		get => mPosition;
		set{
			mPosition = value;
		}
	}

	public bool HasOverflow => mHasOverflow;

	public this(void* data, int size)
	{
		mData = (uint8*)data;
		mSize = size;
	}

	public this(Span<uint8> data)
	{
		mData = data.Ptr;
		mSize = data.Length;
	}

	public this(OutputMemoryStream blob)
	{
		mData = blob.Data;
		mSize = blob.Size;
	}

	public void Set(void* data, int size)
	{
		mData = (uint8*)data;
		mSize = size;
		mPosition = 0;
		mHasOverflow = false;
	}

	public override bool Read(void* buffer, int size)
	{
		if(mPosition + size > mSize)
		{
			for(int i = 0; i < size; i++)
			{
				((uint8*)buffer)[i] = 0;
				}

			mHasOverflow = true;
			return false;
		}

		if(size > 0)
		{
			Internal.MemCpy(buffer, ((uint8*)mData)+mPosition, size);
		}

		mPosition += size;

		return true;
	}

	public bool Read(String string)
	{
		string.Append(ReadString());

		return true;
	}

	public void* Skip(int size)
	{
		var position = mData + mPosition;
		mPosition += size;
		if(mPosition > mSize)
		{
			//Runtime.Assert(false);
			mPosition = mSize;
			mHasOverflow = true;
		}

		return position;
	}

	public char8* ReadString()
	{
		char8* str = (char8*)mData + mPosition;
		while(mPosition < mSize && mData[mPosition] != 0) ++mPosition;

		if(mPosition >= mSize)
		{
			// TODO this should be runtime error, not assert
			Runtime.Assert(false);
			mHasOverflow = true;
			return null;
		}

		++mPosition;

		return str;
	}

	public T GetAs<T>() where T : ValueType
	{
		Runtime.Assert(mPosition + sizeof(T) < mSize);
		return *(T*)(mData + mPosition);
	}
}