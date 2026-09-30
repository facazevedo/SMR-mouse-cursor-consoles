-- A transparent child page in the existing Options shell.
-- Reuses native title, action bar and sliders; no shared classes are patched.
local M = MCC
local row_indent = 18
M.settings_entries = {}
DefineClass.MCCSettingsDialog = {
    __parents = { "XDialog" },
    Id = "idMCCSettings", IdNode = true, IsModal = true,
    Dock = "box", ZOrder = 2, Background = 0,
    draft = false, settings_host = false, advanced = false, testing = false,
    preview_motion = false, preview_controller = false,
    hidden_controls = false, content_margins = false,
}

local function button(parent, text, action, properties)
    local row_properties = properties or {}
    row_properties.Text = Untranslated(text)
    row_properties.TextStyle = "PropName"
    row_properties.Margins = box(row_indent, 0, 0, 0)
    row_properties.LayoutHSpacing = 0
    row_properties.OnPress = action
    -- Keep the native rollover visuals without its horizontal margin shift.
    row_properties.OnSetRollover = XTextButton.OnSetRollover
    local row = MenuEntrySmall:new(row_properties, parent)
    -- MenuEntrySmall renders idText, not the inherited empty label/icon.
    row.idLabel:SetDock("ignore")
    row.idIcon:SetDock("ignore")
    return row
end

function MCCSettingsDialog:Init()
    self.draft = M.NewSettingsDraft()
    self.preview_motion = { x = 150000, y = 65000 }
    local title = DialogTitleNew:new({ Margins = box(113, 0, 0, 0),
        HAlign = "stretch", BigTitle = true }, self)
    title:SetTitle(T(1131, "OPTIONS"))
    title.idTexts:SetLayoutMethod("HList")
    title.idSubtitle:SetVAlign("bottom")
    title.idSubtitle:SetMargins(box(0, 0, 0, 3))
    title.idFrame:SetMinWidth(510)
    ActionBarNew:new({ Margins = box(109, 0, 0, 0) }, self)
    XAction:new({ ActionId = "mccBack", ActionName = T(108518605856, "BACK"),
        ActionToolbar = "ActionBar", ActionShortcut = "Escape", ActionGamepad = "ButtonB",
        OnAction = function() self:GoBack() end }, self)
    XAction:new({ ActionId = "mccDefaults", ActionName = T(849084517790, "DEFAULT"),
        ActionToolbar = "ActionBar", ActionGamepad = "ButtonY",
        OnAction = function() self:ResetDraft() end }, self)
    XAction:new({ ActionId = "mccApply", ActionName = T(5447, "APPLY"),
        ActionToolbar = "ActionBar", ActionGamepad = "ButtonX",
        OnAction = function() self:ApplyDraft() end }, self)
    local panel = XWindow:new({ Id = "idPanel", HAlign = "left", VAlign = "top",
        Margins = self.content_margins, LayoutMethod = "VList", LayoutVSpacing = 13 }, self)
    local list_host = XWindow:new({ LayoutMethod = "HList" }, panel)
    XList:new({ Id = "idList", MinWidth = 875, MaxWidth = 875, MaxHeight = 530,
        BorderWidth = 0, Padding = box(0, 0, 0, 0),
        Background = 0, FocusedBackground = 0, LayoutVSpacing = 13,
        VScroll = "idScroll", MouseScroll = true, ForceInitialSelection = true }, list_host)
    local scroll = ScrollbarNew:new({ Id = "idScroll", Target = "idList" }, list_host)
    -- The native scrollbar reserves its column even when hidden.
    local text_margins = box(row_indent + scroll:GetMinWidth(), 0, 0, 0)
    XText:new({ Translate = true, Id = "idHelp", TextStyle = "ListItem4", HandleMouse = false,
        Margins = text_margins, Padding = box(0, 2, 0, 2), MaxWidth = 850,
        Text = Untranslated("D-pad: choose and adjust. Apply saves changes. Speeds are pixels/sec at 1080p.") }, panel)
    local preview = XWindow:new({ Id = "idPreview", MinHeight = 135, MaxHeight = 135,
        Margins = text_margins, Background = RGBA(35, 52, 68, 100),
        Clip = "self", HandleMouse = false }, panel)
    XText:new({ Translate = true, TextStyle = "ListItem4", Text = Untranslated("TEST AREA  -  choose Test cursor to move here"),
        HandleMouse = false, Padding = box(0, 2, 0, 2) }, preview)
    XImage:new({ Id = "idPreviewCursor", HAlign = "left", VAlign = "top",
        HandleMouse = false, Image = const.DefaultMouseCursor }, preview)
    XText:new({ Translate = true, Id = "idStatus", TextStyle = "ListItem4", HandleMouse = false,
        Margins = text_margins, Padding = box(0, 2, 0, 2), MaxWidth = 850,
        Text = Untranslated("Changes are previewed here before you apply them.") }, panel)
    self:BuildRows()
end

function MCCSettingsDialog:BuildRows()
    self.testing = false
    local list = self:ResolveId("idList")
    list:Clear()
    local category = self.settings_host.mode_param
    self:ResolveId("idTitle"):SetSubtitle(TLookupTag("<GameColorTagF>") .. Untranslated(" / ") ..
        TLookupTag("<GameColorCloseTagF>") .. category.caps_name ..
        Untranslated(self.advanced and " / MOUSE CURSOR CONSOLES / ADVANCED" or " / MOUSE CURSOR CONSOLES"))
    self:ResolveId("idPreview"):SetVisible(not self.advanced)
    self:ResolveId("idPreview"):SetFoldWhenHidden(true)
    local properties = self.draft:GetProperties()
    local wanted = {}
    for i, key in ipairs(M.SettingKeys) do if (i > 3) == self.advanced then wanted[key] = true end end
    for _, prop in ipairs(properties) do
        if wanted[prop.id] then
            if prop.editor == "number" then
                PropNumber:new({ Margins = box(row_indent, 0, 0, 0), RolloverText = Untranslated(prop.help or ""),
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
    if self.window_state == "open" then
        for _, row in ipairs(list) do row:Open() end
        list:SetFocus()
        list:SetSelection(1)
    end
end

function MCCSettingsDialog:ResetDraft()
    for _, prop in ipairs(self.draft:GetProperties()) do self.draft:SetProperty(prop.id, prop.default) end
    self:BuildRows()
    self:ResolveId("idStatus"):SetText(Untranslated("Defaults restored in preview. Choose Apply to save."))
end

function MCCSettingsDialog:ApplyDraft()
    local ok, reason = M.SaveSettings(self.draft)
    if ok then self:Close("apply")
    else self:ResolveId("idStatus"):SetText(Untranslated(reason)) end
end

function MCCSettingsDialog:GoBack()
    if self.testing then self:EndTest()
    elseif self.advanced then self.advanced = false; self:BuildRows()
    else self:Close("cancel") end
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
    self:ResolveId("idStatus"):SetText(Untranslated("Test ended. Apply saves your settings; Back discards changes."))
end

function MCCSettingsDialog:OnShortcut(shortcut, source, ...)
    if shortcut == "Escape" or shortcut == "ButtonB" then
        self:GoBack()
        return "break"
    end
    if self.testing then return "break" end
    return XDialog.OnShortcut(self, shortcut, source, ...)
end

function MCCSettingsDialog:Open(...)
    XDialog.Open(self, ...)
    self:ResolveId("idList"):SetFocus()
    self:ResolveId("idList"):SetSelection(1)
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
    M.Log("SettingsUI", "opened", { layout = "options_child_page", background = "preserved", label_alignment = "controls_column" })
end

function MCCSettingsDialog:Done(result)
    if M.settings_dialog == self then M.settings_dialog = nil end
    local host = self.settings_host
    if host and host.window_state ~= "destroying" then
        for control, state in pairs(self.hidden_controls or {}) do
            if control.window_state ~= "destroying" then
                control:SetFoldWhenHidden(state.fold)
                control:SetVisible(state.visible)
            end
        end
        local list = host:ResolveId("idList")
        local entry = list and list:ResolveId("idMCCControlsEntry")
        if entry and entry.window_state ~= "destroying" then entry:SetFocus() end
        M.Log("SettingsUI", "controls_restored", { mode = host.Mode })
    end
    self.hidden_controls = false
    M.Log("SettingsUI", "closed", { result = result or "cleanup" })
end

function M.OpenSettings(host)
    if M.settings_dialog then return M.settings_dialog end
    local list = host and host:ResolveId("idList")
    local content = list and GetParentOfKind(list, "OptionsContentWindow")
    local title = host and host:ResolveId("idTitle")
    local actions = host and host:ResolveId("idActionBar")
    if not content or not title or not actions or host.window_state ~= "open" or
        host.Mode ~= "properties" or type(host.mode_param) ~= "table" or host.mode_param.id ~= "Controls" then
        M.Log("SettingsUI", "open_rejected", { reason = "native_controls_shell_unavailable" })
        return nil, "Native Controls page is unavailable."
    end
    M.RestoreVanillaBehavior("settings_opened")
    M.held, M.swallowed = {}, {}
    local hidden = {}
    for _, control in ipairs({ content, title, actions }) do
        hidden[control] = { visible = control:GetVisible(), fold = control:GetFoldWhenHidden() }
    end
    local dialog = MCCSettingsDialog:new({ settings_host = host, hidden_controls = hidden,
        content_margins = content:GetMargins() }, content.parent)
    M.settings_dialog = dialog
    for control in pairs(hidden) do
        control:SetFoldWhenHidden(true)
        control:SetVisible(false)
    end
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
    local entry = button(list, "Mouse Cursor Consoles", function() M.OpenSettings(host) end,
        { Id = "idMCCControlsEntry", ZOrder = -1 })
    M.settings_entries[entry] = host
    list:SortChildren()
    entry:Open()
    M.Log("SettingsUI", "controls_entry_added", { label_alignment = "controls_column" })
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
