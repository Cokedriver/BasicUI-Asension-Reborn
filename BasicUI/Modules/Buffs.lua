--============================================================
-- MODULE: Buffs
--============================================================
local MODULE_NAME = "Buffs"
local M = {}

--============================================================
-- CONFIG DEFAULTS
--============================================================
M.defaults = {
    scale = 1.193
}

--============================================================
-- LIFECYCLE: OnInit
--============================================================
function M:OnInit()
    -- Reserved for future logic
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
    if button.BasicUIStyled then return end
    button.BasicUIStyled = true

    local FONT = "Fonts\\ARIALN.ttf"
    local FONT_SIZE = 12
    local FONT_STYLE = "THINOUTLINE"

    -- Duration
    if button.duration then
        button.duration:ClearAllPoints()
        button.duration:SetPoint("BOTTOM", button, "BOTTOM", 0, -2)
        button.duration:SetFont(FONT, FONT_SIZE, FONT_STYLE)
        button.duration:SetShadowOffset(0, 0)
        button.duration:SetDrawLayer("OVERLAY")
    end

    -- Count
    if button.count then
        button.count:ClearAllPoints()
        button.count:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
        button.count:SetFont(FONT, FONT_SIZE, FONT_STYLE)
        button.count:SetShadowOffset(0, 0)
        button.count:SetDrawLayer("OVERLAY")
    end
end

--============================================================
-- HOOK: STYLE BUFF BUTTONS WHEN CREATED
--============================================================
hooksecurefunc("CreateFrame", function(_, name, parent, template)
    if template == "BuffButtonTemplate" or template == "DebuffButtonTemplate" then
        local button = _G[name]
        if button then
            StyleAuraButton(button)
        end
    end
end)

--============================================================
-- APPLY ALL STYLING
--============================================================
local function ApplyAllBuffStyling(self)
    ApplyBuffFrameScaling(self.db.scale)
    OverrideTimeAbbrev()

    -- Style existing buttons (login + reload)
    for i = 1, BUFF_MAX_DISPLAY do
        local b = _G["BuffButton" .. i]
        if b then StyleAuraButton(b) end
    end
    for i = 1, DEBUFF_MAX_DISPLAY do
        local b = _G["DebuffButton" .. i]
        if b then StyleAuraButton(b) end
    end
end

--============================================================
-- LIFECYCLE: OnLoadScreen
--============================================================
function M:OnLoadScreen()
    ApplyAllBuffStyling(self)

    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(_, event, addon)
        if event == "ADDON_LOADED" and addon ~= "BasicUI" then return end
        ApplyAllBuffStyling(self)
    end)
end

--============================================================
-- REGISTER MODULE
--============================================================
BasicUI:RegisterModule(MODULE_NAME, M)
