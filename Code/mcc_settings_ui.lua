-- A transparent child page in the existing Options shell.
-- Reuses native title, action bar and sliders; no shared classes are patched.
local M = MCC
local row_indent = 18
M.settings_entries = {}
DefineClass.MCCSettingsDialog = {
    __parents = { "XDialog" },
    Id = "idMCCSettings", IdNode = true, IsModal = true,
    Dock = "box", ZOrder = 2, Background = 0,
    draft = false, settings_host = false,
    preview_motion = false,
    hidden_controls = false, content_margins = false, shell_halign = false,
}

local function button(parent, text, action, properties)
    local row_properties = properties or {}
    row_properties.Text = Untranslated(text)
    row_properties.TextStyle = "PropName"
    row_properties.Margins = row_properties.Margins or box(row_indent, 0, 0, 0)
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
    local panel = XWindow:new({ Id = "idPanel", Dock = "box",
        Margins = box(113, self.content_margins:miny(), 79, self.content_margins:maxy()) }, self)
    -- Native control size, with compact spacing to fit all fifteen rows.
    local column = XWindow:new({ Id = "idSettingsColumn", Dock = "left",
        MinWidth = 875, MaxWidth = 875, LayoutMethod = "VList", LayoutVSpacing = 16 }, panel)
    XList:new({ Id = "idList", MinWidth = 875, MaxWidth = 875,
        LeftThumbScroll = false,
        BorderWidth = 0, Padding = box(0, 0, 0, 0),
        Background = 0, FocusedBackground = 0, LayoutVSpacing = 6,
        MouseScroll = false, ForceInitialSelection = true }, column)
    -- Keep validation/save errors available without permanent instruction text.
    XText:new({ Translate = true, Id = "idStatus", TextStyle = "ListItem4", HandleMouse = false,
        Visible = false, FoldWhenHidden = true, Padding = box(0, 0, 0, 0), MaxWidth = 875 }, column)
    local preview = XAspectWindow:new({ Id = "idPreview", Dock = "ignore",
        Aspect = point(1, 1), Fit = "smallest", HAlign = "center", VAlign = "center",
        Background = RGBA(35, 52, 68, 100), Clip = "self", HandleMouse = false }, self)
    XImage:new({ Id = "idPreviewCursor", HAlign = "left", VAlign = "top",
        HandleMouse = false, Image = const.DefaultMouseCursor }, preview)
    self:BuildRows()
end

function MCCSettingsDialog:OnLayoutComplete()
    -- Position in screen pixels: centered in the right half, clear of the
    -- Options title/footer and the native-size settings column.
    local width, height = UIL.GetScreenSizeXY()
    local center_x, center_y = MulDivRound(width, 3, 4), MulDivRound(height, 1, 2)
    local panel = self:ResolveId("idPanel").box
    local column = self:ResolveId("idSettingsColumn").box
    local gap = MulDivRound(28, self.scale:x(), 1000)
    local half_width = Min(center_x - Max(MulDivRound(width, 1, 2), column:maxx() + gap),
        panel:maxx() - center_x)
    local half_height = Min(center_y - panel:miny(), panel:maxy() - center_y)
    local half = Max(0, Min(half_width, half_height))
    local area = self:ResolveId("idPreview")
    local previous = area.box
    area:SetLayoutSpace(center_x - half, center_y - half, 2 * half, 2 * half)
    if previous ~= area.box then
        M.Log("SettingsUI", "preview_layout", { side = 2 * half, center_x = center_x, center_y = center_y })
    end
end

function MCCSettingsDialog:BuildRows()
    local list = self:ResolveId("idList")
    list:Clear()
    local category = self.settings_host.mode_param
    self:ResolveId("idTitle"):SetSubtitle(TLookupTag("<GameColorTagF>") .. Untranslated(" / ") ..
        TLookupTag("<GameColorCloseTagF>") .. category.caps_name ..
        Untranslated(" / MOUSE CURSOR CONSOLES"))
    local properties = self.draft:GetProperties()
    for _, prop in ipairs(properties) do
        if prop.editor == "number" then
            PropNumber:new({ Margins = box(0, 0, 0, 0), RolloverText = Untranslated(prop.help or ""),
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
            row = button(list, label(), function() cycle(1) end, { Margins = box(0, 0, 0, 0) })
            row.OnShortcut = function(control, shortcut, source, ...)
                if shortcut == "DPadLeft" then cycle(-1); return "break" end
                if shortcut == "DPadRight" then cycle(1); return "break" end
                return MenuEntrySmall.OnShortcut(control, shortcut, source, ...)
            end
        end
    end
    M.Log("SettingsUI", "rows_built", { count = #list, scrolling = false, preview_left_stick = true })
    if self.window_state == "open" then
        for _, row in ipairs(list) do row:Open() end
        list:SetFocus()
        list:SetSelection(1)
    end
end

function MCCSettingsDialog:ResetDraft()
    for _, prop in ipairs(self.draft:GetProperties()) do self.draft:SetProperty(prop.id, prop.default) end
    self:BuildRows()
    self:ResolveId("idStatus"):SetVisible(false)
end

function MCCSettingsDialog:ApplyDraft()
    local ok, reason = M.SaveSettings(self.draft)
    if ok then self:Close("apply")
    else
        local status = self:ResolveId("idStatus")
        status:SetText(Untranslated(reason))
        status:SetVisible(true)
    end
end

function MCCSettingsDialog:GoBack()
    self:Close("cancel")
end

function MCCSettingsDialog:OnShortcut(shortcut, source, ...)
    if shortcut == "Escape" or shortcut == "ButtonB" then
        self:GoBack()
        return "break"
    end
    return XDialog.OnShortcut(self, shortcut, source, ...)
end

function MCCSettingsDialog:Open(...)
    XDialog.Open(self, ...)
    self:ResolveId("idList"):SetFocus()
    self:ResolveId("idList"):SetSelection(1)
    self:CreateThread("MCCPreview", function()
        local last = RealTime()
        local last_size, last_color, last_x, last_y
        local last_controller, last_connected
        while self.window_state ~= "destroying" do
            WaitNextFrame()
            local time = RealTime()
            local cfg = M.ReadSettings(self.draft)
            local area, image = self:ResolveId("idPreview"), self:ResolveId("idPreviewCursor")
            if cfg.CURSOR_SIZE ~= last_size or cfg.CURSOR_COLOR ~= last_color then
                M.StyleCursor(image, cfg)
                last_size, last_color = cfg.CURSOR_SIZE, cfg.CURSOR_COLOR
            end
            -- measure_width/height include the moving margins. The rendered
            -- box excludes them, so the travel bounds stay fixed at every edge.
            local max_x = Max(0, area.content_box:sizex() - image.box:sizex())
            local max_y = Max(0, area.content_box:sizey() - image.box:sizey())
            self.preview_motion.x = Clamp(self.preview_motion.x, 0, max_x * 1000)
            self.preview_motion.y = Clamp(self.preview_motion.y, 0, max_y * 1000)
            local id = type(ActiveController) == "number" and ActiveController or 0
            local connected = XInput.IsControllerConnected(id)
            if id ~= last_controller or connected ~= last_connected then
                M.Log("SettingsUI", "preview_controller", { controller = id, connected = connected })
                last_controller, last_connected = id, connected
            end
            if connected then
                local state = XInput.CurrentState[id]
                if state and state.LeftThumb then
                    local ax, ay = state.LeftThumb:xy()
                    local _, screen_height = UIL.GetScreenSizeXY()
                    local boost = M.Config.ENABLE_SPEED_BOOST == true and XInput.IsCtrlButtonPressed(id, cfg.SPEED_BOOST_BUTTON) == true
                    M.AdvanceCursor(self.preview_motion, ax, ay, state.LeftThumb:Len2D(), time - last,
                        max_x + 1, max_y + 1, boost, cfg, screen_height)
                end
            end
            local x = MulDivRound(self.preview_motion.x, 1, area.scale:x())
            local y = MulDivRound(self.preview_motion.y, 1, area.scale:y())
            if x ~= last_x or y ~= last_y then image:SetMargins(box(x, y, 0, 0)); last_x, last_y = x, y end
            last = time
        end
    end)
    M.Log("SettingsUI", "opened", { layout = "all_settings_left_preview_right", background = "preserved", scrolling = false })
end

function MCCSettingsDialog:Done(result)
    if M.settings_dialog == self then M.settings_dialog = nil end
    local host = self.settings_host
    if self.parent and self.parent.window_state ~= "destroying" then
        self.parent:SetHAlign(self.shell_halign)
    end
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
        content_margins = content:GetMargins(), shell_halign = content.parent:GetHAlign() }, content.parent)
    M.settings_dialog = dialog
    for control in pairs(hidden) do
        control:SetFoldWhenHidden(true)
        control:SetVisible(false)
    end
    content.parent:SetHAlign("stretch")
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
