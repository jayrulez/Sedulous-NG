using Sedulous.Mathematics;
using Sedulous.SceneGraph;
namespace Sedulous.Engine.Renderer;

// Base light component with common properties
abstract class Light : Component
{
    public Vector3 Color = Vector3(1, 1, 1);
    public float Intensity = 1.0f;
}

// Directional light - only needs direction (from transform)
class DirectionalLight : Light
{
    private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<DirectionalLight>();
    public override ComponentTypeId TypeId => sTypeId;
    
    // Could add shadow-specific properties here
    public bool CastShadows = true;
    public float ShadowBias = 0.001f;
}

// Point light - needs position (from transform) and range
class PointLight : Light
{
    private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<PointLight>();
    public override ComponentTypeId TypeId => sTypeId;
    
    public float Range = 10.0f;
    
    // Attenuation parameters
    public float ConstantAttenuation = 1.0f;
    public float LinearAttenuation = 0.09f;
    public float QuadraticAttenuation = 0.032f;
}

// Spot light - needs position, direction (from transform), range and angles
class SpotLight : Light
{
    private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<SpotLight>();
    public override ComponentTypeId TypeId => sTypeId;
    
    public float Range = 10.0f;
    public float InnerConeAngle = 25.0f; // Inner cone angle in degrees
    public float OuterConeAngle = 35.0f; // Outer cone angle in degrees
    
    // Attenuation parameters
    public float ConstantAttenuation = 1.0f;
    public float LinearAttenuation = 0.09f;
    public float QuadraticAttenuation = 0.032f;
}