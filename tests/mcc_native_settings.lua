-- Native UI/persistence integration in an owned Windows debug process.
-- Simulates controller state only; restores preferences and control style.
rawset(_G, "MCCNativeSettingsReport", { status = "running", checks = {} })
CreateRealTimeThread(function()
    local report = MCCNativeSettingsReport
    local mod, original_style = Mods.MouseCursorConsoles, GetUIStyle()
    local env, m = mod.env, mod.env.MCC
    local original_input = rawget(env, "XInput")
    local saved = AccountStorage.ModPersistentData and AccountStorage.ModPersistentData[mod.id]
    local saved_table = env.CurrentModStorageTable.settings
    local original_options = m.ReadSettings(mod.options)
    local function check(value, name)
        report.checks[#report.checks + 1] = { name = name, passed = not not value }
        if not value then report.failed = true end
    end
    local ok, err = sprocall(function()
        local fake = table.copy(XInput)
        fake.CurrentState = { [0] = { LeftThumb = point(0, 0), LeftTrigger = 0 } }
        fake.IsControllerConnected = function(id) return id == 0 end
        fake.IsCtrlButtonPressed = function(id, key)
            local value = fake.CurrentState[id] and fake.CurrentState[id][key]
            return type(value) == "number" and value >= XInput.GetButtonTreshold(key)
        end
        rawset(env, "XInput", fake)
        ChangeGamepadUIStyle({ [1] = "gamepad" })
        local dlg = m.OpenSettings()
        Sleep(150)
        check(dlg.window_state == "open" and not m.active, "settings open without mouse mode")
        check(#mod.options:GetProperties() == 15, "all native option definitions loaded")
        local list = dlg:ResolveId("idList")
        local slider = list[1].idSlider
        check(slider and slider.idThumb:GetImage() == "UI/CommonRemaster/in_slider.png", "vanilla gold slider artwork")
        local old_speed = dlg.draft:GetProperty("CURSOR_SPEED")
        list[1]:OnShortcut("DPadRight", "gamepad")
        check(dlg.draft:GetProperty("CURSOR_SPEED") == old_speed + 50, "D-pad adjusts native slider")
        check(m.Config.CURSOR_SPEED == original_options.CURSOR_SPEED, "draft does not alter runtime before apply")
        dlg.draft:SetProperty("CURSOR_SIZE", 180)
        Sleep(50)
        check(dlg:ResolveId("idPreviewCursor"):GetImageScale() == point(1800,1800), "size previews before applying")
        dlg:BeginTest()
        local start = dlg.preview_motion.x
        fake.CurrentState[0].LeftThumb = point(32767,0)
        Sleep(80)
        check(dlg.testing and dlg.preview_motion.x > start, "left stick moves isolated preview")
        fake.CurrentState[0].LeftThumb = point(0,0)
        terminal.Shortcut("ButtonB", "gamepad")
        check(not dlg.testing and m.settings_dialog == dlg, "B returns from test without closing settings")
        list[5]:OnPress()
        check(dlg.advanced and #list == 16, "Advanced view exposes tuning and bindings")
        check(_InternalTranslate(list[2].Text) == "Stick response: Linear", "Advanced labels render readable text")
        list[2]:OnPress()
        check(dlg.draft:GetProperty("RESPONSE_CURVE") == "Gradual", "response curve can be changed")
        local old_binding = dlg.draft:GetProperty("TOGGLE_BUTTON")
        list[6]:OnPress()
        check(dlg.draft:GetProperty("TOGGLE_BUTTON") ~= old_binding, "binding choice can be changed")
        dlg.draft:SetProperty("TOGGLE_BUTTON", "ButtonA")
        list[15]:OnPress()
        check(m.settings_dialog == dlg and m.Config.CURSOR_SPEED == original_options.CURSOR_SPEED, "duplicate bindings block Apply atomically")
        list[14]:OnPress()
        check(dlg.draft:GetProperty("CURSOR_SPEED") == m.SettingDefaults.CURSOR_SPEED
            and dlg.draft:GetProperty("CURSOR_SIZE") == 100, "Reset restores draft defaults")
        dlg:OnShortcut("ButtonB", "gamepad")
        check(not dlg.advanced, "B returns from Advanced")
        dlg.draft:SetProperty("CURSOR_SPEED", 700)
        dlg:Close("cancel")
        check(not m.settings_dialog and m.Config.CURSOR_SPEED == original_options.CURSOR_SPEED, "Cancel discards draft")
        dlg = m.OpenSettings()
        dlg.draft:SetProperty("CURSOR_SPEED", 650)
        dlg.draft:SetProperty("CURSOR_SIZE", 150)
        dlg:ResolveId("idList")[7]:OnPress()
        Sleep(250)
        check(not m.settings_dialog and m.Config.CURSOR_SPEED == 650, "Apply closes and updates runtime")
        local read_err, data = env.ReadModPersistentData()
        local decode_err, stored = LuaCodeToTuple(data, env)
        check(not read_err and not decode_err and stored.settings.values.CURSOR_SIZE == 150,
            "Apply writes through supported persistent mod storage")
        mod.options:SetProperty("CURSOR_SIZE", 100)
        m.LoadSettings()
        check(mod.options:GetProperty("CURSOR_SIZE") == 150, "saved preferences reload into native options")
        dlg = m.OpenSettings()
        check(dlg.draft:GetProperty("CURSOR_SIZE") == 150, "reopening restores applied values")
        dlg:Close("test_cleanup")
        check(terminal.desktop.modal_window ~= dlg, "modal ownership released")
    end)
    if not ok then report.error = tostring(err); report.failed = true end
    m.CloseSettings("test_cleanup")
    for key, value in pairs(original_options) do mod.options:SetProperty(key, value) end
    m.ApplySettings(mod.options)
    env.CurrentModStorageTable.settings = saved_table
    if AccountStorage.ModPersistentData then AccountStorage.ModPersistentData[mod.id] = saved end
    SaveAccountStorage(100)
    rawset(env, "XInput", original_input)
    ChangeGamepadUIStyle({ [1] = original_style })
    report.status = report.failed and "failed" or "passed"
end)
