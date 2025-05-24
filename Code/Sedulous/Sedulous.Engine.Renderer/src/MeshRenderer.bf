using Sedulous.Engine.Core.SceneGraph;
using Sedulous.Engine.Core.Resources;
namespace Sedulous.Engine.Renderer;

class MeshRenderer : Component
{
    private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<MeshRenderer>();
    public override ComponentTypeId TypeId => sTypeId;
    
    public ResourceHandle<Mesh> Mesh { get; set; }
    public ResourceHandle<Material> Material { get; set; }
    public bool CastShadows { get; set; } = true;
    public bool ReceiveShadows { get; set; } = true;
}