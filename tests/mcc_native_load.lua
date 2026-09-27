-- Run only in an owned test process via smr-harness run-file.
-- Keeps the user's enabled-mod list intact on disk.
CreateRealTimeThread(function()
    ModsReloadDefs()
    rawset(_G, "MCCNativePreviousLoadMods", table.copy(AccountStorage.LoadMods or {}))
    AccountStorage.LoadMods = table.copy(MCCNativePreviousLoadMods)
    table.insert_unique(AccountStorage.LoadMods, "MouseCursorConsoles")
    ProtectedModsReloadItems(nil, false)
    AccountStorage.LoadMods = MCCNativePreviousLoadMods
    local mod = Mods.MouseCursorConsoles
    local m = mod and mod.env.MCC
    local valid, reason
    if m then valid, reason = m.Validate() end
    rawset(_G, "MCCNativeLoadReport", {
        mod_found = mod ~= nil,
        version = mod and mod.version,
        module_loaded = m ~= nil,
        input_registered = m and m.input ~= nil,
        validation_passed = valid == true,
        validation_reason = reason,
        load_errors = ModsLoadCodeErrorsMessage or false,
        ui_style = GetUIStyle(),
        revision = LuaRevision,
    })
end)
