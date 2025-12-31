using Sedulous.Resources;
using Sedulous.Mathematics;
using System;
using System.Collections;

namespace Sedulous.Engine.Renderer;

/// Resource wrapper for skeletal skin data (joint indices and inverse bind matrices)
class SkinResource : Resource
{
	private SkinData mSkin;
	private bool mOwnsSkin = false;

	public SkinData Skin => mSkin;
	public int JointCount => mSkin?.JointCount ?? 0;
	public List<int32> JointIndices => mSkin?.JointIndices;
	public List<Matrix> InverseBindMatrices => mSkin?.InverseBindMatrices;

	public this(SkinData skin, bool ownsSkin = false)
	{
		Id = Guid.Create();
		mSkin = skin;
		mOwnsSkin = ownsSkin;
	}

	public ~this()
	{
		if (mOwnsSkin && mSkin != null)
		{
			delete mSkin;
		}
	}
}
