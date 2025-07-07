using System;
using System.Collections;
using Sedulous.Utilities;
namespace Sedulous.SceneGraph;

using internal Sedulous.SceneGraph;

abstract class SceneModule
{
	public Scene Scene { get; internal set; }
	public abstract StringView Name { get; }

	private List<EntityQuery> mQueries = new .() ~ delete _;

	protected this()
	{
	}

	protected EntityQuery CreateQuery()
	{
	    var query = new EntityQuery();
	    mQueries.Add(query);
	    return query;
	}

	protected void DestroyQuery(EntityQuery query)
	{
		if(mQueries.Remove(query))
		{
			delete query;
		}
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
		for (var query in mQueries)
			query.CheckEntity(entity);
	}

	protected virtual void OnEntityDestroyed(Entity entity)
	{
		for (var query in mQueries)
			query.RemoveEntity(entity);
	}

	protected virtual void OnEntityHierarchyChanged(Entity entity) { }

	// Component events
	protected virtual void OnComponentAdded(Entity entity, IComponent component)
	{
		for (var query in mQueries)
			query.CheckEntity(entity);
	}

	protected virtual void OnComponentRemoved(Entity entity, IComponent component)
	{
		for (var query in mQueries)
			query.CheckEntity(entity);
	}

	// Update
	internal void Update(Time time)
	{
		OnUpdate(time);
	}

	protected virtual void OnUpdate(Time time) { }
}