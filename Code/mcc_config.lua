-- This table belongs to the mod environment, not to persistent save data.
local previous = rawget(_G, "MCC")
if previous and previous.Shutdown then previous.Shutdown("code_reload") end
rawset(_G, "MCC", {
    Config = {
        ENABLE_MOUSE_MODE = true,
        ENABLE_SPEED_BOOST = true,
        DEBUG_LOGS = false,
        DEBUG_INPUT = false,
        TOGGLE_BUTTON = "RightThumbClick",
        LEFT_CLICK_BUTTON = "ButtonA",
        RIGHT_CLICK_BUTTON = "ButtonB",
        WHEEL_UP_BUTTON = "LeftShoulder",
        WHEEL_DOWN_BUTTON = "RightShoulder",
        MENU_BUTTON = "Start",
        SPEED_BOOST_BUTTON = "LeftTrigger", -- hold L2 / LT
        CURSOR_SPEED = 900, -- pixels/second at 1080p; scales with screen height
        CURSOR_BOOST_PERCENT = 250, -- 2.5x normal speed while held
        STICK_DEADZONE = 6000, -- radial, out of 32767
        DOUBLE_CLICK_MS = 300,
        DOUBLE_CLICK_DISTANCE = 6, -- pixels at 1080p
    },
    active = false,
    boost_active = false,
    transitioning = false,
    held = {},
    swallowed = {},
    clicks = {},
    last_clicks = {},
    wheels = {},
})
