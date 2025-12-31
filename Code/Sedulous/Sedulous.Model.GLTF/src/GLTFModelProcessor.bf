using System.Collections;
using System;
using cgltf_Beef;
namespace Sedulous.Model.Formats.GLTF;

class GLTFModelProcessor : ModelProcessor
{
	private List<StringView> mSupportedExtensions = new .() { "gltf", "glb" } ~ delete _;

	public override void GetExtensions(List<StringView> extensions)
	{
		extensions.AddRange(mSupportedExtensions);
	}

	public override bool SupportsFormat(StringView @extension)
	{
		return mSupportedExtensions.Contains(@extension);
	}

	public override Model Read(StringView path)
	{
		cgltf_options options = .();

		cgltf_data* data = null;

		cgltf_result result = cgltf_parse_file(&options, path.Ptr, &data);

		if (result != .cgltf_result_success)
		{
			return null;
		}
		cgltf_free(data);



		return null;
	}

	public override bool Write(StringView path, Model model)
	{
		return false;
	}
}