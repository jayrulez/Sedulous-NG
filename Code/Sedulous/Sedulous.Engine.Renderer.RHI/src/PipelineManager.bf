using System;
using Sedulous.RHI;
using Sedulous.Mathematics;

namespace Sedulous.Engine.Renderer.RHI;

/// Manages graphics pipelines, shaders, and resource layouts.
/// Extracted from RHIRendererSubsystem to improve separation of concerns.
class PipelineManager
{
	private GraphicsContext mGraphicsContext;
	private RHIRendererSubsystem mRenderer;
	private ShaderManager mShaderManager;

	// Unlit pipeline resources
	private GraphicsPipelineState mUnlitPipeline;
	private Shader mUnlitVertexShader;
	private Shader mUnlitPixelShader;
	private ResourceLayout mUnlitPerObjectResourceLayout;
	private ResourceLayout mUnlitMaterialResourceLayout;
	private LayoutElementDescription[] mUnlitMaterialLayoutElements ~ delete _;
	private ResourceLayout[] mUnlitPipelineResourceLayouts ~ delete _;

	// Unlit pipeline buffers and resource sets
	private Buffer mUnlitVertexCB;
	private Buffer mDefaultUnlitMaterialCB;
	private ResourceSet mUnlitPerObjectResourceSet;
	private ResourceSet mDefaultUnlitMaterialResourceSet;

	// Skinned pipeline resources
	private GraphicsPipelineState mSkinnedUnlitPipeline;
	private Shader mSkinnedVertexShader;
	private Shader mSkinnedPixelShader;
	private ResourceLayout mSkinnedPerObjectResourceLayout;
	private ResourceLayout mBoneMatricesResourceLayout;
	private LayoutElementDescription[] mSkinnedPerObjectLayoutElementDescs ~ delete _;
	private LayoutElementDescription[] mSkinnedBoneMatricesLayoutElementDescs ~ delete _;
	private ResourceLayout[] mSkinnedPipelineResourceLayouts ~ delete _;

	// Public accessors
	public GraphicsPipelineState UnlitPipeline => mUnlitPipeline;
	public GraphicsPipelineState SkinnedUnlitPipeline => mSkinnedUnlitPipeline;

	public ResourceLayout UnlitPerObjectResourceLayout => mUnlitPerObjectResourceLayout;
	public ResourceLayout UnlitMaterialResourceLayout => mUnlitMaterialResourceLayout;
	public ResourceLayout SkinnedPerObjectResourceLayout => mSkinnedPerObjectResourceLayout;
	public ResourceLayout BoneMatricesResourceLayout => mBoneMatricesResourceLayout;

	public Buffer UnlitVertexCB => mUnlitVertexCB;
	public Buffer DefaultUnlitMaterialCB => mDefaultUnlitMaterialCB;
	public ResourceSet UnlitPerObjectResourceSet => mUnlitPerObjectResourceSet;
	public ResourceSet DefaultUnlitMaterialResourceSet => mDefaultUnlitMaterialResourceSet;

	public this(GraphicsContext graphicsContext, RHIRendererSubsystem renderer, ShaderManager shaderManager)
	{
		mGraphicsContext = graphicsContext;
		mRenderer = renderer;
		mShaderManager = shaderManager;
	}

	public ~this()
	{
		Destroy();
	}

	public void Initialize(FrameBuffer targetFrameBuffer)
	{
		CreateUnlitPipeline(targetFrameBuffer);
		CreateSkinnedPipeline(targetFrameBuffer);
	}

	public void Destroy()
	{
		DestroySkinnedPipeline();
		DestroyUnlitPipeline();
	}

	public ResourceLayout GetMaterialResourceLayout(StringView shaderName)
	{
		switch (shaderName)
		{
		case "Unlit": return mUnlitMaterialResourceLayout;
		default: return mUnlitMaterialResourceLayout; // Fallback
		}
	}

	private void CreateUnlitPipeline(FrameBuffer targetFrameBuffer)
	{
		// Compile shaders using ShaderManager
		mUnlitVertexShader = mShaderManager.CompileFromSource(ShaderSources.UnlitShadersVS, .Vertex, "VS");
		mUnlitPixelShader = mShaderManager.CompileFromSource(ShaderSources.UnlitShadersPS, .Pixel, "PS");

		// Create per-object constant buffer
		{
			const int32 MAX_OBJECTS = 1000;
			const int32 ALIGNMENT = 256;
			int32 alignedSize = ((sizeof(UnlitVertexUniforms) + ALIGNMENT - 1) / ALIGNMENT) * ALIGNMENT;

			var perObjectCBDesc = BufferDescription(
				(uint32)(alignedSize * MAX_OBJECTS),
				.ConstantBuffer,
				.Dynamic,
				.Write
			);
			mUnlitVertexCB = mGraphicsContext.Factory.CreateBuffer(perObjectCBDesc);
		}

		// Create default material buffer
		{
			var defaultMaterialData = scope UnlitFragmentUniforms()
			{
				MaterialTint = Color.White.ToVector4(),
				MaterialProperties = Vector4(1, 1, 1, 0)
			};

			var defaultMaterialBufferDesc = BufferDescription(
				sizeof(UnlitVertexUniforms),
				.ConstantBuffer,
				.Dynamic
			);
			mDefaultUnlitMaterialCB = mGraphicsContext.Factory.CreateBuffer(defaultMaterialData, defaultMaterialBufferDesc);
		}

		// Vertex format
		var vertexFormat = scope LayoutDescription()
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Position))
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Normal))
			.Add(ElementDescription(ElementFormat.Float2, ElementSemanticType.TexCoord))
			.Add(ElementDescription(ElementFormat.UByte4Normalized, ElementSemanticType.Color))
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Tangent));
		var vertexLayouts = scope InputLayouts();
		vertexLayouts.Add(vertexFormat);

		// Unlit Per Object ResourceLayout
		{
			LayoutElementDescription[] layoutElementDescs = scope:: LayoutElementDescription[](
				LayoutElementDescription(0, .ConstantBuffer, .Vertex, true, sizeof(UnlitVertexUniforms))
			);
			ResourceLayoutDescription resourceLayoutDesc = ResourceLayoutDescription(params layoutElementDescs);
			mUnlitPerObjectResourceLayout = mGraphicsContext.Factory.CreateResourceLayout(resourceLayoutDesc);
		}

		// Unlit Material ResourceLayout
		{
			mUnlitMaterialLayoutElements = new LayoutElementDescription[](
				LayoutElementDescription(0, .ConstantBuffer, .Pixel, false, sizeof(UnlitFragmentUniforms)),
				LayoutElementDescription(0, .Texture, .Pixel),
				LayoutElementDescription(0, .Sampler, .Pixel)
			);
			ResourceLayoutDescription resourceLayoutDesc = ResourceLayoutDescription(params mUnlitMaterialLayoutElements);
			mUnlitMaterialResourceLayout = mGraphicsContext.Factory.CreateResourceLayout(resourceLayoutDesc);
		}

		// Create pipeline
		var meshPipelineDescription = GraphicsPipelineDescription
		{
			RenderStates = RenderStateDescription.Default,
			Shaders = .()
			{
				VertexShader = mUnlitVertexShader,
				PixelShader = mUnlitPixelShader
			},
			InputLayouts = vertexLayouts,
			ResourceLayouts = mUnlitPipelineResourceLayouts = new ResourceLayout[](mUnlitPerObjectResourceLayout, mUnlitMaterialResourceLayout),
			PrimitiveTopology = .TriangleList,
			Outputs = .CreateFromFrameBuffer(targetFrameBuffer)
		};

		mUnlitPipeline = mGraphicsContext.Factory.CreateGraphicsPipeline(meshPipelineDescription);

		// Per object resource set
		{
			ResourceSetDescription resourceSetDesc = .(mUnlitPerObjectResourceLayout, mUnlitVertexCB);
			mUnlitPerObjectResourceSet = mGraphicsContext.Factory.CreateResourceSet(resourceSetDesc);
		}

		// Default material resource set
		{
			var defaultWhiteTexture = mRenderer.GetDefaultWhiteTexture();
			ResourceSetDescription resourceSetDesc = .(mUnlitMaterialResourceLayout, mDefaultUnlitMaterialCB, defaultWhiteTexture.Resource.Texture, mGraphicsContext.DefaultSampler);
			mDefaultUnlitMaterialResourceSet = mGraphicsContext.Factory.CreateResourceSet(resourceSetDesc);
		}
	}

	private void DestroyUnlitPipeline()
	{
		if (mDefaultUnlitMaterialResourceSet != null)
			mGraphicsContext.Factory.DestroyResourceSet(ref mDefaultUnlitMaterialResourceSet);
		if (mUnlitPerObjectResourceSet != null)
			mGraphicsContext.Factory.DestroyResourceSet(ref mUnlitPerObjectResourceSet);
		if (mUnlitMaterialResourceLayout != null)
			mGraphicsContext.Factory.DestroyResourceLayout(ref mUnlitMaterialResourceLayout);
		if (mUnlitPerObjectResourceLayout != null)
			mGraphicsContext.Factory.DestroyResourceLayout(ref mUnlitPerObjectResourceLayout);
		if (mUnlitPipeline != null)
			mGraphicsContext.Factory.DestroyGraphicsPipeline(ref mUnlitPipeline);

		if (mDefaultUnlitMaterialCB != null)
			mGraphicsContext.Factory.DestroyBuffer(ref mDefaultUnlitMaterialCB);
		if (mUnlitVertexCB != null)
			mGraphicsContext.Factory.DestroyBuffer(ref mUnlitVertexCB);

		if (mUnlitPixelShader != null)
			mGraphicsContext.Factory.DestroyShader(ref mUnlitPixelShader);
		if (mUnlitVertexShader != null)
			mGraphicsContext.Factory.DestroyShader(ref mUnlitVertexShader);
	}

	private void CreateSkinnedPipeline(FrameBuffer targetFrameBuffer)
	{
		// Compile skinned shaders using ShaderManager (dedicated instances to avoid lifetime issues)
		mSkinnedVertexShader = mShaderManager.CompileFromSource(ShaderSources.SkinnedUnlitShadersVS, .Vertex, "VS");
		mSkinnedPixelShader = mShaderManager.CompileFromSource(ShaderSources.UnlitShadersPS, .Pixel, "PS");

		// Skinned vertex format (72 bytes)
		var skinnedVertexFormat = scope LayoutDescription()
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Position))       // 12 bytes
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Normal))         // 12 bytes
			.Add(ElementDescription(ElementFormat.Float2, ElementSemanticType.TexCoord))       // 8 bytes
			.Add(ElementDescription(ElementFormat.UByte4Normalized, ElementSemanticType.Color))// 4 bytes
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Tangent))        // 12 bytes
			.Add(ElementDescription(ElementFormat.UShort4, ElementSemanticType.BlendIndices))  // 8 bytes
			.Add(ElementDescription(ElementFormat.Float4, ElementSemanticType.BlendWeight));   // 16 bytes

		var skinnedVertexLayouts = scope InputLayouts();
		skinnedVertexLayouts.Add(skinnedVertexFormat);

		// Skinned Per Object ResourceLayout
		{
			mSkinnedPerObjectLayoutElementDescs = new LayoutElementDescription[](
				LayoutElementDescription(0, .ConstantBuffer, .Vertex, true, sizeof(UnlitVertexUniforms))
			);
			ResourceLayoutDescription resourceLayoutDesc = ResourceLayoutDescription(params mSkinnedPerObjectLayoutElementDescs);
			mSkinnedPerObjectResourceLayout = mGraphicsContext.Factory.CreateResourceLayout(resourceLayoutDesc);
		}

		// Bone Matrices ResourceLayout (binding 0 in space2, maps to Set 2 in Vulkan)
		{
			mSkinnedBoneMatricesLayoutElementDescs = new LayoutElementDescription[](
				LayoutElementDescription(0, .ConstantBuffer, .Vertex, false, sizeof(BoneMatricesUniforms))
			);
			ResourceLayoutDescription resourceLayoutDesc = ResourceLayoutDescription(params mSkinnedBoneMatricesLayoutElementDescs);
			mBoneMatricesResourceLayout = mGraphicsContext.Factory.CreateResourceLayout(resourceLayoutDesc);
		}

		// Create skinned pipeline
		var skinnedPipelineDescription = GraphicsPipelineDescription
		{
			RenderStates = RenderStateDescription.Default,
			Shaders = .()
			{
				VertexShader = mSkinnedVertexShader,
				PixelShader = mSkinnedPixelShader
			},
			InputLayouts = skinnedVertexLayouts,
			ResourceLayouts = mSkinnedPipelineResourceLayouts = new ResourceLayout[](mSkinnedPerObjectResourceLayout, mUnlitMaterialResourceLayout, mBoneMatricesResourceLayout),
			PrimitiveTopology = .TriangleList,
			Outputs = .CreateFromFrameBuffer(targetFrameBuffer)
		};

		mSkinnedUnlitPipeline = mGraphicsContext.Factory.CreateGraphicsPipeline(skinnedPipelineDescription);
	}

	private void DestroySkinnedPipeline()
	{
		if (mSkinnedUnlitPipeline != null)
			mGraphicsContext.Factory.DestroyGraphicsPipeline(ref mSkinnedUnlitPipeline);
		if (mBoneMatricesResourceLayout != null)
			mGraphicsContext.Factory.DestroyResourceLayout(ref mBoneMatricesResourceLayout);
		if (mSkinnedPerObjectResourceLayout != null)
			mGraphicsContext.Factory.DestroyResourceLayout(ref mSkinnedPerObjectResourceLayout);
		if (mSkinnedPixelShader != null)
			mGraphicsContext.Factory.DestroyShader(ref mSkinnedPixelShader);
		if (mSkinnedVertexShader != null)
			mGraphicsContext.Factory.DestroyShader(ref mSkinnedVertexShader);
	}
}
