-- This table belongs to the mod environment, not to persistent save data.
local previous = rawget(_G, "MCC")
if previous and previous.Shutdown then previous.Shutdown("code_reload") end
rawset(_G, "MCC", {
    CursorArtwork = {
        Image = CurrentModPath .. "Images/mcc_cursor.png",
        ResolutionScale = 10, -- vector export: 240x260 pixels at 24x26 logical size
    },
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
        SPEED_BOOST_BUTTON = "LeftThumbClick", -- hold L3 / Xbox left-stick click
        CURSOR_SPEED = 900, -- pixels/second at 1080p; scales with screen height
        CURSOR_FAST_SPEED = 2250, -- independent pixels/second at 1080p
        CURSOR_SIZE = 100, -- percent
        CURSOR_COLOR = "White",
        RESPONSE_CURVE = "Linear",
        SMOOTHING_MS = 0,
        REMEMBER_POSITION = true,
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
