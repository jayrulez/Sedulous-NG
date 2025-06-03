using Sedulous.Resources;
using System;
using Sedulous.Geometry;
namespace Sedulous.Engine.Renderer;

class MeshResource : Resource
{
    private Mesh mMesh;
	private bool mOwnsMesh = false;

	public Mesh Mesh => mMesh;

    public this(Mesh mesh, bool ownsMesh = false)
    {
        Id = Guid.Create();
        mMesh = mesh;
		mOwnsMesh = ownsMesh;
    }

    public ~this()
    {
		if(mOwnsMesh && mMesh != null)
		{
			delete mMesh;
		}
    }
}