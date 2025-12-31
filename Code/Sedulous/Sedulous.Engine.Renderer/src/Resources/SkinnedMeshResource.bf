using Sedulous.Resources;
using System;
using Sedulous.Geometry;

namespace Sedulous.Engine.Renderer;

class SkinnedMeshResource : Resource
{
	private SkinnedMesh mMesh;
	private bool mOwnsMesh = false;

	public SkinnedMesh Mesh => mMesh;

	public this(SkinnedMesh mesh, bool ownsMesh = false)
	{
		Id = Guid.Create();
		mMesh = mesh;
		mOwnsMesh = ownsMesh;
	}

	public ~this()
	{
		if (mOwnsMesh && mMesh != null)
		{
			delete mMesh;
		}
	}
}
