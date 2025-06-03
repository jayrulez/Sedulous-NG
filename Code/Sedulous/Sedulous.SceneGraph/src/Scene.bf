using System.Collections;
using System;
using Sedulous.Utilities;
namespace Sedulous.SceneGraph;

using internal Sedulous.SceneGraph;

class Scene
{
	public SceneGraphSystem SceneGraph {get; private set;}
    private readonly List<SceneModule> mSceneModules = new .() ~ delete _;
    private readonly List<Entity> mEntities = new .() ~ delete _;
    private readonly Dictionary<EntityId, Entity> mEntityLookup = new .() ~ delete _;
    
    public String Name { get; set; } = new .() ~ delete _;
    public Span<Entity> Entities => mEntities;
    public Span<SceneModule> Modules => mSceneModules;

	public this(SceneGraphSystem sceneGraph)
	{
		SceneGraph = sceneGraph;
	}

	public ~this()
	{
		for(var entity in mEntities)
		{
			//DestroyEntity(entity);
			delete entity;
		}
	}
    
    // Entity management
    public Entity CreateEntity(StringView name = "Entity")
    {
        var entity = new Entity();
        entity.Scene = this;
        entity.Name.Set(name);
        
        mEntities.Add(entity);
        mEntityLookup[entity.Id] = entity;
        
        // Notify modules first (immediate)
        for (var module in mSceneModules)
        {
            module.EntityCreated(entity);
        }

        // Publish message (may be queued)
        SceneGraph.MessageBus.Publish(new EntityCreatedMessage(entity, this));
        
        return entity;
    }
    
    public void DestroyEntity(Entity entity)
    {
        if (entity == null || entity.Scene != this)
            return;
            
        var entityId = entity.Id;
        
        // Notify modules first
        for (var module in mSceneModules)
        {
            module.EntityDestroyed(entity);
        }
        
        // Remove from collections
        mEntities.Remove(entity);
        mEntityLookup.Remove(entity.Id);
        
        // Publish message before cleanup
        SceneGraph.MessageBus.Publish(new EntityDestroyedMessage(entityId, this));
        
        // Cleanup
        entity.Scene = null;
        delete entity;
    }
    
    public Entity FindEntity(EntityId id)
    {
        return mEntityLookup.TryGetValue(id, var entity) ? entity : null;
    }
    
    public Entity FindEntity(StringView name)
    {
        for (var entity in mEntities)
        {
            if (entity.Name == name)
                return entity;
        }
        return null;
    }
    
    // Get root entities (entities without parents)
    public void GetRootEntities(List<Entity> rootEntities)
    {
        rootEntities.Clear();
        for (var entity in mEntities)
        {
            if (entity.Parent == null)
            {
                rootEntities.Add(entity);
            }
        }
    }
    
    // Module management
    public void AddModule(SceneModule module)
    {
        if (mSceneModules.Contains(module))
            return;
            
        module.Scene = this;
        mSceneModules.Add(module);
        module.Attached();
        
        // Initialize with existing entities
        for (var entity in mEntities)
        {
            module.EntityCreated(entity);
        }
    }
    
    public void RemoveModule(SceneModule module)
    {
        if (mSceneModules.Remove(module))
        {
            module.Detached();
            module.Scene = null;
        }
    }
    
    public T GetModule<T>() where T : SceneModule
    {
        for (var module in mSceneModules)
        {
            if (module is T)
                return (T)module;
        }
        return null;
    }
    
    // Event notifications
    internal void OnEntityHierarchyChanged(Entity entity)
    {
        for (var module in mSceneModules)
        {
            module.EntityHierarchyChanged(entity);
        }
    }
    
    internal void OnComponentAdded(Entity entity, IComponent component)
    {
        for (var module in mSceneModules)
        {
            module.ComponentAdded(entity, component);
        }
    }
    
    internal void OnComponentRemoved(Entity entity, IComponent component)
    {
        for (var module in mSceneModules)
        {
            module.ComponentRemoved(entity, component);
        }
    }

	private void UpdateTransforms()
    {
        // List to collect entities with changed transforms
        var changedEntities = scope List<Entity>();
        
        // If you don't have hierarchies, simple update is fine
        bool hasHierarchies = false;
        for (var entity in mEntities)
        {
            if (entity.Parent != null || entity.Children.Length > 0)
            {
                hasHierarchies = true;
                break;
            }
        }
        
        if (!hasHierarchies)
        {
            // Simple case: no hierarchies, just update all transforms
            for (var entity in mEntities)
            {
                entity.Transform.UpdateTransform();
                
                // Collect entities that changed
                if (entity.Transform.WasTransformChanged())
                {
                    changedEntities.Add(entity);
                }
            }
        }
        else
        {
            // Complex case: update in parent-to-child order
            var rootEntities = scope List<Entity>();
            GetRootEntities(rootEntities);
            
            for (var root in rootEntities)
            {
                UpdateTransformHierarchy(root, changedEntities);
            }
        }
        
        // Send messages for all changed transforms
        for (var entity in changedEntities)
        {
            SceneGraph.MessageBus.Publish(new TransformChangedMessage(entity));
            entity.Transform.ResetChangedFlag();
        }
    }

	private void UpdateTransformHierarchy(Entity entity, List<Entity> changedEntities)
	{
	    // Update this entity's transform
	    entity.Transform.UpdateTransform();
	    
	    // Collect if changed
	    if (entity.Transform.WasTransformChanged())
	    {
	        changedEntities.Add(entity);
	    }
	    
	    // Then update all children
	    for (var child in entity.Children)
	    {
	        UpdateTransformHierarchy(child, changedEntities);
	    }
	}

    // Update system
    internal void Update(Time time)
    {
		// Phase 1: Update all transforms
		UpdateTransforms();

        // Phase 2: Update modules in order
        for (var module in mSceneModules)
        {
            module.Update(time);
        }
    }
}