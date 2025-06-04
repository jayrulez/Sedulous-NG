using SDL3Native;
using System;
using Sedulous.Geometry;
namespace Sedulous.Engine.Renderer.SDL;

class GPUMesh : GPUResource
{
	public SDL_GPUBuffer* VertexBuffer;
	public SDL_GPUBuffer* IndexBuffer;
	public uint32 IndexCount;
	public uint32 VertexCount;

	private SDL_GPUDevice* mDevice;

	public this(SDL_GPUDevice* device, Mesh mesh)
	{
		mDevice = device;
		CreateBuffers(mDevice, mesh);
	}

	public ~this()
	{
		SDL_ReleaseGPUBuffer(mDevice, IndexBuffer);
		SDL_ReleaseGPUBuffer(mDevice, VertexBuffer);
	}

	private void CreateBuffers(SDL_GPUDevice* device, Mesh mesh)
	{
		// Create vertex buffer
		var vertexBufferDesc = SDL_GPUBufferCreateInfo()
			{
				usage = .SDL_GPU_BUFFERUSAGE_VERTEX,
				size = (uint32)(mesh.Vertices.VertexCount * mesh.Vertices.VertexSize)
			};

		VertexBuffer = SDL_CreateGPUBuffer(device, &vertexBufferDesc);
		VertexCount = (uint32)mesh.Vertices.VertexCount;

		// Create transfer buffer for vertex data
		var vertexTransferBuffer = SDL_CreateGPUTransferBuffer(device, scope .() { usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD, size = vertexBufferDesc.size });
		var vertexTransfer = SDL_MapGPUTransferBuffer(device, vertexTransferBuffer, false);
		if (vertexTransfer != null)
		{
			Internal.MemCpy(vertexTransfer, mesh.Vertices.GetRawData(), vertexBufferDesc.size);
			SDL_UnmapGPUTransferBuffer(device, vertexTransferBuffer);
		}

		// Create index buffer
		var indexBufferDesc = SDL_GPUBufferCreateInfo()
			{
				usage = .SDL_GPU_BUFFERUSAGE_INDEX,
				size = (uint32)(mesh.Indices.IndexCount * mesh.Indices.GetIndexSize())
			};

		IndexBuffer = SDL_CreateGPUBuffer(device, &indexBufferDesc);
		IndexCount = (uint32)mesh.Indices.IndexCount;

		// Create transfer buffer for index data
		var indexTransferBuffer = SDL_CreateGPUTransferBuffer(device, scope .() { usage = .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD, size = indexBufferDesc.size });
		var indexTransfer = SDL_MapGPUTransferBuffer(device, indexTransferBuffer, false);
		if (indexTransfer != null)
		{
			Internal.MemCpy(indexTransfer, mesh.Indices.GetRawData(), indexBufferDesc.size);
			SDL_UnmapGPUTransferBuffer(device, indexTransferBuffer);
		}

		// Copy data from transfer buffers to GPU buffers
		var commandBuffer = SDL_AcquireGPUCommandBuffer(device);
		var copyPass = SDL_BeginGPUCopyPass(commandBuffer);

		// Copy vertex data
		SDL_UploadToGPUBuffer(copyPass, scope SDL_GPUTransferBufferLocation()
			{
				transfer_buffer = vertexTransferBuffer,
				offset = 0
			}, scope SDL_GPUBufferRegion()
			{
				buffer = VertexBuffer,
				offset = 0, size = vertexBufferDesc.size
			}, false);

		// Copy index data
		SDL_UploadToGPUBuffer(copyPass, scope SDL_GPUTransferBufferLocation()
			{
				transfer_buffer = indexTransferBuffer,
				offset = 0
			}, scope SDL_GPUBufferRegion()
			{
				buffer = IndexBuffer,
				offset = 0,
				size = indexBufferDesc.size
			}, false);

		SDL_EndGPUCopyPass(copyPass);
		SDL_SubmitGPUCommandBuffer(commandBuffer);

		// Clean up transfer buffers
		SDL_ReleaseGPUTransferBuffer(device, vertexTransferBuffer);
		SDL_ReleaseGPUTransferBuffer(device, indexTransferBuffer);
	}
}