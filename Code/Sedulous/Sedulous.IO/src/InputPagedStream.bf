using System;
namespace Sedulous.IO;

class InputPagedStream : IInputStream
{
	private OutputPagedStream.Page* mPage = null;
	private int mPagePosition = 0;

	public int Size
	{
		get
		{
			if (mPage == null) return 0;
			if (mPage.Next == null) return mPage.Size;

			int size = 0;
			OutputPagedStream.Page* page = mPage;
			while(page != null)
			{
			    size += page.Size;
			    page = page.Next;
			}
			return size;
		}
	}

	public this(OutputPagedStream source)
	{
		mPage = source.[Friend]mHead;
	}

	public bool IsEnd => mPage == null || mPage.Next == null && mPagePosition == mPage.Size;

	public bool Read(void* buffer, int size)
	{
		var size;
		uint8* destination = (uint8*)buffer;
		while(size > 0)
		{
			if(mPagePosition == mPage.Size)
			{
				if(mPage.Next == null)
				{
					return false;
				}

				mPagePosition = 0;
				mPage = mPage.Next;
			}

			int chunkSize = Math.Min(size, mPage.Size - mPagePosition);
			Internal.MemCpy(destination, &mPage.Data[0] + mPagePosition, chunkSize);
			mPagePosition += chunkSize;
			size -= chunkSize;
		}

		return true;
	}
}