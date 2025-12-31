using System;
using System.Collections;
using Sedulous.Mathematics;

namespace Sedulous.Model;

/// Skeletal binding information for skinned meshes
class Skin
{
	/// Skin name (optional)
	public String Name ~ delete _;

	/// Indices of nodes that act as joints/bones
	/// These indices refer to Model.Nodes array
	public List<int32> JointIndices = new .() ~ delete _;

	/// Inverse bind matrices for each joint
	/// These transform vertices from mesh space to bone local space
	public List<Matrix> InverseBindMatrices = new .() ~ delete _;

	/// Index of the skeleton root node in Model.Nodes (-1 if not specified)
	public int32 SkeletonRootIndex = -1;

	public this()
	{
	}

	public this(String name)
	{
		Name = new String(name);
	}

	/// Returns the number of joints in this skin
	public int JointCount => JointIndices.Count;

	/// Adds a joint with its inverse bind matrix
	public void AddJoint(int32 nodeIndex, Matrix inverseBindMatrix)
	{
		JointIndices.Add(nodeIndex);
		InverseBindMatrices.Add(inverseBindMatrix);
	}
}
