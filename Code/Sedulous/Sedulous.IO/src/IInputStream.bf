using System;
using System.Collections;
namespace Sedulous.IO;

interface IInputStream
{
	int Size { get; }

	bool Read(void* buffer, int size);
}

extension IInputStream
{
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

	public void Read<T>(List<T> values) where T : ValueType
	{
		int count = Read<int>();
		values.Resize(count);
		Read(values.Ptr, sizeof(T) * count);
	}
}