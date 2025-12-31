namespace Sedulous.RHI;

/// <summary>
/// Identifies a set of device capabilities.
/// </summary>
public enum GraphicsProfile : uint8
{
	/// <summary>
	/// DirectX 9.1 HLSL 3.0 | OpenGL ES 2.0
	/// </summary>
	Level_9_1,
	/// <summary>
	/// DirectX 9.2 HLSL 3.0 | OpenGL ES 2.0
	/// </summary>
	Level_9_2,
	/// <summary>
	/// DirectX 9.3 HLSL 3.0 | OpenGL ES 2.0
	/// </summary>
	Level_9_3,
	/// <summary>
	/// DirectX 10 HLSL 4.0 | OpenGL ES 3.0
	/// (Default)
	/// </summary>
	Level_10_0,
	/// <summary>
	/// DirectX 10.1 HLSL 4.1 | OpenGL ES 3.0
	/// </summary>
	Level_10_1,
	/// <summary>
	/// DirectX 11 HLSL 5.0 | OpenGL ES 3.1 | OpenGL 4.0
	/// </summary>
	Level_11_0,
	/// <summary>
	/// DirectX 11 HLSL 5.0 | OpenGL ES 3.1 | OpenGL 4.1
	/// </summary>
	Level_11_1,
	/// <summary>
	/// DirectX 12.0, Shader Model 6.0 (Wave intrinsics, basic ray tracing support)
	/// </summary>
	Level_12_0,
	/// <summary>
	/// DirectX 12.1, Shader Model 6.1 (Ray tracing functions and structures)
	/// </summary>
	Level_12_1,
	/// <summary>
	/// DirectX 12.2, Shader Model 6.2 (16-bit scalar types)
	/// </summary>
	Level_12_2,
	/// <summary>
	/// DirectX 12.3, Shader Model 6.3 (Ray tracing enhancements)
	/// </summary>
	Level_12_3,
	/// <summary>
	/// DirectX 12.4, Shader Model 6.4 (Wave matrix intrinsics for ML)
	/// </summary>
	Level_12_4,
	/// <summary>
	/// DirectX 12.5, Shader Model 6.5 (New wave intrinsics, Mesh and Amplification shaders)
	/// </summary>
	Level_12_5,
	/// <summary>
	/// DirectX 12.6, Shader Model 6.6 (64-bit atomics, IsHelperLane, packed intrinsics)
	/// </summary>
	Level_12_6,
	/// <summary>
	/// DirectX 12.7, Shader Model 6.7 (QuadAny/All, SampleCmpLevel, writable MSAA)
	/// </summary>
	Level_12_7
}
