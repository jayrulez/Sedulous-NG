using System;
using Sedulous.Geometry;
using Sedulous.Engine.Renderer.GPU;
using Sedulous.RHI;

namespace Sedulous.Engine.Renderer.RHI;

class GPUSkinnedMesh : GPUResource
{
	public Buffer VertexBuffer;
	public Buffer IndexBuffer;
	public uint32 IndexCount;
	public uint32 VertexCount;

	private GraphicsContext mGraphicsContext;

	public this(StringView name, GraphicsContext context, SkinnedMesh mesh)
		: base(name)
	{
		mGraphicsContext = context;
		CreateBuffers(mesh);
	}

	public ~this()
	{
		if (IndexBuffer != null)
			mGraphicsContext.Factory.DestroyBuffer(ref IndexBuffer);
		if (VertexBuffer != null)
			mGraphicsContext.Factory.DestroyBuffer(ref VertexBuffer);
	}

	private void CreateBuffers(SkinnedMesh mesh)
	{
		// Create vertex buffer (72 bytes per skinned vertex)
		var vertexBufferDesc = BufferDescription((uint32)(mesh.VertexCount * mesh.VertexSize), .VertexBuffer, .Immutable);
		VertexBuffer = mGraphicsContext.Factory.CreateBuffer(mesh.GetVertexData(), vertexBufferDesc);
		VertexCount = (uint32)mesh.VertexCount;

		// Create index buffer (only if there are indices)
		if (mesh.IndexCount > 0)
		{
			var indexBufferDesc = BufferDescription((uint32)(mesh.IndexCount * mesh.Indices.GetIndexSize()), .IndexBuffer, .Immutable);
			IndexBuffer = mGraphicsContext.Factory.CreateBuffer(mesh.GetIndexData(), indexBufferDesc);
			IndexCount = (uint32)mesh.IndexCount;
		}
		else
		{
			IndexBuffer = null;
			IndexCount = 0;
		}
	}
}
