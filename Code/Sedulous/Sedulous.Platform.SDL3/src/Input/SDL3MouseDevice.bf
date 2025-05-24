using System;
using Sedulous.Foundation.Utilities;
using Sedulous.Platform;
using Sedulous.Foundation;
using Sedulous.Foundation.Mathematics;
using Sedulous.Platform.Core.Input;
using SDL3Native;
using Sedulous.Platform.Core;
using Sedulous.Foundation.Core;
using internal Sedulous.Platform.SDL3.Input;

namespace Sedulous.Platform.SDL3.Input
{
    /// <summary>
    /// Represents the SDL2 implementation of the MouseDevice class.
    /// </summary>
    public sealed class SDL3MouseDevice : MouseDevice
    {
        /// <summary>
        /// Initializes a new instance of the SDL2MouseDevice class.
        /// </summary>
        /// <param name="inputSystem">The InputSystem.</param>
        public this(SDL3InputSystem inputSystem)
            : base(inputSystem)
        {
            this.window = InputSystem.Backend.PrimaryWindow;

            var buttonCount = Enum.GetCount<MouseButton>();            
            this.states = new InternalButtonState[buttonCount];
        }

		public ~this()
		{
			delete states;
		}

        /// <inheritdoc/>
        internal bool HandleEvent(SDL_Event evt)
        {
            switch ((SDL_EventType)evt.type)
                {
                    case .SDL_EVENT_MOUSE_MOTION:
                        {
                            // HACK: On iOS, for some goddamn reason, SDL2 sends us a spurious motion event
                            // with mouse ID 0 when you first touch the screen. This only seems to happen once
                            // so let's just ignore it.
                            if (!ignoredFirstMouseMotionEvent)
                            {
                                SetMousePositionFromDevicePosition(evt.motion.windowID);
                                ignoredFirstMouseMotionEvent = true;
                            }
                            else
                            {
                                if (!isRegistered && evt.motion.which != SDL_TOUCH_MOUSEID)
                                    Register(evt.motion.windowID);

                                OnMouseMotion(evt.motion);
                            }
                        }
                        return true;

                    case .SDL_EVENT_MOUSE_BUTTON_DOWN:
                        {
                            if (!isRegistered && evt.button.which != SDL_TOUCH_MOUSEID)
                                Register(evt.button.windowID);

                            OnMouseButtonDown(evt.button);
                        }
                        return true;

                    case .SDL_EVENT_MOUSE_BUTTON_UP:
                        {
                            if (!isRegistered && evt.button.which != SDL_TOUCH_MOUSEID)
                                Register(evt.button.windowID);

                            OnMouseButtonUp(evt.button);
                        }
                        return true;

                    case .SDL_EVENT_MOUSE_WHEEL:
                        {
                            if (!isRegistered && evt.wheel.which != SDL_TOUCH_MOUSEID)
                                Register(evt.wheel.windowID);

                            OnMouseWheel(evt.wheel);
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
            buttonStateClicks       = 0;
            buttonStateDoubleClicks = 0;

            for (int i = 0; i < states.Count; i++)
            {
                states[i].Reset();
            }
        }

        /// <inheritdoc/>
        public override void Update(Time time)
        {

        }

        /// <inheritdoc/>
        public override void WarpToWindow(Window window, int32 x, int32 y)
        {
            Contract.Require(window, nameof(window));

            //window.WarpMouseWithinWindow(x, y);
        }

        /// <inheritdoc/>
        public override void WarpToWindowCenter(Window window)
        {
            Contract.Require(window, nameof(window));

            //var size = window.ClientSize;
            //window.WarpMouseWithinWindow(size.Width / 2, size.Height / 2);
        }

        /// <inheritdoc/>
        public override void WarpToPrimaryWindow(int32 x, int32 y)
        {
            var primary = InputSystem.Backend.PrimaryWindow;
            if (primary == null)
                Runtime.InvalidOperationError("NoPrimaryWindow");

            //primary.WarpMouseWithinWindow(x, y);
        }

        /// <inheritdoc/>
        public override void WarpToPrimaryWindowCenter()
        {
            var primary = InputSystem.Backend.PrimaryWindow;
            if (primary == null)
                Runtime.InvalidOperationError("NoPrimaryWindow");

            //var size = primary.ClientSize;
            //primary.WarpMouseWithinWindow(size.Width / 2, size.Height / 2);
        }

        /// <inheritdoc/>
        public override Point2? GetPositionInWindow(Window window)
        {
            Contract.Require(window, nameof(window));

            if (Window != window)
                return null;

            var spos = (Point2)Position;
            /*var cpos = Window.Compositor.WindowToPoint(spos);

            return cpos;*/
			return spos;
        }

        /// <inheritdoc/>
        public override bool IsButtonDown(MouseButton button)
        {
            return states[(int)button].Down;
        }

        /// <inheritdoc/>
        public override bool IsButtonUp(MouseButton button)
        {
            return states[(int)button].Up;
        }

        /// <inheritdoc/>
        public override bool IsButtonPressed(MouseButton button, bool ignoreRepeats = true)
        {
            return states[(int)button].Pressed || (!ignoreRepeats && states[(int)button].Repeated);
        }

        /// <inheritdoc/>
        public override bool IsButtonReleased(MouseButton button)
        {
            return states[(int)button].Released;
        }

        /// <inheritdoc/>
        public override bool IsButtonClicked(MouseButton button)
        {
            return (buttonStateClicks & (uint32)SDL_BUTTON(button)) != 0;
        }

        /// <inheritdoc/>
        public override bool IsButtonDoubleClicked(MouseButton button)
        {
            return (buttonStateDoubleClicks & (uint32)SDL_BUTTON(button)) != 0;
        }

        /// <inheritdoc/>
        public override bool GetIsRelativeModeEnabled()
        {
            return false;// SDL_GetRelativeMouseMode();
        }

        /// <inheritdoc/>
        public override bool SetIsRelativeModeEnabled(bool enabled)
        {
            /*var result = SDL_SetRelativeMouseMode(enabled);
            if (result == -1)
                return false;

            if (result < 0)
                Runtime.SDL2Error();

            relativeMode = enabled;*/
            return true;
        }

        /// <inheritdoc/>
        public override Window Window => window;

        /// <inheritdoc/>
        public override Vector2 Position => Vector2(x, y);

        /// <inheritdoc/>
        public override float X => x;

        /// <inheritdoc/>
        public override float Y => y;

        /// <inheritdoc/>
        public override float WheelDeltaX => wheelDeltaX;

        /// <inheritdoc/>
        public override float WheelDeltaY => wheelDeltaY;

        /// <inheritdoc/>
        public override bool IsRegistered => isRegistered;

        /// <summary>
        /// Creates the SDL2 button state mask that corresponds to the specified button.
        /// </summary>
        /// <param name="button">The button for which to create a state mask.</param>
        /// <returns>The state mask for the specified button.</returns>
        private static int32 SDL_BUTTON(int32 button)
        {
            return 1 << (button - 1);
        }

        /// <summary>
        /// Creates the SDL2 button state mask that corresponds to the specified button.
        /// </summary>
        /// <param name="button">The button for which to create a state mask.</param>
        /// <returns>The state mask for the specified button.</returns>
        private static int32 SDL_BUTTON(MouseButton button)
        {
            switch (button)
            {
                case MouseButton.None:
                    return 0;
                case MouseButton.Left:
                    return SDL_BUTTON(1);
                case MouseButton.Middle:
                    return SDL_BUTTON(2);
                case MouseButton.Right:
                    return SDL_BUTTON(3);
                case MouseButton.XButton1:
                    return SDL_BUTTON(4);
                case MouseButton.XButton2:
                    return SDL_BUTTON(5);
            }
#unwarn
            Runtime.ArgumentError("button");
        }

        /// <summary>
        /// Gets the Framework MouseButton value that corresponds to the specified SDL2 button value.
        /// </summary>
        /// <param name="value">The SDL2 button value to convert.</param>
        /// <returns>The Framework MouseButton value that corresponds to the specified SDL2 button value.</returns>
        private static MouseButton GetFrameworkButton(int32 value)
        {
            if (value == 0)
                return MouseButton.None;

            switch ((SDL_MouseButtonFlags)value)
            {
                case .SDL_BUTTON_LEFT:
                    return MouseButton.Left;
                case .SDL_BUTTON_MIDDLE:
                    return MouseButton.Middle;
                case .SDL_BUTTON_RIGHT:
                    return MouseButton.Right;
                case .SDL_BUTTON_X1:
                    return MouseButton.XButton1;
                case .SDL_BUTTON_X2:
                    return MouseButton.XButton2;
            }
#unwarn
            Runtime.ArgumentError("value");
        }

        /// <summary>
        /// Handles SDL2's MOUSEMOTION event.
        /// </summary>
        private void OnMouseMotion(in SDL_MouseMotionEvent evt)
        {
            if (/*!InputSystem.EmulateMouseWithTouchInput &&*/ evt.which == SDL_TOUCH_MOUSEID)
                return;

            if (relativeMode)
            {
                SetMousePosition(evt.windowID, evt.x, evt.y);
                OnMoved(window, evt.x, evt.y, evt.xrel, evt.yrel);
            }
            else
            {
                SetMousePosition(evt.windowID, evt.x, evt.y);
                OnMoved(window, evt.x, evt.y, evt.xrel, evt.yrel);
            }
        }

        /// <summary>
        /// Handles SDL2's MOUSEBUTTONDOWN event.
        /// </summary>
        private void OnMouseButtonDown(in SDL_MouseButtonEvent evt)
        {
            if (/*!InputSystem.EmulateMouseWithTouchInput &&*/ evt.which == SDL_TOUCH_MOUSEID)
                return;

            var window = InputSystem.Backend.GetWindowById((uint32)evt.windowID);
            var button = GetFrameworkButton(evt.button);

            this.states[(int)button].OnDown(false);

            OnButtonPressed(window, button);
        }

        /// <summary>
        /// Handles SDL2's MOUSEBUTTONUP event.
        /// </summary>
        private void OnMouseButtonUp(in SDL_MouseButtonEvent evt)
        {
            if (evt.which == SDL_TOUCH_MOUSEID)
                return;

            var window = InputSystem.Backend.GetWindowById((uint32)evt.windowID);
            var button = GetFrameworkButton(evt.button);

            this.states[(int)button].OnUp();
            
            if (evt.clicks == 1)
            {
                buttonStateClicks |= (uint32)SDL_BUTTON(evt.button);
                OnClick(window, button);
            }

            if (evt.clicks == 2)
            {
                buttonStateDoubleClicks |= (uint32)SDL_BUTTON(evt.button);
                OnDoubleClick(window, button);
            }

            OnButtonReleased(window, button);
        }

        /// <summary>
        /// Handles SDL2's MOUSEWHEEL event.
        /// </summary>
        private void OnMouseWheel(in SDL_MouseWheelEvent evt)
        {
            if (evt.which == SDL_TOUCH_MOUSEID)
                return;

            var window = InputSystem.Backend.GetWindowById((uint32)evt.windowID);
            wheelDeltaX = evt.x;
            wheelDeltaY = evt.y;
            OnWheelScrolled(window, evt.x, evt.y);
        }

        /// <summary>
        /// Flags the device as registered.
        /// </summary>
        private void Register(uint32 windowID)
        {
            var input = (SDL3InputSystem)InputSystem;
            if (input.RegisterMouseDevice(this))
            {
                isRegistered = true;
            }
        }

        /// <summary>
        /// Sets the mouse cursor's position within its window.
        /// </summary>
        private void SetMousePosition(uint32 windowID, float x, float y)
        {
            this.window = InputSystem.Backend.GetWindowById((uint32)windowID);

            /*if (InputSystem.Backend.SupportsHighDensityDisplayModes)
            {
                var scale = window?.Display.DeviceScale ?? 1f;
                this.x = (int32)(x * scale);
                this.y = (int32)(y * scale);
            }
            else*/
            {
                this.x = x;
                this.y = y;
            }
        }

        /// <summary>
        /// Sets the mouse cursor's position based on the device's physical position.
        /// </summary>
        private void SetMousePositionFromDevicePosition(uint32 windowID)
        {
            float x = 0, y = 0;
            SDL_GetMouseState(&x, &y);
            SetMousePosition(windowID, x, y);
        }

        // The device identifier of the touch-based mouse emulator.
        private const uint32 SDL_TOUCH_MOUSEID = ((uint32)(-1));

        // Property values.
        private float x;
        private float y;
        private float wheelDeltaX;
        private float wheelDeltaY;
        private bool isRegistered;
        private Window window;

        // State values.
        private InternalButtonState[] states;
        private uint32 buttonStateClicks;
        private uint32 buttonStateDoubleClicks;
        private bool ignoredFirstMouseMotionEvent;
        private bool relativeMode;
    }
}
