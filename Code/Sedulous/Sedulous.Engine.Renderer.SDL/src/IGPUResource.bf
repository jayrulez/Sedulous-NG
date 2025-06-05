using System;
namespace Sedulous.Engine.Renderer.SDL;

interface IGPUResource
{
	public StringView Name {get;}

	public int RefCount {get;}

	public void AddRef();

	public void ReleaseRef();

	public void ReleaseLastRef();

	public int ReleaseRefNoDelete();
}