using Sedulous.Engine.Core.SceneGraph;
using Sedulous.Foundation.Mathematics;
namespace Sedulous.Engine.Renderer;

class Light : Component
{
    private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<Light>();
    public override ComponentTypeId TypeId => sTypeId;
    
    public enum LightType { Directional, Point, Spot }
    
    public LightType Type { get; set; } = .Point;
    public Vector3 Color { get; set; } = Vector3.One;
    public float Intensity { get; set; } = 1.0f;
    public float Range { get; set; } = 10.0f;
    public bool CastShadows { get; set; } = true;
}