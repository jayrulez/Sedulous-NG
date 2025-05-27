using SDL3Native;
using System;
using SDL3_shadercross;
using System.IO;
using System.Collections;
namespace Sedulous.Engine.Renderer.SDL;

extension SDLRendererSubsystem
{
	internal void CompileShader(String shaderPath, SDL_ShaderCross_ShaderStage stage, String entrypoint, List<uint8> byteCode)
	{
		String error = scope .();
		String shaderSource = scope .();
		if (File.ReadAllText(shaderPath, shaderSource) case .Err)
		{
			Runtime.FatalError(scope $"Failed to read shader: {shaderPath}.");
		}

		SDL_ShaderCross_HLSL_Info hlslInfo = .()
			{
				source = shaderSource.CStr(),
				entrypoint = entrypoint.CStr(),
				shader_stage = stage,
				enable_debug = true
			};

		uint spirvByteCodeSize = 0;
		void* spirvByteCode = SDL_ShaderCross_CompileSPIRVFromHLSL(&hlslInfo, &spirvByteCodeSize);
		if (spirvByteCode == null)
		{
			error.Set(scope .(SDL_GetError()));
			Runtime.FatalError(scope $"Shader compilation fail: {shaderPath} - {error}");
		}

		byteCode.AddRange(Span<uint8>((uint8*)spirvByteCode, (int)spirvByteCodeSize));
	}
}