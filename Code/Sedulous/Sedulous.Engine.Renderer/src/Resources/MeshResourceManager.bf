using Sedulous.Resources;
using System;
namespace Sedulous.Engine.Renderer;

class MeshResourceManager : ResourceManager<MeshResource>
{
	protected override Result<MeshResource, ResourceLoadError> LoadFromMemory(System.IO.MemoryStream memory)
	{
		return default;
	}

	public override void Unload(MeshResource resource)
	{
		resource.ReleaseRef();
	}
}