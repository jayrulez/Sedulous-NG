using Sedulous.Resources;
using System;
namespace Sedulous.Engine.Renderer;

class TextureResourceManager : ResourceManager<TextureResource>
{
	protected override Result<TextureResource, ResourceLoadError> LoadFromMemory(System.IO.MemoryStream memory)
	{
		return default;
	}

	public override void Unload(TextureResource resource)
	{
		resource.ReleaseRef();
	}
}