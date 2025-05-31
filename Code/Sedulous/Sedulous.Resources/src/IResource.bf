using System;
using Sedulous.Foundation.Utilities;
namespace Sedulous.Resources;

interface IResource
{
	public GUID Id { get; }

	public int RefCount {get;}

	public void AddRef();

	public void ReleaseRef();

	public void ReleaseLastRef();

	public int ReleaseRefNoDelete();
}