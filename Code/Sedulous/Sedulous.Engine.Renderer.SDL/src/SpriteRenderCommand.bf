using Sedulous.SceneGraph;
namespace Sedulous.Engine.Renderer.SDL;

struct SpriteRenderCommand
{
	public Entity Entity;
	public SpriteRenderer Renderer;
	public Transform Transform;
	public float DistanceToCamera;
	public int32 SortKey; // Combines layer and order
}