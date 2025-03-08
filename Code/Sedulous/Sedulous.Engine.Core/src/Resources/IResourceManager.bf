using System;
using System.IO;
namespace Sedulous.Engine.Core.Resources;

interface IResourceManager
{
	Type ResourceType { get; }

	Result<IResource, ResourceLoadError> Load(StringView path);

	Result<IResource, ResourceLoadError> Load(MemoryStream stream);

	void Unload(IResource resource);
}