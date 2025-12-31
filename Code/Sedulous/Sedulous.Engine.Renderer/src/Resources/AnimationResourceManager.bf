using Sedulous.Resources;
using System;

namespace Sedulous.Engine.Renderer;

class AnimationResourceManager : ResourceManager<AnimationResource>
{
	protected override Result<AnimationResource, ResourceLoadError> LoadFromMemory(System.IO.MemoryStream memory)
	{
		return default;
	}

	public override void Unload(AnimationResource resource)
	{
		resource.ReleaseRef();
	}
}
