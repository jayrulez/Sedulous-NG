using Sedulous.Resources;
using Sedulous.Foundation.Mathematics;
using System;
using Sedulous.Geometry;
using Sedulous.Foundation.Utilities;
namespace Sedulous.Engine.Renderer;

class MeshResource : Resource
{
    private Mesh mMesh;
	private bool mOwnsMesh = false;

	public Mesh Mesh => mMesh;

    public this(Mesh mesh, bool ownsMesh = false)
    {
        Id = GUID.Create();
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