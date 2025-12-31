using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Mathematics;
using Sedulous.Engine.Renderer.GPU;

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
	private LayoutElementDescription[] mUnlitPerObjectLayoutElements ~ delete _;
	private ResourceLayout mUnlitMaterialResourceLayout;
	private LayoutElementDescription[] mUnlitMaterialLayoutElements ~ delete _;
	private ResourceLayout[] mUnlitPipelineResourceLayouts ~ delete _;

	// Unlit pipeline buffers and resource sets
	private Buffer mUnlitVertexCB;
	private Buffer mDefaultUnlitMaterialCB;
	private ResourceSet mUnlitPerObjectResourceSet;
	private ResourceSet mDefaultUnlitMaterialResourceSet;

	// Skinned Unlit pipeline resources
	private GraphicsPipelineState mSkinnedUnlitPipeline;
	private Shader mSkinnedVertexShader;
	private Shader mSkinnedPixelShader;
	private ResourceLayout mSkinnedPerObjectResourceLayout;
	private ResourceLayout mBoneMatricesResourceLayout;
	private LayoutElementDescription[] mSkinnedPerObjectLayoutElementDescs ~ delete _;
	private LayoutElementDescription[] mSkinnedBoneMatricesLayoutElementDescs ~ delete _;
	private ResourceLayout[] mSkinnedPipelineResourceLayouts ~ delete _;

	// Skinned Phong pipeline resources
	private GraphicsPipelineState mSkinnedPhongPipeline;
	private Shader mSkinnedPhongVertexShader;
	private Shader mSkinnedPhongPixelShader;
	private ResourceLayout[] mSkinnedPhongPipelineResourceLayouts ~ delete _;

	// Phong pipeline resources
	private GraphicsPipelineState mPhongPipeline;
	private Shader mPhongVertexShader;
	private Shader mPhongPixelShader;
	private ResourceLayout mPhongMaterialResourceLayout;
	private LayoutElementDescription[] mPhongMaterialLayoutElements ~ delete _;
	private ResourceLayout[] mPhongPipelineResourceLayouts ~ delete _;

	// PBR pipeline resources
	private GraphicsPipelineState mPBRPipeline;
	private Shader mPBRVertexShader;
	private Shader mPBRPixelShader;
	private ResourceLayout mPBRMaterialResourceLayout;
	private LayoutElementDescription[] mPBRMaterialLayoutElements ~ delete _;
	private ResourceLayout[] mPBRPipelineResourceLayouts ~ delete _;

	// Skinned PBR pipeline resources
	private GraphicsPipelineState mSkinnedPBRPipeline;
	private Shader mSkinnedPBRVertexShader;
	private Shader mSkinnedPBRPixelShader;
	private ResourceLayout[] mSkinnedPBRPipelineResourceLayouts ~ delete _;

	// Lighting resources (shared by all lit pipelines)
	private ResourceLayout mLightingResourceLayout;
	private LayoutElementDescription[] mLightingLayoutElements ~ delete _;
	private Buffer mLightingBuffer;
	private ResourceSet mLightingResourceSet;

	// Debug line pipeline resources
	private GraphicsPipelineState mDebugLinePipeline;
	private Shader mDebugLineVertexShader;
	private Shader mDebugLinePixelShader;
	private ResourceLayout mDebugResourceLayout;
	private LayoutElementDescription[] mDebugLayoutElements ~ delete _;
	private ResourceLayout[] mDebugPipelineResourceLayouts ~ delete _;

	// Depth-only pipeline resources (for depth prepass)
	private GraphicsPipelineState mDepthOnlyPipeline;
	private GraphicsPipelineState mSkinnedDepthOnlyPipeline;
	private Shader mDepthOnlyVertexShader;
	private Shader mSkinnedDepthOnlyVertexShader;
	private ResourceLayout[] mDepthOnlyPipelineResourceLayouts ~ delete _;
	private ResourceLayout[] mSkinnedDepthOnlyPipelineResourceLayouts ~ delete _;

	// Hi-Z occlusion culling resources
	private Shader mHiZDownsampleShader;
	private ComputePipelineState mHiZDownsamplePipeline;
	private ResourceLayout mHiZResourceLayout;
	private LayoutElementDescription[] mHiZLayoutElements ~ delete _;
	private Buffer mHiZParamsBuffer;

	// Material pipeline registry
	private MaterialPipelineRegistry mMaterialRegistry = new .() ~ delete _;

	// Public accessors
	public GraphicsPipelineState UnlitPipeline => mUnlitPipeline;
	public GraphicsPipelineState SkinnedUnlitPipeline => mSkinnedUnlitPipeline;
	public GraphicsPipelineState SkinnedPhongPipeline => mSkinnedPhongPipeline;
	public GraphicsPipelineState PhongPipeline => mPhongPipeline;
	public GraphicsPipelineState PBRPipeline => mPBRPipeline;
	public GraphicsPipelineState SkinnedPBRPipeline => mSkinnedPBRPipeline;
	public GraphicsPipelineState DebugLinePipeline => mDebugLinePipeline;
	public GraphicsPipelineState DepthOnlyPipeline => mDepthOnlyPipeline;
	public GraphicsPipelineState SkinnedDepthOnlyPipeline => mSkinnedDepthOnlyPipeline;
	public ResourceLayout DebugResourceLayout => mDebugResourceLayout;
	public MaterialPipelineRegistry MaterialRegistry => mMaterialRegistry;
	public ComputePipelineState HiZDownsamplePipeline => mHiZDownsamplePipeline;
	public ResourceLayout HiZResourceLayout => mHiZResourceLayout;
	public Buffer HiZParamsBuffer => mHiZParamsBuffer;

	public ResourceLayout UnlitPerObjectResourceLayout => mUnlitPerObjectResourceLayout;
	public ResourceLayout UnlitMaterialResourceLayout => mUnlitMaterialResourceLayout;
	public ResourceLayout SkinnedPerObjectResourceLayout => mSkinnedPerObjectResourceLayout;
	public ResourceLayout BoneMatricesResourceLayout => mBoneMatricesResourceLayout;
	public ResourceLayout LightingResourceLayout => mLightingResourceLayout;

	public Buffer UnlitVertexCB => mUnlitVertexCB;
	public Buffer LightingBuffer => mLightingBuffer;
	public ResourceSet LightingResourceSet => mLightingResourceSet;
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
		CreateLightingResources();
		CreateUnlitPipeline(targetFrameBuffer);
		CreatePhongPipeline(targetFrameBuffer);
		CreatePBRPipeline(targetFrameBuffer);
		CreateSkinnedPipeline(targetFrameBuffer);
		CreateSkinnedPhongPipeline(targetFrameBuffer);
		CreateSkinnedPBRPipeline(targetFrameBuffer);
		CreateDebugLinePipeline(targetFrameBuffer);
		CreateDepthOnlyPipelines(targetFrameBuffer);
		CreateHiZPipeline();
	}

	public void Destroy()
	{
		DestroyHiZPipeline();
		DestroyDepthOnlyPipelines();
		DestroyDebugLinePipeline();
		DestroySkinnedPBRPipeline();
		DestroySkinnedPhongPipeline();
		DestroySkinnedPipeline();
		DestroyPBRPipeline();
		DestroyPhongPipeline();
		DestroyUnlitPipeline();
		DestroyLightingResources();
	}

	public ResourceLayout GetMaterialResourceLayout(StringView shaderName)
	{
		return mMaterialRegistry.GetMaterialResourceLayout(shaderName);
	}

	private void CreateLightingResources()
	{
		// Create lighting resource layout
		mLightingLayoutElements = new LayoutElementDescription[](
			LayoutElementDescription(0, .ConstantBuffer, .Pixel, false, sizeof(LightingUniforms))
		);
		ResourceLayoutDescription lightingLayoutDesc = ResourceLayoutDescription(params mLightingLayoutElements);
		mLightingResourceLayout = mGraphicsContext.Factory.CreateResourceLayout(lightingLayoutDesc);

		// Create lighting buffer with default values
		// Note: PBR requires higher ambient than Phong due to energy conservation (division by PI)
		var defaultLighting = LightingUniforms()
		{
			DirectionalLightDir = Vector4(0.5f, -1.0f, 0.3f, 0),    // Default light direction
			DirectionalLightColor = Vector4(1.0f, 0.95f, 0.9f, 1.0f), // Warm white, intensity 1.0
			AmbientLight = Vector4(0.3f, 0.3f, 0.35f, 0),            // Higher ambient for PBR
			CameraPosition = Vector4(0, 0, 0, 0)                     // Default camera at origin
		};

		var lightingBufferDesc = BufferDescription(sizeof(LightingUniforms), .ConstantBuffer, .Dynamic);
		mLightingBuffer = mGraphicsContext.Factory.CreateBuffer(&defaultLighting, lightingBufferDesc);

		// Create lighting resource set
		ResourceSetDescription lightingSetDesc = .(mLightingResourceLayout, mLightingBuffer);
		mLightingResourceSet = mGraphicsContext.Factory.CreateResourceSet(lightingSetDesc);
	}

	private void DestroyLightingResources()
	{
		if (mLightingResourceSet != null)
			mGraphicsContext.Factory.DestroyResourceSet(ref mLightingResourceSet);
		if (mLightingBuffer != null)
			mGraphicsContext.Factory.DestroyBuffer(ref mLightingBuffer);
		if (mLightingResourceLayout != null)
			mGraphicsContext.Factory.DestroyResourceLayout(ref mLightingResourceLayout);
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
			mUnlitPerObjectLayoutElements = new LayoutElementDescription[](
				LayoutElementDescription(0, .ConstantBuffer, .Vertex, true, sizeof(UnlitVertexUniforms))
			);
			ResourceLayoutDescription resourceLayoutDesc = ResourceLayoutDescription(params mUnlitPerObjectLayoutElements);
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

		// Register Unlit material type
		mMaterialRegistry.Register("Unlit", mUnlitPipeline, mUnlitMaterialResourceLayout,
			new (resources, material, renderer) => {
				UnlitMaterial.FillResourceSet(resources, material, renderer);
			});
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

	private void CreatePhongPipeline(FrameBuffer targetFrameBuffer)
	{
		// Compile Phong shaders
		mPhongVertexShader = mShaderManager.CompileFromSource(ShaderSources.PhongShadersVS, .Vertex, "VS");
		mPhongPixelShader = mShaderManager.CompileFromSource(ShaderSources.PhongShadersPS, .Pixel, "PS");

		// Vertex format (same as Unlit - standard mesh vertex)
		var vertexFormat = scope LayoutDescription()
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Position))
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Normal))
			.Add(ElementDescription(ElementFormat.Float2, ElementSemanticType.TexCoord))
			.Add(ElementDescription(ElementFormat.UByte4Normalized, ElementSemanticType.Color))
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Tangent));
		var vertexLayouts = scope InputLayouts();
		vertexLayouts.Add(vertexFormat);

		// Phong Material ResourceLayout
		{
			mPhongMaterialLayoutElements = new LayoutElementDescription[](
				LayoutElementDescription(0, .ConstantBuffer, .Pixel, false, sizeof(PhongFragmentUniforms)),
				LayoutElementDescription(0, .Texture, .Pixel),
				LayoutElementDescription(0, .Sampler, .Pixel)
			);
			ResourceLayoutDescription resourceLayoutDesc = ResourceLayoutDescription(params mPhongMaterialLayoutElements);
			mPhongMaterialResourceLayout = mGraphicsContext.Factory.CreateResourceLayout(resourceLayoutDesc);
		}

		// Create Phong pipeline
		// Layout: Set 0 = per-object, Set 1 = material, Set 2 = lighting
		var pipelineDescription = GraphicsPipelineDescription
		{
			RenderStates = RenderStateDescription.Default,
			Shaders = .()
			{
				VertexShader = mPhongVertexShader,
				PixelShader = mPhongPixelShader
			},
			InputLayouts = vertexLayouts,
			ResourceLayouts = mPhongPipelineResourceLayouts = new ResourceLayout[](mUnlitPerObjectResourceLayout, mPhongMaterialResourceLayout, mLightingResourceLayout),
			PrimitiveTopology = .TriangleList,
			Outputs = .CreateFromFrameBuffer(targetFrameBuffer)
		};

		mPhongPipeline = mGraphicsContext.Factory.CreateGraphicsPipeline(pipelineDescription);

		// Register Phong material type
		mMaterialRegistry.Register("Phong", mPhongPipeline, mPhongMaterialResourceLayout,
			new (resources, material, renderer) => {
				PhongMaterial.FillResourceSet(resources, material, renderer);
			});
	}

	private void DestroyPhongPipeline()
	{
		if (mPhongPipeline != null)
			mGraphicsContext.Factory.DestroyGraphicsPipeline(ref mPhongPipeline);
		if (mPhongMaterialResourceLayout != null)
			mGraphicsContext.Factory.DestroyResourceLayout(ref mPhongMaterialResourceLayout);
		if (mPhongPixelShader != null)
			mGraphicsContext.Factory.DestroyShader(ref mPhongPixelShader);
		if (mPhongVertexShader != null)
			mGraphicsContext.Factory.DestroyShader(ref mPhongVertexShader);
	}

	private void CreatePBRPipeline(FrameBuffer targetFrameBuffer)
	{
		// Compile PBR shaders
		mPBRVertexShader = mShaderManager.CompileFromSource(ShaderSources.PBRShadersVS, .Vertex, "VS");
		mPBRPixelShader = mShaderManager.CompileFromSource(ShaderSources.PBRShadersPS, .Pixel, "PS");

		// Vertex format (same as Phong - standard mesh vertex)
		var vertexFormat = scope LayoutDescription()
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Position))
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Normal))
			.Add(ElementDescription(ElementFormat.Float2, ElementSemanticType.TexCoord))
			.Add(ElementDescription(ElementFormat.UByte4Normalized, ElementSemanticType.Color))
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Tangent));
		var vertexLayouts = scope InputLayouts();
		vertexLayouts.Add(vertexFormat);

		// PBR Material ResourceLayout
		// CB + 5 textures (Albedo, Normal, MetallicRoughness, AO, Emissive) + sampler
		{
			mPBRMaterialLayoutElements = new LayoutElementDescription[](
				LayoutElementDescription(0, .ConstantBuffer, .Pixel, false, sizeof(PBRFragmentUniforms)),
				LayoutElementDescription(0, .Texture, .Pixel),  // Albedo
				LayoutElementDescription(1, .Texture, .Pixel),  // Normal
				LayoutElementDescription(2, .Texture, .Pixel),  // MetallicRoughness
				LayoutElementDescription(3, .Texture, .Pixel),  // AO
				LayoutElementDescription(4, .Texture, .Pixel),  // Emissive
				LayoutElementDescription(0, .Sampler, .Pixel)
			);
			ResourceLayoutDescription resourceLayoutDesc = ResourceLayoutDescription(params mPBRMaterialLayoutElements);
			mPBRMaterialResourceLayout = mGraphicsContext.Factory.CreateResourceLayout(resourceLayoutDesc);
		}

		// Create PBR pipeline
		// Layout: Set 0 = per-object, Set 1 = material, Set 2 = lighting
		var pipelineDescription = GraphicsPipelineDescription
		{
			RenderStates = RenderStateDescription.Default,
			Shaders = .()
			{
				VertexShader = mPBRVertexShader,
				PixelShader = mPBRPixelShader
			},
			InputLayouts = vertexLayouts,
			ResourceLayouts = mPBRPipelineResourceLayouts = new ResourceLayout[](mUnlitPerObjectResourceLayout, mPBRMaterialResourceLayout, mLightingResourceLayout),
			PrimitiveTopology = .TriangleList,
			Outputs = .CreateFromFrameBuffer(targetFrameBuffer)
		};

		mPBRPipeline = mGraphicsContext.Factory.CreateGraphicsPipeline(pipelineDescription);

		// Register PBR material type
		mMaterialRegistry.Register("PBR", mPBRPipeline, mPBRMaterialResourceLayout,
			new (resources, material, renderer) => {
				PBRMaterial.FillResourceSet(resources, material, renderer);
			});
	}

	private void DestroyPBRPipeline()
	{
		if (mPBRPipeline != null)
			mGraphicsContext.Factory.DestroyGraphicsPipeline(ref mPBRPipeline);
		if (mPBRMaterialResourceLayout != null)
			mGraphicsContext.Factory.DestroyResourceLayout(ref mPBRMaterialResourceLayout);
		if (mPBRPixelShader != null)
			mGraphicsContext.Factory.DestroyShader(ref mPBRPixelShader);
		if (mPBRVertexShader != null)
			mGraphicsContext.Factory.DestroyShader(ref mPBRVertexShader);
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

	private void CreateSkinnedPhongPipeline(FrameBuffer targetFrameBuffer)
	{
		// Compile skinned Phong shaders (separate pixel shader since lighting is at space3)
		mSkinnedPhongVertexShader = mShaderManager.CompileFromSource(ShaderSources.SkinnedPhongShadersVS, .Vertex, "VS");
		mSkinnedPhongPixelShader = mShaderManager.CompileFromSource(ShaderSources.SkinnedPhongShadersPS, .Pixel, "PS");

		// Skinned vertex format (same as skinned unlit)
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

		// Create skinned Phong pipeline
		// Layout: Set 0 = per-object, Set 1 = material, Set 2 = bones, Set 3 = lighting
		var skinnedPhongPipelineDescription = GraphicsPipelineDescription
		{
			RenderStates = RenderStateDescription.Default,
			Shaders = .()
			{
				VertexShader = mSkinnedPhongVertexShader,
				PixelShader = mSkinnedPhongPixelShader
			},
			InputLayouts = skinnedVertexLayouts,
			ResourceLayouts = mSkinnedPhongPipelineResourceLayouts = new ResourceLayout[](mSkinnedPerObjectResourceLayout, mPhongMaterialResourceLayout, mBoneMatricesResourceLayout, mLightingResourceLayout),
			PrimitiveTopology = .TriangleList,
			Outputs = .CreateFromFrameBuffer(targetFrameBuffer)
		};

		mSkinnedPhongPipeline = mGraphicsContext.Factory.CreateGraphicsPipeline(skinnedPhongPipelineDescription);
	}

	private void DestroySkinnedPhongPipeline()
	{
		if (mSkinnedPhongPipeline != null)
			mGraphicsContext.Factory.DestroyGraphicsPipeline(ref mSkinnedPhongPipeline);
		if (mSkinnedPhongPixelShader != null)
			mGraphicsContext.Factory.DestroyShader(ref mSkinnedPhongPixelShader);
		if (mSkinnedPhongVertexShader != null)
			mGraphicsContext.Factory.DestroyShader(ref mSkinnedPhongVertexShader);
	}

	private void CreateSkinnedPBRPipeline(FrameBuffer targetFrameBuffer)
	{
		// Compile skinned PBR shaders (lighting in space3 since space2 is bones)
		mSkinnedPBRVertexShader = mShaderManager.CompileFromSource(ShaderSources.SkinnedPBRShadersVS, .Vertex, "VS");
		mSkinnedPBRPixelShader = mShaderManager.CompileFromSource(ShaderSources.SkinnedPBRShadersPS, .Pixel, "PS");

		// Skinned vertex format (same as skinned Phong)
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

		// Create skinned PBR pipeline
		// Layout: Set 0 = per-object, Set 1 = material, Set 2 = bones, Set 3 = lighting
		var skinnedPBRPipelineDescription = GraphicsPipelineDescription
		{
			RenderStates = RenderStateDescription.Default,
			Shaders = .()
			{
				VertexShader = mSkinnedPBRVertexShader,
				PixelShader = mSkinnedPBRPixelShader
			},
			InputLayouts = skinnedVertexLayouts,
			ResourceLayouts = mSkinnedPBRPipelineResourceLayouts = new ResourceLayout[](mSkinnedPerObjectResourceLayout, mPBRMaterialResourceLayout, mBoneMatricesResourceLayout, mLightingResourceLayout),
			PrimitiveTopology = .TriangleList,
			Outputs = .CreateFromFrameBuffer(targetFrameBuffer)
		};

		mSkinnedPBRPipeline = mGraphicsContext.Factory.CreateGraphicsPipeline(skinnedPBRPipelineDescription);
	}

	private void DestroySkinnedPBRPipeline()
	{
		if (mSkinnedPBRPipeline != null)
			mGraphicsContext.Factory.DestroyGraphicsPipeline(ref mSkinnedPBRPipeline);
		if (mSkinnedPBRPixelShader != null)
			mGraphicsContext.Factory.DestroyShader(ref mSkinnedPBRPixelShader);
		if (mSkinnedPBRVertexShader != null)
			mGraphicsContext.Factory.DestroyShader(ref mSkinnedPBRVertexShader);
	}

	private void CreateDebugLinePipeline(FrameBuffer targetFrameBuffer)
	{
		// Compile debug line shaders
		mDebugLineVertexShader = mShaderManager.CompileFromSource(ShaderSources.DebugLineVS, .Vertex, "VS");
		mDebugLinePixelShader = mShaderManager.CompileFromSource(ShaderSources.DebugLinePS, .Pixel, "PS");

		// Debug line vertex format (position + color)
		var vertexFormat = scope LayoutDescription()
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Position))
			.Add(ElementDescription(ElementFormat.UByte4Normalized, ElementSemanticType.Color));
		var vertexLayouts = scope InputLayouts();
		vertexLayouts.Add(vertexFormat);

		// Debug resource layout (just view-projection matrix)
		mDebugLayoutElements = new LayoutElementDescription[](
			LayoutElementDescription(0, .ConstantBuffer, .Vertex, false, sizeof(DebugUniforms))
		);
		ResourceLayoutDescription debugLayoutDesc = ResourceLayoutDescription(params mDebugLayoutElements);
		mDebugResourceLayout = mGraphicsContext.Factory.CreateResourceLayout(debugLayoutDesc);

		// Create debug line pipeline with line primitive topology
		var renderStates = RenderStateDescription.Default;
		renderStates.DepthStencilState.DepthEnable = true;
		renderStates.DepthStencilState.DepthWriteMask = false; // Don't write to depth (draw on top of everything)

		var pipelineDescription = GraphicsPipelineDescription
		{
			RenderStates = renderStates,
			Shaders = .()
			{
				VertexShader = mDebugLineVertexShader,
				PixelShader = mDebugLinePixelShader
			},
			InputLayouts = vertexLayouts,
			ResourceLayouts = mDebugPipelineResourceLayouts = new ResourceLayout[](mDebugResourceLayout),
			PrimitiveTopology = .LineList,
			Outputs = .CreateFromFrameBuffer(targetFrameBuffer)
		};

		mDebugLinePipeline = mGraphicsContext.Factory.CreateGraphicsPipeline(pipelineDescription);
	}

	private void DestroyDebugLinePipeline()
	{
		if (mDebugLinePipeline != null)
			mGraphicsContext.Factory.DestroyGraphicsPipeline(ref mDebugLinePipeline);
		if (mDebugResourceLayout != null)
			mGraphicsContext.Factory.DestroyResourceLayout(ref mDebugResourceLayout);
		if (mDebugLinePixelShader != null)
			mGraphicsContext.Factory.DestroyShader(ref mDebugLinePixelShader);
		if (mDebugLineVertexShader != null)
			mGraphicsContext.Factory.DestroyShader(ref mDebugLineVertexShader);
	}

	private void CreateDepthOnlyPipelines(FrameBuffer targetFrameBuffer)
	{
		// Compile depth-only vertex shaders
		mDepthOnlyVertexShader = mShaderManager.CompileFromSource(ShaderSources.DepthOnlyVS, .Vertex, "VS");
		mSkinnedDepthOnlyVertexShader = mShaderManager.CompileFromSource(ShaderSources.SkinnedDepthOnlyVS, .Vertex, "VS");

		// Standard mesh vertex format
		var vertexFormat = scope LayoutDescription()
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Position))
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Normal))
			.Add(ElementDescription(ElementFormat.Float2, ElementSemanticType.TexCoord))
			.Add(ElementDescription(ElementFormat.UByte4Normalized, ElementSemanticType.Color))
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Tangent));
		var vertexLayouts = scope InputLayouts();
		vertexLayouts.Add(vertexFormat);

		// Skinned mesh vertex format
		var skinnedVertexFormat = scope LayoutDescription()
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Position))
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Normal))
			.Add(ElementDescription(ElementFormat.Float2, ElementSemanticType.TexCoord))
			.Add(ElementDescription(ElementFormat.UByte4Normalized, ElementSemanticType.Color))
			.Add(ElementDescription(ElementFormat.Float3, ElementSemanticType.Tangent))
			.Add(ElementDescription(ElementFormat.UShort4, ElementSemanticType.BlendIndices))
			.Add(ElementDescription(ElementFormat.Float4, ElementSemanticType.BlendWeight));
		var skinnedVertexLayouts = scope InputLayouts();
		skinnedVertexLayouts.Add(skinnedVertexFormat);

		// Depth-only render states: depth write enabled, depth test enabled
		var depthOnlyRenderStates = RenderStateDescription.Default;
		depthOnlyRenderStates.DepthStencilState.DepthEnable = true;
		depthOnlyRenderStates.DepthStencilState.DepthWriteMask = true;
		depthOnlyRenderStates.DepthStencilState.DepthFunction = .Less;

		// Create static mesh depth-only pipeline
		// Only needs Set 0 (per-object uniforms) - no material or lighting
		var depthOnlyPipelineDesc = GraphicsPipelineDescription
		{
			RenderStates = depthOnlyRenderStates,
			Shaders = .()
			{
				VertexShader = mDepthOnlyVertexShader,
				PixelShader = null  // No pixel shader for depth-only
			},
			InputLayouts = vertexLayouts,
			ResourceLayouts = mDepthOnlyPipelineResourceLayouts = new ResourceLayout[](mUnlitPerObjectResourceLayout),
			PrimitiveTopology = .TriangleList,
			Outputs = .CreateFromFrameBuffer(targetFrameBuffer)
		};

		mDepthOnlyPipeline = mGraphicsContext.Factory.CreateGraphicsPipeline(depthOnlyPipelineDesc);

		// Create skinned mesh depth-only pipeline
		// Shader uses space0 (Set 0) for per-object and space2 (Set 2) for bone matrices
		// Include material layout as Set 1 placeholder to maintain descriptor set indices
		var skinnedDepthOnlyPipelineDesc = GraphicsPipelineDescription
		{
			RenderStates = depthOnlyRenderStates,
			Shaders = .()
			{
				VertexShader = mSkinnedDepthOnlyVertexShader,
				PixelShader = null  // No pixel shader for depth-only
			},
			InputLayouts = skinnedVertexLayouts,
			ResourceLayouts = mSkinnedDepthOnlyPipelineResourceLayouts = new ResourceLayout[](mSkinnedPerObjectResourceLayout, mUnlitMaterialResourceLayout, mBoneMatricesResourceLayout),
			PrimitiveTopology = .TriangleList,
			Outputs = .CreateFromFrameBuffer(targetFrameBuffer)
		};

		mSkinnedDepthOnlyPipeline = mGraphicsContext.Factory.CreateGraphicsPipeline(skinnedDepthOnlyPipelineDesc);
	}

	private void DestroyDepthOnlyPipelines()
	{
		if (mDepthOnlyPipeline != null)
			mGraphicsContext.Factory.DestroyGraphicsPipeline(ref mDepthOnlyPipeline);
		if (mSkinnedDepthOnlyPipeline != null)
			mGraphicsContext.Factory.DestroyGraphicsPipeline(ref mSkinnedDepthOnlyPipeline);
		if (mDepthOnlyVertexShader != null)
			mGraphicsContext.Factory.DestroyShader(ref mDepthOnlyVertexShader);
		if (mSkinnedDepthOnlyVertexShader != null)
			mGraphicsContext.Factory.DestroyShader(ref mSkinnedDepthOnlyVertexShader);
	}

	private void CreateHiZPipeline()
	{
		// Compile Hi-Z downsample compute shader
		mHiZDownsampleShader = mShaderManager.CompileFromSource(ShaderSources.HiZDownsampleCS, .Compute, "CS");

		// Create Hi-Z resource layout
		// Layout: InputDepth (Texture), OutputDepth (RWTexture/UAV), HiZParams (ConstantBuffer)
		mHiZLayoutElements = new LayoutElementDescription[](
			LayoutElementDescription(0, .Texture, .Compute),                                    // InputDepth
			LayoutElementDescription(0, .TextureReadWrite, .Compute),                           // OutputDepth (UAV)
			LayoutElementDescription(0, .ConstantBuffer, .Compute, false, sizeof(HiZParams))    // HiZParams
		);
		ResourceLayoutDescription hiZLayoutDesc = ResourceLayoutDescription(params mHiZLayoutElements);
		mHiZResourceLayout = mGraphicsContext.Factory.CreateResourceLayout(hiZLayoutDesc);

		// Create Hi-Z params buffer
		var defaultParams = HiZParams() { OutputSizeX = 1, OutputSizeY = 1, InputSizeX = 0, InputSizeY = 0 };
		var hiZParamsBufferDesc = BufferDescription(sizeof(HiZParams), .ConstantBuffer, .Dynamic);
		mHiZParamsBuffer = mGraphicsContext.Factory.CreateBuffer(&defaultParams, hiZParamsBufferDesc);

		// Create Hi-Z compute pipeline
		var resourceLayouts = scope ResourceLayout[](mHiZResourceLayout);
		var pipelineDesc = ComputePipelineDescription(
			resourceLayouts,
			ComputeShaderStateDescription(){ ComputeShader= mHiZDownsampleShader},//ComputeShaderStateDescription(mHiZDownsampleShader, "CS"),
			8, 8, 1  // Thread group size matches shader [numthreads(8, 8, 1)]
		);
		mHiZDownsamplePipeline = mGraphicsContext.Factory.CreateComputePipeline(pipelineDesc);
	}

	private void DestroyHiZPipeline()
	{
		if (mHiZDownsamplePipeline != null)
			mGraphicsContext.Factory.DestroyComputePipeline(ref mHiZDownsamplePipeline);
		if (mHiZResourceLayout != null)
			mGraphicsContext.Factory.DestroyResourceLayout(ref mHiZResourceLayout);
		if (mHiZParamsBuffer != null)
			mGraphicsContext.Factory.DestroyBuffer(ref mHiZParamsBuffer);
		if (mHiZDownsampleShader != null)
			mGraphicsContext.Factory.DestroyShader(ref mHiZDownsampleShader);
	}
}
