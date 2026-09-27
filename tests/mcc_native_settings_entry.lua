-- Exercise the actual native Mod Options entry and its mode-change lifecycle.
rawset(_G, "MCCNativeEntryReport", { status = "running", checks = {} })
CreateRealTimeThread(function()
    local report = MCCNativeEntryReport
    local m = Mods.MouseCursorConsoles.env.MCC
    local options
    local function check(value, name)
        report.checks[#report.checks + 1] = { passed = not not value, name = name }
        if not value then report.failed = true end
    end
    local ok, err = sprocall(function()
        options = OptionsDlg:new({}, terminal.desktop)
        options:Open()
        local host = options[1]
        host:SetMode("mod_choice")
        Sleep(150)
        local list = host:ResolveId("idList")
        local entry
        for _, row in ipairs(list) do
            if row.context == Mods.MouseCursorConsoles then entry = row end
        end
        check(entry ~= nil, "native Mod Options lists Mouse Cursor Consoles")
        entry:OnPress()
        Sleep(150)
        local dlg = m.settings_dialog
        check(dlg and dlg.settings_host == host, "native entry opens dedicated settings page")
        if not dlg then return end
        dlg:Close("cancel")
        check(not m.settings_dialog and host.Mode == "mod_choice", "cancel returns to mod list")
        Sleep(150) -- native content lists rebuild on their own UI thread
        list = host:ResolveId("idList")
        for _, row in ipairs(list) do
            if row.context == Mods.MouseCursorConsoles then row:OnPress(); break end
        end
        Sleep(150)
        check(m.settings_dialog ~= nil, "settings reopen without duplicate dialogs")
        m.settings_dialog:Close("cancel")
        Sleep(150)
        host:SetMode("mod_options", Mods.MouseCursorConsoles)
        m.CloseSettings("cancel_pending_open")
        Sleep(150)
        check(not m.settings_dialog and not m.settings_pending_host, "cleanup cancels a pending settings-open thread")
        host:SetMode("mod_options", Mods.MouseCursorConsoles)
        Sleep(150)
        options:Close()
        check(not m.settings_dialog, "closing options parent removes settings modal")
    end)
    if not ok then report.error = tostring(err); report.failed = true end
    m.CloseSettings("test_cleanup")
    if options and options.window_state ~= "destroying" then options:Close() end
    report.status = report.failed and "failed" or "passed"
end)
