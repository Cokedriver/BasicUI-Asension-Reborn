--============================================================
-- MODULE: Buffs
--============================================================

local addonName, BasicUI = ...
local L = BasicUI.L
local MODULE_NAME = "Buffs"

local M = {}

--============================================================
-- CONFIG DEFAULTS
--============================================================

M.defaults = {
    enabled = true,
    scale = 1.193,
    fontSize = 12,
}

--============================================================
-- LIFECYCLE: OnInit
--============================================================

function M:OnInit()

    BasicDB = BasicDB or {}
    BasicDB.Buffs = BasicDB.Buffs or {}

    self.db = BasicDB.Buffs

    for k,v in pairs(self.defaults) do
        if self.db[k] == nil then
            self.db[k] = v
        end
    end

    self.hooked = false

end

--============================================================
-- FRAME SCALING
--============================================================

local function ApplyBuffFrameScaling(scale)

    if ConsolidatedBuffs then ConsolidatedBuffs:SetScale(scale) end
    if BuffFrame then BuffFrame:SetScale(scale) end
    if VanityBuffs then VanityBuffs:SetScale(scale) end
    if TemporaryEnchantFrame then TemporaryEnchantFrame:SetScale(scale) end

end

local function RestoreBlizzardBuffs()

    if ConsolidatedBuffs then ConsolidatedBuffs:SetScale(1) end
    if BuffFrame then BuffFrame:SetScale(1) end
    if VanityBuffs then VanityBuffs:SetScale(1) end
    if TemporaryEnchantFrame then TemporaryEnchantFrame:SetScale(1) end

    -- restore default time format
    SecondsToTimeAbbrev = function(seconds)
        return SecondsToTime(seconds)
    end

    for i = 1, BUFF_MAX_DISPLAY do
        local b = _G["BuffButton"..i]
        if b and b.duration then
            b.duration:SetFont(STANDARD_TEXT_FONT, 10, "")
        end
    end

    for i = 1, DEBUFF_MAX_DISPLAY do
        local b = _G["DebuffButton"..i]
        if b and b.duration then
            b.duration:SetFont(STANDARD_TEXT_FONT, 10, "")
        end
    end

    if BuffFrame_Update then
        BuffFrame_Update()
    end

end

--============================================================
-- TIME ABBREVIATION
--============================================================

local function OverrideTimeAbbrev()

    SecondsToTimeAbbrev = function(seconds)

        if seconds >= 86400 then
            return "%dd", ceil(seconds / 86400)

        elseif seconds >= 3600 then
            return "%dh", ceil(seconds / 3600)

        elseif seconds >= 60 then
            return "%dm", ceil(seconds / 60)

        else
            return "%d", seconds
        end

    end

end

--============================================================
-- STYLE AURA BUTTON
--============================================================

local function StyleAuraButton(button)

    local FONT = BasicUI:GetBasicFont("N")
    local FONT_STYLE = "THINOUTLINE"
    local size = M.db and M.db.fontSize or 12

    local first = not button.BasicUIStyled
    button.BasicUIStyled = true

    if button.duration then

        if first then
            button.duration:ClearAllPoints()
            button.duration:SetPoint("BOTTOM", button, "BOTTOM", 0, -2)
            button.duration:SetShadowOffset(0,0)
            button.duration:SetDrawLayer("OVERLAY")
        end

        button.duration:SetFont(FONT, size, FONT_STYLE)

    end

    if button.count then

        if first then
            button.count:ClearAllPoints()
            button.count:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
            button.count:SetShadowOffset(0,0)
            button.count:SetDrawLayer("OVERLAY")
        end

        button.count:SetFont(FONT, size, FONT_STYLE)

    end

end

--============================================================
-- SAFE HOOK SETUP
--============================================================

local function SetupHooks(self)

    if self.hooked then return end

    hooksecurefunc("CreateFrame", function(_, name, parent, template)

        if template == "BuffButtonTemplate"
        or template == "DebuffButtonTemplate" then

            local button = _G[name]

            if button then
                StyleAuraButton(button)
            end

        end

    end)

    self.hooked = true

end

--============================================================
-- APPLY ALL STYLING
--============================================================

local function ApplyAllBuffStyling(self)

    ApplyBuffFrameScaling(self.db.scale)
    OverrideTimeAbbrev()

    for i = 1, BUFF_MAX_DISPLAY do
        local b = _G["BuffButton"..i]
        if b then StyleAuraButton(b) end
    end

    for i = 1, DEBUFF_MAX_DISPLAY do
        local b = _G["DebuffButton"..i]
        if b then StyleAuraButton(b) end
    end

end

--============================================================
-- LIFECYCLE: OnEnable
--============================================================

function M:OnEnable()

    if not self.db.enabled then return end

    SetupHooks(self)
    ApplyAllBuffStyling(self)

    local f = CreateFrame("Frame")

    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ADDON_LOADED")

    f:SetScript("OnEvent", function(_, event, addon)

        if event == "ADDON_LOADED" and addon ~= "BasicUI" then return end

        ApplyAllBuffStyling(self)

    end)

end

local function RestoreDefaultBuffs()

    ------------------------------------------------
    -- Reset frame scale
    ------------------------------------------------
    if ConsolidatedBuffs then ConsolidatedBuffs:SetScale(1) end
    if BuffFrame then BuffFrame:SetScale(1) end
    if VanityBuffs then VanityBuffs:SetScale(1) end
    if TemporaryEnchantFrame then TemporaryEnchantFrame:SetScale(1) end

    ------------------------------------------------
    -- Restore default timer function
    ------------------------------------------------
    SecondsToTimeAbbrev = _G.SecondsToTimeAbbrev

    ------------------------------------------------
    -- Reset aura buttons
    ------------------------------------------------
    for i = 1, BUFF_MAX_DISPLAY do

        local b = _G["BuffButton"..i]

        if b then

            b.BasicUIStyled = nil

            if b.duration then
                b.duration:ClearAllPoints()
                b.duration:SetPoint("BOTTOM", b, "BOTTOM", 0, 0)
                b.duration:SetFont(STANDARD_TEXT_FONT, 10, "")
            end

            if b.count then
                b.count:ClearAllPoints()
                b.count:SetPoint("TOPRIGHT", b, "TOPRIGHT", -1, -1)
                b.count:SetFont(STANDARD_TEXT_FONT, 10, "")
            end

        end

    end

    for i = 1, DEBUFF_MAX_DISPLAY do

        local b = _G["DebuffButton"..i]

        if b then

            b.BasicUIStyled = nil

            if b.duration then
                b.duration:ClearAllPoints()
                b.duration:SetPoint("BOTTOM", b, "BOTTOM", 0, 0)
                b.duration:SetFont(STANDARD_TEXT_FONT, 10, "")
            end

            if b.count then
                b.count:ClearAllPoints()
                b.count:SetPoint("TOPRIGHT", b, "TOPRIGHT", -1, -1)
                b.count:SetFont(STANDARD_TEXT_FONT, 10, "")
            end

        end

    end

    ------------------------------------------------
    -- Force Blizzard refresh
    ------------------------------------------------
    if BuffFrame_Update then
        BuffFrame_Update()
    end

end

--============================================================
-- OPTIONS
--============================================================

M.options = {
    type = "group",
    name = "Buffs",
    args = {

        enabled = {
            type = "toggle",
            name = "Enable Buff Styling",
            desc = "Enable BasicUI styling for the default buff and debuff frames.",
            order = 1,
            width = "full",
            get = function() return M.db.enabled end,
			set = function(_, v)

				M.db.enabled = v

				if v then

					M:OnEnable()
					ApplyAllBuffStyling(M)

				else

					RestoreDefaultBuffs()

				end

			end
        },

        scale = {
            type = "range",
            name = "Buff Frame Scale",
            desc = "Adjust the scale of the buff and debuff frames.",
            min = 0.5,
            max = 2,
            step = 0.01,
            order = 2,
			disabled = BuffsDisabled,
            get = function() return M.db.scale end,
            set = function(_, v)

                M.db.scale = v
                ApplyBuffFrameScaling(v)

                if BuffFrame_Update then
                    BuffFrame_Update()
                end

            end,
        },

        fontSize = {
            type = "range",
            name = "Buff Duration Font Size",
            desc = "Adjust the font size used for buff duration text.",
            min = 8,
            max = 32,
            step = 1,
            order = 3,
			disabled = BuffsDisabled,
            get = function() return M.db.fontSize end,
            set = function(_, v)

                M.db.fontSize = v
                ApplyAllBuffStyling(M)

                if BuffFrame_Update then
                    BuffFrame_Update()
                end

            end,
        },

    }
}

--============================================================
-- REGISTER MODULE
--============================================================

BasicUI:RegisterModule(MODULE_NAME, M)