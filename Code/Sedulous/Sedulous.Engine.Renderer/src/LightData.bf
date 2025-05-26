using Sedulous.Foundation.Mathematics;
namespace Sedulous.Engine.Renderer;

struct LightData
{
    public Vector3 Position;
    public Vector3 Direction;
    public Vector3 Color;
    public float Intensity;
    public float Range;
    public int32 Type; // 0=Directional, 1=Point, 2=Spot
}