local M = MCC

-- Software cursor patterned on CommonLua/X/MouseViaGamepad.lua. Movement is
-- explicitly sourced from LeftThumb, independent of native gamepad mouse settings.
DefineClass.MCCCursor = {
    __parents = { "XWindow" },
    Id = "idMCCCursor",
    IdNode = true,
    HandleMouse = false,
    Dock = "box",
    ZOrder = 10000000,
    DrawOnTop = true,
    Clip = false,
    UseClipBox = false,
}

function MCCCursor:Init()
    local image = XImage:new({
        Id = "idCursor", HAlign = "left", VAlign = "top",
        HandleMouse = false, Clip = false, UseClipBox = false,
    }, self)
    image:AddDynamicPosModifier({ id = "cursor", target = "gamepad" })
    image:SetImage(const.DefaultMouseCursor)
    M.StyleCursor(image, M.Config)
end

function M.UpdateCursorVisibility()
    if not M.cursor then return end
    local visible = next(ShowMouseReasons) ~= nil
    for reason in pairs(ForceHideMouseReasons) do
        if reason ~= "MouseCursorConsoles" and reason ~= "MouseDisconnected" then
            visible = false
        end
    end
    if next(ForceShowMouseReasons) then visible = true end
    M.cursor:SetVisible(visible)
end

local function velocity(axis_x, axis_y, length, height, boosted, cfg)
    local deadzone = cfg.STICK_DEADZONE
    if length > deadzone then
        local magnitude = Min(length, 32767) - deadzone
        if cfg.RESPONSE_CURVE == "Gradual" then magnitude = MulDivRound(magnitude, magnitude, 32767 - deadzone) end
        local speed = MulDivRound(boosted and cfg.CURSOR_FAST_SPEED or cfg.CURSOR_SPEED, height, 1080)
        local rate = MulDivRound(speed * 1000, magnitude, 32767 - deadzone)
        return MulDivRound(axis_x, rate, length), -MulDivRound(axis_y, rate, length)
    end
    return 0, 0
end

-- Pure arithmetic separated from engine IO for deterministic movement checks.
function M.MoveCursor(x, y, axis_x, axis_y, length, dt, width, height, boosted, config)
    local vx, vy = velocity(axis_x, axis_y, length, height, boosted, config or M.Config)
    dt = Clamp(dt, 0, 50)
    x, y = x + MulDivRound(vx, dt, 1000), y + MulDivRound(vy, dt, 1000)
    return Clamp(x, 0, Max(0, width - 1) * 1000), Clamp(y, 0, Max(0, height - 1) * 1000)
end

-- Shared by the real cursor and test area. Filter velocity, never cursor position,
-- and stop immediately inside the dead zone so smoothing cannot cause drift.
function M.AdvanceCursor(state, ax, ay, length, dt, width, height, boosted, cfg, reference_height)
    cfg = cfg or M.Config
    dt = Clamp(dt, 0, 50)
    if dt == 0 then return state.x, state.y end
    local vx, vy = velocity(ax, ay, length, reference_height or height, boosted, cfg)
    if cfg.SMOOTHING_MS > 0 and length > cfg.STICK_DEADZONE then
        vx = (state.vx or 0) + MulDivRound(vx - (state.vx or 0), dt, cfg.SMOOTHING_MS + dt)
        vy = (state.vy or 0) + MulDivRound(vy - (state.vy or 0), dt, cfg.SMOOTHING_MS + dt)
    end
    state.vx, state.vy = vx, vy
    state.x = Clamp(state.x + MulDivRound(vx, dt, 1000), 0, Max(0, width - 1) * 1000)
    state.y = Clamp(state.y + MulDivRound(vy, dt, 1000), 0, Max(0, height - 1) * 1000)
    return state.x, state.y
end

function M.SetSpeedBoost(boosted)
    if M.boost_active == boosted then return end
    M.boost_active = boosted
    M.InputLog("speed_boost_changed", {
        active = boosted, controller = M.controller,
        button = M.Config.SPEED_BOOST_BUTTON,
        speed = boosted and M.Config.CURSOR_FAST_SPEED or M.Config.CURSOR_SPEED,
    })
end

function M.UpdateSpeedBoost()
    -- Read current physical state every frame, so a missed button-up event
    -- cannot leave the speed boosted. Only the mode's owning controller counts.
    local boosted = M.active and M.Config.ENABLE_SPEED_BOOST == true
        and XInput.IsCtrlButtonPressed(M.controller, M.Config.SPEED_BOOST_BUTTON) == true
    M.SetSpeedBoost(boosted)
    return boosted
end

function M.SetCursorPosition(pos)
    M.position = pos
    GamepadMouseSetPos(pos)
    terminal.SetMousePos(pos)
    -- last_pos_event is required by terminal.MouseEvent for OnMousePos.
    terminal.MouseEvent("OnMousePos", pos, nil, "gamepad", true)
end

function M.ApplyMousePositionOverride()
    local original = terminal.GetMousePos
    M.original_mouse_position = original
    -- MarsGamepad.lua already wraps this API for its virtual cursor. Keyboard
    -- style otherwise reads an asynchronous hardware warp (one frame behind in
    -- native tests), which would disagree with the software cursor on clicks.
    M.mouse_position_override = function(...)
        if M.active and M.position then return M.position end
        return original(...)
    end
    terminal.GetMousePos = M.mouse_position_override
end

function M.RestoreMousePositionOverride()
    if terminal.GetMousePos == M.mouse_position_override then
        terminal.GetMousePos = M.original_mouse_position
    else
        -- Another mod owns the current wrapper; leave its chain intact. Our
        -- retained closure is inert when inactive and calls its saved original.
        M.Log("Cursor", "position_override_retained_by_other_owner", {})
    end
    M.original_mouse_position, M.mouse_position_override = nil, nil
end

function MCCCursor:TrackLeftStick()
    local last_time = RealTime()
    while M.active and M.cursor == self do
        WaitNextFrame()
        if not M.active or M.cursor ~= self then return end
        if M.Config.ENABLE_MOUSE_MODE ~= true then
            M.RestoreVanillaBehavior("feature_disabled")
            return
        end
        if not XInput.IsControllerConnected(M.controller) then
            M.RestoreVanillaBehavior("controller_disconnected")
            return
        end
        local state = XInput.CurrentState[M.controller]
        local time = RealTime()
        local boosted = M.UpdateSpeedBoost()
        if type(state) == "table" and state.LeftThumb then
            local ax, ay = state.LeftThumb:xy()
            local width, height = UIL.GetScreenSizeXY()
            M.x, M.y = M.AdvanceCursor(M.motion, ax, ay, state.LeftThumb:Len2D(), time - last_time, width, height, boosted)
            local pos = point(MulDivRound(M.x, 1, 1000), MulDivRound(M.y, 1, 1000))
            if pos ~= M.position then M.SetCursorPosition(pos) end
        end
        last_time = time
    end
end

function M.CreateCursor()
    local width, height = UIL.GetScreenSizeXY()
    M.x, M.y = MulDivRound(width, 1000, 2), MulDivRound(height, 1000, 2)
    if M.Config.REMEMBER_POSITION and M.remembered_position then
        local saved = M.remembered_position
        M.x = Clamp(MulDivRound(saved.x, width, saved.width), 0, (width - 1) * 1000)
        M.y = Clamp(MulDivRound(saved.y, height, saved.height), 0, (height - 1) * 1000)
    end
    M.motion = { x = M.x, y = M.y }
    M.cursor = MCCCursor:new({}, terminal.desktop)
    M.cursor:Open()
    M.ApplyMousePositionOverride()
    ForceHideMouseCursor("MouseCursorConsoles")
    ShowMouseCursor("MouseCursorConsoles")
    M.UpdateCursorVisibility()
    M.SetCursorPosition(point(MulDivRound(M.x, 1, 1000), MulDivRound(M.y, 1, 1000)))
    M.cursor:CreateThread("MCCLeftStick", M.cursor.TrackLeftStick, M.cursor)
end

function M.DestroyCursor()
    if M.Config.REMEMBER_POSITION and M.x and M.y then
        local width, height = UIL.GetScreenSizeXY()
        M.remembered_position = { x = M.x, y = M.y, width = width, height = height }
    end
    M.motion = nil
    local cursor = M.cursor
    M.cursor = nil
    if cursor and cursor.window_state ~= "destroying" then cursor:delete() end
    M.RestoreMousePositionOverride()
    HideMouseCursor("MouseCursorConsoles")
    UnforceHideMouseCursor("MouseCursorConsoles")
end
