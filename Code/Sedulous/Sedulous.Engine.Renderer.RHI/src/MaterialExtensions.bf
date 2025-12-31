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