namespace Sedulous.SceneGraph;

abstract class Component : IComponent
{
    public Entity Entity { get; set; }
    //public abstract ComponentTypeId TypeId { get; }
	public static readonly ComponentTypeId ComponentTypeId = ComponentRegistry.GetTypeId<Self>();
}