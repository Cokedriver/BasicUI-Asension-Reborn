--==============================
-- PLUGIN: Performance
--==============================

local Datapanel = BasicUI:GetModule("Datapanel")
if not Datapanel then return end

local floor = math.floor
local format = string.format
local tinsert = table.insert
local sort = table.sort

local Plugin = {}
Plugin.name = "performance"

--============================================================
-- OnEnable
--============================================================
function Plugin:OnEnable()

    Datapanel:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:Refresh()
    end)

end

--============================================================
-- Refresh (panel text)
--============================================================
function Plugin:Refresh()

    if not self.frame then return end

    local fps = floor(GetFramerate() or 0)
    local hex = BasicUI:GetClassHex()

    self.frame.text:SetText(format("|cff%sFPS:|r %d", hex, fps))
    self.frame:SetWidth(self.frame.text:GetStringWidth() + 12)

end

--============================================================
-- Tooltip
--============================================================
local function ShowTooltip(self)

	local Datapanel = BasicUI:GetModule("Datapanel")

	if Datapanel and Datapanel.AnchorTooltip then
		Datapanel:AnchorTooltip(GameTooltip, self)
	else
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
	end

	GameTooltip:ClearLines()

    local header = Datapanel:GetColoredPlayerHeader("Performance")
    GameTooltip:AddLine(header)

    local fps = floor(GetFramerate() or 0)

    local _, _, home, world = GetNetStats()
    home = home or 0
    world = world or 0

    GameTooltip:AddDoubleLine("|cffffff00FPS:|r", "|cffffffff"..fps.."|r")
    GameTooltip:AddDoubleLine("|cffffff00Latency Home:|r", "|cffffffff"..home.." ms|r")
    GameTooltip:AddDoubleLine("|cffffff00Latency World:|r", "|cffffffff"..world.." ms|r")

    GameTooltip:AddLine("|cff666666-------------------------|r")

    --============================================================
    -- Memory Breakdown
    --============================================================

    UpdateAddOnMemoryUsage()

    local total = 0
    local addons = {}
    local numAddons = GetNumAddOns()

    for i = 1, numAddons do

        if IsAddOnLoaded(i) then

            local mem = GetAddOnMemoryUsage(i) or 0
            local name = GetAddOnInfo(i)

            total = total + mem

            tinsert(addons, {
                name = name,
                mem = mem
            })

        end

    end

    sort(addons, function(a,b)
        return a.mem > b.mem
    end)

    GameTooltip:AddDoubleLine(
        "|cffffff00Total AddOn Memory:|r",
        format("|cffffffff%.1f MB|r", total/1024)
    )

    GameTooltip:AddLine(" ")

    for i = 1, math.min(15, #addons) do

        local a = addons[i]

        GameTooltip:AddDoubleLine(
            "|cffffffff"..(a.name or "Unknown").."|r",
            format("|cffffffff%.1f MB|r", a.mem/1024)
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
    Datapanel:ApplyStandardFont(f.text)

    f.text:SetPoint("CENTER")

    f:SetScript("OnEnter", ShowTooltip)
    f:SetScript("OnLeave", GameTooltip_Hide)

    f:SetScript("OnClick", function()
        collectgarbage("collect")
        self:Refresh()
    end)

    f:SetScript("OnUpdate", function(selfFrame, elapsed)

        selfFrame.timer = (selfFrame.timer or 0) + elapsed

        if selfFrame.timer >= 1 then

            Plugin:Refresh()

            selfFrame.timer = 0

        end

    end)

    self.frame = f
    self:Refresh()

    return f

end

--============================================================
-- Register plugin
--============================================================
Datapanel:RegisterPlugin("performance", Plugin)