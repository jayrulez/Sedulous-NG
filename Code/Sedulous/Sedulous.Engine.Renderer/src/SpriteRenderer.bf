using Sedulous.Engine.Core.SceneGraph;
using Sedulous.Engine.Core.Resources;
using Sedulous.Foundation.Mathematics;
namespace Sedulous.Engine.Renderer;

class SpriteRenderer : Component
{
    private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<SpriteRenderer>();
    public override ComponentTypeId TypeId => sTypeId;
    
    public ResourceHandle<Texture> Texture { get; set; }
    public Color Color { get; set; } = .White;
}