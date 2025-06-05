using Sedulous.Resources;
namespace Sedulous.Engine.Renderer;

class TextureResourceManager : ResourceManager<TextureResource>
{
	protected override System.Result<ResourceHandle<TextureResource>, ResourceLoadError> LoadFromMemory(System.IO.MemoryStream memory)
	{
		return default;
	}

	public override void Unload(TextureResource resource)
	{
		resource.ReleaseRef();
	}
}