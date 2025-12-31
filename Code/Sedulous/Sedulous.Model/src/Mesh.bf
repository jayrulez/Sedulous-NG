using System;
using System.Collections;

namespace Sedulous.Model;

/// A single draw call unit with vertices and indices
class MeshPrimitive
{
	/// Vertex data for this primitive
	public List<Vertex> Vertices = new .() ~ delete _;

	/// Index data for this primitive (indices into Vertices array)
	public List<uint32> Indices = new .() ~ delete _;

	/// Index into Model.Materials array (-1 if no material)
	public int32 MaterialIndex = -1;

	/// Primitive topology type
	public PrimitiveType PrimitiveType = .Triangles;

	/// Morph target weights (for blend shapes)
	public List<float> MorphTargetWeights ~ delete _;

	public this()
	{
	}

	/// Creates a primitive with the specified topology
	public this(PrimitiveType primitiveType)
	{
		PrimitiveType = primitiveType;
	}

	/// Returns the number of vertices
	public int VertexCount => Vertices.Count;

	/// Returns the number of indices
	public int IndexCount => Indices.Count;

	/// Returns true if this primitive has indices
	public bool HasIndices => Indices.Count > 0;

	/// Adds a vertex and returns its index
	public uint32 AddVertex(Vertex vertex)
	{
		let index = (uint32)Vertices.Count;
		Vertices.Add(vertex);
		return index;
	}

	/// Adds a triangle using three vertex indices
	public void AddTriangle(uint32 i0, uint32 i1, uint32 i2)
	{
		Indices.Add(i0);
		Indices.Add(i1);
		Indices.Add(i2);
	}
}

/// A mesh containing one or more primitives
class Mesh
{
	/// Mesh name (optional)
	public String Name ~ delete _;

	/// List of primitives that make up this mesh
	public List<MeshPrimitive> Primitives = new .() ~ DeleteContainerAndItems!(_);

	/// Morph target names (for blend shapes)
	public List<String> MorphTargetNames ~ DeleteContainerAndItems!(_);

	public this()
	{
	}

	public this(String name)
	{
		Name = new String(name);
	}

	/// Returns the total vertex count across all primitives
	public int TotalVertexCount
	{
		get
		{
			int count = 0;
			for (let prim in Primitives)
				count += prim.VertexCount;
			return count;
		}
	}

	/// Returns the total index count across all primitives
	public int TotalIndexCount
	{
		get
		{
			int count = 0;
			for (let prim in Primitives)
				count += prim.IndexCount;
			return count;
		}
	}

	/// Adds a new primitive and returns it
	public MeshPrimitive AddPrimitive(PrimitiveType primitiveType = .Triangles)
	{
		let primitive = new MeshPrimitive(primitiveType);
		Primitives.Add(primitive);
		return primitive;
	}
}
