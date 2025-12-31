using System;
using System.Collections;
using Sedulous.Mathematics;

namespace Sedulous.Engine.Renderer;

/// Skin binding data for skeletal animation
class SkinData
{
	public String Name ~ delete _;
	public List<int32> JointIndices = new .() ~ delete _;
	public List<Matrix> InverseBindMatrices = new .() ~ delete _;
	public int32 SkeletonRootIndex = -1;

	public int JointCount => JointIndices.Count;
}
