using System;
using System.Collections;
using Sedulous.Mathematics;

namespace Sedulous.Engine.Renderer;

/// Animation target path
enum AnimationTargetPath
{
	Translation,
	Rotation,
	Scale,
	Weights
}

/// Interpolation type for keyframes
enum AnimationInterpolation
{
	Linear,
	Step,
	CubicSpline
}

/// Animation sampler containing keyframe data
class AnimationSamplerData
{
	public List<float> KeyframeTimes = new .() ~ delete _;
	public List<float> KeyframeValues = new .() ~ delete _;
	public AnimationInterpolation Interpolation = .Linear;

	public int KeyframeCount => KeyframeTimes.Count;
	public float Duration => KeyframeTimes.Count > 0 ? KeyframeTimes[KeyframeTimes.Count - 1] : 0;

	public Vector3 GetTranslation(int index)
	{
		let i = index * 3;
		return Vector3(KeyframeValues[i], KeyframeValues[i + 1], KeyframeValues[i + 2]);
	}

	public Quaternion GetRotation(int index)
	{
		let i = index * 4;
		return Quaternion(KeyframeValues[i], KeyframeValues[i + 1], KeyframeValues[i + 2], KeyframeValues[i + 3]);
	}

	public Vector3 GetScale(int index)
	{
		let i = index * 3;
		return Vector3(KeyframeValues[i], KeyframeValues[i + 1], KeyframeValues[i + 2]);
	}
}

/// Animation channel targeting a specific node property
class AnimationChannelData
{
	public int32 TargetNodeIndex = -1;
	public AnimationTargetPath TargetPath = .Translation;
	public AnimationSamplerData Sampler = new .() ~ delete _;

	public float Duration => Sampler.Duration;
}

/// Animation clip containing multiple channels
class AnimationClipData
{
	public String Name ~ delete _;
	public List<AnimationChannelData> Channels = new .() ~ DeleteContainerAndItems!(_);

	public float Duration
	{
		get
		{
			float maxDuration = 0;
			for (let channel in Channels)
			{
				if (channel.Duration > maxDuration)
					maxDuration = channel.Duration;
			}
			return maxDuration;
		}
	}

	public int ChannelCount => Channels.Count;
}
