local WT_Features = LibStub("AceAddon-3.0"):NewAddon("WT_Features",
                                                     "AceEvent-3.0")

local function GetClassColors()
    -- 获取当前职业的颜色
    local classColor =
        C_ClassColor.GetClassColor(select(2, UnitClass("player")))
    -- 使用职业颜色来设置文本颜色（以聊天窗口为例）
    local classColorCode = string.format("%02x%02x%02x",
                                         math.floor(classColor.r * 255),
                                         math.floor(classColor.g * 255),
                                         math.floor(classColor.b * 255))
    return classColorCode
end

function WT_Features:AutoFoldQuestBar(event, isLogin, isReloadUI)
    -- if not isLogin and not isReloadUI then
    local autoFoldQuestBar = self.parent:GetProfileSetting("autoFoldQuestBar")
    local isPartyEnabled = autoFoldQuestBar.autoFoldQuestBarParty
    local isRaidEnabled = autoFoldQuestBar.autoFoldQuestBarRaid
    local isPVPEnabled = autoFoldQuestBar.autoFoldQuestBarPVP

    if autoFoldQuestBar.enabled then
        local _, instanceType = GetInstanceInfo()
        if instanceType == "party" and isPartyEnabled then
            if QuestObjectiveTracker and QuestObjectiveTracker.ContentsFrame then
                if QuestObjectiveTracker.ContentsFrame:IsShown() and
                    QuestObjectiveTracker.Header and
                    QuestObjectiveTracker.Header.MinimizeButton then
                    QuestObjectiveTracker.Header.MinimizeButton:Click()
                    print(string.format("|cff%s%s|r", GetClassColors(),
                                        "WeiWanTools: 已自动收起任务列表!"))
                end
            end
            return
        elseif instanceType == "raid" and isRaidEnabled then
            if QuestObjectiveTracker and QuestObjectiveTracker.ContentsFrame then
                if QuestObjectiveTracker.ContentsFrame:IsShown() and
                    QuestObjectiveTracker.Header and
                    QuestObjectiveTracker.Header.MinimizeButton then
                    QuestObjectiveTracker.Header.MinimizeButton:Click()
                    print(string.format("|cff%s%s|r", GetClassColors(),
                                        "WeiWanTools: 已自动收起任务列表!"))
                end
            end
            return
        elseif instanceType == "pvp" and isPVPEnabled then
            if QuestObjectiveTracker and QuestObjectiveTracker.ContentsFrame then
                if QuestObjectiveTracker.ContentsFrame:IsShown() and
                    QuestObjectiveTracker.Header and
                    QuestObjectiveTracker.Header.MinimizeButton then
                    QuestObjectiveTracker.Header.MinimizeButton:Click()
                    print(string.format("|cff%s%s|r", GetClassColors(),
                                        "WeiWanTools: 已自动收起任务列表!"))
                end
            end
            return
        end

        if QuestObjectiveTracker and QuestObjectiveTracker.ContentsFrame then
            if not QuestObjectiveTracker.ContentsFrame:IsShown() and
                QuestObjectiveTracker.Header and
                QuestObjectiveTracker.Header.MinimizeButton then
                QuestObjectiveTracker.Header.MinimizeButton:Click()
                print(string.format("|cff%s%s|r", GetClassColors(),
                                    "WeiWanTools: 已自动展开任务列表!"))
            end
        end
    end
end

function WT_Features:NameplateAdJust(event, isLogin, isReloadUI)
    -- if not isLogin and not isReloadUI then
    local nameplateSetting = self.parent:GetProfileSetting("nameplateSetting")
    local isPartyEnabled = nameplateSetting.autoNameplateParty
    local isRaidEnabled = nameplateSetting.autoNameplateRaid
    local isPVPEnabled = nameplateSetting.autoNameplatePVP

    if nameplateSetting.enabled then
        local _, instanceType = GetInstanceInfo()
        if instanceType == "party" and isPartyEnabled then
            SetCVar("nameplateShowOnlyNames", 1)
            print(string.format("|cff%s%s|r", GetClassColors(),
                                "WeiWanTools: 已自动调整姓名板!"))
            return
        elseif instanceType == "raid" and isRaidEnabled then
            SetCVar("nameplateShowOnlyNames", 1)
            print(string.format("|cff%s%s|r", GetClassColors(),
                                "WeiWanTools: 已自动调整姓名板!"))
            return
        elseif instanceType == "pvp" and isPVPEnabled then
            SetCVar("nameplateShowOnlyNames", 1)
            print(string.format("|cff%s%s|r", GetClassColors(),
                                "WeiWanTools: 已自动调整姓名板!"))
            return
        end
        SetCVar("nameplateShowOnlyNames", 0)
    end
end
function WT_Features:AutoSettingGame(event, isLogin, isReloadUI)
    local autoGameSetting = self.parent:GetProfileSetting("autoSetting")
    if isLogin or isReloadUI then
        if autoGameSetting.enabled and autoGameSetting.autoCloseBattleText then
            -- 自动设置战斗文字关闭
            SetCVar("floatingCombatTextCombatDamage", 0)
            SetCVar("floatingCombatTextCombatHealing", 0)
            print(string.format("|cff%s%s|r", GetClassColors(),
                                "WeiWanTools: 关闭游戏浮动战斗文字！"))
        end
        if autoGameSetting.enabled and autoGameSetting.autoShowLowLevelQuest then
            -- 开启低等级任务追踪
            Settings.SetValue("PROXY_ACCOUNT_COMPLETED_QUEST_FILTERING", true)
            Settings.SetValue("PROXY_TRIVIAL_QUEST_FILTERING", true)
            print(string.format("|cff%s%s|r", GetClassColors(),
                                "WeiWanTools: 开启低等级任务追踪!"))
        end

        if autoGameSetting.enabled and autoGameSetting.minimapTrackingShowAll then
            -- 小地图开启所有追踪选项
            SetCVar("minimapTrackingShowAll", 1)
            print(string.format("|cff%s%s|r", GetClassColors(),
                                "WeiWanTools: 小地图开启所有追踪选项!"))
        end

        if autoGameSetting.enabled and autoGameSetting.showUnitNameOwn then
            -- 自动显示玩家自身名称
            SetCVar("UnitNameOwn", 1)
            print(string.format("|cff%s%s|r", GetClassColors(),
                                "WeiWanTools: 自动显示玩家自身名称!"))
        end
    end
end

function WT_Features:NameplateSetting(event, isLogin, isReloadUI)
    local nameplateSetting = self.parent:GetProfileSetting("nameplateSetting")
    if isLogin or isReloadUI then
        if nameplateSetting.enabled and nameplateSetting.nameplateShowAll then
            -- 自动启用所有姓名板
            SetCVar("nameplateShowAll", 1)
        end
        if nameplateSetting.enabled and nameplateSetting.nameplateShowEnemies then
            -- 自动开启显示敌方姓名板
            SetCVar("nameplateShowEnemies", 1)
        end
        if nameplateSetting.enabled and nameplateSetting.nameplateShowFriends then
            -- 自动开启显示友方姓名板
            SetCVar("nameplateShowFriends", 1)
        end
        print(string.format("|cff%s%s|r", GetClassColors(),
                            "WeiWanTools: 自动开启姓名板相关设置!"))
    end
end

function WT_Features:PLAYER_ENTERING_WORLD(event, isLogin, isReloadUI)

    -- 进出副本自动折叠任务栏
    WT_Features:AutoFoldQuestBar(event, isLogin, isReloadUI)
    -- 姓名板调整
    WT_Features:NameplateAdJust(event, isLogin, isReloadUI)
    -- 姓名板自动设置
    WT_Features:NameplateSetting(event, isLogin, isReloadUI)
    -- 游戏自动设置
    WT_Features:AutoSettingGame(event, isLogin, isReloadUI)
end

function WT_Features:deleteAllGeneralMacros()
    -- 定义对话框
    StaticPopupDialogs["WEIWANTOOLS_DELETE_GENERAL_MACROS_POPUP"] = {
        text = "你确定要删除所有通用宏吗?\n这将清空通用的所有的宏命令!",
        button1 = "确定",
        button2 = "取消",
        OnAccept = function()
            StaticPopup_Hide("WEIWANTOOLS_DELETE_GENERAL_MACROS_POPUP");
            -- 删除所有宏
            for i = 1, 120 do DeleteMacro(i) end
            for i = 1, 120 do DeleteMacro(i) end
            for i = 1, 120 do DeleteMacro(i) end
            for i = 1, 120 do DeleteMacro(i) end
            for i = 1, 120 do DeleteMacro(i) end
            for i = 1, 120 do DeleteMacro(i) end
        end,
        timeout = 0,
        whileDead = 1,
        showAlert = 1,
        exclusive = 1
    }

    -- 显示对话框
    StaticPopup_Show("WEIWANTOOLS_DELETE_GENERAL_MACROS_POPUP")
end

function WT_Features:deleteAllMacros()
    -- 定义对话框
    StaticPopupDialogs["WEIWANTOOLS_DELETE_ALL_MACROS_POPUP"] = {
        text = "你确定要删除所有宏吗?\n这将清空所有的宏命令(通用+角色)!",
        button1 = "确定",
        button2 = "取消",
        OnAccept = function()
            StaticPopup_Hide("WEIWANTOOLS_DELETE_ALL_MACROS_POPUP");
            -- 删除所有角色宏
            for i = 1, 138 do DeleteMacro(i) end
            for i = 1, 138 do DeleteMacro(i) end
            for i = 1, 138 do DeleteMacro(i) end
            for i = 1, 138 do DeleteMacro(i) end
            for i = 1, 138 do DeleteMacro(i) end
            for i = 1, 138 do DeleteMacro(i) end
        end,
        timeout = 0,
        whileDead = 1,
        showAlert = 1,
        exclusive = 1
    }

    -- 显示对话框
    StaticPopup_Show("WEIWANTOOLS_DELETE_ALL_MACROS_POPUP")
end
function WT_Features:deleteAllUserMacros()
    -- 定义对话框
    StaticPopupDialogs["WEIWANTOOLS_DELETE_USER_MACROS_POPUP"] = {
        text = "你确定要删除所有角色宏吗?\n这将清空角色的所有的宏命令!",
        button1 = "确定",
        button2 = "取消",
        OnAccept = function()
            StaticPopup_Hide("WEIWANTOOLS_DELETE_USER_MACROS_POPUP");
            -- 删除所有角色宏
            for i = 121, 138 do DeleteMacro(i) end
            for i = 121, 138 do DeleteMacro(i) end
            for i = 121, 138 do DeleteMacro(i) end
            for i = 121, 138 do DeleteMacro(i) end
            for i = 121, 138 do DeleteMacro(i) end
        end,
        timeout = 0,
        whileDead = 1,
        showAlert = 1,
        exclusive = 1
    }

    -- 显示对话框
    StaticPopup_Show("WEIWANTOOLS_DELETE_USER_MACROS_POPUP")
end

-- 定义一个函数来注册自己到父模块
function WT_Features:RegisterWithParent(parent) self.parent = parent end

function WT_Features:OnInitialize()
    -- 尝试获取父模块的配置
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function WT_Features:OnEnable() end
