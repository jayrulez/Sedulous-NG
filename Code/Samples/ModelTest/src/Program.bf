using System;
using System.IO;
using Sedulous.Model;
using Sedulous.Model.Formats.GLTF;
using System.Diagnostics;

namespace ModelTest;

class Program
{
	public static void Main()
	{
		let processor = scope GLTFModelProcessor();

		// Get the path to the sample models
		let cwd = scope String();
		Directory.GetCurrentDirectory(cwd);

		let basePath = scope String();
		basePath.Append(cwd);
		basePath.Append("\\glTF-Sample-Assets\\Models");

		Debug.WriteLine("=== Sedulous Model Library Test ===\n");

		// Test various models - use GLB (binary) format for reliability
		TestModel(processor, basePath, "Box", "glTF-Binary/Box.glb");
		TestModel(processor, basePath, "BoxTextured", "glTF-Binary/BoxTextured.glb");
		TestModel(processor, basePath, "BoxAnimated", "glTF-Binary/BoxAnimated.glb");
		TestModel(processor, basePath, "Avocado", "glTF-Binary/Avocado.glb");
		TestModel(processor, basePath, "CesiumMan", "glTF-Binary/CesiumMan.glb");
		TestModel(processor, basePath, "BrainStem", "glTF-Binary/BrainStem.glb");
		TestModel(processor, basePath, "Fox", "glTF-Binary/Fox.glb");

		Debug.WriteLine("\n=== Testing Different Image Embedding Methods ===\n");

		// Test glTF with external image files
		TestModel(processor, basePath, "BoxTextured", "glTF/BoxTextured.gltf");

		// Test glTF-Embedded with base64 encoded images
		TestModel(processor, basePath, "BoxTextured", "glTF-Embedded/BoxTextured.gltf");

		Debug.WriteLine("\n=== Test Complete ===");
	}

	static void TestModel(GLTFModelProcessor processor, StringView basePath, StringView modelName, StringView relativePath)
	{
		let fullPath = scope String();
		fullPath.Append(basePath);
		fullPath.Append("\\");
		fullPath.Append(modelName);
		fullPath.Append("\\");
		fullPath.Append(relativePath);
		fullPath.Replace('/', '\\'); // Normalize to Windows paths

		Debug.WriteLine(scope $"--- Loading: {modelName} ---");
		Debug.WriteLine(scope $"Path: {fullPath}");

		if (!File.Exists(fullPath))
		{
			Debug.WriteLine("  File not found, skipping.\n");
			return;
		}

		let model = processor.Read(fullPath);
		if (model == null)
		{
			Debug.WriteLine("  Failed to load model!\n");
			return;
		}
		defer delete model;

		PrintModelInfo(model);
		Debug.WriteLine("");
	}

	static void PrintModelInfo(Model model)
	{
		Debug.WriteLine(scope $"  Meshes: {model.MeshCount}");
		Debug.WriteLine(scope $"  Materials: {model.MaterialCount}");
		Debug.WriteLine(scope $"  Textures: {model.TextureCount}");
		Debug.WriteLine(scope $"  Nodes: {model.NodeCount}");
		Debug.WriteLine(scope $"  Skins: {model.SkinCount}");
		Debug.WriteLine(scope $"  Animations: {model.AnimationCount}");

		// Print mesh details
		if (model.MeshCount > 0)
		{
			Debug.WriteLine("\n  Mesh Details:");
			for (int i = 0; i < model.MeshCount; i++)
			{
				let mesh = model.Meshes[i];
				let name = mesh.Name != null ? mesh.Name : "(unnamed)";
				Debug.WriteLine(scope $"    [{i}] \"{name}\": {mesh.Primitives.Count} primitive(s), {mesh.TotalVertexCount} vertices, {mesh.TotalIndexCount} indices");
			}
		}

		// Print material details
		if (model.MaterialCount > 0)
		{
			Debug.WriteLine("\n  Material Details:");
			for (int i = 0; i < model.MaterialCount; i++)
			{
				let mat = model.Materials[i];
				let name = mat.Name != null ? mat.Name : "(unnamed)";
				let hasBaseColor = mat.BaseColorTexture.HasTexture ? "yes" : "no";
				let hasNormal = mat.NormalTexture.Texture.HasTexture ? "yes" : "no";
				Debug.WriteLine(scope $"    [{i}] \"{name}\": baseColor={hasBaseColor}, normal={hasNormal}, metallic={mat.MetallicFactor:F2}, roughness={mat.RoughnessFactor:F2}");
			}
		}

		// Print texture details
		if (model.TextureCount > 0)
		{
			Debug.WriteLine("\n  Texture Details:");
			for (int i = 0; i < model.TextureCount; i++)
			{
				let tex = model.Textures[i];
				let name = tex.Name != null ? tex.Name : "(unnamed)";
				let hasImage = tex.ImageData != null ? "loaded" : "not loaded";
				let source = tex.SourceUri != null ? tex.SourceUri : "(embedded)";
				Debug.WriteLine(scope $"    [{i}] \"{name}\": {hasImage}, source={source}");
			}
		}

		// Print node hierarchy
		if (model.NodeCount > 0)
		{
			Debug.WriteLine("\n  Node Hierarchy:");
			for (let rootIdx in model.RootNodeIndices)
			{
				PrintNodeTree(model, rootIdx, 2);
			}
		}

		// Print skin details
		if (model.SkinCount > 0)
		{
			Debug.WriteLine("\n  Skin Details:");
			for (int i = 0; i < model.SkinCount; i++)
			{
				let skin = model.Skins[i];
				let name = skin.Name != null ? skin.Name : "(unnamed)";
				Debug.WriteLine(scope $"    [{i}] \"{name}\": {skin.JointCount} joints");
			}
		}

		// Print animation details
		if (model.AnimationCount > 0)
		{
			Debug.WriteLine("\n  Animation Details:");
			for (int i = 0; i < model.AnimationCount; i++)
			{
				let anim = model.Animations[i];
				let name = anim.Name != null ? anim.Name : "(unnamed)";
				Debug.WriteLine(scope $"    [{i}] \"{name}\": {anim.ChannelCount} channels, duration={anim.Duration:F2}s");
			}
		}
	}

	static void PrintNodeTree(Model model, int32 nodeIndex, int indent)
	{
		let node = model.GetNode(nodeIndex);
		if (node == null) return;

		let indentStr = scope String();
		for (int i = 0; i < indent; i++)
			indentStr.Append("  ");

		let name = node.Name != null ? node.Name : "(unnamed)";
		let meshInfo = node.HasMesh ? scope $" [mesh:{node.MeshIndex}]" : "";
		let skinInfo = node.HasSkin ? scope $" [skin:{node.SkinIndex}]" : "";

		Debug.WriteLine(scope $"{indentStr}[{nodeIndex}] \"{name}\"{meshInfo}{skinInfo}");

		// Print children (but limit recursion depth for large models)
		if (indent < 8)
		{
			for (int i = 0; i < node.Children.Count; i++)
			{
				// Find index of child in model.Nodes
				let child = node.Children[i];
				for (int j = 0; j < model.Nodes.Count; j++)
				{
					if (model.Nodes[j] == child)
					{
						PrintNodeTree(model, (int32)j, indent + 1);
						break;
					}
				}
			}
		}
		else if (node.Children.Count > 0)
		{
			Debug.WriteLine(scope $"{indentStr}  ... ({node.Children.Count} more children)");
		}
	}
}
