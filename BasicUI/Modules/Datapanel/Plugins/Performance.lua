--============================================================
-- PLUGIN: Performance
-- Datapanel version (no Ace3, no options UI)
--============================================================
local parent = BasicUI:GetModule("Datapanel")
local M = parent

local Plugin = {}
Plugin.name = "performance"

--============================================================
-- OnEnable
--============================================================
function Plugin:OnEnable()
    -- Initial refresh after login
    M:RegisterEvent("PLAYER_ENTERING_WORLD", function() Plugin:Refresh() end)
end

--============================================================
-- Refresh (panel text)
--============================================================
function Plugin:Refresh()
    if not self.frame then return end

    local fps = math.floor(GetFramerate())
    local hex = M:GetClassHex()

    local text = string.format("|cff%sFPS:|r %d", hex, fps)
    self.frame.text:SetText(text)
end



--============================================================
-- Tooltip
--============================================================
local function ShowTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:ClearLines()

    -- Class‑colored header
    local header = M:GetColoredPlayerHeader("Performance")
    GameTooltip:AddLine(header)

    -- FPS
    local fps = tonumber(GetFramerate()) or 0
    fps = math.floor(fps)

    -- Latency
    local _, _, home, world = GetNetStats()
    home  = tonumber(home)  or 0
    world = tonumber(world) or 0

    -- Yellow titles, white numbers
    GameTooltip:AddDoubleLine("|cffffff00FPS:|r", "|cffffffff" .. fps .. "|r")
    GameTooltip:AddDoubleLine("|cffffff00Latency Home:|r", "|cffffffff" .. home .. " ms|r")
    GameTooltip:AddDoubleLine("|cffffff00Latency World:|r", "|cffffffff" .. world .. " ms|r")
    GameTooltip:AddLine("|cff666666-------------------------|r")

    -- Memory breakdown
    UpdateAddOnMemoryUsage()
    local total = 0
    local addons = {}

    for i = 1, GetNumAddOns() do
        if IsAddOnLoaded(i) then
            local mem = tonumber(GetAddOnMemoryUsage(i)) or 0
            total = total + mem
            table.insert(addons, { name = GetAddOnInfo(i), mem = mem })
        end
    end

    table.sort(addons, function(a,b) return a.mem > b.mem end)

    GameTooltip:AddDoubleLine(
        "|cffffff00Total AddOn Memory:|r",
        string.format("|cffffffff%.1f MB|r", total/1024)
    )

    GameTooltip:AddLine(" ")

    for i = 1, math.min(15, #addons) do
        local a = addons[i]
        GameTooltip:AddDoubleLine(
            "|cffffffff" .. a.name .. "|r",
            string.format("|cffffffff%.1f MB|r", a.mem/1024)
        )
    end

    if #addons > 15 then
        GameTooltip:AddLine("|cff888888... and more|r")
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff00ff00<Left-Click to Force Garbage Collection>|r")

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
    M:ApplyStandardFont(f.text)

    -- Correct centering inside the plugin slot
    f.text:ClearAllPoints()
    f.text:SetPoint("CENTER", f, "CENTER")

    f:SetScript("OnEnter", ShowTooltip)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    f:SetScript("OnClick", function()
        collectgarbage("collect")
        Plugin:Refresh()
    end)

    f:SetScript("OnUpdate", function(self, elapsed)
        self.timer = (self.timer or 0) + elapsed
        if self.timer > 1 then
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
M:RegisterPlugin("performance", Plugin)
