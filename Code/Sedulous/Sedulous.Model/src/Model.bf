using System;
using System.Collections;

namespace Sedulous.Model;

/// Root container for a 3D model with meshes, materials, animations, and scene hierarchy
class Model
{
	/// Model name (optional)
	public String Name ~ delete _;

	/// All meshes in this model
	public List<Mesh> Meshes = new .() ~ DeleteContainerAndItems!(_);

	/// All materials in this model
	public List<Material> Materials = new .() ~ DeleteContainerAndItems!(_);

	/// All textures in this model
	public List<Texture> Textures = new .() ~ DeleteContainerAndItems!(_);

	/// All nodes in the scene hierarchy (flat list)
	public List<Node> Nodes = new .() ~ DeleteContainerAndItems!(_);

	/// Indices of root-level nodes (nodes without parents)
	public List<int32> RootNodeIndices = new .() ~ delete _;

	/// All skins (skeletal bindings) in this model
	public List<Skin> Skins = new .() ~ DeleteContainerAndItems!(_);

	/// All animations in this model
	public List<Animation> Animations = new .() ~ DeleteContainerAndItems!(_);

	public this()
	{
	}

	public this(String name)
	{
		Name = new String(name);
	}

	/// Returns the total mesh count
	public int MeshCount => Meshes.Count;

	/// Returns the total material count
	public int MaterialCount => Materials.Count;

	/// Returns the total texture count
	public int TextureCount => Textures.Count;

	/// Returns the total node count
	public int NodeCount => Nodes.Count;

	/// Returns the total skin count
	public int SkinCount => Skins.Count;

	/// Returns the total animation count
	public int AnimationCount => Animations.Count;

	/// Adds a mesh and returns its index
	public int32 AddMesh(Mesh mesh)
	{
		let index = (int32)Meshes.Count;
		Meshes.Add(mesh);
		return index;
	}

	/// Adds a material and returns its index
	public int32 AddMaterial(Material material)
	{
		let index = (int32)Materials.Count;
		Materials.Add(material);
		return index;
	}

	/// Adds a texture and returns its index
	public int32 AddTexture(Texture texture)
	{
		let index = (int32)Textures.Count;
		Textures.Add(texture);
		return index;
	}

	/// Adds a node and returns its index
	public int32 AddNode(Node node)
	{
		let index = (int32)Nodes.Count;
		Nodes.Add(node);
		return index;
	}

	/// Adds a root node index
	public void AddRootNodeIndex(int32 index)
	{
		RootNodeIndices.Add(index);
	}

	/// Adds a skin and returns its index
	public int32 AddSkin(Skin skin)
	{
		let index = (int32)Skins.Count;
		Skins.Add(skin);
		return index;
	}

	/// Adds an animation and returns its index
	public int32 AddAnimation(Animation animation)
	{
		let index = (int32)Animations.Count;
		Animations.Add(animation);
		return index;
	}

	/// Gets a mesh by index
	public Mesh GetMesh(int32 index)
	{
		if (index >= 0 && index < Meshes.Count)
			return Meshes[index];
		return null;
	}

	/// Gets a material by index
	public Material GetMaterial(int32 index)
	{
		if (index >= 0 && index < Materials.Count)
			return Materials[index];
		return null;
	}

	/// Gets a texture by index
	public Texture GetTexture(int32 index)
	{
		if (index >= 0 && index < Textures.Count)
			return Textures[index];
		return null;
	}

	/// Gets a node by index
	public Node GetNode(int32 index)
	{
		if (index >= 0 && index < Nodes.Count)
			return Nodes[index];
		return null;
	}

	/// Gets a skin by index
	public Skin GetSkin(int32 index)
	{
		if (index >= 0 && index < Skins.Count)
			return Skins[index];
		return null;
	}

	/// Gets an animation by index
	public Animation GetAnimation(int32 index)
	{
		if (index >= 0 && index < Animations.Count)
			return Animations[index];
		return null;
	}

	/// Finds a node by name (returns first match)
	public Node FindNodeByName(StringView name)
	{
		for (let node in Nodes)
		{
			if (node.Name != null && node.Name == name)
				return node;
		}
		return null;
	}

	/// Finds an animation by name (returns first match)
	public Animation FindAnimationByName(StringView name)
	{
		for (let anim in Animations)
		{
			if (anim.Name != null && anim.Name == name)
				return anim;
		}
		return null;
	}
}
