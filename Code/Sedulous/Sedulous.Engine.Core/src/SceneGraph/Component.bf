namespace Sedulous.Engine.Core.SceneGraph;

abstract class Component : IComponent
{
    public Entity Entity { get; set; }
    public abstract ComponentTypeId TypeId { get; }
}