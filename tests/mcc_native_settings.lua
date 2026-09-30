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
            return value == true or type(value) == "number" and value >= XInput.GetButtonTreshold(key)
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
        local native_number
        for _, row in ipairs(host:ResolveId("idList")) do
            if row.idSlider then native_number = row; break end
        end
        local native_scale = native_number.idName.scale
        local native_slider_width = native_number.idSlider.box:sizex()
        local native_list = host:ResolveId("idList")
        local native_row_step = native_list[3].box:miny() - native_list[2].box:miny()
        local dlg = m.OpenSettings(host)
        Sleep(150)
        check(dlg.window_state == "open" and not m.active, "settings open without mouse mode")
        check(#dlg.draft:GetProperties() == 15, "all private Controls definitions loaded")
        local list = dlg:ResolveId("idList")
        local panel, preview = dlg:ResolveId("idPanel"), dlg:ResolveId("idPreview")
        check(#list == 15 and list.VScroll == "" and not list.MouseScroll,
            "all fifteen settings appear together without a scrollbar or mouse scrolling")
        check(list[15].box:maxy() <= panel.box:maxy(), "all native-size settings fit above the footer")
        check(list[1].idName.scale == native_scale and list[5].idText.scale == native_scale
            and list[1].idSlider.box:sizex() == native_slider_width,
            "option text and sliders use the same size as native Controls")
        local same_spacing = true
        for i = 2, #list do
            local difference = list[i].box:miny() - list[i - 1].box:miny() - native_row_step
            if difference < -1 or difference > 1 then same_spacing = false end
        end
        check(same_spacing, "all rows match the vertical spacing of native Controls")
        local label = dlg:ResolveId("idPreviewLabel")
        check(#preview == 2 and _InternalTranslate(label.Text) == "Test area"
            and label.box:minx() >= preview.box:minx() and label.box:miny() >= preview.box:miny()
            and label.box:maxx() < preview.box:minx() + preview.box:sizex() / 2
            and label.box:maxy() < preview.box:miny() + preview.box:sizey() / 2
            and not dlg:ResolveId("idStatus"):GetVisible(),
            "Test area appears inside the upper-left corner without permanent status text")
        check(preview.box:minx() > list.box:maxx() and preview.box:sizex() == preview.box:sizey()
            and preview.box:sizey() > panel.box:sizey() / 2,
            "right preview is a large square with equal width and height")
        local screen_width, screen_height = UIL.GetScreenSizeXY()
        check(preview.box:minx() + preview.box:maxx() == 2 * MulDivRound(screen_width, 3, 4)
            and preview.box:miny() + preview.box:maxy() == 2 * MulDivRound(screen_height, 1, 2),
            "square is centered in the right half of the screen")
        check(list[5].RolloverTemplate == list[6].RolloverTemplate
            and list[5].RolloverAnchor == "right" and list[5].RolloverOnFocus
            and _InternalTranslate(list[5].RolloverText):find("Gradual: finer control", 1, true),
            "stick response uses the same right-side explanation tooltip as Smoothing")
        check(dlg:ResolveId("idPreviewCursor"):GetImage() == m.CursorArtwork.Image
            and dlg:ResolveId("idPreviewCursor"):CalcSrcRect():sizex() == 240
            and dlg:ResolveId("idPreviewCursor"):CalcSrcRect():sizey() == 260,
            "preview uses the tightly bounded high-resolution cursor artwork")
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
        dlg.draft:SetProperty("CURSOR_SIZE", 300)
        Sleep(50)
        check(dlg:ResolveId("idPreviewCursor"):GetImageScale() == point(300,300), "maximum cursor size previews before applying")
        local start = dlg.preview_motion.x
        fake.CurrentState[0].LeftThumb = point(32767,0)
        Sleep(80)
        check(dlg.preview_motion.x > start, "left stick moves preview immediately while all settings are visible")
        local saved_boost = dlg.draft:GetProperty("SPEED_BOOST_BUTTON")
        local saved_filter = dlg.draft:GetProperty("SMOOTHING_MS")
        dlg.draft:SetProperty("SPEED_BOOST_BUTTON", "LeftThumbClick")
        dlg.draft:SetProperty("SMOOTHING_MS", 0)
        fake.CurrentState[0].LeftThumbClick = true
        Sleep(60)
        check(dlg.preview_motion.vx == MulDivRound(dlg.draft:GetProperty("CURSOR_FAST_SPEED"), screen_height, 1080) * 1000,
            "holding L3 / Xbox LS click activates configured fast preview speed")
        fake.CurrentState[0].LeftThumbClick = false
        Sleep(60)
        check(dlg.preview_motion.vx == MulDivRound(dlg.draft:GetProperty("CURSOR_SPEED"), screen_height, 1080) * 1000,
            "releasing the stick click restores normal preview speed")
        fake.CurrentState[0].LeftTrigger = 255
        Sleep(60)
        check(dlg.preview_motion.vx == MulDivRound(dlg.draft:GetProperty("CURSOR_SPEED"), screen_height, 1080) * 1000,
            "L2 / LT does not boost the preview with the stick-click binding")
        fake.CurrentState[0].LeftTrigger = 0
        dlg.draft:SetProperty("SPEED_BOOST_BUTTON", saved_boost)
        dlg.draft:SetProperty("SMOOTHING_MS", saved_filter)
        fake.CurrentState[0].LeftThumb = point(0,0)
        local saved_speed, saved_smoothing = dlg.draft:GetProperty("CURSOR_SPEED"), dlg.draft:GetProperty("SMOOTHING_MS")
        dlg.draft:SetProperty("CURSOR_SPEED", 4000)
        dlg.draft:SetProperty("SMOOTHING_MS", 0)
        for _, corner in ipairs({
            { name = "bottom right", x = 32767, y = -32767, right = true, bottom = true },
            { name = "top right", x = 32767, y = 32767, right = true },
            { name = "top left", x = -32767, y = 32767 },
            { name = "bottom left", x = -32767, y = -32767, bottom = true },
        }) do
            fake.CurrentState[0].LeftThumb = point(corner.x, corner.y)
            Sleep(600)
            local cursor = dlg:ResolveId("idPreviewCursor").box
            local bounds = preview.content_box
            local dx = corner.right and cursor:maxx() - bounds:maxx() or cursor:minx() - bounds:minx()
            local dy = corner.bottom and cursor:maxy() - bounds:maxy() or cursor:miny() - bounds:miny()
            check(dx >= -2 and dx <= 2 and dy >= -2 and dy <= 2
                and bounds:sizex() == bounds:sizey(), "cursor reaches " .. corner.name .. " without shrinking the square")
        end
        fake.CurrentState[0].LeftThumb = point(0,0)
        dlg.draft:SetProperty("CURSOR_SPEED", saved_speed)
        dlg.draft:SetProperty("SMOOTHING_MS", saved_smoothing)
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
        check(dlg:ResolveId("idStatus"):GetVisible(), "validation errors remain visible after removing instructions")
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
