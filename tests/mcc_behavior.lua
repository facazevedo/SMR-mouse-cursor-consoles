-- Host-side behavioral contract. Engine stubs are deliberately not shipped.
local checks, clock, style = 0, 1000, "gamepad"
local events, logs, connected, physical = {}, {}, true, {}
local function check(value, label)
    checks = checks + 1
    assert(value, label)
end
local pt = {}
pt.__index = pt
pt.__eq = function(a, b) return a.px == b.px and a.py == b.py end
function pt:xy() return self.px, self.py end
function pt:Len2D() return math.sqrt(self.px ^ 2 + self.py ^ 2) end
function pt:Dist2D(other) return point(self.px - other.px, self.py - other.py):Len2D() end
function point(x, y) return setmetatable({ px = x, py = y }, pt) end
function MulDivRound(a, b, c) return math.floor(a * b / c + 0.5) end
Min, Max = math.min, math.max
function Clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end
function RealTime() return clock end
function WaitNextFrame() coroutine.yield() end
local hooks = {}
OnMsg = setmetatable({}, { __newindex = function(_, key, fn) hooks[key] = hooks[key] or {}; table.insert(hooks[key], fn) end })
local function msg(key, ...)
    for _, fn in ipairs(hooks[key] or {}) do fn(...) end
end
local window = {}
function window:new(props, parent)
    local obj = setmetatable(props or {}, { __index = self })
    obj.parent, obj.threads = parent, {}
    if obj.Id and parent then parent[obj.Id] = obj end
    if obj.Init then obj:Init() end
    return obj
end
function window:Open() self.window_state = "open" end
function window:delete() self.window_state = "destroying"; self.threads = {} end
function window:SetVisible(v) self.visible = v end
function window:SetImage(v) self.image = v end
function window:SetImageScale(v) self.image_scale = v end
function window:SetImageColor(v) self.image_color = v end
function window:AddDynamicPosModifier(v) self.modifier = v end
function window:CreateThread(name, fn, ...) self.threads[name] = coroutine.create(fn) end
XImage = window
function RGB(r, g, b) return r * 65536 + g * 256 + b end
function RGBA(r, g, b, a) return RGB(r, g, b) + a * 16777216 end
DefineClass = setmetatable({}, { __newindex = function(_, name, value)
    setmetatable(value, { __index = window }); _G[name] = value
end })
terminal = { desktop = {}, targets = {}, pos = point(12, 34) }
function terminal.AddTarget(target) terminal.targets[target] = true end
function terminal.RemoveTarget(target) terminal.targets[target] = nil end
function terminal.GetMousePos() return terminal.pos end
function terminal.SetMousePos(pos) terminal.pos = pos end
function terminal.MouseEvent(event, pos, button, meta, last)
    events[#events + 1] = { event = event, pos = pos, button = button, meta = meta, last = last }
end
function terminal.Shortcut(shortcut) events[#events + 1] = { event = shortcut } end
local virtual_pos = point(45, 67)
function GamepadMouseSetPos(pos) virtual_pos = pos end
function GamepadMouseGetPos() return virtual_pos end
function GetUIStyle() return style end
hr = { XBoxLeftThumbLocked = 2, XBoxRightThumbLocked = 3, GamepadMouseEnabled = false }
function ChangeGamepadUIStyle(value)
    if style ~= value[1] then
        style = value[1]
        local delta = style == "gamepad" and -1 or 1
        hr.XBoxLeftThumbLocked = hr.XBoxLeftThumbLocked + delta
        hr.XBoxRightThumbLocked = hr.XBoxRightThumbLocked + delta
        msg("GamepadUIStyleChanged")
    end
end
function OnUIStyleChangedDialogs() end
function GetInGameInterface() return nil end -- first main menu, no colony loaded
UIL = { GetScreenSizeXY = function() return 1920, 1080 end }
XInput = {
    CurrentState = { [0] = { LeftThumb = point(0, 0), RightThumb = point(32767, 0) } },
    Buttons = { "RightThumbClick", "ButtonA", "ButtonB", "ButtonX", "LeftShoulder", "RightShoulder", "Start" },
    AnalogsAsButtons = { "LeftTrigger", "RightTrigger" },
    IsControllerConnected = function() return connected end,
    IsCtrlButtonPressed = function(_, button)
        if button == "LeftTrigger" then return (physical[button] or 0) >= 64 end
        return physical[button]
    end,
}
const = { DefaultMouseCursor = "UI/Cursors/Cursor.tga" }
ShowMouseReasons, ForceHideMouseReasons, ForceShowMouseReasons = {}, { MouseDisconnected = true }, {}
function ShowMouseCursor(reason) ShowMouseReasons[reason] = true; msg("ShowMouseCursor") end
function HideMouseCursor(reason) ShowMouseReasons[reason] = nil; msg("ShowMouseCursor") end
function ForceHideMouseCursor(reason) ForceHideMouseReasons[reason] = true; msg("ShowMouseCursor") end
function UnforceHideMouseCursor(reason) ForceHideMouseReasons[reason] = nil; msg("ShowMouseCursor") end
RolloverSuspendReasons = { [false] = true, unrelated = true }
function ResumeRollover(reason) RolloverSuspendReasons[reason or false] = nil end
function SuspendRollover(reason) RolloverSuspendReasons[reason or false] = true end
function XDestroyRolloverWindow() end
CurrentModId, CurrentModDef = "MouseCursorConsoles", { version = 1 }
function Untranslated(text) return text end
function CreateMessageBox(_, _, text) events[#events + 1] = { event = "error", text = text } end
local real_print = print
print = function(text) logs[#logs + 1] = text end
function PlaceObj(_, values)
    local obj = {}; for i = 1, #values, 2 do obj[values[i]] = values[i + 1] end; return obj
end
local metadata, items = dofile("metadata.lua"), dofile("items.lua")
CurrentModDef.version = metadata.version
for i, file in ipairs(metadata.code) do
    check(items[i].CodeFileName == file, "Editor and runtime load orders differ")
    dofile(file)
end
local M = MCC
local native_mouse_position = terminal.GetMousePos
local function event(name, button, controller) return M.input[name](M.input, button, controller or 0) end
local function toggle()
    event("OnXButtonDown", "RightThumbClick"); event("OnXButtonUp", "RightThumbClick")
end
msg("ClassesBuilt"); local input = M.input; msg("ModsReloaded")
check(input == M.input, "Installation must be idempotent")
toggle()
check(M.active and style == "keyboard" and M.cursor.visible, "Toggle must enable PC cursor at the main menu without a colony")
check(hr.XBoxLeftThumbLocked == 4 and hr.XBoxRightThumbLocked == 5, "Both native sticks must be locked")
check(not RolloverSuspendReasons[false] and RolloverSuspendReasons.unrelated, "Only disconnected-mouse rollover suspension may be lifted")
check(events[#events].last == true, "Mouse movement must reach terminal dispatch")
check(terminal.GetMousePos() == M.position, "Position queries must use authoritative software cursor")
local cursor = M.cursor
M.ApplyModBehavior(0)
check(M.cursor == cursor and hr.XBoxLeftThumbLocked == 4, "Double enable must not duplicate cursor or locks")
local x, y = M.MoveCursor(500000, 500000, 0, 0, 0, 16, 1920, 1080)
check(x == 500000 and y == 500000, "Idle left stick must not drift")
x, y = M.MoveCursor(x, y, 5999, 0, 5999, 16, 1920, 1080)
check(x == 500000, "Dead zone must suppress small input")
x, y = M.MoveCursor(x, y, 32767, 0, 32767, 20, 1920, 1080)
check(x == 518000 and y == 500000, "Full right should move exactly 18 pixels in 20ms")
x, y = M.MoveCursor(x, y, 0, 32767, 32767, 20, 1920, 1080)
check(y == 482000, "Stick up must move screen cursor upward")
x, y = M.MoveCursor(1919000, 0, 32767, 32767, 46340, 1000, 1920, 1080)
check(x == 1919000 and y == 0, "Movement must clamp to screen and cap stalled frame time")
local thread = cursor.threads.MCCLeftStick
check(coroutine.resume(thread, cursor), "Cursor loop must start")
clock = clock + 16
check(coroutine.resume(thread), "Cursor loop must resume")
check(M.position == point(960, 540), "Right stick alone must not move cursor")
local function step()
    clock = clock + 20
    local ok, err = coroutine.resume(thread)
    assert(ok, err)
end
XInput.CurrentState[0].LeftThumb = point(32767, 0)
physical.LeftTrigger = 63
local before = M.x
step()
check(not M.boost_active and M.x - before == 18000, "Below trigger threshold must keep normal speed")
physical.LeftTrigger = 64
before = M.x
step()
check(M.boost_active and M.x - before == 45000, "Held L2/LT must move exactly 2.5x faster")
local boost_events = #events
event("OnXButtonDown", "LeftTrigger"); event("OnXButtonRepeat", "LeftTrigger")
check(#events == boost_events, "Boost trigger must not emit clicks or wheel events")
physical.LeftTrigger = 0 -- deliberately omit button-up delivery until after polling
before = M.x
step()
check(not M.boost_active and M.x - before == 18000, "Physical release must restore speed even without button-up")
event("OnXButtonUp", "LeftTrigger")
M.Config.ENABLE_SPEED_BOOST = false
physical.LeftTrigger = 255
before = M.x
step()
check(not M.boost_active and M.x - before == 18000, "Disabled boost flag must prevent acceleration")
M.Config.ENABLE_SPEED_BOOST = true
XInput.CurrentState[0].LeftThumb = point(0, 0)
before = M.x
step()
check(M.boost_active and M.x == before, "Held boost alone must not move cursor")
physical.LeftTrigger = 0
step()
event("OnXButtonDown", "ButtonA")
check(events[#events].event == "OnMouseButtonDown" and events[#events].button == "L", "Cross/A must press left mouse")
local count = #events
event("OnXButtonRepeat", "ButtonA")
check(#events == count, "Held click must not generate repeated presses")
event("OnXButtonUp", "ButtonA")
check(events[#events].event == "OnMouseButtonUp", "Mouse release must be paired")
clock = clock + 50
event("OnXButtonDown", "ButtonA")
check(events[#events].event == "OnMouseButtonDoubleClick", "Nearby quick second press must double click")
event("OnXButtonUp", "ButtonA")
event("OnXButtonDown", "LeftShoulder"); event("OnXButtonRepeat", "LeftShoulder")
check(events[#events].event == "OnMouseWheelForward", "Wheel up must repeat")
event("OnXButtonUp", "LeftShoulder")
count = #events; event("OnXButtonRepeat", "LeftShoulder")
check(#events == count, "Wheel repeat must stop after release")
event("OnXButtonDown", "RightShoulder")
check(events[#events].event == "OnMouseWheelBack", "Wheel down binding")
event("OnXButtonUp", "RightShoulder")
event("OnXButtonDown", "Start"); event("OnXButtonUp", "Start")
check(events[#events].event == "Escape", "Menu must dispatch PC Escape")
count = #events
event("OnXButtonDown", "ButtonA", 1); event("OnXButtonDown", "RightThumbClick", 1)
check(M.active and #events == count, "Other controller cannot click or toggle owner session")
physical.LeftTrigger = 255; M.UpdateSpeedBoost()
event("OnXButtonDown", "ButtonB"); toggle()
check(not M.boost_active, "Toggle off must clear boost even if trigger remains held")
physical.LeftTrigger = 0
check(not M.active and not M.cursor and style == "gamepad", "Same toggle must restore gamepad")
check(events[#events].event == "OnMouseButtonUp" and events[#events].button == "R", "Exit must release held right click")
check(hr.XBoxLeftThumbLocked == 2 and hr.XBoxRightThumbLocked == 3, "Exit must preserve existing camera locks")
check(terminal.pos == point(12, 34) and virtual_pos == point(45, 67), "Restore both cursor positions")
check(terminal.GetMousePos == native_mouse_position, "Restore the exact original mouse-position function")
check(RolloverSuspendReasons[false] and not ForceHideMouseReasons.MouseCursorConsoles, "Restore cursor reasons")
check(event("OnXButtonUp", "ButtonB") == "break", "Suppress release of mouse-mode button after exit")
check(event("OnXButtonUp", "ButtonA", 1) == "break", "Suppress other controller's held release after exit")
M.RestoreVanillaBehavior("again")
check(hr.XBoxLeftThumbLocked == 2, "Double disable must be harmless")
event("OnXButtonDown", "RightThumbClick"); event("OnXButtonRepeat", "RightThumbClick"); event("OnXButtonDown", "RightThumbClick")
check(M.active, "Held or duplicate toggle may only switch once")
event("OnXButtonUp", "RightThumbClick"); toggle()
physical.ButtonA, physical.LeftShoulder = true, true
toggle(); count = #events
event("OnXButtonDown", "ButtonA"); event("OnXButtonRepeat", "LeftShoulder")
check(#events == count, "Buttons held across entry must wait for release")
event("OnXButtonUp", "ButtonA"); event("OnXButtonUp", "LeftShoulder")
physical = {}
msg("OnXInputControllerDisconnected", 0)
check(not M.active and style == "gamepad", "Disconnect must restore controls")
toggle()
for _, hook in ipairs({ "NewGame", "ChangeMap", "LoadGame", "DoneGame" }) do
    local retained_cursor = M.cursor
    event("OnXButtonDown", "ButtonA")
    event("OnXButtonDown", "LeftShoulder")
    msg(hook)
    check(M.active and M.cursor == retained_cursor and style == "keyboard", hook .. " must preserve mouse mode across screens")
    check(not M.clicks.L and events[#events].event == "OnMouseButtonUp", hook .. " must release held clicks")
    local event_count = #events
    event("OnXButtonRepeat", "LeftShoulder")
    check(#events == event_count, hook .. " must cancel held wheel repeats")
    event("OnXButtonUp", "ButtonA"); event("OnXButtonUp", "LeftShoulder")
end
physical.LeftTrigger = 255; M.UpdateSpeedBoost(); msg("SystemInactivate")
check(not M.active and not M.boost_active and style == "gamepad", "Focus loss must restore controls and boost")
physical.LeftTrigger = 0
toggle(); ChangeGamepadUIStyle({ [1] = "gamepad" })
check(not M.active and hr.XBoxLeftThumbLocked == 2, "External control-style change must release ownership")
M.Config.ENABLE_MOUSE_MODE = false
check(event("OnXButtonDown", "RightThumbClick") == nil and not M.active, "Disabled feature must leave controller behavior alone")
event("OnXButtonUp", "RightThumbClick"); M.Config.ENABLE_MOUSE_MODE = true
local fn = GamepadMouseSetPos; GamepadMouseSetPos = nil
check(not M.ApplyModBehavior(0) and style == "gamepad", "Missing API must refuse before changing state")
GamepadMouseSetPos = fn
M.Config.RIGHT_CLICK_BUTTON = "ButtonA"
check(not M.Validate(), "Conflicting bindings must be rejected")
M.Config.RIGHT_CLICK_BUTTON = "ButtonB"
M.Config.SPEED_BOOST_BUTTON = "ButtonA"
check(not M.Validate(), "Boost binding must not collide with left click")
M.Config.SPEED_BOOST_BUTTON = "RightTrigger"
check(M.Validate(), "Right trigger is a supported configurable boost binding")
M.Config.SPEED_BOOST_BUTTON = "LeftTrigger"
for _, invalid in ipairs({ 49, 8001, 150.5, "2250" }) do
    M.Config.CURSOR_FAST_SPEED = invalid
    check(not M.Validate(), "Invalid fast speed must be rejected: " .. tostring(invalid))
end
M.Config.CURSOR_FAST_SPEED = 2250
hr.GamepadMouseEnabled = true
check(not M.ApplyModBehavior(0), "Existing virtual mouse ownership must be respected")
hr.GamepadMouseEnabled = false
M.Log("Test", "disabled")
check(#logs == 0, "Debug flags false must remain quiet")
M.Config.DEBUG_LOGS = "true"; M.Log("Test", "string")
check(#logs == 0, "Debug flag must be exactly boolean true")
M.Config.DEBUG_LOGS = true; M.Log("Test", "enabled", { active = false })
check(#logs == 1 and logs[1]:find("active=false", 1, true), "Structured logs must be readable")
M.SetSpeedBoost(true)
check(#logs == 1, "Boost transitions must respect DEBUG_INPUT=false")
M.Config.DEBUG_INPUT = true; M.SetSpeedBoost(false)
check(#logs == 2 and logs[2]:find("speed_boost_changed", 1, true), "Boost transition must log with both debug flags true")
M.Config.DEBUG_LOGS = false
toggle(); msg("ModUnloadLua", CurrentModId)
check(not M.active and not M.input and next(terminal.targets) == nil, "Unload must remove cursor, locks and input target")
print = real_print
print("PASS: " .. checks .. " behavioral checks (stubbed engine; not console certification)")
