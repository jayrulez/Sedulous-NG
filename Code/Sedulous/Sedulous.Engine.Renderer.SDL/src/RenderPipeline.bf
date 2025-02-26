using System.Collections;
using System;
using Sedulous.Engine.Renderer.SDL.RenderPasses;
using SDL3Native;
namespace Sedulous.Engine.Renderer.SDL;

class RenderPipeline
{
	internal readonly SDLRendererSubsystem Renderer;

	private readonly List<RenderPass> mPasses = new .() ~ delete _;

	private readonly Dictionary<String, void*> mSharedResources = new .() ~ delete _;

	public this(SDLRendererSubsystem renderer)
	{
		Renderer = renderer;
	}

	internal void SetSharedResource(String resourceKey, void* resource)
	{
		mSharedResources[resourceKey] = resource;
	}

	internal void RemoveSharedResource(String resourceKey)
	{
		if (mSharedResources.ContainsKey(resourceKey))
		{
			mSharedResources.Remove(resourceKey);
		}
	}

	internal T* GetSharedResource<T>(String resourceKey) where T : struct
	{
		if (!mSharedResources.ContainsKey(resourceKey))
		{
			//return null;
			Runtime.FatalError(scope $"No shared resource with '{resourceKey}' was found.");
		}

		return (T*)mSharedResources[resourceKey];
	}

	public void Setup()
	{
		//mPasses.Add(new GBufferPass(this));
		//mPasses.Add(new LightingPass(this));
		//mPasses.Add(new CompositionPass(this));

		for(var pass in mPasses)
		{
			pass.Initialize();
		}
	}

	public void Destroy()
	{
		for (var pass in mPasses.Reversed)
		{
			pass.Destroy();
			delete pass;
		}
	}

	public void Execute(SDL_GPUCommandBuffer* commandBuffer)
	{
		for (var pass in mPasses)
		{
			pass.Execute(commandBuffer);
		}
	}

	public void OnResize(uint32 width, uint32 height)
	{
		for (var pass in mPasses)
		{
			pass.OnResize(width, height);
		}
	}
}