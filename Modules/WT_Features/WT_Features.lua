local WT_Features = LibStub("AceAddon-3.0"):NewAddon("WT_Features",
                                                     "AceEvent-3.0")

function WT_Features:PLAYER_ENTERING_WORLD(event, isLogin, isReloadUI)
    -- 使用self.parent.GetProfileSetting来获取配置
    local autoFoldQuestBar = self.parent:GetProfileSetting("autoFoldQuestBar")
    local isPartyEnabled = autoFoldQuestBar.autoFoldQuestBarParty
    local isRaidEnabled = autoFoldQuestBar.autoFoldQuestBarRaid
    local isPVPEnabled = autoFoldQuestBar.autoFoldQuestBarPVP

    if autoFoldQuestBar.enabled then
        print("开启了功能")
        if not isLogin and not isReloadUI then
            print("开启了功能,isLogin", isLogin)
            print("开启了功能,isReloadUI", isReloadUI)
            local _, instanceType = GetInstanceInfo()
            print(instanceType)
            if instanceType == "party" and isPartyEnabled then
                ObjectiveTracker_Collapse()
                print("party")
                return
            elseif instanceType == "raid" and isRaidEnabled then
                ObjectiveTracker_Collapse()
                print("raid")
                return
            elseif instanceType == "pvp" and isPVPEnabled then
                ObjectiveTracker_Collapse()
                print("pvp")
                return
            end
            ObjectiveTracker_Expand()
        end
    else
        ObjectiveTracker_Expand()
    end
end

-- 定义一个函数来注册自己到父模块
function WT_Features:RegisterWithParent(parent) self.parent = parent end

function WT_Features:OnInitialize()
    -- 尝试获取父模块的配置
    print('初始化执行', self.parent)
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function WT_Features:OnEnable() end
