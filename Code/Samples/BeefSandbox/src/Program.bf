using System.Diagnostics;
namespace BeefSandbox;

public class Program
{
    public static void Main()
    {
		var p2 = scope Program2();

		Debug.WriteLine(typeof(Program2).GetFullName(.. scope .()));
    }
}

namespace MyNS
{
	
}

public class Program2
{
    public static void Main()
    {
    }
}