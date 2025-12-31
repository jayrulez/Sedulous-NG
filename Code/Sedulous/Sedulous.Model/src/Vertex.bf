using Sedulous.Mathematics;
using System;

namespace Sedulous.Model;

/// Full PBR vertex with all attributes for GPU rendering
[CRepr]
struct Vertex
{
	/// Vertex position in local space
	public Vector3 Position;

	/// Vertex normal vector (normalized)
	public Vector3 Normal;

	/// Tangent vector with handedness in W component (-1 or 1)
	public Vector4 Tangent;

	/// Primary texture coordinates
	public Vector2 TexCoord0;

	/// Secondary texture coordinates (for lightmaps, detail maps, etc.)
	public Vector2 TexCoord1;

	/// Vertex color (RGBA)
	public Vector4 Color;

	/// Bone indices for skeletal animation (up to 4 bones per vertex)
	public uint16[4] Joints;

	/// Bone weights for skeletal animation (normalized, should sum to 1.0)
	public Vector4 Weights;

	/// Creates a default vertex with identity values
	public this()
	{
		Position = .Zero;
		Normal = Vector3(0, 1, 0);
		Tangent = Vector4(1, 0, 0, 1);
		TexCoord0 = .Zero;
		TexCoord1 = .Zero;
		Color = Vector4(1, 1, 1, 1);
		Joints = .(0, 0, 0, 0);
		Weights = Vector4(1, 0, 0, 0);
	}

	/// Creates a vertex with position only
	public this(Vector3 position)
	{
		Position = position;
		Normal = Vector3(0, 1, 0);
		Tangent = Vector4(1, 0, 0, 1);
		TexCoord0 = .Zero;
		TexCoord1 = .Zero;
		Color = Vector4(1, 1, 1, 1);
		Joints = .(0, 0, 0, 0);
		Weights = Vector4(1, 0, 0, 0);
	}

	/// Creates a vertex with position, normal, and texture coordinates
	public this(Vector3 position, Vector3 normal, Vector2 texCoord0)
	{
		Position = position;
		Normal = normal;
		Tangent = Vector4(1, 0, 0, 1);
		TexCoord0 = texCoord0;
		TexCoord1 = .Zero;
		Color = Vector4(1, 1, 1, 1);
		Joints = .(0, 0, 0, 0);
		Weights = Vector4(1, 0, 0, 0);
	}
}
