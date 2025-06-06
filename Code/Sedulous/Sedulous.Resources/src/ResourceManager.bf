using System;
using System.IO;
using System.Collections;
namespace Sedulous.Resources;

abstract class ResourceManager<T> : IResourceManager where T : IResource
{
	public Type ResourceType => typeof(T);

	public Result<ResourceHandle<IResource>, ResourceLoadError> Load(StringView path)
	{
		var handle = LoadFromFile(path);
		if (handle case .Err(let error))
			return .Err(error);
		return ResourceHandle<IResource>(handle.Value);
	}

	public Result<ResourceHandle<IResource>, ResourceLoadError> Load(MemoryStream stream)
	{
		var handle = LoadFromMemory(stream);
		if (handle case .Err(let error))
			return .Err(error);
		return ResourceHandle<IResource>(handle.Value);
	}

	protected virtual Result<void, FileOpenError> ReadFile(StringView path, List<uint8> buffer)
	{
		var stream = scope UnbufferedFileStream();

		var fileOpenResult = stream.Open(path, .Read);
		if (fileOpenResult case .Err(let error))
		{
			return .Err(error);
		}

		var memory = scope List<uint8>() { Count = stream.Length };
		var readResult = stream.TryRead(memory);
		if (readResult case .Err)
			return .Err(.Unknown);

		buffer.AddRange(memory);
		return .Ok;
	}

	protected virtual Result<T, ResourceLoadError> LoadFromFile(StringView path)
	{
		var memory = scope List<uint8>();
		var readFile = ReadFile(path, memory);
		if (readFile case .Err(let error))
		{
			switch (error)
			{
			case .NotFound:
				return .Err(.NotFound);

			default:
				return .Err(.Unknown);
			}
		}

		return LoadFromMemory(scope MemoryStream(memory, false));
	}

	protected abstract Result<T, ResourceLoadError> LoadFromMemory(MemoryStream memory);

	public abstract void Unload(T resource);

	public void Unload(ref ResourceHandle<IResource> resource)
	{
		Unload((T)resource.Resource);
	}
}