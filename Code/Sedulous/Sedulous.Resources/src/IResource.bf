using System;
namespace Sedulous.Resources;

interface IResource
{
	public Guid Id { get; }

	public int RefCount {get;}

	public void AddRef();

	public void ReleaseRef();

	public void ReleaseLastRef();

	public int ReleaseRefNoDelete();
}