-- WT_Notes.lua
local WT_Notes = LibStub("AceAddon-3.0"):NewAddon("WT_Notes", "AceConsole-3.0",
                                                  "AceEvent-3.0", "AceComm-3.0")
local AceGUI = LibStub("AceGUI-3.0", true)
local AceDB = LibStub('AceDB-3.0')
local Base64 = LibStub('LibBase64-1.0')
-- 初始化全局数据
WT_Notes.notes = {}
-- 主面板
WT_Notes.Note_M_Frame = nil
-- 左侧笔记列表面板
WT_Notes.Note_M_L_Body_Frame = nil
-- 中间编辑器面板
WT_Notes.Note_M_E_Body_Frame = nil
-- 右侧工具栏面板
WT_Notes.Note_M_T_Body_Frame = nil
-- 右侧设置栏面板
WT_Notes.Note_M_S_Body_Frame = nil
-- 编辑器文本框
WT_Notes.Note_M_E_Body_EditBox = nil

WT_Notes.Note_M_S_Body_pinCheckbox = nil

WT_Notes.Note_M_S_Body_sendChannel = "PARTY"

-- 在 WT_Notes 表中添加格式化控制变量
WT_Notes.IsFormattingOn = true
WT_Notes.IsFormattingOn_Saved = false
WT_Notes.last_highlight_start = 0
WT_Notes.last_highlight_end = 0
WT_Notes.last_cursor_pos = 0

WT_Notes.CURRENT_COLOR_CODE = "00ff00"

WT_Notes.PERVIEW_WINDOW = nil
WT_Notes.PERVIEW_WINDOW_TEXT = nil
WT_Notes.notebookSetting = {
    enabled = false,
    noteFontSize = 50,
    noteListAlpha = 0.8,
    noteBodyAlpha = 0.6,
    noteRightAlpha = 0.8,
    noteThemeColor = "00bd00"
}

-- 定义切换主面板显示的函数
function WT_Notes:ToggleNoteMainPanel(open)
    -- 如果未显示，则显示
    if open then
        WT_Notes.Note_M_Frame:Show()
    else
        WT_Notes.Note_M_Frame:Hide()
    end
end

-- 选中的笔记数据
WT_Notes.selectedNote = {
    name = "笔记名称: ",
    index = nil,
    content = "",
    settings = {pin = false},
    _NOTE_ROW = nil,
    _NOTE_ROW_TEXT = nil,
    _NOTE_PIN_WINDOWN = nil,
    _NOTE_PIN_WINDOWN_TEXT = nil
}
-- 选中笔记按钮对应的Title
WT_Notes.selectedEditNoteTitle = nil

-- 定义一个函数来注册自己到父模块
function WT_Notes:RegisterWithParent(parent) self.parent = parent end

local function CreateButton(frame, template, title, width, height)
    local btn = CreateFrame("Button", title, frame, template)
    btn:SetSize(width, height)
    -- 创建FontString并设置属性
    local btnText = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    btnText:SetText(title) -- 设置文本
    return btn, btnText
end

function WT_Notes:AlertWarn(msg)
    StaticPopupDialogs["WEIWAN_ERROR_CONFIRM_POPUP"] = {
        text = msg,
        button1 = "确定",
        OnAccept = function()
            StaticPopup_Hide("WEIWAN_ERROR_CONFIRM_POPUP");
        end,
        timeout = 0,
        whileDead = 1,
        showAlert = 1,
        exclusive = 1
    }
    StaticPopup_Show("WEIWAN_ERROR_CONFIRM_POPUP")
end

function WT_Notes:CheckNoteNameExist(noteName)
    -- 检查是否有重名的笔记
    local isDuplicate = false
    for index, note in pairs(self.notes) do
        if note.name == noteName then
            isDuplicate = true
            break
        end
    end
    return isDuplicate
end

function WT_Notes:HexToRGB(hex)
    -- 验证十六进制颜色代码是否是有效的6个字符长度
    if #hex ~= 6 then error("Invalid hex color code") end

    -- 从十六进制颜色代码中提取RGB分量
    local r = tonumber("0x" .. string.sub(hex, 1, 2)) / 255
    local g = tonumber("0x" .. string.sub(hex, 3, 4)) / 255
    local b = tonumber("0x" .. string.sub(hex, 5, 6)) / 255

    return r, g, b
end

function WT_Notes:RenameNote(newName)

    -- 首先检查新名称是否为空
    if newName == nil or newName == "" then
        WT_Notes:AlertWarn("笔记名称不能为空。")
        return
    end

    -- 检查是否有重名的笔记
    if WT_Notes:CheckNoteNameExist(newName) then
        local msg = "存在同名的笔记，请选择一个不同的名称。"
        WT_Notes:AlertWarn(msg)
    else
        WT_Notes.selectedNote.name = newName
        WT_Notes:UpdateNoteAll()
        WT_Notes.selectedNote._NOTE_ROW_TEXT:SetText(WT_Notes.selectedNote.name)
        WT_Notes:UpdatePinWindow(WT_Notes.selectedNote)
    end
end

local function SetWayPoint(mapID, x, y)
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x / 10000,
                                                           y / 10000))
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)

end
function mysplit(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end
local function OnHyperlinkClickHandle(hyperlink)
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    if string.match(hyperlink, "^trade") then
        GameTooltip:SetHyperlink(hyperlink)
        GameTooltip:Show()
    elseif string.match(hyperlink, "^worldmap") then
        local list = mysplit(hyperlink, ":")
        SetWayPoint(list[2], list[3], list[4])
        GameTooltip:SetText("点击创建地图标记")
        GameTooltip:Show()
    elseif string.match(hyperlink, "^journal") then
        GameTooltip:SetHyperlink(hyperlink)
        GameTooltip:Show()
    else
        GameTooltip:SetHyperlink(hyperlink)
        GameTooltip:Show()
    end
end

local function OnHyperlinkEnterHandle(hyperlink)
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    if string.match(hyperlink, "^trade") then
        GameTooltip:SetText("点击打开专业面板")
        GameTooltip:Show()
    elseif string.match(hyperlink, "^worldmap") then
        GameTooltip:SetText("点击创建地图标记")
        GameTooltip:Show()
    elseif string.match(hyperlink, "^journal") then
        GameTooltip:SetText("点击打开冒险手册")
        GameTooltip:Show()
    else
        GameTooltip:SetHyperlink(hyperlink)
        GameTooltip:Show()
    end

end

local function OnHyperlinkLeaveHandle(self) GameTooltip:Hide() end
local function CreatePinWindow(note)
    local window = AceGUI:Create("Window")
    window:SetTitle(note.name) -- 设置窗口标题
    window:SetWidth(300) -- 设置窗口初始宽度
    window:SetHeight(400) -- 设置窗口初始高度
    window_text = AceGUI:Create("Label")

    -- 创建一个Label组件
    window_text:SetHeight(20) -- 设置高度，根据需要调整
    window_text:SetWidth(200) -- 设置宽度，根据需要调整
    window_text:SetFullWidth(true) -- 让Label宽度充满其父容器的宽度

    -- 将Label添加到AceGUI容器中
    window:AddChild(window_text)

    -- 可选：设置文本对齐方式
    window_text:SetJustifyH("LEFT") -- 左对齐
    window:SetCallback("OnClose", function(widget)
        window:Hide()
        window_text:SetText("")
    end)
    window_text:SetText(note.content) -- 设置文本
    window_text:SetPoint("TOPLEFT", 10, -30) -- 设置文本对象的位置
    window_text:SetFontObject(GameFontNormal) -- 设置字体对象，您也可以指定其他字体

    window_text.frame:SetHyperlinksEnabled(true)
    -- 注册 OnHyperlinkEnter 事件
    window_text.frame:SetScript("OnHyperlinkEnter", function(self, hyperlink)
        OnHyperlinkEnterHandle(hyperlink)
    end)

    -- 注册 OnHyperlinkLeave 事件
    window_text.frame:SetScript("OnHyperlinkLeave",
                                function(self) OnHyperlinkLeaveHandle(self) end)

    -- 注册 OnHyperlinkLeave 事件
    window_text.frame:SetScript("OnHyperlinkClick", function(self, hyperlink)
        OnHyperlinkClickHandle(hyperlink)
    end)
    window.frame:Hide()
    return window, window_text
end

local function ShowPinWindow(note)
    if note.settings.pin == true then
        WT_Notes:UpdatePinWindow(note)
        note._NOTE_PIN_WINDOWN.frame:Show()
    end
end

local function HidePinWindow(note)
    if note.settings.pin == false then
        WT_Notes:UpdatePinWindow(note)
        note._NOTE_PIN_WINDOWN.frame:Hide()
    end
end

function WT_Notes:UpdatePinWindow(note)
    if (note._NOTE_PIN_WINDOWN ~= nil) then
        note._NOTE_PIN_WINDOWN_TEXT:SetText(note.content)
        note._NOTE_PIN_WINDOWN:SetTitle(note.name)
    end
end

-- 创建一个函数来添加标签按钮
local function CreateNoteRow(note)
    local tabVerticalOffset = 0 -- 初始化偏移量为0
    local noteRow, noteRowText = CreateButton(WT_Notes.Note_M_L_Body_Frame,
                                              "WT_NotesTabButtonTemplate",
                                              note.name, 200, 20)
    -- 检查index的值，如果不等于1，则设置偏移量
    if note.index ~= 1 then
        tabVerticalOffset = 20 * (note.index - 1) -- 根据index计算偏移量
    end
    noteRow:SetPoint("TOPLEFT", WT_Notes.Note_M_L_Body_Frame, "TOPLEFT", 0,
                     -tabVerticalOffset)
    noteRow.Bg:SetVertexColor(0, 0, 0, 0)
    note._NOTE_ROW = noteRow
    note._NOTE_ROW_TEXT = noteRowText
    local window, window_text = CreatePinWindow(note)
    note._NOTE_PIN_WINDOWN = window
    note._NOTE_PIN_WINDOWN_TEXT = window_text
    ShowPinWindow(note)
    noteRowText:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    noteRowText:SetPoint("LEFT", 0, 0) -- 文本居中
    noteRowText:SetTextColor(1, 1, 1) -- 设置文本颜色为白色

    noteRow:SetScript("OnClick", function(self)
        WT_Notes.selectedNote = note
        WT_Notes:SelectNote()
    end)

    return note
end

-- 定义新建笔记的对话框函数
function WT_Notes:ShowNewNoteDialog()
    -- 定义新建笔记的对话框
    StaticPopupDialogs["CREATE_NEW_NOTE_DIALOG"] = {
        text = "输入新笔记的名称：",
        button1 = "创建",
        button2 = "取消",
        hasEditBox = true, -- 指定存在一个输入框
        editBoxWidth = 200, -- 输入框的宽度
        timeout = 0,
        whileDead = 1,
        showAlert = 1,
        showInCombat = 1,
        exclusive = 1,
        hideOnEscape = 1,
        OnAccept = function(self)
            local newNoteName = self.editBox:GetText() -- 获取输入框中的文本
            if newNoteName and newNoteName ~= "" then
                StaticPopup_Hide("CREATE_NEW_NOTE_DIALOG")
                -- 调用新建笔记的函数
                WT_Notes:CreateNewNote(newNoteName)
            else
                -- 如果输入为空，则显示错误消息
                WT_Notes:AlertWarn("名称不能为空。")
            end
        end,
        OnCancel = function(self)
            StaticPopup_Hide("CREATE_NEW_NOTE_DIALOG")
        end,
        EditBoxOnEscapePressed = function(self)
            StaticPopup_Hide("CREATE_NEW_NOTE_DIALOG")
        end
    }
    -- 显示对话框
    StaticPopup_Show("CREATE_NEW_NOTE_DIALOG")
end

function WT_Notes:SaveNoteContent()
    if WT_Notes.selectedNote then
        WT_Notes.selectedNote.content = WT_Notes.Note_M_E_Body_EditBox:GetText()
        -- 这里可以添加额外的代码来更新笔记的显示或其他逻辑
        if WT_Notes.selectedNote.settings.pin then
            WT_Notes.selectedNote._NOTE_PIN_WINDOWN_TEXT:SetText(
                WT_Notes.selectedNote.content)
        end
    end
end
function WT_Notes:UpdateEditBoxText()
    if self.selectedNote and self.selectedNote.index ~= nil then
        WT_Notes.Note_M_E_Body_EditBox:SetText(self.selectedNote.content or "")
        WT_Notes.Note_M_E_Body_EditBox:HighlightText(0, 0) -- 清除高亮
    else
        WT_Notes.Note_M_E_Body_EditBox:SetText("")
        WT_Notes.Note_M_E_Body_EditBox:HighlightText(0, 0) -- 清除高亮
    end
end

function WT_Notes:UpdatePinCheckbox()
    if (WT_Notes.selectedNote._NOTE_PIN_WINDOWN ~= nil) then
        WT_Notes.Note_M_S_Body_pinCheckbox:SetDisabled(false)
        WT_Notes.Note_M_S_Body_pinCheckbox:SetValue(
            WT_Notes.selectedNote.settings.pin)
    else
        WT_Notes.Note_M_S_Body_pinCheckbox:SetDisabled(true)
        WT_Notes.Note_M_S_Body_pinCheckbox:SetValue(
            WT_Notes.selectedNote.settings.pin)
    end

end

-- 定义选中笔记的函数
function WT_Notes:SelectNote()
    -- 清除其他笔记的选中状态
    if WT_Notes.selectedNote then
        for idx, note in pairs(WT_Notes.notes) do
            if note.index == WT_Notes.selectedNote.index then
                note._NOTE_ROW.Bg:SetVertexColor(1, 1, 0, 0.8) -- 设置为默认颜色
                WT_Notes:UpdateNoteAll()
            end
        end
    end

    if WT_Notes.selectedNote then
        for idx, note in pairs(self.notes) do
            if note.index ~= WT_Notes.selectedNote.index then
                note._NOTE_ROW.Bg:SetVertexColor(0, 0, 0, 0) -- 设置为默认颜色
            end
        end
    end
    WT_Notes:UpdateNoteAll()
    WT_Notes:UpdatePinWindow(WT_Notes.selectedNote)
end

-- 这个函数可以在添加或删除笔记后调用，以更新EditBox的状态
function WT_Notes:UpdateEditBoxAfterNoteChange()
    WT_Notes.Note_M_E_Body_EditBox:SetDisabled(#self.notes < 1)
end

function WT_Notes:UpdateEditTitle()
    -- 使用if-else语句设置文本
    if WT_Notes.selectedNote.name == "笔记名称: " then
        WT_Notes.selectedEditNoteTitle:SetText("笔记名称: ")
    else
        WT_Notes.selectedEditNoteTitle:SetText("笔记名称: " ..
                                                   WT_Notes.selectedNote.name)
    end
end

function WT_Notes:UpdateNoteAll()
    -- 更新编辑器状态
    WT_Notes:UpdateEditBoxAfterNoteChange()
    -- 更新编辑器标题
    WT_Notes:UpdateEditTitle()
    -- 更新编辑器文本
    WT_Notes:UpdateEditBoxText()

    WT_Notes:UpdatePinCheckbox()
end

-- 定义删除笔记的函数
function WT_Notes:DeleteNote()
    if self.selectedNote then
        -- 从数据结构中移除笔记

        -- 假设 self.notes 是一个包含多个笔记的表
        for index, note in ipairs(self.notes) do
            if note.name == self.selectedNote.name then
                self.selectedNote._NOTE_ROW:Hide()
                self.selectedNote._NOTE_ROW:ClearAllPoints() -- 清除所有锚点
                self.selectedNote._NOTE_ROW:SetParent(nil) -- 设置父级为 nil
                self.selectedNote.settings.pin = false
                HidePinWindow(self.selectedNote)
                self.selectedNote._NOTE_PIN_WINDOWN = nil
                self.selectedNote._NOTE_PIN_WINDOWN_TEXT = nil
                table.remove(self.notes, note.index)
            end
        end

        if #self.notes > 0 then
            -- 刷新笔记列表UI
            self:RefreshNoteListUI()
            -- 如果还有笔记，选中最后一个笔记（因为刚删除了一个，最后一个会上移）
            self.selectedNote = self.notes[1]
            self:SelectNote()
        else
            self.selectedNote = {
                name = "笔记名称: ",
                index = nil,
                content = "",
                settings = {pin = false},
                _NOTE_ROW = nil,
                _NOTE_ROW_TEXT = nil,
                _NOTE_PIN_WINDOWN = nil,
                _NOTE_PIN_WINDOWN_TEXT = nil
            }
            WT_Notes:UpdateNoteAll()
        end

    else
        -- 如果没有选中的笔记，显示警告信息
        local msg = "没有选中的笔记，无法删除。"
        self:AlertWarn(msg)
    end
end

-- 定义创建新笔记的函数
function WT_Notes:CreateNewNote(name)

    -- 检查是否达到最大笔记数量限制
    if #self.notes >= 30 then
        local msg = "您已达到最大笔记数量限制（30篇）。"
        self:AlertWarn(msg)
        return -- 达到数量限制，不再继续创建笔记
    end

    -- 检查笔记名称是否已存在
    if self:CheckNoteNameExist(name) then
        local msg = "存在同名的笔记，请选择一个不同的名称。"
        self:AlertWarn(msg)
    else
        -- 创建新的笔记条目
        local newNote = {
            name = name,
            index = #self.notes + 1,
            content = "", -- 新建笔记初始内容为空
            settings = {pin = false},
            _NOTE_ROW = nil,
            _NOTE_ROW_TEXT = nil,
            _NOTE_PIN_WINDOWN = nil,
            _NOTE_PIN_WINDOWN_TEXT = nil
        }
        table.insert(self.notes, newNote) -- 将新笔记添加到笔记列表
        -- 创建笔记行并添加到UI中
        local createdNote = CreateNoteRow(newNote)

        WT_Notes.selectedNote = createdNote
        -- 选中新创建的笔记
        self:SelectNote();

    end
end

-- 定义删除笔记的确认对话框函数
function WT_Notes:ConfirmDeleteNote()

    if #self.notes < 1 then
        WT_Notes:AlertWarn("没有笔记可以删除!")
        return
    end
    if self.selectedNote and self.selectedNote.name ~= "笔记名称:" then
        StaticPopupDialogs["CONFIRM_DELETE_NOTE"] = {
            text = "确定要删除笔记 '" .. self.selectedNote.name ..
                "' 吗？",
            button1 = "删除",
            button2 = "取消",
            OnAccept = function() self:DeleteNote() end,
            showAlert = 1,
            whileDead = 1,
            showInCombat = 1,
            timeout = 0,
            exclusive = 1,
            hideOnEscape = 1
        }
        StaticPopup_Show("CONFIRM_DELETE_NOTE")
    else
        local msg = "没有选中的笔记，无法删除。"
        self:AlertWarn(msg)
    end
end

-- 定义刷新笔记列表UI的函数
function WT_Notes:RefreshNoteListUI()
    if WT_Notes.Note_M_L_Body_Frame then
        -- 先隐藏所有现有的笔记行
        for index, note in pairs(self.notes) do note._NOTE_ROW:Hide() end
        -- 重新创建笔记行并添加到UI中
        for index, note in ipairs(self.notes) do
            note.index = index
            local createdNote = CreateNoteRow(note)
        end
    end
end

function WT_Notes:ApplyColorToSelectedText(editBox, colorCode)
    local Start, End = self:GetTextHighlight(editBox)
    -- 检查是否选择了文本
    if Start == End then return end

    -- 获取当前文本
    local Text = editBox:GetText()
    local s_str = Text:sub(1, Start)
    local c_str = Text:sub(Start + 1, End)
    local e_str = Text:sub(End + 1)
    -- 应用颜色代码到选中的文本
    local NewText = Text:sub(1, Start) .. "|cff" .. colorCode ..
                        Text:sub(Start + 1, End) .. "|r" .. Text:sub(End + 1)
    -- 设置新文本到编辑框
    WT_Notes.selectedNote.content = NewText
    WT_Notes:UpdateEditBoxText()
    WT_Notes.SaveNoteContent()
end

function WT_Notes:GetTextHighlight(editBox)
    local Text, Cursor = editBox:GetText(), editBox:GetCursorPosition();
    editBox:Insert(""); -- Delete selected text
    local TextNew, CursorNew = editBox:GetText(), editBox:GetCursorPosition();
    -- Restore previous text
    editBox:SetText(Text);
    editBox:SetCursorPosition(Cursor);
    local Start, End = CursorNew, #Text - (#TextNew - CursorNew);
    editBox:HighlightText(Start, End);
    return Start, End;
end

function WT_Notes:rgbaToHex(r, g, b, a)
    return string.format("%02x%02x%02x", math.floor(r * 255),
                         math.floor(g * 255), math.floor(b * 255))
end

function WT_Notes:ShowExportDialog(encodedContent)
    -- 定义导出对话框
    StaticPopupDialogs["WT_NOTES_EXPORT_DIALOG"] = {
        text = "导出的笔记内容：",
        button1 = "确定",
        timeout = 0,
        whileDead = 1,
        showAlert = false,
        showInCombat = 1,
        exclusive = 1,
        hideOnEscape = 1,
        hasEditBox = true, -- 指定存在一个输入框
        OnShow = function(self, data)
            self.editBox:SetText(encodedContent)
        end,
        OnAccept = function(self, data, data2)
            local text = self.editBox:GetText()
            -- do whatever you want with it
        end,
        editBoxWidth = 300, -- 输入框的宽度
        EditBoxIsMultiLine = false, -- 多行文本框
        EditBoxMaxLetters = 9999999 -- 设置最大字符数，避免过长文本导致的问题
    }

    -- 显示对话框并设置文本框内容
    StaticPopup_Show("WT_NOTES_EXPORT_DIALOG")
end
function generateRandomString(length)
    -- 定义可能包含在随机字符串中的字符
    local charset =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

    -- 初始化一个空字符串
    local randomString = ""

    -- 循环生成指定长度的随机字符串
    for i = 1, length do
        -- 从charset中选取一个随机字符
        local randomIndex = math.random(1, #charset)
        local randomChar = charset:sub(randomIndex, randomIndex)
        -- 将随机字符添加到结果字符串
        randomString = randomString .. randomChar
    end

    return randomString
end

function WT_Notes:ShowImportDialog()
    -- 定义导出对话框
    StaticPopupDialogs["WT_NOTES_IMPORT_DIALOG"] = {
        text = "导入的笔记字符串：",
        button1 = "导入",
        timeout = 0,
        whileDead = 1,
        showAlert = false,
        showInCombat = 1,
        exclusive = 1,
        hideOnEscape = 1,
        hasEditBox = true, -- 指定存在一个输入框
        OnShow = function(self, data) self.editBox:SetText("") end,
        OnAccept = function(self, data, data2)
            local encodedContent = self.editBox:GetText()
            if encodedContent == nil or encodedContent == "" then
                WT_Notes:AlertWarn("不能导入空字符串!")
            end
            local newName = nil
            local newContent = nil
            if encodedContent then
                local strarr = mysplit(encodedContent, "@@@@@@")
                if #strarr > 1 then
                    newName = strarr[1]
                    newContent = strarr[2]
                end
            end

            local noteName = Base64:Decode(newName)
            local noteContent = Base64:Decode(newContent)

            if WT_Notes:CheckNoteNameExist(noteName) then
                noteName = noteName .. "_" .. generateRandomString(8)
            end
            -- 创建新的笔记条目
            local newNote = {
                name = noteName,
                index = #WT_Notes.notes + 1,
                content = noteContent, -- 新建笔记初始内容为空
                settings = {pin = false},
                _NOTE_ROW = nil,
                _NOTE_ROW_TEXT = nil,
                _NOTE_PIN_WINDOWN = nil,
                _NOTE_PIN_WINDOWN_TEXT = nil
            }
            table.insert(WT_Notes.notes, newNote) -- 将新笔记添加到笔记列表
            -- 创建笔记行并添加到UI中
            local createdNote = CreateNoteRow(newNote)
            WT_Notes.selectedNote = createdNote
            -- 选中新创建的笔记
            WT_Notes:SelectNote();
        end,
        editBoxWidth = 300, -- 输入框的宽度
        EditBoxIsMultiLine = false, -- 多行文本框
        EditBoxMaxLetters = 9999999 -- 设置最大字符数，避免过长文本导致的问题
    }

    -- 显示对话框并设置文本框内容
    StaticPopup_Show("WT_NOTES_IMPORT_DIALOG")
end

function WT_Notes:SyncNoteToOthers()
    if (#WT_Notes.notes < 1) then
        WT_Notes:AlertWarn("没有笔记可以同步!")
        return
    end
    if WT_Notes.selectedNote == nil then
        WT_Notes:AlertWarn("请选择一篇笔记同步!")
        return
    else
        if WT_Notes.selectedNote.content == nil or WT_Notes.selectedNote.content ==
            "" then
            WT_Notes:AlertWarn("同步的笔记内容不能为空!")
            return
        end
    end
    local encodedContent = Base64:Encode(WT_Notes.selectedNote.content)
    local encodedName = Base64:Encode(WT_Notes.selectedNote.name)
    local message = "WT_Notes:" .. encodedName .. "@@@@@@" .. encodedContent
    WT_Notes:SendCommMessage("WT_Notes", message, "RAID")
end
local function removeColorCodes(text)
    -- 正则表达式匹配颜色代码及其包围的文本
    local pattern = "(.-)|cff[0-9a-fA-F]+(.-)|r(.-)"
    -- 正则表达式匹配特殊链接
    local linkPattern = "|H[^|]*|h[^|]*|h"

    -- 替换操作
    local hasLink = string.match(text, linkPattern)
    local beforeText, colorText, afterText = string.match(text, pattern)
    if colorText and not hasLink then
        return beforeText .. colorText .. afterText
    else
        return text
    end
end
-- 设置UI界面
function WT_Notes:SetupUI()
    -- 创建一个框架实例
    self.frame =
        CreateFrame("Frame", "WT_NotesFrame", UIParent, "WT_NotesFrame")
    self.frame:SetPoint("CENTER")
    self.frame:SetSize(1200, 700)
    self.frame:SetFrameStrata("HIGH"); -- 设置框架的层级为高
    self.frame:SetFrameLevel(0)
    self.frame.Bg:SetColorTexture(0, 0, 0, 0)
    local tr, tg, tb =
        WT_Notes:HexToRGB(WT_Notes.notebookSetting.noteThemeColor)
    self.frame.WT_NoteListFrame:SetSize(200, 700)
    self.frame.WT_NoteListFrame.Bg:SetColorTexture(0, 0, 0, 0)
    self.frame.WT_NoteListFrame.WT_NoteListFrameTitle:SetSize(200, 30)

    self.frame.WT_NoteListFrame.WT_NoteListFrameTitle.Bg:SetColorTexture(tr, tg,
                                                                         tb, 1)
    local listTitleText =
        self.frame.WT_NoteListFrame.WT_NoteListFrameTitle:CreateFontString(nil,
                                                                           "ARTWORK",
                                                                           "GameFontNormal")
    listTitleText:SetFont(STANDARD_TEXT_FONT, 24, "OUTLINE")
    listTitleText:SetText("笔记列表")
    listTitleText:SetTextColor(1, 1, 1)
    listTitleText:SetPoint("TOPLEFT",
                           self.frame.WT_NoteListFrame.WT_NoteListFrameTitle,
                           "TOPLEFT", 0, -5)
    self.frame.WT_NoteListFrame.WT_NoteListFrameBody:SetSize(200, 600)
    self.frame.WT_NoteListFrame.WT_NoteListFrameBody.Bg:SetColorTexture(0, 0, 0,
                                                                        WT_Notes.notebookSetting
                                                                            .noteListAlpha)
    self.frame.WT_NoteListFrame:SetFrameStrata("HIGH");
    self.frame.WT_NoteListFrame:SetFrameLevel(0)
    self.frame.WT_NoteListFrame.WT_NoteListFrameOpt:SetSize(200, 70)
    self.frame.WT_NoteListFrame.WT_NoteListFrameOpt.Bg:SetColorTexture(0, 0, 0,
                                                                       WT_Notes.notebookSetting
                                                                           .noteListAlpha)
    local newNoteBtn, newNoteBtnText = CreateButton(
                                           self.frame.WT_NoteListFrame
                                               .WT_NoteListFrameOpt,
                                           "WT_OptButtonTemplate_1",
                                           "新建笔记", 170, 20)

    newNoteBtnText:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    newNoteBtnText:SetPoint("CENTER", 0, 0) -- 文本居中
    newNoteBtnText:SetTextColor(1, 1, 1) -- 设置文本颜色为白色
    newNoteBtn:SetPoint("TOPLEFT",
                        self.frame.WT_NoteListFrame.WT_NoteListFrameOpt,
                        "TOPLEFT", 15, -10)
    newNoteBtn.Bg:SetVertexColor(0, 0, 0, 1)
    newNoteBtn:SetScript("OnClick",
                         function(self) WT_Notes:ShowNewNoteDialog() end)

    local deleteNoteBtn, deleteNoteBtnText =
        CreateButton(self.frame.WT_NoteListFrame.WT_NoteListFrameOpt,
                     "WT_OptButtonTemplate_2", "删除", 78, 20)

    deleteNoteBtnText:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    deleteNoteBtnText:SetPoint("CENTER", 0, 0) -- 文本居中
    deleteNoteBtnText:SetTextColor(1, 1, 1) -- 设置文本颜色为白色
    deleteNoteBtn:SetPoint("TOPLEFT",
                           self.frame.WT_NoteListFrame.WT_NoteListFrameOpt,
                           "TOPLEFT", 15, -35)
    deleteNoteBtn.Bg:SetVertexColor(0, 0, 0, 1)
    deleteNoteBtn:SetScript("OnClick",
                            function(self) WT_Notes:ConfirmDeleteNote() end)

    local renameNoteBtn, renameNoteBtnText =
        CreateButton(self.frame.WT_NoteListFrame.WT_NoteListFrameOpt,
                     "WT_OptButtonTemplate_2", "重命名", 78, 20)

    renameNoteBtnText:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    renameNoteBtnText:SetPoint("CENTER", 0, 0) -- 文本居中
    renameNoteBtnText:SetTextColor(1, 1, 1) -- 设置文本颜色为白色
    renameNoteBtn:SetPoint("TOPLEFT",
                           self.frame.WT_NoteListFrame.WT_NoteListFrameOpt,
                           "TOPLEFT", 107, -35)
    renameNoteBtn.Bg:SetVertexColor(0, 0, 0, 1)
    renameNoteBtn:SetScript("OnClick", function(self)
        -- 首先检查是否有选中的笔记
        if not WT_Notes.selectedNote or WT_Notes.selectedNote.name ==
            "笔记名称: " then
            local msg = "没有选中的笔记，无法重命名。"
            WT_Notes:AlertWarn(msg)
            return
        end

        -- 定义重命名笔记的对话框
        StaticPopupDialogs["WT_NOTES_RENAME_NOTE_CONFIRM_POPUP"] = {
            text = "输入笔记的新名称：",
            button1 = "确定",
            button2 = "取消",
            hasEditBox = true, -- 指定存在一个输入框
            editBoxWidth = 200, -- 输入框的宽度，根据需要调整
            timeout = 0,
            whileDead = 1,
            showAlert = 1,
            exclusive = 1,
            hideOnEscape = 1,
            OnAccept = function(self)
                local newNoteName = self.editBox:GetText(); -- 获取输入框中的文本
                if newNoteName and newNoteName ~= "" then
                    StaticPopup_Hide("WT_NOTES_RENAME_NOTE_CONFIRM_POPUP");
                    -- 调用重命名笔记的函数，传入笔记对象和新名称
                    WT_Notes:RenameNote(newNoteName);
                else
                    WT_Notes:AlertWarn("笔记名称不能为空!")
                end
            end,
            OnCancel = function(self)
                StaticPopup_Hide("WT_NOTES_RENAME_NOTE_CONFIRM_POPUP");
            end,
            EditBoxOnEscapePressed = function(self)
                StaticPopup_Hide("WT_NOTES_RENAME_NOTE_CONFIRM_POPUP");
            end -- 当按下Esc键时隐藏对话框
        }
        -- 显示对话框并初始化输入框的文本为当前选中笔记的名称
        StaticPopup_Show("WT_NOTES_RENAME_NOTE_CONFIRM_POPUP");
    end)

    self.frame.WT_NoteEditFrame:SetSize(800, 700)
    self.frame.WT_NoteEditFrame:SetFrameStrata("HIGH");
    self.frame.WT_NoteEditFrame:SetFrameLevel(0)
    self.frame.WT_NoteEditFrame.Bg:SetColorTexture(0, 0, 0, 0)
    self.frame.WT_NoteEditFrame.WT_NoteEditFrameTitle:SetSize(200, 30)
    self.frame.WT_NoteEditFrame.WT_NoteEditFrameTitle.Bg:SetColorTexture(tr, tg,
                                                                         tb, 1)

    self.frame.WT_NoteEditFrame.WT_NoteEditFrameBody:SetSize(800, 670)
    self.frame.WT_NoteEditFrame.WT_NoteEditFrameBody.Bg:SetColorTexture(0, 0, 0,
                                                                        WT_Notes.notebookSetting
                                                                            .noteBodyAlpha)

    -- 创建AceGUI MultiLineEditBox
    WT_Notes.Note_M_E_Body_EditBox = AceGUI:Create("MultiLineEditBox")
    WT_Notes.Note_M_E_Body_EditBox:SetHeight(670)
    WT_Notes.Note_M_E_Body_EditBox:SetWidth(800)
    WT_Notes.Note_M_E_Body_EditBox.frame.obj.editBox:SetFont(STANDARD_TEXT_FONT,
                                                             WT_Notes.notebookSetting
                                                                 .noteFontSize,
                                                             "OUTLINE")
    -- WT_Notes.Note_M_E_Body_EditBox.frame.obj.scrollBG = nil
    WT_Notes.Note_M_E_Body_EditBox.frame.obj.scrollBG:Hide()
    WT_Notes.Note_M_E_Body_EditBox.frame:SetParent(
        self.frame.WT_NoteEditFrame.WT_NoteEditFrameBody)
    WT_Notes.Note_M_E_Body_EditBox.frame:SetPoint("TOPLEFT", self.frame
                                                      .WT_NoteEditFrame
                                                      .WT_NoteEditFrameBody,
                                                  "TOPLEFT", 0, 6)
    WT_Notes.Note_M_E_Body_EditBox.frame:SetPoint("BOTTOM", self.frame
                                                      .WT_NoteEditFrame
                                                      .WT_NoteEditFrameBody,
                                                  "BOTTOM", 0, -5)

    WT_Notes.Note_M_E_Body_EditBox:DisableButton(true)
    WT_Notes.Note_M_E_Body_EditBox:SetLabel("")
    -- 为MultiLineEditBox设置OnTextChanged事件监听
    WT_Notes.Note_M_E_Body_EditBox:SetCallback("OnTextChanged", function()
        WT_Notes:SaveNoteContent()
    end)
    WT_Notes.Note_M_E_Body_EditBox.frame:Show()

    WT_Notes.selectedEditNoteTitle = self.frame.WT_NoteEditFrame
                                         .WT_NoteEditFrameTitle:CreateFontString(
                                         nil, "ARTWORK", "GameFontNormal")
    WT_Notes.selectedEditNoteTitle:SetFont(STANDARD_TEXT_FONT, 24, "OUTLINE")
    WT_Notes.selectedEditNoteTitle:SetText("笔记名称: ")
    WT_Notes.selectedEditNoteTitle:SetTextColor(1, 1, 1)
    WT_Notes.selectedEditNoteTitle:SetPoint("TOPLEFT", self.frame
                                                .WT_NoteEditFrame
                                                .WT_NoteEditFrameTitle,
                                            "TOPLEFT", 0, -5)

    self.frame.WT_NoteRightFrame:SetSize(200, 700)
    self.frame.WT_NoteRightFrame.Bg:SetColorTexture(0, 0, 0, 0)
    self.frame.WT_NoteRightFrame:SetFrameStrata("HIGH");
    self.frame.WT_NoteRightFrame:SetFrameLevel(0)
    self.frame.WT_NoteRightFrame.WT_NoteToolsFrame:SetSize(200, 350)
    self.frame.WT_NoteRightFrame.WT_NoteToolsFrame:SetFrameStrata("HIGH");
    self.frame.WT_NoteRightFrame.WT_NoteToolsFrame:SetFrameLevel(0)
    self.frame.WT_NoteRightFrame.WT_NoteToolsFrame.Bg:SetColorTexture(0, 0, 0, 0)

    self.frame.WT_NoteRightFrame.WT_NoteToolsFrame.WT_NoteToolsFrameTitle:SetSize(
        200, 30)
    self.frame.WT_NoteRightFrame.WT_NoteToolsFrame.WT_NoteToolsFrameTitle.Bg:SetColorTexture(
        tr, tg, tb, 1)

    self.frame.WT_NoteRightFrame.WT_NoteToolsFrame.WT_NoteToolsFrameBody:SetSize(
        200, 320)
    self.frame.WT_NoteRightFrame.WT_NoteToolsFrame.WT_NoteToolsFrameBody.Bg:SetColorTexture(
        0, 0, 0, WT_Notes.notebookSetting.noteRightAlpha)
    -- 工具栏添加预览按钮
    local previewButton = AceGUI:Create("Button")
    previewButton:SetText("预览") -- 设置按钮文本
    previewButton:SetWidth(170) -- 设置按钮宽度
    previewButton:SetHeight(40) -- 设置按钮高度
    previewButton.frame:SetParent(self.frame.WT_NoteRightFrame.WT_NoteToolsFrame
                                      .WT_NoteToolsFrameBody)
    previewButton.frame:SetPoint("BOTTOMLEFT", self.frame.WT_NoteRightFrame
                                     .WT_NoteToolsFrame.WT_NoteToolsFrameBody,
                                 "BOTTOMLEFT", 15, 10)

    -- 创建颜色选择器控件
    local colorPicker = AceGUI:Create("ColorPicker")
    colorPicker:SetWidth(24)
    colorPicker:SetColor(0, 1, 0, 1)
    colorPicker:SetCallback("OnValueChanged", function(self, event, r, g, b, a)
        WT_Notes.CURRENT_COLOR_CODE = WT_Notes:rgbaToHex(r, g, b, a)
    end)

    local applyTextColorButton = AceGUI:Create("Button")
    applyTextColorButton:SetText("应用") -- 设置按钮文本
    applyTextColorButton:SetWidth(70) -- 设置按钮宽度
    applyTextColorButton:SetHeight(20) -- 设置按钮高度
    applyTextColorButton.frame:SetParent(
        self.frame.WT_NoteRightFrame.WT_NoteToolsFrame.WT_NoteToolsFrameBody)
    applyTextColorButton.frame:SetPoint("TOPLEFT", self.frame.WT_NoteRightFrame
                                            .WT_NoteToolsFrame
                                            .WT_NoteToolsFrameBody, "TOPLEFT",
                                        120, -7)
    applyTextColorButton.frame:Show()
    -- 设置按钮的回调函数
    applyTextColorButton:SetCallback("OnClick", function()
        WT_Notes:ApplyColorToSelectedText(
            WT_Notes.Note_M_E_Body_EditBox.frame.obj.editBox,
            WT_Notes.CURRENT_COLOR_CODE)
    end)

    WT_Notes.Note_M_E_Body_EditBox.frame.obj.editBox:SetScript(
        "OnEditFocusLost", function(...)
            local args = {...}
            for i, arg in ipairs(args) do end
        end)
    -- 在 WT_Notes:SetupUI() 或其他适当位置设置
    WT_Notes.Note_M_E_Body_EditBox.frame.obj.editBox:SetScript("OnKeyDown",
                                                               function(self,
                                                                        key)
        if WT_Notes.IsFormattingOn and key == "LALT" then
            -- 保存当前的插入位置修复值
            WT_Notes.IsFormattingOn_Saved = true
            WT_Notes.IsFormattingOn = false

            -- 获取当前编辑框的文本和高亮
            local text = self:GetText()
            local h_start, h_end = WT_Notes:GetTextHighlight(
                                       WT_Notes.Note_M_E_Body_EditBox.frame.obj
                                           .editBox)

            -- 计算高亮和光标位置的颜色代码数量
            local c_start, c_end, c_cursor = 0, 0, 0
            text:sub(1, h_start):gsub("|([cr])",
                                      function()
                c_start = c_start + 1
            end)
            text:sub(1, h_end):gsub("|([cr])", function()
                c_end = c_end + 1
            end)

            -- 替换文本中的颜色代码
            text = text:gsub("|([cr])", "||%1")
            self:SetText(text)

            -- 更新高亮和光标位置
            WT_Notes.Note_M_E_Body_EditBox.frame.obj.editBox:HighlightText(
                h_start + c_start, h_end + c_end)
            self:SetCursorPosition(WT_Notes.last_cursor_pos + c_cursor)
        end
    end)

    WT_Notes.Note_M_E_Body_EditBox.frame.obj.editBox:SetScript("OnKeyUp",
                                                               function(self,
                                                                        key)
        if WT_Notes.IsFormattingOn_Saved and key == "LALT" then
            -- 恢复格式化状态
            WT_Notes.IsFormattingOn = true
            WT_Notes.IsFormattingOn_Saved = false

            -- 同上，进行逆向操作，恢复颜色代码
            local text = self:GetText()
            local h_start, h_end = WT_Notes:GetTextHighlight(
                                       WT_Notes.Note_M_E_Body_EditBox.frame.obj
                                           .editBox)
            local c_start, c_end = 0, 0

            -- 计算额外的颜色代码数量
            text:sub(1, h_start):gsub("||([cr])",
                                      function()
                c_start = c_start + 1
            end)
            text:sub(1, h_end):gsub("||([cr])", function()
                c_end = c_end + 1
            end)

            -- 恢复颜色代码
            text = text:gsub("||([cr])", "|%1")
            self:SetText(text)

            -- 更新高亮和光标位置
            WT_Notes.Note_M_E_Body_EditBox.frame.obj.editBox:HighlightText(
                h_start - c_start, h_end - c_end)
            self:SetCursorPosition(WT_Notes.last_cursor_pos)
        end
    end)

    colorPicker:SetLabel("字体颜色: ")
    colorPicker.frame:SetParent(self.frame.WT_NoteRightFrame.WT_NoteToolsFrame
                                    .WT_NoteToolsFrameBody)
    colorPicker.frame:SetPoint("TOPLEFT", self.frame.WT_NoteRightFrame
                                   .WT_NoteToolsFrame.WT_NoteToolsFrameBody,
                               "TOPLEFT", 85, -5)
    colorPicker.text:SetJustifyH("LEFT")
    colorPicker.text:SetTextColor(1, 1, 1)
    colorPicker.text:SetPoint("TOPLEFT", self.frame.WT_NoteRightFrame
                                  .WT_NoteToolsFrame.WT_NoteToolsFrameBody,
                              "TOPLEFT", 10, -5)
    colorPicker.frame:Show()

    WT_Notes.PERVIEW_WINDOW = AceGUI:Create("Window")
    WT_Notes.PERVIEW_WINDOW:SetTitle("冒险笔记本-预览") -- 设置窗口标题
    WT_Notes.PERVIEW_WINDOW:SetStatusText("拖动右下角调整大小") -- 设置状态文本，给用户操作提示
    WT_Notes.PERVIEW_WINDOW:SetWidth(300) -- 设置窗口初始宽度
    WT_Notes.PERVIEW_WINDOW:SetHeight(400) -- 设置窗口初始高度
    WT_Notes.PERVIEW_WINDOW:SetCallback("OnClose", function(widget)
        WT_Notes.PERVIEW_WINDOW_TEXT:SetText("")
        WT_Notes.PERVIEW_WINDOW:Hide()
    end)

    -- 创建一个Label组件
    WT_Notes.PERVIEW_WINDOW_TEXT = AceGUI:Create("Label")
    WT_Notes.PERVIEW_WINDOW_TEXT:SetText("这是需要显示的文本。") -- 设置文本
    WT_Notes.PERVIEW_WINDOW_TEXT:SetHeight(20) -- 设置高度，根据需要调整
    WT_Notes.PERVIEW_WINDOW_TEXT:SetWidth(200) -- 设置宽度，根据需要调整
    WT_Notes.PERVIEW_WINDOW_TEXT:SetFullWidth(true) -- 让Label宽度充满其父容器的宽度

    -- 将Label添加到AceGUI容器中
    WT_Notes.PERVIEW_WINDOW:AddChild(WT_Notes.PERVIEW_WINDOW_TEXT)

    -- 可选：设置文本对齐方式
    WT_Notes.PERVIEW_WINDOW_TEXT:SetJustifyH("LEFT") -- 左对齐
    WT_Notes.PERVIEW_WINDOW_TEXT.frame:SetHyperlinksEnabled(true)
    -- 注册 OnHyperlinkEnter 事件
    WT_Notes.PERVIEW_WINDOW_TEXT.frame:SetScript("OnHyperlinkEnter", function(
        self, hyperlink) OnHyperlinkEnterHandle(hyperlink) end)

    -- 注册 OnHyperlinkLeave 事件
    WT_Notes.PERVIEW_WINDOW_TEXT.frame:SetScript("OnHyperlinkLeave", function(
        self) OnHyperlinkLeaveHandle(self) end)

    -- 注册 OnHyperlinkLeave 事件
    WT_Notes.PERVIEW_WINDOW_TEXT.frame:SetScript("OnHyperlinkClick", function(
        self, hyperlink) OnHyperlinkClickHandle(hyperlink) end)

    -- 设置按钮的回调函数
    previewButton:SetCallback("OnClick", function()
        if (#WT_Notes.notes < 1) then
            WT_Notes:AlertWarn("没有笔记可以预览!")
            return
        end

        WT_Notes.PERVIEW_WINDOW_TEXT:SetText(WT_Notes.selectedNote.content)
        -- GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        -- GameTooltip:SetHyperlink("|cff71d5ff|Hspell:2061:0|h[快速治疗]|h|r")
        -- GameTooltip:Show()
        WT_Notes.PERVIEW_WINDOW:Show()
    end)
    WT_Notes.PERVIEW_WINDOW:Hide()
    previewButton.frame:Show()

    local toolsTitleText = self.frame.WT_NoteRightFrame.WT_NoteToolsFrame
                               .WT_NoteToolsFrameTitle:CreateFontString(nil,
                                                                        "ARTWORK",
                                                                        "GameFontNormal")
    toolsTitleText:SetFont(STANDARD_TEXT_FONT, 24, "OUTLINE")
    toolsTitleText:SetText("工具栏")
    toolsTitleText:SetTextColor(1, 1, 1)
    toolsTitleText:SetPoint("TOPLEFT", self.frame.WT_NoteRightFrame
                                .WT_NoteToolsFrame.WT_NoteToolsFrameTitle,
                            "TOPLEFT", 0, -5)

    self.frame.WT_NoteRightFrame.WT_NoteSettingFrame:SetSize(200, 350)
    self.frame.WT_NoteRightFrame.WT_NoteSettingFrame:SetFrameStrata("HIGH");
    self.frame.WT_NoteRightFrame.WT_NoteSettingFrame:SetFrameLevel(0)
    self.frame.WT_NoteRightFrame.WT_NoteSettingFrame.Bg:SetColorTexture(0, 0, 0,
                                                                        WT_Notes.notebookSetting
                                                                            .noteRightAlpha)

    self.frame.WT_NoteRightFrame.WT_NoteSettingFrame.WT_NoteSettingFrameTitle:SetSize(
        200, 30)
    self.frame.WT_NoteRightFrame.WT_NoteSettingFrame.WT_NoteSettingFrameTitle.Bg:SetColorTexture(
        tr, tg, tb, 1)
    local settingTitleText = self.frame.WT_NoteRightFrame.WT_NoteSettingFrame
                                 .WT_NoteSettingFrameTitle:CreateFontString(nil,
                                                                            "ARTWORK",
                                                                            "GameFontNormal")
    settingTitleText:SetFont(STANDARD_TEXT_FONT, 24, "OUTLINE")
    settingTitleText:SetText("设置区")
    settingTitleText:SetTextColor(1, 1, 1)
    settingTitleText:SetPoint("TOPLEFT", self.frame.WT_NoteRightFrame
                                  .WT_NoteSettingFrame.WT_NoteSettingFrameTitle,
                              "TOPLEFT", 0, -5)
    self.frame.WT_NoteRightFrame.WT_NoteSettingFrame.WT_NoteSettingFrameBody:SetSize(
        200, 320)
    self.frame.WT_NoteRightFrame.WT_NoteSettingFrame.WT_NoteSettingFrameBody.Bg:SetColorTexture(
        0, 0, 0, 0)

    -- 使用 AceGUI 创建一个复选框
    WT_Notes.Note_M_S_Body_pinCheckbox = AceGUI:Create("CheckBox")
    WT_Notes.Note_M_S_Body_pinCheckbox:SetLabel("在界面上显示该笔记") -- 设置复选框旁边显示的文本
    WT_Notes.Note_M_S_Body_pinCheckbox:SetDisabled(#WT_Notes.notes < 1)
    WT_Notes.Note_M_S_Body_pinCheckbox:SetCallback("OnValueChanged",
                                                   function(self)
        if self.checked == true then
            -- 显示笔记面板
            -- 同步状态
            WT_Notes.selectedNote.settings.pin = true
            ShowPinWindow(WT_Notes.selectedNote)
        elseif self.checked == false then
            WT_Notes.selectedNote.settings.pin = false
            HidePinWindow(WT_Notes.selectedNote)
        end

    end) -- 设置值变化时的回调函数

    WT_Notes.Note_M_S_Body_pinCheckbox.frame:SetParent(self.frame
                                                           .WT_NoteRightFrame
                                                           .WT_NoteSettingFrame
                                                           .WT_NoteSettingFrameBody)
    WT_Notes.Note_M_S_Body_pinCheckbox.frame:SetPoint("TOPLEFT", self.frame
                                                          .WT_NoteRightFrame
                                                          .WT_NoteSettingFrame
                                                          .WT_NoteSettingFrameBody,
                                                      "TOPLEFT", 10, -5)
    WT_Notes.Note_M_S_Body_pinCheckbox.frame:Show()

    -- 工具栏添加预览按钮
    local importNoteButton = AceGUI:Create("Button")
    importNoteButton:SetText("导入") -- 设置按钮文本
    importNoteButton:SetWidth(85) -- 设置按钮宽度
    importNoteButton:SetHeight(20) -- 设置按钮高度
    importNoteButton.frame:SetParent(self.frame.WT_NoteRightFrame
                                         .WT_NoteSettingFrame
                                         .WT_NoteSettingFrameBody)
    importNoteButton.frame:SetPoint("TOPLEFT", self.frame.WT_NoteRightFrame
                                        .WT_NoteSettingFrame
                                        .WT_NoteSettingFrameBody, "TOPLEFT", 10,
                                    -40)
    -- 设置按钮的回调函数
    importNoteButton:SetCallback("OnClick",
                                 function() WT_Notes:ShowImportDialog() end)
    importNoteButton.frame:Show()

    -- 工具栏添加预览按钮
    local exportNoteButton = AceGUI:Create("Button")
    exportNoteButton:SetText("导出") -- 设置按钮文本
    exportNoteButton:SetWidth(85) -- 设置按钮宽度
    exportNoteButton:SetHeight(20) -- 设置按钮高度
    exportNoteButton.frame:SetParent(self.frame.WT_NoteRightFrame
                                         .WT_NoteSettingFrame
                                         .WT_NoteSettingFrameBody)
    exportNoteButton.frame:SetPoint("TOPLEFT", self.frame.WT_NoteRightFrame
                                        .WT_NoteSettingFrame
                                        .WT_NoteSettingFrameBody, "TOPLEFT",
                                    100, -40)
    -- 设置按钮的回调函数
    exportNoteButton:SetCallback("OnClick", function()
        if (#WT_Notes.notes < 1) then
            WT_Notes:AlertWarn("没有笔记可以导出!")
            return
        end
        if WT_Notes.selectedNote == nil then
            WT_Notes:AlertWarn("请选择一篇笔记导出!")
            return
        else
            if WT_Notes.selectedNote.content == nil or
                WT_Notes.selectedNote.content == "" then
                WT_Notes:AlertWarn("导出笔记内容不能为空!")
                return
            end
        end
        local base64content = Base64:Encode(WT_Notes.selectedNote.content)
        local base64name = Base64:Encode(WT_Notes.selectedNote.name)
        local exportStr = base64name .. "@@@@@@" .. base64content
        WT_Notes:ShowExportDialog(exportStr)
    end)
    exportNoteButton.frame:Show()

    -- 工具栏添加预览按钮
    local syncNoteButton = AceGUI:Create("Button")
    syncNoteButton:SetText("同步到其它人") -- 设置按钮文本
    syncNoteButton:SetWidth(175) -- 设置按钮宽度
    syncNoteButton:SetHeight(30) -- 设置按钮高度
    syncNoteButton.frame:SetParent(self.frame.WT_NoteRightFrame
                                       .WT_NoteSettingFrame
                                       .WT_NoteSettingFrameBody)
    syncNoteButton.frame:SetPoint("TOPLEFT", self.frame.WT_NoteRightFrame
                                      .WT_NoteSettingFrame
                                      .WT_NoteSettingFrameBody, "TOPLEFT", 10,
                                  -70)
    -- 设置按钮的回调函数
    syncNoteButton:SetCallback("OnClick", function()
        if (#WT_Notes.notes < 1) then
            WT_Notes:AlertWarn("没有笔记可以导出!")
            return
        end
        WT_Notes:SyncNoteToOthers()
    end)
    syncNoteButton.frame:Show()

    -- 工具栏添加预览按钮
    local sendNoteButton = AceGUI:Create("Button")
    sendNoteButton:SetText("发送到") -- 设置按钮文本
    sendNoteButton:SetWidth(85) -- 设置按钮宽度
    sendNoteButton:SetHeight(20) -- 设置按钮高度
    sendNoteButton.frame:SetParent(self.frame.WT_NoteRightFrame
                                       .WT_NoteSettingFrame
                                       .WT_NoteSettingFrameBody)
    sendNoteButton.frame:SetPoint("TOPLEFT", self.frame.WT_NoteRightFrame
                                      .WT_NoteSettingFrame
                                      .WT_NoteSettingFrameBody, "TOPLEFT", 10,
                                  -110)
    -- 设置按钮的回调函数
    sendNoteButton:SetCallback("OnClick", function()
        if (#WT_Notes.notes < 1) then
            WT_Notes:AlertWarn("没有笔记可以导出!")
            return
        end
        -- 获取笔记内容并分割成多行
        local noteContent = self.selectedNote.content
        local lines = {string.split("\n", noteContent)}
        for _, line in ipairs(lines) do
            -- 替换匹配到的颜色代码为空字符串
            local newLine = removeColorCodes(line)
            SendChatMessage(newLine, WT_Notes.Note_M_S_Body_sendChannel)
        end
    end)
    sendNoteButton.frame:Show()

    -- 创建 Dropdown 控件
    local sendChannelDropdown = AceGUI:Create("Dropdown")
    sendChannelDropdown:SetWidth(85) -- 设置 Dropdown 宽度
    sendChannelDropdown:SetLabel(nil) -- 设置 Dropdown 旁边显示的文本标签
    local options = {
        ["SAY"] = "说",
        ["YELL"] = "大喊",
        ["PARTY"] = "小队",
        ["RAID"] = "团队",
        ["INSTANCE_CHAT"] = "副本",
        ["GUILD"] = "工会"
    }
    -- 设置选项和回调函数
    sendChannelDropdown:SetList(options)
    sendChannelDropdown:SetValue("PARTY")
    sendChannelDropdown:SetCallback("OnValueChanged", function(value)
        WT_Notes.Note_M_S_Body_sendChannel = value.value
    end)
    sendChannelDropdown.frame:SetParent(self.frame.WT_NoteRightFrame
                                            .WT_NoteSettingFrame
                                            .WT_NoteSettingFrameBody)
    sendChannelDropdown.frame:SetPoint("TOPLEFT", sendNoteButton.frame,
                                       "TOPRIGHT", 5, 3.5)
    sendChannelDropdown.frame:Show()
    -- 创建自定义关闭按钮
    self.frame.CloseButton:SetSize(32, 32)
    self.frame.CloseButton:SetNormalTexture(
        "Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    self.frame.CloseButton:SetPushedTexture(
        "Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    self.frame.CloseButton:SetHighlightTexture(
        "Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    -- 注册关闭按钮点击事件
    self.frame.CloseButton:SetScript("OnClick", function() self.frame:Hide() end)

    self.frame:EnableMouse(true)
    self.frame:SetMovable(true)
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    self.frame:SetScript("OnDragStop",
                         function(self) self:StopMovingOrSizing() end)

    WT_Notes.Note_M_Frame = self.frame
    WT_Notes.Note_M_L_Body_Frame = self.Note_M_Frame.WT_NoteListFrame
                                       .WT_NoteListFrameBody
    WT_Notes.Note_M_E_Body_Frame = self.Note_M_Frame.WT_NoteEditFrame
                                       .WT_NoteEditFrameBody

    WT_Notes.Note_M_T_Body_Frame = self.Note_M_Frame.WT_NoteRightFrame
                                       .WT_NoteToolsFrame.WT_NoteToolsFrameBody
    WT_Notes.Note_M_S_Body_Frame = self.Note_M_Frame.WT_NoteRightFrame
                                       .WT_NoteSettingFrame
                                       .WT_NoteSettingFrameBody
    WT_Notes.Note_M_Frame:Hide()
end

function WT_Notes:OnAddonMessageReceived(prefix, message, distribution, sender)

    if prefix == nil or prefix ~= "WT_Notes" then return end
    local username = UnitName("player")
    if sender == username then return end

    print("接收到" .. sender .. "发送的笔记。")
    -- 检查是否是我们的同步消息
    local noteName, noteContent = message:match("(.-)@@@@@@(.+)")
    if noteName and noteContent then
        noteName = Base64:Decode(string.gsub(noteName, "WT_Notes:", ""))
        noteContent = Base64:Decode(noteContent)
        if WT_Notes:CheckNoteNameExist(noteName) then
            noteName = noteName .. "_" .. generateRandomString(8)
        end
        -- 创建新的笔记条目
        local newNote = {
            name = noteName,
            index = #WT_Notes.notes + 1,
            content = noteContent, -- 新建笔记初始内容为空
            settings = {pin = false},
            _NOTE_ROW = nil,
            _NOTE_ROW_TEXT = nil,
            _NOTE_PIN_WINDOWN = nil,
            _NOTE_PIN_WINDOWN_TEXT = nil
        }
        table.insert(WT_Notes.notes, newNote) -- 将新笔记添加到笔记列表
        -- 创建笔记行并添加到UI中
        local createdNote = CreateNoteRow(newNote)
        WT_Notes.selectedNote = createdNote
        -- 选中新创建的笔记
        WT_Notes:SelectNote();
    end
end

-- 初始化函数
function WT_Notes:OnInitialize()
    print('WT_Notes 初始化执行')
    -- 注册数据库, 这里的名字和toc文件的名字一致
    self.db = AceDB:New("WT_NotesDB")
    self.db:RegisterDefaults({profile = {notes = {}}})

    -- 开启了插件这里才不会=nil
    if self.parent then
        WT_Notes.notebookSetting = self.parent:GetProfileSetting(
                                       "notebookSetting")
        -- 因为不会写滚动条,所以最多支持30篇笔记
        WT_Notes.notes = self.db.profile.notes
        -- 渲染笔记UI框架
        self:SetupUI()
        -- 渲染笔记列表
        for index, note in pairs(WT_Notes.notes) do
            local noteRow = CreateNoteRow(note)
        end
        if #self.notes > 0 then
            self.selectedNote = WT_Notes.notes[1]
            WT_Notes:SelectNote()
        else
            WT_Notes:UpdateNoteAll()
        end
        self:RegisterComm("WT_Notes", "OnAddonMessageReceived")
    end
end

function WT_Notes:WT_NoteCommand(cmd)
    cmd = string.lower(cmd)
    if cmd == "open" then
        WT_Notes:ToggleNoteMainPanel(true)
    elseif cmd == "close" then
        WT_Notes:ToggleNoteMainPanel(false)
    elseif cmd == "toggle" then
        if WT_Notes.Note_M_Frame:IsVisible() then
            WT_Notes:ToggleNoteMainPanel(false)
        else
            WT_Notes:ToggleNoteMainPanel(true)
        end
    else
        WT_Notes:ToggleNoteMainPanel(true)
    end
end

-- 启用函数
function WT_Notes:OnEnable() self:RegisterChatCommand("note", "WT_NoteCommand") end
