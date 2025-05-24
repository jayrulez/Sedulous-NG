using Sedulous.Engine.Core.SceneGraph;
using System;
namespace Sedulous.Engine.Renderer.SDL;

class PostProcessModule : SceneModule
{
    public override StringView Name => "PostProcess";
    
    private SDLRendererSubsystem mRenderer;
    
    public this(SDLRendererSubsystem renderer)
    {
        mRenderer = renderer;
    }
    
    public void ApplyEffects()
    {
        // Apply post-processing effects like bloom, tone mapping, etc.
    }
}