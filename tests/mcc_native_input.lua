-- Integration check in a disposable, harness-owned Windows game process.
-- No colony or physical controller is available: only colony eligibility and
-- controller state are simulated, inside this mod's environment. UI, cursor,
-- terminal dispatch, classes, threads, style changes and messages are native.
rawset(_G, "MCCNativeInputReport", { status = "running", checks = {} })
CreateRealTimeThread(function()
    local report = MCCNativeInputReport
    local env = Mods.MouseCursorConsoles.env
    local m = env.MCC
    local session_style = GetUIStyle()
    local original_style, original_left, original_right
    local old_input, old_interface = rawget(env, "XInput"), rawget(env, "GetInGameInterface")
    local window
    local function check(value, name)
        report.checks[#report.checks + 1] = { name = name, passed = not not value }
        if not value then report.failed = true end
    end
    local ok, err = sprocall(function()
        ChangeGamepadUIStyle({ [1] = "gamepad" })
        original_style = GetUIStyle()
        original_left, original_right = hr.XBoxLeftThumbLocked, hr.XBoxRightThumbLocked
        local fake_input = table.copy(XInput)
        fake_input.CurrentState = { [0] = { LeftThumb = point(0, 0), RightThumb = point(0, 0) } }
        fake_input.IsControllerConnected = function(id) return id == 0 end
        fake_input.IsCtrlButtonPressed = function() return false end
        rawset(env, "XInput", fake_input)
        rawset(env, "GetInGameInterface", function() return window end)
        local received = {}
        local function receive(name)
            return function(_, pos, button)
                received[#received + 1] = { event = name, button = button }
                return "break"
            end
        end
        window = XWindow:new({
            Dock = "box", HandleMouse = true, ZOrder = 500000,
            OnMouseButtonDown = receive("down"), OnMouseButtonUp = receive("up"),
            OnMouseButtonDoubleClick = receive("double"),
            OnMouseWheelForward = receive("wheel_up"), OnMouseWheelBack = receive("wheel_down"),
        }, terminal.desktop)
        window:Open()
        window:SetModal(true)
        Sleep(30)
        local function button(event, name) terminal.XEvent(event, name, 0) end
        local function tap(name) button("OnXButtonDown", name); button("OnXButtonUp", name) end
        tap("RightThumbClick")
        check(m.active and m.cursor and m.cursor.window_state == "open", "toggle creates native cursor")
        if not m.active then return end
        check(GetUIStyle() == "keyboard", "temporary PC style")
        local cursor = m.cursor
        check(cursor.visible and cursor.idCursor:GetImage() ~= "", "software cursor is visible with a native cursor image")
        m.ApplyModBehavior(0)
        check(m.cursor == cursor, "enable is idempotent")
        local start = m.position
        fake_input.CurrentState[0].RightThumb = point(32767, 0)
        Sleep(80)
        check(m.position == start, "right stick does not move cursor")
        fake_input.CurrentState[0].LeftThumb = point(32767, 0)
        Sleep(150)
        fake_input.CurrentState[0].LeftThumb = point(0, 0)
        check(m.position:x() > start:x() and m.position:y() == start:y(), "left stick moves cursor right")
        report.positions = { desired = tostring(m.position), native = tostring(terminal.GetMousePos()), drawn = tostring(GamepadMouseGetPos()) }
        check(terminal.GetMousePos() == m.position and GamepadMouseGetPos() == m.position, "native and drawn positions agree")
        tap("ButtonA")
        check(#received == 2 and received[1].event == "down" and received[1].button == "L" and received[2].event == "up", "left click reaches native UI")
        tap("ButtonA")
        check(received[3] and received[3].event == "double" and received[4].event == "up", "double click reaches native UI")
        tap("LeftShoulder"); tap("RightShoulder")
        check(received[5] and received[5].event == "wheel_up" and received[6].event == "wheel_down", "wheel events reach native UI")
        button("OnXButtonDown", "ButtonB")
        tap("RightThumbClick")
        check(not m.active and not m.cursor, "same toggle destroys cursor")
        check(received[7] and received[7].event == "down" and received[7].button == "R" and received[8].event == "up", "toggle releases held right click")
        button("OnXButtonUp", "ButtonB")
        check(#received == 8, "post-toggle release does not leak")
        check(GetUIStyle() == original_style and hr.XBoxLeftThumbLocked == original_left and hr.XBoxRightThumbLocked == original_right, "native style and camera counters restored")
        tap("RightThumbClick"); Msg("OnXInputControllerDisconnected", 0)
        check(not m.active, "disconnect restores mode")
        tap("RightThumbClick"); m.Shutdown("native_test")
        check(not m.active and not m.input, "shutdown removes input")
        m.Install()
        check(m.input ~= nil, "input can be reinstalled")
    end)
    m.RestoreVanillaBehavior("native_test_cleanup")
    rawset(env, "XInput", old_input)
    rawset(env, "GetInGameInterface", old_interface)
    if window then window:delete() end
    ChangeGamepadUIStyle({ [1] = session_style })
    report.error = not ok and tostring(err) or false
    report.status = ok and not report.failed and "passed" or "failed"
    FlushLogFile()
end)
