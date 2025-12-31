using System;
using Sedulous.Imaging;

namespace Sedulous.Model;

/// Texture sampler settings
class TextureSampler
{
	/// Wrapping mode for U (horizontal) coordinate
	public TextureWrapMode WrapU = .Repeat;

	/// Wrapping mode for V (vertical) coordinate
	public TextureWrapMode WrapV = .Repeat;

	/// Magnification filter (when texel is larger than pixel)
	public TextureFilter MagFilter = .Linear;

	/// Minification filter (when texel is smaller than pixel)
	public TextureFilter MinFilter = .LinearMipmapLinear;
}

/// Texture reference with sampler settings
class Texture
{
	/// Texture name (optional)
	public String Name ~ delete _;

	/// Raw image data (owned by this texture)
	public Image ImageData ~ delete _;

	/// Sampler settings for this texture
	public TextureSampler Sampler = new .() ~ delete _;

	/// MIME type of the source image (e.g., "image/png", "image/jpeg")
	public String MimeType ~ delete _;

	/// URI or path to the source image file (if loaded from external file)
	public String SourceUri ~ delete _;

	public this()
	{
	}

	public this(String name)
	{
		Name = new String(name);
	}
}
