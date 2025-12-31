using Sedulous.Resources;
using Sedulous.Mathematics;
using System;
using System.Collections;

namespace Sedulous.Engine.Renderer;

/// Resource wrapper for skeleton structure (node hierarchy for animation)
class SkeletonResource : Resource
{
	private SkeletonData mSkeleton;
	private bool mOwnsSkeleton = false;

	public SkeletonData Skeleton => mSkeleton;
	public List<SkeletonNode> Nodes => mSkeleton?.Nodes;
	public List<int32> RootNodeIndices => mSkeleton?.RootNodeIndices;
	public int NodeCount => mSkeleton?.NodeCount ?? 0;

	public this(SkeletonData skeleton, bool ownsSkeleton = false)
	{
		Id = Guid.Create();
		mSkeleton = skeleton;
		mOwnsSkeleton = ownsSkeleton;
	}

	public ~this()
	{
		if (mOwnsSkeleton && mSkeleton != null)
		{
			delete mSkeleton;
		}
	}

	/// Get node by index
	public SkeletonNode GetNode(int32 index)
	{
		return mSkeleton?.GetNode(index);
	}

	/// Find node index by name
	public int32 FindNodeIndex(StringView name)
	{
		if (mSkeleton == null)
			return -1;

		for (int32 i = 0; i < mSkeleton.Nodes.Count; i++)
		{
			if (mSkeleton.Nodes[i].Name != null && mSkeleton.Nodes[i].Name == name)
				return i;
		}
		return -1;
	}
}
