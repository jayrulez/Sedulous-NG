using Sedulous.Foundation;
using Sedulous.Foundation.Core;
namespace Sedulous.Platform.Core.Input;

/// <summary>
/// Represents the method that is called when a <see cref="KeyboardDevice"/> is registered
/// with the context as a result of receiving input for the first time.
/// </summary>
/// <param name="device">The device that was registered.</param>
public delegate void KeyboardRegistrationEventHandler(KeyboardDevice device);

/// <summary>
/// Represents the method that is called when a <see cref="MouseDevice"/> is registered
/// with the context as a result of receiving input for the first time.
/// </summary>
/// <param name="device">The device that was registered.</param>
public delegate void MouseRegistrationEventHandler(MouseDevice device);

/// <summary>
/// Represents the method that is called when a <see cref="GamePadDevice"/> is 
/// connected or disconnected.
/// </summary>
/// <param name="device">The device that was connected or disconnected.</param>
/// <param name="playerIndex">The player index associated with the game pad.</param>
public delegate void GamePadConnectionEventHandler(GamePadDevice device, int32 playerIndex);

/// <summary>
/// Represents the method that is called when a <see cref="GamePadDevice"/> is registered
/// with the context as a result of receiving input for the first time.
/// </summary>
/// <param name="device">The device that was registered.</param>
/// <param name="playerIndex">The player index associated with the game pad.</param>
public delegate void GamePadRegistrationEventHandler(GamePadDevice device, int32 playerIndex);

/// <summary>
/// Represents the Framework's input subsystem.
/// </summary>
abstract class InputSystem
{
	public abstract WindowSystem Backend { get; }

	/// <summary>
	/// Gets a value indicating whether the current platform supports
	/// keyboard input.
	/// </summary>
	/// <returns><see langword="true"/> if the current platform supports 
	/// keyboard input; otherwise, <see langword="false"/>.</returns>
	public abstract bool IsKeyboardSupported();

	/// <summary>
	/// Gets a value indicating whether a keyboard device has been
	/// registered with the context.
	/// </summary>
	/// <returns><see langword="true"/> if a keyboard device is registered 
	/// with the context; otherwise, <see langword="false"/>.</returns>
	public abstract bool IsKeyboardRegistered();

	/// <summary>
	/// Gets the keyboard device, if keyboard input is supported.
	/// </summary>
	/// <remarks>If keyboard input is not supported on the current platform, 
	/// this method will throw <see cref="NotSupportedException"/>.</remarks>
	/// <returns>The keyboard device.</returns>
	public abstract KeyboardDevice GetKeyboard();

	/// <summary>
	/// Gets a value indicating whether the current platform supports 
	/// mouse input.
	/// </summary>
	/// <returns><see langword="true"/> if the current platform supports 
	/// mouse input; otherwise, <see langword="false"/>.</returns>
	public abstract bool IsMouseSupported();

	/// <summary>
	/// Gets a value indicating whether a mouse device has been registered 
	/// with the context.
	/// </summary>
	/// <returns><see langword="true"/> if a mouse device is registered with 
	/// the context; otherwise, <see langword="false"/></returns>
	public abstract bool IsMouseRegistered();

	/// <summary>
	/// Gets the mouse device, if mouse input is supported.
	/// </summary>
	/// <remarks>If mouse input is not supported on the current platform, 
	/// this method will throw <see cref="NotSupportedException"/>.</remarks>
	/// <returns>The mouse device.</returns>
	public abstract MouseDevice GetMouse();

	/// <summary>
	/// Gets the number of game pads that are currently connected.
	/// </summary>
	/// <returns>The number of game pads that are currently connected.</returns>
	public abstract int32 GetGamePadCount();

	/// <summary>
	/// Gets a value indicating whether the current platform supports 
	/// game pad input.
	/// </summary>
	/// <returns><see langword="true"/> if the current platform supports 
	/// game pad input; otherwise, <see langword="false"/>.</returns>
	public abstract bool IsGamePadSupported();

	/// <summary>
	/// Gets a value indicating whether any game pad is connected.
	/// </summary>
	/// <returns><see langword="true"/> if ta game pad is connected; 
	/// otherwise, <see langword="false"/>.</returns>
	public abstract bool IsGamePadConnected();

	/// <summary>
	/// Gets a value indicating whether the game pad for the specified 
	/// player is connected.
	/// </summary>
	/// <param name="playerIndex">The index of the player to evaluate.</param>
	/// <returns><see langword="true"/> if the specified player's game pad 
	/// is connected; otherwise, <see langword="false"/>.</returns>
	public abstract bool IsGamePadConnected(int32 playerIndex);

	/// <summary>
	/// Gets a value indicating whether any game pad has been registered 
	/// with the context.
	/// </summary>
	/// <returns><see langword="true"/> if a game pad has been registered; 
	/// otherwise, <see langword="false"/>.</returns>
	public abstract bool IsGamePadRegistered();

	/// <summary>
	/// Gets a value indicating whether the game pad for the specified player has 
	/// been registered with the context.
	/// </summary>
	/// <returns><see langword="true"/> if the game pad for the specified player
	/// is registered with the context; otherwise, <see langword="false"/></returns>
	public abstract bool IsGamePadRegistered(int32 playerIndex);

	/// <summary>
	/// Gets the game pad that belongs to the specified player.
	/// </summary>
	/// <param name="playerIndex">The index of the player for which to 
	/// retrieve a game pad.</param>
	/// <returns>The game pad that belongs to the specified player,
	/// or <see langword="null"/> if no such game pad exists.</returns>
	public abstract GamePadDevice GetGamePadForPlayer(int32 playerIndex);

	/// <summary>
	/// Gets the first connected game pad device.
	/// </summary>
	/// <returns>The first connected game pad device, 
	/// or <see langword="null"/> if no game pads are connected.</returns>
	public abstract GamePadDevice GetFirstConnectedGamePad();

	/// <summary>
	/// Gets the first registered game pad device.
	/// </summary>
	/// <returns>The first registered game pad device, 
	/// or <see langword="null"/> if no game pads are registered.</returns>
	public abstract GamePadDevice GetFirstRegisteredGamePad();

	/// <summary>
	/// Gets the primary game pad.
	/// </summary>
	/// <remarks>The primary game pad is the first device which was registered as a
	/// result of receiving user input.</remarks>
	/// <returns>The primary game pad, or <see langword="null"/> if there is no
	/// primary game pad.</returns>
	public abstract GamePadDevice GetPrimaryGamePad();

	/// <summary>
	/// Gets a value indicating whether a mouse cursor is available, either from a physical
	/// device or from touch emulation.
	/// </summary>
	public abstract bool IsMouseCursorAvailable
	{
		get;
	}

	/// <summary>
	/// Occurs when a keyboard device is registered as a result of receiving
	/// user input for the first time.
	/// </summary>
	public abstract EventAccessor<KeyboardRegistrationEventHandler> KeyboardRegistered { get; }

	/// <summary>
	/// Occurs when a mouse device is registered as a result of receiving
	/// user input for the first time.
	/// </summary>
	public abstract EventAccessor<MouseRegistrationEventHandler> MouseRegistered { get; }

	/// <summary>
	/// Occurs when a game pad is connected.
	/// </summary>
	public abstract EventAccessor<GamePadConnectionEventHandler> GamePadConnected { get; }

	/// <summary>
	/// Occurs when a game pad is disconnected.
	/// </summary>
	public abstract EventAccessor<GamePadConnectionEventHandler> GamePadDisconnected { get; }

	/// <summary>
	/// Occurs when a game pad device is registered as a result of receiving
	/// user input for the first time.
	/// </summary>
	public abstract EventAccessor<GamePadRegistrationEventHandler> GamePadRegistered { get; }
}