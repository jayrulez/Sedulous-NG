using System;
namespace Sedulous.RHI.MeshShader;

/// <summary>
/// This class represents the GPU mesh shader pipeline.
/// </summary>
public abstract class MeshShaderPipelineState : PipelineState
{
	/// <summary>
	/// Gets the mesh shader pipeline state description.
	/// </summary>
	public readonly MeshShaderPipelineDescription Description;

	/// <summary>
	/// Gets or sets a string identifying this instance. It can be used in graphics debugger tools.
	/// </summary>
	public abstract String Name { get; set; }

	/// <summary>
	/// Initializes a new instance of the <see cref="T:Sedulous.RHI.MeshShader.MeshShaderPipelineState" /> class.
	/// </summary>
	/// <param name="description">The pipeline state description.</param>
	public this(in MeshShaderPipelineDescription description)
	{
		Description = description;
	}
}
