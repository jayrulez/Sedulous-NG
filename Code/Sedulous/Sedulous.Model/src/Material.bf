using System;
using Sedulous.Mathematics;

namespace Sedulous.Model;

/// Texture info reference with UV set index
struct TextureInfo
{
	/// Index into Model.Textures array (-1 if no texture)
	public int32 TextureIndex = -1;

	/// UV coordinate set to use (0 = TexCoord0, 1 = TexCoord1)
	public int32 TexCoordIndex = 0;

	/// Texture coordinate transform scale
	public Vector2 Scale = Vector2(1, 1);

	/// Texture coordinate transform offset
	public Vector2 Offset = Vector2(0, 0);

	/// Texture coordinate transform rotation (radians)
	public float Rotation = 0;

	/// Returns true if a texture is assigned
	public bool HasTexture => TextureIndex >= 0;
}

/// Normal texture info with scale factor
struct NormalTextureInfo
{
	/// Base texture info
	public TextureInfo Texture = .();

	/// Normal map scale factor
	public float Scale = 1.0f;
}

/// Occlusion texture info with strength factor
struct OcclusionTextureInfo
{
	/// Base texture info
	public TextureInfo Texture = .();

	/// Occlusion strength (0 = no occlusion, 1 = full occlusion)
	public float Strength = 1.0f;
}

/// PBR Metallic-Roughness material
class Material
{
	/// Material name (optional)
	public String Name ~ delete _;

	// PBR Metallic-Roughness properties

	/// Base color factor (RGBA, linear color space)
	public Vector4 BaseColorFactor = Vector4(1, 1, 1, 1);

	/// Metallic factor (0 = dielectric, 1 = metal)
	public float MetallicFactor = 1.0f;

	/// Roughness factor (0 = smooth, 1 = rough)
	public float RoughnessFactor = 1.0f;

	/// Emissive factor (RGB, linear color space)
	public Vector3 EmissiveFactor = Vector3(0, 0, 0);

	// Alpha properties

	/// Alpha rendering mode
	public AlphaMode AlphaMode = .Opaque;

	/// Alpha cutoff threshold for Mask mode
	public float AlphaCutoff = 0.5f;

	// Rendering properties

	/// Whether the material is double-sided
	public bool DoubleSided = false;

	// Texture references

	/// Base color texture (RGB = color, A = alpha)
	public TextureInfo BaseColorTexture = .();

	/// Metallic-roughness texture (B = metallic, G = roughness)
	public TextureInfo MetallicRoughnessTexture = .();

	/// Normal map texture
	public NormalTextureInfo NormalTexture = .();

	/// Ambient occlusion texture (R channel)
	public OcclusionTextureInfo OcclusionTexture = .();

	/// Emissive texture (RGB)
	public TextureInfo EmissiveTexture = .();

	public this()
	{
	}

	public this(String name)
	{
		Name = new String(name);
	}
}
