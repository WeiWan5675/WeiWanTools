local WT_Features = LibStub("AceAddon-3.0"):NewAddon("WT_Features",
                                                     "AceEvent-3.0")

-- 获取当前职业的颜色
local classColor = C_ClassColor.GetClassColor(select(2, UnitClass("player")))
-- 使用职业颜色来设置文本颜色（以聊天窗口为例）
local classColorCode = string.format("%02x%02x%02x",
                                     math.floor(classColor.r * 255),
                                     math.floor(classColor.g * 255),
                                     math.floor(classColor.b * 255))

function WT_Features:AutoFoldQuestBar(event, isLogin, isReloadUI)
    if not isLogin and not isReloadUI then
        local autoFoldQuestBar = self.parent:GetProfileSetting(
                                     "autoFoldQuestBar")
        local isPartyEnabled = autoFoldQuestBar.autoFoldQuestBarParty
        local isRaidEnabled = autoFoldQuestBar.autoFoldQuestBarRaid
        local isPVPEnabled = autoFoldQuestBar.autoFoldQuestBarPVP
        if autoFoldQuestBar.enabled then
            local _, instanceType = GetInstanceInfo()
            if instanceType == "party" and isPartyEnabled then
                ObjectiveTracker_Collapse()
                return
            elseif instanceType == "raid" and isRaidEnabled then
                ObjectiveTracker_Collapse()
                return
            elseif instanceType == "pvp" and isPVPEnabled then
                ObjectiveTracker_Collapse()
                return
            end
            ObjectiveTracker_Expand()
        else
            ObjectiveTracker_Expand()
        end
    end
end

function WT_Features:AutoSettingGame(event, isLogin, isReloadUI)

    if (isLogin) then
        local autoGameSetting = self.parent:GetProfileSetting("autoSetting")
        if autoGameSetting.enabled and autoGameSetting.autoCloseBattleText then
            -- 自动设置战斗文字关闭
            SetCVar("floatingCombatTextCombatDamage", 0)
            SetCVar("floatingCombatTextCombatHealing", 0)
            print(string.format("|cff%s%s|r", classColorCode,
                                "WeiWanTools: 关闭游戏浮动战斗文字！"))
        end
    end
end

function WT_Features:PLAYER_ENTERING_WORLD(event, isLogin, isReloadUI)

    -- 进出副本自动折叠任务栏
    WT_Features:AutoFoldQuestBar(event, isLogin, isReloadUI)

    WT_Features:AutoSettingGame(event, isLogin, isReloadUI)

end

-- 定义一个函数来注册自己到父模块
function WT_Features:RegisterWithParent(parent) self.parent = parent end

function WT_Features:OnInitialize()
    -- 尝试获取父模块的配置
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function WT_Features:OnEnable() end
