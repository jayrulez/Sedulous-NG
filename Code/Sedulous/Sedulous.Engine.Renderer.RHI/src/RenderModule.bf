using Sedulous.SceneGraph;
using System;
using Sedulous.Engine.Core;
namespace Sedulous.Engine.Renderer.RHI;

class RenderModule: SceneModule
{
	public override StringView Name => "Render";

	private RHIRendererSubsystem mRenderer;

	public this(RHIRendererSubsystem renderer)
	{
		mRenderer = renderer;
	}

	internal void RenderFrame(IEngine.UpdateInfo info)
	{

	}
}