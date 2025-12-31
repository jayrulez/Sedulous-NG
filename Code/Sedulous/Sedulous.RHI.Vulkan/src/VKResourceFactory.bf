using System;
using Bulkan;
using Sedulous.RHI;
using Sedulous.RHI.MeshShader;
using Sedulous.RHI.Raytracing;

namespace Sedulous.RHI.Vulkan;

using internal Sedulous.RHI.Vulkan;

/// <summary>
/// The Vulkan version of the Resource Factory.
/// </summary>
public class VKResourceFactory : ResourceFactory
{
	private VKGraphicsContext context;

	/// <inheritdoc />
	protected override GraphicsContext GraphicsContext => context;

	/// <summary>
	/// Initializes a new instance of the <see cref="T:Sedulous.RHI.Vulkan.VKResourceFactory" /> class.
	/// </summary>
	/// <param name="graphicsContext">The graphics context.</param>
	public this(VKGraphicsContext graphicsContext)
	{
		context = graphicsContext;
	}

	/// <inheritdoc />
	protected override Sedulous.RHI.Buffer CreateBufferInternal(void* data, in BufferDescription description)
	{
		return new VKBuffer(context, data, description);
	}

	/// <inheritdoc />
	protected override CommandQueue CreateCommandQueueInternal(CommandQueueType queueType)
	{
		uint32 queueFamily = uint32.MaxValue;
		switch (queueType)
		{
		case CommandQueueType.Graphics:
			queueFamily = context.QueueIndices.GraphicsFamily;
			break;
		case CommandQueueType.Compute:
			queueFamily = context.QueueIndices.ComputeFamily;
			break;
		case CommandQueueType.Copy:
			queueFamily = context.QueueIndices.CopyFamily;
			break;
		}
		if (queueFamily != uint32.MaxValue)
		{
			return new VKCommandQueue(context, queueType);
		}
		if (context.ValidationLayer != null)
		{
			context.ValidationLayer.Notify("Vulkan", scope $"CommandQueue of type {queueType} is not supported." , ValidationLayer.Severity.Warning);
		}
		return null;
	}

	/// <inheritdoc />
	protected override ComputePipelineState CreateComputePipelineInternal(in ComputePipelineDescription description)
	{
		return new VKComputePipelineState(context, description);
	}

	/// <inheritdoc />
	protected override RaytracingPipelineState CreateRaytracingPipelineInternal(in RaytracingPipelineDescription description)
	{
		return new VKRaytracingPipelineState(context, description);
	}

	/// <inheritdoc />
	protected override MeshShaderPipelineState CreateMeshShaderPipelineInternal(in MeshShaderPipelineDescription description)
	{
		return new VKMeshShaderPipelineState(context, description);
	}

	/// <inheritdoc />
	protected override FrameBuffer CreateFrameBufferInternal(FrameBufferAttachment? depthTarget, FrameBufferAttachmentList colorTargets, bool disposeAttachments)
	{
		return new VKFrameBuffer(context, depthTarget, colorTargets, disposeAttachments);
	}

	/// <inheritdoc />
	protected override GraphicsPipelineState CreateGraphicsPipelineInternal(in GraphicsPipelineDescription description)
	{
		return new VKGraphicsPipelineState(context, description);
	}

	/// <inheritdoc />
	protected override ResourceLayout CreateResourceLayoutInternal(in ResourceLayoutDescription description)
	{
		return new VKResourceLayout(context, description);
	}

	/// <inheritdoc />
	protected override ResourceSet CreateResourceSetInternal(in ResourceSetDescription description)
	{
		return new VKResourceSet(context, description);
	}

	/// <inheritdoc />
	protected override SamplerState CreateSamplerStateInternal(in SamplerStateDescription description)
	{
		return new VKSamplerState(context, description);
	}

	/// <inheritdoc />
	protected override Shader CreateShaderInternal(in ShaderDescription description)
	{
		return new VKShader(context, description);
	}

	/// <inheritdoc />
	protected override Texture CreateTextureInternal(DataBox[] data, in TextureDescription description, in SamplerStateDescription samplerState)
	{
		return new VKTexture(context, data, description, samplerState);
	}

	/// <inheritdoc />
	protected override Texture GetTextureFromNativePointerInternal(void* texturePointer, in TextureDescription textureDescription)
	{
		return VKTexture.FromVulkanImage(image: new VkImage((uint64)(int)texturePointer), context: context, description: textureDescription);
	}

	/// <inheritdoc />
	public override QueryHeap CreateQueryHeap(in QueryHeapDescription description)
	{
		return new VKQueryHeap(context, description);
	}	
	
	public override void DestroyCommandQueue(ref CommandQueue commandQueue)
	{
		if(let impl = commandQueue as VKCommandQueue)
		{
			impl.Dispose();
			delete impl;
			commandQueue = null;
		}
	}

	public override void DestroyGraphicsPipeline(ref GraphicsPipelineState pipeline)
	{
		if(let impl = pipeline as VKGraphicsPipelineState)
		{
			impl.Dispose();
			delete impl;
			pipeline = null;
		}
	}

	public override void DestroyComputePipeline(ref ComputePipelineState pipeline)
	{
		if(let impl = pipeline as VKComputePipelineState)
		{
			impl.Dispose();
			delete impl;
			pipeline = null;
		}
	}

	public override void DestroyRaytracingPipeline(ref RaytracingPipelineState pipeline)
	{
		if(let impl = pipeline as VKRaytracingPipelineState)
		{
			impl.Dispose();
			delete impl;
			pipeline = null;
		}
	}

	public override void DestroyMeshShaderPipeline(ref MeshShaderPipelineState pipeline)
	{
		if(let impl = pipeline as VKMeshShaderPipelineState)
		{
			impl.Dispose();
			delete impl;
			pipeline = null;
		}
	}

	public override void DestroyTexture(ref Texture texture)
	{
		if(let impl = texture as VKTexture)
		{
			impl.Dispose();
			delete impl;
			texture = null;
		}
	}

	public override void DestroyBuffer(ref Buffer buffer)
	{
		if(let impl = buffer as VKBuffer)
		{
			impl.Dispose();
			delete impl;
			buffer = null;
		}
	}

	public override void DestroyQueryHeap(ref QueryHeap queryHeap)
	{
		if(let impl = queryHeap as VKQueryHeap)
		{
			impl.Dispose();
			delete impl;
			queryHeap = null;
		}
	}

	public override void DestroyShader(ref Shader shader)
	{
		if(let impl = shader as VKShader)
		{
			impl.Dispose();
			delete impl;
			shader = null;
		}
	}

	public override void DestroySampler(ref SamplerState sampler)
	{
		if(let impl = sampler as VKSamplerState)
		{
			impl.Dispose();
			delete impl;
			sampler = null;
		}
	}

	public override void DestroyFrameBuffer(ref FrameBuffer frameBuffer)
	{
		if(let impl = frameBuffer as VKFrameBuffer)
		{
			impl.Dispose();
			delete impl;
			frameBuffer = null;
		}
		if(let impl = frameBuffer as VKSwapChainFrameBuffer)
		{
			impl.Dispose();
			delete impl;
			frameBuffer = null;
		}
	}

	public override void DestroyResourceLayout(ref ResourceLayout resourceLayout)
	{
		if(let impl = resourceLayout as VKResourceLayout)
		{
			impl.Dispose();
			delete impl;
			resourceLayout = null;
		}
	}

	public override void DestroyResourceSet(ref ResourceSet resourceSet)
	{
		if(let impl = resourceSet as VKResourceSet)
		{
			impl.Dispose();
			delete impl;
			resourceSet = null;
		}
	}
}
