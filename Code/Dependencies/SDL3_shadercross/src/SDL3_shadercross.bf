using SDL3Native;
using System;
/*
  Simple DirectMedia Layer Shader Cross Compiler
  Copyright (C) 2024 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
	 claim that you wrote the original software. If you use this software
	 in a product, an acknowledgment in the product documentation would be
	 appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
	 misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/

namespace SDL3_shadercross;

public static
{
	/**
	 * Printable format: "%d.%d.%d", MAJOR, MINOR, MICRO
	 */
	public const uint32 SDL_SHADERCROSS_MAJOR_VERSION = 3;
	public const uint32 SDL_SHADERCROSS_MINOR_VERSION = 0;
	public const uint32 SDL_SHADERCROSS_MICRO_VERSION = 0;

	[CRepr]public enum SDL_ShaderCross_ShaderStage
	{
		SDL_SHADERCROSS_SHADERSTAGE_VERTEX,
		SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT,
		SDL_SHADERCROSS_SHADERSTAGE_COMPUTE
	}
	[CRepr]public struct SDL_ShaderCross_GraphicsShaderMetadata
	{
		public uint32 num_samplers; /**< The number of samplers defined in the shader. */
		public uint32 num_storage_textures; /**< The number of storage textures defined in the shader. */
		public uint32 num_storage_buffers; /**< The number of storage buffers defined in the shader. */
		public uint32 num_uniform_buffers; /**< The number of uniform buffers defined in the shader. */

		public SDL_PropertiesID props; /**< A properties ID for extensions. This is allocated and freed by the caller, and should be 0 if no extensions are needed. */
	}

	[CRepr]public struct SDL_ShaderCross_ComputePipelineMetadata
	{
		public uint32 num_samplers; /**< The number of samplers defined in the shader. */
		public uint32 num_readonly_storage_textures; /**< The number of readonly storage textures defined in the shader. */
		public uint32 num_readonly_storage_buffers; /**< The number of readonly storage buffers defined in the shader. */
		public uint32 num_readwrite_storage_textures; /**< The number of read-write storage textures defined in the shader. */
		public uint32 num_readwrite_storage_buffers; /**< The number of read-write storage buffers defined in the shader. */
		public uint32 num_uniform_buffers; /**< The number of uniform buffers defined in the shader. */
		public uint32 threadcount_x; /**< The number of threads in the X dimension. */
		public uint32 threadcount_y; /**< The number of threads in the Y dimension. */
		public uint32 threadcount_z; /**< The number of threads in the Z dimension. */

		public SDL_PropertiesID props; /**< A properties ID for extensions. This is allocated and freed by the caller, and should be 0 if no extensions are needed. */
	}

	[CRepr]public struct SDL_ShaderCross_SPIRV_Info
	{
		public  uint8* bytecode; /**< The SPIRV bytecode. */
		public uint bytecode_size; /**< The length of the SPIRV bytecode. */
		public char8* entrypoint; /**< The entry point function name for the shader in UTF-8. */
		public SDL_ShaderCross_ShaderStage shader_stage; /**< The shader stage to transpile the shader with. */
		public bool enable_debug; /**< Allows debug info to be emitted when relevant. Can be useful for graphics debuggers like RenderDoc. */
		public char8* name; /**< A UTF-8 name to associate with the shader. Optional, can be NULL. */

		public SDL_PropertiesID props; /**< A properties ID for extensions. Should be 0 if no extensions are needed. */
	}

	[CRepr]public struct SDL_ShaderCross_HLSL_Define
	{
		public char8* name; /**< The define name. */
		public char8* value; /**< An optional value for the define. Can be NULL. */
	}

	[CRepr]public struct SDL_ShaderCross_HLSL_Info
	{
		public char8* source; /**< The HLSL source code for the shader. */
		public char8* entrypoint; /**< The entry point function name for the shader in UTF-8. */
		public char8* include_dir; /**< The include directory for shader code. Optional, can be NULL. */
		public SDL_ShaderCross_HLSL_Define* defines; /**< An array of defines. Optional, can be NULL. If not NULL, must be terminated with a fully NULL define struct. */
		public SDL_ShaderCross_ShaderStage shader_stage; /**< The shader stage to compile the shader with. */
		public bool enable_debug; /**< Allows debug info to be emitted when relevant. Can be useful for graphics debuggers like RenderDoc. */
		public char8* name; /**< A UTF-8 name to associate with the shader. Optional, can be NULL. */

		public SDL_PropertiesID props; /**< A properties ID for extensions. Should be 0 if no extensions are needed. */
	}

	/**
	 * Initializes SDL_shadercross
	 *
	 * \threadsafety This should only be called once, from a single thread.
	 */
	[CLink]public static extern bool SDL_ShaderCross_Init();
	/**
	 * De-initializes SDL_shadercross
	 *
	 * \threadsafety This should only be called once, from a single thread.
	 */
	[CLink]public static extern void SDL_ShaderCross_Quit();

	/**
	 * Get the supported shader formats that SPIRV cross-compilation can output
	 *
	 * \threadsafety It is safe to call this function from any thread.
	 */
	[CLink]public static extern SDL_GPUShaderFormat SDL_ShaderCross_GetSPIRVShaderFormats();

	/**
	 * Transpile to MSL code from SPIRV code.
	 *
	 * You must SDL_free the returned string once you are done with it.
	 *
	 * \param info a struct describing the shader to transpile.
	 * \returns an SDL_malloc'd string containing MSL code.
	 */
	[CLink]public static extern void* SDL_ShaderCross_TranspileMSLFromSPIRV(
		SDL_ShaderCross_SPIRV_Info* info);

	/**
	 * Transpile to HLSL code from SPIRV code.
	 *
	 * You must SDL_free the returned string once you are done with it.
	 *
	 * \param info a struct describing the shader to transpile.
	 * \returns an SDL_malloc'd string containing HLSL code.
	 */
	[CLink]public static extern void* SDL_ShaderCross_TranspileHLSLFromSPIRV(
		SDL_ShaderCross_SPIRV_Info* info);

	/**
	 * Compile DXBC bytecode from SPIRV code.
	 *
	 * You must SDL_free the returned buffer once you are done with it.
	 *
	 * \param info a struct describing the shader to transpile.
	 * \param size filled in with the bytecode buffer size.
	 * \returns an SDL_malloc'd buffer containing DXBC bytecode.
	 */
	[CLink]public static extern void* SDL_ShaderCross_CompileDXBCFromSPIRV(
		SDL_ShaderCross_SPIRV_Info* info,
		uint* size);

	/**
	 * Compile DXIL bytecode from SPIRV code.
	 *
	 * You must SDL_free the returned buffer once you are done with it.
	 *
	 * \param info a struct describing the shader to transpile.
	 * \param size filled in with the bytecode buffer size.
	 * \returns an SDL_malloc'd buffer containing DXIL bytecode.
	 */
	[CLink]public static extern void* SDL_ShaderCross_CompileDXILFromSPIRV(
		SDL_ShaderCross_SPIRV_Info* info,
		uint* size);

	/**
	 * Compile an SDL GPU shader from SPIRV code.
	 *
	 * \param device the SDL GPU device.
	 * \param info a struct describing the shader to transpile.
	 * \param metadata a pointer filled in with shader metadata.
	 * \returns a compiled SDL_GPUShader
	 *
	 * \threadsafety It is safe to call this function from any thread.
	 */
	[CLink]public static extern SDL_GPUShader* SDL_ShaderCross_CompileGraphicsShaderFromSPIRV(
		SDL_GPUDevice* device,
		SDL_ShaderCross_SPIRV_Info* info,
		SDL_ShaderCross_GraphicsShaderMetadata* metadata);

	/**
	 * Compile an SDL GPU compute pipeline from SPIRV code.
	 *
	 * \param device the SDL GPU device.
	 * \param info a struct describing the shader to transpile.
	 * \param metadata a pointer filled in with compute pipeline metadata.
	 * \returns a compiled SDL_GPUComputePipeline
	 *
	 * \threadsafety It is safe to call this function from any thread.
	 */
	[CLink]public static extern SDL_GPUComputePipeline* SDL_ShaderCross_CompileComputePipelineFromSPIRV(
		SDL_GPUDevice* device,
		SDL_ShaderCross_SPIRV_Info* info,
		SDL_ShaderCross_ComputePipelineMetadata* metadata);

	/**
	 * Reflect graphics shader info from SPIRV code.
	 *
	 * \param bytecode the SPIRV bytecode.
	 * \param bytecode_size the length of the SPIRV bytecode.
	 * \param metadata a pointer filled in with shader metadata.
	 *
	 * \threadsafety It is safe to call this function from any thread.
	 */
	[CLink]public static extern bool SDL_ShaderCross_ReflectGraphicsSPIRV(
		uint8* bytecode,
		uint bytecode_size,
		SDL_ShaderCross_GraphicsShaderMetadata* metadata);

	/**
	 * Reflect compute pipeline info from SPIRV code.
	 *
	 * \param bytecode the SPIRV bytecode.
	 * \param bytecode_size the length of the SPIRV bytecode.
	 * \param metadata a pointer filled in with compute pipeline metadata.
	 *
	 * \threadsafety It is safe to call this function from any thread.
	 */
	[CLink]public static extern bool SDL_ShaderCross_ReflectComputeSPIRV(
		uint8* bytecode,
		uint bytecode_size,
		SDL_ShaderCross_ComputePipelineMetadata* metadata);

	/**
	 * Get the supported shader formats that HLSL cross-compilation can output
	 *
	 * \threadsafety It is safe to call this function from any thread.
	 */
	[CLink]public static extern SDL_GPUShaderFormat SDL_ShaderCross_GetHLSLShaderFormats();

	/**
	 * Compile to DXBC bytecode from HLSL code via a SPIRV-Cross round trip.
	 *
	 * You must SDL_free the returned buffer once you are done with it.
	 *
	 * \param info a struct describing the shader to transpile.
	 * \param size filled in with the bytecode buffer size.
	 * \returns an SDL_malloc'd buffer containing DXBC bytecode.
	 *
	 * \threadsafety It is safe to call this function from any thread.
	 */
	[CLink]public static extern void* SDL_ShaderCross_CompileDXBCFromHLSL(
		SDL_ShaderCross_HLSL_Info* info,
		uint* size);

	/**
	 * Compile to DXIL bytecode from HLSL code via a SPIRV-Cross round trip.
	 *
	 * You must SDL_free the returned buffer once you are done with it.
	 *
	 * \param info a struct describing the shader to transpile.
	 * \param size filled in with the bytecode buffer size.
	 * \returns an SDL_malloc'd buffer containing DXIL bytecode.
	 *
	 * \threadsafety It is safe to call this function from any thread.
	 */
	[CLink]public static extern void* SDL_ShaderCross_CompileDXILFromHLSL(
		SDL_ShaderCross_HLSL_Info* info,
		uint* size);

	/**
	 * Compile to SPIRV bytecode from HLSL code.
	 *
	 * You must SDL_free the returned buffer once you are done with it.
	 *
	 * \param info a struct describing the shader to transpile.
	 * \param size filled in with the bytecode buffer size.
	 * \returns an SDL_malloc'd buffer containing SPIRV bytecode.
	 *
	 * \threadsafety It is safe to call this function from any thread.
	 */
	[CLink]public static extern void* SDL_ShaderCross_CompileSPIRVFromHLSL(
		SDL_ShaderCross_HLSL_Info* info,
		uint* size);

	/**
	 * Compile an SDL GPU shader from HLSL code.
	 *
	 * \param device the SDL GPU device.
	 * \param info a struct describing the shader to transpile.
	 * \param metadata a pointer filled in with shader metadata.
	 * \returns a compiled SDL_GPUShader
	 *
	 * \threadsafety It is safe to call this function from any thread.
	 */
	[CLink]public static extern SDL_GPUShader* SDL_ShaderCross_CompileGraphicsShaderFromHLSL(
		SDL_GPUDevice* device,
		SDL_ShaderCross_HLSL_Info* info,
		SDL_ShaderCross_GraphicsShaderMetadata* metadata);

	/**
	 * Compile an SDL GPU compute pipeline from code.
	 *
	 * \param device the SDL GPU device.
	 * \param info a struct describing the shader to transpile.
	 * \param metadata a pointer filled in with compute pipeline metadata.
	 * \returns a compiled SDL_GPUComputePipeline
	 *
	 * \threadsafety It is safe to call this function from any thread.
	 */
	[CLink]public static extern SDL_GPUComputePipeline* SDL_ShaderCross_CompileComputePipelineFromHLSL(
		SDL_GPUDevice* device,
		SDL_ShaderCross_HLSL_Info* info,
		SDL_ShaderCross_ComputePipelineMetadata* metadata);
}