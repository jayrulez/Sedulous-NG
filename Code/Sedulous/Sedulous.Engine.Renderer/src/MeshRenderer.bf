using Sedulous.Foundation.Mathematics;
using Sedulous.SceneGraph;
using Sedulous.Resources;
namespace Sedulous.Engine.Renderer;

class MeshRenderer : Component
{
    private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<MeshRenderer>();
    public override ComponentTypeId TypeId => sTypeId;
	
	public ResourceHandle<MeshResource> Mesh { get; set; } ~ _.Release();
	public ResourceHandle<MaterialResource> Material { get; set; }

    public bool UseLighting = true;
    public Vector4 Color = .(1, 1, 1, 1);
}