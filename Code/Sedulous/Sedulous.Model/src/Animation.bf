using System;
using System.Collections;

namespace Sedulous.Model;

/// Animation clip containing multiple channels
class Animation
{
	/// Animation name (optional)
	public String Name ~ delete _;

	/// Animation channels, each targeting a specific node property
	public List<AnimationChannel> Channels = new .() ~ DeleteContainerAndItems!(_);

	public this()
	{
	}

	public this(String name)
	{
		Name = new String(name);
	}

	/// Returns the total duration of this animation (max of all channel durations)
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

	/// Returns the number of channels in this animation
	public int ChannelCount => Channels.Count;

	/// Adds a new animation channel
	public AnimationChannel AddChannel(int32 targetNodeIndex, AnimationPath targetPath)
	{
		let channel = new AnimationChannel(targetNodeIndex, targetPath);
		Channels.Add(channel);
		return channel;
	}
}
