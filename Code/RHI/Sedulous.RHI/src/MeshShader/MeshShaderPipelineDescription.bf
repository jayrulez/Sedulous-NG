using System;

namespace Sedulous.RHI.MeshShader;

/// <summary>
/// Contains properties that describe the characteristics of a new mesh shader pipeline state Object.
/// </summary>
public struct MeshShaderPipelineDescription : IEquatable<MeshShaderPipelineDescription>
{
	/// <summary>
	/// The rendering state description.
	/// </summary>
	public RenderStateDescription RenderStates;

	/// <summary>
	/// Describes the state of the shader.
	/// </summary>
	public MeshShaderStateDescription Shaders;

	/// <summary>
	/// Describes the layout of resource inputs.
	/// </summary>
	public ResourceLayout[] ResourceLayouts;

	/// <summary>
	/// Defines how vertices are interpreted and rendered by the pipeline.
	/// </summary>
	public PrimitiveTopology PrimitiveTopology;

	/// <summary>
	/// A description of the output attachments used by the <see cref="T:Sedulous.RHI.GraphicsPipelineState" />.
	/// </summary>
	public OutputDescription Outputs;

	/// <summary>
	/// Initializes a new instance of the <see cref="T:Sedulous.RHI.MeshShader.MeshShaderPipelineDescription" /> struct.
	/// </summary>
	/// <param name="primitiveTopology">Defines how vertices are interpreted and rendered by the pipeline.</param>
	/// <param name="inputLayouts">Describes the input vertex buffer data.</param>
	/// <param name="resourceLayouts">The resource layouts array.</param>
	/// <param name="shaders">The shader state description.</param>
	/// <param name="renderStates">The render state description.</param>
	/// <param name="outputs">Description of the output attachments.</param>
	public this(PrimitiveTopology primitiveTopology, InputLayouts inputLayouts, ResourceLayout[] resourceLayouts, MeshShaderStateDescription shaders, RenderStateDescription renderStates, OutputDescription outputs)
	{
		PrimitiveTopology = primitiveTopology;
		ResourceLayouts = resourceLayouts;
		Shaders = shaders;
		RenderStates = renderStates;
		Outputs = outputs;
	}

	/// <summary>
	/// Returns a hash code for this instance.
	/// </summary>
	/// <param name="other">Object to be compared.</param>
	/// <returns>
	/// A hash code for this instance, suitable for use in hashing algorithms and data structures like a hash table.
	/// </returns>
	public bool Equals(MeshShaderPipelineDescription other)
	{
		if (PrimitiveTopology != other.PrimitiveTopology || !ResourceLayouts.SequenceEqual(other.ResourceLayouts) || Shaders != other.Shaders || RenderStates != other.RenderStates || Outputs != other.Outputs)
		{
			return false;
		}
		return true;
	}

	/// <summary>
	/// Determines whether the specified <see cref="T:System.Object" /> is equal to this instance.
	/// </summary>
	/// <param name="obj">The <see cref="T:System.Object" /> to compare with this instance.</param>
	/// <returns>
	///   <c>true</c> if the specified <see cref="T:System.Object" /> is equal to this instance; otherwise, <c>false</c>.
	/// </returns>
	public bool Equals(Object obj)
	{
		if (obj == null)
		{
			return false;
		}
		if (obj is MeshShaderPipelineDescription)
		{
			return Equals((MeshShaderPipelineDescription)obj);
		}
		return false;
	}

	/// <summary>
	/// Returns a hash code for this instance.
	/// </summary>
	/// <returns>
	/// A hash code for this instance, suitable for use in hashing algorithms and data structures like hash tables.
	/// </returns>
	public int GetHashCode()
	{
		int hash = 0;
		hash = HashCode.Mix(hash, (int)PrimitiveTopology);
		hash = HashCode.Mix(hash, Outputs.GetHashCode());
		for (int i = 0; i < ResourceLayouts.Count; i++)
		{
			hash = HashCode.Mix(hash, ResourceLayouts[i].GetHashCode());
		}
		hash = HashCode.Mix(hash, RenderStates.GetHashCode());
		hash = HashCode.Mix(hash, Shaders.GetHashCode());
		return hash;
	}

	/// <summary>
	/// Implements the operator ==.
	/// </summary>
	/// <param name="value1">The first value.</param>
	/// <param name="value2">The second value.</param>
	/// <returns>
	/// The result of the operator.
	/// </returns>
	public static bool operator ==(MeshShaderPipelineDescription value1, MeshShaderPipelineDescription value2)
	{
		return value1.Equals(value2);
	}

	/// <summary>
	/// Implements the operator ==.
	/// </summary>
	/// <param name="value1">The first value.</param>
	/// <param name="value2">The second value.</param>
	/// <returns>
	/// The result of the operator.
	/// </returns>
	public static bool operator !=(MeshShaderPipelineDescription value1, MeshShaderPipelineDescription value2)
	{
		return !value1.Equals(value2);
	}
}
