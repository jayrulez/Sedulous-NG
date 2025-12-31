using System;
using System.Collections;

namespace Sedulous.RHI;

/// <summary>
/// This structure contains all the shader stages.
/// </summary>
public struct GraphicsShaderStateDescription : IEquatable<GraphicsShaderStateDescription>
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
	/// Gets or sets the vertex shader program.
	/// </summary>
	public Shader VertexShader;

	/// <summary>
	/// Gets or sets the hull shader program.
	/// </summary>
	public Shader HullShader;

	/// <summary>
	/// Gets or sets the domain shader program.
	/// </summary>
	public Shader DomainShader;

	/// <summary>
	/// Gets or sets the geometry shader program.
	/// </summary>
	public Shader GeometryShader;

	/// <summary>
	/// Gets or sets the pixel shader program.
	/// </summary>
	public Shader PixelShader;

	/// <summary>
	/// Represents a relationship between semantics and shader locations.
	/// </summary>
	public InputLayouts ShaderInputLayout;

	/// <inheritdoc />
	public bool Equals(GraphicsShaderStateDescription other)
	{
		if (VertexShader != other.VertexShader || HullShader != other.HullShader || DomainShader != other.DomainShader || GeometryShader != other.GeometryShader || PixelShader != other.PixelShader)
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
		if (obj is GraphicsShaderStateDescription)
		{
			return Equals((GraphicsShaderStateDescription)obj);
		}
		return false;
	}

	/// <inheritdoc />
	public int GetHashCode()
	{
		int hashCode = 0;
		if (VertexShader != null)
		{
			hashCode = (hashCode * 397) ^ VertexShader.GetHashCode();
		}
		if (HullShader != null)
		{
			hashCode = (hashCode * 397) ^ HullShader.GetHashCode();
		}
		if (DomainShader != null)
		{
			hashCode = (hashCode * 397) ^ DomainShader.GetHashCode();
		}
		if (GeometryShader != null)
		{
			hashCode = (hashCode * 397) ^ GeometryShader.GetHashCode();
		}
		if (PixelShader != null)
		{
			hashCode = (hashCode * 397) ^ PixelShader.GetHashCode();
		}
		return hashCode;
	}
}
