using Sedulous.Engine.Core.SceneGraph;
using System;
using SDL3Native;
using System.Collections;
using Sedulous.Foundation.Mathematics;
namespace Sedulous.Engine.Renderer.SDL;

using internal Sedulous.Engine.Renderer.SDL;

class RenderModule : SceneModule
{
    public override StringView Name => "Render";

    private SDLRendererSubsystem mRenderer;

    public this(SDLRendererSubsystem renderer)
    {
        mRenderer = renderer;
    }

    protected override void RegisterComponentInterests()
    {
        // We'll add component interests later when we have cameras and renderers
    }

    protected override bool ShouldTrackEntity(Entity entity)
    {
        // For now, we don't track any entities
        return false;
    }

    protected override void OnUpdate(TimeSpan deltaTime)
    {
        // For now, nothing to update - the renderer handles the triangle directly
    }
}