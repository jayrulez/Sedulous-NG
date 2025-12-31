using System.Collections;
using System;
using System.IO;
using cgltf_Beef;
using Sedulous.Mathematics;
using Sedulous.Imaging;

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

		// Convert path to null-terminated string for cgltf
		let pathStr = scope String(path);

		// Parse the GLTF/GLB file
		cgltf_result result = cgltf_parse_file(&options, pathStr.CStr(), &data);
		if (result != .cgltf_result_success)
			return null;

		defer cgltf_free(data);

		// Load binary buffers (external .bin files or embedded data)
		result = cgltf_load_buffers(&options, data, pathStr.CStr());
		if (result != .cgltf_result_success)
			return null;

		// Get base path for loading external resources
		let basePath = scope String();
		Path.GetDirectoryPath(path, basePath);

		// Create the model
		let model = new Model();

		// Convert textures first (materials reference them)
		ConvertTextures(data, model, basePath);

		// Convert materials
		ConvertMaterials(data, model);

		// Convert meshes
		ConvertMeshes(data, model);

		// Convert nodes (scene hierarchy)
		ConvertNodes(data, model);

		// Set up root nodes from the default scene
		if (data.scene != null)
		{
			for (int i = 0; i < (int)data.scene.nodes_count; i++)
			{
				let nodeIndex = (int32)cgltf_node_index(data, data.scene.nodes[i]);
				model.AddRootNodeIndex(nodeIndex);
			}
		}
		else if (data.scenes_count > 0)
		{
			// Use first scene if no default
			let scene = &data.scenes[0];
			for (int i = 0; i < (int)scene.nodes_count; i++)
			{
				let nodeIndex = (int32)cgltf_node_index(data, scene.nodes[i]);
				model.AddRootNodeIndex(nodeIndex);
			}
		}

		// Convert skins
		ConvertSkins(data, model);

		// Convert animations
		ConvertAnimations(data, model);

		return model;
	}

	private void ConvertTextures(cgltf_data* data, Model model, StringView basePath)
	{
		for (int i = 0; i < (int)data.textures_count; i++)
		{
			let gltfTexture = &data.textures[i];
			let texture = new Texture();

			if (gltfTexture.name != null)
				texture.Name = new String(gltfTexture.name);

			// Load image data
			if (gltfTexture.image != null)
			{
				let gltfImage = gltfTexture.image;

				if (gltfImage.mime_type != null)
					texture.MimeType = new String(gltfImage.mime_type);

				if (gltfImage.uri != null)
				{
					let uri = StringView(gltfImage.uri);

					if (uri.StartsWith("data:"))
					{
						// Base64 encoded data URI (e.g., "data:image/png;base64,iVBORw0...")
						// Don't store the full base64 string as SourceUri (it's huge and not useful)
						if (LoadImageFromDataUri(uri) case .Ok(let image))
							texture.ImageData = image;
					}
					else
					{
						// External image file
						texture.SourceUri = new String(uri);

						let imagePath = scope String();
						Path.InternalCombine(imagePath, basePath, uri);

						if (ImageLoaderFactory.LoadImage(imagePath) case .Ok(let image))
							texture.ImageData = image;
					}
				}
				else if (gltfImage.buffer_view != null)
				{
					// Embedded image data in buffer
					let bufferData = cgltf_buffer_view_data(gltfImage.buffer_view);
					let size = (int)gltfImage.buffer_view.size;
					if (bufferData != null && size > 0)
					{
						let span = Span<uint8>(bufferData, size);
						let formatHint = GetFormatHintFromMimeType(gltfImage.mime_type);

						// Debug: Write embedded image to file to verify it's valid
						/*{
							let debugPath = scope String();
							debugPath.AppendF("debug_embedded_image_{}.png", i);
							let file = scope System.IO.FileStream();
							if (file.Create(debugPath) case .Ok)
							{
								file.TryWrite(span);
								file.Close();
							}
						}*/

						if (ImageLoaderFactory.LoadImageFromMemory(span, formatHint) case .Ok(let image))
							texture.ImageData = image;
					}
				}
			}

			// Convert sampler settings
			if (gltfTexture.sampler != null)
			{
				let sampler = gltfTexture.sampler;
				texture.Sampler.WrapU = ConvertWrapMode(sampler.wrap_s);
				texture.Sampler.WrapV = ConvertWrapMode(sampler.wrap_t);
				texture.Sampler.MagFilter = ConvertFilter(sampler.mag_filter);
				texture.Sampler.MinFilter = ConvertFilter(sampler.min_filter);
			}

			model.AddTexture(texture);
		}
	}

	private StringView GetFormatHintFromMimeType(char8* mimeType)
	{
		if (mimeType == null)
			return "";

		let mime = StringView(mimeType);
		if (mime == "image/png")
			return ".png";
		if (mime == "image/jpeg")
			return ".jpg";
		return "";
	}

	private Result<Image> LoadImageFromDataUri(StringView dataUri)
	{
		// Format: data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...
		let commaPos = dataUri.IndexOf(',');
		if (commaPos == -1)
			return .Err;

		let header = dataUri.Substring(5, commaPos - 5); // Skip "data:"
		let base64Data = dataUri.Substring(commaPos + 1);

		// Parse MIME type from header (e.g., "image/png;base64")
		StringView formatHint = "";
		if (header.Contains("image/png"))
			formatHint = ".png";
		else if (header.Contains("image/jpeg") || header.Contains("image/jpg"))
			formatHint = ".jpg";

		// Use cgltf's base64 decoder
		// Estimate decoded size: base64 uses 4 chars per 3 bytes
		let estimatedSize = (base64Data.Length * 3) / 4;
		void* decodedData = null;
		cgltf_options options = .();

		let base64Str = scope String(base64Data);
		if (cgltf_load_buffer_base64(&options, (.)estimatedSize, base64Str.CStr(), &decodedData) != .cgltf_result_success)
			return .Err;

		defer Internal.StdFree(decodedData);

		let span = Span<uint8>((uint8*)decodedData, estimatedSize);

		if (ImageLoaderFactory.LoadImageFromMemory(span, formatHint) case .Ok(let image))
			return .Ok(image);

		return .Err;
	}

	private TextureWrapMode ConvertWrapMode(cgltf_wrap_mode mode)
	{
		switch (mode)
		{
		case .cgltf_wrap_mode_clamp_to_edge: return .ClampToEdge;
		case .cgltf_wrap_mode_mirrored_repeat: return .MirroredRepeat;
		case .cgltf_wrap_mode_repeat: return .Repeat;
		default: return .Repeat;
		}
	}

	private TextureFilter ConvertFilter(cgltf_filter_type filter)
	{
		switch (filter)
		{
		case .cgltf_filter_type_nearest: return .Nearest;
		case .cgltf_filter_type_linear: return .Linear;
		case .cgltf_filter_type_nearest_mipmap_nearest: return .NearestMipmapNearest;
		case .cgltf_filter_type_linear_mipmap_nearest: return .LinearMipmapNearest;
		case .cgltf_filter_type_nearest_mipmap_linear: return .NearestMipmapLinear;
		case .cgltf_filter_type_linear_mipmap_linear: return .LinearMipmapLinear;
		default: return .Linear;
		}
	}

	private void ConvertMaterials(cgltf_data* data, Model model)
	{
		for (int i = 0; i < (int)data.materials_count; i++)
		{
			let gltfMat = &data.materials[i];
			let material = new Material();

			if (gltfMat.name != null)
				material.Name = new String(gltfMat.name);

			// PBR Metallic-Roughness
			if (gltfMat.has_pbr_metallic_roughness != 0)
			{
				let pbr = &gltfMat.pbr_metallic_roughness;

				material.BaseColorFactor = Vector4(
					pbr.base_color_factor[0],
					pbr.base_color_factor[1],
					pbr.base_color_factor[2],
					pbr.base_color_factor[3]
				);
				material.MetallicFactor = pbr.metallic_factor;
				material.RoughnessFactor = pbr.roughness_factor;

				// Base color texture
				if (pbr.base_color_texture.texture != null)
				{
					material.BaseColorTexture.TextureIndex = (int32)cgltf_texture_index(data, pbr.base_color_texture.texture);
					material.BaseColorTexture.TexCoordIndex = pbr.base_color_texture.texcoord;
					ConvertTextureTransform(&pbr.base_color_texture, ref material.BaseColorTexture);
				}

				// Metallic-roughness texture
				if (pbr.metallic_roughness_texture.texture != null)
				{
					material.MetallicRoughnessTexture.TextureIndex = (int32)cgltf_texture_index(data, pbr.metallic_roughness_texture.texture);
					material.MetallicRoughnessTexture.TexCoordIndex = pbr.metallic_roughness_texture.texcoord;
					ConvertTextureTransform(&pbr.metallic_roughness_texture, ref material.MetallicRoughnessTexture);
				}
			}

			// Normal texture
			if (gltfMat.normal_texture.texture != null)
			{
				material.NormalTexture.Texture.TextureIndex = (int32)cgltf_texture_index(data, gltfMat.normal_texture.texture);
				material.NormalTexture.Texture.TexCoordIndex = gltfMat.normal_texture.texcoord;
				material.NormalTexture.Scale = gltfMat.normal_texture.scale;
				ConvertTextureTransform(&gltfMat.normal_texture, ref material.NormalTexture.Texture);
			}

			// Occlusion texture
			if (gltfMat.occlusion_texture.texture != null)
			{
				material.OcclusionTexture.Texture.TextureIndex = (int32)cgltf_texture_index(data, gltfMat.occlusion_texture.texture);
				material.OcclusionTexture.Texture.TexCoordIndex = gltfMat.occlusion_texture.texcoord;
				material.OcclusionTexture.Strength = gltfMat.occlusion_texture.scale;
				ConvertTextureTransform(&gltfMat.occlusion_texture, ref material.OcclusionTexture.Texture);
			}

			// Emissive texture
			if (gltfMat.emissive_texture.texture != null)
			{
				material.EmissiveTexture.TextureIndex = (int32)cgltf_texture_index(data, gltfMat.emissive_texture.texture);
				material.EmissiveTexture.TexCoordIndex = gltfMat.emissive_texture.texcoord;
				ConvertTextureTransform(&gltfMat.emissive_texture, ref material.EmissiveTexture);
			}

			// Emissive factor
			material.EmissiveFactor = Vector3(
				gltfMat.emissive_factor[0],
				gltfMat.emissive_factor[1],
				gltfMat.emissive_factor[2]
			);

			// Alpha mode
			material.AlphaMode = ConvertAlphaMode(gltfMat.alpha_mode);
			material.AlphaCutoff = gltfMat.alpha_cutoff;
			material.DoubleSided = gltfMat.double_sided != 0;

			model.AddMaterial(material);
		}
	}

	private void ConvertTextureTransform(cgltf_texture_view* view, ref TextureInfo info)
	{
		if (view.has_transform != 0)
		{
			info.Offset = Vector2(view.transform.offset[0], view.transform.offset[1]);
			info.Scale = Vector2(view.transform.scale[0], view.transform.scale[1]);
			info.Rotation = view.transform.rotation;

			if (view.transform.has_texcoord != 0)
				info.TexCoordIndex = view.transform.texcoord;
		}
	}

	private AlphaMode ConvertAlphaMode(cgltf_alpha_mode mode)
	{
		switch (mode)
		{
		case .cgltf_alpha_mode_opaque: return .Opaque;
		case .cgltf_alpha_mode_mask: return .Mask;
		case .cgltf_alpha_mode_blend: return .Blend;
		default: return .Opaque;
		}
	}

	private void ConvertMeshes(cgltf_data* data, Model model)
	{
		for (int i = 0; i < (int)data.meshes_count; i++)
		{
			let gltfMesh = &data.meshes[i];
			let mesh = new Mesh();

			if (gltfMesh.name != null)
				mesh.Name = new String(gltfMesh.name);

			// Convert primitives
			for (int p = 0; p < (int)gltfMesh.primitives_count; p++)
			{
				let gltfPrim = &gltfMesh.primitives[p];
				let primitive = new MeshPrimitive();

				primitive.PrimitiveType = ConvertPrimitiveType(gltfPrim.type);

				// Get material index
				if (gltfPrim.material != null)
					primitive.MaterialIndex = (int32)cgltf_material_index(data, gltfPrim.material);

				// Find vertex count from position accessor
				int vertexCount = 0;
				for (int a = 0; a < (int)gltfPrim.attributes_count; a++)
				{
					if (gltfPrim.attributes[a].type == .cgltf_attribute_type_position)
					{
						vertexCount = (int)gltfPrim.attributes[a].data.count;
						break;
					}
				}

				// Initialize vertices
				primitive.Vertices.Reserve(vertexCount);
				for (int v = 0; v < vertexCount; v++)
					primitive.Vertices.Add(Vertex());

				// Read vertex attributes
				for (int a = 0; a < (int)gltfPrim.attributes_count; a++)
				{
					let attr = &gltfPrim.attributes[a];
					ReadVertexAttribute(attr, primitive.Vertices);
				}

				// Read indices
				if (gltfPrim.indices != null)
				{
					let indexCount = (int)gltfPrim.indices.count;
					primitive.Indices.Reserve(indexCount);

					for (int idx = 0; idx < indexCount; idx++)
					{
						let index = (uint32)cgltf_accessor_read_index(gltfPrim.indices, (.)idx);
						primitive.Indices.Add(index);
					}
				}

				mesh.Primitives.Add(primitive);
			}

			model.AddMesh(mesh);
		}
	}

	private void ReadVertexAttribute(cgltf_attribute* attr, List<Vertex> vertices)
	{
		let accessor = attr.data;
		if (accessor == null)
			return;

		let count = (int)accessor.count;
		float[16] floatData = .();
		uint32[4] uintData = .();

		for (int i = 0; i < count && i < vertices.Count; i++)
		{
			switch (attr.type)
			{
			case .cgltf_attribute_type_position:
				if (cgltf_accessor_read_float(accessor, (.)i, &floatData[0], 3) != 0)
					vertices[i].Position = Vector3(floatData[0], floatData[1], floatData[2]);

			case .cgltf_attribute_type_normal:
				if (cgltf_accessor_read_float(accessor, (.)i, &floatData[0], 3) != 0)
					vertices[i].Normal = Vector3(floatData[0], floatData[1], floatData[2]);

			case .cgltf_attribute_type_tangent:
				if (cgltf_accessor_read_float(accessor, (.)i, &floatData[0], 4) != 0)
					vertices[i].Tangent = Vector4(floatData[0], floatData[1], floatData[2], floatData[3]);

			case .cgltf_attribute_type_texcoord:
				if (cgltf_accessor_read_float(accessor, (.)i, &floatData[0], 2) != 0)
				{
					if (attr.index == 0)
						vertices[i].TexCoord0 = Vector2(floatData[0], floatData[1]);
					else if (attr.index == 1)
						vertices[i].TexCoord1 = Vector2(floatData[0], floatData[1]);
				}

			case .cgltf_attribute_type_color:
				if (accessor.type == .cgltf_type_vec4)
				{
					if (cgltf_accessor_read_float(accessor, (.)i, &floatData[0], 4) != 0)
						vertices[i].Color = Vector4(floatData[0], floatData[1], floatData[2], floatData[3]);
				}
				else if (accessor.type == .cgltf_type_vec3)
				{
					if (cgltf_accessor_read_float(accessor, (.)i, &floatData[0], 3) != 0)
						vertices[i].Color = Vector4(floatData[0], floatData[1], floatData[2], 1.0f);
				}

			case .cgltf_attribute_type_joints:
				if (cgltf_accessor_read_uint(accessor, (.)i, &uintData[0], 4) != 0)
				{
					vertices[i].Joints[0] = (uint16)uintData[0];
					vertices[i].Joints[1] = (uint16)uintData[1];
					vertices[i].Joints[2] = (uint16)uintData[2];
					vertices[i].Joints[3] = (uint16)uintData[3];
				}

			case .cgltf_attribute_type_weights:
				if (cgltf_accessor_read_float(accessor, (.)i, &floatData[0], 4) != 0)
					vertices[i].Weights = Vector4(floatData[0], floatData[1], floatData[2], floatData[3]);

			default:
				break;
			}
		}
	}

	private PrimitiveType ConvertPrimitiveType(cgltf_primitive_type type)
	{
		switch (type)
		{
		case .cgltf_primitive_type_points: return .Points;
		case .cgltf_primitive_type_lines: return .Lines;
		case .cgltf_primitive_type_line_loop: return .LineLoop;
		case .cgltf_primitive_type_line_strip: return .LineStrip;
		case .cgltf_primitive_type_triangles: return .Triangles;
		case .cgltf_primitive_type_triangle_strip: return .TriangleStrip;
		case .cgltf_primitive_type_triangle_fan: return .TriangleFan;
		default: return .Triangles;
		}
	}

	private void ConvertNodes(cgltf_data* data, Model model)
	{
		// First pass: create all nodes
		for (int i = 0; i < (int)data.nodes_count; i++)
		{
			let gltfNode = &data.nodes[i];
			let node = new Node();

			if (gltfNode.name != null)
				node.Name = new String(gltfNode.name);

			// Transform
			if (gltfNode.has_matrix != 0)
			{
				// Decompose matrix to TRS (simplified - just store TRS if available)
				// For now, use the TRS values if present
			}

			if (gltfNode.has_translation != 0)
				node.Translation = Vector3(gltfNode.translation[0], gltfNode.translation[1], gltfNode.translation[2]);

			if (gltfNode.has_rotation != 0)
				node.Rotation = Quaternion(gltfNode.rotation[0], gltfNode.rotation[1], gltfNode.rotation[2], gltfNode.rotation[3]);

			if (gltfNode.has_scale != 0)
				node.Scale = Vector3(gltfNode.scale[0], gltfNode.scale[1], gltfNode.scale[2]);

			// Mesh reference
			if (gltfNode.mesh != null)
				node.MeshIndex = (int32)cgltf_mesh_index(data, gltfNode.mesh);

			// Skin reference
			if (gltfNode.skin != null)
				node.SkinIndex = (int32)cgltf_skin_index(data, gltfNode.skin);

			// Camera reference
			if (gltfNode.camera != null)
				node.CameraIndex = (int32)cgltf_camera_index(data, gltfNode.camera);

			// Morph target weights
			if (gltfNode.weights_count > 0)
			{
				node.Weights = new List<float>();
				for (int w = 0; w < (int)gltfNode.weights_count; w++)
					node.Weights.Add(gltfNode.weights[w]);
			}

			model.AddNode(node);
		}

		// Second pass: set up parent-child relationships
		for (int i = 0; i < (int)data.nodes_count; i++)
		{
			let gltfNode = &data.nodes[i];
			let node = model.Nodes[i];

			// Set parent
			if (gltfNode.parent != null)
			{
				let parentIndex = (int)cgltf_node_index(data, gltfNode.parent);
				node.Parent = model.Nodes[parentIndex];
			}

			// Add children (children are already created, just add references)
			for (int c = 0; c < (int)gltfNode.children_count; c++)
			{
				let childIndex = (int)cgltf_node_index(data, gltfNode.children[c]);
				// Note: We don't use AddChild here because the child is already owned by Model.Nodes
				// Just add the reference without ownership transfer
				node.Children.Add(model.Nodes[childIndex]);
			}
		}
	}

	private void ConvertSkins(cgltf_data* data, Model model)
	{
		for (int i = 0; i < (int)data.skins_count; i++)
		{
			let gltfSkin = &data.skins[i];
			let skin = new Skin();

			if (gltfSkin.name != null)
				skin.Name = new String(gltfSkin.name);

			// Skeleton root
			if (gltfSkin.skeleton != null)
				skin.SkeletonRootIndex = (int32)cgltf_node_index(data, gltfSkin.skeleton);

			// Joint indices
			for (int j = 0; j < (int)gltfSkin.joints_count; j++)
			{
				let jointIndex = (int32)cgltf_node_index(data, gltfSkin.joints[j]);
				skin.JointIndices.Add(jointIndex);
			}

			// Inverse bind matrices
			if (gltfSkin.inverse_bind_matrices != null)
			{
				let accessor = gltfSkin.inverse_bind_matrices;
				float[16] matrixData = .();

				for (int j = 0; j < (int)accessor.count; j++)
				{
					if (cgltf_accessor_read_float(accessor, (.)j, &matrixData[0], 16) != 0)
					{
						// GLTF uses column-major matrices, convert to our Matrix format
						let matrix = Matrix(
							matrixData[0], matrixData[1], matrixData[2], matrixData[3],
							matrixData[4], matrixData[5], matrixData[6], matrixData[7],
							matrixData[8], matrixData[9], matrixData[10], matrixData[11],
							matrixData[12], matrixData[13], matrixData[14], matrixData[15]
						);
						skin.InverseBindMatrices.Add(matrix);
					}
				}
			}

			model.AddSkin(skin);
		}
	}

	private void ConvertAnimations(cgltf_data* data, Model model)
	{
		for (int i = 0; i < (int)data.animations_count; i++)
		{
			let gltfAnim = &data.animations[i];
			let animation = new Animation();

			if (gltfAnim.name != null)
				animation.Name = new String(gltfAnim.name);

			// Convert channels
			for (int c = 0; c < (int)gltfAnim.channels_count; c++)
			{
				let gltfChannel = &gltfAnim.channels[c];

				if (gltfChannel.target_node == null)
					continue;

				let channel = new AnimationChannel();
				channel.TargetNodeIndex = (int32)cgltf_node_index(data, gltfChannel.target_node);
				channel.TargetPath = ConvertAnimationPath(gltfChannel.target_path);

				// Convert sampler
				if (gltfChannel.sampler != null)
				{
					let gltfSampler = gltfChannel.sampler;
					channel.Sampler.Interpolation = ConvertInterpolation(gltfSampler.interpolation);

					// Read input (keyframe times)
					if (gltfSampler.input != null)
					{
						let inputCount = (int)gltfSampler.input.count;
						float timeValue = 0;
						for (int t = 0; t < inputCount; t++)
						{
							if (cgltf_accessor_read_float(gltfSampler.input, (.)t, &timeValue, 1) != 0)
								channel.Sampler.KeyframeTimes.Add(timeValue);
						}
					}

					// Read output (keyframe values)
					if (gltfSampler.output != null)
					{
						let outputAccessor = gltfSampler.output;
						let outputCount = (int)outputAccessor.count;
						let componentCount = (int)cgltf_num_components(outputAccessor.type);
						float[16] values = .();

						for (int v = 0; v < outputCount; v++)
						{
							if (cgltf_accessor_read_float(outputAccessor, (.)v, &values[0], (.)componentCount) != 0)
							{
								for (int comp = 0; comp < componentCount; comp++)
									channel.Sampler.KeyframeValues.Add(values[comp]);
							}
						}
					}
				}

				animation.Channels.Add(channel);
			}

			model.AddAnimation(animation);
		}
	}

	private AnimationPath ConvertAnimationPath(cgltf_animation_path_type path)
	{
		switch (path)
		{
		case .cgltf_animation_path_type_translation: return .Translation;
		case .cgltf_animation_path_type_rotation: return .Rotation;
		case .cgltf_animation_path_type_scale: return .Scale;
		case .cgltf_animation_path_type_weights: return .Weights;
		default: return .Translation;
		}
	}

	private InterpolationType ConvertInterpolation(cgltf_interpolation_type interp)
	{
		switch (interp)
		{
		case .cgltf_interpolation_type_linear: return .Linear;
		case .cgltf_interpolation_type_step: return .Step;
		case .cgltf_interpolation_type_cubic_spline: return .CubicSpline;
		default: return .Linear;
		}
	}

	public override bool Write(StringView path, Model model)
	{
		// GLTF export not implemented yet
		return false;
	}
}
