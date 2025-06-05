using Sedulous.Resources;
namespace Sedulous.Engine.Renderer;

class MeshResourceManager : ResourceManager<MeshResource>
{
	protected override System.Result<ResourceHandle<MeshResource>, ResourceLoadError> LoadFromMemory(System.IO.MemoryStream memory)
	{
		return default;
	}

	public override void Unload(MeshResource resource)
	{
		resource.ReleaseRef();
	}
}