using System;
using System.Collections;
using Sedulous.Mathematics;

namespace Sedulous.Engine.Renderer;

/// Skeleton node for animation
class SkeletonNode
{
	public String Name ~ delete _;
	public Vector3 Translation = Vector3.Zero;
	public Quaternion Rotation = Quaternion.Identity;
	public Vector3 Scale = Vector3.One;
	public int32 ParentIndex = -1;  // -1 for root nodes
	public List<int32> ChildIndices = new .() ~ delete _;

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
}

/// Skeleton structure for animation
class SkeletonData
{
	public List<SkeletonNode> Nodes = new .() ~ DeleteContainerAndItems!(_);
	public List<int32> RootNodeIndices = new .() ~ delete _;

	public int NodeCount => Nodes.Count;

	public SkeletonNode GetNode(int32 index)
	{
		if (index >= 0 && index < Nodes.Count)
			return Nodes[index];
		return null;
	}
}
