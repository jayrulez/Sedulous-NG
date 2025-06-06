using Sedulous.Resources;
using System.IO;
using System;
namespace Sedulous.Engine.Renderer;

class MaterialResourceManager : ResourceManager<MaterialResource>
{
    protected override Result<MaterialResource, ResourceLoadError> LoadFromMemory(MemoryStream memory)
    {
        // TODO: Implement material loading from file
        // This would parse material definitions (JSON, XML, custom format)
        return .Err(.NotSupported);
    }
    
    public override void Unload(MaterialResource resource)
    {
        resource.ReleaseRef();
    }
}