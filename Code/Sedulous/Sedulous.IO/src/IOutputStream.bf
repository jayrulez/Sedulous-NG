using System.Collections;
using System;
namespace Sedulous.IO;

interface IOutputStream
{
	bool Write(void* buffer, int size);
}

extension IOutputStream
{
	public bool Write<T>(T value) where T : ValueType
	{
		var value;
		return Write(&value, sizeof(T));
	}

	public bool Write<T>(List<T> values) where T : ValueType
	{
		if (values == null)
		{
			return false;
		}

		Write<int>(values.Count);
		return Write(values.Ptr, values.Count * sizeof(T));
	}

	public bool Write(uint value) => Write<uint>(value);
	public bool Write(int value) => Write<int>(value);
	public bool Write(uint64 value) => Write<uint64>(value);
	public bool Write(int64 value) => Write<int64>(value);
	public bool Write(uint32 value) => Write<uint32>(value);
	public bool Write(int32 value) => Write<int32>(value);
	public bool Write(float value) => Write<float>(value);
	public bool Write(double value) => Write<double>(value);

	public bool Write(StringView value)
	{
		return Write(value.Ptr, value.Length);
	}
}