using System;
using Sedulous.Geometry;
using Sedulous.Engine.Renderer.GPU;
using Sedulous.RHI;
namespace Sedulous.Engine.Renderer.RHI;

class GPUMesh : GPUResource
{
	public Buffer VertexBuffer;
	public Buffer IndexBuffer;
	public uint32 IndexCount;
	public uint32 VertexCount;

	private GraphicsContext mGraphicsContext;

	public this(StringView name, GraphicsContext context, Mesh mesh)
		: base(name)
	{
		mGraphicsContext = context;
		CreateBuffers(mesh);
	}

	public ~this()
	{
		if (IndexBuffer != null)
			mGraphicsContext.Factory.DestroyBuffer(ref IndexBuffer);
		mGraphicsContext.Factory.DestroyBuffer(ref VertexBuffer);
	}

	private void CreateBuffers(Mesh mesh)
	{
		// Create vertex buffer
		var vertexBufferDesc = BufferDescription((uint32)(mesh.Vertices.VertexCount * mesh.Vertices.VertexSize), .VertexBuffer, .Immutable);

		VertexBuffer = mGraphicsContext.Factory.CreateBuffer(mesh.Vertices.GetRawData(), vertexBufferDesc);
		VertexCount = (uint32)mesh.Vertices.VertexCount;

		// Create index buffer (only if there are indices)
		if (mesh.Indices.IndexCount > 0)
		{
			var indexBufferDesc = BufferDescription((uint32)(mesh.Indices.IndexCount * mesh.Indices.GetIndexSize()), .IndexBuffer, .Immutable);
			IndexBuffer = mGraphicsContext.Factory.CreateBuffer(mesh.Indices.GetRawData(), indexBufferDesc);
			IndexCount = (uint32)mesh.Indices.IndexCount;
		}
		else
		{
			IndexBuffer = null;
			IndexCount = 0;
		}
	}
}