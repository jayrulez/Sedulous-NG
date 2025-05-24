using Sedulous.Engine.Core.SceneGraph;
using System;
namespace Sedulous.Engine.Renderer.SDL;

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
        RegisterComponentInterest<MeshRenderer>();
        RegisterComponentInterest<SpriteRenderer>();
        RegisterComponentInterest<Camera>();
    }

    protected override bool ShouldTrackEntity(Entity entity)
    {
        // Track entities with any renderable component
        return entity.HasComponent<MeshRenderer>() || 
               entity.HasComponent<SpriteRenderer>() ||
               entity.HasComponent<Camera>();
    }

    protected override void OnEntityAddedToTracking(Entity entity)
    {
        // Add to appropriate render queues
        if (entity.HasComponent<Camera>())
        {
            // Set as active camera if none exists
        }
    }

    protected override void Update(TimeSpan deltaTime)
    {
        // Update render data for all tracked entities
        for (var entity in TrackedEntities)
        {
            if (entity.HasComponent<MeshRenderer>())
            {
                UpdateMeshRenderData(entity);
            }
        }
    }

    public void PrepareRenderData()
    {
        // Called from renderer subsystem
        // Prepare all render commands
    }

    private void UpdateMeshRenderData(Entity entity)
    {
        // Update matrices, culling, LOD, etc.
        entity.Transform.MarkDirty(); // Ensure matrices are updated
    }
}