using Sedulous.SceneGraph;
using Sedulous.Mathematics;
namespace Sedulous.Engine.Renderer.SDL;

struct MeshRenderCommand
{
	public Entity Entity;
	public Matrix WorldMatrix;
	public MeshRenderer Renderer;
	public float DistanceToCamera;
}