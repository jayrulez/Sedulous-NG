using Sedulous.SceneGraph;
using Sedulous.Resources;
using Sedulous.Mathematics;
namespace Sedulous.Engine.Renderer;

class SpriteRenderer : Component
{
    private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<SpriteRenderer>();
    public override ComponentTypeId TypeId => sTypeId;
    
    public ResourceHandle<TextureResource> Texture { get; set; }
    public Color Color { get; set; } = .White;
}