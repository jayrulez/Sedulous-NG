using System;
namespace Sedulous.Platform.Core;

abstract class Window
{
	public ref SurfaceInfo SurfaceInfo { get; protected set; }

	public abstract uint32 Width { get; }

	public abstract uint32 Height { get; }

	public abstract StringView Title { get; set; }

	public ref Event<delegate void(uint32 width, uint32 height)> OnResized { get; protected set; }

	public this()
	{
	}

	public virtual void* GetNativePointer(String name)
	{
		return null;
	}
}