using Sedulous.SceneGraph;
using System;
namespace Sedulous.Engine.Input;

class InputComponent : Component
{
    //private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<InputComponent>();
    //public override ComponentTypeId TypeId => sTypeId;

    public bool ReceivesInput { get; set; } = true;
    public InputContext InputContext { get; set; }
    
    // Movement behavior
    public bool EnableMovement { get; set; } = false;
    public float MovementSpeed { get; set; } = 5.0f;
    
    // Input event callbacks
    public delegate void(Entity entity, StringView actionName) OnActionPressed;
    public delegate void(Entity entity, StringView actionName) OnActionHeld;
    public delegate void(Entity entity, StringView actionName, float value) OnActionValue;
}