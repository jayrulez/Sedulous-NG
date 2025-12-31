using Sedulous.Resources;
using System;

namespace Sedulous.Engine.Renderer;

class SkeletonResourceManager : ResourceManager<SkeletonResource>
{
	protected override Result<SkeletonResource, ResourceLoadError> LoadFromMemory(System.IO.MemoryStream memory)
	{
		return default;
	}

	public override void Unload(SkeletonResource resource)
	{
		resource.ReleaseRef();
	}
}
