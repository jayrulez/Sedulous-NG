using System.Collections;
using System;
namespace Sedulous.SceneGraph;

class EntityQuery
{
	private List<Type> mRequiredComponents = new .() ~ delete _;
	private List<Type> mAnyOfComponents = new .() ~ delete _;
	private List<Type> mExcludedComponents = new .() ~ delete _;
	private HashSet<EntityId> mMatchingEntities = new .() ~ delete _;
	private List<Entity> mCachedEntityList = new .() ~ delete _;
	private bool mCacheDirty = true;

	public EntityQuery With<T>() where T : Component
	{
		mRequiredComponents.Add(typeof(T));
		mCacheDirty = true;
		return this;
	}

	public EntityQuery WithAnyOf(params Type[] types)
	{
		if (types.Count > 0)
		{
			for (var type in types)
				mAnyOfComponents.Add(type);
			mCacheDirty = true;
		}
		return this;
	}

	public EntityQuery Without<T>() where T : Component
	{
		mExcludedComponents.Add(typeof(T));
		mCacheDirty = true;
		return this;
	}

	// Check if entity matches query
	public bool Matches(Entity entity)
	{
		for (var requiredType in mRequiredComponents)
		{
			if (!entity.HasComponent(requiredType))
				return false;
		}

		for (var excludedType in mExcludedComponents)
		{
			if (entity.HasComponent(excludedType))
				return false;
		}

		if (mAnyOfComponents.Count > 0)
		{
			bool hasAnyOf = false;
			for (var anyType in mAnyOfComponents)
			{
				if (entity.HasComponent(anyType))
				{
					hasAnyOf = true;
					break;
				}
			}
			if (!hasAnyOf)
				return false;
		}

		return true;
	}

	public void ForEach<T>(Scene scene, delegate void(Entity entity, T component) action) where T : Component
	{
		var entities = scope List<Entity>();
		GetEntities(scene, entities);
		for (var entity in entities)
		{
			var component = entity.GetComponent<T>();
			if (component != null)
				action(entity, component);
		}
	}

	// Get matching entities
	public void GetEntities(Scene scene, List<Entity> outEntities)
	{
		if (mCacheDirty)
		{
			RebuildCache(scene);
			mCacheDirty = false;
		}

		outEntities.Clear();
		outEntities.AddRange(mCachedEntityList);
	}

	private void RebuildCache(Scene scene)
	{
		mCachedEntityList.Clear();
		for (var entityId in mMatchingEntities)
		{
			if (var entity = scene.FindEntity(entityId))
				mCachedEntityList.Add(entity);
		}
	}

	// Internal tracking
	internal void CheckEntity(Entity entity)
	{
		bool wasMatching = mMatchingEntities.Contains(entity.Id);
		bool isMatching = Matches(entity);

		if (isMatching && !wasMatching)
		{
			mMatchingEntities.Add(entity.Id);
			mCacheDirty = true;
		}
		else if (!isMatching && wasMatching)
		{
			mMatchingEntities.Remove(entity.Id);
			mCacheDirty = true;
		}
	}

	internal void RemoveEntity(Entity entity)
	{
		mMatchingEntities.Remove(entity.Id);
	}
}