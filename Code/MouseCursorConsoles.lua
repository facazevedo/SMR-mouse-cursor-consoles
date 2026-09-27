-- Lifecycle wiring only. metadata.lua lists dependencies before this file.
local M = MCC

OnMsg.ClassesBuilt = M.Install
OnMsg.ModsReloaded = M.Install

function OnMsg.NewGame() M.Install() end
function OnMsg.LoadGame()
    M.RestoreVanillaBehavior("load_game")
    M.Install()
end
function OnMsg.ChangeMap() M.RestoreVanillaBehavior("change_map") end
function OnMsg.DoneGame() M.RestoreVanillaBehavior("done_game") end
function OnMsg.SystemInactivate()
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
