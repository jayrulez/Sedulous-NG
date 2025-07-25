namespace Sedulous.RHI;

/// <summary>
/// Helpers for the <see cref="T:Sedulous.RHI.ShaderStages" /> enum.
/// </summary>
public static class ShaderStagesHelpers
{
	/// <summary>
	/// Gets the shader stages as an array.
	/// </summary>
	public const ShaderStages[?] ShaderStagesArray = .(
		ShaderStages.Vertex,
		ShaderStages.Hull,
		ShaderStages.Domain,
		ShaderStages.Geometry,
		ShaderStages.Pixel,
		ShaderStages.Mesh,
		ShaderStages.Amplification,
		ShaderStages.Compute,
		ShaderStages.RayGeneration
		);

	/// <summary>
	/// Gets the shader stages count.
	/// </summary>
	public static readonly int ShaderStagesCount = ShaderStagesArray.Count;

	/// <summary>
	/// Gets the rasterization stages (Vertex, Hull, Domain, Geometry, Pixel, and Compute).
	/// </summary>
	public static readonly int RasterizationShaderStagesCount = ShaderStagesArray.Count - 1;

	/// <summary>
	/// Gets the shader stage index.
	/// </summary>
	/// <param name="stages">The shader stage.</param>
	/// <returns>The stage index.</returns>
	public static int IndexOf(ShaderStages stages)
	{
		switch (stages)
		{
		case ShaderStages.Vertex:
			return 0;
		case ShaderStages.Hull:
			return 1;
		case ShaderStages.Domain:
			return 2;
		case ShaderStages.Geometry:
			return 3;
		case ShaderStages.Pixel:
			return 4;
		case ShaderStages.Mesh:
			return 5;
		case ShaderStages.Amplification:
			return 6;
		case ShaderStages.Compute:
			return 7;
		case ShaderStages.RayGeneration:
			return 8;
		default:
			return -1;
		}
	}
}
