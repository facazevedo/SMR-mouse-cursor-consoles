local M = MCC

DefineClass.MCCInput = {
    __parents = { "TerminalTarget" },
    -- Ahead of desktop/gameplay; below the engine's FilterEventsTarget.
    terminal_target_priority = 1000000,
}

local function bucket(collection, controller)
    collection[controller] = collection[controller] or {}
    return collection[controller]
end

function M.EmitMouse(event, button)
    M.InputLog("mouse_event", { event = event, button = button, controller = M.controller })
    return terminal.MouseEvent(event, M.position, button, "gamepad")
end

function M.ReleaseClicks()
    for _, button in ipairs({ "L", "R" }) do
        if M.clicks[button] then
            M.clicks[button] = nil
            M.EmitMouse("OnMouseButtonUp", button)
        end
    end
    M.last_clicks = {}
    M.wheels = {}
end

function M.PressMouse(button)
    if M.clicks[button] then return end
    local time, last = RealTime(), M.last_clicks[button]
    local _, height = UIL.GetScreenSizeXY()
    local distance = MulDivRound(M.Config.DOUBLE_CLICK_DISTANCE, height, 1080)
    local double = last and time - last.time <= M.Config.DOUBLE_CLICK_MS
        and M.position:Dist2D(last.position) <= distance
    M.clicks[button] = true
    if double then
        M.last_clicks[button] = nil
        M.EmitMouse("OnMouseButtonDoubleClick", button)
    else
        M.last_clicks[button] = { time = time, position = M.position }
        M.EmitMouse("OnMouseButtonDown", button)
    end
end

function MCCInput:OnXButtonDown(button, controller)
    local held = bucket(M.held, controller)
    local duplicate = held[button]
    held[button] = true
    if bucket(M.swallowed, controller)[button] then return "break" end
    if M.active and controller ~= M.controller then
        bucket(M.swallowed, controller)[button] = true
        return "break"
    end
    if button == M.Config.TOGGLE_BUTTON and M.Config.ENABLE_MOUSE_MODE == true then
        if not M.active and type(ActiveController) == "number" and ActiveController ~= controller then return end
        bucket(M.swallowed, controller)[button] = true
        if not duplicate then M.Toggle(controller) end
        return "break"
    end
    if not M.active then return end
    bucket(M.swallowed, controller)[button] = true
    if duplicate then return "break" end
    local cfg = M.Config
    if button == cfg.LEFT_CLICK_BUTTON then M.PressMouse("L")
    elseif button == cfg.RIGHT_CLICK_BUTTON then M.PressMouse("R")
    elseif button == cfg.WHEEL_UP_BUTTON then
        M.wheels[button] = true
        M.EmitMouse("OnMouseWheelForward")
    elseif button == cfg.WHEEL_DOWN_BUTTON then
        M.wheels[button] = true
        M.EmitMouse("OnMouseWheelBack")
    elseif button == cfg.MENU_BUTTON then terminal.Shortcut("Escape", "keyboard") end
    return "break"
end

function MCCInput:OnXButtonUp(button, controller)
    bucket(M.held, controller)[button] = nil
    local consumed = bucket(M.swallowed, controller)[button]
    bucket(M.swallowed, controller)[button] = nil
    if M.active and controller == M.controller then
        M.wheels[button] = nil
        local mouse = button == M.Config.LEFT_CLICK_BUTTON and "L"
            or button == M.Config.RIGHT_CLICK_BUTTON and "R"
        if mouse and M.clicks[mouse] then
            M.clicks[mouse] = nil
            M.EmitMouse("OnMouseButtonUp", mouse)
        end
    end
    if M.active or consumed then return "break" end
end

function MCCInput:OnXButtonRepeat(button, controller)
    if M.active and controller == M.controller and M.wheels[button] then
        if button == M.Config.WHEEL_UP_BUTTON then M.EmitMouse("OnMouseWheelForward")
        elseif button == M.Config.WHEEL_DOWN_BUTTON then M.EmitMouse("OnMouseWheelBack") end
    end
    if M.active or bucket(M.swallowed, controller)[button] then return "break" end
end

function MCCInput:OnXNewPacket()
    if M.active then return "break" end
end
