using Sedulous.Mathematics;
using Sedulous.SceneGraph;
namespace Sedulous.Engine.Renderer;


class Light : Component
{
    private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<Light>();
    public override ComponentTypeId TypeId => sTypeId;

    public enum LightType
    {
        Directional,
        Point,
        Spot
    }
    
    public LightType Type = .Directional;
    public Vector3 Color = .(1, 1, 1);
    public float Intensity = 1.0f;
}