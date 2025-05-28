using System.Collections;
using System;
using System.Threading;
namespace Sedulous.SceneGraph;

static class ComponentRegistry
{
    private static ComponentTypeId sNextTypeId = 1;
    private static Dictionary<Type, ComponentTypeId> sTypeToId = new .() ~ delete _;
    private static Dictionary<ComponentTypeId, Type> sIdToType = new .() ~ delete _;
    
    public static ComponentTypeId GetTypeId<T>() where T : Component
    {
        return GetTypeId(typeof(T));
    }
    
    public static ComponentTypeId GetTypeId(Type type)
    {
        if (!sTypeToId.TryGetValue(type, var typeId))
        {
            typeId = Interlocked.Increment(ref sNextTypeId);
            sTypeToId[type] = typeId;
            sIdToType[typeId] = type;
        }
        return typeId;
    }
    
    public static Type GetType(ComponentTypeId typeId)
    {
        return sIdToType.TryGetValue(typeId, var type) ? type : null;
    }
}