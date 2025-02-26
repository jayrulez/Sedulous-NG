using SDL3Native;
namespace Sedulous.Engine.Renderer.SDL;

using internal Sedulous.Engine.Renderer.SDL;

abstract class RenderPass
{
	protected readonly SDLRendererSubsystem Renderer { get; private set; }
	protected readonly RenderPipeline Pipeline { get; private set; }

	public this(RenderPipeline pipeline)
	{
		Renderer = pipeline.Renderer;
		Pipeline = pipeline;
	}

	public virtual void Initialize() { }
	public virtual void Destroy() { }

	public abstract void Execute(SDL_GPUCommandBuffer* commandBuffer);

	public virtual void OnResize(uint32 width, uint32 height) { }
}