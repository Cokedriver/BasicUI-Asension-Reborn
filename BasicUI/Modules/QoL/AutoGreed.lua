BasicUI_QoL_RegisterModule("AutoGreed", function(M)

    if not M.db.enableAutoGreed then return end

    --------------------------------------------------
    -- EQUIPMENT SLOT MAP (Dual-slot aware)
    --------------------------------------------------

    local slotIDMap = {
        ["INVTYPE_HEAD"] = {1}, ["INVTYPE_NECK"] = {2}, ["INVTYPE_SHOULDER"] = {3},
        ["INVTYPE_BODY"] = {4}, ["INVTYPE_CHEST"] = {5}, ["INVTYPE_ROBE"] = {5},
        ["INVTYPE_WAIST"] = {6}, ["INVTYPE_LEGS"] = {7}, ["INVTYPE_FEET"] = {8},
        ["INVTYPE_WRIST"] = {9}, ["INVTYPE_HAND"] = {10}, ["INVTYPE_CLOAK"] = {15},
        ["INVTYPE_FINGER"] = {11, 12},
        ["INVTYPE_TRINKET"] = {13, 14},
        ["INVTYPE_WEAPON"] = {16, 17},
        ["INVTYPE_2HWEAPON"] = {16},
        ["INVTYPE_SHIELD"] = {17},
        ["INVTYPE_WEAPONMAINHAND"] = {16},
        ["INVTYPE_WEAPONOFFHAND"] = {17},
        ["INVTYPE_HOLDABLE"] = {17},
        ["INVTYPE_RANGED"] = {18},
        ["INVTYPE_THROWN"] = {18},
        ["INVTYPE_RELIC"] = {18},
    }

    --------------------------------------------------
    -- UPGRADE CHECK
    --------------------------------------------------

    function M:IsUpgrade(link)
        local _, _, _, iLvl, _, _, _, _, equipLoc = GetItemInfo(link)
        if not iLvl then return false end

        local slots = slotIDMap[equipLoc]
        if not slots then return false end

        local lowestCurrentILvl = 999
        local hasEmptySlot = false

        for _, slotID in ipairs(slots) do
            local currentItemLink = GetInventoryItemLink("player", slotID)

            if not currentItemLink then
                hasEmptySlot = true
                break
            end

            local _, _, _, currentILvl = GetItemInfo(currentItemLink)
            currentILvl = currentILvl or 0

            if currentILvl < lowestCurrentILvl then
                lowestCurrentILvl = currentILvl
            end
        end

        if hasEmptySlot then return true end
        return iLvl > lowestCurrentILvl
    end

    --------------------------------------------------
    -- STAT PROFILE DETECTION (ASCENSION SAFE)
    --------------------------------------------------

    local statTooltip = CreateFrame("GameTooltip", "BasicUIStatScanTooltip", nil, "GameTooltipTemplate")
    statTooltip:SetOwner(UIParent, "ANCHOR_NONE")

    local function GetPrimaryStatProfile()

        local stats = {
            Strength = 0,
            Agility = 0,
            Intellect = 0,
            Defense = 0,
            SpellPower = 0,
            AttackPower = 0
        }

        for slot = 1, 19 do
            local link = GetInventoryItemLink("player", slot)
            if link then
                statTooltip:SetHyperlink(link)

                for i = 2, statTooltip:NumLines() do
                    local text = _G["BasicUIStatScanTooltipTextLeft"..i]
                    if text then
                        text = text:GetText()
                        if text then
                            if text:find("Strength") then stats.Strength = stats.Strength + 1 end
                            if text:find("Agility") then stats.Agility = stats.Agility + 1 end
                            if text:find("Intellect") then stats.Intellect = stats.Intellect + 1 end
                            if text:find("Defense") then stats.Defense = stats.Defense + 1 end
                            if text:find("Spell Power") then stats.SpellPower = stats.SpellPower + 1 end
                            if text:find("Attack Power") then stats.AttackPower = stats.AttackPower + 1 end
                        end
                    end
                end
            end
        end

        local highest = 0
        local primary = nil

        for stat, value in pairs(stats) do
            if value > highest then
                highest = value
                primary = stat
            end
        end

        return primary
    end

    --------------------------------------------------
    -- LOOT EVENT
    --------------------------------------------------

    local f = CreateFrame("Frame")
    f:RegisterEvent("START_LOOT_ROLL")

    local lootTooltip = CreateFrame("GameTooltip", "BasicUILootScanTooltip", nil, "GameTooltipTemplate")
    lootTooltip:SetOwner(UIParent, "ANCHOR_NONE")

    f:SetScript("OnEvent", function(_, _, rollID)

        local _, _, _, _, _, canDisenchant, canGreed = GetLootRollItemInfo(rollID)
        local link = GetLootRollItemLink(rollID)
        if not link then return end

        local name, _, _, _, _, _, _, _, _, _, _, _, _, bindType = GetItemInfo(link)
        if not name then return end

        --------------------------------------------------
        -- ❌ Skip BoE items
        --------------------------------------------------
        if bindType == 2 then
            return
        end

        --------------------------------------------------
        -- Detect Player Stat Profile
        --------------------------------------------------

        local primaryStat = GetPrimaryStatProfile()
        if not primaryStat then return end

        --------------------------------------------------
        -- Check Item Stat Match
        --------------------------------------------------

        local function ItemMatchesPrimaryStat(link)

            lootTooltip:SetHyperlink(link)

            for i = 2, lootTooltip:NumLines() do
                local text = _G["BasicUILootScanTooltipTextLeft"..i]
                if text then
                    text = text:GetText()
                    if text then
                        if primaryStat == "Strength" and text:find("Strength") then return true end
                        if primaryStat == "Agility" and text:find("Agility") then return true end
                        if primaryStat == "Intellect" and text:find("Intellect") then return true end
                        if primaryStat == "Defense" and text:find("Defense") then return true end
                        if primaryStat == "SpellPower" and text:find("Spell Power") then return true end
                        if primaryStat == "AttackPower" and text:find("Attack Power") then return true end
                    end
                end
            end

            return false
        end

        --------------------------------------------------
        -- NEED only if upgrade + stat match
        --------------------------------------------------

        if M:IsUpgrade(link) and ItemMatchesPrimaryStat(link) then
            RollOnLoot(rollID, 1)
            return
        end

        --------------------------------------------------
        -- Otherwise DE → Greed
        --------------------------------------------------

        if canDisenchant then
            RollOnLoot(rollID, 3)
        elseif canGreed then
            RollOnLoot(rollID, 2)
        end
    end)

end)