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

function M:GetAdvancedSpec()

    local baseSpec = GetPlayerSpec()
    local _, class = UnitClass("player")

    --====================================================
    -- 🐻 DRUID: FERAL SPLIT
    --====================================================
    if class == "DRUID" and baseSpec == "Feral" then

        if C_CharacterAdvancement and C_CharacterAdvancement.GetKnownTalentEntries then

            local entries = C_CharacterAdvancement.GetKnownTalentEntries()

            if entries then
                for _, entry in ipairs(entries) do

                    -- Talent name check
                    if entry.Name then
                        local name = entry.Name:lower()

                        if name:find("thick hide") then
                            return "Feral Guardian"
                        end
                    end

                    -- SpellID fallback
                    if entry.SpellID then
                        local spellName = GetSpellInfo(entry.SpellID)
                        if spellName and spellName:lower():find("thick hide") then
                            return "Feral Guardian"
                        end
                    end
                end
            end
        end

        return "Feral DPS"
    end

	--====================================================
	-- ⚡ SHAMAN: ENHANCEMENT SPLIT (ASCENSION)
	--====================================================
	if class == "SHAMAN" and baseSpec == "Enhancement" then

		-- 🛡️ PRIMARY: Earthen Guardian aura (BEST SIGNAL)
		for i = 1, 40 do
			local buff = UnitBuff("player", i)
			if not buff then break end

			buff = buff:lower()

			if buff:find("earthen guardian") then
				return "Enhancement Tank"
			end
		end

		-- 🧠 SECONDARY: Talent fallback (optional safety)
		if C_CharacterAdvancement and C_CharacterAdvancement.GetKnownTalentEntries then

			local entries = C_CharacterAdvancement.GetKnownTalentEntries()

			if entries then
				for _, entry in ipairs(entries) do

					if entry.Name then
						local name = entry.Name:lower()

						if name:find("toughness") or name:find("shield specialization") then
							return "Enhancement Tank"
						end
					end

					if entry.SpellID then
						local spellName = GetSpellInfo(entry.SpellID)
						if spellName then
							spellName = spellName:lower()

							if spellName:find("toughness") then
								return "Enhancement Tank"
							end
						end
					end
				end
			end
		end

		-- ⚔️ DEFAULT
		return "Enhancement DPS"
	end

    --====================================================
    -- ✅ DEFAULT (ALL OTHER SPECS)
    --====================================================
    return baseSpec
end

--============================================================
-- 🎯 SPEC-BASED WEIGHTS
--============================================================
function M:GetSpecWeights()

    local spec = self:GetAdvancedSpec()

    if spec then
        spec = spec:gsub("%s+", " ")
    end

    local weights = {

        --====================================================
        -- 🌿 DRUID
        --====================================================

        ["Feral DPS"] = {
            AGI = 2,
            AP  = 1,
            HIT = .5,
            EXP = .5,
            CRIT = .6,
            HASTE = .4,
            ARPEN = 1,
            STR = 2,
            STAM = 0
        },

        ["Feral Guardian"] = {
            STAM = 3,
            AP = 1,
			STR = 1,
			ARMOR = .1,
			ARPEN = .5,
			EXP = .5,
            AGI = 2,
            DODGE = .9,
            DEF = 2,
        },

        ["Balance"] = {
            INT = .6,
            SP  = 1,
            HIT = .5,
            HASTE = .7,
            CRIT = .6,
            SPELLPEN = .5,
            SPIRIT = 0.3
        },

        ["Restoration"] = {
            INT = .1,
            SP  = 1,
			SPIRIT = .9,
            HASTE = .8,
            CRIT = .5,
            MP5 = 0,
            STAM = 0
        },

        --====================================================
        -- ⚔️ WARRIOR
        --====================================================

        ["Arms"] = {
            STR = 2,
			AGI = 1,
            AP  = 1,
            WEAPON_DPS = 14,
            HIT = .5,
            EXP = .5,
            CRIT = .5,
            HASTE = .5,
            ARPEN = 1
        },

        ["Fury"] = {
            STR = 2,
			AGI = 1,
            AP  = 1,
            WEAPON_DPS = 14,
            HIT = .5,
            EXP = .5,
            CRIT = .5,
            HASTE = .6,
            ARPEN = .5
        },

        ["Protection Warrior"] = {
            STAM = 2,
            ARMOR = .1,
            DEF = 1,
            DODGE = 1,
            PARRY = 1,
            BLOCK = 1,
            STR = 1,
			AGI = 1,
			ARPEN = .5,
			AP = 1,
			WEAPON_DPS = 14,
			CRIT = .2,
			HASTE = .2,
			HIT = .5
        },

        --====================================================
        -- 🛡 PALADIN
        --====================================================

        ["Retribution"] = {
            STR = 2.5,
            AP  = 1,
            WEAPON_DPS = 14,
            HIT = 1,
            EXP = .5,
            CRIT = 1,
            HASTE = .4,
			STR = 2.5,
			AGI = 1,
			AP = 1,
			SO = .7,
			ARPEN = .1,
			EXP = .5
        },

        ["Holy"] = {
            INT = 4,
            SP  = 1,
            CRIT = .4,
            HASTE = 1,
            MP5 = .2,
			SPIRIT = .5
        },

        ["Protection"] = {
            STAM = 2.5,
            ARMOR = .1,
            DEF = 2,
            DODGE = .5,
            PARRY = .5,
            BLOCK = 2,
            STR = 1,
			AGI = 1,
			AP = 1,
			WEAPON_DPS = 14,
			CRIT = .1,
			HASTE = .1,
			HIT = .5
        },

        --====================================================
        -- ⚡ SHAMAN
        --====================================================

        ["Enhancement"] = {
            AGI = 1,
            AP  = 1,
            WEAPON_DPS = 14,
            HIT = .5,
            EXP = .5,
            STR = 1,
            CRIT = .5,
            HASTE = .5,
			SP = .4
        },

        ["Elemental"] = {
            INT = .2,
            SP  = 1,
            HIT = .5,
            HASTE = 1,
            CRIT = .9,
            SPELLPEN = .5
        },

        ["Restoration Shaman"] = {
            INT = 1,
            SP  = 1,
            HASTE = .5,
            CRIT = .5,
            MP5 = .1,
			SPIRIT = .1
        },

        --====================================================
        -- 🗡 ROGUE
        --====================================================

        ["Assassination"] = {
            AGI = 2,
            AP  = 1,
            HIT = .5,
            EXP = .5,
            CRIT = .8,
            HASTE = .6,
			STR = 1,
			WEAPON_DPS = 14,
			ARPEN = .5
        },

        ["Outlaw"] = {
            AGI = 4.0,
            AP  = 3.5,
            WEAPON_DPS = 4.5,
            HIT = 3.2,
            EXP = 3.0,
            CRIT = 2.6,
            HASTE = 2.4
        },

        ["Subtlety"] = {
            AGI = 2,
            AP  = 1,
            HIT = .5,
            EXP = .5,
            CRIT = .7,
            HASTE = .6
        },

        --====================================================
        -- 🏹 HUNTER
        --====================================================

        ["Beast Mastery"] = {
            AGI = 2,
            AP  = 1,
            HIT = .5,
            CRIT = .5,
            HASTE = .4,
			STAM = .1,
			INT = .1,
			ARPEN = .5,
			WEAPON_DPS = 14
        },

        ["Marksmanship"] = {
            AGI = 2,
            AP  = 1,
            HIT = .5,
            CRIT = .8,
            HASTE = .5,
			STAM = .1,
			INT = 1.1,
			ARPEN = 1,
			WEAPON_DPS = 14
        },

        ["Survival"] = {
            AGI = 2.5,
            AP  = 1,
            HIT = .5,
            CRIT = .4,
            HASTE = .8,
			STAM = .1,
			INT = .1,
			STR = 1,
			WEAPON_DPS = 14,
			ARPEN = 1
        },

        --====================================================
        -- 🔥 MAGE
        --====================================================

        ["Fire"] = {
            INT = .1,
            SP  = 1,
            HIT = .5,
            HASTE = .6,
            CRIT = .9,
            SPELLPEN = .5,
			MP5 = .01
        },

        ["Frost"] = {
            INT = .1,
            SP  = 1,
            HIT = .5,
            HASTE = .8,
            CRIT = .5,
			MP5 = .01,
			SPELLPEN = .5
        },

        ["Arcane"] = {
            INT = .8,
            SP  = 1,
            HIT = .5,
            HASTE = .6,
            CRIT = .6,
			SPELLPEN = .5,
			MP5 = .05
        },

        --====================================================
        -- ☠️ WARLOCK
        --====================================================

        ["Affliction"] = {
            INT = .1,
            SP  = 1,
            HIT = .5,
            HASTE = 2,
            CRIT = .8
        },

        ["Demonology"] = {
            INT = .1,
            SP  = 1,
            HIT = .5,
            HASTE = .5,
            CRIT = .5,
			SPELLPEN = .5,
			SPIRIT = .5
        },

        ["Destruction"] = {
            INT = .1,
            SP  = 1,
            HIT = .5,
            CRIT = .7,
            HASTE = .8,
			SPELLPEN = .5
        },

        --====================================================
        -- ✝️ PRIEST
        --====================================================

        ["Shadow"] = {
            INT = .1,
            SP  = 1,
            HIT = .5,
            HASTE = .7,
            CRIT = .6,
			SPELLPEN = .5
        },

        ["Discipline"] = {
            INT = .4,
            SP  = 1,
            HASTE = .6,
            CRIT = .2,
            MP5 = .3,
			SPIRIT = .1
        },

        ["Holy Priest"] = {
            INT = .5,
            SP  = 1,
            HASTE = .5,
            CRIT = .6,
            MP5 = .3
        },

        --====================================================
        -- 💀 DEATH KNIGHT
        --====================================================

        ["Blood"] = {
            STAM = 4.5,
            DEF = 3.0,
            DODGE = 2.5,
            PARRY = 2.2
        },

        ["Frost DK"] = {
            STR = 4.0,
            AP  = 3.5,
            WEAPON_DPS = 4.5,
            HIT = 3.2,
            EXP = 3.0,
            CRIT = 2.6,
            HASTE = 2.3
        },

        ["Unholy"] = {
            STR = 4.0,
            AP  = 3.5,
            HIT = 3.2,
            EXP = 3.0,
            CRIT = 2.6,
            HASTE = 2.3
        },

        --====================================================
        -- 🧠 FALLBACK
        --====================================================

        ["Unknown"] = self:GetAdaptiveWeights(),
    }

    return weights[spec] or weights["Unknown"]
end

--============================================================
-- 🚫 SPEC FILTER
--============================================================

function M:IsItemValidForSpec(link)
    if not link then return false, "CLASS" end

    local class = select(2, UnitClass("player"))
    local spec = GetPlayerSpec()
    local weights = self:GetSpecWeights()

    local itemName, _, _, _, _, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(link)

    if not itemType then return true end

    --====================================================
    -- 🛡 ARMOR FILTER
    --====================================================
    if itemType == "Armor" then
        local isArmorSlot =
            itemEquipLoc == "INVTYPE_HEAD" or
            itemEquipLoc == "INVTYPE_SHOULDER" or
            itemEquipLoc == "INVTYPE_CHEST" or
            itemEquipLoc == "INVTYPE_ROBE" or
            itemEquipLoc == "INVTYPE_WAIST" or
            itemEquipLoc == "INVTYPE_LEGS" or
            itemEquipLoc == "INVTYPE_FEET" or
            itemEquipLoc == "INVTYPE_WRIST" or
            itemEquipLoc == "INVTYPE_HAND"

        if isArmorSlot then
            if class == "DRUID" or class == "ROGUE" or class == "MONK" then
                if itemSubType ~= "Leather" then
                    -- Cloth is wearable but not ideal → SPEC issue
                    if itemSubType == "Cloth" then
                        return false, "SPEC"
                    end
                    return false, "CLASS"
                end
            elseif class == "MAGE" or class == "PRIEST" or class == "WARLOCK" then
                if itemSubType ~= "Cloth" then return false, "CLASS" end
            elseif class == "HUNTER" or class == "SHAMAN" then
                if itemSubType ~= "Mail" then return false, "CLASS" end
            elseif class == "WARRIOR" or class == "PALADIN" or class == "DEATHKNIGHT" then
                if itemSubType ~= "Plate" then return false, "CLASS" end
            end
        end
    end

    --====================================================
    -- ⚔️ WEAPON FILTER
    --====================================================
    if itemType == "Weapon" then
        local sub = itemSubType and itemSubType:lower() or ""

        -- Casters using melee → SPEC issue
        if weights.INT and weights.INT > (weights.STR or 0) and weights.INT > (weights.AGI or 0) then
            if sub:find("axe") or sub:find("sword") or sub:find("mace") then
                return false, "SPEC"
            end
        end

        -- Melee using wand → SPEC issue
        if (weights.STR or 0) > (weights.INT or 0) or (weights.AGI or 0) > (weights.INT or 0) then
            if sub:find("wand") then
                return false, "SPEC"
            end
        end
    end

    --====================================================
    -- 🪄 RELICS (CLASS LOCKED)
    --====================================================
    scanTip:ClearLines()
    scanTip:SetHyperlink(link)

    for i = 1, scanTip:NumLines() do
        local right = _G["BasicUIItemScoreScannerTextRight"..i]
        if right then
            local text = right:GetText()
            if text then
                text = text:lower()
				-- Allow relics (handled by custom system)
				if text == "libram" or text == "totem" or text == "idol" or text == "sigil" then
					return true
				end
            end
        end
    end
	
	--====================================================
	-- 🛡 SHIELD BLOCK (CLASS RESTRICTION)
	--====================================================
	if itemEquipLoc == "INVTYPE_SHIELD" then
		if class ~= "WARRIOR" and class ~= "PALADIN" and class ~= "SHAMAN" then
			return false, "CLASS"
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
-- 🪄 RELIC COMPATIBILITY SYSTEM
--============================================================
local function IsRelic(itemLink)
    if not itemLink then return false end
    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemLink)
    return equipLoc == "INVTYPE_RELIC"
end

local function GetItemStatsFromTooltip(tooltip)
    local stats = { agi=0,str=0,int=0,stam=0,ap=0,crit=0,spell=0 }

    for i = 1, tooltip:NumLines() do
        local line = _G[tooltip:GetName().."TextLeft"..i]
        if line then
            local text = line:GetText()
            if text then
                text = text:lower()

                if text:find("agility") then stats.agi = stats.agi + 1 end
                if text:find("strength") then stats.str = stats.str + 1 end
                if text:find("intellect") then stats.int = stats.int + 1 end
                if text:find("stamina") then stats.stam = stats.stam + 1 end
                if text:find("attack power") then stats.ap = stats.ap + 1 end
                if text:find("critical") then stats.crit = stats.crit + 1 end
                if text:find("spell power") then stats.spell = stats.spell + 1 end
            end
        end
    end

    return stats
end

local SPEC_WEIGHTS_RELIC = {
    ["Feral Guardian"] = { stam=3, agi=2 },
    ["Feral DPS"] = { agi=3, ap=3, crit=2 },
    ["Enhancement Tank"] = { stam=3, str=2 },
    ["Enhancement DPS"] = { str=3, ap=3, crit=2 },
    ["Balance"] = { int=3, spell=3 },
    ["Elemental"] = { int=3, spell=3 },
    ["Restoration"] = { int=3, spell=3 },
    ["Holy"] = { int=3, spell=3 },
    ["Retribution"] = { str=3, ap=3 },
    ["Protection"] = { stam=3, str=2 },
}

local function ScoreRelic(stats, weights)
    local score = 0
    for stat, val in pairs(stats) do
        if weights[stat] then
            score = score + val * weights[stat]
        end
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
	
	--============================================================
	-- 🪄 RELIC SCORING DISPLAY
	--============================================================
	if IsRelic(link) then

		local spec = M:GetAdvancedSpec()
		local weights = SPEC_WEIGHTS_RELIC[spec]

		if weights then
			local stats = GetItemStatsFromTooltip(tooltip)
			local score = ScoreRelic(stats, weights)

			tooltip:AddLine(" ")
			tooltip:AddLine("|cff66ccffBasicUI Item Score|r")
			
			if score >= 6 then
				tooltip:AddLine("|cff00ff00Relic: Excellent match for your spec|r")
			elseif score >= 3 then
				tooltip:AddLine("|cffffff00Relic: Good match for your spec|r")
			else
				tooltip:AddLine("|cffff5555Relic: Not ideal for your spec|r")
			end
		end
	end

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
	if M.db.specFilter then
		local valid, reason = M:IsItemValidForSpec(link)

		if not valid then
			tooltip:AddLine(" ")

			--========================
			-- 🎨 CLASS COLOR
			--========================
			local className, classFile = UnitClass("player")
			local classColor = RAID_CLASS_COLORS[classFile]

			local coloredClass = className
			if classColor then
				coloredClass = string.format(
					"|cff%02x%02x%02x%s|r",
					classColor.r * 255,
					classColor.g * 255,
					classColor.b * 255,
					className
				)
			end

			--========================
			-- 🎨 SPEC COLOR
			--========================
			local spec = GetPlayerSpec()
			local weights = M:GetSpecWeights()

			local specColor = "|cffffff00" -- default yellow

			local str = weights.STR or 0
			local agi = weights.AGI or 0
			local int = weights.INT or 0

			if str >= agi and str >= int then
				specColor = "|cffff5555" -- red (STR)
			elseif agi >= str and agi >= int then
				specColor = "|cff55ff55" -- green (AGI)
			elseif int >= str and int >= agi then
				specColor = "|cff5599ff" -- blue (INT)
			end

			local coloredSpec = specColor .. spec .. "|r"

			--========================
			-- 🧾 OUTPUT
			--========================
			if reason == "CLASS" then
				tooltip:AddLine("|cffff5555This item is not for your|r " ..coloredClass.. " |cffff5555class|r")

			elseif reason == "SPEC" then
				tooltip:AddLine("|cffffff00This item is not ideal for your|r " ..coloredSpec.. " |cffffff00spec|r")
			end

			tooltip:AddLine(" ")
			return
		end
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