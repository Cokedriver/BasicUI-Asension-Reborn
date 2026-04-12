local addonName, BasicUI = ...

if not (BasicUI and BasicUI.ItemScore) then return end

local ItemScore = BasicUI.ItemScore
ItemScore.Upgrades = {}
local U = ItemScore.Upgrades

local LEVEL_CAP = 60

local SLOT_MAP = {
    INVTYPE_HEAD = 1, INVTYPE_NECK = 2,
    INVTYPE_SHOULDER = 3, INVTYPE_CHEST = 5,
    INVTYPE_WAIST = 6, INVTYPE_LEGS = 7,
    INVTYPE_FEET = 8, INVTYPE_WRIST = 9,
    INVTYPE_HAND = 10, INVTYPE_CLOAK = 15,

    INVTYPE_FINGER = {11,12},
    INVTYPE_TRINKET = {13,14},

    INVTYPE_WEAPON = 16,
    INVTYPE_2HWEAPON = 16,
    INVTYPE_WEAPONMAINHAND = 16,

    INVTYPE_WEAPONOFFHAND = 17,
    INVTYPE_SHIELD = 17,
	INVTYPE_HOLDABLE = 17,
}

U.SLOT_MAP = SLOT_MAP

function U:GetEffectiveScore(link)
    return ItemScore:GetItemScore(link) or 0
end

local function calc(old, new)
    if not old or old <= 0 then return 100 end
    return ((new - old) / (old + 1)) * 100
end

function U:GetUpgradePercent(link)
    local newScore = self:GetEffectiveScore(link)
    local itemName, _, _, _, _, _, _, _, equipLoc = GetItemInfo(link)

    -- 🛠 FIX: force item info to load
    if not equipLoc then
        local itemID = GetItemInfoInstant(link)
        if itemID then
            equipLoc = select(4, GetItemInfoInstant(link))
        end
    end

    if not equipLoc then return end
    local slot = self.SLOT_MAP[equipLoc]
    if not slot then return end

    --========================================================
    -- 🧠 2H WEAPON LOGIC (COMPARE VS MH + OH)
    --========================================================
    if equipLoc == "INVTYPE_2HWEAPON" then
        local mh = GetInventoryItemLink("player", 16)
        local oh = GetInventoryItemLink("player", 17)

        local mhScore = mh and self:GetEffectiveScore(mh) or 0
        local ohScore = oh and self:GetEffectiveScore(oh) or 0

        local combined = mhScore + ohScore

        if combined <= 0 then return 100 end
        return ((newScore - combined) / (combined + 1)) * 100
    end

    --========================================================
    -- 🧠 1H WEAPON LOGIC (COMPARE VS MH)
    --========================================================
    if equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_WEAPONMAINHAND" then
        local mh = GetInventoryItemLink("player", 16)
        local mhScore = mh and self:GetEffectiveScore(mh) or 0

        if mhScore <= 0 then return 100 end
        return ((newScore - mhScore) / (mhScore + 1)) * 100
    end

    --========================================================
    -- 🛡 OFFHAND LOGIC (FIXED)
    --========================================================
    if equipLoc == "INVTYPE_WEAPONOFFHAND"
    or equipLoc == "INVTYPE_SHIELD"
    or equipLoc == "INVTYPE_HOLDABLE" then

        local mh = GetInventoryItemLink("player", 16)
        local oh = GetInventoryItemLink("player", 17)

        local mhScore = mh and self:GetEffectiveScore(mh) or 0
        local ohScore = oh and self:GetEffectiveScore(oh) or 0

        -- 🧠 Case 1: Dual wield (MH + OH)
        if mh and oh then
            if ohScore <= 0 then return 100 end
            return ((newScore - ohScore) / (ohScore + 1)) * 100
        end

        -- 🧠 Case 2: 2H equipped → OFFHAND ADDS VALUE (FIXED)
        if mh and not oh then
            if mhScore <= 0 then return 100 end

            local percent = (newScore / (mhScore + 1)) * 100

            -- prevent tiny values showing as equal
            if percent > -1 and percent < 1 then
                percent = 0
            end

            return percent
        end

        -- 🧠 Case 3: Nothing equipped
        return 100
    end

    --========================================================
    -- 💍 RINGS / TRINKETS (WORST SLOT)
    --========================================================
    if type(slot) == "table" then
        local worstScore = math.huge

        for _, s in ipairs(slot) do
            local eq = GetInventoryItemLink("player", s)
            local eqScore = eq and self:GetEffectiveScore(eq) or 0

            if eqScore < worstScore then
                worstScore = eqScore
            end
        end

        if worstScore <= 0 then return 100 end
        return ((newScore - worstScore) / (worstScore + 1)) * 100
    end

    --========================================================
    -- 🎯 NORMAL SLOTS
    --========================================================
    local eq = GetInventoryItemLink("player", slot)
    local eqScore = eq and self:GetEffectiveScore(eq) or 0

    if eqScore <= 0 then return 100 end
    return ((newScore - eqScore) / (eqScore + 1)) * 100
end

function U:GetUpgradeBreakdown(link)
    local equipLoc = select(9, GetItemInfo(link))
    local slots = self.SLOT_MAP[equipLoc]

    if type(slots) ~= "table" then return end

    local newScore = self:GetEffectiveScore(link)
    local results = {}

    for i, slotID in ipairs(slots) do
        local eqLink = GetInventoryItemLink("player", slotID)
        local eqScore = eqLink and self:GetEffectiveScore(eqLink) or 0

        local percent
        if eqScore > 0 then
            percent = ((newScore - eqScore) / (eqScore + 1)) * 100
        else
            percent = 100
        end

        -- remove noise
        if percent > -2 and percent < 2 then
            percent = 0
        end

        results[i] = percent
    end

    return results
end

function U:GetSlotName(equipLoc)
    if equipLoc == "INVTYPE_FINGER" then return "Ring"
    elseif equipLoc == "INVTYPE_TRINKET" then return "Trinket"
    else return "Slot" end
end