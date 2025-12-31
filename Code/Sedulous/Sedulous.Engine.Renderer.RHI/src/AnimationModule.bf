using Sedulous.SceneGraph;
using Sedulous.Engine.Core;
using Sedulous.Engine.Renderer;
using Sedulous.Mathematics;
using System;
using System.Collections;
using Sedulous.Utilities;

namespace Sedulous.Engine.Renderer.RHI;

/// Scene module that updates skeletal animations
class AnimationModule : SceneModule
{
	public override StringView Name => "Animation";

	private EntityQuery mAnimatorQuery;

	public this()
	{
		mAnimatorQuery = CreateQuery().With<Animator>();
	}

	public ~this()
	{
		DestroyQuery(mAnimatorQuery);
	}

	protected override void OnUpdate(Time time)
	{
		float deltaTime = (float)time.ElapsedTime.TotalSeconds;

		// Update all animators
		for (var entity in mAnimatorQuery.GetEntities(Scene, .. scope .()))
		{
			if (entity.HasComponent<Animator>())
			{
				var animator = entity.GetComponent<Animator>();
				UpdateAnimator(animator, deltaTime);
			}
		}
	}

	private void UpdateAnimator(Animator animator, float deltaTime)
	{
		if (!animator.IsPlaying || animator.CurrentAnimationIndex < 0)
			return;

		var animHandle = animator.CurrentAnimation;
		if (!animHandle.IsValid || animHandle.Resource == null)
			return;

		var animation = animHandle.Resource.Animation;
		if (animation == null)
			return;

		// Advance time
		animator.CurrentTime = animator.CurrentTime + deltaTime * animator.PlaybackSpeed;

		// Handle looping
		if (animator.CurrentTime >= animation.Duration)
		{
			if (animator.Loop)
			{
				animator.CurrentTime = animator.CurrentTime % animation.Duration;
			}
			else
			{
				animator.CurrentTime = animation.Duration;
				animator.IsPlaying = false;
			}
		}

		// Sample animation channels
		SampleAnimation(animator, animation, animator.CurrentTime);

		// Compute bone matrices
		ComputeBoneMatrices(animator);
	}

	private void SampleAnimation(Animator animator, AnimationClipData animation, float time)
	{
		// Sample each channel
		for (var channel in animation.Channels)
		{
			int32 nodeIndex = channel.TargetNodeIndex;
			if (nodeIndex < 0 || nodeIndex >= animator.JointTranslations.Count)
				continue;

			var sampler = channel.Sampler;
			if (sampler.KeyframeCount == 0)
				continue;

			switch (channel.TargetPath)
			{
			case .Translation:
				animator.JointTranslations[nodeIndex] = SampleTranslation(sampler, time);
			case .Rotation:
				animator.JointRotations[nodeIndex] = SampleRotation(sampler, time);
			case .Scale:
				animator.JointScales[nodeIndex] = SampleScale(sampler, time);
			case .Weights:
				// Morph target weights not implemented
				break;
			}
		}
	}

	private Vector3 SampleTranslation(AnimationSamplerData sampler, float time)
	{
		var (idx0, idx1, t) = FindKeyframes(sampler, time);

		if (idx0 == idx1 || sampler.Interpolation == .Step)
			return sampler.GetTranslation(idx0);

		var v0 = sampler.GetTranslation(idx0);
		var v1 = sampler.GetTranslation(idx1);
		return Vector3.Lerp(v0, v1, t);
	}

	private Quaternion SampleRotation(AnimationSamplerData sampler, float time)
	{
		var (idx0, idx1, t) = FindKeyframes(sampler, time);

		if (idx0 == idx1 || sampler.Interpolation == .Step)
			return sampler.GetRotation(idx0);

		var q0 = sampler.GetRotation(idx0);
		var q1 = sampler.GetRotation(idx1);
		return Quaternion.Slerp(q0, q1, t);
	}

	private Vector3 SampleScale(AnimationSamplerData sampler, float time)
	{
		var (idx0, idx1, t) = FindKeyframes(sampler, time);

		if (idx0 == idx1 || sampler.Interpolation == .Step)
			return sampler.GetScale(idx0);

		var v0 = sampler.GetScale(idx0);
		var v1 = sampler.GetScale(idx1);
		return Vector3.Lerp(v0, v1, t);
	}

	/// Find surrounding keyframe indices and interpolation factor
	private (int idx0, int idx1, float t) FindKeyframes(AnimationSamplerData sampler, float time)
	{
		if (sampler.KeyframeCount == 0)
			return (0, 0, 0);

		if (sampler.KeyframeCount == 1)
			return (0, 0, 0);

		// Clamp time to animation range
		if (time <= sampler.KeyframeTimes[0])
			return (0, 0, 0);

		int lastIdx = sampler.KeyframeCount - 1;
		if (time >= sampler.KeyframeTimes[lastIdx])
			return (lastIdx, lastIdx, 0);

		// Binary search for keyframe
		int idx0 = 0;
		int idx1 = lastIdx;

		while (idx1 - idx0 > 1)
		{
			int mid = (idx0 + idx1) / 2;
			if (sampler.KeyframeTimes[mid] <= time)
				idx0 = mid;
			else
				idx1 = mid;
		}

		float t0 = sampler.KeyframeTimes[idx0];
		float t1 = sampler.KeyframeTimes[idx1];
		float t = (time - t0) / (t1 - t0);

		return (idx0, idx1, t);
	}

	private void ComputeBoneMatrices(Animator animator)
	{
		var skeletonHandle = animator.Skeleton;
		if (!skeletonHandle.IsValid || skeletonHandle.Resource == null)
			return;

		var skeleton = skeletonHandle.Resource;
		var nodes = skeleton.Nodes;
		if (nodes == null || nodes.Count == 0)
			return;

		int nodeCount = nodes.Count;

		// Compute local transforms first
		var localTransforms = scope Matrix[nodeCount];
		for (int32 i = 0; i < nodeCount; i++)
		{
			if (i < animator.JointTranslations.Count)
			{
				var translation = animator.JointTranslations[i];
				var rotation = animator.JointRotations[i];
				var scale = animator.JointScales[i];

				let scaleMatrix = Matrix.CreateScale(scale.X, scale.Y, scale.Z);
				let rotationMatrix = Matrix.CreateFromQuaternion(rotation);
				let translationMatrix = Matrix.CreateTranslation(translation.X, translation.Y, translation.Z);
				localTransforms[i] = scaleMatrix * rotationMatrix * translationMatrix;
			}
			else
			{
				localTransforms[i] = nodes[i].LocalTransform;
			}
		}

		// Compute world transforms - handle arbitrary node order by computing recursively
		var worldTransforms = scope Matrix[nodeCount];
		var computed = scope bool[nodeCount];
		for (int32 i = 0; i < nodeCount; i++)
		{
			ComputeNodeWorldTransform(i, nodes, localTransforms, worldTransforms, computed);
		}

		// Store world transforms in bone matrices
		for (int32 i = 0; i < Math.Min(nodeCount, animator.BoneMatrices.Count); i++)
		{
			animator.BoneMatrices[i] = worldTransforms[i];
		}
	}

	private void ComputeNodeWorldTransform(int32 nodeIndex, List<SkeletonNode> nodes, Matrix[] localTransforms, Matrix[] worldTransforms, bool[] computed)
	{
		if (computed[nodeIndex])
			return;

		var node = nodes[nodeIndex];

		if (node.ParentIndex >= 0 && node.ParentIndex < nodes.Count)
		{
			// Ensure parent is computed first
			ComputeNodeWorldTransform(node.ParentIndex, nodes, localTransforms, worldTransforms, computed);
			worldTransforms[nodeIndex] = localTransforms[nodeIndex] * worldTransforms[node.ParentIndex];
		}
		else
		{
			// Root node
			worldTransforms[nodeIndex] = localTransforms[nodeIndex];
		}

		computed[nodeIndex] = true;
	}
}
