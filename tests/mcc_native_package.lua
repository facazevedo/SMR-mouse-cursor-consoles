-- Run via smr-harness in an owned debug-game process, after setting
-- MCCPackageOutput to a new, empty, project-owned output directory.
-- Uses the uploader's native packer without its shared-temp deletion or upload.
local output = rawget(_G, "MCCPackageOutput")
assert(type(output) == "string" and output ~= "", "MCCPackageOutput is required")
CreateRealTimeThread(function()
    local report = { complete = false, passed = false }
    rawset(_G, "MCCPackageReport", report)
    local function check(condition, message)
        if not condition then
            report.error = message
            report.complete = true
            error(message)
        end
    end
    local mod = Mods.MouseCursorConsoles
    check(mod ~= nil, "Mod definition missing")
    check(not mod:IsDirty(), "Refusing to package unsaved editor changes")
    for _, field in ipairs({ "title", "short_description", "description", "image" }) do
        check(type(mod[field]) == "string" and mod[field] ~= "", "Missing " .. field)
    end
    check(#mod.short_description <= 200, "Summary exceeds publisher limit")
    check(type(mod.lua_revision) == "number" and mod.lua_revision > 0, "Invalid Lua revision")
    check(io.exists(mod.image), "Preview image missing")
    report.image_bytes = io.getsize(mod.image)
    check(report.image_bytes and report.image_bytes <= 2 * 1024 * 1024, "Preview exceeds 2 MB")
    check(not io.exists(output), "Output directory already exists; choose a fresh directory")
    local err = AsyncCreatePath(output)
    check(not err, "Create output directory: " .. tostring(err))
    local files
    err, files = AsyncListFiles(mod.content_path, nil, "recursive")
    check(not err and type(files) == "table", "List payload: " .. tostring(err))
    local expected = { ["metadata.lua"] = true, ["items.lua"] = true }
    local prefix = "Mod/" .. mod.id .. "/"
    check(mod.image:sub(1, #prefix) == prefix, "Preview must be inside this mod")
    expected[mod.image:sub(#prefix + 1)] = true
    for _, file in ipairs(mod.code) do expected[file] = true end
    local index = {}
    for _, file in ipairs(files) do
        local relative = file:sub(#mod.content_path + 1)
        check(expected[relative] == true, "Unexpected payload file: " .. relative)
        expected[relative] = nil
        index[#index + 1] = { src = file, dst = relative }
    end
    check(next(expected) == nil, "Payload is incomplete")
    report.file_count = #index
    report.pack_path = output .. "/" .. ModsPackFileName
    err = AsyncPack(report.pack_path, mod.content_path, index)
    check(not err, "Native packing failed: " .. tostring(err))
    report.pack_bytes = io.getsize(report.pack_path)
    check(report.pack_bytes and report.pack_bytes > 0 and report.pack_bytes <= 5 * 1024 * 1024 * 1024,
        "Package is empty or exceeds 5 GB")
    report.unpacked_path = output .. "/unpacked"
    err = AsyncCreatePath(report.unpacked_path)
    check(not err, "Create unpack directory: " .. tostring(err))
    err = AsyncUnpack(report.pack_path, report.unpacked_path)
    check(not err, "Native unpacking failed: " .. tostring(err))
    report.version = mod.version
    report.short_description = mod.short_description
    report.passed = true
    report.complete = true
end)
