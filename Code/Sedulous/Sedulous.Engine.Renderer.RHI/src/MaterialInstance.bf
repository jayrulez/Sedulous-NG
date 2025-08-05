using System;
using System.Collections;
using Sedulous.Engine.Renderer.RHI.Shaders;
using Sedulous.Resources;
using Sedulous.Mathematics;
namespace Sedulous.Engine.Renderer.RHI;

// An instance of a material template with specific values
class MaterialInstance : Material
{
	private MaterialTemplate mTemplate;
	private Dictionary<StringView, Variant> mParameterValues = new .() ~ delete _;
	private Dictionary<StringView, ResourceHandle<TextureResource>> mTextures = new .() ~ { for (var item in _) item.value.Release(); };

	// Cached data
	private uint8[] mConstantBufferData ~ delete _;
	private bool mDirty = true;

	// Override material properties
	public override StringView ShaderName => mTemplate.ShaderName;

	public MaterialTemplate Template => mTemplate;

	public this(MaterialTemplate template)
	{
		mTemplate = template;
		mConstantBufferData = new uint8[template.ConstantBufferSize];

		// Set defaults from template
		Blending = template.DefaultBlendMode;
		Culling = template.DefaultCullMode;
		DepthWrite = template.DefaultDepthWrite;
		DepthTest = template.DefaultDepthTest;

		// Initialize with default values
		for (var group in template.ParameterGroups)
		{
			for (var param in group.Parameters)
			{
				if (!param.IsTexture())
				{
					mParameterValues[param.Name] = Variant.CreateFromVariant(param.DefaultValue);
				}
			}
		}

		UpdateConstantBuffer();
	}

	public ~this()
	{
		// Release texture handles
		for (var (_, handle) in mTextures)
		{
			handle.Release();
		}
	}

	// Set parameter values
	public bool SetFloat(StringView name, float value)
	{
		if (mTemplate.ParameterLookup.TryGetValue(name, let param) && param.Type == .Float)
		{
			mParameterValues[name] = Variant.Create(value);
			mDirty = true;
			return true;
		}
		return false;
	}

	public bool SetVector2(StringView name, Vector2 value)
	{
		if (mTemplate.ParameterLookup.TryGetValue(name, let param) && param.Type == .Float2)
		{
			mParameterValues[name] = Variant.Create(value);
			mDirty = true;
			return true;
		}
		return false;
	}

	public bool SetVector3(StringView name, Vector3 value)
	{
		if (mTemplate.ParameterLookup.TryGetValue(name, let param) && param.Type == .Float3)
		{
			mParameterValues[name] = Variant.Create(value);
			mDirty = true;
			return true;
		}
		return false;
	}

	public bool SetVector4(StringView name, Vector4 value)
	{
		if (mTemplate.ParameterLookup.TryGetValue(name, let param) && param.Type == .Float4)
		{
			mParameterValues[name] = Variant.Create(value);
			mDirty = true;
			return true;
		}
		return false;
	}

	public bool SetColor(StringView name, Color value)
	{
		if (mTemplate.ParameterLookup.TryGetValue(name, let param) && param.Type == .Color)
		{
			mParameterValues[name] = Variant.Create(value.ToVector4());
			mDirty = true;
			return true;
		}
		return false;
	}

	public bool SetInt(StringView name, int32 value)
	{
		if (mTemplate.ParameterLookup.TryGetValue(name, let param) && param.Type == .Int)
		{
			mParameterValues[name] = Variant.Create(value);
			mDirty = true;
			return true;
		}
		return false;
	}

	public bool SetBool(StringView name, bool value)
	{
		if (mTemplate.ParameterLookup.TryGetValue(name, let param) && param.Type == .Bool)
		{
			mParameterValues[name] = Variant.Create(value);
			mDirty = true;
			return true;
		}
		return false;
	}

	public bool SetTexture(StringView name, ref ResourceHandle<TextureResource> texture)
	{
		if (mTemplate.ParameterLookup.TryGetValue(name, let param) && param.IsTexture())
		{
			// Release old texture if exists
			if (mTextures.TryGetValue(name, var oldHandle))
			{
				oldHandle.Release();
			}

			mTextures[name] = texture;
			texture.AddRef();
			return true;
		}
		return false;
	}

	// Get parameter values
	public float? GetFloat(StringView name)
	{
		if (mParameterValues.TryGetValue(name, let value))
		{
			if (value.TryGet<float>(let val))
				return val;
		}
		return null;
	}

	public Vector2? GetVector2(StringView name)
	{
		if (mParameterValues.TryGetValue(name, let value))
		{
			if (value.TryGet<Vector2>(let val))
				return val;
		}
		return null;
	}

	public Vector3? GetVector3(StringView name)
	{
		if (mParameterValues.TryGetValue(name, let value))
		{
			if (value.TryGet<Vector3>(let val))
				return val;
		}
		return null;
	}

	public Vector4? GetVector4(StringView name)
	{
		if (mParameterValues.TryGetValue(name, let value))
		{
			if (value.TryGet<Vector4>(let val))
				return val;
		}
		return null;
	}

	public Color? GetColor(StringView name)
	{
		if (mParameterValues.TryGetValue(name, let value))
		{
			if (value.TryGet<Vector4>(let val))
				return Color(val.X, val.Y, val.Z, val.W);
		}
		return null;
	}

	public ResourceHandle<TextureResource>? GetTexture(StringView name)
	{
		if (mTextures.TryGetValue(name, let handle))
			return handle;
		return null;
	}

	// Update the constant buffer data
	private void UpdateConstantBuffer()
	{
		if (!mDirty || mConstantBufferData == null)
			return;

		// Clear buffer
		Internal.MemSet(mConstantBufferData.Ptr, 0, mConstantBufferData.Count);

		// Write each parameter value
		for (var group in mTemplate.ParameterGroups)
		{
			for (var param in group.Parameters)
			{
				if (param.IsTexture())
					continue;

				if (!mParameterValues.TryGetValue(param.Name, let value))
					continue;

				void* destPtr = &mConstantBufferData[param.Offset];

				switch (param.Type)
				{
				case .Float:
					if (value.TryGet<float>(let f))
						*(float*)destPtr = f;
				case .Float2:
					if (value.TryGet<Vector2>(let v2))
						*(Vector2*)destPtr = v2;
				case .Float3:
					if (value.TryGet<Vector3>(let v3))
						*(Vector3*)destPtr = v3;
				case .Float4,.Color:
					if (value.TryGet<Vector4>(let v4))
						*(Vector4*)destPtr = v4;
				case .Int:
					if (value.TryGet<int32>(let i))
						*(int32*)destPtr = i;
				case .Bool:
					if (value.TryGet<bool>(let b))
						*(int32*)destPtr = b ? 1 : 0; // Bools are 4 bytes in HLSL
				case .Matrix:
					if (value.TryGet<Matrix>(let m))
						*(Matrix*)destPtr = m;
				default:
					break;
				}
			}
		}

		mDirty = false;
	}

	// Get shader features based on current state
	public ShaderFeatures GetRequiredFeatures()
	{
		ShaderFeatures features = mTemplate.RequiredFeatures;

		// Add features based on textures
		if (GetTexture("NormalTexture").HasValue)
			features |= .NormalMapping;

		if (GetTexture("EmissiveTexture").HasValue)
			features |= .Emission;

		// Add features based on blend mode
		if (Blending == .AlphaTest)
			features |= .AlphaTest;
		else if (Blending == .AlphaBlend)
			features |= .AlphaBlend;

		return features;
	}

	// Material base class implementation
	public override int GetUniformDataSize()
	{
		return (int)mTemplate.ConstantBufferSize;
	}

	public override void FillUniformData(Span<uint8> buffer)
	{
		UpdateConstantBuffer();
		if (mConstantBufferData != null && buffer.Length >= mConstantBufferData.Count)
		{
			Internal.MemCpy(buffer.Ptr, mConstantBufferData.Ptr, mConstantBufferData.Count);
		}
	}

	public override void GetTextureResources(List<ResourceHandle<TextureResource>> textures)
	{
		textures.Clear();

		// Add textures in the order defined by the template
		for (var group in mTemplate.ParameterGroups)
		{
			for (var param in group.Parameters)
			{
				if (param.IsTexture())
				{
					if (mTextures.TryGetValue(param.Name, let handle))
					{
						if (handle.IsValid)
							textures.Add(handle);
					}
				}
			}
		}
	}

	// Validate this instance
	public Result<void> Validate()
	{
		if (mTemplate.Validate != null)
			return mTemplate.Validate(this);
		return .Ok;
	}

	// Clone this material instance
	public MaterialInstance Clone()
	{
		var clone = new MaterialInstance(mTemplate);

		// Copy properties
		clone.Blending = Blending;
		clone.Culling = Culling;
		clone.DepthWrite = DepthWrite;
		clone.DepthTest = DepthTest;
		clone.RenderOrder = RenderOrder;

		// Copy parameter values
		for (var (name, value) in mParameterValues)
		{
			clone.mParameterValues[name] = Variant.CreateFromVariant(value);
		}

		// Copy texture references
		for (var (name, handle) in mTextures)
		{
			clone.SetTexture(name, ref handle);
		}

		clone.mDirty = true;
		return clone;
	}
}