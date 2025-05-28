using Sedulous.SceneGraph;
using System;
using System.Collections;
using Sedulous.Foundation.Mathematics;
namespace Sedulous.Engine.Input;

using internal Sedulous.Engine.Input;

class InputModule : SceneModule
{
    public override StringView Name => "Input";

    private InputSubsystem mInputSubsystem;
    private List<InputContext> mSceneContexts = new .() ~ delete _;

    public this(InputSubsystem inputSubsystem)
    {
        mInputSubsystem = inputSubsystem;
    }

    protected override void RegisterComponentInterests()
    {
        RegisterComponentInterest<InputComponent>();
    }

    protected override void OnUpdate(TimeSpan deltaTime)
    {
        // Update scene-specific input contexts
        for (var context in mSceneContexts)
        {
            context.Update(deltaTime);
        }

        // Update input components
        for (var entity in TrackedEntities)
        {
            var inputComponent = entity.GetComponent<InputComponent>();
            if (inputComponent != null)
            {
                UpdateInputComponent(entity, inputComponent, deltaTime);
            }
        }
    }

    private void UpdateInputComponent(Entity entity, InputComponent input, TimeSpan deltaTime)
    {
        // Handle input for this entity
        if (input.ReceivesInput)
        {
            // Process input actions for this entity
            if (input.InputContext != null)
            {
                // Check all actions in this entity's input context
                for (var actionEntry in input.InputContext.mActions)
                {
                    var actionName = actionEntry.key;
                    var action = actionEntry.value;
                    
                    // Handle different input events
                    if (action.IsPressed())
                    {
                        input.OnActionPressed?.Invoke(entity, actionName);
                    }
                    
                    if (action.IsHeld())
                    {
                        input.OnActionHeld?.Invoke(entity, actionName);
                    }
                    
                    // Handle axis values (for movement, etc.)
                    var currentValue = action.GetValue();
                    if (Math.Abs(currentValue) > 0.01f) // Dead zone
                    {
                        input.OnActionValue?.Invoke(entity, actionName, currentValue);
                    }
                }
                
                // Process any entity-specific input behaviors
                ProcessEntityInputBehaviors(entity, input, deltaTime);
            }
        }
    }

    private void ProcessEntityInputBehaviors(Entity entity, InputComponent input, TimeSpan deltaTime)
    {
        // Handle common input behaviors based on other components
        
        // Movement input for entities with transform
        if (input.EnableMovement && entity.Transform != null)
        {
            HandleMovementInput(entity, input, deltaTime);
        }
    }

    private void HandleMovementInput(Entity entity, InputComponent input, TimeSpan deltaTime)
    {
        var moveSpeed = input.MovementSpeed;
        var transform = entity.Transform;
        
        // Get movement input from action manager
        var actionManager = mInputSubsystem.ActionManager;
        
        var moveForward = actionManager.GetActionValue("MoveForward") - actionManager.GetActionValue("MoveBack");
        var moveRight = actionManager.GetActionValue("MoveRight") - actionManager.GetActionValue("MoveLeft");
        var moveUp = actionManager.GetActionValue("MoveUp") - actionManager.GetActionValue("MoveDown");
        
        if (Math.Abs(moveForward) > 0.01f || Math.Abs(moveRight) > 0.01f || Math.Abs(moveUp) > 0.01f)
        {
            var movement = Vector3.Zero;
            
            // Calculate movement in local space
            movement += transform.Forward * moveForward;
            movement += Vector3.Cross(transform.Forward, transform.Up) * moveRight;
            movement += transform.Up * moveUp;
            
            // Normalize and apply speed
            if (movement.LengthSquared() > 0.01f)
            {
                movement = Vector3.Normalize(movement) * moveSpeed * (float)deltaTime.TotalSeconds;
                transform.Position += movement;
                transform.MarkDirty();
            }
        }
    }

    public void AddSceneContext(InputContext context)
    {
        mSceneContexts.Add(context);
    }

    public void RemoveSceneContext(InputContext context)
    {
        mSceneContexts.Remove(context);
    }
}