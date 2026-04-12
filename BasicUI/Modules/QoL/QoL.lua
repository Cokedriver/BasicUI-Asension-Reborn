--============================================================
-- MODULE: QoL Loader
--============================================================
local addonName, BasicUI = ...
local MODULE_NAME = "QoL"
local M = {}

------------------------------------------------------------
-- Submodule Registry
------------------------------------------------------------

M.modules = {}

function BasicUI_QoL_RegisterModule(name, module)

    if type(module) == "function" then
        module = { OnEnable = module }
    end

    module.name = name
    module.core = M

    M.modules[name] = module

end

--============================================================
-- DEFAULTS
--============================================================

M.defaults = {

    enabled = true,

    enableAutomation       = true,
    enableAutoGreed        = true,
    enableAltBuy           = true,

    enableMinimap          = true,
    enableTradeSkill       = true,

    enableNotifications    = true,

    enableMapCoords        = true,
    enableWorldMapFog      = true,
    showPlayerCoords       = true,
    showCursorCoords       = true,

    enableZoneTextMove      = true,
    enableZoneTextAnimation = true,
    enableAlertMove         = true,
    enableLootMove          = true,
    enableLargeLootIcons    = true,

    enableFlashingNodes    = true,
    flashInterval          = 1.0,
}

--============================================================
-- LIFECYCLE
--============================================================

function M:OnEnable()

    if not self.db.enabled then return end

    for name, module in pairs(self.modules) do
        if module.OnEnable then
            pcall(module.OnEnable, module, self)
        end
    end

end

------------------------------------------------------------

function M:OnDisable()

    for name, module in pairs(self.modules) do
        if module.OnDisable then
            pcall(module.OnDisable, module, self)
        end
    end

end

------------------------------------------------------------
-- Live Settings Refresh
------------------------------------------------------------

function M:ApplySettings()

    if not self.db.enabled then
        self:OnDisable()
        return
    end

    for name, module in pairs(self.modules) do

        local settingKey = "enable" .. name

        if self.db[settingKey] == false then
            if module.OnDisable then
                pcall(module.OnDisable, module, self)
            end
        else
            if module.ApplySettings then
                pcall(module.ApplySettings, module, self)
            elseif module.OnEnable then
                pcall(module.OnEnable, module, self)
            end
        end

    end

end

--============================================================
-- OPTIONS
--============================================================

M.options = {
    type = "group",
    name = "Quality of Life",
    args = {

        enabled = {
            type = "toggle",
            name = "Enable QoL Features",
            desc = "Enable BasicUI quality of life improvements.",
            width = "full",
            order = 1,

            get = function() return M.db.enabled end,
            set = function(_, v)

                M.db.enabled = v
                BasicUI:RefreshModule(M)

            end,
        },

        ------------------------------------------------
        -- Automation
        ------------------------------------------------

        automation = {
            type = "group",
            name = "Automation",
            inline = true,
            order = 2,

            args = {

                enableAutomation = {
                    type = "toggle",
                    name = "Enable Automation",
                    desc = "Automatically handle certain repetitive interactions such as gossip and quest dialogs.",
                    order = 1,

                    get = function() return M.db.enableAutomation end,
                    set = function(_, v)
                        M.db.enableAutomation = v
                        BasicUI:RefreshModule(M)
                    end,
                },

                enableAutoGreed = {
                    type = "toggle",
                    name = "Enable Auto Greed",
                    desc = "Automatically select greed on loot items when possible.",
                    order = 2,

                    get = function() return M.db.enableAutoGreed end,
                    set = function(_, v)
                        M.db.enableAutoGreed = v
                        BasicUI:RefreshModule(M)
                    end,
                },

                enableAltBuy = {
                    type = "toggle",
                    name = "Enable Alt Buy",
                    desc = "Hold the Alt key while purchasing items to buy a full stack.",
                    order = 3,

                    get = function() return M.db.enableAltBuy end,
                    set = function(_, v)
                        M.db.enableAltBuy = v
                        BasicUI:RefreshModule(M)
                    end,
                },

            },
        },

        ------------------------------------------------
        -- Interface Enhancements
        ------------------------------------------------

        interface = {
            type = "group",
            name = "Interface Enhancements",
            inline = true,
            order = 3,

            args = {

                enableMinimap = {
                    type = "toggle",
                    name = "Enable Minimap Tweaks",
                    desc = "Enable BasicUI improvements for the minimap.",
                    order = 1,

                    get = function() return M.db.enableMinimap end,
                    set = function(_, v)
                        M.db.enableMinimap = v
                        BasicUI:RefreshModule(M)
                    end,
                },

                enableTradeSkill = {
                    type = "toggle",
                    name = "Enable Trade Skill Enhancements",
                    desc = "Enable improvements to the trade skill interface.",
                    order = 2,

                    get = function() return M.db.enableTradeSkill end,
                    set = function(_, v)
                        M.db.enableTradeSkill = v
                        BasicUI:RefreshModule(M)
                    end,
                },

                enableFlashingNodes = {
                    type = "toggle",
                    name = "Flashing Minimap Nodes",
                    desc = "Makes gathering nodes flash on the minimap.",
                    order = 3,

                    get = function() return M.db.enableFlashingNodes end,
                    set = function(_, v)
                        M.db.enableFlashingNodes = v
                        BasicUI:RefreshModule(M)
                    end,
                },

                flashInterval = {
                    type = "range",
                    name = "Node Flash Speed",
                    desc = "Adjust how fast minimap nodes flash.",
                    order = 4,
                    min = 0.1,
                    max = 1,
                    step = 0.05,

                    get = function() return M.db.flashInterval end,
                    set = function(_, v)
                        M.db.flashInterval = v
                    end,
                },
            },
        },

        ------------------------------------------------
        -- Notifications
        ------------------------------------------------

        notifications = {
            type = "group",
            name = "Notifications",
            inline = true,
            order = 4,

            disabled = function()
                return not M.db.enableNotifications
            end,

            args = {

                enableNotifications = {
                    type = "toggle",
                    name = "Enable Notifications",
                    desc = "Control the position and appearance of zone text, loot alerts, and achievement notifications.",
                    width = "full",

                    get = function() return M.db.enableNotifications end,
                    set = function(_, v)
                        M.db.enableNotifications = v
                        BasicUI:RefreshModule(M)
                    end,
                },

                enableZoneTextMove = {
                    type = "toggle",
                    name = "Move Zone Text",
                    desc = "Move the zone text banner to a custom position.",

                    get = function() return M.db.enableZoneTextMove end,
                    set = function(_, v)
                        M.db.enableZoneTextMove = v
                        BasicUI:RefreshModule(M)
                    end,
                },

                enableZoneTextAnimation = {
                    type = "toggle",
                    name = "Animate Zone Text",
                    desc = "Enable smoother animation for zone text.",

                    get = function() return M.db.enableZoneTextAnimation end,
                    set = function(_, v)
                        M.db.enableZoneTextAnimation = v
                        BasicUI:RefreshModule(M)
                    end,
                },

                enableAlertMove = {
                    type = "toggle",
                    name = "Move Alert Frames",
                    desc = "Move achievement and alert notifications.",

                    get = function() return M.db.enableAlertMove end,
                    set = function(_, v)
                        M.db.enableAlertMove = v
                        BasicUI:RefreshModule(M)
                    end,
                },

                enableLootMove = {
                    type = "toggle",
                    name = "Move Loot Roll Frames",
                    desc = "Move group loot roll frames to a better position.",

                    get = function() return M.db.enableLootMove end,
                    set = function(_, v)
                        M.db.enableLootMove = v
                        BasicUI:RefreshModule(M)
                    end,
                },

                enableLargeLootIcons = {
                    type = "toggle",
                    name = "Large Loot Icons",
                    desc = "Increase the size of special loot icons.",

                    get = function() return M.db.enableLargeLootIcons end,
                    set = function(_, v)
                        M.db.enableLargeLootIcons = v
                        BasicUI:RefreshModule(M)
                    end,
                },

            },
        },

        ------------------------------------------------
        -- Map Coordinates
        ------------------------------------------------

        mapcoords = {
            type = "group",
            name = "Map Coordinates",
            inline = true,
            order = 5,

            args = {

                enableMapCoords = {
                    type = "toggle",
                    name = "Enable Map Coordinates",
                    desc = "Display map coordinates on the world map.",

                    get = function() return M.db.enableMapCoords end,
                    set = function(_, v)
                        M.db.enableMapCoords = v
                        BasicUI:RefreshModule(M)
                    end,
                },

                enableWorldMapFog = {
                    type = "toggle",
                    name = "Darken Undiscovered Map",
                    desc = "Darkens unexplored areas of the world map for better visibility.",

                    get = function() return M.db.enableWorldMapFog end,
                    set = function(_, v)
                        M.db.enableWorldMapFog = v
                        BasicUI:RefreshModule(M)
                    end,
                },

                showPlayerCoords = {
                    type = "toggle",
                    name = "Show Player Coordinates",
                    desc = "Display your character's current map coordinates.",

                    get = function() return M.db.showPlayerCoords end,
                    set = function(_, v)
                        M.db.showPlayerCoords = v
                        BasicUI:RefreshModule(M)
                    end,
                },

                showCursorCoords = {
                    type = "toggle",
                    name = "Show Cursor Coordinates",
                    desc = "Display the cursor's position on the world map.",

                    get = function() return M.db.showCursorCoords end,
                    set = function(_, v)
                        M.db.showCursorCoords = v
                        BasicUI:RefreshModule(M)
                    end,
                },

            },
        },

    },
}

--============================================================
-- REGISTER MODULE
--============================================================

BasicUI:RegisterModule(MODULE_NAME, M)