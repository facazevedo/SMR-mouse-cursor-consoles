-- A mod-owned modal, reached through Options > Controls.
-- Reuses the vanilla PropNumber slider; no shared classes are patched.
local M = MCC
M.settings_entries = {}
DefineClass.MCCSettingsDialog = {
    __parents = { "XDialog" },
    Id = "idMCCSettings", IdNode = true, IsModal = true,
    ZOrder = 200000, Background = RGBA(5, 12, 20, 255),
    draft = false, settings_host = false, advanced = false, testing = false,
    preview_motion = false, preview_controller = false,
}

local function button(parent, text, action)
    return MenuEntrySmall:new({ Text = Untranslated(text), TextStyle = "ListItem3R",
        OnPress = action, MinHeight = 34 }, parent)
end

function MCCSettingsDialog:Init()
    self.draft = M.NewSettingsDraft()
    self.preview_motion = { x = 150000, y = 65000 }
    local panel = XWindow:new({ Id = "idPanel", HAlign = "center", VAlign = "center",
        MinWidth = 1000, MaxWidth = 1000, LayoutMethod = "VList", LayoutVSpacing = 8,
        Padding = box(25, 15, 25, 15) }, self)
    XText:new({ Translate = true, Id = "idHeading", TextStyle = "ListItem3R", Text = Untranslated("MOUSE CURSOR CONSOLES"),
        HandleMouse = false }, panel)
    XText:new({ Translate = true, Id = "idHelp", TextStyle = "ListItem4", HandleMouse = false,
        Text = Untranslated("D-pad: choose and adjust. Apply saves; Cancel discards. Speeds are pixels/sec at 1080p.") }, panel)
    local list_host = XWindow:new({ LayoutMethod = "HList" }, panel)
    XList:new({ Id = "idList", MinWidth = 915, MaxWidth = 915, MaxHeight = 345,
        BorderWidth = 0, Background = 0, FocusedBackground = 0, LayoutVSpacing = 5,
        VScroll = "idScroll", MouseScroll = true, ForceInitialSelection = true }, list_host)
    ScrollbarNew:new({ Id = "idScroll", Target = "idList" }, list_host)
    local preview = XWindow:new({ Id = "idPreview", MinHeight = 135, MaxHeight = 135,
        Background = RGBA(35, 52, 68, 255), Clip = "self", HandleMouse = false }, panel)
    XText:new({ Translate = true, TextStyle = "ListItem4", Text = Untranslated("TEST AREA  -  choose Test cursor to move here"),
        HandleMouse = false }, preview)
    XImage:new({ Id = "idPreviewCursor", HAlign = "left", VAlign = "top",
        HandleMouse = false, Image = const.DefaultMouseCursor }, preview)
    XText:new({ Translate = true, Id = "idStatus", TextStyle = "ListItem4", HandleMouse = false,
        Text = Untranslated("Changes are previewed here before you apply them.") }, panel)
    self:BuildRows()
end

function MCCSettingsDialog:BuildRows()
    self.testing = false
    local list = self:ResolveId("idList")
    list:Clear()
    self:ResolveId("idHeading"):SetText(Untranslated(self.advanced and "MOUSE CURSOR CONSOLES / ADVANCED" or "MOUSE CURSOR CONSOLES"))
    self:ResolveId("idPreview"):SetVisible(not self.advanced)
    self:ResolveId("idPreview"):SetFoldWhenHidden(true)
    local properties = self.draft:GetProperties()
    local wanted = {}
    for i, key in ipairs(M.SettingKeys) do if (i > 3) == self.advanced then wanted[key] = true end end
    for _, prop in ipairs(properties) do
        if wanted[prop.id] then
            if prop.editor == "number" then
                PropNumber:new({ RolloverText = Untranslated(prop.help or ""),
                    RolloverTitle = prop.name }, list, ModOptionEditorContext(self.draft, prop))
            else
                local row
                local function label()
                    local value = self.draft:GetProperty(prop.id)
                    local text = type(value) == "boolean" and (value and "On" or "Off") or M.ButtonLabels[value] or tostring(value)
                    return _InternalTranslate(prop.name) .. ": " .. text
                end
                local function cycle(direction)
                    local value = self.draft:GetProperty(prop.id)
                    if prop.editor == "bool" then value = not value
                    else
                        local index = 1
                        for i, item in ipairs(prop.items) do if item.value == value then index = i end end
                        index = (index - 1 + direction) % #prop.items + 1
                        value = prop.items[index].value
                    end
                    self.draft:SetProperty(prop.id, value)
                    row:SetText(Untranslated(label()))
                end
                row = button(list, label(), function() cycle(1) end)
                row.OnShortcut = function(control, shortcut, source, ...)
                    if shortcut == "DPadLeft" or shortcut == "LeftThumbLeft" then cycle(-1); return "break" end
                    if shortcut == "DPadRight" or shortcut == "LeftThumbRight" then cycle(1); return "break" end
                    return MenuEntrySmall.OnShortcut(control, shortcut, source, ...)
                end
            end
        end
    end
    if not self.advanced then
        button(list, "Test cursor", function() self:BeginTest() end)
    end
    button(list, self.advanced and "Back to basic settings" or "Advanced settings", function()
        self.advanced = not self.advanced
        self:BuildRows()
    end)
    button(list, "Reset to defaults", function()
        for _, prop in ipairs(properties) do self.draft:SetProperty(prop.id, prop.default) end
        self:BuildRows()
        self:ResolveId("idStatus"):SetText(Untranslated("Defaults restored in preview. Choose Apply to save."))
    end)
    button(list, "Apply and close", function()
        local ok, reason = M.SaveSettings(self.draft)
        if ok then self:Close("apply")
        else self:ResolveId("idStatus"):SetText(Untranslated(reason)) end
    end)
    button(list, "Cancel", function() self:Close("cancel") end)
    if self.window_state == "open" then
        for _, row in ipairs(list) do row:Open() end
        list:SetFocus()
        list:SetSelection(1)
    end
end

function MCCSettingsDialog:BeginTest()
    local controller = type(ActiveController) == "number" and ActiveController or 0
    if not XInput.IsControllerConnected(controller) then
        self:ResolveId("idStatus"):SetText(Untranslated("Connect a controller to test left-stick movement. Sliders can still be edited."))
        return
    end
    self.preview_controller, self.testing = controller, true
    self.preview_motion.vx, self.preview_motion.vy = 0, 0
    self:SetFocus()
    self:ResolveId("idStatus"):SetText(Untranslated("Move left stick; hold your boost button for fast speed. Circle / B or Escape returns to settings."))
end

function MCCSettingsDialog:EndTest()
    self.testing = false
    self:ResolveId("idList"):SetFocus()
    self:ResolveId("idList"):SetSelection(1)
    self:ResolveId("idStatus"):SetText(Untranslated("Test ended. Apply saves your settings; Cancel discards changes."))
end

function MCCSettingsDialog:OnShortcut(shortcut, source, ...)
    if shortcut == "Escape" or shortcut == "ButtonB" then
        if self.testing then self:EndTest()
        elseif self.advanced then self.advanced = false; self:BuildRows()
        else self:Close("cancel") end
        return "break"
    end
    if self.testing then return "break" end
    return XDialog.OnShortcut(self, shortcut, source, ...)
end

function MCCSettingsDialog:Open(...)
    XDialog.Open(self, ...)
    self:CreateThread("MCCPreview", function()
        local last = RealTime()
        local last_size, last_color, last_x, last_y
        while self.window_state ~= "destroying" do
            WaitNextFrame()
            local time = RealTime()
            local cfg = M.ReadSettings(self.draft)
            local area, image = self:ResolveId("idPreview"), self:ResolveId("idPreviewCursor")
            if cfg.CURSOR_SIZE ~= last_size or cfg.CURSOR_COLOR ~= last_color then
                M.StyleCursor(image, cfg)
                last_size, last_color = cfg.CURSOR_SIZE, cfg.CURSOR_COLOR
            end
            if self.testing then
                local id = self.preview_controller
                if not XInput.IsControllerConnected(id) then self:EndTest()
                else
                    local state = XInput.CurrentState[id]
                    if state and state.LeftThumb then
                        local ax, ay = state.LeftThumb:xy()
                        local width, height = area.content_box:sizex(), area.content_box:sizey()
                        local _, screen_height = UIL.GetScreenSizeXY()
                        local boost = M.Config.ENABLE_SPEED_BOOST == true and XInput.IsCtrlButtonPressed(id, cfg.SPEED_BOOST_BUTTON) == true
                        M.AdvanceCursor(self.preview_motion, ax, ay, state.LeftThumb:Len2D(), time - last,
                            Max(1, width - image.measure_width), Max(1, height - image.measure_height), boost, cfg, screen_height)
                    end
                end
            end
            local x = MulDivRound(self.preview_motion.x, 1, area.scale:x())
            local y = MulDivRound(self.preview_motion.y, 1, area.scale:y())
            if x ~= last_x or y ~= last_y then image:SetMargins(box(x, y, 0, 0)); last_x, last_y = x, y end
            last = time
        end
    end)
    M.Log("SettingsUI", "opened", {})
end

function MCCSettingsDialog:Done(result)
    if M.settings_dialog == self then M.settings_dialog = nil end
    M.Log("SettingsUI", "closed", { result = result or "cleanup" })
end

function M.OpenSettings(host)
    if M.settings_dialog then return M.settings_dialog end
    M.RestoreVanillaBehavior("settings_opened")
    M.held, M.swallowed = {}, {}
    local dialog = MCCSettingsDialog:new({ settings_host = host }, terminal.desktop)
    M.settings_dialog = dialog
    dialog:Open()
    return dialog
end

function M.CloseSettings(reason)
    if M.settings_dialog then M.settings_dialog:Close(reason) end
end

-- XContentTemplate emits this after creating rows and before XContentList
-- rebuilds its selection index. Add our row on each rebuild, without replacing
-- any vanilla method or changing the native Controls properties.
function OnMsg.XWindowRecreated(list)
    if not M.input or not IsKindOf(list, "XContentList") then return end
    local host = GetParentOfKind(list, "XDialog")
    if not host or not GetParentOfKind(host, "OptionsDlg") then return end
    local category = GetDialogModeParam(list)
    if host.Mode ~= "properties" or type(category) ~= "table" or category.id ~= "Controls" then return end
    if list:ResolveId("idMCCControlsEntry") then return end
    for entry in pairs(M.settings_entries) do
        if entry.window_state == "destroying" then M.settings_entries[entry] = nil end
    end
    local entry = MenuEntrySmall:new({
        Id = "idMCCControlsEntry", ZOrder = -1, Margins = box(18, 0, 0, 0),
        Text = Untranslated("Mouse Cursor Consoles"), TextStyle = "PropName",
        OnPress = function() M.OpenSettings(host) end,
    }, list)
    M.settings_entries[entry] = host
    list:SortChildren()
    entry:Open()
    M.Log("SettingsUI", "controls_entry_added", {})
end

function M.RemoveSettingsEntries(host)
    for entry, owner in pairs(M.settings_entries) do
        if not host or owner == host or GetParentOfKind(owner, "OptionsDlg") == host then
            M.settings_entries[entry] = nil
            if entry.window_state ~= "destroying" then entry:delete() end
        end
    end
    M.Log("SettingsUI", "controls_entries_removed", { all = host == nil })
end

function OnMsg.DialogClose(dialog)
    if M.settings_dialog and M.settings_dialog.settings_host == dialog then M.CloseSettings("parent_closed") end
    M.RemoveSettingsEntries(dialog)
end
