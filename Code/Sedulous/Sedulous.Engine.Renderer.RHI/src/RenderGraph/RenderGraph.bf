using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.Engine.Renderer.RHI.RenderGraph
{
	public class RenderGraph
	{
		private GraphicsContext mContext;
		private ResourceFactory mResourceFactory;
		
		private List<RenderGraphPass> mPasses = new .() ~ delete _;
		private List<RenderGraphResource> mResources = new .() ~ delete _;
		private Dictionary<RenderGraphResourceHandle, RenderGraphResource> mResourceMap = new .() ~ delete _;
		private Dictionary<RenderGraphPassHandle, RenderGraphPass> mPassMap = new .() ~ delete _;
		
		private List<RenderGraphPass> mExecutionOrder = new .() ~ delete _;
		private RenderGraphContext mRenderContext ~ delete _;
		private RenderGraphBuilder mBuilder ~ delete _;
		
		private uint32 mNextResourceIndex = 0;
		private uint32 mNextResourceVersion = 0;
		private uint32 mNextPassIndex = 0;
		
		private StringView mName;
		private bool mCompiled = false;

		public this(StringView name, GraphicsContext context, ResourceFactory resourceFactory)
		{
			mName = name;
			mContext = context;
			mResourceFactory = resourceFactory;
			mRenderContext = new RenderGraphContext(this);
			mBuilder = new RenderGraphBuilder();
		}

		public RenderGraphResourceHandle CreateTexture(StringView name, TextureDescription desc, RenderGraphResourceFlags flags = .None)
		{
			let handle = RenderGraphResourceHandle(mNextResourceIndex++, mNextResourceVersion++);
			let resource = new RenderGraphTextureResource(handle, name, desc);
			resource.Flags = flags;
			
			mResources.Add(resource);
			mResourceMap[handle] = resource;
			
			return handle;
		}

		public RenderGraphResourceHandle ImportTexture(StringView name, Texture texture)
		{
			let desc = texture.Description;
			let handle = RenderGraphResourceHandle(mNextResourceIndex++, mNextResourceVersion++);
			let resource = new RenderGraphTextureResource(handle, name, desc);
			resource.Flags = .Imported;
			resource.ImportedTexture = texture;
			
			mResources.Add(resource);
			mResourceMap[handle] = resource;
			
			return handle;
		}

		public RenderGraphResourceHandle CreateBuffer(StringView name, BufferDescription desc, RenderGraphResourceFlags flags = .None)
		{
			let handle = RenderGraphResourceHandle(mNextResourceIndex++, mNextResourceVersion++);
			let resource = new RenderGraphBufferResource(handle, name, desc);
			resource.Flags = flags;
			
			mResources.Add(resource);
			mResourceMap[handle] = resource;
			
			return handle;
		}

		public RenderGraphResourceHandle ImportBuffer(StringView name, Buffer buffer)
		{
			let desc = buffer.Description;
			let handle = RenderGraphResourceHandle(mNextResourceIndex++, mNextResourceVersion++);
			let resource = new RenderGraphBufferResource(handle, name, desc);
			resource.Flags = .Imported;
			resource.ImportedBuffer = buffer;
			
			mResources.Add(resource);
			mResourceMap[handle] = resource;
			
			return handle;
		}


		public T AddPass<T>(StringView name, RenderFunc renderFunc) where T : RenderGraphPass
		{
			let handle = RenderGraphPassHandle(mNextPassIndex++);
			T pass = null;
			
			if (typeof(T) == typeof(RenderGraphGraphicsPass))
			{
				pass = new RenderGraphGraphicsPass(handle, name) as T;
			}
			else if (typeof(T) == typeof(RenderGraphComputePass))
			{
				pass = new RenderGraphComputePass(handle, name) as T;
			}
			else if (typeof(T) == typeof(RenderGraphCopyPass))
			{
				pass = new RenderGraphCopyPass(handle, name) as T;
			}
			
			if (pass != null)
			{
				pass.SetRenderFunc(renderFunc);
				mPasses.Add(pass);
				mPassMap[handle] = pass;
			}
			
			mCompiled = false;
			return pass;
		}

		public void Compile()
		{
			mExecutionOrder.Clear();

			// Build dependency graph and perform topological sort
			List<RenderGraphPass> sorted = scope .();
			HashSet<RenderGraphPass> visited = scope .();
			HashSet<RenderGraphPass> visiting = scope .();

			for (let pass in mPasses)
			{
				if (!visited.Contains(pass))
				{
					TopologicalSort(pass, visited, visiting, sorted);
				}
			}

			// The topological sort already produces correct order (dependencies first)
			// No reversal needed - dependencies are visited and added before dependents
			for (let pass in sorted)
			{
				mExecutionOrder.Add(pass);
			}

			// Perform resource lifetime analysis
			AnalyzeResourceLifetimes();

			// Cull unused passes
			CullUnusedPasses();

			mCompiled = true;
		}

		private void TopologicalSort(RenderGraphPass pass, HashSet<RenderGraphPass> visited, HashSet<RenderGraphPass> visiting, List<RenderGraphPass> sorted)
		{
			if (visited.Contains(pass))
				return;
			
			if (visiting.Contains(pass))
			{
				// Circular dependency detected
				Runtime.FatalError(scope $"Circular dependency detected in render graph at pass: {pass.Name}");
			}
			
			visiting.Add(pass);
			
			// Visit dependencies first
			for (let depHandle in pass.Dependencies)
			{
				if (mPassMap.TryGetValue(depHandle, let depPass))
				{
					TopologicalSort(depPass, visited, visiting, sorted);
				}
			}
			
			visiting.Remove(pass);
			visited.Add(pass);
			sorted.Add(pass);
		}

		private void AnalyzeResourceLifetimes()
		{
			// Reset all resource lifetimes
			for (let resource in mResources)
			{
				resource.[Friend]mRefCount = 0;
				resource.[Friend]mFirstPass = uint32.MaxValue;
				resource.[Friend]mLastPass = 0;
			}
			
			// Analyze each pass in execution order
			for (int passIndex = 0; passIndex < mExecutionOrder.Count; passIndex++)
			{
				let pass = mExecutionOrder[passIndex];
				
				// Mark input resources
				for (let resourceHandle in pass.InputResources)
				{
					if (mResourceMap.TryGetValue(resourceHandle, let resource))
					{
						resource.AddRef((uint32)passIndex);
					}
				}
				
				// Mark output resources
				for (let resourceHandle in pass.OutputResources)
				{
					if (mResourceMap.TryGetValue(resourceHandle, let resource))
					{
						resource.AddRef((uint32)passIndex);
					}
				}
			}
		}

		private void CullUnusedPasses()
		{
			// Start from output passes and mark all dependencies as used
			HashSet<RenderGraphPass> usedPasses = scope .();
			
			// Find passes that write to non-transient resources or have side effects
			for (let pass in mPasses)
			{
				bool hasOutput = false;
				
				// Check if any output is non-transient or imported
				for (let resourceHandle in pass.OutputResources)
				{
					if (mResourceMap.TryGetValue(resourceHandle, let resource))
					{
						if (!resource.IsTransient || resource.IsImported)
						{
							hasOutput = true;
							break;
						}
					}
				}
				
				// Check for explicit disable culling flag
				if (pass.Flags.HasFlag(.DisableCulling))
				{
					hasOutput = true;
				}
				
				if (hasOutput)
				{
					MarkPassAndDependencies(pass, usedPasses);
				}
			}
			
			// Cull passes not in used set
			for (let pass in mPasses)
			{
				pass.SetCulled(!usedPasses.Contains(pass));
			}
		}

		private void MarkPassAndDependencies(RenderGraphPass pass, HashSet<RenderGraphPass> usedPasses)
		{
			if (usedPasses.Contains(pass))
				return;
			
			usedPasses.Add(pass);
			
			// Mark all dependencies as used
			for (let depHandle in pass.Dependencies)
			{
				if (mPassMap.TryGetValue(depHandle, let depPass))
				{
					MarkPassAndDependencies(depPass, usedPasses);
				}
			}
			
			// Mark passes that produce our input resources
			for (let inputHandle in pass.InputResources)
			{
				for (let otherPass in mPasses)
				{
					if (otherPass.OutputResources.Contains(inputHandle))
					{
						MarkPassAndDependencies(otherPass, usedPasses);
					}
				}
			}
		}

		public void Execute(CommandBuffer cmd)
		{
			if (!mCompiled)
			{
				Compile();
			}
			
			// Create resources
			AllocateResources();
			
			// Update render context resource map
			mRenderContext.SetResourceMap(mResourceMap);
			
			// Execute passes in order
			for (int i = 0; i < mExecutionOrder.Count; i++)
			{
				let pass = mExecutionOrder[i];
				
				if (!pass.IsCulled)
				{
					mRenderContext.SetCurrentPass(pass.Handle);
					
					// Begin render pass if graphics pass
					if (pass.PassType == .Graphics)
					{
						let graphicsPass = pass as RenderGraphGraphicsPass;
						cmd.BeginRenderPass(graphicsPass.RenderPassDesc);
					}
					
					// Execute pass
					pass.Execute(cmd, mRenderContext);
					
					// End render pass if graphics pass
					if (pass.PassType == .Graphics)
					{
						cmd.EndRenderPass();
					}
				}
				
				// Release transient resources after last use
				ReleaseTransientResources((uint32)i);
			}
		}

		private void AllocateResources()
		{
			for (let resource in mResources)
			{
				if (resource.RefCount > 0 && !resource.IsImported)
				{
					resource.CreateResource(mContext, mResourceFactory);
				}
			}
		}

		private void ReleaseTransientResources(uint32 passIndex)
		{
			for (let resource in mResources)
			{
				if (resource.IsTransient && resource.LastPass == passIndex)
				{
					resource.DestroyResource();
				}
			}
		}

		public void Reset()
		{
			// Destroy all non-imported resources
			for (let resource in mResources)
			{
				if (!resource.IsImported)
				{
					resource.DestroyResource();
				}
				delete resource;
			}
			
			// Clear passes
			for (let pass in mPasses)
			{
				delete pass;
			}
			
			mPasses.Clear();
			mResources.Clear();
			mResourceMap.Clear();
			mPassMap.Clear();
			mExecutionOrder.Clear();
			
			mNextResourceIndex = 0;
			mNextResourceVersion = 0;
			mNextPassIndex = 0;
			mCompiled = false;
		}

		public GraphicsContext GraphicsContext => mContext;
		public ResourceFactory ResourceFactory => mResourceFactory;
	}
}