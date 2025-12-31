using Sedulous.Mathematics;
using Sedulous.SceneGraph;
using Sedulous.Resources;

namespace Sedulous.Engine.Renderer;

/// Component for rendering skinned meshes with skeletal animation
class SkinnedMeshRenderer : Component
{
	public ResourceHandle<SkinnedMeshResource> Mesh { get; set; } ~ _.Release();
	public ResourceHandle<MaterialResource> Material { get; set; } ~ _.Release();
	public ResourceHandle<SkinResource> Skin { get; set; } ~ _.Release();

	// Fallback color if no material is set
	public Color Color = .White;
}
