using Sedulous.Engine.Core.SceneGraph;
using System;
using System.Collections;
namespace Sedulous.Engine.Renderer.SDL;

class LightingModule : SceneModule
{
    public override StringView Name => "Lighting";
    
    private SDLRendererSubsystem mRenderer;
    private List<Entity> mLights = new .() ~ delete _;
    
    public this(SDLRendererSubsystem renderer)
    {
        mRenderer = renderer;
    }
    
    protected override void RegisterComponentInterests()
    {
        RegisterComponentInterest<Light>();
    }
    
    protected override bool ShouldTrackEntity(Entity entity)
    {
        return entity.HasComponent<Light>();
    }
    
    protected override void OnEntityAddedToTracking(Entity entity)
    {
        mLights.Add(entity);
    }
    
    protected override void OnEntityRemovedFromTracking(Entity entity)
    {
        mLights.Remove(entity);
    }
    
    public void UpdateLighting()
    {
        // Update light data for rendering
        for (var lightEntity in mLights)
        {
            UpdateLightData(lightEntity);
        }
    }
    
    private void UpdateLightData(Entity lightEntity)
    {
        // Update light uniforms, shadow maps, etc.
    }
}