using System;
using System.IO;
namespace Sedulous.Resources;

interface IResourceManager
{
	Type ResourceType { get; }

	Result<ResourceHandle<IResource>, ResourceLoadError> Load(StringView path);

	Result<ResourceHandle<IResource>, ResourceLoadError> Load(MemoryStream stream);

	void Unload(ref ResourceHandle<IResource> resource);
}