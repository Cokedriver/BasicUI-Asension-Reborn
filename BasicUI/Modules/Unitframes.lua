--============================================================
-- MODULE: Unitframes (Ascension 3.3.5a)
--============================================================
local MODULE_NAME = "Unitframes"
local M = CreateFrame("Frame", "BasicUI_Unitframes", UIParent)

-- SECTION 1: Config & Fonts
local UNIT_FONT_BOLD    = [[Interface\AddOns\BasicUI\Media\Expressway_Rg_BOLD.ttf]]
local UNIT_FONT_REGULAR = [[Interface\AddOns\BasicUI\Media\Expressway_Rg.ttf]]

--============================================================
-- SECTION 1: DEFAULTS
--============================================================
M.defaults = {
    enabled = true,
    playerScale = 1.193,
    targetScale = 1.193,
    focusScale = 1.193,
    partyScale = 1.193,
    bossScale = 1.193,
    arenaScale = 1.193,
    
    enablePlayer = true,
    enableTarget = true,
    enableFocus = true,
    enableParty = true,
    enableBoss = true,
    enableArena = true,
    
    enableCastbar = true,
    castbarScale = 1.193,
    
    enablePet = true,
    petFontSize = 13,
    petColor = { r = 157/255, g = 197/255, b = 255/255 },
    
    enableClassHealth = true,
    hideHitText = true,
}

--============================================================
-- SECTION 2: Standalone Color Logic
--============================================================
local CUSTOM_FACTION_BAR_COLORS = {
    [1] = {r = 1, g = 0, b = 0},
    [2] = {r = 1, g = 0, b = 0},
    [3] = {r = 1, g = 0, b = 0},
    [4] = {r = 1, g = 1, b = 0},
    [5] = {r = 0, g = 1, b = 0},
    [6] = {r = 0, g = 1, b = 0},
    [7] = {r = 0, g = 1, b = 0},
    [8] = {r = 0, g = 1, b = 0},
}

local function GetUnitColor(unit)
    local r, g, b

    if UnitIsUnit(unit, "pet") then
        r, g, b = 157/255, 197/255, 255/255
    elseif UnitIsDead(unit) or UnitIsGhost(unit) then
        r, g, b = 0.5, 0.5, 0.5
    elseif UnitIsPlayer(unit) then
        if UnitIsFriend(unit, 'player') then
            local _, class = UnitClass(unit)
            if class then
                local color = RAID_CLASS_COLORS[class]
                r, g, b = color.r, color.g, color.b
            else
                r, g, b = 0.60, 0.60, 0.60
            end
        else
            r, g, b = 1, 0, 0
        end
    else
        -- Logic for NPCs: Check combat first to catch Neutral -> Hostile transitions
        local reaction = UnitReaction(unit, 'player')
        
        if (UnitAffectingCombat(unit) or UnitThreatSituation("player", unit)) and UnitCanAttack("player", unit) then
            r, g, b = 1, 0, 0 -- Turn Red if we are fighting it
        elseif reaction and CUSTOM_FACTION_BAR_COLORS[reaction] then
            r = CUSTOM_FACTION_BAR_COLORS[reaction].r
            g = CUSTOM_FACTION_BAR_COLORS[reaction].g
            b = CUSTOM_FACTION_BAR_COLORS[reaction].b
        else
            r, g, b = 157/255, 197/255, 255/255
        end
    end
    return r, g, b
end

--============================================================
-- SECTION 3: Castbar Styling & Timer Logic
--============================================================
local function StyleDefaultCastbar(self)
    local cb = _G["CastingBarFrame"]
    if not cb then return end

    if not cb.timer then
        cb.timer = cb:CreateFontString(nil, "OVERLAY")
        cb.timer:SetFont("Fonts\\FRIZQT__.TTF", 13)
        cb.timer:SetPoint("RIGHT", cb, "RIGHT", -5, 3) 
        cb.timer:SetTextColor(1, 1, 1)
        cb.timer:SetJustifyH("RIGHT")
    end

    local function ApplySafeFont(obj, size)
        if not obj then return end
        local success = obj:SetFont(UNIT_FONT_REGULAR, size)
        if not success then
            obj:SetFont("Fonts\\FRIZQT__.TTF", size)
        end
    end

    local function UpdateCastbarStyle()
        local _, class = UnitClass("player")
        local color = RAID_CLASS_COLORS[class]
        if color then
            cb:SetStatusBarColor(color.r, color.g, color.b)
        end

        local text = _G["CastingBarFrameText"]
        if text then 
            ApplySafeFont(text, 13) 
            text:SetTextColor(1, 1, 1)
            text:ClearAllPoints()
            text:SetPoint("LEFT", cb, "LEFT", 5, 3)
            text:SetJustifyH("LEFT")
        end
        
        if cb.timer then
            ApplySafeFont(cb.timer, 13)
        end
    end

    cb:HookScript("OnUpdate", function(self)
        if not self.timer or not self.timer:GetFont() then return end
        
        if self.casting then
            local timeLeft = self.maxValue - self.value
            self.timer:SetText(string.format("%.1f", math.max(timeLeft, 0)))
        elseif self.channeling then
            local timeLeft = self.value
            self.timer:SetText(string.format("%.1f", math.max(timeLeft, 0)))
        else
            if self.timer:GetText() ~= "" then
                self.timer:SetText("")
            end
        end
    end)

    cb:HookScript("OnShow", UpdateCastbarStyle)
    cb:SetScale(self.db.castbarScale or 1.193)
    UpdateCastbarStyle()
end

--============================================================
-- SECTION 4: Placement and Core Styling
--============================================================
function M:UpdateFrameScales()
    local db = self.db
    if PlayerFrame then
        PlayerFrame:SetMovable(true)
        PlayerFrame:SetUserPlaced(true)
        PlayerFrame:ClearAllPoints()
        PlayerFrame:SetPoint("CENTER", UIParent, "CENTER", -225, -200)
        PlayerFrame:SetScale(db.playerScale or 1.193)
    end
    if TargetFrame then
        TargetFrame:SetMovable(true)
        TargetFrame:SetUserPlaced(true)
        TargetFrame:ClearAllPoints()
        TargetFrame:SetPoint("CENTER", UIParent, "CENTER", 235, -200)
        TargetFrame:SetScale(db.targetScale or 1.193)
    end
    if FocusFrame then FocusFrame:SetScale(db.focusScale or 1.193) end
end

function M:ApplyAllStyling(frame)
    if not frame or not frame.unit or not UnitExists(frame.unit) then return end
    local unit, db = frame.unit, self.db
    local frameName = frame:GetName()
    
    local r, g, b = GetUnitColor(unit)

    -- 1. Handle the Name Background
    local nameBG = _G[frameName.."NameBackground"]
    if nameBG then
        if UnitAffectingCombat(unit) then
            nameBG:SetVertexColor(r, g, b, 1)
        else
            nameBG:SetVertexColor(0.1, 0.1, 0.1, 0.1)
        end
    end

    -- 2. Color the Name Text
    local nameText = frame.name or _G[frameName.."Name"] or _G[frameName.."TextureFrameName"]
    if nameText then
        local font = (frame == TargetFrameToT or frame == FocusFrameToT) and UNIT_FONT_REGULAR or UNIT_FONT_BOLD
        nameText:SetFont(font, 16, "THINOUTLINE")
        nameText:SetTextColor(r, g, b) 
    end

    -- 3. Health Bar Styling
    if db.enableClassHealth then
        local hb = frame.healthBar or frame.HealthBar
        if hb then
            hb:SetStatusBarColor(r, g, b)
        end
    end
end

--============================================================
-- SECTION 5: Events & Initialization
--============================================================
M:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and (...) == "BasicUI" then
        if BasicConfig and BasicConfig.Unitframes then
            self.db = BasicConfig.Unitframes
        else
            self.db = self.defaults 
        end

        if self.db.hideHitText then
            PlayerHitIndicator:Hide()
            PetHitIndicator:Hide()
            PlayerHitIndicator.Show = function() end
            PetHitIndicator.Show = function() end
            CombatText_UpdateUnitModel = function() end
        end

        self:UpdateFrameScales()
        StyleDefaultCastbar(self)

        hooksecurefunc("UnitFrame_Update", function(f) if f then self:ApplyAllStyling(f) end end)
        hooksecurefunc("UnitFrameHealthBar_Update", function(s) if s and s:GetParent() then self:ApplyAllStyling(s:GetParent()) end end)
        hooksecurefunc("TargetFrame_CheckClassification", function(f) if f then self:ApplyAllStyling(f) end end)

        self:RegisterEvent("UNIT_FLAGS")
        self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
        self:RegisterEvent("UNIT_COMBAT")
        self:RegisterEvent("PLAYER_REGEN_DISABLED")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    elseif event == "UNIT_FLAGS" or event == "UNIT_THREAT_SITUATION_UPDATE" then
        local unit = ...
        if unit == "target" then
            self:ApplyAllStyling(TargetFrame)
        end
    elseif event == "UNIT_COMBAT" or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        self:ApplyAllStyling(PlayerFrame)
        self:ApplyAllStyling(TargetFrame)
    end
end)

M:RegisterEvent("ADDON_LOADED")
BasicUI:RegisterModule(MODULE_NAME, M)