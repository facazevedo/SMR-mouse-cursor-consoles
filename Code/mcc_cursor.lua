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

-- Pure arithmetic separated from engine IO for deterministic movement checks.
function M.MoveCursor(x, y, axis_x, axis_y, length, dt, width, height)
    local deadzone = M.Config.STICK_DEADZONE
    if length > deadzone then
        local magnitude = Min(length, 32767) - deadzone
        local speed = MulDivRound(M.Config.CURSOR_SPEED, height, 1080)
        local distance = MulDivRound(speed * Min(dt, 50), magnitude, 32767 - deadzone)
        x = x + MulDivRound(axis_x, distance, length)
        y = y - MulDivRound(axis_y, distance, length)
    end
    return Clamp(x, 0, Max(0, width - 1) * 1000), Clamp(y, 0, Max(0, height - 1) * 1000)
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
        if type(state) == "table" and state.LeftThumb then
            local ax, ay = state.LeftThumb:xy()
            local width, height = UIL.GetScreenSizeXY()
            M.x, M.y = M.MoveCursor(M.x, M.y, ax, ay, state.LeftThumb:Len2D(), time - last_time, width, height)
            local pos = point(MulDivRound(M.x, 1, 1000), MulDivRound(M.y, 1, 1000))
            if pos ~= M.position then M.SetCursorPosition(pos) end
        end
        last_time = time
    end
end

function M.CreateCursor()
    local width, height = UIL.GetScreenSizeXY()
    M.x, M.y = MulDivRound(width, 1000, 2), MulDivRound(height, 1000, 2)
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
    local cursor = M.cursor
    M.cursor = nil
    if cursor and cursor.window_state ~= "destroying" then cursor:delete() end
    M.RestoreMousePositionOverride()
    HideMouseCursor("MouseCursorConsoles")
    UnforceHideMouseCursor("MouseCursorConsoles")
end
