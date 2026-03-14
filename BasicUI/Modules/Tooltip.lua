--============================================================
-- MODULE: Tooltip
--============================================================
local addonName, BasicUI = ...
local MODULE_NAME = "Tooltip"
local M = {}

local db

local TOOLTIP_FRAMES = {
    GameTooltip,
    ItemRefTooltip,
    ShoppingTooltip1,
    ShoppingTooltip2,
    ShoppingTooltip3,
    WorldMapTooltip,
    DropDownList1MenuBackdrop,
    DropDownList2MenuBackdrop,
    ConsolidatedBuffsTooltip,
    ChatMenu,
    EmoteMenu,
    LanguageMenu,
    VoiceMacroMenu,
    FriendsTooltip,
    PetBuffTooltip,
    PlayerBuffTooltip,
}

--============================================================
-- SECTION 1: Defaults (cfg → M.defaults)
--============================================================
M.defaults = {
    enabled = true,

	font = BasicUI:GetBasicFont("N"),
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
        font = BasicUI:GetBasicFont("N"),
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
    [3] = {r = 1, g = 0, b = 0},
    [4] = {r = 1, g = 1, b = 0},
    [5] = {r = 0, g = 1, b = 0},
    [6] = {r = 0, g = 1, b = 0},
    [7] = {r = 0, g = 1, b = 0},
    [8] = {r = 0, g = 1, b = 0},
}

function GameTooltip_UnitColor(unit)
    return BasicUI:GetUnitColor(unit)
end

--============================================================
-- Tooltip Font Setup
--============================================================
function ApplyTooltipFonts(db)

    if not db or not db.enabled then return end

    if db.fontOutline then

        GameTooltipText:SetFont(db.font, db.fontSize, 'THINOUTLINE')
        GameTooltipText:SetShadowOffset(0, 0)

        GameTooltipTextSmall:SetFont(db.font, db.fontSize, 'THINOUTLINE')
        GameTooltipTextSmall:SetShadowOffset(0, 0)

    else

        GameTooltipText:SetFont(db.font, db.fontSize)
        GameTooltipTextSmall:SetFont(db.font, db.fontSize)

    end

end

--============================================================
-- SECTION 3: Item Quality Border Coloring
--============================================================
function M:SetupItemQualityBorder()

    if not db.itemqualityBorderColor then return end

    for _, tooltip in pairs({
        GameTooltip,
        ItemRefTooltip,
        ShoppingTooltip1,
        ShoppingTooltip2,
        ShoppingTooltip3,
    }) do
        tooltip:HookScript("OnTooltipSetItem", function(self)
            local name, item = self:GetItem()
            if item then
                local quality = select(3, GetItemInfo(item))
                if quality then
                    local r, g, b = GetItemQualityColor(quality)
                    self:SetBackdropBorderColor(r, g, b)
                end
            end
        end)

        tooltip:HookScript("OnTooltipCleared", function(self)
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
            .. (db.showSpecializationIcon and specIcon or '')
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

    if db.healthbar.customColor.apply and not db.healthbar.reactionColoring then
        r = db.healthbar.customColor.r
        g = db.healthbar.customColor.g
        b = db.healthbar.customColor.b

    elseif db.healthbar.reactionColoring and unit then
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
        return db.showPVPIcons
            and '|TInterface\\AddOns\\cTooltip\\Media\\UI-PVP-FFA:12|t'
            or '|cffFF0000# |r'

    elseif faction and UnitIsPVP(unit) then
        return db.showPVPIcons
            and '|TInterface\\AddOns\\cTooltip\\Media\\UI-PVP-'..faction..':12|t'
            or '|cff00FF00# |r'
    end

    return ''
end

--============================================================
-- Tooltip Unit Hook
--============================================================
function M:SetupUnitTooltipHook()

    GameTooltip.inspectCache = {}

    GameTooltip:HookScript("OnTooltipSetUnit", function(self)

        if not db or not db.enabled then return end

        local unit = GetRealUnit(self)

        if db.hideInCombat and InCombatLockdown() then
            self:Hide()
            return
        end

        if UnitExists(unit) and UnitName(unit) ~= UNKNOWN then
            local ilvl = 0
            local specIcon = ""
            local lastUpdate = 30

            for _, cache in pairs(self.inspectCache) do
                if cache.GUID == UnitGUID(unit) then
                    ilvl = cache.itemLevel or 0
                    specIcon = cache.specIcon or ""
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
            local r, g, b = GameTooltip_UnitColor(unit)

            if db.showPlayerTitles and UnitPVPName(unit) then
                name = UnitPVPName(unit)
            end

            GameTooltipTextLeft1:SetText(name)
            GameTooltipTextLeft1:SetTextColor(r, g, b)

            local guildName = GetGuildInfo(unit)
            if guildName then
                GameTooltipTextLeft2:SetText("|cffFF66CC"..GameTooltipTextLeft2:GetText().."|r")
            end

            for i = 2, GameTooltip:NumLines() do
                local line = _G["GameTooltipTextLeft"..i]
                if line:GetText() and line:GetText():find("^"..TOOLTIP_UNIT_LEVEL:gsub("%%s", ".+")) then
                    line:SetText(GetFormattedUnitString(unit, specIcon))
                end
            end

            if db.showUnitRole then
                self:AddLine(GetUnitRoleString(unit), 1, 1, 1)
            end

            if db.showMouseoverTarget then
                AddMouseoverTarget(self, unit)
            end

            for i = 3, GameTooltip:NumLines() do
                local line = _G["GameTooltipTextLeft"..i]
                if line:GetText() and line:GetText():find(PVP_ENABLED) then
                    line:SetText(nil)
                    GameTooltipTextLeft1:SetText(GetUnitPVPIcon(unit)..GameTooltipTextLeft1:GetText())
                end
            end

            GameTooltipTextLeft1:SetText(GetUnitRaidIcon(unit)..GameTooltipTextLeft1:GetText())

            if UnitIsAFK(unit) then
                self:AppendText("|cff00ff00 <AFK>|r")
            elseif UnitIsDND(unit) then
                self:AppendText("|cff00ff00 <DND>|r")
            end

            if realm and realm ~= "" then
                if db.abbrevRealmNames then
                    self:AppendText(" (*)")
                else
                    self:AppendText(" - "..realm)
                end
            end

            if GameTooltipStatusBar:IsShown() then
                self:AddLine(" ")
                GameTooltipStatusBar:ClearAllPoints()
                GameTooltipStatusBar:SetPoint("LEFT", self:GetName().."TextLeft"..self:NumLines(), 1, -3)
                GameTooltipStatusBar:SetPoint("RIGHT", self, -10, 0)
            end

            if db.reactionBorderColor then
                self:SetBackdropBorderColor(r, g, b)
            end

            if UnitIsDead(unit) or UnitIsGhost(unit) then
                GameTooltipStatusBar:SetBackdropColor(0.5, 0.5, 0.5, 0.3)
            else
                if not db.healthbar.customColor.apply and not db.healthbar.reactionColoring then
                    GameTooltipStatusBar:SetBackdropColor(27/255, 243/255, 27/255, 0.3)
                else
                    SetHealthBarColor(unit)
                end
            end
        end

    end)

end

--============================================================
-- Tooltip Cleared & Healthbar Logic
--============================================================
function M:SetupTooltipClearedHook()

    GameTooltip:HookScript("OnTooltipCleared", function(self)

        local bar = GameTooltipStatusBar

        bar:ClearAllPoints()
        bar:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0.5, 3)
        bar:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", -1, 3)
        bar:SetBackdropColor(0, 1, 0, 0.3)

        if db.reactionBorderColor then
            self:SetBackdropBorderColor(1, 1, 1)
        end

    end)

end

--------------------------------------------------------------
-- Healthbar Text
--------------------------------------------------------------
function M:SetupHealthBarText()

    if not db.healthbar then return end

    local bar = GameTooltipStatusBar

    if not bar.Text then
        bar.Text = bar:CreateFontString(nil, "OVERLAY")
    end

    bar.Text:SetPoint("CENTER", bar, db.healthbar.textPos, 0, 1)

    if db.healthbar.showOutline then
        bar.Text:SetFont(db.healthbar.font, db.healthbar.fontSize, "THINOUTLINE")
        bar.Text:SetShadowOffset(0, 0)
    else
        bar.Text:SetFont(db.healthbar.font, db.healthbar.fontSize)
        bar.Text:SetShadowOffset(1, -1)
    end

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

function M:SetupHealthBarHook()

    local bar = GameTooltipStatusBar

    if self.healthBarHooked then return end
    self.healthBarHooked = true

    bar:HookScript("OnValueChanged", function(self, value)

        if not db or not db.enabled or not value then return end

        local min, max = self:GetMinMaxValues()
        if value < min or value > max or value == 0 or value == 1 then return end

        local fullString = GetHealthTag(db.healthbar.healthFullFormat, value, max)
        local normalString = GetHealthTag(db.healthbar.healthFormat, value, max)

        local perc = (value / max) * 100

        if perc >= 100 then
            self.Text:SetText(fullString)
        else
            self.Text:SetText(normalString)
        end

    end)

end

--------------------------------------------------------------
-- Buff Tooltip Border Coloring
--------------------------------------------------------------
local function StyleBuffTooltip(self, unit, index, filter)

    if not db or not db.enabled then return end
	
    local r, g, b = GameTooltip_UnitColor(unit)
    self:SetBackdropBorderColor(r, g, b)
end

--============================================================
-- Tooltip Backdrop Styling
--============================================================
function ApplyTooltipStyle(self, db)

    if not db or not db.enabled then return end

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
        tile = true,
        tileSize = 16,
        edgeSize = 18,
        insets = {
            left = bgsize,
            right = bgsize,
            top = bgsize,
            bottom = bgsize
        }
    })

    self:HookScript("OnShow", function(self)
        self:SetBackdropColor(0, 0, 0, db.bgDarkness or 1)
    end)

end

function M:SetupHooks()

    if self.hooked then return end

    hooksecurefunc(GameTooltip, "SetUnitBuff", StyleBuffTooltip)
    hooksecurefunc(GameTooltip, "SetUnitDebuff", StyleBuffTooltip)
    hooksecurefunc(GameTooltip, "SetUnitAura", StyleBuffTooltip)

    hooksecurefunc("TargetFrame_CheckFaction", function(self)

		if not db or not db.enabled then return end
		
        if UnitPlayerControlled(self.unit) then
            self.nameBackground:SetVertexColor(GameTooltip_UnitColor(self.unit))
        end
    end)

    self.hooked = true

end

--============================================================
-- SECTION 5: Lifecycle + Registration
--============================================================
function M:OnInit()

    BasicDB = BasicDB or {}
    BasicDB.Tooltip = BasicDB.Tooltip or {}

    self.db = BasicDB.Tooltip
    db = self.db

    BasicUI:CopyDefaults(self.defaults, self.db)

    if not db.enabled then
        return
    end

    ------------------------------------------------
    -- Setup Tooltip Features
    ------------------------------------------------
    self:SetupItemQualityBorder()
    self:SetupHealthBarText()
    self:SetupTooltipClearedHook()
    self:SetupUnitTooltipHook()
    self:SetupHealthBarHook()

end

function M:OnLoadScreen()

    db = self.db or {}

    ApplyTooltipFonts(db)

	for _, tooltip in ipairs(TOOLTIP_FRAMES) do
		if tooltip then
			ApplyTooltipStyle(tooltip, db)
		end
	end

end

local function TooltipDisabled()
    return not M.db.enabled
end

--============================================================
-- OPTIONS
--============================================================

M.options = {
    type = "group",
    name = "Tooltip",
    args = {

        enabled = {
            type = "toggle",
            name = "Enable Tooltip Styling",
            desc = "Enable BasicUI styling and enhancements for game tooltips.",
            order = 1,
			width = "full",
            get = function() return M.db.enabled end,
            set = function(_, v)
                M.db.enabled = v
                BasicUI:RequestReload()
            end,
        },

        ------------------------------------------------
        -- Appearance
        ------------------------------------------------

        appearance = {
            type = "group",
            name = "Appearance",
            inline = true,
            order = 2,
			disabled = TooltipDisabled,
            args = {

                fontSize = {
                    type = "range",
                    name = "Tooltip Font Size",
                    desc = "Adjust the font size used in tooltips.",
                    min = 8, max = 32, step = 1,
                    order = 1,
                    get = function() return M.db.fontSize end,
                    set = function(_, v)
                        M.db.fontSize = v
                        BasicUI:RequestReload()
                    end,
                },

                fontOutline = {
                    type = "toggle",
                    name = "Font Outline",
                    desc = "Enable an outline on tooltip text for improved readability.",
                    order = 2,
                    get = function() return M.db.fontOutline end,
                    set = function(_, v)
                        M.db.fontOutline = v
                        BasicUI:RequestReload()
                    end,
                },

                bgDarkness = {
                    type = "range",
                    name = "Background Darkness",
                    desc = "Adjust how dark the tooltip background appears.",
                    min = 0,
                    max = 1,
                    step = 0.05,
                    order = 3,
                    get = function() return M.db.bgDarkness end,
                    set = function(_, v)
                        M.db.bgDarkness = v
                        BasicUI:RequestReload()
                    end,
                },

                reactionBorderColor = {
                    type = "toggle",
                    name = "Reaction Border Color",
                    desc = "Color the tooltip border based on the unit's reaction.",
                    order = 4,
                    get = function() return M.db.reactionBorderColor end,
                    set = function(_, v)
                        M.db.reactionBorderColor = v
                        BasicUI:RequestReload()
                    end,
                },

                itemqualityBorderColor = {
                    type = "toggle",
                    name = "Item Quality Border",
                    desc = "Color the tooltip border based on item quality.",
                    order = 5,
                    get = function() return M.db.itemqualityBorderColor end,
                    set = function(_, v)
                        M.db.itemqualityBorderColor = v
                        BasicUI:RequestReload()
                    end,
                },

            },
        },

        ------------------------------------------------
        -- Behavior
        ------------------------------------------------

        behavior = {
            type = "group",
            name = "Behavior",
            inline = true,
            order = 3,
			disabled = TooltipDisabled,
            args = {

                showOnMouseover = {
                    type = "toggle",
                    name = "Anchor to Mouse",
                    desc = "Display the tooltip at the mouse cursor instead of the default anchor.",
                    order = 1,
                    get = function() return M.db.showOnMouseover end,
                    set = function(_, v)
                        M.db.showOnMouseover = v
                        BasicUI:RequestReload()
                    end,
                },

                hideInCombat = {
                    type = "toggle",
                    name = "Hide in Combat",
                    desc = "Hide tooltips while you are in combat.",
                    order = 2,
                    get = function() return M.db.hideInCombat end,
                    set = function(_, v)
                        M.db.hideInCombat = v
                        BasicUI:RequestReload()
                    end,
                },

            },
        },

        ------------------------------------------------
        -- Information
        ------------------------------------------------

        information = {
            type = "group",
            name = "Information",
            inline = true,
            order = 4,
			disabled = TooltipDisabled,
            args = {

                abbrevRealmNames = {
                    type = "toggle",
                    name = "Abbreviate Realm Names",
                    desc = "Shorten realm names when displaying player information.",
                    order = 1,
                    get = function() return M.db.abbrevRealmNames end,
                    set = function(_, v)
                        M.db.abbrevRealmNames = v
                        BasicUI:RequestReload()
                    end,
                },

                hideRealmText = {
                    type = "toggle",
                    name = "Hide Realm Names",
                    desc = "Hide the realm name portion of player names.",
                    order = 2,
                    get = function() return M.db.hideRealmText end,
                    set = function(_, v)
                        M.db.hideRealmText = v
                        BasicUI:RequestReload()
                    end,
                },

                showPlayerTitles = {
                    type = "toggle",
                    name = "Show Player Titles",
                    desc = "Display player titles in tooltips.",
                    order = 3,
                    get = function() return M.db.showPlayerTitles end,
                    set = function(_, v)
                        M.db.showPlayerTitles = v
                        BasicUI:RequestReload()
                    end,
                },

                showUnitRole = {
                    type = "toggle",
                    name = "Show Unit Role",
                    desc = "Display the group role (tank, healer, damage) in the tooltip.",
                    order = 4,
                    get = function() return M.db.showUnitRole end,
                    set = function(_, v)
                        M.db.showUnitRole = v
                        BasicUI:RequestReload()
                    end,
                },

                showPVPIcons = {
                    type = "toggle",
                    name = "Show PvP Icons",
                    desc = "Display PvP faction icons for players.",
                    order = 5,
                    get = function() return M.db.showPVPIcons end,
                    set = function(_, v)
                        M.db.showPVPIcons = v
                        BasicUI:RequestReload()
                    end,
                },

                showMouseoverTarget = {
                    type = "toggle",
                    name = "Show Mouseover Target",
                    desc = "Display the target of the unit currently being hovered.",
                    order = 6,
                    get = function() return M.db.showMouseoverTarget end,
                    set = function(_, v)
                        M.db.showMouseoverTarget = v
                        BasicUI:RequestReload()
                    end,
                },

                showSpecializationIcon = {
                    type = "toggle",
                    name = "Show Specialization Icon",
                    desc = "Display the player's specialization icon.",
                    order = 7,
                    get = function() return M.db.showSpecializationIcon end,
                    set = function(_, v)
                        M.db.showSpecializationIcon = v
                        BasicUI:RequestReload()
                    end,
                },

                showItemLevel = {
                    type = "toggle",
                    name = "Show Item Level",
                    desc = "Display the item level in item tooltips.",
                    order = 8,
                    get = function() return M.db.showItemLevel end,
                    set = function(_, v)
                        M.db.showItemLevel = v
                        BasicUI:RequestReload()
                    end,
                },

            },
        },

        ------------------------------------------------
        -- Health Bar
        ------------------------------------------------

        healthbar = {
            type = "group",
            name = "Health Bar",
            inline = true,
            order = 5,
			disabled = TooltipDisabled,
            args = {

                fontSize = {
                    type = "range",
                    name = "Health Text Size",
                    desc = "Adjust the font size of the tooltip health text.",
                    min = 8, max = 32, step = 1,
                    order = 1,
                    get = function() return M.db.healthbar.fontSize end,
                    set = function(_, v)
                        M.db.healthbar.fontSize = v
                        BasicUI:RequestReload()
                    end,
                },

                showOutline = {
                    type = "toggle",
                    name = "Health Text Outline",
                    desc = "Enable an outline on tooltip health text.",
                    order = 2,
                    get = function() return M.db.healthbar.showOutline end,
                    set = function(_, v)
                        M.db.healthbar.showOutline = v
                        BasicUI:RequestReload()
                    end,
                },

                reactionColoring = {
                    type = "toggle",
                    name = "Reaction Health Coloring",
                    desc = "Color the health bar based on the unit's reaction.",
                    order = 3,
                    get = function() return M.db.healthbar.reactionColoring end,
                    set = function(_, v)
                        M.db.healthbar.reactionColoring = v
                        BasicUI:RequestReload()
                    end,
                },

                apply = {
                    type = "toggle",
                    name = "Enable Custom Health Color",
                    desc = "Apply a custom color to the tooltip health bar.",
                    order = 4,
                    get = function() return M.db.healthbar.customColor.apply end,
                    set = function(_, v)
                        M.db.healthbar.customColor.apply = v
                        BasicUI:RequestReload()
                    end,
                },

                color = {
                    type = "color",
                    name = "Custom Health Color",
                    desc = "Choose a custom color for the tooltip health bar.",
                    order = 5,
                    get = function()
                        local c = M.db.healthbar.customColor
                        return c.r, c.g, c.b
                    end,
                    set = function(_, r, g, b)
                        local c = M.db.healthbar.customColor
                        c.r, c.g, c.b = r, g, b
                        BasicUI:RequestReload()
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