using System;
using System.Collections;
namespace Sedulous.IO;

abstract class InputStream
{
	public abstract int Size { get; }

	public abstract bool Read(void* buffer, int size);

	public void Read<T>(ref T value) where T : ValueType
	{
		Read(&value, sizeof(T));
	}

	public T Read<T>() where T : ValueType
	{
		T value = default;

		Read(&value, sizeof(T));

		return value;
	}

	public void ReadList<T>(List<T> values) where T : ValueType
	{
		int count = Read<int>();
		values.Resize(count);
		Read(values.Ptr, sizeof(T) * count);
	}
}