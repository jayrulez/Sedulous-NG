using System;
using Sedulous.Mathematics;
using Sedulous.Engine.Renderer.GPU;
using Sedulous.RHI;

namespace Sedulous.Engine.Renderer.RHI;

/// GPU resource for bone matrices used in skeletal animation
class GPUSkeleton : GPUResource
{
	public Buffer BoneMatrixBuffer;
	public int32 BoneCount;

	private GraphicsContext mGraphicsContext;

	public this(StringView name, GraphicsContext context, int32 boneCount)
		: base(name)
	{
		mGraphicsContext = context;
		BoneCount = boneCount;
		CreateBuffer();
	}

	public ~this()
	{
		if (BoneMatrixBuffer != null)
			mGraphicsContext.Factory.DestroyBuffer(ref BoneMatrixBuffer);
	}

	private void CreateBuffer()
	{
		// Create bone matrix buffer (MAX_BONES * 64 bytes for 4x4 matrix)
		// Initialize with identity matrices so descriptor set is valid immediately
		var initialData = scope Matrix[MAX_BONES];
		for (int i = 0; i < MAX_BONES; i++)
			initialData[i] = .Identity;

		var bufferDesc = BufferDescription((uint32)(MAX_BONES * sizeof(Matrix)), .ConstantBuffer, .Dynamic, .Write);
		BoneMatrixBuffer = mGraphicsContext.Factory.CreateBuffer(&initialData[0], bufferDesc);
	}

	/// Update bone matrices from animator
	public void UpdateBoneMatrices(CommandBuffer cmd, Matrix* matrices, int32 count)
	{
		if (BoneMatrixBuffer == null || count <= 0)
			return;

		// Map buffer and copy matrices
		var mappedResource = mGraphicsContext.MapMemory(BoneMatrixBuffer, .Write);
		if (mappedResource.Data != null)
		{
			Internal.MemCpy(mappedResource.Data, matrices, Math.Min(count, MAX_BONES) * sizeof(Matrix));
			mGraphicsContext.UnmapMemory(BoneMatrixBuffer);
		}
	}

	/// Update bone matrices from a list
	public void UpdateBoneMatrices(CommandBuffer cmd, System.Collections.List<Matrix> matrices)
	{
		if (matrices == null || matrices.Count == 0)
			return;

		UpdateBoneMatrices(cmd, matrices.Ptr, (int32)matrices.Count);
	}
}
