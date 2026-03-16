--==============================
-- PLUGIN: MainStats
--==============================

local Datapanel = BasicUI:GetModule("Datapanel")
if not Datapanel then return end

local Plugin = {}
Plugin.name = "mainstats"

--============================================================
-- Ascension Spec Detection
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

    if not primaryTab then
        return UnitClass("player") or "Unknown"
    end

    return primaryTab:gsub("(%u)", " %1"):gsub("^%s+", "")

end

--============================================================
-- Stat Priority Table
--============================================================
local SPEC_PRIORITY = {

    ["Arms"]        = "Str > Crit > AP",
    ["Fury"]        = "Str > Crit > Haste",
    ["Protection"]  = "Str > Defense > Block",

    ["Holy"]        = "Int > Spirit > Haste",
    ["Retribution"] = "Str > Crit > Haste",
    ["Protection"]  = "Str > Defense > Stam",

    ["Beast Mastery"] = "Agi > AP > Crit",
    ["Marksmanship"]  = "Agi > Crit > AP",
    ["Survival"]      = "Agi > Crit > AP",

    ["Assassination"] = "Agi > Crit > AP",
    ["Combat"]        = "Agi > Haste > AP",
    ["Subtlety"]      = "Agi > Crit > AP",

    ["Discipline"] = "Int > Spirit > Haste",
    ["Holy"]       = "Int > Spirit > Haste",
    ["Shadow"]     = "Int > Haste > Crit",

    ["Blood"]   = "Str > Parry > Stam",
    ["Frost"]   = "Str > Hit > Haste",
    ["Unholy"]  = "Str > Haste > Crit",

    ["Elemental"]   = "Int > Haste > Crit",
    ["Enhancement"] = "Agi > AP > Crit",
    ["Restoration"] = "Int > Spirit > Haste",

    ["Arcane"] = "Int > Haste > Crit",
    ["Fire"]   = "Int > Crit > Haste",
    ["Frost"]  = "Int > Haste > Crit",

    ["Affliction"]  = "Int > Haste > Crit",
    ["Demonology"]  = "Int > Spirit > Haste",
    ["Destruction"] = "Int > Crit > Haste",

    ["Balance"]       = "Int > Haste > Crit",
    ["Feral Combat"]  = "Agi > AP > Crit",
    ["Feral"]         = "Agi > AP > Crit",
    ["Guardian"]      = "Stam > Agi > Armor",
    ["Restoration"]   = "Int > Spirit > Haste",
}

--============================================================
-- Stat Value Resolver
--============================================================
local FULL_STAT_NAMES = {
    str     = "Strength",
    agi     = "Agility",
    int     = "Intellect",
    stam    = "Stamina",
    ap      = "Attack Power",
    crit    = "Critical Strike",
    haste   = "Haste",
    hit     = "Hit Chance",
    spirit  = "Spirit",
    parry   = "Parry",
    block   = "Block",
    defense = "Defense",
}

local function GetStatValue(stat)

    local key = stat:lower()
    local label = FULL_STAT_NAMES[key] or stat

    if key == "str" then
        return label, UnitStat("player",1)

    elseif key == "agi" then
        return label, UnitStat("player",2)

    elseif key == "int" then
        return label, UnitStat("player",4)

    elseif key == "stam" then
        return label, UnitStat("player",3)

    elseif key == "ap" then
        local base,pos,neg = UnitAttackPower("player")
        return label, base + pos + neg

    elseif key == "crit" then
        return label, string.format("%.2f%%",GetCritChance())

    elseif key == "haste" then
        return label, string.format("%.2f%%",GetCombatRatingBonus(CR_HASTE_MELEE))

    elseif key == "hit" then
        return label, string.format("%.2f%%",GetCombatRatingBonus(CR_HIT_MELEE))

    elseif key == "spirit" then
        return label, UnitStat("player",5)

    elseif key == "parry" then
        return label, string.format("%.2f%%",GetParryChance())

    elseif key == "block" then
        return label, string.format("%.2f%%",GetBlockChance())

    elseif key == "defense" then
        local base,mod = UnitDefense("player")
        return label, base + mod
    end

    return stat,"N/A"

end

--============================================================
-- Panel Text
--============================================================
function Plugin:Refresh()

    if not self.frame then return end

    local spec = GetPlayerSpec()
    local priority = SPEC_PRIORITY[spec] or "N/A"

    local firstStat = priority:match("([^>]+)")
    firstStat = firstStat and firstStat:gsub("%s+","") or "N/A"

    local label,value = GetStatValue(firstStat)
    local hex = BasicUI:GetClassHex()

    self.frame.text:SetText("|cff"..hex..label..":|r "..tostring(value))
    self.frame:SetWidth(self.frame.text:GetStringWidth() + 12)

end

--============================================================
-- Tooltip Helpers
--============================================================
local function GetRoleFromSpec(spec)

    local roleMap = {

        ["Protection"] = "TANK",
        ["Guardian"] = "TANK",
        ["Blood"] = "TANK",

        ["Arms"] = "MELEE",
        ["Fury"] = "MELEE",
        ["Retribution"] = "MELEE",
        ["Assassination"] = "MELEE",
        ["Combat"] = "MELEE",
        ["Enhancement"] = "MELEE",
        ["Feral"] = "MELEE",

        ["Beast Mastery"] = "RANGED",
        ["Marksmanship"] = "RANGED",
        ["Survival"] = "RANGED",

        ["Shadow"] = "CASTER",
        ["Arcane"] = "CASTER",
        ["Fire"] = "CASTER",
        ["Frost"] = "CASTER",
        ["Affliction"] = "CASTER",
        ["Demonology"] = "CASTER",
        ["Destruction"] = "CASTER",
        ["Elemental"] = "CASTER",
        ["Balance"] = "CASTER",

        ["Holy"] = "HEALER",
        ["Restoration"] = "HEALER",
        ["Discipline"] = "HEALER",
    }

    return roleMap[spec] or "MELEE"

end

local function AddStatLine(label,value)
    GameTooltip:AddDoubleLine(label..":",tostring(value),1,1,1,1,1,1)
end

--============================================================
-- Tooltip
--============================================================
local function ShowTooltip(self)

    GameTooltip:SetOwner(self,"ANCHOR_TOP")
    GameTooltip:ClearLines()

    local spec = GetPlayerSpec()
    local role = GetRoleFromSpec(spec)
    local priority = SPEC_PRIORITY[spec] or "N/A"

    GameTooltip:AddLine(Datapanel:GetColoredPlayerHeader("Stats"))
    GameTooltip:AddLine(" ")

    GameTooltip:AddLine("|cffffd100Stat Priority Order|r")
    GameTooltip:AddLine("  "..priority)
    GameTooltip:AddLine(" ")

    if priority ~= "N/A" then

        GameTooltip:AddLine("|cffffd100Current Priority Values|r")

        for stat in string.gmatch(priority,"([^>]+)") do
            stat = stat:gsub("%s+","")
            local label,value = GetStatValue(stat)
            AddStatLine(label,value)
        end

    end

    GameTooltip:AddLine("-------------------------",0.4,0.4,0.4)

    GameTooltip:AddLine("|cffffd100Attributes|r")

    AddStatLine("Strength",UnitStat("player",1))
    AddStatLine("Agility",UnitStat("player",2))
    AddStatLine("Stamina",UnitStat("player",3))
    AddStatLine("Intellect",UnitStat("player",4))
    AddStatLine("Spirit",UnitStat("player",5))

    local _,effectiveArmor = UnitArmor("player")
    AddStatLine("Armor",effectiveArmor)

    GameTooltip:AddLine(" ")

    if role == "MELEE" or role == "RANGED" or role == "TANK" then

        GameTooltip:AddLine("|cffffd100Melee Stats|r")

        local base,pos,neg = UnitAttackPower("player")
        AddStatLine("Attack Power",base + pos + neg)
        AddStatLine("Crit",string.format("%.2f%%",GetCritChance()))
        AddStatLine("Haste",string.format("%.2f%%",GetCombatRatingBonus(CR_HASTE_MELEE)))
        AddStatLine("Hit",string.format("%.2f%%",GetCombatRatingBonus(CR_HIT_MELEE)))

        GameTooltip:AddLine(" ")

    end

    if role == "CASTER" or role == "HEALER" then

        GameTooltip:AddLine("|cffffd100Spell Stats|r")

        local spellPower = GetSpellBonusDamage and GetSpellBonusDamage(2) or 0
        AddStatLine("Spell Power",spellPower)
        AddStatLine("Crit",string.format("%.2f%%",GetSpellCritChance(2)))
        AddStatLine("Haste",string.format("%.2f%%",GetCombatRatingBonus(CR_HASTE_SPELL)))
        AddStatLine("Hit",string.format("%.2f%%",GetCombatRatingBonus(CR_HIT_SPELL)))

        local baseRegen = select(1,GetManaRegen())
        AddStatLine("Mana Regen",string.format("%.0f",baseRegen))

        GameTooltip:AddLine(" ")

    end

    if role == "TANK" then

        GameTooltip:AddLine("|cffffd100Defense Stats|r")

        local baseDef,modDef = UnitDefense("player")
        AddStatLine("Defense",baseDef + modDef)
        AddStatLine("Parry",string.format("%.2f%%",GetParryChance()))
        AddStatLine("Block",string.format("%.2f%%",GetBlockChance()))
        AddStatLine("Dodge",string.format("%.2f%%",GetDodgeChance()))

        GameTooltip:AddLine(" ")

    end

    GameTooltip:Show()

end

--============================================================
-- CreateFrame
--============================================================
function Plugin:CreateFrame(parent)

    local f = CreateFrame("Button",nil,parent)
    f:SetHeight(20)
    f:EnableMouse(true)

    f.text = f:CreateFontString(nil,"OVERLAY")
    Datapanel:ApplyStandardFont(f.text)
    f.text:SetPoint("CENTER")

    f:SetScript("OnEnter",ShowTooltip)
    f:SetScript("OnLeave",function() GameTooltip:Hide() end)

    self.frame = f
    self:Refresh()

    return f

end

--============================================================
-- Register plugin
--============================================================
Datapanel:RegisterPlugin("mainstats",Plugin)