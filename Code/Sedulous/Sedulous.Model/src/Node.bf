using System;
using System.Collections;
using Sedulous.Mathematics;

namespace Sedulous.Model;

/// Scene hierarchy node with transform, mesh reference, and children
class Node
{
	/// Node name (optional)
	public String Name ~ delete _;

	/// Translation component of local transform
	public Vector3 Translation = Vector3.Zero;

	/// Rotation component of local transform (quaternion)
	public Quaternion Rotation = Quaternion.Identity;

	/// Scale component of local transform
	public Vector3 Scale = Vector3.One;

	/// Index into Model.Meshes array (-1 if no mesh)
	public int32 MeshIndex = -1;

	/// Index into Model.Skins array (-1 if no skin)
	public int32 SkinIndex = -1;

	/// Child nodes (references only - nodes are owned by Model.Nodes)
	/// When creating nodes manually outside of Model, caller is responsible for node lifetime
	public List<Node> Children = new .() ~ delete _;

	/// Parent node (weak reference, not owned)
	public Node Parent = null;

	/// Camera index if this node has a camera (-1 if none)
	public int32 CameraIndex = -1;

	/// Morph target weights (for blend shapes, if mesh has morph targets)
	public List<float> Weights ~ delete _;

	public this()
	{
	}

	public this(String name)
	{
		Name = new String(name);
	}

	/// Gets the local transform matrix from TRS components
	public Matrix LocalTransform
	{
		get
		{
			let scaleMatrix = Matrix.CreateScale(Scale.X, Scale.Y, Scale.Z);
			let rotationMatrix = Matrix.CreateFromQuaternion(Rotation);
			let translationMatrix = Matrix.CreateTranslation(Translation.X, Translation.Y, Translation.Z);
			return scaleMatrix * rotationMatrix * translationMatrix;
		}
	}

	/// Gets the world transform by concatenating parent transforms
	public Matrix WorldTransform
	{
		get
		{
			if (Parent != null)
				return LocalTransform * Parent.WorldTransform;
			return LocalTransform;
		}
	}

	/// Returns true if this node has a mesh
	public bool HasMesh => MeshIndex >= 0;

	/// Returns true if this node has a skin (skeletal mesh)
	public bool HasSkin => SkinIndex >= 0;

	/// Returns true if this node has children
	public bool HasChildren => Children.Count > 0;

	/// Adds a child node and sets its parent
	public void AddChild(Node child)
	{
		child.Parent = this;
		Children.Add(child);
	}

	/// Creates and adds a new child node with the given name
	public Node AddChild(String name)
	{
		let child = new Node(name);
		AddChild(child);
		return child;
	}
}
