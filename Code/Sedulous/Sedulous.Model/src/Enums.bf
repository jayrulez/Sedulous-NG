namespace Sedulous.Model;

/// Primitive topology type for mesh rendering
enum PrimitiveType
{
	Points,
	Lines,
	LineLoop,
	LineStrip,
	Triangles,
	TriangleStrip,
	TriangleFan
}

/// Material alpha blending mode
enum AlphaMode
{
	Opaque,
	Mask,
	Blend
}

/// Animation channel target path
enum AnimationPath
{
	Translation,
	Rotation,
	Scale,
	Weights
}

/// Keyframe interpolation type
enum InterpolationType
{
	Linear,
	Step,
	CubicSpline
}

/// Texture wrapping mode
enum TextureWrapMode
{
	Repeat,
	ClampToEdge,
	MirroredRepeat
}

/// Texture filtering mode
enum TextureFilter
{
	Nearest,
	Linear,
	NearestMipmapNearest,
	LinearMipmapNearest,
	NearestMipmapLinear,
	LinearMipmapLinear
}
