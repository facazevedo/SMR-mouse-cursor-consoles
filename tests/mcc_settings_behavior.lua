-- Preference and motion contracts; the native UI has separate integration checks.
dofile("tests/mcc_behavior.lua")
local M, checks = MCC, 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local function copy(values) local t = {}; for k,v in pairs(values) do t[k] = v end; return t end
local function options(values)
    return { GetProperty = function(_, key) return values[key] end,
        SetProperty = function(_, key, value) values[key] = value end }
end
local defaults = copy(M.SettingDefaults)
local metadata = dofile("metadata.lua")
check(type(metadata.default_options) == "table" and next(metadata.default_options) == nil,
    "Mod must not advertise general Mod Options")
for _, item in ipairs(dofile("items.lua")) do
    check(item.CodeFileName ~= nil, "Manifest must not register duplicate mod options")
end
local definitions = {}
for _, prop in ipairs(M.SettingProperties) do definitions[prop.id] = prop end
for _, key in ipairs(M.SettingKeys) do
    check(definitions[key] and definitions[key].default == defaults[key], "Controls/config default mismatch: " .. key)
end
check(M.ValidateSettings(defaults), "Defaults must be valid")
local cfg = copy(defaults)
cfg.CURSOR_FAST_SPEED = 800
check(not M.ValidateSettings(cfg), "Fast speed below normal rejected")
cfg = copy(defaults); cfg.TOGGLE_BUTTON = cfg.LEFT_CLICK_BUTTON
check(not M.ValidateSettings(cfg), "Duplicate binding rejected")
cfg = copy(defaults); cfg.LEFT_CLICK_BUTTON = "RightTrigger"
check(not M.ValidateSettings(cfg), "Analog triggers reserved for polling boost")
cfg = copy(defaults); cfg.REMEMBER_POSITION = "true"
check(not M.ValidateSettings(cfg), "Boolean settings must be actual booleans")
for _, key in ipairs({"CURSOR_SIZE", "STICK_DEADZONE", "SMOOTHING_MS"}) do
    cfg = copy(defaults); cfg[key] = -1
    check(not M.ValidateSettings(cfg), "Invalid range rejected: " .. key)
end

cfg = copy(defaults)
local linear = M.MoveCursor(0, 0, 18000, 0, 18000, 16, 1920, 1080, false, cfg)
cfg.RESPONSE_CURVE = "Gradual"
local gradual = M.MoveCursor(0, 0, 18000, 0, 18000, 16, 1920, 1080, false, cfg)
check(gradual > 0 and gradual < linear, "Gradual response is finer at partial deflection")
local full = M.MoveCursor(0, 0, 32767, 0, 32767, 16, 1920, 1080, false, cfg)
check(full == 14400, "Gradual full-stick speed remains unchanged")
cfg.CURSOR_SPEED, cfg.CURSOR_FAST_SPEED = 400, 3000
check(M.MoveCursor(0,0,32767,0,32767,20,1920,1080,true,cfg) == 60000, "Fast speed is independent of normal speed")
local function move(frames, dt, height)
    local state = {x = 500000, y = 500000}
    for i = 1, frames do M.AdvanceCursor(state,32767,0,32767,dt,10000,height,false,defaults) end
    return state.x - 500000
end
check(move(100,10,1080) == move(50,20,1080), "Linear speed independent of frame rate")
check(move(50,20,2160) == 2 * move(50,20,1080), "Speed scales with display resolution")
cfg = copy(defaults); cfg.SMOOTHING_MS = 100
local state = { x=500000, y=500000 }
M.AdvanceCursor(state,32767,0,32767,16,1920,1080,false,cfg)
check(state.x > 500000 and state.x < 514400, "Smoothing softens initial movement")
local stopped = state.x
M.AdvanceCursor(state,0,0,0,16,1920,1080,false,cfg)
check(state.x == stopped and state.vx == 0, "Release stops immediately with smoothing enabled")
M.AdvanceCursor(state,32767,0,32767,-100,1920,1080,false,cfg)
check(state.x == stopped, "Nonpositive frame time cannot move the cursor")

local save_count, current = 0, copy(defaults)
CurrentModOptions = options(current)
CurrentModStorageTable = { unrelated = {keep = true} }
WriteModPersistentStorageTable = function() save_count = save_count + 1 end
cfg = copy(defaults); cfg.CURSOR_SIZE = 170; cfg.CURSOR_SPEED = 500
check(M.SaveSettings(options(cfg)), "Valid preferences save")
check(save_count == 1 and current.CURSOR_SIZE == 170 and M.Config.CURSOR_SPEED == 500, "Apply updates runtime and saved options")
check(CurrentModStorageTable.unrelated.keep, "Unrelated storage preserved")
local stored = CurrentModStorageTable.settings.values
check(M.ReadSettings(options(stored)).CURSOR_SIZE == 170, "Preferences reload from account storage")
cfg.CURSOR_FAST_SPEED = 100
check(not M.SaveSettings(options(cfg)) and save_count == 1 and M.Config.CURSOR_SIZE == 170, "Invalid draft has no persisted or runtime effects")
cfg = copy(defaults)
WriteModPersistentStorageTable = function() return "disk error" end
check(not M.SaveSettings(options(cfg)) and CurrentModStorageTable.settings.values == stored
    and M.Config.CURSOR_SIZE == 170, "Write failure preserves current settings and reports failure")
current.CURSOR_SIZE = 100
check(M.LoadSettings() and current.CURSOR_SIZE == 170, "Saved schema reloads into native options")
check(M.ApplySettings(options(defaults)), "Defaults can be restored")
print("PASS: " .. checks .. " settings and motion checks (host)")
