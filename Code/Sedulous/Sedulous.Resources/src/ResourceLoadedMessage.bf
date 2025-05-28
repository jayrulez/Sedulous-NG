using Sedulous.Messaging;
using System;
namespace Sedulous.Resources;

class ResourceLoadedMessage : Message
{
    public StringView ResourcePath { get; private set; }
    public ResourceHandle<IResource> Resource { get; private set; }

    public this(StringView resourcePath, ResourceHandle<IResource> resource)
    {
        ResourcePath = resourcePath;
        Resource = resource;
    }
}