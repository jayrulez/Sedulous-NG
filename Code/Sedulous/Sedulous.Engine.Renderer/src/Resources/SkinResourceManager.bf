using Sedulous.Resources;
using System;

namespace Sedulous.Engine.Renderer;

class SkinResourceManager : ResourceManager<SkinResource>
{
	protected override Result<SkinResource, ResourceLoadError> LoadFromMemory(System.IO.MemoryStream memory)
	{
		return default;
	}

	public override void Unload(SkinResource resource)
	{
		resource.ReleaseRef();
	}
}
