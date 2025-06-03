using System;
using System.Collections;
namespace BeefSandbox;

class Application{

	protected virtual void OnInitializing() {}
	protected virtual void OnInitialized() {}
	protected virtual void OnShuttingDown() {}

	public void Run()
	{
		OnInitializing();
		OnInitialized();
		OnShuttingDown();
	}
}

public class Program
{
    public static void Main()
    {
        var app = scope Application();

    }
}