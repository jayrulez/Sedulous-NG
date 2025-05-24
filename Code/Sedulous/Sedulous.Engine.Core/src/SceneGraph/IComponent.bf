namespace Sedulous.Engine.Core.SceneGraph;

interface IComponent
{
    Entity Entity { get; set; }
    ComponentTypeId TypeId { get; }
}