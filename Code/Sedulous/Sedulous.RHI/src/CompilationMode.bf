using System;
using Sedulous.Foundation;
using Sedulous.Foundation.Core;

namespace Sedulous.RHI;

/// <summary>
/// An enumeration.
/// </summary>
[Flags]
public enum CompilationMode : uint8
{
	/// <summary>
	/// Shaders are compiled without specific parameters.
	/// </summary>
	None = 0,
	/// <summary>
	/// Shaders are compiled with debugging information.
	/// </summary>
	Debug = 1,
	/// <summary>
	/// Shaders are compiled with optimization.
	/// </summary>
	Release = 2
}
