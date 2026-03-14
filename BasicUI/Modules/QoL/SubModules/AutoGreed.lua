--============================================================
-- BasicUI QoL: AutoGreed
--============================================================

BasicUI_QoL_RegisterModule("AutoGreed", {

    frame = nil,

    ----------------------------------------------------------
    -- SLOT MAP (handles multi-slot gear)
    ----------------------------------------------------------

    slotIDMap = {
        INVTYPE_HEAD = {1},
        INVTYPE_NECK = {2},
        INVTYPE_SHOULDER = {3},
        INVTYPE_BODY = {4},
        INVTYPE_CHEST = {5},
        INVTYPE_ROBE = {5},
        INVTYPE_WAIST = {6},
        INVTYPE_LEGS = {7},
        INVTYPE_FEET = {8},
        INVTYPE_WRIST = {9},
        INVTYPE_HAND = {10},
        INVTYPE_FINGER = {11,12},
        INVTYPE_TRINKET = {13,14},
        INVTYPE_CLOAK = {15},
        INVTYPE_WEAPON = {16,17},
        INVTYPE_2HWEAPON = {16},
        INVTYPE_WEAPONMAINHAND = {16},
        INVTYPE_WEAPONOFFHAND = {17},
        INVTYPE_SHIELD = {17},
        INVTYPE_HOLDABLE = {17},
        INVTYPE_RANGED = {18},
        INVTYPE_THROWN = {18},
        INVTYPE_RELIC = {18},
    },

    ----------------------------------------------------------
    -- UPGRADE CHECK
    ----------------------------------------------------------

    IsUpgrade = function(self, link)

        local _, _, _, itemLevel, _, _, _, _, equipLoc = GetItemInfo(link)
        if not equipLoc then return false end

        local slots = self.slotIDMap[equipLoc]
        if not slots then return false end

        local playerLevel = UnitLevel("player")
        local newILvl = GetDetailedItemLevelInfo(link) or itemLevel or 0

        local lowestEquipped = math.huge

        for _, slotID in ipairs(slots) do

            local equippedLink = GetInventoryItemLink("player", slotID)

            -- Empty slot = upgrade
            if not equippedLink then
                return true
            end

            local _, _, quality = GetItemInfo(equippedLink)

            -- Heirloom rule (<60 = best gear)
            if quality == 7 and playerLevel < 60 then
                return false
            end

            local equippedILvl = GetDetailedItemLevelInfo(equippedLink) or 0

            if equippedILvl < lowestEquipped then
                lowestEquipped = equippedILvl
            end

        end

        return newILvl > lowestEquipped

    end,

    ----------------------------------------------------------
    -- AUTO ROLL LOGIC
    ----------------------------------------------------------

    HandleRoll = function(self, rollID)

        local link = GetLootRollItemLink(rollID)
        if not link then return end

        local name, _, quality = GetItemInfo(link)

        -- Item info not cached yet
        if not name then
            C_Timer.After(0.2, function()
                self:HandleRoll(rollID)
            end)
            return
        end

        -- Cannot roll on heirlooms
        if quality == 7 then
            return
        end

        local _, _, _, _, _, canNeed, canGreed, canDisenchant = GetLootRollItemInfo(rollID)

        -- NEED if upgrade
        if canNeed and self:IsUpgrade(link) then
            RollOnLoot(rollID, 1)
            return
        end

        -- DISENCHANT
        if canDisenchant then
            RollOnLoot(rollID, 3)
            return
        end

        -- GREED
        if canGreed then
            RollOnLoot(rollID, 2)
        end

    end,

    ----------------------------------------------------------
    -- ENABLE
    ----------------------------------------------------------

    OnEnable = function(self, M)

        if not M.db.enableAutoGreed then return end

        if not self.frame then
            self.frame = CreateFrame("Frame")
        end

        self.frame:RegisterEvent("START_LOOT_ROLL")

        self.frame:SetScript("OnEvent", function(_, _, rollID)

            -- Small delay so manual rolls aren't overridden
            C_Timer.After(0.2, function()
                self:HandleRoll(rollID)
            end)

        end)

    end,

    ----------------------------------------------------------
    -- DISABLE
    ----------------------------------------------------------

    OnDisable = function(self)

        if self.frame then
            self.frame:UnregisterAllEvents()
        end

    end,

})