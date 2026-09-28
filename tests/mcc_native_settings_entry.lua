-- Follow the Controls route and verify the general Mod Options route is absent.
rawset(_G, "MCCNativeEntryReport", { status = "running", checks = {} })
CreateRealTimeThread(function()
    local report = MCCNativeEntryReport
    local m = Mods.MouseCursorConsoles.env.MCC
    local original_style = GetUIStyle()
    local options
    local function check(value, name)
        report.checks[#report.checks + 1] = { passed = not not value, name = name }
        if not value then report.failed = true end
    end
    local ok, err = sprocall(function()
        ChangeGamepadUIStyle({ [1] = "gamepad" })
        options = OptionsDlg:new({}, terminal.desktop)
        options:Open()
        local host = options[1]
        Sleep(150)
        local list = host:ResolveId("idList")
        local controls
        for _, row in ipairs(list) do
            if row.context.id == "Controls" then controls = row end
        end
        check(controls ~= nil, "Options root exposes Controls")
        check(not Mods.MouseCursorConsoles:HasOptions(), "mod does not advertise a general Mod Options category")
        controls:OnPress()
        Sleep(150)
        list = host:ResolveId("idList")
        local controls_entry = list:ResolveId("idMCCControlsEntry")
        check(controls_entry and list[1] == controls_entry, "Mouse Cursor Consoles is the first Controls row")
        check(#list > 1, "vanilla Controls rows remain available")
        controls_entry:SetFocus()
        terminal.Shortcut("ButtonA", "gamepad")
        Sleep(150)
        check(m.settings_dialog and m.settings_dialog.settings_host == host, "controller confirm opens settings from Controls")
        terminal.Shortcut("ButtonB", "gamepad")
        Sleep(150)
        check(not m.settings_dialog and host.Mode == "properties" and host.mode_param.id == "Controls", "controller back returns to Controls")
        terminal.Shortcut("ButtonA", "gamepad")
        Sleep(150)
        check(m.settings_dialog ~= nil, "controller focus returns to the Controls entry after closing")
        if m.settings_dialog then m.settings_dialog:Close("cancel") end
        list:RequestRespawn()
        Sleep(150)
        local count = 0
        for _, row in ipairs(list) do if row.Id == "idMCCControlsEntry" then count = count + 1 end end
        check(count == 1, "Controls rebuild retains exactly one mod row")
        m.Shutdown("entry_test")
        check(not list:ResolveId("idMCCControlsEntry"), "shutdown removes mod-owned Controls row")
        check(next(m.settings_entries) == nil, "shutdown clears entry ownership")
        m.Install()
        list:RequestRespawn()
        Sleep(150)
        controls_entry = list:ResolveId("idMCCControlsEntry")
        check(controls_entry ~= nil, "reinstallation allows Controls entry again")
        controls_entry:OnPress()
        Sleep(150)
        options:Close()
        check(not m.settings_dialog and next(m.settings_entries) == nil, "closing Controls parent removes modal and entry ownership")

        options = OptionsDlg:new({}, terminal.desktop)
        options:Open()
        host = options[1]
        -- Inspect the shared list even if another enabled mod exposes it.
        host:SetMode("mod_choice")
        Sleep(150)
        list = host:ResolveId("idList")
        local duplicate
        for _, row in ipairs(list) do
            if row.context == Mods.MouseCursorConsoles then duplicate = row end
        end
        check(not duplicate, "general Mod Options list has no Mouse Cursor Consoles entry")
        check(next(Mods.MouseCursorConsoles.options:GetProperties()) == nil,
            "private Controls properties do not leak into native Mod Options")

    end)
    if not ok then report.error = tostring(err); report.failed = true end
    m.CloseSettings("test_cleanup")
    if options and options.window_state ~= "destroying" then options:Close() end
    ChangeGamepadUIStyle({ [1] = original_style })
    report.status = report.failed and "failed" or "passed"
    FlushLogFile()
end)
