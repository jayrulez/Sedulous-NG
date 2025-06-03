using System;
using System.Collections;
using Sedulous.Utilities;
namespace Sedulous.SceneGraph;

abstract class SceneModule
{
	public Scene Scene { get; internal set; }
	public abstract StringView Name { get; }

	private List<ComponentTypeId> mInterestedComponents = new .() ~ delete _;
	private List<Entity> mTrackedEntities = new .() ~ delete _;

	protected this()
	{
		RegisterComponentInterests();
	}

	// Override to register which components this module cares about
	protected virtual void RegisterComponentInterests() { }

	// Helper to register interest in a component type
	protected void RegisterComponentInterest<T>() where T : Component
	{
		mInterestedComponents.Add(ComponentRegistry.GetTypeId<T>());
	}

	// Lifecycle
	internal void Attached() => OnAttached();
	internal void Detached() => OnDetached();

	protected virtual void OnAttached() { }
	protected virtual void OnDetached() { }

	// Entity events
	internal void EntityCreated(Entity entity) => OnEntityCreated(entity);

	internal void EntityDestroyed(Entity entity) => OnEntityDestroyed(entity);

	internal void EntityHierarchyChanged(Entity entity) => OnEntityHierarchyChanged(entity);

	// Component events
	internal void ComponentAdded(Entity entity, IComponent component) => OnComponentAdded(entity, component);

	internal void ComponentRemoved(Entity entity, IComponent component) => OnComponentRemoved(entity, component);


	protected virtual void OnEntityCreated(Entity entity)
	{
		CheckEntityInterest(entity);
	}

	protected virtual void OnEntityDestroyed(Entity entity)
	{
		mTrackedEntities.Remove(entity);
		OnEntityRemovedFromTracking(entity);
	}

	protected virtual void OnEntityHierarchyChanged(Entity entity) { }

	// Component events
	protected virtual void OnComponentAdded(Entity entity, IComponent component)
	{
		if (mInterestedComponents.Contains(component.TypeId))
		{
			CheckEntityInterest(entity);
		}
	}

	protected virtual void OnComponentRemoved(Entity entity, IComponent component)
	{
		if (mInterestedComponents.Contains(component.TypeId))
		{
			CheckEntityInterest(entity);
		}
	}

	// Update
	internal void Update(Time time)
	{
		OnUpdate(time);
	}
	protected virtual void OnUpdate(Time time) { }

	// Override these for entity tracking
	protected virtual void OnEntityAddedToTracking(Entity entity) { }
	protected virtual void OnEntityRemovedFromTracking(Entity entity) { }

	// Check if entity should be tracked based on component interests
	private void CheckEntityInterest(Entity entity)
	{
		bool shouldTrack = ShouldTrackEntity(entity);
		bool isTracked = mTrackedEntities.Contains(entity);

		if (shouldTrack && !isTracked)
		{
			mTrackedEntities.Add(entity);
			OnEntityAddedToTracking(entity);
		}
		else if (!shouldTrack && isTracked)
		{
			mTrackedEntities.Remove(entity);
			OnEntityRemovedFromTracking(entity);
		}
	}

	// Override for custom tracking logic
	protected virtual bool ShouldTrackEntity(Entity entity)
	{
		// Default: track if entity has ANY of the interested components
		for (var componentType in mInterestedComponents)
		{
			if (entity.HasComponent(componentType))
				return true;
		}
		return false;
	}

	protected Span<Entity> TrackedEntities => mTrackedEntities;
}