--============================================================
-- BasicUI Core
--============================================================

local addonName, BasicUI = ...
_G.BasicUI = BasicUI

------------------------------------------------------------
-- Tables
------------------------------------------------------------

BasicUI.modules = {}

BasicUI.options = {
    type = "group",
    name = "BasicUI",
    args = {}
}

------------------------------------------------------------
-- WoW API
------------------------------------------------------------

local CreateFrame = CreateFrame
local pairs = pairs
local type = type
local table_insert = table.insert
local table_sort = table.sort
local ipairs = ipairs

------------------------------------------------------------
-- Ace
------------------------------------------------------------

local AceConfig = LibStub("AceConfig-3.0")
local AceDialog = LibStub("AceConfigDialog-3.0")

--============================================================
-- PROFILE SYSTEM
--============================================================

function BasicUI:GetProfileDB(moduleName)

    BasicDB = BasicDB or {}

    BasicDB.profile = BasicDB.profile or "Default"
    BasicDB.profiles = BasicDB.profiles or {}

    if not BasicDB.profiles[BasicDB.profile] then
        BasicDB.profiles[BasicDB.profile] = {}
    end

    local profile = BasicDB.profiles[BasicDB.profile]

    profile[moduleName] = profile[moduleName] or {}

    return profile[moduleName]

end

--============================================================
-- Module Registration
--============================================================

function BasicUI:RegisterModule(name, module)

    if not name or not module then return end

    module.name = name
    module.core = self

    self.modules[name] = module

    module.db = self:GetProfileDB(name)

    if module.defaults then
        module.db = BasicUI:CopyDefaults(module.defaults, module.db)
        BasicDB.profiles[BasicDB.profile][name] = module.db
    end

end

--============================================================
-- Get Module
--============================================================

function BasicUI:GetModule(name)
    return self.modules[name]
end

--============================================================
-- Enable / Disable Module
--============================================================

function BasicUI:EnableModule(name)

    local module = self:GetModule(name)
    if not module then return end

    if module.OnEnable then
        module:OnEnable()
    end

end

function BasicUI:DisableModule(name)

    local module = self:GetModule(name)
    if not module then return end

    if module.panel then
        module.panel:Hide()
    end

    if module.OnDisable then
        module:OnDisable()
    end

end

--============================================================
-- Module Sorting
--============================================================

function BasicUI:GetSortedModules()

    local list = {}

    for _, module in pairs(self.modules) do
        table_insert(list, module)
    end

    table_sort(list, function(a, b)
        return (a.priority or 0) > (b.priority or 0)
    end)

    return list

end

--============================================================
-- Initialize Modules
--============================================================

function BasicUI:InitializeModules()

    for _, module in ipairs(self:GetSortedModules()) do

        if module.OnInit then

            local ok, err = pcall(module.OnInit, module)

            if not ok then
                print("|cffff5555BasicUI Error (OnInit): "..module.name.."|r")
                print(err)
            end

        end

        if module.options then
            self.options.args[module.name] = module.options
        end

    end

end

--============================================================
-- Enable Modules
--============================================================

function BasicUI:EnableModules()

    for _, module in ipairs(self:GetSortedModules()) do

        if module.OnEnable then

            local ok, err = pcall(module.OnEnable, module)

            if not ok then
                print("|cffff5555BasicUI Error (OnEnable): "..module.name.."|r")
                print(err)
            end

        end

        if module.OnLoadScreen then

            local ok, err = pcall(module.OnLoadScreen, module)

            if not ok then
                print("|cffff5555BasicUI Error (OnLoadScreen): "..module.name.."|r")
                print(err)
            end

        end

    end

end

--============================================================
-- PROFILE OPTIONS
--============================================================

BasicUI.options.args.Profiles = {
    type = "group",
    name = "Profiles",
    order = 999,
    args = {

        current = {
            type = "select",
            name = "Current Profile",
            order = 1,

            values = function()
                local list = {}
                for name in pairs(BasicDB.profiles) do
                    list[name] = name
                end
                return list
            end,

            get = function()
                return BasicDB.profile
            end,

            set = function(_, value)
                BasicDB.profile = value
                ReloadUI()
            end,
        },

        create = {
            type = "input",
            name = "Create Profile",
            order = 3,

            set = function(_, value)

                if value == "" then return end

                BasicDB.profiles[value] = {}
                BasicDB.profile = value

                ReloadUI()

            end
        },

        duplicate = {
            type = "input",
            name = "Duplicate Current Profile",
            order = 4,

            set = function(_, value)

                if value == "" then return end

                local src = BasicDB.profiles[BasicDB.profile]

                local function DeepCopy(tbl)
                    local copy = {}
                    for k,v in pairs(tbl) do
                        if type(v) == "table" then
                            copy[k] = DeepCopy(v)
                        else
                            copy[k] = v
                        end
                    end
                    return copy
                end

                BasicDB.profiles[value] = DeepCopy(src)
                BasicDB.profile = value

                ReloadUI()

            end
        },

        delete = {
            type = "input",
            name = "Delete Profile",
            order = 5,

            set = function(_, value)
                if value ~= "Default" then
                    BasicDB.profiles[value] = nil
                end
            end
        },

        reset = {
            type = "execute",
            name = "Reset Current Profile",
            order = 7,
            confirm = true,

            func = function()
                BasicDB.profiles[BasicDB.profile] = {}
                ReloadUI()
            end
        }

    }
}

--============================================================
-- OPTIONS INITIALIZATION
--============================================================

function BasicUI:InitializeOptions()

    AceConfig:RegisterOptionsTable("BasicUI", self.options)

    AceDialog:AddToBlizOptions(
        "BasicUI",
        "BasicUI"
    )

end

--============================================================
-- STARTUP
--============================================================

local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function()

    BasicDB = BasicDB or {}

    BasicDB.profile = BasicDB.profile or "Default"
    BasicDB.profiles = BasicDB.profiles or {}

    if not BasicDB.profiles[BasicDB.profile] then
        BasicDB.profiles[BasicDB.profile] = {}
    end

    BasicUI:InitializeOptions()
    BasicUI:InitializeModules()
    BasicUI:EnableModules()

end)