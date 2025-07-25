using System;
namespace Sedulous.RHI;

/// <summary>
/// This struct represents the result of a compilation process in a shader.
/// </summary>
public struct CompilationResult
{
	/// <summary>
	/// The byte code before compiling a shader.
	/// </summary>
	public readonly uint8[] ByteCode;

	/// <summary>
	/// True if the compilation was incorrect.
	/// </summary>
	public readonly bool HasErrors;

	/// <summary>
	/// The line number of the error.
	/// </summary>
	public readonly uint32 ErrorLine;

	/// <summary>
	/// Error message if hasErrors is true.
	/// </summary>
	public readonly String Message;

	/// <summary>
	/// Initializes a new instance of the <see cref="T:Sedulous.RHI.CompilationResult" /> struct.
	/// </summary>
	/// <param name="bytecode">The compiled byte code.</param>
	/// <param name="hasErrors">Indicates whether the compilation was successful or not.</param>
	/// <param name="errorLine">The error line number if hasErrors is true.</param>
	/// <param name="message">The error message if hasErrors is true.</param>
	public this(uint8[] bytecode, bool hasErrors, uint32 errorLine = 0, String message = null)
	{
		ByteCode = bytecode;
		HasErrors = hasErrors;
		ErrorLine = errorLine;
		Message = message;
	}
}
