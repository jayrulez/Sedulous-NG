using System;
using System.Text;
using Sedulous.Foundation.Utilities;
using Sedulous.Platform.Core.Input;
using SDL3Native;
using Sedulous.Platform.Core;
using internal Sedulous.Platform.SDL3.Input;

namespace Sedulous.Platform.SDL3.Input
{
    /// <summary>
    /// Represents the SDL2 implementation of the KeyboardDevice class.
    /// </summary>
    public sealed class SDL3KeyboardDevice : KeyboardDevice
    {
        /// <summary>
        /// Initializes a new instance of the SDL2KeyboardDevice class.
        /// </summary>
        /// <param name="inputSystem">The InputSystem.</param>
        public this(SDL3InputSystem inputSystem)
            : base(inputSystem)
        {
            int32 numkeys = 0;
            SDL_GetKeyboardState(&numkeys);

            this.states = new InternalButtonState[numkeys];
        }

		public ~this()
		{
			delete states;
		}

        /// <inheritdoc/>
        internal bool HandleEvent(SDL_Event evt)
        {
            
                switch (evt.key.type)
                {
                    case .SDL_EVENT_KEY_DOWN:
                        {
                            if (!isRegistered)
                                Register();

                            OnKeyDown(evt.key);
                        }
                        return true;

                    case .SDL_EVENT_KEY_UP:
                        {
                            if (!isRegistered)
                                Register();

                            OnKeyUp(evt.key);
                        }
                        return true;

                    case .SDL_EVENT_TEXT_EDITING:
                        {
                            if (!isRegistered)
                                Register();

                            OnTextEditing(evt.edit);
                        }
                        return true;

                    case .SDL_EVENT_TEXT_INPUT:
                        {
                            if (isRegistered)
                                Register();

                            OnTextInput(evt.text);
                        }
                        return true;

				default: return false;
                }
        }

        /// <summary>
        /// Resets the device's state in preparation for the next frame.
        /// </summary>
        public void ResetDeviceState()
        {
            for (int i = 0; i < states.Count; i++)
            {
                states[i].Reset();
            }
        }

        /// <inheritdoc/>
        public override void Update(PlatformTime time)
        {

        }

        /// <inheritdoc/>
        public override void GetTextInput(String sb, bool @append = false)
        {
            if (!@append)
                sb.Length = 0;

            for (int i = 0; i < textInputLength; i++)
            {
                sb.Append(mText[i]);
            }
        }

        /// <inheritdoc/>
        public override bool IsButtonDown(Scancode button)
        {
            var scancode = (int)button;
            return states[scancode].Down;
        }

        /// <inheritdoc/>
        public override bool IsButtonUp(Scancode button)
        {
            var scancode = (int)button;
            return states[scancode].Up;
        }

        /// <inheritdoc/>
        public override bool IsButtonPressed(Scancode button, bool ignoreRepeats = true)
        {
            var scancode = (int)button;
            return states[scancode].Pressed || (!ignoreRepeats && states[scancode].Repeated);
        }

        /// <inheritdoc/>
        public override bool IsButtonReleased(Scancode button)
        {
            var scancode = (int)button;
            return states[scancode].Released;
        }

        /// <inheritdoc/>
        public override bool IsKeyDown(Key key)
        {
            var scancode = (int)SDL_GetScancodeFromKey((SDL_Keycode)key, null);
            return states[scancode].Down;
        }

        /// <inheritdoc/>
        public override bool IsKeyUp(Key key)
        {
            var scancode = (int)SDL_GetScancodeFromKey((SDL_Keycode)key, null);
            return states[scancode].Up;
        }

        /// <inheritdoc/>
        public override bool IsKeyPressed(Key key, bool ignoreRepeats = true)
        {
            var scancode = (int)SDL_GetScancodeFromKey((SDL_Keycode)key, null);
            return states[scancode].Pressed || (!ignoreRepeats && states[scancode].Repeated);
        }

        /// <inheritdoc/>
        public override bool IsKeyReleased(Key key)
        {
            var scancode = (int)SDL_GetScancodeFromKey((SDL_Keycode)key, null);
            return states[scancode].Released;
        }

        /// <inheritdoc/>
        public override ButtonState GetKeyState(Key key)
        {
            var state = IsKeyDown(key) ? ButtonState.Down : ButtonState.Up;

            if (IsKeyPressed(key))
                state |= ButtonState.Pressed;

            if (IsKeyReleased(key))
                state |= ButtonState.Released;

            return state;
        }

        /// <inheritdoc/>
        public override bool IsNumLockDown => (SDL_GetModState() & .SDL_KMOD_NUM) == .SDL_KMOD_NUM;

        /// <inheritdoc/>
        public override bool IsCapsLockDown => (SDL_GetModState() & .SDL_KMOD_CAPS) == .SDL_KMOD_CAPS;

        /// <inheritdoc/>
        public override bool IsRegistered => isRegistered;

        /// <summary>
        /// Handles SDL2's KEYDOWN event.
        /// </summary>
        private void OnKeyDown(in SDL_KeyboardEvent evt)
        {
            var window = InputSystem.Backend.GetWindowById((int32)evt.windowID);
            var mods   = evt.mod;
            var ctrl   = (mods & .SDL_KMOD_CTRL) != 0;
            var alt    = (mods & .SDL_KMOD_ALT) != 0;
            var shift  = (mods & .SDL_KMOD_SHIFT) != 0;
            var @repeat = evt.@repeat;

            states[(int)evt.scancode].OnDown(@repeat);

            if (!@repeat)
            {
                OnButtonPressed(window, (Scancode)evt.scancode);
            }
            OnKeyPressed(window, (Key)evt.key, ctrl, alt, shift, @repeat);
        }

        /// <summary>
        /// Handles SDL2's KEYUP event.
        /// </summary>
        private void OnKeyUp(in SDL_KeyboardEvent evt)
        {
            var window = InputSystem.Backend.GetWindowById((int32)evt.windowID);

            states[(int)evt.scancode].OnUp();

            OnButtonReleased(window, (Scancode)evt.scancode);
            OnKeyReleased(window, (Key)evt.key);
        }

        /// <summary>
        /// Handles SDL2's TEXTEDITING event.
        /// </summary>
        private void OnTextEditing(in SDL_TextEditingEvent evt)
        {
            var window = InputSystem.Backend.GetWindowById((int32)evt.windowID);
            if (GetText(evt.text))
                {
                    OnTextEditing(window);
                }
        }

        /// <summary>
        /// Handles SDL2's TEXTINPUT event.
        /// </summary>
        private void OnTextInput(in SDL_TextInputEvent evt)
        {
            var window = InputSystem.Backend.GetWindowById((int32)evt.windowID);
            if (GetText(evt.text))
                {
                    OnTextInput(window);
                }
        }

        /// <summary>
        /// Converts inputted text (which is in UTF-8 format) to UTF-16.
        /// </summary>
        /// <param name="input">A pointer to the inputted text.</param>
        /// <returns><see langword="true"/> if the input data was successfully converted; otherwise, <see langword="false"/>.</returns>
        private bool GetText(in char8[SDL_TextInputEvent.SDL_TEXT_SIZE] input)
        {
			//mText.Clear();
			var input;
			String text = scope .(&input);
			if(text.Length == 0)
				return false;

			mText.Set(text);

			return true;
        }

        /// <summary>
        /// Flags the device as registered.
        /// </summary>
        private void Register()
        {
            var input = (SDL3InputSystem)InputSystem;
            if (input.RegisterKeyboardDevice(this))
                isRegistered = true;
        }

        // State values.
        private readonly InternalButtonState[] states;
        private readonly String mText = new .() ~ delete _;
        private int32 textInputLength;
        private bool isRegistered;
    }
}
