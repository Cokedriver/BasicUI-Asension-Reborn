local parent = BasicUI:GetModule("Datapanel")
local M = parent

local Plugin = {}
Plugin.name = "spec"

--============================================================
-- Logic: Determine Spec based on Talent Distribution
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
        -- Formats "BeastMastery" to "Beast Mastery"
        return primaryTab:gsub("(%u)", " %1"):gsub("^%s+", ""), tabCounts
    end
    
    return UnitClass("player") or "Unknown", tabCounts
end

--============================================================
-- Logic: Get Equipped Enchants (Modern Slot API)
--============================================================
local function GetEnchantList()
    local names = {}
    
    -- pull data from the C_MysticEnchant system seen in your /fstack
    if C_MysticEnchant and C_MysticEnchant.GetEquippedEnchants then
        local equipped = C_MysticEnchant.GetEquippedEnchants()
        if equipped then
            for _, data in ipairs(equipped) do
                if data.name then
                    table.insert(names, data.name)
                end
            end
        end
    end
    
    return names
end

--============================================================
-- OnEnable
--============================================================
function Plugin:OnEnable()
    M:RegisterEvent("PLAYER_LOGIN", function() Plugin:Refresh() end)
    M:RegisterEvent("PLAYER_ENTERING_WORLD", function() Plugin:Refresh() end)
    M:RegisterEvent("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED", function() Plugin:Refresh() end)
end

--============================================================
-- Refresh (Panel Text)
--============================================================
function Plugin:Refresh()
    if not self.frame then return end

    local specName = GetPlayerSpec()
    local labelColor = M:GetClassHex()

    local text = string.format("|cff%sSpec:|r |cffffffff%s|r", labelColor, specName)
    self.frame.text:SetText(text)
    self.frame:SetWidth(self.frame.text:GetStringWidth() + 12)
end

--============================================================
-- Tooltip (Displays Spec and Enchant List)
--============================================================
local function ShowTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:ClearLines()

    local header = M:GetColoredPlayerHeader("Character Specialization")
    GameTooltip:AddLine(header)
    GameTooltip:AddLine(" ")

    local specName, tabCounts = GetPlayerSpec()
    GameTooltip:AddDoubleLine("Active Spec:", specName, 1,1,1, 0,1,0)

    -- Show Active Preset Name
    local presetName = "None active"
    if MysticEnchantManagerUtil and MysticEnchantManagerUtil.GetActivePreset then
        local presetId = MysticEnchantManagerUtil.GetActivePreset()
        if presetId then
            presetName = MysticEnchantManagerUtil.GetPresetName(presetId)
        end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Mystic Enchant Preset", 0.1, 0.8, 1)
    GameTooltip:AddLine(presetName, 1, 1, 1)

    -- List individual enchants found via API
    local enchants = GetEnchantList()
    if #enchants > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Equipped Enchants:", 1, 0.82, 0)
        for _, name in ipairs(enchants) do
            GameTooltip:AddLine("  • " .. name, 0.8, 0.8, 0.8)
        end
    end

    -- Talent distribution
    if tabCounts and next(tabCounts) then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Talent Distribution:", 1, 0.82, 0)
        for tab, count in pairs(tabCounts) do
            local formatted = tab:gsub("(%u)", " %1"):gsub("^%s+", "")
            GameTooltip:AddDoubleLine("  " .. formatted, count .. " talents", 1,1,1, 0.7,0.7,0.7)
        end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff00ff00Left-Click:|r Open Talents", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cff00ff00Right-Click:|r Open Mystic Enchants", 0.7, 0.7, 0.7)

    GameTooltip:Show()
end

--============================================================
-- CreateFrame
--============================================================
--============================================================
-- CreateFrame
--============================================================
function Plugin:CreateFrame(parent)
    local f = CreateFrame("Button", nil, parent)
    f:SetHeight(20)
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    f.text = f:CreateFontString(nil, "OVERLAY")
    M:ApplyStandardFont(f.text)
    f.text:SetPoint("CENTER")

    f:SetScript("OnEnter", ShowTooltip)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    f:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            RunBinding("TOGGLETALENTS")
		elseif button == "RightButton" then
			if Collections then
				-- If already open AND already on Mystic → close
				if Collections:IsShown() and Collections:IsOnTab(3) then
					Collections:Hide()
				else
					-- Otherwise open Mystic
					Collections:Show()
					Collections:GoToTab(3)
				end
			end
		end
    end)

    self.frame = f
    self:Refresh()
    return f
end

--============================================================
-- Register plugin
--============================================================
M:RegisterPlugin("spec", Plugin)