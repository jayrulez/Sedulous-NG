using Sedulous.Mathematics;
using Sedulous.SceneGraph;
using Sedulous.Resources;
using System;
using System.Collections;

namespace Sedulous.Engine.Renderer;

/// Component for skeletal animation playback
class Animator : Component
{
	// Skeleton structure (node hierarchy for animation)
	public ResourceHandle<SkeletonResource> Skeleton { get; set; } ~ _.Release();

	// Available animations
	private List<ResourceHandle<AnimationResource>> mAnimations = new .() ~ {
		for (var handle in _)
			handle.Release();
		delete _;
	};

	// Animation playback state
	public int32 CurrentAnimationIndex { get; set; } = -1;
	public float CurrentTime { get; set; } = 0.0f;
	public float PlaybackSpeed { get; set; } = 1.0f;
	public bool IsPlaying { get; set; } = false;
	public bool Loop { get; set; } = true;

	// Computed bone matrices (updated each frame by AnimationModule)
	private List<Matrix> mBoneMatrices = new .() ~ delete _;

	// Animated pose per node (Translation, Rotation, Scale)
	private List<Vector3> mJointTranslations = new .() ~ delete _;
	private List<Quaternion> mJointRotations = new .() ~ delete _;
	private List<Vector3> mJointScales = new .() ~ delete _;

	public List<Matrix> BoneMatrices => mBoneMatrices;
	public List<Vector3> JointTranslations => mJointTranslations;
	public List<Quaternion> JointRotations => mJointRotations;
	public List<Vector3> JointScales => mJointScales;

	public int AnimationCount => mAnimations.Count;

	/// Add an animation to this animator
	public void AddAnimation(ResourceHandle<AnimationResource> animation)
	{
		mAnimations.Add(animation);
	}

	/// Get animation by index
	public ResourceHandle<AnimationResource> GetAnimation(int index)
	{
		if (index >= 0 && index < mAnimations.Count)
			return mAnimations[index];
		return default;
	}

	/// Play animation at given index
	public void Play(int32 animationIndex)
	{
		if (animationIndex >= 0 && animationIndex < mAnimations.Count)
		{
			CurrentAnimationIndex = animationIndex;
			CurrentTime = 0.0f;
			IsPlaying = true;
		}
	}

	/// Stop animation playback
	public void Stop()
	{
		IsPlaying = false;
	}

	/// Pause animation playback
	public void Pause()
	{
		IsPlaying = false;
	}

	/// Resume animation playback
	public void Resume()
	{
		IsPlaying = true;
	}

	/// Get current animation resource (if any)
	public ResourceHandle<AnimationResource> CurrentAnimation
	{
		get
		{
			if (CurrentAnimationIndex >= 0 && CurrentAnimationIndex < mAnimations.Count)
				return mAnimations[CurrentAnimationIndex];
			return default;
		}
	}

	/// Initialize pose arrays to match skeleton node count
	public void InitializePose(int nodeCount)
	{
		mJointTranslations.Clear();
		mJointRotations.Clear();
		mJointScales.Clear();
		mBoneMatrices.Clear();

		for (int i = 0; i < nodeCount; i++)
		{
			mJointTranslations.Add(.Zero);
			mJointRotations.Add(.Identity);
			mJointScales.Add(.(1, 1, 1));
			mBoneMatrices.Add(.Identity);
		}
	}

	/// Resize bone matrices array
	public void ResizeBoneMatrices(int count)
	{
		while (mBoneMatrices.Count < count)
			mBoneMatrices.Add(.Identity);
		while (mBoneMatrices.Count > count)
			mBoneMatrices.PopBack();
	}
}
