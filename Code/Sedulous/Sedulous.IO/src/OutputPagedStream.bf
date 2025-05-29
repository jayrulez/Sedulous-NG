using System;
namespace Sedulous.IO;

class OutputPagedStream : OutputStream
{
	public struct Page
	{
		public Page* Next = null;
		public int Size = 0;
		public uint8[4096 - sizeof(Page*) - sizeof(int)] Data;
	}

	private Page* mHead = null;
	private Page* mTail = null;

	public this()
	{
		mTail = mHead = new Page();
	}

	public ~this()
	{
		Page* page = mHead;
		while (page != null)
		{
			Page* tmp = page;
			page = page.Next;
			delete tmp;
		}
	}

	public override bool Write(void* buffer, int size)
	{
		var size;
		uint8* src = (uint8*)buffer;
		while (size > 0)
		{
		    Span<uint8> destination = Reserve(size);
		    Internal.MemCpy(destination.Ptr, src, destination.Length);
		    src += destination.Length;
		    size -= destination.Length;
		}
		return true;
	}

	private Span<uint8> Reserve(int size)
	{
		var size;
		if (mTail.Size == mTail.Data.Count)
		{
			Page* newPage = new Page();
			mTail.Next = newPage;
			mTail = newPage;
		}

		uint8* reservation = &mTail.Data[0] + mTail.Size;
		size = Math.Min(size, sizeof(decltype(mTail.Data)) - mTail.Size);
		mTail.Size += size;
		return Span<uint8>(reservation, size);
	}
}