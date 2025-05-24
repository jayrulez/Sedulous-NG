using Sedulous.Engine.Core;
using System;
using Sedulous.Platform.Core.Input;
using Sedulous.Engine.Core.SceneGraph;
using System.Collections;
namespace Sedulous.Engine.Input;

class InputSubsystem : Subsystem
{
    public override StringView Name => "Input";

    private InputSystem mInputSystem;
    private InputActionManager mActionManager = new .() ~ delete _;

    public InputActionManager ActionManager => mActionManager;

    public this(InputSystem inputSystem)
    {
        mInputSystem = inputSystem;
    }

    public ~this()
    {
        delete mInputSystem;
    }

    protected override Result<void> OnInitializing(IEngine engine)
    {
        // Register for engine updates
        RegisterUpdateFunction(.(){
            Priority = 1000, // High priority - update input first
            Stage = .PreUpdate,
            Function = new => OnUpdate
        });

        return .Ok;
    }

    protected override void CreateSceneModules(Scene scene, List<SceneModule> modules)
    {
        modules.Add(new InputModule(this));
    }

    private void OnUpdate(IEngine.UpdateInfo info)
    {
        // Update action manager
        mActionManager.Update(info.Time.ElapsedTime);
    }

    public KeyboardDevice GetKeyboard() => mInputSystem.GetKeyboard();
    public MouseDevice GetMouse() => mInputSystem.GetMouse();
    public GamePadDevice GetGamePad(int32 playerIndex = 0) => mInputSystem.GetGamePadForPlayer(playerIndex);
}