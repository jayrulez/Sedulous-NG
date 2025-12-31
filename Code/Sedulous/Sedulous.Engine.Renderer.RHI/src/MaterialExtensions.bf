using System.Collections;
using Sedulous.RHI;
using Sedulous.Engine.Renderer.RHI;
namespace Sedulous.Engine.Renderer;

extension UnlitMaterial
{
	public static void FillResourceSet(List<GraphicsResource> resources, GPUMaterial gpuMaterial, RHIRendererSubsystem renderer)
	{
		// Uniform buffer
		resources.Add(gpuMaterial.UniformBuffer ?? renderer.DefaultUnlitMaterialCB);

		// Main texture
		var textures = gpuMaterial.GetGPUTextures();
		resources.Add(textures.Count > 0 ? textures[0].Resource.Texture : renderer.GetDefaultWhiteTexture().Resource.Texture);

		// Sampler
		resources.Add(renderer.GraphicsContext.DefaultSampler);
	}
}

extension PhongMaterial
{
	public static void FillResourceSet(List<GraphicsResource> resources, GPUMaterial gpuMaterial, RHIRendererSubsystem renderer)
	{
		// Uniform buffer (PhongFragmentUniforms)
		resources.Add(gpuMaterial.UniformBuffer);

		// Diffuse texture
		var textures = gpuMaterial.GetGPUTextures();
		resources.Add(textures.Count > 0 ? textures[0].Resource.Texture : renderer.GetDefaultWhiteTexture().Resource.Texture);

		// Sampler
		resources.Add(renderer.GraphicsContext.DefaultSampler);
	}
}

extension PBRMaterial
{
	public static void FillResourceSet(List<GraphicsResource> resources, GPUMaterial gpuMaterial, RHIRendererSubsystem renderer)
	{
		// Uniform buffer (PBRFragmentUniforms)
		resources.Add(gpuMaterial.UniformBuffer);

		// PBR textures (5 total):
		// 0: Albedo, 1: Normal, 2: MetallicRoughness, 3: AO, 4: Emissive
		var textures = gpuMaterial.GetGPUTextures();
		let defaultWhite = renderer.GetDefaultWhiteTexture().Resource.Texture;
		let defaultBlack = renderer.GetDefaultBlackTexture().Resource.Texture;
		let defaultNormal = renderer.GetDefaultNormalTexture().Resource.Texture;

		// Albedo (default white)
		resources.Add(textures.Count > 0 && textures[0].Resource != null ? textures[0].Resource.Texture : defaultWhite);

		// Normal map (default flat normal)
		resources.Add(textures.Count > 1 && textures[1].Resource != null ? textures[1].Resource.Texture : defaultNormal);

		// MetallicRoughness (default: 0 metallic, 0.5 roughness - use white texture, shader handles values)
		resources.Add(textures.Count > 2 && textures[2].Resource != null ? textures[2].Resource.Texture : defaultWhite);

		// AO (default white = no occlusion)
		resources.Add(textures.Count > 3 && textures[3].Resource != null ? textures[3].Resource.Texture : defaultWhite);

		// Emissive (default black = no emission)
		resources.Add(textures.Count > 4 && textures[4].Resource != null ? textures[4].Resource.Texture : defaultBlack);

		// Sampler
		resources.Add(renderer.GraphicsContext.DefaultSampler);
	}
}