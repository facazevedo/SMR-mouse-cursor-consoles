local M = MCC

local function unavailable(name)
    M.Log("Validation", "activation_refused", { reason = name })
    return false, name
end

function M.Validate()
    for _, name in ipairs({
        "GetUIStyle", "ChangeGamepadUIStyle", "OnUIStyleChangedDialogs",
        "GamepadMouseSetPos", "GamepadMouseGetPos", "GetInGameInterface",
        "ForceHideMouseCursor", "UnforceHideMouseCursor", "ShowMouseCursor", "HideMouseCursor",
        "ResumeRollover", "SuspendRollover", "XDestroyRolloverWindow",
        "RealTime", "WaitNextFrame", "point", "MulDivRound", "Clamp", "Min", "Max",
    }) do
        if type(rawget(_G, name)) ~= "function" then return unavailable("Missing API: " .. name) end
    end
    for name, methods in pairs({
        terminal = { "AddTarget", "RemoveTarget", "MouseEvent", "GetMousePos", "SetMousePos", "Shortcut" },
        XInput = { "IsControllerConnected", "IsCtrlButtonPressed" },
        UIL = { "GetScreenSizeXY" },
    }) do
        local object = rawget(_G, name)
        if type(object) ~= "table" then return unavailable("Missing API table: " .. name) end
        for _, method in ipairs(methods) do
            if type(object[method]) ~= "function" then return unavailable("Missing API: " .. name .. "." .. method) end
        end
    end
    if not terminal.desktop or not rawget(_G, "MCCCursor") or not rawget(_G, "MCCInput") then
        return unavailable("UI classes or desktop are not ready")
    end
    for _, name in ipairs({ "ShowMouseReasons", "ForceHideMouseReasons", "ForceShowMouseReasons", "RolloverSuspendReasons" }) do
        if type(rawget(_G, name)) ~= "table" then return unavailable("Missing cursor state: " .. name) end
    end
    if type(XInput.CurrentState) ~= "table" or type(XInput.Buttons) ~= "table" or not rawget(_G, "hr")
        or type(hr.XBoxLeftThumbLocked) ~= "number" or type(hr.XBoxRightThumbLocked) ~= "number" then
        return unavailable("Controller state or camera lock counters are unavailable")
    end
    local bindings = {}
    for _, key in ipairs({ "TOGGLE_BUTTON", "LEFT_CLICK_BUTTON", "RIGHT_CLICK_BUTTON", "WHEEL_UP_BUTTON", "WHEEL_DOWN_BUTTON", "MENU_BUTTON" }) do
        local value = M.Config[key]
        local known = false
        for _, button in ipairs(XInput.Buttons) do if value == button then known = true end end
        if not known or bindings[value] then return unavailable("Invalid or duplicate binding: " .. key) end
        bindings[value] = true
    end
    if type(M.Config.CURSOR_SPEED) ~= "number" or M.Config.CURSOR_SPEED <= 0
        or type(M.Config.STICK_DEADZONE) ~= "number" or M.Config.STICK_DEADZONE < 0 or M.Config.STICK_DEADZONE >= 32767
        or type(M.Config.DOUBLE_CLICK_MS) ~= "number" or M.Config.DOUBLE_CLICK_MS < 0
        or type(M.Config.DOUBLE_CLICK_DISTANCE) ~= "number" or M.Config.DOUBLE_CLICK_DISTANCE < 0 then
        return unavailable("Invalid cursor speed, dead zone, or double-click configuration")
    end
    return true
end

function M.ApplyModBehavior(controller)
    if M.active then return true end
    if M.Config.ENABLE_MOUSE_MODE ~= true then return false, "Mouse mode is disabled" end
    local ok, reason = M.Validate()
    if not ok then return false, reason end
    if ChangingMap or not GetInGameInterface() then return false, "Open a colony before enabling mouse mode" end
    if not XInput.IsControllerConnected(controller) then return false, "Controller is disconnected" end
    if hr.GamepadMouseEnabled == true or hr.GamepadMouseEnabled == 1 then
        return unavailable("Another virtual mouse is already active")
    end
    local style = GetUIStyle()
    if style ~= "keyboard" and style ~= "gamepad" then
        return unavailable("Unsupported control style: " .. tostring(style))
    end
    M.previous_style = style
    M.previous_mouse = terminal.GetMousePos()
    M.previous_gamepad_mouse = GamepadMouseGetPos()
    M.previous_rollover_suspended = RolloverSuspendReasons[false] == true
    M.controller, M.active, M.transitioning = controller, true, true
    -- Ignore buttons held when entering; a fresh press is required for a click.
    M.swallowed[controller] = M.swallowed[controller] or {}
    for _, button in ipairs(XInput.Buttons) do
        if XInput.IsCtrlButtonPressed(controller, button) then M.swallowed[controller][button] = true end
    end
    -- Transient UI change: never write AccountStorage or call SwitchControls.
    ChangeGamepadUIStyle({ [1] = "keyboard" })
    OnUIStyleChangedDialogs()
    -- Own one increment, preserving any locks held by dialogs or other mods.
    hr.XBoxLeftThumbLocked = hr.XBoxLeftThumbLocked + 1
    hr.XBoxRightThumbLocked = hr.XBoxRightThumbLocked + 1
    M.camera_locked = true
    if M.previous_rollover_suspended then ResumeRollover() end
    M.CreateCursor()
    M.transitioning = false
    M.Log("Lifecycle", "mouse_mode_enabled", { controller = controller, previous_style = style, stick = "LeftThumb", speed = M.Config.CURSOR_SPEED })
    return true
end

function M.RestoreVanillaBehavior(reason, keep_current_style)
    if not M.active then return true end
    M.transitioning = true
    M.ReleaseClicks()
    M.active = false
    M.DestroyCursor()
    XDestroyRolloverWindow(true)
    if M.previous_rollover_suspended and not g_MouseConnected then SuspendRollover() end
    if M.camera_locked then
        hr.XBoxLeftThumbLocked = hr.XBoxLeftThumbLocked - 1
        hr.XBoxRightThumbLocked = hr.XBoxRightThumbLocked - 1
        M.camera_locked = false
    end
    if not keep_current_style and GetUIStyle() ~= M.previous_style then
        ChangeGamepadUIStyle({ [1] = M.previous_style })
        OnUIStyleChangedDialogs()
    end
    terminal.SetMousePos(M.previous_mouse)
    GamepadMouseSetPos(M.previous_gamepad_mouse)
    M.transitioning = false
    M.Log("Lifecycle", "mouse_mode_disabled", { reason = reason, restored_style = GetUIStyle(), controller = M.controller })
    M.controller, M.position = nil, nil
    return true
end

function M.Toggle(controller)
    if M.active then return M.RestoreVanillaBehavior("toggle") end
    local ok, reason = M.ApplyModBehavior(controller)
    if not ok then
        M.Log("Lifecycle", "toggle_refused", { reason = reason })
        CreateMessageBox(terminal.desktop, Untranslated("Mouse Cursor Consoles"), Untranslated(reason))
    end
    return ok, reason
end

function M.Install()
    if M.input or M.Config.ENABLE_MOUSE_MODE ~= true then return end
    local ok = M.Validate()
    if not ok then return end
    M.input = MCCInput:new()
    terminal.AddTarget(M.input)
    M.Log("Lifecycle", "input_registered", { version = CurrentModDef.version, enabled = M.Config.ENABLE_MOUSE_MODE, debug_input = M.Config.DEBUG_INPUT, toggle = M.Config.TOGGLE_BUTTON })
end

function M.Shutdown(reason)
    M.RestoreVanillaBehavior(reason)
    if M.input then terminal.RemoveTarget(M.input); M.input = nil end
    M.held, M.swallowed = {}, {}
    M.Log("Lifecycle", "input_removed", { reason = reason })
end
