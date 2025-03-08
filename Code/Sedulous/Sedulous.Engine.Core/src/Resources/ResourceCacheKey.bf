using System;
namespace Sedulous.Engine.Core.Resources;

internal struct ResourceCacheKey : IHashable
{
	public int PathHash = 0;
	public Type ResourceType = null;

	public this(StringView path, Type resourceType)
	{
		PathHash = HashCode.Generate(path);
		ResourceType = resourceType;
	}

	public int GetHashCode()
	{
		int hashCode = 45;

		hashCode = HashCode.Mix(hashCode, PathHash);
		hashCode = HashCode.Mix(hashCode, ResourceType.GetTypeId());

		return hashCode;
	}
}