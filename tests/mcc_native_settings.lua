-- Native UI/persistence integration in an owned Windows debug process.
-- Simulates controller state only; restores preferences and control style.
rawset(_G, "MCCNativeSettingsReport", { status = "running", checks = {} })
CreateRealTimeThread(function()
    local report = MCCNativeSettingsReport
    local mod, original_style = Mods.MouseCursorConsoles, GetUIStyle()
    local env, m = mod.env, mod.env.MCC
    local original_input = rawget(env, "XInput")
    local original_controller = rawget(env, "ActiveController")
    local saved = AccountStorage.ModPersistentData and AccountStorage.ModPersistentData[mod.id]
    local saved_table = env.CurrentModStorageTable.settings
    local original_options = m.ReadSettings(mod.options)
    local options, host
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
        rawset(env, "ActiveController", 0)
        ChangeGamepadUIStyle({ [1] = "gamepad" })
        options = OptionsDlg:new({}, terminal.desktop)
        options:Open()
        host = options[1]
        Sleep(150)
        for _, row in ipairs(host:ResolveId("idList")) do
            if row.context.id == "Controls" then row:OnPress(); break end
        end
        Sleep(150)
        local dlg = m.OpenSettings(host)
        Sleep(150)
        check(dlg.window_state == "open" and not m.active, "settings open without mouse mode")
        check(#dlg.draft:GetProperties() == 15, "all private Controls definitions loaded")
        local list = dlg:ResolveId("idList")
        local panel, preview = dlg:ResolveId("idPanel"), dlg:ResolveId("idPreview")
        check(#list == 15 and list.VScroll == "" and not list.MouseScroll,
            "all fifteen settings appear together without a scrollbar or mouse scrolling")
        check(list[15].box:maxy() <= panel.box:maxy() and dlg:ResolveId("idHelp").box:maxy() <= panel.box:maxy(),
            "last setting and instructions fit above the footer")
        check(preview.box:minx() > list.box:maxx() and preview.box:sizex() == preview.box:sizey()
            and preview.box:sizey() > panel.box:sizey() / 2,
            "right preview is a large square with equal width and height")
        local first_y = list[1].box:miny()
        for i = 1, 14 do list:OnShortcut("DPadDown", "gamepad") end
        check(list:GetFocusedItem() == 15 and list[1].box:miny() == first_y,
            "D-pad reaches the final binding without scrolling")
        list:SetSelection(1)
        local slider = list[1].idSlider
        check(slider and slider.idThumb:GetImage() == "UI/CommonRemaster/in_slider.png", "vanilla gold slider artwork")
        local old_speed = dlg.draft:GetProperty("CURSOR_SPEED")
        list[1]:OnShortcut("DPadRight", "gamepad")
        check(dlg.draft:GetProperty("CURSOR_SPEED") == old_speed + 50, "D-pad adjusts native slider")
        list[1]:OnShortcut("LeftThumbRight", "gamepad")
        check(dlg.draft:GetProperty("CURSOR_SPEED") == old_speed + 50, "left stick does not adjust the basic slider")
        local selected = list:GetFocusedItem()
        list:OnShortcut("LeftThumbDown", "gamepad")
        check(not list.LeftThumbScroll and list:GetFocusedItem() == selected, "left stick does not navigate basic rows")
        check(m.Config.CURSOR_SPEED == original_options.CURSOR_SPEED, "draft does not alter runtime before apply")
        dlg.draft:SetProperty("CURSOR_SIZE", 180)
        Sleep(50)
        check(dlg:ResolveId("idPreviewCursor"):GetImageScale() == point(1800,1800), "size previews before applying")
        local start = dlg.preview_motion.x
        fake.CurrentState[0].LeftThumb = point(32767,0)
        Sleep(80)
        check(dlg.preview_motion.x > start, "left stick moves preview immediately while all settings are visible")
        fake.CurrentState[0].LeftThumb = point(0,0)
        check(_InternalTranslate(list[5].Text) == "Stick response: Linear", "choice labels render readable text")
        list[5]:OnShortcut("LeftThumbRight", "gamepad")
        check(dlg.draft:GetProperty("RESPONSE_CURVE") == "Linear", "left stick cannot change choice settings")
        local deadzone = dlg.draft:GetProperty("STICK_DEADZONE")
        list[4]:OnShortcut("LeftThumbRight", "gamepad")
        check(dlg.draft:GetProperty("STICK_DEADZONE") == deadzone, "left stick cannot change tuning sliders")
        list[5]:OnPress()
        check(dlg.draft:GetProperty("RESPONSE_CURVE") == "Gradual", "response curve can be changed")
        local old_binding = dlg.draft:GetProperty("TOGGLE_BUTTON")
        list[9]:OnPress()
        check(dlg.draft:GetProperty("TOGGLE_BUTTON") ~= old_binding, "binding choice can be changed")
        dlg.draft:SetProperty("TOGGLE_BUTTON", "ButtonA")
        terminal.Shortcut("ButtonX", "gamepad")
        check(m.settings_dialog == dlg and m.Config.CURSOR_SPEED == original_options.CURSOR_SPEED, "duplicate bindings block Apply atomically")
        terminal.Shortcut("ButtonY", "gamepad")
        check(dlg.draft:GetProperty("CURSOR_SPEED") == m.SettingDefaults.CURSOR_SPEED
            and dlg.draft:GetProperty("CURSOR_SIZE") == 100, "Reset restores draft defaults")
        dlg.draft:SetProperty("CURSOR_SPEED", 700)
        terminal.Shortcut("ButtonB", "gamepad")
        check(not m.settings_dialog and m.Config.CURSOR_SPEED == original_options.CURSOR_SPEED, "Cancel discards draft")
        dlg = m.OpenSettings(host)
        dlg.draft:SetProperty("CURSOR_SPEED", 650)
        dlg.draft:SetProperty("CURSOR_SIZE", 150)
        terminal.Shortcut("ButtonX", "gamepad")
        Sleep(250)
        check(not m.settings_dialog and m.Config.CURSOR_SPEED == 650, "Apply closes and updates runtime")
        local read_err, data = env.ReadModPersistentData()
        local decode_err, stored = LuaCodeToTuple(data, env)
        check(not read_err and not decode_err and stored.settings.values.CURSOR_SIZE == 150,
            "Apply writes through supported persistent mod storage")
        mod.options:SetProperty("CURSOR_SIZE", 100)
        m.LoadSettings()
        check(mod.options:GetProperty("CURSOR_SIZE") == 150, "saved preferences reload into native options")
        dlg = m.OpenSettings(host)
        check(dlg.draft:GetProperty("CURSOR_SIZE") == 150, "reopening restores applied values")
        dlg:Close("test_cleanup")
        check(terminal.desktop.modal_window ~= dlg, "modal ownership released")
        mod:UnloadOptions()
        dlg = m.OpenSettings(host)
        check(dlg.draft:GetProperty("CURSOR_SPEED") == 650 and dlg.draft:GetProperty("CURSOR_SIZE") == 150,
            "native cache clearing cannot reset private Controls preferences")
        dlg:Close("test_cleanup")
    end)
    if not ok then report.error = tostring(err); report.failed = true end
    m.CloseSettings("test_cleanup")
    if options and options.window_state ~= "destroying" then options:Close() end
    for key, value in pairs(original_options) do mod.options:SetProperty(key, value) end
    m.ApplySettings(mod.options)
    env.CurrentModStorageTable.settings = saved_table
    if AccountStorage.ModPersistentData then AccountStorage.ModPersistentData[mod.id] = saved end
    SaveAccountStorage(100)
    rawset(env, "XInput", original_input)
    rawset(env, "ActiveController", original_controller)
    ChangeGamepadUIStyle({ [1] = original_style })
    report.status = report.failed and "failed" or "passed"
end)
