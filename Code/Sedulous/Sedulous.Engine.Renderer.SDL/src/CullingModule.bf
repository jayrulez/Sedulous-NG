using Sedulous.Engine.Core.SceneGraph;
using System;
namespace Sedulous.Engine.Renderer.SDL;

class CullingModule : SceneModule
{
    public override StringView Name => "Culling";
    
    private SDLRendererSubsystem mRenderer;
    
    public this(SDLRendererSubsystem renderer)
    {
        mRenderer = renderer;
    }
    
    protected override void RegisterComponentInterests()
    {
        RegisterComponentInterest<MeshRenderer>();
        RegisterComponentInterest<Camera>();
    }
    
    public void UpdateCulling()
    {
        // Perform frustum culling on tracked entities
        for (var entity in TrackedEntities)
        {
            if (entity.HasComponent<MeshRenderer>())
            {
                // Cull against camera frustum
                PerformFrustumCulling(entity);
            }
        }
    }
    
    private void PerformFrustumCulling(Entity entity)
    {
        // Frustum culling logic
    }
}