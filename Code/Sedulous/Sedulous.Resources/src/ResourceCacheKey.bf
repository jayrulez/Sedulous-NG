using System;
namespace Sedulous.Resources;

internal struct ResourceCacheKey : IHashable
{
	public int IdentifierHash = 0;
	public Type ResourceType = null;

	public this(StringView identifier, Type resourceType)
	{
		IdentifierHash = identifier.GetHashCode();
		ResourceType = resourceType;
	}

	public int GetHashCode()
	{
		int hashCode = 45;

		hashCode = HashCode.Mix(hashCode, IdentifierHash);
		hashCode = HashCode.Mix(hashCode, ResourceType.GetTypeId());

		return hashCode;
	}
}