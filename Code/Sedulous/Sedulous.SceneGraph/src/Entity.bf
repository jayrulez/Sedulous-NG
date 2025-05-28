using System;
using System.Collections;
using System.Threading;
namespace Sedulous.SceneGraph;

using internal Sedulous.SceneGraph;

public typealias EntityId = uint64;
public typealias ComponentTypeId = uint32;

// Core Entity Structure
class Entity
{
    public const EntityId InvalidId = EntityId.MinValue;
    
    private static EntityId sNextId = 1;
    
    public EntityId Id { get; private set; }
    public String Name { get; set; } = new .() ~ delete _;
    public Transform Transform { get; set; } = new .() ~ delete _;
    public Scene Scene { get; internal set; }
    
    // Traditional hierarchy
    public Entity Parent { get; private set; }
    private List<Entity> mChildren = new .() ~ delete _;
    public Span<Entity> Children => mChildren;
    
    // Component storage - hybrid approach
    private Dictionary<ComponentTypeId, IComponent> mComponents = new .() ~ delete _;
    
    public this()
    {
        Id = Interlocked.Increment(ref sNextId);
        //Transform = new .();
		Transform.Entity = this; // Set the entity reference
    }
    
    public ~this()
    {
        // Cleanup components
        for (var component in mComponents.Values)
        {
            delete component;
        }
        
        // Remove from parent
        if (Parent != null)
            Parent.RemoveChild(this);
    }
    
    // Hierarchy management
    public void AddChild(Entity child)
    {
        if (child.Parent != null)
            child.Parent.RemoveChild(child);
            
        child.Parent = this;
        mChildren.Add(child);
        
        // Notify scene modules
        Scene?.OnEntityHierarchyChanged(child);
    }
    
    public void RemoveChild(Entity child)
    {
        if (mChildren.Remove(child))
        {
            child.Parent = null;
            Scene?.OnEntityHierarchyChanged(child);
        }
    }
    
    // Component management
    public T AddComponent<T>() where T : Component, new
    {
        var typeId = ComponentRegistry.GetTypeId<T>();
        if (mComponents.ContainsKey(typeId))
            return (T)mComponents[typeId];
            
        var component = new T();
        component.Entity = this;
        mComponents[typeId] = component;
        
        // Notify scene modules
        Scene?.OnComponentAdded(this, component);
        
        // Publish message
        Scene.SceneGraph.MessageBus.Publish(new ComponentAddedMessage(this, component));
        
        return component;
    }
    
    public T GetComponent<T>() where T : Component
    {
        var typeId = ComponentRegistry.GetTypeId<T>();
        if (mComponents.TryGetValue(typeId, var component))
            return (T)component;
        return null;
    }
    
    public bool HasComponent<T>() where T : Component
    {
        var typeId = ComponentRegistry.GetTypeId<T>();
        return mComponents.ContainsKey(typeId);
    }

    public bool HasComponent(ComponentTypeId typeId)
    {
        return mComponents.ContainsKey(typeId);
    }

    public IComponent GetComponent(ComponentTypeId typeId)
    {
        return mComponents.TryGetValue(typeId, var component) ? component : null;
    }
    
    public void RemoveComponent<T>() where T : Component
    {
        var typeId = ComponentRegistry.GetTypeId<T>();
        if (mComponents.TryGetValue(typeId, var component))
        {
            mComponents.Remove(typeId);
            
            Scene?.OnComponentRemoved(this, component);
            
            // Publish message before deletion
            Scene.SceneGraph.MessageBus.Publish(new ComponentRemovedMessage(this, typeId));
            
            delete component;
        }
    }
}