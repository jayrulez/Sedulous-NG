using System;
using System.Collections;
namespace BeefSandbox;

interface IInputStream
{
    int Size { get; }

    bool Read(void* buffer, int size);
}

static
{
    public static void Read<T>(this IInputStream stream, ref int value) where T : ValueType
    {
        stream.Read(&value, sizeof(int));
    }

    public static T Read<T>(this IInputStream stream) where T : ValueType
    {
        T value = default;

        stream.Read(&value, sizeof(T));

        return value;
    }

    public static void ReadList<T>(this IInputStream stream, List<T> values) where T : ValueType
    {
        int count = stream.Read<int>();
        values.Resize(count);
        stream.Read(values.Ptr, sizeof(T) * count);
    }
}

/*extension IInputStream
{
	public void Read<T>(ref int value) where T : ValueType
	{
	    Read(&value, sizeof(int));
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
}*/

class InputMemoryStream : IInputStream
{
    public int Size
    {
        get
        {
            return default;
        }
    }

    public virtual bool Read(void* buffer, int size)
    {
        return default;
    }
}

public class Program
{
    public static void Main()
    {
        let ms = scope InputMemoryStream();
        ms.Read<int>();
    }
}