--==============================
-- PLUGIN: Reputation (GOD MODE)
--==============================

local Datapanel = BasicUI:GetModule("Datapanel")
if not Datapanel then return end

local format = string.format
local tinsert = table.insert
local tsort = table.sort

local Plugin = {}
Plugin.name = "reputation"

--============================================================
-- Internal Tracking
--============================================================
Plugin.lastValues = {}
Plugin.sessionGains = {}
Plugin.trackedFaction = nil
Plugin.lastGainTime = 0
Plugin.sessionStart = GetTime()

--============================================================
-- OnEnable
--============================================================
function Plugin:OnEnable()

    Datapanel:RegisterEvent("UPDATE_FACTION", function()
        self:ScanReputationChanges()
        self:Refresh()
    end)

    Datapanel:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:ScanReputationChanges()
        self:Refresh()
    end)

end

--============================================================
-- Scan Reputation Changes
--============================================================
function Plugin:ScanReputationChanges()

    for i = 1, GetNumFactions() do

        local name, _, _, _, _, barValue, _, _, isHeader = GetFactionInfo(i)

        if not isHeader and name then

            local current = barValue or 0

            if self.lastValues[i] then

                local diff = current - self.lastValues[i]

                if diff > 0 then
                    self.trackedFaction = i
                    self.lastGainTime = GetTime()
                    self.sessionGains[i] = (self.sessionGains[i] or 0) + diff
                end

            end

            self.lastValues[i] = current

        end

    end

end

--============================================================
-- Helpers
--============================================================
local function GetStandingColor(reaction)
    local c = FACTION_BAR_COLORS[reaction]
    if not c then return "ffffff" end
    return format("%02x%02x%02x", c.r*255, c.g*255, c.b*255)
end

local function GetFactionData(i)
    local name, _, standingID, barMin, barMax, barValue,
          _, _, isHeader, _, _, _, _, isChild = GetFactionInfo(i)

    if not name or isHeader then return end

    local current = (barValue or 0) - (barMin or 0)
    local max = (barMax or 1) - (barMin or 0)
    local remaining = max - current

    return name, standingID, current, max, remaining, isChild
end

local function AddFactionLine(i)

    local name, standingID, current, max = GetFactionData(i)
    if not name then return end

    local colorHex = GetStandingColor(standingID)
    local standingText = _G["FACTION_STANDING_LABEL"..standingID]

    GameTooltip:AddDoubleLine(
        "|cffffffff"..name.."|r",
        format("|cff%s%s %d/%d|r", colorHex, standingText, current, max)
    )

end

local function AddFactionBlock()

    for i = 1, GetNumFactions() do

        local name, _, standingID, barMin, barMax, barValue,
              _, _, isHeader, _, _, _, _, isChild = GetFactionInfo(i)

        if name then
            if isHeader then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cffFFD100"..name.."|r")
            else
                local current = (barValue or 0) - (barMin or 0)
                local max = (barMax or 1) - (barMin or 0)

                local colorHex = GetStandingColor(standingID)
                local standingText = _G["FACTION_STANDING_LABEL"..standingID]

                local prefix = isChild and "   " or ""

                GameTooltip:AddDoubleLine(
                    prefix.."|cffffffff"..name.."|r",
                    format("|cff%s%s %d/%d|r", colorHex, standingText, current, max)
                )
            end
        end

    end

end

local function GetWatchedFactionIndex()
    for i = 1, GetNumFactions() do
        local _, _, _, _, _, _, _, _, _, _, _, _, _, isWatched = GetFactionInfo(i)
        if isWatched then return i end
    end
end



--============================================================
-- Refresh
--============================================================
function Plugin:Refresh()

    if not self.frame then return end

    local hex = BasicUI:GetClassHex()
    self.frame.text:SetText("|cff"..hex.."Reputation|r")
    self.frame:SetWidth(self.frame.text:GetStringWidth() + 12)

end

--============================================================
-- Tooltip
--============================================================
local function ShowTooltip(self)

    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:ClearLines()

    Datapanel:AddTooltipHeader(GameTooltip, "Reputation")

    ------------------------------------------------
    -- CURRENT TARGET REP
    ------------------------------------------------
    Datapanel:AddTooltipDivider(GameTooltip)
    GameTooltip:AddLine("|cff00ffffCurrent Rep|r")

    local i = Plugin.trackedFaction or GetWatchedFactionIndex()

    if i then
        local name, standingID, current, max, remaining = GetFactionData(i)

        local colorHex = GetStandingColor(standingID)
        local standingText = _G["FACTION_STANDING_LABEL"..standingID]

        GameTooltip:AddDoubleLine(name, format("|cff%s%s|r", colorHex, standingText))
        GameTooltip:AddDoubleLine("Progress:", current.."/"..max)
        GameTooltip:AddDoubleLine("Remaining:", remaining)

        -- Rep/hour
        local elapsed = GetTime() - Plugin.sessionStart
        local gained = Plugin.sessionGains[i] or 0

        if elapsed > 0 and gained > 0 then
            local perHour = floor(gained / elapsed * 3600)
            GameTooltip:AddDoubleLine("Rep/hour:", "+"..perHour)
        end

    else
        GameTooltip:AddLine("|cff888888No faction detected|r")
    end

    ------------------------------------------------
    -- SESSION GAINS
    ------------------------------------------------
    Datapanel:AddTooltipDivider(GameTooltip)
    GameTooltip:AddLine("|cff00ff00Session Gains|r")

    local total = 0
    local list = {}

    for i, v in pairs(Plugin.sessionGains) do
        if v > 0 then
            tinsert(list, {i=i, v=v})
            total = total + v
        end
    end

    tsort(list, function(a,b) return a.v > b.v end)

    if #list == 0 then
        GameTooltip:AddLine("|cff888888No gains yet|r")
    else
        GameTooltip:AddDoubleLine("Total:", "+"..total)
        GameTooltip:AddLine(" ")

        for _, data in ipairs(list) do
            local name, standingID = GetFactionData(data.i)
            local colorHex = GetStandingColor(standingID)

            GameTooltip:AddDoubleLine(
                name,
                format("|cff%s+%d|r", colorHex, data.v)
            )
        end
    end

    ------------------------------------------------
    -- ALL REPUTATIONS
    ------------------------------------------------
    Datapanel:AddTooltipDivider(GameTooltip)
    GameTooltip:AddLine("|cffffff00All Reputations|r")

    AddFactionBlock()

    ------------------------------------------------
    -- Footer
    ------------------------------------------------
    Datapanel:AddTooltipSpacer(GameTooltip)
    GameTooltip:AddLine("|cff00ff00Left Click: Open Reputation|r")
    GameTooltip:AddLine("|cff00ff00Shift Click: Reset Session|r")

    GameTooltip:Show()

end

--============================================================
-- CreateFrame
--============================================================
function Plugin:CreateFrame(parent)

    local f = CreateFrame("Button", nil, parent)

    f:SetHeight(20)
    f:EnableMouse(true)
    f:RegisterForClicks("LeftButtonUp")

    f.text = f:CreateFontString(nil, "OVERLAY")
    Datapanel:ApplyStandardFont(f.text)
    f.text:SetPoint("CENTER")

    f:SetScript("OnEnter", ShowTooltip)
    f:SetScript("OnLeave", GameTooltip_Hide)

    f:SetScript("OnClick", function()
        if IsShiftKeyDown() then
            Plugin.sessionGains = {}
            Plugin.sessionStart = GetTime()
        else
            ToggleCharacter("ReputationFrame")
        end
    end)

    self.frame = f
    self:Refresh()

    return f

end

--============================================================
-- Register
--============================================================
Datapanel:RegisterPlugin("reputation", Plugin)