using Sedulous.Resources;
using Sedulous.Foundation.Mathematics;
using System;
using Sedulous.Geometry;
namespace Sedulous.Engine.Renderer;

class MeshResource : Resource
{
    private Mesh mMesh;

	public Mesh Mesh => mMesh;

    public this(Mesh mesh)
    {
        Id = Guid.Create();
        mMesh = mesh;
    }

    public ~this()
    {
    }
}