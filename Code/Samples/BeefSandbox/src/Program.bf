using System.Diagnostics;
namespace BeefSandbox;



public class Program
{
	delegate void MyAction();

	public enum MyEnum
	{
	    case DelegateCase(MyAction);
	}

	static void Example1()
	{
	    var value = MyEnum.DelegateCase((delegate void())new () => {});
	    if (value case .DelegateCase(var inner))
	        delete inner;
	}

	static void Example2()
	{
	    var value = MyEnum.DelegateCase(new () => {});
	    if (value case .DelegateCase(var inner))
	        delete inner;
	}

    public static void Main()
    {
		Example1();
    }
}