using Sedulous.Resources;
using System;

namespace Sedulous.Engine.Renderer;

/// Resource wrapper for animation clip data
class AnimationResource : Resource
{
	private AnimationClipData mAnimation;
	private bool mOwnsAnimation = false;

	public AnimationClipData Animation => mAnimation;
	public String AnimationName => mAnimation?.Name;
	public float Duration => mAnimation?.Duration ?? 0;
	public int ChannelCount => mAnimation?.ChannelCount ?? 0;

	public this(AnimationClipData animation, bool ownsAnimation = false)
	{
		Id = Guid.Create();
		mAnimation = animation;
		mOwnsAnimation = ownsAnimation;
	}

	public ~this()
	{
		if (mOwnsAnimation && mAnimation != null)
		{
			delete mAnimation;
		}
	}

	/// Get animation channel by index
	public AnimationChannelData GetChannel(int index)
	{
		if (mAnimation != null && index >= 0 && index < mAnimation.Channels.Count)
			return mAnimation.Channels[index];
		return null;
	}
}
