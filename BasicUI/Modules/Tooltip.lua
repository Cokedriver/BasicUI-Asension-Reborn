--============================================================
-- MODULE: Tooltip
--============================================================
local MODULE_NAME = "Tooltip"
local M = {}

local function DB()
    return M.db or M.defaults
end

--============================================================
-- SECTION 1: Defaults (cfg → M.defaults)
--============================================================
M.defaults = {
    fontSize = 15,
    fontOutline = false,

    showOnMouseover = false,
    hideInCombat = false,

    reactionBorderColor = true,
    itemqualityBorderColor = true,

    abbrevRealmNames = false,
    hideRealmText = false,
    showPlayerTitles = true,
    showUnitRole = true,
    showPVPIcons = false,
    showMouseoverTarget = true,
    showSpecializationIcon = true,
    showItemLevel = true,
    bgDarkness = 1,

    healthbar = {
        healthFormat = '$cur / $max',
        healthFullFormat = '$cur',

        fontSize = 13,
        font = "Fonts\\FRIZQT__.ttf",
        showOutline = true,
        textPos = 'CENTER',

        reactionColoring = true,
        customColor = {
            apply = false,
            r = 0,
            g = 1,
            b = 1
        }
    }
}

--============================================================
-- SECTION 2: Faction Colors + Tooltip Styling
--============================================================

CUSTOM_FACTION_BAR_COLORS = {
    [1] = {r = 1, g = 0, b = 0},
    [2] = {r = 1, g = 0, b = 0},
    [3] = {r = 1, g = 0, b = 0}, -- Changed to Red for hostile
    [4] = {r = 1, g = 1, b = 0},
    [5] = {r = 0, g = 1, b = 0},
    [6] = {r = 0, g = 1, b = 0},
    [7] = {r = 0, g = 1, b = 0},
    [8] = {r = 0, g = 1, b = 0},
}

function GameTooltip_UnitColor(unit)
    local r, g, b

    if UnitIsUnit(unit, "pet") then
        r, g, b = 157/255, 197/255, 255/255

    elseif UnitIsDead(unit) or UnitIsGhost(unit) then
        r, g, b = 0.5, 0.5, 0.5

    elseif UnitIsPlayer(unit) then
        if UnitIsFriend(unit, 'player') then
            local _, class = UnitClass(unit)
            if class then
                r = RAID_CLASS_COLORS[class].r
                g = RAID_CLASS_COLORS[class].g
                b = RAID_CLASS_COLORS[class].b
            else
                r, g, b = 0.60, 0.60, 0.60
            end
        else
            r, g, b = 1, 0, 0
        end

    else
        -- Logic for NPCs: Check combat/threat first to turn Neutral -> Red
        local reaction = UnitReaction(unit, 'player')
        
        if (UnitAffectingCombat(unit) or UnitThreatSituation("player", unit)) and UnitCanAttack("player", unit) then
            r, g, b = 1, 0, 0 -- Red if Engaged
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

hooksecurefunc("TargetFrame_CheckFaction", function(self)
    if UnitPlayerControlled(self.unit) then
        self.nameBackground:SetVertexColor(GameTooltip_UnitColor(self.unit))
    end
end)

--============================================================
-- Tooltip Font Setup
--============================================================
local function ApplyTooltipFonts(db)
    if db.fontOutline then
        GameTooltipText:SetFont([[Fonts\FRIZQT__.ttf]], db.fontSize, 'THINOUTLINE')
        GameTooltipText:SetShadowOffset(0, 0)

        GameTooltipTextSmall:SetFont([[Fonts\FRIZQT__.ttf]], db.fontSize, 'THINOUTLINE')
        GameTooltipTextSmall:SetShadowOffset(0, 0)
    else
        GameTooltipText:SetFont([[Fonts\FRIZQT__.ttf]], db.fontSize)
        GameTooltipTextSmall:SetFont([[Fonts\FRIZQT__.ttf]], db.fontSize)
    end
end

--============================================================
-- Tooltip Backdrop Styling
--============================================================
local function ApplyTooltipStyle(self, db)
    local bgsize
    if self == ConsolidatedBuffsTooltip then
        bgsize = 1
    elseif self == FriendsTooltip then
        FriendsTooltip:SetScale(1.1)
        bgsize = 1
    else
        bgsize = 3
    end

    self:SetBackdrop({
        bgFile = [[Interface\DialogFrame\UI-DialogBox-Background-Dark]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        tile = true, tileSize = 16, edgeSize = 18,
        insets = { left = bgsize, right = bgsize, top = bgsize, bottom = bgsize }
    })

    self:HookScript('OnShow', function(self)
        self:SetBackdropColor(0, 0, 0, db.bgDarkness)
    end)
end


--============================================================
-- SECTION 3: Item Quality Border Coloring
--============================================================
if DB().itemqualityBorderColor then
    for _, tooltip in pairs({
        GameTooltip,
        ItemRefTooltip,
        ShoppingTooltip1,
        ShoppingTooltip2,
        ShoppingTooltip3,
    }) do
        tooltip:HookScript('OnTooltipSetItem', function(self)
            local name, item = self:GetItem()
            if item then
                local quality = select(3, GetItemInfo(item))
                if quality then
                    local r, g, b = GetItemQualityColor(quality)
                    self:SetBackdropBorderColor(r, g, b)
                end
            end
        end)

        tooltip:HookScript('OnTooltipCleared', function(self)
            self:SetBackdropBorderColor(1, 1, 1)
        end)
    end
end

--============================================================
-- SECTION 4: Unit Formatting, PvP, Roles, Healthbar, Inspect
--============================================================

local _G = _G
local select = select
local format = string.format

local UnitName = UnitName
local UnitLevel = UnitLevel
local UnitExists = UnitExists
local UnitIsDead = UnitIsDead
local UnitIsGhost = UnitIsGhost
local UnitFactionGroup = UnitFactionGroup
local UnitCreatureType = UnitCreatureType
local GetQuestDifficultyColor = GetQuestDifficultyColor

local tankIcon    = '|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:13:13:0:0:64:64:0:19:22:41|t'
local healIcon    = '|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:13:13:0:0:64:64:20:39:1:20|t'
local damagerIcon = '|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:13:13:0:0:64:64:20:39:22:41|t'

--------------------------------------------------------------
-- GetRealUnit
--------------------------------------------------------------
local function GetRealUnit(self)
    if GetMouseFocus() and not GetMouseFocus():GetAttribute('unit') and GetMouseFocus() ~= WorldFrame then
        return select(2, self:GetUnit())
    elseif GetMouseFocus() and GetMouseFocus():GetAttribute('unit') then
        return GetMouseFocus():GetAttribute('unit')
    elseif select(2, self:GetUnit()) then
        return select(2, self:GetUnit())
    else
        return 'mouseover'
    end
end

--------------------------------------------------------------
-- Unit Formatting Helpers
--------------------------------------------------------------
local function GetFormattedUnitType(unit)
    return UnitCreatureType(unit) or ''
end

local function GetFormattedUnitClassification(unit)
    local class = UnitClassification(unit)
    if class == 'worldboss' then
        return '|cffFF0000'..BOSS..'|r '
    elseif class == 'rareelite' then
        return '|cffFF66CCRare|r |cffFFFF00'..ELITE..'|r '
    elseif class == 'rare' then
        return '|cffFF66CCRare|r '
    elseif class == 'elite' then
        return '|cffFFFF00'..ELITE..'|r '
    end
    return ''
end

local function GetFormattedUnitLevel(unit)
    local diff = GetQuestDifficultyColor(UnitLevel(unit))
    if UnitLevel(unit) == -1 then
        return '|cffff0000??|r '
    elseif UnitLevel(unit) == 0 then
        return '? '
    else
        return format('|cff%02x%02x%02x%s|r ',
            diff.r*255, diff.g*255, diff.b*255, UnitLevel(unit))
    end
end

local function GetFormattedUnitClass(unit)
    local color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
    if color then
        return format(' |cff%02x%02x%02x%s|r',
            color.r*255, color.g*255, color.b*255, UnitClass(unit))
    end
end

local function GetFormattedUnitString(unit, specIcon)
    if UnitIsPlayer(unit) then
        if not UnitRace(unit) then return nil end
        return GetFormattedUnitLevel(unit)
            .. UnitRace(unit)
            .. GetFormattedUnitClass(unit)
            .. (DB().showSpecializationIcon and specIcon or '')
    else
        return GetFormattedUnitLevel(unit)
            .. GetFormattedUnitClassification(unit)
            .. GetFormattedUnitType(unit)
    end
end

--------------------------------------------------------------
-- Unit Role
--------------------------------------------------------------
local function GetUnitRoleString(unit)
    local role = UnitGroupRolesAssigned(unit)
    if role == 'TANK' then
        return '   '..tankIcon..' '..TANK
    elseif role == 'HEALER' then
        return '   '..healIcon..' '..HEALER
    elseif role == 'DAMAGER' then
        return '   '..damagerIcon..' '..DAMAGER
    end
end

--------------------------------------------------------------
-- Mouseover Target
--------------------------------------------------------------
local function AddMouseoverTarget(self, unit)
    local target = unit.."target"
    if not UnitExists(target) then return end

    local name = UnitName(target)
    local classColor = RAID_CLASS_COLORS[select(2, UnitClass(target))]
        or { r = 1, g = 0, b = 1 }

    local reactionColor = {
        r = select(1, GameTooltip_UnitColor(target)),
        g = select(2, GameTooltip_UnitColor(target)),
        b = select(3, GameTooltip_UnitColor(target)),
    }

    if name == UnitName("player") then
        self:AddLine('|cffFFFF00Target|r: |cffff0000** YOU **|r')
    else
        if UnitIsPlayer(target) then
            self:AddLine(format('|cffFFFF00Target|r: |cff%02x%02x%02x%s|r',
                classColor.r*255, classColor.g*255, classColor.b*255, name), 1, 1, 1)
        else
            self:AddLine(format('|cffFFFF00Target|r: |cff%02x%02x%02x%s|r',
                reactionColor.r*255, reactionColor.g*255, reactionColor.b*255, name), 1, 1, 1)
        end
    end
end

--------------------------------------------------------------
-- Healthbar Coloring
--------------------------------------------------------------
local function SetHealthBarColor(unit)
    local r, g, b

    if DB().healthbar.customColor.apply and not DB().healthbar.reactionColoring then
        r = DB().healthbar.customColor.r
        g = DB().healthbar.customColor.g
        b = DB().healthbar.customColor.b

    elseif DB().healthbar.reactionColoring and unit then
        r, g, b = GameTooltip_UnitColor(unit)

    else
        r, g, b = 0, 1, 0
    end

    GameTooltipStatusBar:SetStatusBarColor(r, g, b)
    GameTooltipStatusBar:SetBackdropColor(r, g, b, 0.3)
end

--------------------------------------------------------------
-- Raid Icon
--------------------------------------------------------------
local function GetUnitRaidIcon(unit)
    local index = GetRaidTargetIndex(unit)
    if index then
        return ICON_LIST[index].."11|t "
    end
    return ''
end

--------------------------------------------------------------
-- PvP Icon
--------------------------------------------------------------
local function GetUnitPVPIcon(unit)
    local faction = UnitFactionGroup(unit)

    if UnitIsPVPFreeForAll(unit) then
        return DB().showPVPIcons
            and '|TInterface\\AddOns\\cTooltip\\Media\\UI-PVP-FFA:12|t'
            or '|cffFF0000# |r'

    elseif faction and UnitIsPVP(unit) then
        return DB().showPVPIcons
            and '|TInterface\\AddOns\\cTooltip\\Media\\UI-PVP-'..faction..':12|t'
            or '|cff00FF00# |r'
    end

    return ''
end

--============================================================
-- Tooltip Unit Hook
--============================================================
GameTooltip.inspectCache = {}

GameTooltip:HookScript('OnTooltipSetUnit', function(self)
    local unit = GetRealUnit(self)

    if DB().hideInCombat and InCombatLockdown() then
        self:Hide()
        return
    end

    if UnitExists(unit) and UnitName(unit) ~= UNKNOWN then
        local ilvl = 0
        local specIcon = ''
        local lastUpdate = 30

        for _, cache in pairs(self.inspectCache) do
            if cache.GUID == UnitGUID(unit) then
                ilvl = cache.itemLevel or 0
                specIcon = cache.specIcon or ''
                lastUpdate = cache.lastUpdate
                    and math.abs(cache.lastUpdate - math.floor(GetTime()))
                    or 30
            end
        end

        if unit and CanInspect(unit) then
            if not self.inspectRefresh and lastUpdate >= 30 and not self.blockInspectRequests then
                self.inspectRequestSent = true
                NotifyInspect(unit)
            end
        end

        self.inspectRefresh = false

        local name, realm = UnitName(unit)
        local r, g, b = GameTooltip_UnitColor(unit) -- Get dynamic color

        if DB().showPlayerTitles and UnitPVPName(unit) then
            name = UnitPVPName(unit)
        end

        -- APPLY NAME COLOR TO TOOLTIP
        GameTooltipTextLeft1:SetText(name)
        GameTooltipTextLeft1:SetTextColor(r, g, b)

        local guildName = GetGuildInfo(unit)
        if guildName then
            GameTooltipTextLeft2:SetText('|cffFF66CC'..GameTooltipTextLeft2:GetText()..'|r')
        end

        for i = 2, GameTooltip:NumLines() do
            local line = _G['GameTooltipTextLeft'..i]
            if line:GetText():find('^'..TOOLTIP_UNIT_LEVEL:gsub('%%s', '.+')) then
                line:SetText(GetFormattedUnitString(unit, specIcon))
            end
        end

        if DB().showUnitRole then
            self:AddLine(GetUnitRoleString(unit), 1, 1, 1)
        end

        if DB().showMouseoverTarget then
            AddMouseoverTarget(self, unit)
        end

        for i = 3, GameTooltip:NumLines() do
            local line = _G['GameTooltipTextLeft'..i]
            if line:GetText():find(PVP_ENABLED) then
                line:SetText(nil)
                GameTooltipTextLeft1:SetText(GetUnitPVPIcon(unit)..GameTooltipTextLeft1:GetText())
            end
        end

        GameTooltipTextLeft1:SetText(GetUnitRaidIcon(unit)..GameTooltipTextLeft1:GetText())

        if UnitIsAFK(unit) then
            self:AppendText('|cff00ff00 <AFK>|r')
        elseif UnitIsDND(unit) then
            self:AppendText('|cff00ff00 <DND>|r')
        end

        if realm and realm ~= '' then
            if DB().abbrevRealmNames then
                self:AppendText(' (*)')
            else
                self:AppendText(' - '..realm)
            end
        end

        if GameTooltipStatusBar:IsShown() then
            self:AddLine(' ')
            GameTooltipStatusBar:ClearAllPoints()
            GameTooltipStatusBar:SetPoint('LEFT', self:GetName()..'TextLeft'..self:NumLines(), 1, -3)
            GameTooltipStatusBar:SetPoint('RIGHT', self, -10, 0)
        end

        if DB().reactionBorderColor then
            self:SetBackdropBorderColor(r, g, b)
        end

        if UnitIsDead(unit) or UnitIsGhost(unit) then
            GameTooltipStatusBar:SetBackdropColor(0.5, 0.5, 0.5, 0.3)
        else
            if not DB().healthbar.customColor.apply and not DB().healthbar.reactionColoring then
                GameTooltipStatusBar:SetBackdropColor(27/255, 243/255, 27/255, 0.3)
            else
                SetHealthBarColor(unit)
            end
        end
    end
end)

--============================================================
-- Tooltip Cleared & Healthbar Logic
--============================================================
GameTooltip:HookScript('OnTooltipCleared', function(self)
    GameTooltipStatusBar:ClearAllPoints()
    GameTooltipStatusBar:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0.5, 3)
    GameTooltipStatusBar:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', -1, 3)
    GameTooltipStatusBar:SetBackdropColor(0, 1, 0, 0.3)

    if DB().reactionBorderColor then
        self:SetBackdropBorderColor(1, 1, 1)
    end
end)

--------------------------------------------------------------
-- Healthbar Text
--------------------------------------------------------------
local bar = GameTooltipStatusBar
bar.Text = bar:CreateFontString(nil, 'OVERLAY')
bar.Text:SetPoint('CENTER', bar, DB().healthbar.textPos, 0, 1)

if DB().healthbar.showOutline then
    bar.Text:SetFont(DB().healthbar.font, DB().healthbar.fontSize, 'THINOUTLINE')
    bar.Text:SetShadowOffset(0, 0)
else
    bar.Text:SetFont(DB().healthbar.font, DB().healthbar.fontSize)
    bar.Text:SetShadowOffset(1, -1)
end

local function ColorGradient(perc, ...)
    if perc >= 1 then
        local r, g, b = select(select('#', ...) - 2, ...)
        return r, g, b
    elseif perc <= 0 then
        local r, g, b = ...
        return r, g, b
    end

    local num = select('#', ...) / 3
    local segment, relperc = math.modf(perc*(num-1))
    local r1, g1, b1, r2, g2, b2 = select((segment*3)+1, ...)

    return r1 + (r2-r1)*relperc,
           g1 + (g2-g1)*relperc,
           b1 + (b2-b1)*relperc
end

local function FormatValue(value)
    if value >= 1e6 then
        return tonumber(format('%.1f', value/1e6))..'m'
    elseif value >= 1e3 then
        return tonumber(format('%.1f', value/1e3))..'k'
    end
    return value
end

local function DeficitValue(value)
    return value == 0 and '' or '-'..FormatValue(value)
end

local function GetHealthTag(text, cur, max)
    local perc = format('%d', (cur/max)*100)
    if max == 1 then return perc end

    local r, g, b = ColorGradient(cur/max, 1,0,0, 1,1,0, 0,1,0)

    text = text:gsub('$cur', FormatValue(cur))
    text = text:gsub('$max', FormatValue(max))
    text = text:gsub('$deficit', DeficitValue(max-cur))
    text = text:gsub('$perc', perc..'%%')
    text = text:gsub('$smartperc', perc)
    text = text:gsub('$smartcolorperc', format('|cff%02x%02x%02x%d|r', r*255, g*255, b*255, perc))
    text = text:gsub('$colorperc', format('|cff%02x%02x%02x%d%%|r', r*255, g*255, b*255, perc))

    return text
end

GameTooltipStatusBar:HookScript('OnValueChanged', function(self, value)
    if not value then return end

    local min, max = self:GetMinMaxValues()
    if value < min or value > max or value == 0 or value == 1 then return end

    local fullString = GetHealthTag(DB().healthbar.healthFullFormat, value, max)
    local normalString = GetHealthTag(DB().healthbar.healthFormat, value, max)

    local perc = (value/max)*100
    if perc >= 100 then
        self.Text:SetText(fullString)
    else
        self.Text:SetText(normalString)
    end
end)

--------------------------------------------------------------
-- Buff Tooltip Border Coloring
--------------------------------------------------------------
local function StyleBuffTooltip(self, unit, index, filter)
    local r, g, b = GameTooltip_UnitColor(unit)
    self:SetBackdropBorderColor(r, g, b)
end

hooksecurefunc(GameTooltip, "SetUnitBuff", StyleBuffTooltip)
hooksecurefunc(GameTooltip, "SetUnitDebuff", StyleBuffTooltip)
hooksecurefunc(GameTooltip, "SetUnitAura", StyleBuffTooltip)

--============================================================
-- SECTION 5: Lifecycle + Registration
--============================================================
function M:OnInit()
    -- This is now handled by BasicUI:RegisterModule
    -- But we add a safety check here
    if not self.db then self.db = {} end
end

function M:OnLoadScreen()
    -- Ensure db is pointing to the right place
    local db = self.db or (BasicConfig and BasicConfig.Tooltip) or {}

    -- Apply fonts
    ApplyTooltipFonts(db)

    -- Style tooltips
    for _, tooltip in pairs({
        GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2, ShoppingTooltip3,
        WorldMapTooltip, DropDownList1MenuBackdrop, DropDownList2MenuBackdrop,
        ConsolidatedBuffsTooltip, ChatMenu, EmoteMenu, LanguageMenu,
        VoiceMacroMenu, FriendsTooltip, PetBuffTooltip, PlayerBuffTooltip,
    }) do
        ApplyTooltipStyle(tooltip, db)
    end
end

-- This triggers the registration and the OnInit call
BasicUI:RegisterModule(MODULE_NAME, M)


