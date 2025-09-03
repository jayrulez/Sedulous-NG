using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.Engine.Renderer.RHI.RenderGraph
{
	public enum RenderGraphResourceType
	{
		Texture,
		Buffer
	}

	public enum RenderGraphResourceFlags : uint8
	{
		None = 0,
		Imported = 1 << 0,
		Transient = 1 << 1,
		History = 1 << 2,
		ForceNonTransient = 1 << 3
	}

	public struct RenderGraphResourceHandle : IHashable
	{
		public uint32 Index;
		public uint32 Version;

		public this(uint32 index, uint32 version)
		{
			Index = index;
			Version = version;
		}

		public bool IsValid => Index != uint32.MaxValue;

		public const RenderGraphResourceHandle Invalid = .(uint32.MaxValue, 0);

		public int GetHashCode()
		{
			return ((int)Index << 16) | (int)Version;
		}

		public static bool operator==(RenderGraphResourceHandle lhs, RenderGraphResourceHandle rhs)
		{
			return lhs.Index == rhs.Index && lhs.Version == rhs.Version;
		}

		public static bool operator!=(RenderGraphResourceHandle lhs, RenderGraphResourceHandle rhs)
		{
			return !(lhs == rhs);
		}
	}

	public abstract class RenderGraphResource
	{
		public RenderGraphResourceHandle Handle { get; protected set; }
		public StringView Name { get; protected set; }
		public RenderGraphResourceType ResourceType { get; protected set; }
		public RenderGraphResourceFlags Flags { get; set; }
		public bool IsImported => Flags.HasFlag(.Imported);
		public bool IsTransient => Flags.HasFlag(.Transient) && !Flags.HasFlag(.ForceNonTransient);
		
		protected uint32 mRefCount = 0;
		protected uint32 mFirstPass = uint32.MaxValue;
		protected uint32 mLastPass = 0;

		public this(RenderGraphResourceHandle handle, StringView name, RenderGraphResourceType type)
		{
			Handle = handle;
			Name = name;
			ResourceType = type;
			Flags = .None;
		}

		public void AddRef(uint32 passIndex)
		{
			mRefCount++;
			mFirstPass = Math.Min(mFirstPass, passIndex);
			mLastPass = Math.Max(mLastPass, passIndex);
		}

		public void Release(uint32 passIndex)
		{
			if (mRefCount > 0)
				mRefCount--;
		}

		public bool IsUsedByPass(uint32 passIndex)
		{
			return passIndex >= mFirstPass && passIndex <= mLastPass;
		}

		public uint32 FirstPass => mFirstPass;
		public uint32 LastPass => mLastPass;
		public uint32 RefCount => mRefCount;

		public abstract void CreateResource(GraphicsContext context, ResourceFactory factory);
		public abstract void DestroyResource();
	}

	public class RenderGraphTextureResource : RenderGraphResource
	{
		public TextureDescription Description { get; set; }
		public Texture Texture { get; private set; }
		public Texture ImportedTexture { get; set; }

		public this(RenderGraphResourceHandle handle, StringView name, TextureDescription desc) 
			: base(handle, name, .Texture)
		{
			Description = desc;
		}

		public override void CreateResource(GraphicsContext context, ResourceFactory factory)
		{
			if (IsImported)
			{
				Texture = ImportedTexture;
			}
			else if (Texture == null)
			{
				Texture = factory.CreateTexture(Description);
			}
		}

		public override void DestroyResource()
		{
			if (!IsImported && Texture != null)
			{
				Texture?.Dispose();
				delete Texture;
				Texture = null;
			}
		}
	}

	public class RenderGraphBufferResource : RenderGraphResource
	{
		public BufferDescription Description { get; set; }
		public Buffer Buffer { get; private set; }
		public Buffer ImportedBuffer { get; set; }

		public this(RenderGraphResourceHandle handle, StringView name, BufferDescription desc) 
			: base(handle, name, .Buffer)
		{
			Description = desc;
		}

		public override void CreateResource(GraphicsContext context, ResourceFactory factory)
		{
			if (IsImported)
			{
				Buffer = ImportedBuffer;
			}
			else if (Buffer == null)
			{
				Buffer = factory.CreateBuffer(Description);
			}
		}

		public override void DestroyResource()
		{
			if (!IsImported && Buffer != null)
			{
				Buffer?.Dispose();
				delete Buffer;
				Buffer = null;
			}
		}
	}

}