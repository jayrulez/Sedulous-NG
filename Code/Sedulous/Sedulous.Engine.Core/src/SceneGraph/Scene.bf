using System.Collections;
using System;
namespace Sedulous.Engine.Core.SceneGraph;

using internal Sedulous.Engine.Core.SceneGraph;

class Scene
{
    private readonly List<SceneModule> mSceneModules = new .() ~ delete _;
    private readonly List<Entity> mEntities = new .() ~ delete _;
    private readonly Dictionary<EntityId, Entity> mEntityLookup = new .() ~ delete _;
    
    public String Name { get; set; } = new .() ~ delete _;
    public Span<Entity> Entities => mEntities;
    public Span<SceneModule> Modules => mSceneModules;

    // Engine reference for events
    internal IEngine mEngine;
    
    internal void SetEngine(IEngine engine)
    {
        mEngine = engine;
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
        if (mEngine != null)
        {
            mEngine.Messages.Publish(new EntityCreatedMessage(entity, this));
        }
        
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
        if (mEngine != null)
        {
            mEngine.Messages.Publish(new EntityDestroyedMessage(entityId, this));
        }
        
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
    
    // Update system
    internal void Update(TimeSpan deltaTime)
    {
        // Update modules in order
        for (var module in mSceneModules)
        {
            //module.Update(deltaTime);
        }
    }
}