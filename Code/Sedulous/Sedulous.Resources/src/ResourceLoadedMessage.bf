using Sedulous.Messaging;
using System;
namespace Sedulous.Resources;

class ResourceLoadedMessage : Message
{
    public StringView ResourcePath { get; private set; }
    public IResource Resource { get; private set; }

    public this(StringView resourcePath, IResource resource)
    {
        ResourcePath = resourcePath;
        Resource = resource;
    }
}