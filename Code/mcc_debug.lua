local M = MCC

function M.Log(scope, operation, data)
    if M.Config.DEBUG_LOGS ~= true then return end
    local fields = {}
    for key, value in pairs(data or {}) do
        fields[#fields + 1] = tostring(key) .. "=" .. tostring(value)
    end
    table.sort(fields)
    print("[MouseCursorConsoles][" .. scope .. "] " .. operation .. " " .. table.concat(fields, " "))
end

function M.InputLog(operation, data)
    if M.Config.DEBUG_INPUT == true then M.Log("Input", operation, data) end
end
