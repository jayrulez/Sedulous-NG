using System;
using Sedulous.RHI.Raytracing;
namespace Sedulous.RHI;

static
{
	public static int GetHashCode(this Shader[] items)
	{
		if(items == null)
			return 0;

		int hash = 0;
		for(int i = 0; i < items.Count; i++)
		{
			hash = HashCode.Mix(hash, items[i].GetHashCode());
		}
		return hash;
	}

	public static int GetHashCode(this ResourceLayout item)
	{
		if(item == null)
			return 0;

		int hash = 0;
		return hash;
	}

	public static int GetHashCode(this ResourceLayout[] items)
	{
		if(items == null)
			return 0;

		int hash = 0;
		for(int i = 0; i < items.Count; i++)
		{
			hash = HashCode.Mix(hash, items[i].GetHashCode());
		}
		return hash;
	}

	public static int GetHashCode(this HitGroupDescription item)
	{
		int hash = 0;
		return hash;
	}

	public static int GetHashCode(this HitGroupDescription[] items)
	{
		if(items == null)
			return 0;

		int hash = 0;
		for(int i = 0; i < items.Count; i++)
		{
			hash = HashCode.Mix(hash, items[i].GetHashCode());
		}
		return hash;
	}

	public static int GetHashCode(this Texture item)
	{
		if(item == null)
			return 0;

		int hash = 0;
		return hash;
	}
}