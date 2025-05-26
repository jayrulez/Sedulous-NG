using Sedulous.Foundation.Mathematics;
using Sedulous.Engine.Core.SceneGraph;
namespace Sedulous.Engine.Renderer;

struct RenderCommand
{
    public Entity Entity;
    public Mesh Mesh;
    public Material Material;
    public Matrix WorldMatrix;
    public float DistanceToCamera;
    public bool IsTransparent;
}