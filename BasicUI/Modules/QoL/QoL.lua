--============================================================
-- MODULE: QoL Loader
--============================================================
local MODULE_NAME = "QoL"
local M = {}

-- Global registry for QoL submodules
BasicUI_QoL_Modules = {}

function BasicUI_QoL_RegisterModule(name, func)
    BasicUI_QoL_Modules[name] = func
end

--============================================================
-- DEFAULTS
--============================================================
M.defaults = {
    enabled = true,

    enableAutomation   = true,
    enableAutoGreed    = true,
    enableAltBuy       = true,
    enableMinimap      = true,
    enableTradeSkill   = true,
    enableZoneText     = true,
    enableMapCoords    = true,
    showPlayerCoords   = true,
    showCursorCoords   = true,

}

--============================================================
-- LIFECYCLE
--============================================================
function M:OnInit()
    self.db = self.defaults
end

function M:OnLoadScreen()
    self:LoadModules()
end

--============================================================
-- AUTO MODULE LOADER
--============================================================
function M:LoadModules()
    for name, func in pairs(BasicUI_QoL_Modules) do
        local ok, err = pcall(func, self)
        if not ok then
            print("|cffff5555BasicUI QoL: Error loading module '" .. name .. "':|r")
            print(err)
        end
    end
end

BasicUI:RegisterModule(MODULE_NAME, M)