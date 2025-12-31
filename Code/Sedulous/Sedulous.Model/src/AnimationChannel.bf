using System;
using System.Collections;
using Sedulous.Mathematics;

namespace Sedulous.Model;

/// Keyframe sampler with interpolation data
class AnimationSampler
{
	/// Keyframe times in seconds
	public List<float> KeyframeTimes = new .() ~ delete _;

	/// Keyframe values as raw floats
	/// The number of floats per keyframe depends on the target path:
	/// - Translation: 3 floats (x, y, z)
	/// - Rotation: 4 floats (x, y, z, w quaternion)
	/// - Scale: 3 floats (x, y, z)
	/// - Weights: N floats (morph target weights)
	/// For CubicSpline interpolation, each keyframe has 3x the values (in-tangent, value, out-tangent)
	public List<float> KeyframeValues = new .() ~ delete _;

	/// Interpolation method between keyframes
	public InterpolationType Interpolation = .Linear;

	public this()
	{
	}

	/// Returns the number of keyframes
	public int KeyframeCount => KeyframeTimes.Count;

	/// Returns the duration of this sampler (time of last keyframe)
	public float Duration => KeyframeTimes.Count > 0 ? KeyframeTimes[KeyframeTimes.Count - 1] : 0;

	/// Adds a translation keyframe
	public void AddTranslationKeyframe(float time, Vector3 translation)
	{
		KeyframeTimes.Add(time);
		KeyframeValues.Add(translation.X);
		KeyframeValues.Add(translation.Y);
		KeyframeValues.Add(translation.Z);
	}

	/// Adds a rotation keyframe
	public void AddRotationKeyframe(float time, Quaternion rotation)
	{
		KeyframeTimes.Add(time);
		KeyframeValues.Add(rotation.X);
		KeyframeValues.Add(rotation.Y);
		KeyframeValues.Add(rotation.Z);
		KeyframeValues.Add(rotation.W);
	}

	/// Adds a scale keyframe
	public void AddScaleKeyframe(float time, Vector3 scale)
	{
		KeyframeTimes.Add(time);
		KeyframeValues.Add(scale.X);
		KeyframeValues.Add(scale.Y);
		KeyframeValues.Add(scale.Z);
	}

	/// Gets a translation value at the specified keyframe index
	public Vector3 GetTranslation(int keyframeIndex)
	{
		let baseIndex = keyframeIndex * 3;
		return Vector3(
			KeyframeValues[baseIndex],
			KeyframeValues[baseIndex + 1],
			KeyframeValues[baseIndex + 2]
		);
	}

	/// Gets a rotation value at the specified keyframe index
	public Quaternion GetRotation(int keyframeIndex)
	{
		let baseIndex = keyframeIndex * 4;
		return Quaternion(
			KeyframeValues[baseIndex],
			KeyframeValues[baseIndex + 1],
			KeyframeValues[baseIndex + 2],
			KeyframeValues[baseIndex + 3]
		);
	}

	/// Gets a scale value at the specified keyframe index
	public Vector3 GetScale(int keyframeIndex)
	{
		let baseIndex = keyframeIndex * 3;
		return Vector3(
			KeyframeValues[baseIndex],
			KeyframeValues[baseIndex + 1],
			KeyframeValues[baseIndex + 2]
		);
	}
}

/// Animation channel targeting a specific node property
class AnimationChannel
{
	/// Index of the target node in Model.Nodes
	public int32 TargetNodeIndex = -1;

	/// The property being animated
	public AnimationPath TargetPath = .Translation;

	/// The sampler containing keyframe data
	public AnimationSampler Sampler = new .() ~ delete _;

	public this()
	{
	}

	public this(int32 targetNodeIndex, AnimationPath targetPath)
	{
		TargetNodeIndex = targetNodeIndex;
		TargetPath = targetPath;
	}

	/// Returns the duration of this channel
	public float Duration => Sampler.Duration;
}
