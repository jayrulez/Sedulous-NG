using System;
using Sedulous.Utilities;
using Sedulous.Foundation;
using System.IO;
using Sedulous.Platform;
using Sedulous.Platform.Core.Input;
using SDL3Native;
using Sedulous.Platform.Core;
using Sedulous.Foundation.Core;

using internal Sedulous.Foundation;
using internal Sedulous.Platform.SDL3.Input;

namespace Sedulous.Platform.SDL3.Input;

/// <summary>
/// Represents the SDL2 implementation of the Input subsystem.
/// </summary>
public sealed class SDL3InputSystem : InputSystem
{
	/// <summary>
	/// Initializes a new instance of the SDL2Input class.
	/// </summary>
	/// <param name="backend">The backend.</param>
	public this(SDL3WindowSystem backend)
	{
		mWindowSystem = backend;
		this.mKeyboard = new SDL3KeyboardDevice(this);
		this.mMouse = new SDL3MouseDevice(this);
		this.mGamePadInfo = new GamePadDeviceInfo(this);
		this.mGamePadInfo.GamePadConnected.Subscribe(new => OnGamePadConnected);
		this.mGamePadInfo.GamePadDisconnected.Subscribe(new => OnGamePadDisconnected);

		LoadGameControllerMappingDatabase();
	}


	public ~this()
	{
		delete mKeyboard;
		delete mMouse;
		delete mGamePadInfo;
	}

	/// <inheritdoc/>
	internal bool HandleEvent(SDL_Event ev)
	{
		if (this.mMouse.HandleEvent(ev))
			return true;

		if (this.mKeyboard.HandleEvent(ev))
			return true;

		if (this.mGamePadInfo.HandleEvent(ev))
			return true;

		return false;
	}

	/// <summary>
	/// Resets the device's state in preparation for the next frame.
	/// </summary>
	public void ResetDeviceStates()
	{
		this.mKeyboard.ResetDeviceState();
		this.mMouse.ResetDeviceState();
		this.mGamePadInfo.ResetDeviceStates();
	}

	/// <inheritdoc/>
	public void Update(Time time)
	{
		this.mKeyboard.Update(time);
		this.mMouse.Update(time);
		this.mGamePadInfo.Update(time);
	}

	/// <inheritdoc/>
	public override bool IsKeyboardSupported()
	{
		return true;
	}

	/// <inheritdoc/>
	public override bool IsKeyboardRegistered()
	{
		return mKeyboard.IsRegistered;
	}

	/// <inheritdoc/>
	public override KeyboardDevice GetKeyboard()
	{
		return mKeyboard;
	}

	/// <inheritdoc/>
	public override bool IsMouseSupported()
	{
		return true;
	}

	/// <inheritdoc/>
	public override bool IsMouseRegistered()
	{
		return mMouse.IsRegistered;
	}

	/// <inheritdoc/>
	public override MouseDevice GetMouse()
	{
		return mMouse;
	}

	/// <inheritdoc/>
	public override int32 GetGamePadCount()
	{
		return mGamePadInfo.Count;
	}

	/// <inheritdoc/>
	public override bool IsGamePadSupported()
	{
		return true;
	}

	/// <inheritdoc/>
	public override bool IsGamePadConnected()
	{
		return mGamePadInfo.Count > 0;
	}

	/// <inheritdoc/>
	public override bool IsGamePadConnected(int32 playerIndex)
	{
		Contract.EnsureRange(playerIndex >= 0, nameof(playerIndex));

		return mGamePadInfo.GetGamePadForPlayer(playerIndex) != null;
	}

	/// <inheritdoc/>
	public override bool IsGamePadRegistered()
	{
		for (int32 i = 0; i < mGamePadInfo.Count; i++)
		{
			if (mGamePadInfo.GetGamePadForPlayer(i)?.IsRegistered ?? false)
				return true;
		}

		return false;
	}

	/// <inheritdoc/>
	public override bool IsGamePadRegistered(int32 playerIndex)
	{
		Contract.EnsureRange(playerIndex >= 0, nameof(playerIndex));

		return mGamePadInfo.GetGamePadForPlayer(playerIndex)?.IsRegistered ?? false;
	}

	/// <inheritdoc/>
	public override GamePadDevice GetGamePadForPlayer(int32 playerIndex)
	{
		return mGamePadInfo.GetGamePadForPlayer(playerIndex);
	}

	/// <inheritdoc/>
	public override GamePadDevice GetFirstConnectedGamePad()
	{
		return mGamePadInfo.GetFirstConnectedGamePad();
	}

	/// <inheritdoc/>
	public override GamePadDevice GetFirstRegisteredGamePad()
	{
		return mGamePadInfo.GetFirstRegisteredGamePad();
	}

	/// <inheritdoc/>
	public override GamePadDevice GetPrimaryGamePad()
	{
		return mPrimaryGamePad;
	}

	public override WindowSystem Backend => mWindowSystem;

	/// <inheritdoc/>
	public override bool IsMouseCursorAvailable => mMouse.IsRegistered;

	/// <inheritdoc/>
	public readonly override EventAccessor<KeyboardRegistrationEventHandler> KeyboardRegistered { get; } = new .() ~ delete _;

	/// <inheritdoc/>
	public readonly override EventAccessor<MouseRegistrationEventHandler> MouseRegistered { get; } = new .() ~ delete _;

	/// <inheritdoc/>
	public readonly override EventAccessor<GamePadConnectionEventHandler> GamePadConnected { get; } = new .() ~ delete _;

	/// <inheritdoc/>
	public readonly override EventAccessor<GamePadConnectionEventHandler> GamePadDisconnected { get; } = new .() ~ delete _;

	/// <inheritdoc/>
	public readonly override EventAccessor<GamePadRegistrationEventHandler> GamePadRegistered { get; } = new .() ~ delete _;

	/// <summary>
	/// Registers the specified device as having received user input.
	/// </summary>
	/// <param name="device">The device to register.</param>
	/// <returns><see langword="true"/> if the device was registered; otherwise, <see langword="false"/>.</returns>
	internal bool RegisterKeyboardDevice(SDL3KeyboardDevice device)
	{
		if (device.IsRegistered)
			return false;

		KeyboardRegistered?.Invoke(device);
		return true;
	}

	/// <summary>
	/// Registers the specified device as having received user input.
	/// </summary>
	/// <param name="device">The device to register.</param>
	/// <returns><see langword="true"/> if the device was registered; otherwise, <see langword="false"/>.</returns>
	internal bool RegisterMouseDevice(SDL3MouseDevice device)
	{
		if (device.IsRegistered)
			return false;

		MouseRegistered?.Invoke(device);
		return true;
	}

	/// <summary>
	/// Registers the specified device as having received user input.
	/// </summary>
	/// <param name="device">The device to register.</param>
	/// <returns><see langword="true"/> if the device was registered; otherwise, <see langword="false"/>.</returns>
	internal bool RegisterGamePadDevice(SDL3GamePadDevice device)
	{
		if (mPrimaryGamePad == null)
			mPrimaryGamePad = device;

		if (device.IsRegistered)
			return false;

		GamePadRegistered?.Invoke(device, device.PlayerIndex);
		return true;
	}

	/// <summary>
	/// Attempts to load gamecontrollerdb.txt, if it is located in the application's root directory. 
	/// </summary>
	private void LoadGameControllerMappingDatabase()
	{
		const String DatabasePath = "gamecontrollerdb.txt";

		if (File.Exists(DatabasePath))
		{
			var data = File.ReadAll(DatabasePath, .. scope .());

			var rw = SDL_IOFromMem(data.Ptr, (.)data.Count);
			if (SDL_AddGamepadMappingsFromIO(rw, false) < 0)
				Runtime.SDL3Error();
		}
	}

	/// <summary>
	/// Raises the <see cref="GamePadConnected"/> event.
	/// </summary>
	/// <param name="device">The device that was connected.</param>
	/// <param name="playerIndex">The player index associated with the game pad.</param>
	private void OnGamePadConnected(GamePadDevice device, int32 playerIndex)
	{
		GamePadConnected?.Invoke(device, playerIndex);
	}

	/// <summary>
	/// Raises the <see cref="GamePadDisconnected"/> event.
	/// </summary>
	/// <param name="device">The device that was disconnected.</param>
	/// <param name="playerIndex">The player index associated with the game pad.</param>
	private void OnGamePadDisconnected(GamePadDevice device, int32 playerIndex)
	{
		if (mPrimaryGamePad == device)
			mPrimaryGamePad = null;

		GamePadDisconnected?.Invoke(device, playerIndex);
	}

	// Input devices.
	private readonly SDL3WindowSystem mWindowSystem;
	private SDL3KeyboardDevice mKeyboard;
	private SDL3MouseDevice mMouse;
	private GamePadDeviceInfo mGamePadInfo;
	private SDL3GamePadDevice mPrimaryGamePad;
}
