--============================================================
-- MODULE: ItemScore (FINAL + OPTIONS + ADAPTIVE)
--============================================================

local addonName, BasicUI = ...

BasicUI.ItemScore = BasicUI.ItemScore or {}
local M = BasicUI.ItemScore

--============================================================
-- DEFAULTS
--============================================================

M.defaults = {
    enabled = true,
    showTooltip = true,
    showPercent = true,
    showBreakdown = true,
    enableHeirloomScaling = true,

    ignoreTrash = true,
    specFilter = true,
}

--============================================================
-- INIT
--============================================================

function M:OnInit()
    BasicDB = BasicDB or {}
    BasicDB.ItemScore = BasicDB.ItemScore or {}

    self.db = BasicDB.ItemScore

    for k,v in pairs(self.defaults) do
        if self.db[k] == nil then
            self.db[k] = v
        end
    end
end

--============================================================
-- TOOLTIP SCANNER
--============================================================

local scanTip = CreateFrame("GameTooltip", "BasicUIItemScoreScanner", nil, "GameTooltipTemplate")
scanTip:SetOwner(UIParent, "ANCHOR_NONE")

--============================================================
-- 🚫 TOOL FILTER
--============================================================

local function IsProfessionTool(link)
    if not link then return false end

    local name = GetItemInfo(link)
    if not name then return false end

    name = name:lower()

    if name == "blacksmith hammer" then return true end
    if name == "mining pick" then return true end
    if name == "skinning knife" then return true end
	if name == "lumber axe" then return true end
    if name:find("fishing pole") then return true end

    scanTip:ClearLines()
    scanTip:SetHyperlink(link)

    for i = 1, scanTip:NumLines() do
        local left = _G["BasicUIItemScoreScannerTextLeft"..i]
        if left then
            local text = left:GetText()
            if text then
                text = text:lower()

                if text:find("fishing skill") then return true end
                if text:find("mining") then return true end
                if text:find("skinning") then return true end
                if text:find("blacksmith") then return true end
                if text:find("cutting down trees") then return true end
            end
        end
    end

    return false
end

--============================================================
-- 🧠 TRUE SPEC DETECTION (ASCENSION TALENTS)
--============================================================
local function GetPlayerSpec()

    if not C_CharacterAdvancement or not C_CharacterAdvancement.GetKnownTalentEntries then
        return UnitClass("player") or "Unknown"
    end

    local entries = C_CharacterAdvancement.GetKnownTalentEntries()

    if not entries or #entries == 0 then
        return UnitClass("player") or "Unknown"
    end

    local tabCounts = {}

    for _, entry in ipairs(entries) do
        if entry.Tab then
            tabCounts[entry.Tab] = (tabCounts[entry.Tab] or 0) + 1
        end
    end

    local maxCount = 0
    local primaryTab = nil

    for tab, count in pairs(tabCounts) do
        if count > maxCount then
            maxCount = count
            primaryTab = tab
        end
    end

    if primaryTab then
        return primaryTab:gsub("(%u)", " %1"):gsub("^%s+", ""), tabCounts
    end

    return UnitClass("player") or "Unknown", tabCounts
end

--============================================================
-- 🔁 FALLBACK (STAT-BASED)
--============================================================
function M:GetAdaptiveWeights()
    local str = UnitStat("player", 1)
    local agi = UnitStat("player", 2)
    local intl = UnitStat("player", 4)

    if str >= agi and str >= intl then
        return { STR=3.0, CRIT=2.0, HASTE=1.6, HIT=2.0, STAM=0.5 }
    elseif agi >= str and agi >= intl then
        return { AGI=3.0, CRIT=2.2, HASTE=1.8, HIT=2.0, STAM=0.5 }
    else
        return { INT=3.5, CRIT=1.6, HASTE=2.2, HIT=2.0, STAM=0.5 }
    end
end

--============================================================
-- 🎯 SPEC-BASED WEIGHTS
--============================================================
function M:GetSpecWeights()

    local spec = GetPlayerSpec()
	
    -- 🔧 normalize spec string
    if spec then
        spec = spec:gsub("%s+", " ")
    end

    local weights = {

        --====================================================
        -- 🛡 WARRIOR
        --====================================================
        ["Arms"]        = { STR=3.2, CRIT=2.2, HASTE=1.6 },
        ["Fury"]        = { STR=3.0, HASTE=2.2, CRIT=2.0 },
        ["Protection Warrior"] = { STR=2.0, STAM=2.5, HASTE=1.5 },

        --====================================================
        -- 🛡 PALADIN
        --====================================================
        ["Retribution"] = { STR=3.2, CRIT=2.2, HASTE=1.8 },
        ["Holy"]        = { INT=3.5, HASTE=2.2, CRIT=1.6 },
        ["Protection"]  = { STR=2.0, STAM=2.5, HASTE=1.5 },

        --====================================================
        -- 🌿 DRUID
        --====================================================
        ["Feral"]       = { AGI=3.2, CRIT=2.3, HASTE=1.8 },
        ["Balance"]     = { INT=3.5, HASTE=2.2, CRIT=1.6 },
        ["Restoration"] = { INT=3.5, HASTE=2.0 },

        --====================================================
        -- ⚡ SHAMAN
        --====================================================
        ["Enhancement"] = { AGI=3.0, STR=2.0, HASTE=2.0 },
        ["Elemental"]   = { INT=3.5, HASTE=2.2 },
        ["Restoration Shaman"] = { INT=3.5, HASTE=2.0 },

        --====================================================
        -- 🗡 ROGUE
        --====================================================
        ["Assassination"] = { AGI=3.2, CRIT=2.3 },
        ["Outlaw"]        = { AGI=3.0, HASTE=2.0 },
        ["Subtlety"]      = { AGI=3.2, CRIT=2.2 },

        --====================================================
        -- 🏹 HUNTER
        --====================================================
        ["Beast Mastery"] = { AGI=3.2, CRIT=2.2, HASTE=1.8 },
        ["Marksmanship"]  = { AGI=3.4, CRIT=2.4 },
        ["Survival"]      = { AGI=3.0, HASTE=2.0 },

        --====================================================
        -- 🔥 MAGE
        --====================================================
        ["Fire"]   = { INT=3.5, CRIT=2.4 },
        ["Frost"]  = { INT=3.5, HASTE=2.2 },
        ["Arcane"] = { INT=3.5, HASTE=2.2 },

        --====================================================
        -- ☠️ WARLOCK
        --====================================================
        ["Affliction"] = { INT=3.5, HASTE=2.2 },
        ["Demonology"] = { INT=3.5, HASTE=2.0 },
        ["Destruction"] = { INT=3.5, CRIT=2.2 },

        --====================================================
        -- ✝️ PRIEST
        --====================================================
        ["Shadow"]     = { INT=3.5, HASTE=2.2 },
        ["Discipline"] = { INT=3.5, HASTE=2.0 },
        ["Holy Priest"] = { INT=3.5, HASTE=2.0 },

        --====================================================
        -- 💀 DEATH KNIGHT
        --====================================================
        ["Blood"]  = { STR=2.5, STAM=2.5 },
        ["Frost DK"]  = { STR=3.2, HASTE=2.2 },
        ["Unholy"] = { STR=3.0, HASTE=2.0 },

        --====================================================
        -- 🐼 MONK
        --====================================================
        ["Windwalker"] = { AGI=3.2, CRIT=2.2 },
        ["Brewmaster"] = { AGI=2.5, STAM=2.5 },
        ["Mistweaver"] = { INT=3.5, HASTE=2.0 },

        --====================================================
        -- 😈 DEMON HUNTER
        --====================================================
        ["Havoc"] = { AGI=3.4, CRIT=2.3 },
        ["Vengeance"] = { AGI=2.5, STAM=2.5 },

        --====================================================
        -- 💀 FALLBACK (VERY IMPORTANT)
        --====================================================
        ["Unknown"] = self:GetAdaptiveWeights(),
    }

    return weights[spec] or weights["Unknown"]
end

--============================================================
-- 🚫 SPEC FILTER
--============================================================

function M:IsItemValidForSpec(link)
    local weights = self:GetSpecWeights()
    local class = select(2, UnitClass("player"))

    scanTip:ClearLines()
    scanTip:SetHyperlink(link)

    for i = 1, scanTip:NumLines() do
        local right = _G["BasicUIItemScoreScannerTextRight"..i]
        if right then
            local text = right:GetText()
            if text then
                text = text:lower()

                if text == "wand" then return weights.INT and weights.INT > 1 end
                if text == "gun" or text == "bow" or text == "crossbow" then return weights.AGI and weights.AGI > 1 end

                if text == "libram" then return class == "PALADIN" end
                if text == "totem" then return class == "SHAMAN" end
                if text == "idol" then return class == "DRUID" end
                if text == "sigil" then return class == "DEATHKNIGHT" end
            end
        end
    end

    return true
end

--============================================================
-- 📊 SCORE
--============================================================

function M:GetItemScore(link)
    if not link then return 0 end

    local stats = GetItemStats(link)
    if not stats then return 0 end

    local itemInfo = { GetItemInfo(link) }
    local quality = itemInfo[3]

    if IsProfessionTool(link) then return 0 end
    if self.db.specFilter and not self:IsItemValidForSpec(link) then return 0 end

    local weights = self:GetAdaptiveWeights()
    local score = 0

    for stat, val in pairs(stats) do
        if stat == "ITEM_MOD_STRENGTH_SHORT" then score = score + val * (weights.STR or 0)
        elseif stat == "ITEM_MOD_AGILITY_SHORT" then score = score + val * (weights.AGI or 0)
        elseif stat == "ITEM_MOD_INTELLECT_SHORT" then score = score + val * (weights.INT or 0)
        elseif stat == "ITEM_MOD_STAMINA_SHORT" then score = score + val * (weights.STAM or 0)
        elseif stat:find("CRIT") then score = score + val * (weights.CRIT or 0)
        elseif stat:find("HASTE") then score = score + val * (weights.HASTE or 0)
        elseif stat:find("HIT") then score = score + val * (weights.HIT or 0)
        end
    end

    -- 👑 Heirloom fix
    if self.db.enableHeirloomScaling and quality == 7 and UnitLevel("player") < 60 then
        score = score + 100
    end

    return score
end

--============================================================
-- TOOLTIP
--============================================================

local function AddTooltip(tooltip)
    if not M.db.enabled or not M.db.showTooltip then return end

    local _, link = tooltip:GetItem()
    if not link then return end

    if IsProfessionTool(link) then return end

    local itemInfo = { GetItemInfo(link) }
    local quality = itemInfo[3]
    local equipLoc = itemInfo[9]
    if not equipLoc then return end

    -- 🚫 trash filter
    if M.db.ignoreTrash and quality and quality <= 1 then
        return
    end

    -- 🚫 spec filter
    if M.db.specFilter and not M:IsItemValidForSpec(link) then
        tooltip:AddLine(" ")
        tooltip:AddLine("|cffff5555This item is not for your class/spec|r")
		tooltip:AddLine(" ")
        return
    end

    local upgrades = BasicUI.ItemScore.Upgrades
    if not upgrades then return end

    local result = upgrades:GetUpgradePercent(link)
    if result == nil then return end

    local breakdown = upgrades:GetUpgradeBreakdown(link)

	tooltip:AddLine(" ")
	tooltip:AddLine("|cff66ccffBasicUI Item Score|r")

    -- 💍 breakdown
    if breakdown and M.db.showBreakdown then
        local slotName = upgrades:GetSlotName(equipLoc)

        for i, p in ipairs(breakdown) do
            local color = p > 0 and "|cff00ff00" or "|cffff0000"
            local label = p > 0 and "Upgrade" or "Downgrade"

            if p == 0 then
                color = "|cffffff00"
                label = "Equal"
            end

            tooltip:AddDoubleLine(
                slotName.." "..i..":",
                color..label.." "..math.floor(math.abs(p)).."%|r"
            )
        end
		tooltip:AddLine(" ")

        return
    end

    -- normal display
    if result > -2 and result < 2 then result = 0 end

    if result == 0 then
        tooltip:AddLine("|cffffff00Equal to current gear|r")
		tooltip:AddLine(" ")
    elseif result > 0 then
        tooltip:AddLine("|cff00ff00This item is a "..math.floor(result).."% Upgrade|r")
		tooltip:AddLine(" ")
    else
        tooltip:AddLine("|cffff0000This item is a "..math.floor(-result).."% Downgrade|r")
		tooltip:AddLine(" ")
    end
	
end

--============================================================
-- ENABLE
--============================================================

function M:OnEnable()
    GameTooltip:HookScript("OnTooltipSetItem", AddTooltip)
end

--============================================================
-- OPTIONS (ACE3)
--============================================================

local function ISDisabled()
    return not M.db.enabled
end

M.options = {
    type = "group",
    name = "Item Score",
    args = {

        enabled = {
            type = "toggle",
            name = "Enable ItemScore",
            order = 1,
            width = "full",
            get = function() return M.db.enabled end,
            set = function(_, v) M.db.enabled = v end,
        },

        general = {
            type = "group",
            name = "General",
            inline = true,
            order = 2,
            disabled = ISDisabled,
            args = {

                showTooltip = {
                    type = "toggle",
                    name = "Show Tooltip",
                    order = 1,
                    get = function() return M.db.showTooltip end,
                    set = function(_, v) M.db.showTooltip = v end,
                },

                showBreakdown = {
                    type = "toggle",
                    name = "Show Ring/Trinket Breakdown",
                    order = 2,
                    get = function() return M.db.showBreakdown end,
                    set = function(_, v) M.db.showBreakdown = v end,
                },
            },
        },

        filtering = {
            type = "group",
            name = "Filtering",
            inline = true,
            order = 3,
            disabled = ISDisabled,
            args = {

                ignoreTrash = {
                    type = "toggle",
                    name = "Ignore Grey/White Items",
                    order = 1,
                    get = function() return M.db.ignoreTrash end,
                    set = function(_, v) M.db.ignoreTrash = v end,
                },

                specFilter = {
                    type = "toggle",
                    name = "Filter Unusable Items",
                    order = 2,
                    get = function() return M.db.specFilter end,
                    set = function(_, v) M.db.specFilter = v end,
                },
            },
        },

        scoring = {
            type = "group",
            name = "Scoring",
            inline = true,
            order = 4,
            disabled = ISDisabled,
            args = {

                enableHeirloomScaling = {
                    type = "toggle",
                    name = "Heirlooms Strong Until 60",
                    order = 1,
                    get = function() return M.db.enableHeirloomScaling end,
                    set = function(_, v) M.db.enableHeirloomScaling = v end,
                },
            },
        },
    },
}

--============================================================
-- REGISTER
--============================================================

BasicUI:RegisterModule("ItemScore", M)