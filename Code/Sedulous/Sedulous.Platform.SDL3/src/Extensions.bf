namespace System;

extension Runtime
{
	[NoReturn]
	public static void SDL3Error(String message = "SDL3 Error", String filePath = Compiler.CallerFilePath, int line = Compiler.CallerLineNum)
	{
		Runtime.RuntimeError(message, filePath, line, 2);
	}
}