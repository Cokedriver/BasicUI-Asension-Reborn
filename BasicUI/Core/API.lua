--============================================================
-- BasicUI API
-- Shared Utility Functions
--============================================================

local addonName, BasicUI = ...

------------------------------------------------------------
-- WoW API
------------------------------------------------------------

local pairs = pairs
local format = string.format

local UnitIsUnit = UnitIsUnit
local UnitIsDead = UnitIsDead
local UnitIsGhost = UnitIsGhost
local UnitIsPlayer = UnitIsPlayer
local UnitIsFriend = UnitIsFriend
local UnitClass = UnitClass
local UnitReaction = UnitReaction
local UnitThreatSituation = UnitThreatSituation
local UnitCanAttack = UnitCanAttack
local UnitAffectingCombat = UnitAffectingCombat
local UnitName = UnitName

--============================================================
-- DEFAULT COPY UTILITY
--============================================================

function BasicUI:CopyDefaults(src, dst)

    if type(src) ~= "table" then return {} end
    if type(dst) ~= "table" then dst = {} end

    for k, v in pairs(src) do

        if type(v) == "table" then
            dst[k] = self:CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end

    end

    return dst

end

--============================================================
-- MODULE REFRESH SYSTEM
--============================================================

function BasicUI:RefreshModule(module)

    if not module then return end

    if module.ApplySettings then
        module:ApplySettings()
    elseif module.OnEnable then
        module:OnEnable()
    end

end


function BasicUI:RefreshAll()

    for _, module in pairs(self.modules) do

        if module.db and module.db.enabled ~= false then
            self:RefreshModule(module)
        end

    end

end

--============================================================
-- SMART RELOAD POPUP
--============================================================

BasicUI.reloadRequested = false

StaticPopupDialogs["BASICUI_RELOAD_UI"] = {
    text = "Some changes require a UI reload to take effect.",
    button1 = "Reload UI",
    button2 = "Later",
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

function BasicUI:RequestReload()

    if self.reloadRequested then return end

    self.reloadRequested = true

    StaticPopup_Show("BASICUI_RELOAD_UI")

end

--============================================================
-- UNIT COLOR SYSTEM
--============================================================

local CUSTOM_FACTION_BAR_COLORS = {

    [1] = {r=1,g=0,b=0},
    [2] = {r=1,g=0,b=0},
    [3] = {r=1,g=0,b=0},

    [4] = {r=1,g=1,b=0},

    [5] = {r=0,g=1,b=0},
    [6] = {r=0,g=1,b=0},
    [7] = {r=0,g=1,b=0},
    [8] = {r=0,g=1,b=0},

}

function BasicUI:GetUnitColor(unit)

    local r,g,b

    if UnitIsUnit(unit,"pet") then

        r,g,b = 157/255,197/255,255/255

    elseif UnitIsDead(unit) or UnitIsGhost(unit) then

        r,g,b = 0.5,0.5,0.5

    elseif UnitIsPlayer(unit) then

        if UnitIsFriend(unit,"player") then

            local _,class = UnitClass(unit)

            if class and RAID_CLASS_COLORS[class] then
                local c = RAID_CLASS_COLORS[class]
                r,g,b = c.r,c.g,c.b
            else
                r,g,b = 0.6,0.6,0.6
            end

        else

            r,g,b = 1,0,0

        end

    else

        local reaction = UnitReaction(unit,"player")

        if (UnitAffectingCombat(unit) or UnitThreatSituation("player",unit))
        and UnitCanAttack("player",unit) then

            r,g,b = 1,0,0

        elseif reaction and CUSTOM_FACTION_BAR_COLORS[reaction] then

            local c = CUSTOM_FACTION_BAR_COLORS[reaction]
            r,g,b = c.r,c.g,c.b

        else

            r,g,b = 157/255,197/255,255/255

        end

    end

    return r,g,b

end

--============================================================
-- CLASS COLOR HELPERS
--============================================================

function BasicUI:GetClassColor(unit)

    local _,class = UnitClass(unit or "player")

    if class and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        return c.r,c.g,c.b
    end

    return 1,1,1

end


function BasicUI:GetClassHex(unit)

    local r,g,b = self:GetClassColor(unit)

    return format("%02x%02x%02x", r*255, g*255, b*255)

end


function BasicUI:ColorText(text,unit)

    local hex = self:GetClassHex(unit)

    return "|cff"..hex..text.."|r"

end


function BasicUI:GetColoredPlayerHeader(title)

    local name = UnitName("player") or "Player"
    local hex = self:GetClassHex("player")

    return "|cff"..hex..name.."|r - "..title

end

--============================================================
-- SLASH COMMANDS
--============================================================

SLASH_BASICUI1 = "/basicui"
SLASH_BASICUI2 = "/bui"

SlashCmdList["BASICUI"] = function()

    InterfaceOptionsFrame_OpenToCategory("BasicUI")
    InterfaceOptionsFrame_OpenToCategory("BasicUI")

end

SLASH_BASICUIRELOAD1 = "/rl"

SlashCmdList["BASICUIRELOAD"] = function()

    ReloadUI()

end