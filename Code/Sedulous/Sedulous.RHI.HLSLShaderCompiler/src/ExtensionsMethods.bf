using System;
using Sedulous.RHI;

namespace Sedulous.RHI.HLSLShaderCompiler;

/// <summary>
/// Extension methods used to convert values from the RHI to DirectX.
/// </summary>
public static class ExtensionsMethods
{
	/// <summary>
	/// Converts from VertexSemanticType to HLSL semantic string.
	/// </summary>
	/// <param name="semantic">The semantic to convert.</param>
	/// <returns>The semantic string.</returns>
	public static String ToHLSLSemantic(this ElementSemanticType semantic)
	{
		switch (semantic)
		{
		case ElementSemanticType.Position:
			return "POSITION";
		case ElementSemanticType.TexCoord:
			return "TEXCOORD";
		case ElementSemanticType.Normal:
			return "NORMAL";
		case ElementSemanticType.Tangent:
			return "TANGENT";
		case ElementSemanticType.Binormal:
			return "BINORMAL";
		case ElementSemanticType.Color:
			return "COLOR";
		case ElementSemanticType.BlendIndices:
			return "BLENDINDICES";
		case ElementSemanticType.BlendWeight:
			return "BLENDWEIGHT";
		default:
			return null;
		}
	}

	/// <summary>
	/// Converts a ShaderStage to a DirectX string.
	/// </summary>
	/// <param name="stage">The ShaderStage to convert.</param>
	/// <returns>The resulting string.</returns>
	public static String ToDirectXString(this ShaderStages stage)
	{
		switch (stage)
		{
		case ShaderStages.Vertex:
			return "vs";
		case ShaderStages.Hull:
			return "hs";
		case ShaderStages.Domain:
			return "ds";
		case ShaderStages.Geometry:
			return "gs";
		case ShaderStages.Pixel:
			return "ps";
		case ShaderStages.Compute:
			return "cs";
		case ShaderStages.Mesh:
			return "ms";
		default:
			return null;
		}
	}

	/// <summary>
	/// Converts from ShaderStage to DirectX stage.
	/// </summary>
	/// <param name="stage">The ShaderStage to convert.</param>
	/// <returns>The resulting string.</returns>
	public static DxcShaderStage ToDirectXStage(this ShaderStages stage)
	{
		switch (stage)
		{
		case ShaderStages.Vertex:
			return DxcShaderStage.Vertex;
		case ShaderStages.Hull:
			return DxcShaderStage.Hull;
		case ShaderStages.Domain:
			return DxcShaderStage.Domain;
		case ShaderStages.Geometry:
			return DxcShaderStage.Geometry;
		case ShaderStages.Pixel:
			return DxcShaderStage.Pixel;
		case ShaderStages.Compute:
			return DxcShaderStage.Compute;
		case ShaderStages.Mesh:
			return DxcShaderStage.Mesh;
		case ShaderStages.Amplification:
			return DxcShaderStage.Amplification;
		case ShaderStages.RayGeneration,
			ShaderStages.Miss,
			ShaderStages.ClosestHit,
			ShaderStages.AnyHit,
			ShaderStages.Intersection:
			return DxcShaderStage.Library;
		default:
			return DxcShaderStage.Vertex;
		}
	}

	/// <summary>
	/// Converts from a graphics profile to a DirectX graphics profile.
	/// </summary>
	/// <param name="profile">The profile to convert.</param>
	/// <returns>The converted profile.</returns>
	public static DxcShaderModel ToDirectX(this GraphicsProfile profile)
	{
		switch (profile)
		{
		case GraphicsProfile.Level_12_0:
			return DxcShaderModel.Model6_0;
		case GraphicsProfile.Level_12_1:
			return DxcShaderModel.Model6_1;
		case GraphicsProfile.Level_12_2:
			return DxcShaderModel.Model6_2;
		case GraphicsProfile.Level_12_3:
			return DxcShaderModel.Model6_3;
		case GraphicsProfile.Level_12_4:
			return DxcShaderModel.Model6_4;
		case GraphicsProfile.Level_12_5:
			return DxcShaderModel.Model6_5;
		case GraphicsProfile.Level_12_6:
			return DxcShaderModel.Model6_6;
		case GraphicsProfile.Level_12_7:
			return DxcShaderModel.Model6_7;
		default:
			return DxcShaderModel.Model6_0;
		}
	}
}
