using Sedulous.Resources;
using System;

namespace Sedulous.Engine.Renderer;

class SkinnedMeshResourceManager : ResourceManager<SkinnedMeshResource>
{
	protected override Result<SkinnedMeshResource, ResourceLoadError> LoadFromMemory(System.IO.MemoryStream memory)
	{
		return default;
	}

	public override void Unload(SkinnedMeshResource resource)
	{
		resource.ReleaseRef();
	}
}
