--============================================================
-- BasicUI - Pure Lua Core Framework
--============================================================
-- Handles:
--   • SavedVariables
--   • Module registration
--   • Sub-module (plugin) registration
--   • Event dispatching
--   • Default config merging
--   • Lifecycle: OnInit / OnLoadScreen
--   • /rl command
--============================================================

BasicUI = {}
BasicUI.modules = {}
BasicUI.events  = {}

--============================================================
-- SAVED VARIABLES ROOT
--============================================================
BasicDB = BasicDB or {
    modules = {},
    config  = {},
}

--============================================================
-- MIGRATION: Move Datapanel DB into Datapanel.data
--============================================================
if BasicDB.Datapanel and not BasicDB.Datapanel.data then
    BasicDB.Datapanel.data = {}

    -- Move all keys into .data
    for k, v in pairs(BasicDB.Datapanel) do
        if k ~= "data" then
            BasicDB.Datapanel.data[k] = v
        end
    end

    -- Clean up old keys
    for k in pairs(BasicDB.Datapanel) do
        if k ~= "data" then
            BasicDB.Datapanel[k] = nil
        end
    end
end

--============================================================
-- HELPERS: Deep Copy Defaults
--============================================================
local function CopyDefaults(src, dest)
    if type(src) ~= "table" then return end
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = dest[k] or {}
            CopyDefaults(v, dest[k])
        else
            if dest[k] == nil then
                dest[k] = v
            end
        end
    end
end

--============================================================
-- EVENT DISPATCHER
--============================================================
local eventFrame = CreateFrame("Frame")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if BasicUI.events[event] then
        for _, handler in ipairs(BasicUI.events[event]) do
            handler(...)
        end
    end
end)

function BasicUI:RegisterEvent(event, func)
    if not BasicUI.events[event] then
        BasicUI.events[event] = {}
        eventFrame:RegisterEvent(event)
    end
    table.insert(BasicUI.events[event], func)
end

--============================================================
-- DATABASE LOADER (PER MODULE)
--============================================================
function BasicUI:LoadModuleDB(name, defaults)
    -- Ensure module namespace exists
    BasicDB[name] = BasicDB[name] or {}

    -- Ensure module.data exists
    BasicDB[name].data = BasicDB[name].data or {}

    -- Use the .data table as the module DB
    local db = BasicDB[name].data

    -- Apply defaults
    if defaults then
        CopyDefaults(defaults, db)
    end

    return db
end

--============================================================
-- SAFE CALL WRAPPER
--============================================================
local function SafeCall(func, module, stage)
    if type(func) ~= "function" then return end

    local ok, err = pcall(func, module)
    if not ok then
        print("|cffff5555BasicUI Error in module '" .. (module.name or "?") .. "' during " .. stage .. ":|r")
        print("|cffff8888" .. tostring(err) .. "|r")
    end
end

--============================================================
-- MODULE REGISTRATION (Self-Contained Version)
--============================================================
function BasicUI:RegisterModule(name, obj)
    self.modules[name] = obj
    obj.name = name

    -- 1. Initialize the Database from SavedVariables (BasicDB)
    BasicDB.config[name] = BasicDB.config[name] or {}
    
    -- 2. Merge internal module defaults into the live DB
    if obj.defaults then
        CopyDefaults(obj.defaults, BasicDB.config[name])
    end

    -- 3. Point the module to its specific config slice
    obj.db = BasicDB.config[name]

    -- 4. Run Init
    if obj.OnInit then
        SafeCall(obj.OnInit, obj, "OnInit")
    end
end

--============================================================
-- MODULE RETRIEVAL
--============================================================
function BasicUI:GetModule(name)
    return self.modules[name]
end

--============================================================
-- SUB-MODULE (PLUGIN) REGISTRATION
--============================================================
function BasicUI:RegisterSubModule(parentName, pluginName, plugin)
    local parent = self.modules[parentName]
    if not parent then
        print("|cffff5555BasicUI: Parent module '" .. parentName .. "' not found for plugin '" .. pluginName .. "'|r")
        return
    end

    parent.submodules[pluginName] = plugin

    if parent.OnSubModuleRegistered then
        SafeCall(parent.OnSubModuleRegistered, parent, "OnSubModuleRegistered")
    end
end

--============================================================
-- LIFECYCLE: OnLoadScreen
--============================================================
BasicUI:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    -- Only run this once
    if BasicUI.Loaded then return end
    
    for name, module in pairs(BasicUI.modules) do
        -- Check if the module is enabled in the master list
        if BasicDB.modules[name] == nil then
            BasicDB.modules[name] = true
        end

        if BasicDB.modules[name] then
            SafeCall(module.OnLoadScreen, module, "OnLoadScreen")
        end
    end
    
    BasicUI.Loaded = true
end)

--============================================================
-- UNIT FRAME TEXT SHORTENING (Health & Mana)
--============================================================

-- Helper function to format 1500 into 1.5k
local function ShortenNumber(value)
    if not value then return "" end
    if value >= 1e6 then
        return string.format("%.1fm", value / 1e6)
    elseif value >= 1e3 then
        return string.format("%.1fk", value / 1e3)
    else
        return tostring(value)
    end
end

-- Hook for 3.3.5a compatible status bars
hooksecurefunc("TextStatusBar_UpdateTextString", function(bar)
    if not bar or not bar.TextString then return end
    
    local value = bar:GetValue()
    local _, valueMax = bar:GetMinMaxValues()
    
    if valueMax > 0 then
        local current = ShortenNumber(value)
        local max = ShortenNumber(valueMax)
        bar.TextString:SetText(current .. " / " .. max)
    end
end)

--============================================================
-- SLASH COMMANDS
--============================================================
SLASH_RL1 = "/rl"
SlashCmdList["RL"] = ReloadUI

--============================================================
-- CORE LOADED MESSAGE
--============================================================
-- print("|cff00aaffBasicUI: Loaded|r")
