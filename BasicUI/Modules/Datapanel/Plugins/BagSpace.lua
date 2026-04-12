--==============================
-- PLUGIN: BagSpace
--==============================

local Datapanel = BasicUI:GetModule("Datapanel")
if not Datapanel then return end

local floor = math.floor
local abs = math.abs

local Plugin = {}
Plugin.name = "bagspace"

--============================================================
-- Internal Session Tracking (Classic Style)
--============================================================
local sessionStartGold = 0
local sessionGoldChange = 0

--============================================================
-- Save Player Data (Classic DB Structure)
--============================================================
local function SavePlayerData()

    BasicDB = BasicDB or {}
    BasicDB.Gold = BasicDB.Gold or {}

    local name = UnitName("player")
    local realm = GetRealmName()
    local faction = UnitFactionGroup("player")
    local level = UnitLevel("player")
    local _, class = UnitClass("player")
    local gold = GetMoney()

    BasicDB.Gold[realm] = BasicDB.Gold[realm] or {}
    BasicDB.Gold[realm][faction] = BasicDB.Gold[realm][faction] or {}
    BasicDB.Gold[realm][faction][name] = BasicDB.Gold[realm][faction][name] or {}

    BasicDB.Gold[realm][faction][name].gold = gold
    BasicDB.Gold[realm][faction][name].level = level
    BasicDB.Gold[realm][faction][name].class = class

    if sessionStartGold == 0 then
        sessionStartGold = gold
        sessionGoldChange = 0
    end

end

--============================================================
-- Classic Gold Formatting
--============================================================
local function formatMoney(c)

    if not c or c < 0 then return "" end

    local str = ""

    if c >= 10000 then
        local g = floor(c/10000)
        c = c - g*10000
        str = str..g.."|cFFFFD800g|r "
    end

    if c >= 100 then
        local s = floor(c/100)
        c = c - s*100
        str = str..s.."|cFFC7C7C7s|r "
    end

    str = str..c.."|cFFEEA55Fc|r"

    return str

end

--============================================================
-- Class Icon
--============================================================
local function GetClassIcon(class)

    if not class or not CLASS_ICON_TCOORDS[class] then
        return ""
    end

    local c = CLASS_ICON_TCOORDS[class]

    return string.format(
        "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:20:20:0:0:256:256:%d:%d:%d:%d|t",
        c[1]*256,
        c[2]*256,
        c[3]*256,
        c[4]*256
    )

end

--============================================================
-- Currency Helper (Wrath / 3.3.5 Compatible)
--============================================================
local function AddCurrencyByName(currencyName)

    local num = GetCurrencyListSize()

    for i = 1, num do
        local name, isHeader, isExpanded, isUnused, isWatched, count = GetCurrencyListInfo(i)

        if isHeader and not isExpanded then
            ExpandCurrencyList(i, 1)
        end

        if not isHeader and name == currencyName then
            if count and count > 0 then
                GameTooltip:AddDoubleLine(
                    name .. ":",
                    BreakUpLargeNumbers(count),
                    1,1,1,
                    1,1,1
                )
            end
            return
        end
    end

end

--============================================================
-- OnEnable
--============================================================
function Plugin:OnEnable()

    Datapanel:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        SavePlayerData()
        self:Refresh()
    end)

    Datapanel:RegisterEvent("BAG_UPDATE", function()
        SavePlayerData()
        self:Refresh()
    end)

    Datapanel:RegisterEvent("PLAYER_MONEY", function()

        local gold = GetMoney()

        if sessionStartGold == 0 then
            sessionStartGold = gold
        end

        sessionGoldChange = gold - sessionStartGold

        SavePlayerData()
        self:Refresh()

    end)

end

--============================================================
-- Refresh (Panel Text)
--============================================================
function Plugin:Refresh()

    if not self.frame then return end

    local free, total = 0, 0

    for bag = 0, NUM_BAG_SLOTS do

        local slots = GetContainerNumSlots(bag)

        if slots and slots > 0 then

            total = total + slots

            for slot = 1, slots do
                if not GetContainerItemInfo(bag, slot) then
                    free = free + 1
                end
            end

        end

    end

    local numColor
    if free <= 5 then
        numColor = "ff0000"
    else
        numColor = "ffffff"
    end

    local classHex = BasicUI:GetClassHex()

    local text = string.format(
        "|cff%sBags:|r |cff%s%d/%d|r",
        classHex,
        numColor,
        free,
        total
    )

    self.frame.text:SetText(text)
    self.frame:SetWidth(self.frame.text:GetStringWidth() + 12)

end

--============================================================
-- Tooltip (Classic Layout)
--============================================================
local function ShowTooltip(self)
	local Datapanel = BasicUI:GetModule("Datapanel")

	if Datapanel and Datapanel.AnchorTooltip then
		Datapanel:AnchorTooltip(GameTooltip, self)
	else
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
	end

	GameTooltip:ClearLines()

    local playerName = UnitName("player")
    local realm = GetRealmName()
    local currentGold = GetMoney()
    local playerLevel = UnitLevel("player")

    local _, playerClass = UnitClass("player")
    local classColor = RAID_CLASS_COLORS[playerClass] or {r=1,g=1,b=1}

    GameTooltip:AddDoubleLine(
        string.format("|cff%02x%02x%02x%s|r",
            classColor.r*255,
            classColor.g*255,
            classColor.b*255,
            playerName.."'s Gold"
        ),
        formatMoney(currentGold),
        1,1,1, 1,1,1
    )

    GameTooltip:AddLine(" ")

	--============================================================
	-- AUTO LIST ALL CURRENCIES (Item-Quality Colored - Ascension Fix)
	--============================================================
	GameTooltip:AddLine("Currencies:")

	local num = GetCurrencyListSize()

	for i = 1, num do
		local name, isHeader, isExpanded, isUnused, isWatched, count,
			  icon = GetCurrencyListInfo(i)

		-- Expand collapsed headers
		if isHeader and not isExpanded then
			ExpandCurrencyList(i, 1)
		end

		if not isHeader and name and count then

			local r, g, b = 1, 1, 1  -- default white

			-- Try to match color via item info using icon name
			local itemName, itemLink = GetItemInfo(name)

			if itemLink then
				local quality = select(3, GetItemInfo(itemLink))
				if quality then
					r, g, b = GetItemQualityColor(quality)
				end
			end

			GameTooltip:AddDoubleLine(
				name .. ":",
				BreakUpLargeNumbers(count),
				r, g, b,
				r, g, b
			)
		end
	end

	GameTooltip:AddLine(" ")
    -- SESSION SECTION
    local earned = 0
    local spent = 0

    if sessionGoldChange > 0 then
        earned = sessionGoldChange
    elseif sessionGoldChange < 0 then
        spent = abs(sessionGoldChange)
    end

    GameTooltip:AddLine("This Session:")
    GameTooltip:AddDoubleLine("Earned:", formatMoney(earned), 1,1,1, 1,1,1)
    GameTooltip:AddDoubleLine("Spent:", formatMoney(spent), 1,1,1, 1,1,1)

    if earned > spent then
        GameTooltip:AddDoubleLine("Profit:", formatMoney(earned-spent), 0,1,0, 1,1,1)
    elseif spent > earned then
        GameTooltip:AddDoubleLine("Deficit:", formatMoney(spent-earned), 1,0,0, 1,1,1)
    end

    GameTooltip:AddLine(" ")

    local totalAllianceGold = 0
    local totalHordeGold = 0
    local totalNeutralGold = 0

    if BasicDB.Gold and BasicDB.Gold[realm] then

        local function AddFactionSection(factionName)
            if not BasicDB.Gold[realm][factionName] then return end

            GameTooltip:AddLine(factionName.." Characters:")

            local characters = {}

            for name, info in pairs(BasicDB.Gold[realm][factionName]) do
                table.insert(characters, {
                    name = name,
                    level = info.level,
                    class = info.class,
                    gold = info.gold
                })
            end

            table.sort(characters, function(a, b)
                if a.level ~= b.level then
                    return a.level > b.level
                else
                    return a.name < b.name
                end
            end)

            for _, info in ipairs(characters) do
                local cc = RAID_CLASS_COLORS[info.class] or {r=1,g=1,b=1}
                local diffColor = GetQuestDifficultyColor(info.level)
                local levelHex = string.format("%02x%02x%02x",
                    diffColor.r * 255,
                    diffColor.g * 255,
                    diffColor.b * 255
                )

                GameTooltip:AddDoubleLine(
                    string.format(
                        "%s [|cff%s%d|r] |cff%02x%02x%02x%s|r",
                        GetClassIcon(info.class),
                        levelHex,
                        info.level,
                        cc.r*255,
                        cc.g*255,
                        cc.b*255,
                        info.name
                    ),
                    formatMoney(info.gold),
                    1,1,1,
                    1,1,1
                )

                if factionName == "Alliance" then
                    totalAllianceGold = totalAllianceGold + info.gold
                elseif factionName == "Horde" then
                    totalHordeGold = totalHordeGold + info.gold
                elseif factionName == "Neutral" then
                    totalNeutralGold = totalNeutralGold + info.gold
                end
            end

            local total = 0
            if factionName == "Alliance" then total = totalAllianceGold end
            if factionName == "Horde" then total = totalHordeGold end
            if factionName == "Neutral" then total = totalNeutralGold end

            GameTooltip:AddDoubleLine(
                "Total "..factionName.." Gold",
                formatMoney(total)
            )

            GameTooltip:AddLine(" ")
        end

        AddFactionSection("Alliance")
        AddFactionSection("Horde")
        AddFactionSection("Neutral")
    end

    local totalRealmGold = totalAllianceGold + totalHordeGold + totalNeutralGold

    GameTooltip:AddDoubleLine(
        "Total Gold for "..realm,
        formatMoney(totalRealmGold)
    )

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffeda55fClick|r to Open Bags")
    GameTooltip:AddLine("|cffeda55f/rsg|r to Reset Gold Totals.")

    GameTooltip:Show()
end

--============================================================
-- CreateFrame
--============================================================
function Plugin:CreateFrame(parent)

    local f = CreateFrame("Button", nil, parent)
    f:SetHeight(20)
    f:RegisterForClicks("LeftButtonUp")

    f.text = f:CreateFontString(nil,"OVERLAY")
    Datapanel:ApplyStandardFont(f.text)
    f.text:SetPoint("CENTER")

    f:SetScript("OnClick", function() OpenAllBags() end)
    f:SetScript("OnEnter", ShowTooltip)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.frame = f
    self:Refresh()

    return f

end

--============================================================
-- Register Plugin
--============================================================
Datapanel:RegisterPlugin("bagspace", Plugin)