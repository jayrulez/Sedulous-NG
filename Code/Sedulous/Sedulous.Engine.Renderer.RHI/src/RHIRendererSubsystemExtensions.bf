using Sedulous.RHI;
using System.Collections;
using System;
using System.IO;
using Sedulous.RHI.HLSLShaderCompiler;
namespace Sedulous.Engine.Renderer.RHI;

extension RHIRendererSubsystem
{
	internal void CompileShader(GraphicsContext graphicsContext, String shaderPath, ShaderStages stage, String entrypoint, List<uint8> byteCode)
	{
		String error = scope .();
		String shaderSource = scope .();
		if (File.ReadAllText(shaderPath, shaderSource) case .Err)
		{
			Runtime.FatalError(scope $"Failed to read shader: {shaderPath}.");
		}

		if (DxcShaderCompiler.CompileShader(graphicsContext, shaderSource, entrypoint, stage, CompilerParameters.Default, byteCode, ref error) case .Err)
		{
			Runtime.FatalError(scope $"Shader compilation fail: {shaderPath} - {error}");
		}
	}

	internal void CompileShaderSource(GraphicsContext graphicsContext, String shaderSource, ShaderStages stage, String entrypoint, List<uint8> byteCode)
	{
		String error = scope .();

		if (DxcShaderCompiler.CompileShader(graphicsContext, shaderSource, entrypoint, stage, CompilerParameters.Default, byteCode, ref error) case .Err)
		{
			Runtime.FatalError(scope $"Shader compilation fail: {error}");
		}

		File.WriteAll(scope $"{stage}.spv", byteCode);
	}

	internal static void CompileShaderFromSource(GraphicsContext graphicsContext, String shaderSource, ShaderStages stage, String entrypoint, List<uint8> byteCode)
	{
		String error = scope .();

		if (DxcShaderCompiler.CompileShader(graphicsContext, shaderSource, entrypoint, stage, CompilerParameters.Default, byteCode, ref error) case .Err)
		{
			Runtime.FatalError(scope $"Shader compilation fail: {error}");
		}

		File.WriteAll(scope $"{stage}.spv", byteCode);
	}
}