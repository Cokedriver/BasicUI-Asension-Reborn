--============================================================
-- PLUGIN: Professions (Ascension‑accurate tiers)
-- Datapanel version (no Ace3, no options UI)
--============================================================
local parent = BasicUI:GetModule("Datapanel")
local M = parent

local Plugin = {}
Plugin.name = "professions"

local prof1, prof2 = nil, nil   -- detected primary professions

-- Gathering professions have no window
local GATHERING = {
    ["Skinning"] = true,
    ["Mining"] = true,
    ["Herbalism"] = true,
}

--============================================================
-- Safe profession opener
--============================================================
local function SafeOpenProfession(name)
    if not name then return end

    if GATHERING[name] then
        print("|cffffff00BasicUI:|r |cffff0000" .. name .. " has no window to open.|r")
        return
    end

    CastSpellByName(name)
end

--============================================================
-- Detect Primary Professions
--============================================================
local function DetectPrimaryProfessions()
    prof1, prof2 = nil, nil

    -- Force skill cache refresh (Ascension quirk)
    for i = 1, GetNumSkillLines() do GetSkillLineInfo(i) end
    for i = 1, GetNumSkillLines() do GetSkillLineInfo(i) end

    for i = 1, GetNumSkillLines() do
        local name, isHeader, _, rank, _, _, maxRank, isAbandonable =
            GetSkillLineInfo(i)

        if not isHeader and maxRank and maxRank > 1 and isAbandonable then
            if not prof1 then
                prof1 = name
            elseif not prof2 then
                prof2 = name
            end
        end
    end
end

--============================================================
-- OnEnable
--============================================================
function Plugin:OnEnable()
    M:RegisterEvent("SKILL_LINES_CHANGED", function() Plugin:Refresh() end)
end

--============================================================
-- Refresh (panel text)
--============================================================
function Plugin:Refresh()
    if not self.frame then return end

    DetectPrimaryProfessions()

    local hex = M:GetClassHex()
    self.frame.text:SetText(string.format("|cff%sProfessions|r", hex))
    self.frame:SetWidth(self.frame.text:GetStringWidth() + 12)
end

--============================================================
-- Ascension‑accurate Tier Helper
--============================================================
local function GetTierData(rank, maxRank)
    -- Ascension gives correct maxRank (75, 150, 225, 300)
    maxRank = maxRank or 75

    local color = "ffffff" -- default white

    if maxRank == 75 then
        color = "ffffff"   -- Apprentice
    elseif maxRank == 150 then
        color = "ff8c00"   -- Journeyman
    elseif maxRank == 225 then
        color = "ffff00"   -- Expert
    elseif maxRank == 300 then
        color = "00ccff"   -- Artisan
    end

    -- Training indicator
    local train = ""
    if rank == maxRank and maxRank < 300 then
        train = " |cffff0000[Train]|r"
    end

    return "|cff" .. color, train, maxRank
end

--============================================================
-- Tooltip
--============================================================
local function ShowTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:ClearLines()

    -- Force skill cache refresh
    for i = 1, GetNumSkillLines() do GetSkillLineInfo(i) end
    for i = 1, GetNumSkillLines() do GetSkillLineInfo(i) end

    -- Header
    local header = M:GetColoredPlayerHeader("Professions")
    GameTooltip:AddLine(header)
    GameTooltip:AddLine("-------------------------", 0.4, 0.4, 0.4)

    local primaries, secondaries, weapons, languages = {}, {}, {}, {}

    -- Weapon skills
    local weaponList = {
        ["Swords"] = true, ["Two-Handed Swords"] = true,
        ["Axes"] = true, ["Two-Handed Axes"] = true,
        ["Maces"] = true, ["Two-Handed Maces"] = true,
        ["Daggers"] = true,
        ["Polearms"] = true,
        ["Staves"] = true,
        ["Fist Weapons"] = true,
        ["Bows"] = true,
        ["Guns"] = true,
        ["Crossbows"] = true,
        ["Thrown"] = true,
        ["Wands"] = true,
        ["Defense"] = true,
    }

    -- Languages
    local languageList = {
        ["Common"] = true, ["Orcish"] = true, ["Darnassian"] = true,
        ["Dwarven"] = true, ["Gnomish"] = true, ["Troll"] = true,
        ["Gutterspeak"] = true, ["Thalassian"] = true,
        ["Draconic"] = true, ["Demonic"] = true, ["Titan"] = true,
        ["Old Tongue"] = true,
    }

    -- Scan skill lines
    for i = 1, GetNumSkillLines() do
        local name, isHeader, _, rank, _, _, maxRank, isAbandonable =
            GetSkillLineInfo(i)

        if not isHeader and maxRank and maxRank > 1 then

            if isAbandonable then
                table.insert(primaries, { n = name, r = rank, max = maxRank })

            elseif weaponList[name] then
                table.insert(weapons, { n = name, r = rank })

            elseif languageList[name] or name:find("Language") then
                table.insert(languages, { n = name })

            else
                table.insert(secondaries, { n = name, r = rank, max = maxRank })
            end
        end
    end

    --============================================================
    -- Primary Professions
    --============================================================
    GameTooltip:AddLine("Primary Professions", 1, 0.82, 0)
    if #primaries == 0 then
        GameTooltip:AddLine("None", 0.5, 0.5, 0.5)
    else
        for _, p in ipairs(primaries) do
            local color, train, tierMax = GetTierData(p.r, p.max)
            local rankStr = string.format("%s%d / %d|r%s", color, p.r, tierMax, train)
            GameTooltip:AddDoubleLine(p.n, rankStr, 1,1,1, 1,1,1)
        end
    end

    GameTooltip:AddLine("-------------------------", 0.4, 0.4, 0.4)

    --============================================================
    -- Secondary Skills
    --============================================================
    GameTooltip:AddLine("Secondary Skills", 1, 0.82, 0)
    if #secondaries == 0 then
        GameTooltip:AddLine("None", 0.5, 0.5, 0.5)
    else
        for _, s in ipairs(secondaries) do
            local color, train, tierMax = GetTierData(s.r, s.max)
            local rankStr = string.format("%s%d / %d|r%s", color, s.r, tierMax, train)
            GameTooltip:AddDoubleLine(s.n, rankStr, 1,1,1, 1,1,1)
        end
    end

    GameTooltip:AddLine("-------------------------", 0.4, 0.4, 0.4)

    --============================================================
    -- Weapon Skills
    --============================================================
    GameTooltip:AddLine("Weapon Skills", 1, 0.82, 0)
    if #weapons == 0 then
        GameTooltip:AddLine("None", 0.5, 0.5, 0.5)
    else
        for _, w in ipairs(weapons) do
            GameTooltip:AddDoubleLine(w.n, w.r, 1,1,1, 1,1,1)
        end
    end

    GameTooltip:AddLine("-------------------------", 0.4, 0.4, 0.4)

    --============================================================
    -- Languages
    --============================================================
    GameTooltip:AddLine("Languages", 1, 0.82, 0)
    if #languages == 0 then
        GameTooltip:AddLine("None", 0.5, 0.5, 0.5)
    else
        for _, l in ipairs(languages) do
            GameTooltip:AddLine(l.n, 1,1,1)
        end
    end

    GameTooltip:AddLine(" ")
	GameTooltip:AddLine("|cff00ff00Left-Click:|r Open " .. (prof1 or "Profession 1"), 0.7, 0.7, 0.7)
	GameTooltip:AddLine("|cff00ff00Right-Click:|r Open " .. (prof2 or "Profession 2"), 0.7, 0.7, 0.7)
	GameTooltip:AddLine("|cff00ff00Mouse Wheel Click:|r Open Professions Window", 0.7, 0.7, 0.7)

    GameTooltip:Show()
end

--============================================================
-- CreateFrame
--============================================================
function Plugin:CreateFrame(parent)
    local f = CreateFrame("Button", nil, parent)
    f:SetHeight(20)
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")

    f.text = f:CreateFontString(nil, "OVERLAY")
    M:ApplyStandardFont(f.text)
    f.text:SetPoint("CENTER")

    f:SetScript("OnEnter", ShowTooltip)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

	f:SetScript("OnClick", function(self, button)
		if InCombatLockdown() then
			UIErrorsFrame:AddMessage("Cannot open professions during combat!", 1,0,0)
			return
		end

		DetectPrimaryProfessions()

		if button == "LeftButton" then
			SafeOpenProfession(prof1)

		elseif button == "RightButton" then
			SafeOpenProfession(prof2)

		elseif button == "MiddleButton" then
			if AscensionSpellbookFrame then
				if AscensionSpellbookFrame:IsShown()
				   and PanelTemplates_GetSelectedTab(AscensionSpellbookFrame) == 3 then

					AscensionSpellbookFrame:Hide()

				else
					AscensionSpellbookFrame:Show()

					if AscensionSpellbookFrameTab3 then
						AscensionSpellbookFrameTab3:Click()
					end
				end
			end
		end
		
	end)

    -- Auto-refresh every 10 seconds
    f:SetScript("OnUpdate", function(self, elapsed)
        self.timer = (self.timer or 0) + elapsed
        if self.timer > 10 then
            Plugin:Refresh()
            self.timer = 0
        end
    end)

    self.frame = f
    self:Refresh()
    return f
end

--============================================================
-- Register plugin
--============================================================
M:RegisterPlugin("professions", Plugin)
