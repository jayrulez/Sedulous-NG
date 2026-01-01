using System;
using System.IO;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RHI.HLSLShaderCompiler;

namespace Sedulous.Engine.Renderer.RHI;

/// Manages shader compilation and caching.
/// Provides a central point for all shader-related operations.
class ShaderManager
{
	private GraphicsContext mGraphicsContext;

	// Compiled shader cache (keyed by source hash + entry point)
	private Dictionary<String, Shader> mShaderCache = new .() ~ {
		for (var entry in _)
		{
			delete entry.key;
			mGraphicsContext.Factory.DestroyShader(ref entry.value);
		}
		delete _;
	};

	public this(GraphicsContext graphicsContext)
	{
		mGraphicsContext = graphicsContext;
	}

	/// Compile shader from source code
	public Shader CompileFromSource(StringView shaderSource, ShaderStages stage, StringView entryPoint)
	{
		var byteCode = scope List<uint8>();
		CompileShaderSource(shaderSource, stage, entryPoint, byteCode);

		var shaderBytes = scope uint8[byteCode.Count];
		byteCode.CopyTo(shaderBytes);

		var shaderDesc = ShaderDescription(stage, scope String(entryPoint), shaderBytes);
		return mGraphicsContext.Factory.CreateShader(shaderDesc);
	}

	/// Compile shader from file
	public Result<Shader> CompileFromFile(StringView shaderPath, ShaderStages stage, StringView entryPoint)
	{
		String shaderSource = scope .();
		if (File.ReadAllText(scope String(shaderPath), shaderSource) case .Err)
		{
			return .Err;
		}

		return .Ok(CompileFromSource(shaderSource, stage, entryPoint));
	}

	/// Compile shader source to bytecode
	public void CompileToByteCode(StringView shaderSource, ShaderStages stage, StringView entryPoint, List<uint8> byteCode)
	{
		CompileShaderSource(shaderSource, stage, entryPoint, byteCode);
	}

	private void CompileShaderSource(StringView shaderSource, ShaderStages stage, StringView entryPoint, List<uint8> byteCode)
	{
		String error = scope .();

		if (DxcShaderCompiler.CompileShader(
			mGraphicsContext,
			scope String(shaderSource),
			scope String(entryPoint),
			stage,
			CompilerParameters.Default,
			byteCode,
			ref error) case .Err)
		{
			Runtime.FatalError(scope $"Shader compilation fail: {error}");
		}

		// Write SPIR-V for debugging
		File.WriteAll(scope $"{stage}.spv", byteCode);
	}

	/// Destroy a shader created by this manager
	public void DestroyShader(ref Shader shader)
	{
		if (shader != null)
			mGraphicsContext.Factory.DestroyShader(ref shader);
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
