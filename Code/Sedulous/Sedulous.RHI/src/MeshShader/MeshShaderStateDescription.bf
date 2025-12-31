using System;
using System.Collections;

namespace Sedulous.RHI.MeshShader;

/// <summary>
/// This structure contains all the shader stages.
/// </summary>
public struct MeshShaderStateDescription : IEquatable<MeshShaderStateDescription>
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
	/// Gets or sets the amplification shader program.
	/// </summary>
	public Shader AmplificationShader;

	/// <summary>
	/// Gets or sets the mesh shader program.
	/// </summary>
	public Shader MeshShader;

	/// <summary>
	/// Gets or sets the pixel shader program.
	/// </summary>
	public Shader PixelShader;

	/// <inheritdoc />
	public bool Equals(MeshShaderStateDescription other)
	{
		if (AmplificationShader != other.AmplificationShader || MeshShader != other.MeshShader || PixelShader != other.PixelShader)
		{
			return false;
		}
		return true;
	}

	/// <inheritdoc />
	public bool Equals(Object obj)
	{
		if (obj == null)
		{
			return false;
		}
		if (obj is MeshShaderStateDescription)
		{
			return Equals((MeshShaderStateDescription)obj);
		}
		return false;
	}

	/// <inheritdoc />
	public int GetHashCode()
	{
		int hashCode = 0;
		if (AmplificationShader != null)
		{
			hashCode = (hashCode * 397) ^ AmplificationShader.GetHashCode();
		}
		if (MeshShader != null)
		{
			hashCode = (hashCode * 397) ^ MeshShader.GetHashCode();
		}
		if (PixelShader != null)
		{
			hashCode = (hashCode * 397) ^ PixelShader.GetHashCode();
		}
		return hashCode;
	}
}
