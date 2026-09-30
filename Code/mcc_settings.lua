-- Owns validated preferences and persistence; no UI or game-save state.
local M = MCC
M.SettingKeys = {
    "CURSOR_SPEED", "CURSOR_FAST_SPEED", "CURSOR_SIZE", "STICK_DEADZONE",
    "RESPONSE_CURVE", "SMOOTHING_MS", "CURSOR_COLOR", "REMEMBER_POSITION",
    "TOGGLE_BUTTON", "SPEED_BOOST_BUTTON", "LEFT_CLICK_BUTTON", "RIGHT_CLICK_BUTTON",
    "WHEEL_UP_BUTTON", "WHEEL_DOWN_BUTTON", "MENU_BUTTON",
}
M.SettingDefaults = {}
for _, key in ipairs(M.SettingKeys) do M.SettingDefaults[key] = M.Config[key] end

-- Private Controls-page schema: no ModItemOption registrations in the general menu.
M.SettingProperties = {
    { id = "CURSOR_SPEED", name = Untranslated("Normal cursor speed"), editor = "number", default = M.SettingDefaults.CURSOR_SPEED, help = "Pixels per second at 1080p. Small stick movements travel more slowly.", min = 50, max = 4000, step = 50, slider = true, show_value_text = true, dpad_only = true },
    { id = "CURSOR_FAST_SPEED", name = Untranslated("Fast cursor speed"), editor = "number", default = M.SettingDefaults.CURSOR_FAST_SPEED, help = "Absolute speed while holding the boost button. Must be at least normal speed.", min = 50, max = 8000, step = 50, slider = true, show_value_text = true, dpad_only = true },
    { id = "CURSOR_SIZE", name = Untranslated("Cursor size %"), editor = "number", default = M.SettingDefaults.CURSOR_SIZE, help = "Scale the cursor image without changing its click position.", min = 50, max = 300, step = 10, slider = true, show_value_text = true, dpad_only = true },
    { id = "STICK_DEADZONE", name = Untranslated("Stick dead zone"), editor = "number", default = M.SettingDefaults.STICK_DEADZONE, help = "Radial threshold out of 32767. Increase to reduce drift; high values need more stick travel.", min = 0, max = 16000, step = 500, slider = true, show_value_text = true, dpad_only = true },
    { id = "RESPONSE_CURVE", name = Untranslated("Stick response"), editor = "choice", default = M.SettingDefaults.RESPONSE_CURVE, help = "Gradual gives finer control near the center; full-stick speed is unchanged.", items = { { value = "Linear" }, { value = "Gradual" } } },
    { id = "SMOOTHING_MS", name = Untranslated("Smoothing (ms)"), editor = "number", default = M.SettingDefaults.SMOOTHING_MS, help = "Optional velocity smoothing. Zero disables it. Higher values add input delay; release stops immediately.", min = 0, max = 150, step = 10, slider = true, show_value_text = true, dpad_only = true },
    { id = "CURSOR_COLOR", name = Untranslated("Cursor color"), editor = "choice", default = M.SettingDefaults.CURSOR_COLOR, help = "Tint the cursor for visibility. Outline comes from the game cursor artwork.", items = { { value = "White" }, { value = "Yellow" }, { value = "Cyan" } } },
    { id = "REMEMBER_POSITION", name = Untranslated("Remember cursor position"), editor = "bool", default = M.SettingDefaults.REMEMBER_POSITION, help = "Resume at the previous position when toggling on in this session. Settings persist; cursor coordinates do not enter saves." },
    { id = "TOGGLE_BUTTON", name = Untranslated("Mouse-mode toggle"), editor = "choice", default = M.SettingDefaults.TOGGLE_BUTTON, help = "All bindings must be different. Native construction modifiers are not emulated in mouse mode.", items = { { value = "RightThumbClick" }, { value = "LeftThumbClick" } } },
    { id = "SPEED_BOOST_BUTTON", name = Untranslated("Hold for fast movement"), editor = "choice", default = M.SettingDefaults.SPEED_BOOST_BUTTON, help = "All bindings must be different. Native construction modifiers are not emulated in mouse mode.", items = { { value = "RightThumbClick" }, { value = "LeftThumbClick" }, { value = "ButtonA" }, { value = "ButtonB" }, { value = "ButtonX" }, { value = "ButtonY" }, { value = "LeftShoulder" }, { value = "RightShoulder" }, { value = "Start" }, { value = "DPadUp" }, { value = "DPadDown" }, { value = "DPadLeft" }, { value = "DPadRight" }, { value = "LeftTrigger" }, { value = "RightTrigger" } } },
    { id = "LEFT_CLICK_BUTTON", name = Untranslated("Left click"), editor = "choice", default = M.SettingDefaults.LEFT_CLICK_BUTTON, help = "All bindings must be different. Native construction modifiers are not emulated in mouse mode.", items = { { value = "RightThumbClick" }, { value = "LeftThumbClick" }, { value = "ButtonA" }, { value = "ButtonB" }, { value = "ButtonX" }, { value = "ButtonY" }, { value = "LeftShoulder" }, { value = "RightShoulder" }, { value = "Start" }, { value = "DPadUp" }, { value = "DPadDown" }, { value = "DPadLeft" }, { value = "DPadRight" } } },
    { id = "RIGHT_CLICK_BUTTON", name = Untranslated("Right click"), editor = "choice", default = M.SettingDefaults.RIGHT_CLICK_BUTTON, help = "All bindings must be different. Native construction modifiers are not emulated in mouse mode.", items = { { value = "RightThumbClick" }, { value = "LeftThumbClick" }, { value = "ButtonA" }, { value = "ButtonB" }, { value = "ButtonX" }, { value = "ButtonY" }, { value = "LeftShoulder" }, { value = "RightShoulder" }, { value = "Start" }, { value = "DPadUp" }, { value = "DPadDown" }, { value = "DPadLeft" }, { value = "DPadRight" } } },
    { id = "WHEEL_UP_BUTTON", name = Untranslated("Wheel up"), editor = "choice", default = M.SettingDefaults.WHEEL_UP_BUTTON, help = "All bindings must be different. Native construction modifiers are not emulated in mouse mode.", items = { { value = "RightThumbClick" }, { value = "LeftThumbClick" }, { value = "ButtonA" }, { value = "ButtonB" }, { value = "ButtonX" }, { value = "ButtonY" }, { value = "LeftShoulder" }, { value = "RightShoulder" }, { value = "Start" }, { value = "DPadUp" }, { value = "DPadDown" }, { value = "DPadLeft" }, { value = "DPadRight" } } },
    { id = "WHEEL_DOWN_BUTTON", name = Untranslated("Wheel down"), editor = "choice", default = M.SettingDefaults.WHEEL_DOWN_BUTTON, help = "All bindings must be different. Native construction modifiers are not emulated in mouse mode.", items = { { value = "RightThumbClick" }, { value = "LeftThumbClick" }, { value = "ButtonA" }, { value = "ButtonB" }, { value = "ButtonX" }, { value = "ButtonY" }, { value = "LeftShoulder" }, { value = "RightShoulder" }, { value = "Start" }, { value = "DPadUp" }, { value = "DPadDown" }, { value = "DPadLeft" }, { value = "DPadRight" } } },
    { id = "MENU_BUTTON", name = Untranslated("Menu / Escape"), editor = "choice", default = M.SettingDefaults.MENU_BUTTON, help = "All bindings must be different. Native construction modifiers are not emulated in mouse mode.", items = { { value = "RightThumbClick" }, { value = "LeftThumbClick" }, { value = "ButtonA" }, { value = "ButtonB" }, { value = "ButtonX" }, { value = "ButtonY" }, { value = "LeftShoulder" }, { value = "RightShoulder" }, { value = "Start" }, { value = "DPadUp" }, { value = "DPadDown" }, { value = "DPadLeft" }, { value = "DPadRight" } } },
}

function M.NewSettingsDraft()
    local draft = PropertyObject:new({ properties = M.SettingProperties })
    -- The native loader can clear its option cache when no generic options are
    -- registered. The validated runtime values remain the authority for this UI.
    for _, key in ipairs(M.SettingKeys) do draft:SetProperty(key, M.Config[key]) end
    return draft
end

M.ButtonLabels = {
    RightThumbClick = "R3 / Right-stick click", LeftThumbClick = "L3 / Left-stick click",
    ButtonA = "Cross / A", ButtonB = "Circle / B", ButtonX = "Square / X",
    ButtonY = "Triangle / Y", LeftShoulder = "L1 / LB", RightShoulder = "R1 / RB",
    LeftTrigger = "L2 / LT", RightTrigger = "R2 / RT", Start = "Options / Menu",
    DPadUp = "D-pad Up", DPadDown = "D-pad Down", DPadLeft = "D-pad Left", DPadRight = "D-pad Right",
}

function M.ReadSettings(options)
    local values = {}
    for _, key in ipairs(M.SettingKeys) do
        local value = options and options:GetProperty(key)
        if value == nil then value = M.SettingDefaults[key] end
        values[key] = value
    end
    return values
end

function M.ValidateSettings(values)
    for key, limits in pairs({ CURSOR_SPEED = {50, 4000}, CURSOR_FAST_SPEED = {50, 8000},
        CURSOR_SIZE = {50, 300}, STICK_DEADZONE = {0, 16000}, SMOOTHING_MS = {0, 150} }) do
        local value = values[key]
        if type(value) ~= "number" or value % 1 ~= 0 or value < limits[1] or value > limits[2] then
            return false, "Invalid " .. key .. ": choose a value within the slider range."
        end
    end
    if values.CURSOR_FAST_SPEED < values.CURSOR_SPEED then
        return false, "Fast cursor speed must be at least normal cursor speed."
    end
    if values.RESPONSE_CURVE ~= "Linear" and values.RESPONSE_CURVE ~= "Gradual" then return false, "Invalid stick response." end
    if values.CURSOR_COLOR ~= "White" and values.CURSOR_COLOR ~= "Yellow" and values.CURSOR_COLOR ~= "Cyan" then return false, "Invalid cursor color." end
    if type(values.REMEMBER_POSITION) ~= "boolean" then return false, "Invalid remember-position setting." end
    if values.TOGGLE_BUTTON ~= "RightThumbClick" and values.TOGGLE_BUTTON ~= "LeftThumbClick" then
        return false, "Use a stick click for the toggle so normal menu navigation remains available."
    end
    local used = {}
    for _, key in ipairs(M.SettingKeys) do
        if key:sub(-7) == "_BUTTON" then
            local value = values[key]
            if not M.ButtonLabels[value] or (key ~= "SPEED_BOOST_BUTTON" and (value == "LeftTrigger" or value == "RightTrigger")) then
                return false, "Unsupported button for " .. key
            end
            if used[value] then return false, "Each action needs a different button: " .. M.ButtonLabels[value] end
            used[value] = true
        end
    end
    return true
end

function M.ApplySettings(options)
    local values = M.ReadSettings(options)
    local ok, reason = M.ValidateSettings(values)
    if not ok then M.Log("Settings", "preferences_rejected", { reason = reason }); return false, reason end
    M.RestoreVanillaBehavior("settings_changed")
    for _, key in ipairs(M.SettingKeys) do M.Config[key] = values[key] end
    if not M.Config.REMEMBER_POSITION then M.remembered_position = nil end
    M.Log("Settings", "preferences_applied", { normal = values.CURSOR_SPEED, fast = values.CURSOR_FAST_SPEED,
        size = values.CURSOR_SIZE, deadzone = values.STICK_DEADZONE, curve = values.RESPONSE_CURVE, smoothing_ms = values.SMOOTHING_MS })
    return true
end

function M.LoadSettings()
    local saved = CurrentModStorageTable and CurrentModStorageTable.settings
    if saved ~= nil then
        if type(saved) ~= "table" or saved.schema ~= 1 or type(saved.values) ~= "table" then
            M.Log("Settings", "storage_rejected", { reason = "unsupported_schema" })
            return false, "Unsupported saved cursor settings."
        end
        local ok, reason = M.ValidateSettings(saved.values)
        if not ok then M.Log("Settings", "storage_rejected", { reason = reason }); return false, reason end
        for _, key in ipairs(M.SettingKeys) do CurrentModOptions:SetProperty(key, saved.values[key]) end
    end
    return M.ApplySettings(CurrentModOptions)
end

function M.SaveSettings(draft)
    local values = M.ReadSettings(draft)
    local ok, reason = M.ValidateSettings(values)
    if not ok then return false, reason end
    if type(CurrentModStorageTable) ~= "table" or type(WriteModPersistentStorageTable) ~= "function" then
        M.Log("Settings", "save_unavailable", {})
        return false, "Mod preference storage is not available. Settings were not saved."
    end
    local previous = CurrentModStorageTable.settings
    CurrentModStorageTable.settings = { schema = 1, values = values }
    local err = WriteModPersistentStorageTable()
    if err then
        CurrentModStorageTable.settings = previous
        M.Log("Settings", "save_failed", { error = err })
        return false, "Could not save cursor settings: " .. tostring(err)
    end
    M.ApplySettings(draft)
    for _, key in ipairs(M.SettingKeys) do
        CurrentModOptions:SetProperty(key, values[key])
    end
    M.Log("Settings", "save_requested", { version = CurrentModDef.version })
    return true
end

function M.StyleCursor(image, config)
    local scale = config.CURSOR_SIZE * 10
    image:SetImageScale(point(scale, scale))
    local color = config.CURSOR_COLOR
    image:SetImageColor(color == "Yellow" and RGB(255, 230, 80)
        or color == "Cyan" and RGB(80, 240, 255) or RGB(255, 255, 255))
end
