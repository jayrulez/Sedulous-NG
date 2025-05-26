using Sedulous.Foundation.Mathematics;
namespace Sedulous.Engine.Renderer;

struct CameraData
{
    public Matrix ViewMatrix;
    public Matrix ProjectionMatrix;
    public Matrix ViewProjectionMatrix;
    public Vector3 Position;
    public Vector3 Forward;
}