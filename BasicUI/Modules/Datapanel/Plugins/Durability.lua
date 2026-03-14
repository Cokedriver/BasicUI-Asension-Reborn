--==============================
-- PLUGIN: Durability
--==============================

local Datapanel = BasicUI:GetModule("Datapanel")
if not Datapanel then return end

local floor = math.floor

local Plugin = {}
Plugin.name = "durability"

-- Hidden scanner tooltip for repair cost
local scanner = CreateFrame("GameTooltip", "DatapanelDuraScanner", nil, "GameTooltipTemplate")
scanner:SetOwner(WorldFrame, "ANCHOR_NONE")

--============================================================
-- OnEnable
--============================================================
function Plugin:OnEnable()

    -- Refresh engine (updates every 5 seconds)
    Datapanel:RegisterRefresh(self,5)

    Datapanel:RegisterEvent("UPDATE_INVENTORY_DURABILITY", function()
        self:Refresh()
    end)

    Datapanel:RegisterEvent("UPDATE_INVENTORY_ALERTS", function()
        self:Refresh()
    end)

    Datapanel:RegisterEvent("PLAYER_REGEN_ENABLED", function()
        self:Refresh()
    end)

end

--============================================================
-- Refresh (panel text)
--============================================================
function Plugin:Refresh()

    if not self.frame then return end

    local lowest = 100
    local hasItems = false
    local wearingHeirloom = false

    for i = 1, 18 do

        local cur, max = GetInventoryItemDurability(i)

        local link = GetInventoryItemLink("player", i)
        if link then
            local _, _, quality = GetItemInfo(link)
            if quality == 7 then
                wearingHeirloom = true
            end
        end

        if cur and max then
            hasItems = true
            local pct = (cur / max) * 100
            if pct < lowest then
                lowest = pct
            end
        end

    end

    local classHex = Datapanel:GetClassHex()
    local display = ""

    if wearingHeirloom and lowest == 100 then

        display = "|cff00ccffHeirloom|r"

    elseif hasItems then

        local color = "|cffffffff"

        if lowest < 20 then
            color = "|cffff0000"
        elseif lowest < 50 then
            color = "|cffffff00"
        end

        display = string.format("%s%d%%|r", color, floor(lowest))

    else

        display = "|cffffffffN/A|r"

    end

    self.frame.text:SetText(
        string.format("|cff%sDurability:|r %s", classHex, display)
    )

    self.frame:SetWidth(self.frame.text:GetStringWidth() + 12)

end

--============================================================
-- Tooltip
--============================================================
local function ShowTooltip(self)

    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:ClearLines()

    -- Average item level calculation
    local slots = {
        "Head","Shoulder","Back","Chest","Wrist","Hands","Waist","Legs","Feet",
        "Finger0","Finger1","Trinket0","Trinket1","MainHand","SecondaryHand","Ranged"
    }

    local totalILvl = 0
    local count = 0
    local playerLevel = UnitLevel("player")

    for _, slotName in ipairs(slots) do

        local id = GetInventorySlotInfo(slotName.."Slot")
        local link = GetInventoryItemLink("player", id)

        if link then

            local _, _, quality, ilvl = GetItemInfo(link)
            local effective = (quality == 7) and playerLevel or ilvl

            if effective and effective > 0 then
                totalILvl = totalILvl + effective
                count = count + 1
            end

        end

    end

    local avgILvl = count > 0 and (totalILvl / count) or 0

    local header = Datapanel:GetColoredPlayerHeader("Durability")
    GameTooltip:AddLine(header)

    GameTooltip:AddDoubleLine(
        "Average Item Level:",
        string.format("|cffffff00%.1f|r", avgILvl),
        1,1,1,
        1,1,1
    )

    GameTooltip:AddLine("-------------------------",0.4,0.4,0.4)

    local displaySlots = {
        "Head","Shoulder","Chest","Waist","Legs","Feet","Wrist","Hands",
        "MainHand","SecondaryHand","Ranged"
    }

    local totalCost = 0
    local cfg = Datapanel.db.plugins.durability

    for _, slotName in ipairs(displaySlots) do

        local id = GetInventorySlotInfo(slotName.."Slot")
        local link = GetInventoryItemLink("player", id)

        if link then

            local _, _, quality, ilvl = GetItemInfo(link)
            local cur, max = GetInventoryItemDurability(id)

            local isHeirloom = (quality == 7)
            local effective = isHeirloom and playerLevel or ilvl

            local right = nil

            if isHeirloom then

                right = string.format(
                    "|cff00ffff[%d]|r  |cff00ccffHeirloom|r",
                    effective
                )

            elseif cur and max then

                local pct = floor((cur / max) * 100)

                local color =
                    (pct < 20 and "|cffff0000") or
                    (pct < 50 and "|cffffff00") or
                    "|cff00ff00"

                right = string.format(
                    "|cff00ffff[%d]|r  %s%d%%|r",
                    effective,
                    color,
                    pct
                )

                if cfg.showRepairCost then

                    scanner:ClearLines()
                    local hasItem, _, cost = scanner:SetInventoryItem("player", id)

                    if hasItem and cost then
                        totalCost = totalCost + cost
                    end

                end

            end

            if right then
                GameTooltip:AddDoubleLine(link, right, 1,1,1, 1,1,1)
            end

        end

    end

    if cfg.showRepairCost and totalCost > 0 then

        GameTooltip:AddLine(" ")

        GameTooltip:AddDoubleLine(
            "Base Repair Cost (Neutral):",
            GetCoinTextureString(totalCost),
            1,1,1,
            1,1,1
        )

        GameTooltip:AddLine("-------------------------",0.4,0.4,0.4)

        local rep = {
            {name="Friendly", discount=0.05, r=0,g=1,b=0},
            {name="Honored",  discount=0.10, r=0,g=1,b=0.5},
            {name="Revered",  discount=0.15, r=0,g=1,b=1},
            {name="Exalted",  discount=0.20, r=1,g=0.8,b=0},
        }

        for _, tier in ipairs(rep) do

            local cost = totalCost * (1 - tier.discount)

            GameTooltip:AddDoubleLine(
                string.format("%s (-%d%%):", tier.name, tier.discount*100),
                GetCoinTextureString(cost),
                tier.r, tier.g, tier.b,
                1,1,1
            )

        end

    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("<Click to open Character Sheet>",0.5,0.5,0.5)

    GameTooltip:Show()

end

--============================================================
-- CreateFrame
--============================================================
function Plugin:CreateFrame(parent)

    local f = CreateFrame("Button", nil, parent)
    f:SetHeight(20)
    f:EnableMouse(true)

    f.text = f:CreateFontString(nil,"OVERLAY")
    Datapanel:ApplyStandardFont(f.text)
    f.text:SetPoint("CENTER")

    f:SetScript("OnEnter", ShowTooltip)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f:SetScript("OnClick", function() ToggleCharacter("PaperDollFrame") end)

    self.frame = f
    self:Refresh()

    return f

end

--============================================================
-- Register plugin
--============================================================
Datapanel:RegisterPlugin("durability", Plugin)