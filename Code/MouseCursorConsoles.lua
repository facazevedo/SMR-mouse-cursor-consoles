-- Lifecycle wiring only. metadata.lua lists dependencies before this file.
local M = MCC

OnMsg.ClassesBuilt = M.Install
OnMsg.ModsReloaded = M.Install

function OnMsg.ApplyModOptions(id)
    if id == CurrentModId then M.settings_loaded = M.LoadSettings() end
end

function OnMsg.NewGame()
    M.ReleaseTransitionInput("new_game")
    M.Install()
end
function OnMsg.LoadGame()
    M.ReleaseTransitionInput("load_game")
    M.Install()
end
function OnMsg.ChangeMap() M.ReleaseTransitionInput("change_map") end
function OnMsg.DoneGame() M.ReleaseTransitionInput("done_game") end
function OnMsg.SystemInactivate()
    if M.settings_dialog and M.settings_dialog.testing then M.settings_dialog:EndTest() end
    M.RestoreVanillaBehavior("focus_lost")
    M.held, M.swallowed = {}, {}
end
function OnMsg.OnXInputControllerDisconnected(controller)
    if M.controller == controller then M.RestoreVanillaBehavior("controller_disconnected") end
    M.held[controller], M.swallowed[controller] = nil, nil
end
function OnMsg.GamepadUIStyleChanged()
    if M.active and not M.transitioning and GetUIStyle() ~= "keyboard" then
        M.RestoreVanillaBehavior("external_style_change", true)
    end
end
function OnMsg.MouseCursor(cursor)
    if M.cursor then M.cursor.idCursor:SetImage(cursor) end
end
OnMsg.ShowMouseCursor = M.UpdateCursorVisibility
function OnMsg.ModsReloading() M.Shutdown("mods_reloading") end
function OnMsg.ReloadLua() M.Shutdown("lua_reload") end
function OnMsg.ModUnloadLua(id)
    if id == CurrentModId then M.Shutdown("mod_unloaded") end
end
