-- 创建你的插件实例
local WeiWanTools = LibStub("AceAddon-3.0"):NewAddon("WeiWanTools",
                                                     "AceConsole-3.0",
                                                     "AceEvent-3.0")

-- 加载第三方库
local AceGUI = LibStub('AceGUI-3.0')
local AceConfig = LibStub('AceConfig-3.0')
local AceConfigDialog = LibStub('AceConfigDialog-3.0')
local AceDB = LibStub('AceDB-3.0')
local LDB = LibStub('LibDataBroker-1.1')
local LDBI = LibStub('LibDBIcon-1.0')
WeiWanTools.WT_Features = nil
WeiWanTools.WT_Notes = nil

function WeiWanTools:WtHelpInfo()
    print("-----------WeiWanTools帮助信息-----------")
    print("/wt opt 打开设置面板")
    print("/wt note 打开冒险笔记本")
    print("/wt help 打印帮助信息")
    print("----------------------------------------")
end

function WeiWanTools:WtOpenSettings(group) AceConfigDialog:Open("WeiWanTools") end

function WeiWanTools:WtRootCommand(cmd)
    cmd = string.lower(cmd)
    if cmd == "help" then
        self:WtHelpInfo()
    elseif cmd == "opt" then
        self:WtOpenSettings()
    elseif cmd == "note" or cmd == "notes" or cmd == "-n" then
        if WeiWanTools.WT_Notes ~= nil then
            WeiWanTools.WT_Notes:ToggleNoteMainPanel(true)
        end
    else
        self:WtHelpInfo()
    end
end

function WeiWanTools:OnToggleOptionChanged(optionValue, optionName)
    -- print("optionName: ", optionName)
    -- print("optionValue: ", optionValue)
end

function WeiWanTools:ResetProfileConfirmation()
    -- 定义对话框
    StaticPopupDialogs["WEIWANTOOLS_RESET_CONFIRM_POPUP"] = {
        text = "你确定要重置 'WeiWanTools' 插件的所有设置到默认值吗？\n这将删除所有自定义设置。",
        button1 = "确定",
        button2 = "取消",
        OnAccept = function()
            StaticPopup_Hide("WEIWANTOOLS_RESET_CONFIRM_POPUP");
            WeiWanTools:ResetProfile()
            -- AceConfigDialog:SelectGroup("WeiWanTools", "generalSettingGroup")
            AceConfigDialog:ConfigTableChanged(nil, "WeiWanTools")
        end,
        timeout = 0,
        whileDead = 1,
        showAlert = 1,
        exclusive = 1
    }

    -- 显示对话框
    StaticPopup_Show("WEIWANTOOLS_RESET_CONFIRM_POPUP")
end

-- 定义配置选项
local options = {
    type = "group",
    name = "WeiWan Tools Setting",
    args = {
        generalSettingGroup = {
            type = "group",
            name = "基础",
            args = {
                generalSettingTitle = {
                    type = "header", -- 标题
                    name = "WeiWanTools基础设置"
                },
                showMiniMapIcon = {
                    type = "toggle", -- 开关
                    name = "显示小地图图标",
                    desc = "是否显示小地图图标",
                    get = function(info)
                        return WeiWanTools.db.global.showMiniMapIcon
                    end,
                    set = function(info, value)
                        WeiWanTools.db.global.showMiniMapIcon = value
                        WeiWanTools:OnToggleOptionChanged(value,
                                                          '显示小地图图标')
                    end
                }
            },
            order = 1
        },
        basicFeaturesGroup = {
            type = "group",
            name = "小功能",
            args = {
                basicFeaturesTitle = {
                    type = "header", -- 标题
                    name = "小功能设置",
                    order = 1
                },
                autoSetting = {
                    type = "toggle", -- 开关
                    name = "启用自动游戏设置",
                    desc = "启用自动游戏设置",
                    get = function(info)
                        return WeiWanTools.db.global.autoSetting.enabled
                    end,
                    set = function(info, value)
                        WeiWanTools.db.global.autoSetting.enabled = value
                        WeiWanTools:OnToggleOptionChanged(value,
                                                          '启用自动游戏设置')
                    end,
                    order = 2
                },
                nameplateSetting = {
                    type = "toggle", -- 开关
                    name = "启用姓名版增强",
                    desc = "启用姓名版增强",
                    get = function(info)
                        return WeiWanTools.db.global.nameplateSetting.enabled
                    end,
                    set = function(info, value)
                        WeiWanTools.db.global.nameplateSetting.enabled = value
                        WeiWanTools:OnToggleOptionChanged(value,
                                                          '启用姓名版增强')
                    end,
                    order = 2
                },
                autoSettingGroup = {
                    type = "group",
                    name = "自动游戏设置",
                    args = {
                        autoCloseBattleText = {
                            type = "toggle", -- 开关
                            name = "关闭浮动战斗信息",
                            desc = "关闭浮动战斗信息",
                            get = function(info)
                                return WeiWanTools.db.global.autoSetting
                                           .autoCloseBattleText
                            end,
                            set = function(info, value)
                                WeiWanTools.db.global.autoSetting
                                    .autoCloseBattleText = value
                                WeiWanTools:OnToggleOptionChanged(value,
                                                                  '地下城时自动折叠追踪栏')
                            end
                        },
                        autoShowLowLevelQuest = {
                            type = "toggle", -- 开关
                            name = "开启低等级任务追踪",
                            desc = "开启低等级任务追踪",
                            get = function(info)
                                return WeiWanTools.db.global.autoSetting
                                           .autoShowLowLevelQuest
                            end,
                            set = function(info, value)
                                WeiWanTools.db.global.autoSetting
                                    .autoShowLowLevelQuest = value
                                WeiWanTools:OnToggleOptionChanged(value,
                                                                  '开启低等级任务追踪')
                            end
                        },
                        minimapTrackingShowAll = {
                            type = "toggle", -- 开关
                            name = "小地图开启所有追踪选项",
                            desc = "小地图开启所有追踪选项",
                            get = function(info)
                                return WeiWanTools.db.global.autoSetting
                                           .minimapTrackingShowAll
                            end,
                            set = function(info, value)
                                WeiWanTools.db.global.autoSetting
                                    .minimapTrackingShowAll = value
                                WeiWanTools:OnToggleOptionChanged(value,
                                                                  '小地图开启所有追踪选项')
                            end
                        },
                        showUnitNameOwn = {
                            type = "toggle", -- 开关
                            name = "自动显示玩家自身名称",
                            desc = "自动显示玩家自身名称",
                            get = function(info)
                                return WeiWanTools.db.global.autoSetting
                                           .showUnitNameOwn
                            end,
                            set = function(info, value)
                                WeiWanTools.db.global.autoSetting
                                    .showUnitNameOwn = value
                                WeiWanTools:OnToggleOptionChanged(value,
                                                                  '自动显示玩家自身名称')
                            end
                        }
                    }
                },
                nameplateSettingGroup = {
                    type = "group",
                    name = "姓名版增强",
                    args = {
                        basicNameplateSettingTitle = {
                            type = "header", -- 标题
                            name = "自动开启姓名版",
                            order = 1
                        },
                        nameplateShowAll = {
                            type = "toggle", -- 开关
                            name = "自动启用所有姓名版",
                            desc = "自动启用所有姓名版",
                            get = function(info)
                                return WeiWanTools.db.global.nameplateSetting
                                           .nameplateShowAll
                            end,
                            set = function(info, value)
                                WeiWanTools.db.global.nameplateSetting
                                    .nameplateShowAll = value
                                WeiWanTools:OnToggleOptionChanged(value,
                                                                  '自动启用所有姓名版')
                            end,
                            order = 2
                        },
                        nameplateShowEnemies = {
                            type = "toggle", -- 开关
                            name = "自动显示敌方姓名板",
                            desc = "自动显示敌方姓名板",
                            get = function(info)
                                return WeiWanTools.db.global.nameplateSetting
                                           .nameplateShowEnemies
                            end,
                            set = function(info, value)
                                WeiWanTools.db.global.nameplateSetting
                                    .nameplateShowEnemies = value
                                WeiWanTools:OnToggleOptionChanged(value,
                                                                  '自动显示敌方姓名板')
                            end,
                            order = 3
                        },
                        nameplateShowFriends = {
                            type = "toggle", -- 开关
                            name = "自动显示友方姓名板",
                            desc = "自动显示友方姓名板",
                            get = function(info)
                                return WeiWanTools.db.global.nameplateSetting
                                           .nameplateShowFriends
                            end,
                            set = function(info, value)
                                WeiWanTools.db.global.nameplateSetting
                                    .nameplateShowFriends = value
                                WeiWanTools:OnToggleOptionChanged(value,
                                                                  '自动显示友方姓名板')
                            end,
                            order = 4
                        },
                        fubenNameplateSettingTitle = {
                            type = "header", -- 标题
                            name = "自动调整姓名版",
                            order = 5
                        },
                        autoNameplatePVP = {
                            type = "toggle", -- 开关
                            name = "PVP自动调整姓名版",
                            desc = "PVP自动调整姓名版",
                            get = function(info)
                                return WeiWanTools.db.global.nameplateSetting
                                           .autoNameplatePVP
                            end,
                            set = function(info, value)
                                WeiWanTools.db.global.nameplateSetting
                                    .autoNameplatePVP = value
                                WeiWanTools:OnToggleOptionChanged(value,
                                                                  'PVP自动调整姓名版')
                            end,
                            order = 6
                        },
                        autoNameplateParty = {
                            type = "toggle", -- 开关
                            name = "地下城自动调整姓名版",
                            desc = "地下城自动调整姓名版",
                            get = function(info)
                                return WeiWanTools.db.global.nameplateSetting
                                           .autoNameplateParty
                            end,
                            set = function(info, value)
                                WeiWanTools.db.global.nameplateSetting
                                    .autoNameplateParty = value
                                WeiWanTools:OnToggleOptionChanged(value,
                                                                  '地下城自动调整姓名版')
                            end,
                            order = 7
                        },
                        autoNameplateRaid = {
                            type = "toggle", -- 开关
                            name = "团队副本自动调整姓名版",
                            desc = "团队副本自动调整姓名版",
                            get = function(info)
                                return WeiWanTools.db.global.nameplateSetting
                                           .autoNameplateRaid
                            end,
                            set = function(info, value)
                                WeiWanTools.db.global.nameplateSetting
                                    .autoNameplateRaid = value
                                WeiWanTools:OnToggleOptionChanged(value,
                                                                  '团队副本自动调整姓名版')
                            end,
                            order = 8
                        }
                    }
                },
                autoFoldQuestBar = {
                    type = "toggle", -- 开关
                    name = "启用自动折叠追踪栏",
                    desc = "启用自动折叠追踪栏",
                    get = function(info)
                        return WeiWanTools.db.global.autoFoldQuestBar.enabled
                    end,
                    set = function(info, value)
                        WeiWanTools.db.global.autoFoldQuestBar.enabled = value
                        WeiWanTools:OnToggleOptionChanged(value,
                                                          '启用自动折叠追踪栏')
                    end,
                    order = 2
                },
                autoFoldQuestBarGroup = {
                    type = "group",
                    name = "自动折叠追踪栏",
                    args = {
                        basicFeaturesTitle = {
                            type = "header", -- 标题
                            name = "在以下场景中自动折叠",
                            order = 1
                        },
                        autoFoldQuestBarParty = {
                            type = "toggle", -- 开关
                            name = "地下城",
                            desc = "地下城时自动折叠追踪栏",
                            get = function(info)
                                return WeiWanTools.db.global.autoFoldQuestBar
                                           .autoFoldQuestBarParty
                            end,
                            set = function(info, value)
                                WeiWanTools.db.global.autoFoldQuestBar
                                    .autoFoldQuestBarParty = value
                                WeiWanTools:OnToggleOptionChanged(value,
                                                                  '地下城时自动折叠追踪栏')
                            end
                        },
                        autoFoldQuestBarRaid = {
                            type = "toggle", -- 开关
                            name = "团队副本",
                            desc = "团队副本时自动折叠追踪栏",
                            get = function(info)
                                return WeiWanTools.db.global.autoFoldQuestBar
                                           .autoFoldQuestBarRaid
                            end,
                            set = function(info, value)
                                WeiWanTools.db.global.autoFoldQuestBar
                                    .autoFoldQuestBarRaid = value
                                WeiWanTools:OnToggleOptionChanged(value,
                                                                  '团队副本时自动折叠追踪栏')
                            end
                        },
                        autoFoldQuestBarPVP = {
                            type = "toggle", -- 开关
                            name = "PVP",
                            desc = "PVP时自动折叠追踪栏",
                            get = function(info)
                                return WeiWanTools.db.global.autoFoldQuestBar
                                           .autoFoldQuestBarPVP
                            end,
                            set = function(info, value)
                                WeiWanTools.db.global.autoFoldQuestBar
                                    .autoFoldQuestBarPVP = value
                                WeiWanTools:OnToggleOptionChanged(value,
                                                                  'PVP时自动折叠追踪栏')
                            end
                        }
                    }
                },
                quickOperation = {
                    type = "group",
                    name = "常用快捷操作",
                    args = {
                        basicFeaturesTitle = {
                            type = "header", -- 标题
                            name = "宏命令快速操作",
                            order = 1
                        },
                        deleteAllGeneralMacros = {
                            type = "execute",
                            name = "删除所有通用宏",
                            desc = "点击删除所有通用宏!",
                            func = function()
                                WeiWanTools.WT_Features:deleteAllGeneralMacros()
                            end,
                            dialogControl = "Button"
                        },
                        deleteAllUserMacros = {
                            type = "execute",
                            name = "删除所有角色宏",
                            desc = "点击删除所有角色宏!",
                            func = function()
                                WeiWanTools.WT_Features:deleteAllUserMacros()
                            end,
                            dialogControl = "Button"
                        },
                        deleteAllMacros = {
                            type = "execute",
                            name = "删除所有宏(通用+角色)",
                            desc = "点击删除所有角色宏!",
                            func = function()
                                WeiWanTools.WT_Features:deleteAllMacros()
                            end,
                            dialogControl = "Button"
                        }
                    }
                }
            },
            order = 3
        },
        notebookGroup = {
            type = "group",
            name = "冒险笔记本",
            args = {
                notebookSettingTitle = {
                    type = "header", -- 标题
                    name = "基础设置",
                    order = 1
                },
                notebookSetting = {
                    type = "toggle", -- 开关
                    name = "启用冒险笔记本",
                    desc = "启用冒险笔记本",
                    get = function(info)
                        return WeiWanTools.db.global.notebookSetting.enabled
                    end,
                    set = function(info, value)
                        WeiWanTools.db.global.notebookSetting.enabled = value
                        WeiWanTools:OnToggleOptionChanged(value,
                                                          '启用自动折叠追踪栏')
                    end,
                    order = 2
                },
                notebookSettingGroup = {
                    type = "group",
                    name = "基础设置",
                    args = {
                        noteBasicTitle = {
                            type = "header", -- 标题
                            name = "外观设置",
                            order = 0
                        },
                        noteFontSize = {
                            type = "range", -- 或者使用 "input"
                            name = "编辑器字体大小",
                            desc = "设置编辑器笔记字体的大小",
                            min = 12, -- 最小值
                            max = 48, -- 最大值
                            step = 1, -- 步长
                            get = function(info)
                                return WeiWanTools.db.global.notebookSetting
                                           .noteFontSize
                            end,
                            set = function(info, value)
                                WeiWanTools.db.global.notebookSetting
                                    .noteFontSize = value
                                WeiWanTools:OnToggleOptionChanged(value,
                                                                  '编辑器字体大小')
                            end,
                            order = 1
                        },
                        noteListAlpha = {
                            name = "左侧列表透明度",
                            type = "range", -- 或者使用 "input"
                            desc = "调整笔记软件左侧列表区域的透明度",
                            min = 0, -- 最小值
                            max = 1, -- 最大值
                            step = 0.1, -- 步长
                            get = function(info)
                                return WeiWanTools.db.global.notebookSetting
                                           .noteListAlpha
                            end,
                            set = function(info, value)
                                WeiWanTools.db.global.notebookSetting
                                    .noteListAlpha = value
                                WeiWanTools:OnToggleOptionChanged(
                                    WeiWanTools.db.global.notebookSetting
                                        .noteListAlpha, '左侧列表透明度')
                            end,
                            order = 2
                        },
                        noteBodyAlpha = {
                            name = "编辑器透明度",
                            type = "range", -- 或者使用 "input"
                            desc = "调整笔记软件中间部位编辑器的透明度",
                            min = 0, -- 最小值
                            max = 1, -- 最大值
                            step = 0.1, -- 步长
                            get = function(info)
                                return WeiWanTools.db.global.notebookSetting
                                           .noteBodyAlpha
                            end,
                            set = function(info, value)
                                WeiWanTools.db.global.notebookSetting
                                    .noteBodyAlpha = value
                                WeiWanTools:OnToggleOptionChanged(
                                    WeiWanTools.db.global.notebookSetting
                                        .noteBodyAlpha, '编辑器透明度')
                            end,
                            order = 3
                        },
                        noteRightAlpha = {
                            name = "右侧面板透明度",
                            type = "range", -- 或者使用 "input"
                            desc = "调整笔记软件右侧面板透明度",
                            min = 0, -- 最小值
                            max = 1, -- 最大值
                            step = 0.1, -- 步长
                            get = function(info)
                                return WeiWanTools.db.global.notebookSetting
                                           .noteRightAlpha
                            end,
                            set = function(info, value)
                                WeiWanTools.db.global.notebookSetting
                                    .noteRightAlpha = value
                                WeiWanTools:OnToggleOptionChanged(
                                    WeiWanTools.db.global.notebookSetting
                                        .noteRightAlpha, '右侧面板透明度')
                            end,
                            order = 4
                        },
                        noteBasicColorTitle = {
                            type = "header", -- 标题
                            name = "颜色设置",
                            order = 5
                        },
                        noteThemeColor = {
                            type = "color",
                            name = "笔记本主题颜色",
                            desc = "选择一个颜色。",
                            get = function(info)
                                hex = tostring(
                                          WeiWanTools.db.global.notebookSetting
                                              .noteThemeColor)
                                -- 去除可能存在的井号前缀（#）
                                if string.sub(hex, 1, 1) == "#" then
                                    hex = string.sub(hex, 2)
                                end

                                -- 验证十六进制颜色代码是否是有效的6个字符长度
                                if #hex ~= 6 then
                                    error("Invalid hex color code")
                                end

                                -- 从十六进制颜色代码中提取RGB分量
                                local r =
                                    tonumber("0x" .. string.sub(hex, 1, 2)) /
                                        255
                                local g =
                                    tonumber("0x" .. string.sub(hex, 3, 4)) /
                                        255
                                local b =
                                    tonumber("0x" .. string.sub(hex, 5, 6)) /
                                        255

                                return r, g, b
                            end,
                            hasAlpha = false,
                            set = function(info, r, g, b)
                                local colorStr =
                                    string.format("%02x%02x%02x", r * 255,
                                                  g * 255, b * 255)
                                WeiWanTools.db.global.notebookSetting
                                    .noteThemeColor = colorStr
                                WeiWanTools:OnToggleOptionChanged(colorStr,
                                                                  '笔记本主题颜色')
                            end,
                            order = 6
                        }
                    }
                }
            },
            order = 3
        },
        resetProfileExecute = {
            type = "execute",
            name = "重置",
            desc = "点击重置插件所有设置",
            func = function() WeiWanTools:ResetProfileConfirmation() end,
            dialogControl = "Button"
        }
    }
}

-- 插件重置配置函数
function WeiWanTools:ResetProfile()
    -- 重置数据库到默认值
    self.db:ResetProfile()
    -- 打印重置完成的信息
    self:Print("所有配置已重置为默认值。")
end

function WeiWanTools:MiniMapIconClick() WeiWanTools:WtOpenSettings() end

-- 定义一个回调函数供子模块使用
function WeiWanTools:GetProfileSetting(key) return self.db.global[key] end

-- 定义一个回调函数供子模块使用
function WeiWanTools:SetProfileSetting(key, value) self.db.global[key] = value end

function WeiWanTools:RegisterMiniMapIcon()
    local borker = LDB:NewDataObject("WeiWanTools", {
        type = 'data source',
        label = "WeiWanTools",
        icon = 'Interface\\Icons\\INV_Trinket_RevendrethRaid_02_Blue',
        OnClick = function() WeiWanTools:MiniMapIconClick() end
    })

    brokerConfig = {hide = false}
    brokerConfig.hide = not self.db.global.showMiniMapIcon
    LDBI:Register("WeiWanTools", borker, brokerConfig)
end

-- 插件初始化函数
function WeiWanTools:OnInitialize()
    -- 在AceConfig中注册配置表
    AceConfig:RegisterOptionsTable("WeiWanTools", options)
    -- 注册数据库, 这里的名字和toc文件的名字一致
    self.db = AceDB:New("WeiWanToolsDB")
    self.db:RegisterDefaults({
        global = {
            autoFoldQuestBar = {
                enabled = false,
                autoFoldQuestBarParty = true,
                autoFoldQuestBarRaid = true,
                autoFoldQuestBarPVP = true
            },
            notebookSetting = {
                enabled = false,
                noteFontSize = 18,
                noteListAlpha = 0.8,
                noteBodyAlpha = 0.6,
                noteLeftAlpha = 0.8,
                noteThemeColor = "00bd00"
            },
            showMiniMapIcon = true, -- 是否显示小地图图标
            autoSetting = {
                enabled = true,
                autoCloseBattleText = true,
                autoShowLowLevelQuest = true,
                minimapTrackingShowAll = true,
                showUnitNameOwn = true
            },
            nameplateSetting = {
                enabled = true,
                nameplateShowAll = true,
                nameplateShowEnemies = true,
                nameplateShowFriends = true,
                autoNameplateParty = true,
                autoNameplateRaid = true,
                autoNameplatePVP = true
            },
            auctions = {}
        },
        profile = {}
    })
    -- 注册到暴雪插件设置
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(
                            "WeiWanTools", "WeiWanTools")
    -- 添加小地图按钮
    WeiWanTools:RegisterMiniMapIcon()
    -- 注册子模块
    if self.db.global.notebookSetting.enabled then
        WeiWanTools.WT_Notes = LibStub("AceAddon-3.0"):GetAddon("WT_Notes")
        WeiWanTools.WT_Notes:RegisterWithParent(WeiWanTools)
    end
    WeiWanTools.WT_Features = LibStub("AceAddon-3.0"):GetAddon("WT_Features")
    WeiWanTools.WT_Features:RegisterWithParent(WeiWanTools)
end

function WeiWanTools:OnEnable()
    -- 注册命令
    self:RegisterChatCommand("wt", "WtRootCommand")
end

function WeiWanTools:OnDisable()
    -- Called when the addon is disabled
end

local instance = WeiWanTools
