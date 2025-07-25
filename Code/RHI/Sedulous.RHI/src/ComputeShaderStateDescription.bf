using System;
using System.Collections;

namespace Sedulous.RHI;

/// <summary>
/// This structure contains all the shader stages.
/// </summary>
public struct ComputeShaderStateDescription : IEquatable<ComputeShaderStateDescription>
{
	/// <summary>
	/// ConstantBuffer bindings.
	/// Used in OpenGL 4.1 or later and OpenGL ES 3.0 or later.
	/// </summary>
	public List<(String name, uint32 slot)> constantBuffersBindings;

	/// <summary>
	/// Texture bindings.
	/// Used in OpenGL 4.1 or earlier and OpenGLES 3.0 or earlier.
	/// </summary>
	public List<(String name, uint32 slot)> texturesBindings;

	/// <summary>
	/// Uniform parameter bindings.
	/// Used in WebGL1 and OpenGL ES 2.0.
	/// </summary>
	public Dictionary<String, BufferParameterBinding> bufferParametersBinding;

	/// <summary>
	/// Gets or sets the compute shader program.
	/// </summary>
	public Shader ComputeShader;

	/// <inheritdoc />
	public bool Equals(Object obj)
	{
		if (obj == null)
		{
			return false;
		}
		if (obj is ComputeShaderStateDescription)
		{
			return Equals((ComputeShaderStateDescription)obj);
		}
		return false;
	}

	/// <inheritdoc />
	public bool Equals(ComputeShaderStateDescription other)
	{
		if (ComputeShader != other.ComputeShader)
		{
			return false;
		}
		return true;
	}

	/// <inheritdoc />
	public int GetHashCode()
	{
		int hashCode = 0;
		if (ComputeShader != null)
		{
			hashCode = (hashCode * 397) ^ ComputeShader.GetHashCode();
		}
		return hashCode;
	}
}
