using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Engine.Renderer.GPU;

namespace Sedulous.Engine.Renderer.RHI;

/// Delegate for filling material resource set resources
delegate void MaterialResourceSetFiller(List<GraphicsResource> resources, GPUMaterial material, RHIRendererSubsystem renderer);

/// Information about a registered material pipeline
struct MaterialPipelineInfo
{
	public GraphicsPipelineState Pipeline;
	public ResourceLayout MaterialResourceLayout;
	public MaterialResourceSetFiller ResourceSetFiller;
}

/// Registry for material pipelines.
/// Maps material types to their pipelines, resource layouts, and resource set creation logic.
/// Eliminates hardcoded switch statements for material handling.
class MaterialPipelineRegistry
{
	private Dictionary<String, MaterialPipelineInfo> mRegistry = new .() ~ {
		for (var entry in _)
			delete entry.key;
		delete _;
	};

	private List<MaterialResourceSetFiller> mFillers = new .() ~ {
		for (var filler in _)
			delete filler;
		delete _;
	};

	private MaterialPipelineInfo mDefaultPipeline;
	private String mDefaultMaterialType ~ delete _;

	/// Register a material pipeline
	public void Register(StringView materialType, GraphicsPipelineState pipeline, ResourceLayout materialLayout, MaterialResourceSetFiller resourceSetFiller)
	{
		var info = MaterialPipelineInfo()
		{
			Pipeline = pipeline,
			MaterialResourceLayout = materialLayout,
			ResourceSetFiller = resourceSetFiller
		};

		mRegistry[new String(materialType)] = info;
		mFillers.Add(resourceSetFiller);

		// First registered becomes the default
		if (mDefaultMaterialType == null)
		{
			mDefaultMaterialType = new String(materialType);
			mDefaultPipeline = info;
		}
	}

	/// Set the default material type (fallback when material type not found)
	public void SetDefault(StringView materialType)
	{
		if (mRegistry.TryGetValue(scope String(materialType), let info))
		{
			delete mDefaultMaterialType;
			mDefaultMaterialType = new String(materialType);
			mDefaultPipeline = info;
		}
	}

	/// Get pipeline info for a material type
	public MaterialPipelineInfo GetPipelineInfo(StringView materialType)
	{
		if (mRegistry.TryGetValue(scope String(materialType), let info))
			return info;
		return mDefaultPipeline;
	}

	/// Get the pipeline for a material type
	public GraphicsPipelineState GetPipeline(StringView materialType)
	{
		return GetPipelineInfo(materialType).Pipeline;
	}

	/// Get the material resource layout for a material type
	public ResourceLayout GetMaterialResourceLayout(StringView materialType)
	{
		return GetPipelineInfo(materialType).MaterialResourceLayout;
	}

	/// Fill resource set resources for a material
	public void FillResourceSet(StringView materialType, List<GraphicsResource> resources, GPUMaterial material, RHIRendererSubsystem renderer)
	{
		var info = GetPipelineInfo(materialType);
		if (info.ResourceSetFiller != null)
			info.ResourceSetFiller(resources, material, renderer);
	}

	/// Check if a material type is registered
	public bool IsRegistered(StringView materialType)
	{
		return mRegistry.ContainsKey(scope String(materialType));
	}

	/// Get all registered material types
	public void GetRegisteredTypes(List<String> outTypes)
	{
		for (var key in mRegistry.Keys)
			outTypes.Add(new String(key));
	}
}
