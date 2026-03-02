--============================================================
-- PLUGIN: Friends (Enhanced for Ascension/WR)
-- Datapanel version (no Ace3, no options UI)
--============================================================
local parent = BasicUI:GetModule("Datapanel")
local M = parent

local Plugin = {}
Plugin.name = "friends"

--============================================================
-- Helpers
--============================================================

local STATUS_ICONS = {
    ["AFK"] = "|cffaaaaaa[AFK]|r ",
    ["DND"] = "|cffff5555[DND]|r ",
}

local function GetStatusIcon(status)
    if not status then return "" end
    return STATUS_ICONS[status] or ""
end

--============================================================
-- Faction detection (WR/Ascension: GetFriendInfo() returns nil)
--============================================================

local function DetectFactionFromClassColor(classFile)
    local cc = RAID_CLASS_COLORS[classFile]
    if not cc then return nil end

    -- Horde colors are slightly darker on WR
    if cc.r < 0.8 and cc.g < 0.8 then
        return "Horde"
    else
        return "Alliance"
    end
end

--============================================================
-- Faction letter (no icons)
--============================================================
local function GetFactionLetterFromClass(classFile)
    local faction = DetectFactionFromClassColor(classFile)

    if faction == "Alliance" then
        return "|cff0070ffA|r "   -- Blue A
    elseif faction == "Horde" then
        return "|cffff2020H|r "   -- Red H
    end

    return ""
end

--============================================================
-- Difficulty color for level + zone
--============================================================
local function GetDifficultyColor(friendLevel)
    local playerLevel = UnitLevel("player")
    local diff = friendLevel - playerLevel

    if diff >= 5 then
        return "|cffff0000"   -- Red (much higher)
    elseif diff >= 3 then
        return "|cffff7f00"   -- Orange (higher)
    elseif diff >= -2 then
        return "|cffffff00"   -- Yellow (even match)
    elseif diff >= -10 then
        return "|cff1eff00"   -- Green (lower)
    else
        return "|cff9d9d9d"   -- Grey (trivial)
    end
end

--============================================================
-- Clean Ascension "added as" junk from zone
--============================================================
local function CleanZone(rawZone)
    if not rawZone or rawZone == "" then
        return "Unknown"
    end

    local zone = rawZone
    zone = zone:gsub("%s*[Aa]dded as[:]?%s*%b()", "")
    zone = zone:gsub("%s*[Aa]dded as[:]?.*$", "")
    zone = zone:gsub("%s*%b()", "")
    zone = zone:gsub("^%s+", ""):gsub("%s+$", "")

    if zone == "" then
        zone = "Unknown"
    end

    return zone
end

--============================================================
-- Count online friends
--============================================================
local function CountFriendsOnline()
    local total = GetNumFriends()
    local online = 0

    for i = 1, total do
        local _, _, _, _, connected = GetFriendInfo(i)
        if connected then online = online + 1 end
    end

    return online, total
end

--============================================================
-- OnEnable
--============================================================
function Plugin:OnEnable()
    M:RegisterEvent("FRIENDLIST_UPDATE", function()
        Plugin:Refresh()
    end)

    M:RegisterEvent("FRIEND_METADATA_CHANGED", function()
        Plugin:Refresh()
    end)

    M:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        if ShowFriends then ShowFriends() end
        Plugin:Refresh()
    end)
end

--============================================================
-- Refresh (panel text)
--============================================================
function Plugin:Refresh()
    if not self.frame then return end

    if ShowFriends then ShowFriends() end

    local online = CountFriendsOnline()
    local hex = M:GetClassHex()

    self.frame.text:SetText("|cff" .. hex .. "Friends:|r " .. online)
    self.frame:SetWidth(self.frame.text:GetStringWidth() + 12)
end

--============================================================
-- Tooltip
--============================================================
local function ShowTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:ClearLines()

    local online, total = CountFriendsOnline()

    -- Header
    local header = M:GetColoredPlayerHeader("Friends")
    GameTooltip:AddLine(header)
    GameTooltip:AddLine(" ")

    --============================================================
    -- Build friend list
    --============================================================
    local friends = {}

    for i = 1, total do
        local name, level, classLoc, zone, connected, status =
            GetFriendInfo(i)

        if connected and name then
            local cleanZone = CleanZone(zone)

            -- Convert localized class to file key
            local classFile
            for eng, loc in pairs(LOCALIZED_CLASS_NAMES_MALE) do
                if loc == classLoc then classFile = eng break end
            end
            if not classFile then
                for eng, loc in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
                    if loc == classLoc then classFile = eng break end
                end
            end

            table.insert(friends, {
                name      = name,
                level     = level or 0,
                classFile = classFile,
                zone      = cleanZone,
                status    = status,
            })
        end
    end

    --============================================================
    -- Sorting: zone → class → level → name
    --============================================================
    table.sort(friends, function(a, b)
        if a.zone ~= b.zone then
            return a.zone < b.zone
        end
        if a.classFile ~= b.classFile then
            return (a.classFile or "") < (b.classFile or "")
        end
        if a.level ~= b.level then
            return a.level > b.level
        end
        return a.name < b.name
    end)

    --============================================================
    -- Single-line friend → zone rows
    --============================================================
    for _, f in ipairs(friends) do
        local cc = RAID_CLASS_COLORS[f.classFile] or { r = 1, g = 1, b = 1 }
        local factionLetter = GetFactionLetterFromClass(f.classFile)
        local statusIcon = GetStatusIcon(f.status)

        local coloredName = string.format(
            "|cff%02x%02x%02x%s|r",
            cc.r * 255, cc.g * 255, cc.b * 255,
            f.name
        )

        -- Difficulty-colored level
        local levelColor = GetDifficultyColor(f.level)

        -- LEFT: [Level] Faction Status Name
        local leftText = string.format(
            "%s[%d]|r %s%s",
            levelColor,
            f.level,
            --factionLetter,
            statusIcon,
            coloredName
        )

		-- RIGHT: Zone (Changed from dynamic level color to static grey)
		local rightText = string.format("|cffaaaaaa%s|r", f.zone)

        GameTooltip:AddDoubleLine(leftText, rightText, 1, 1, 1, 1, 1, 1)
    end

    if #friends == 0 then
        GameTooltip:AddLine("|cff888888No friends online.|r")
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff00ff00<Left-Click> Open Friends List|r")
    GameTooltip:AddLine("|cff00ff00<Right-Click> Open Friend Menu|r")

    GameTooltip:Show()
end

--============================================================
-- Right-click Menu Builder
--============================================================
local menuFrame = CreateFrame("Frame", "DatapanelFriendsMenu", UIParent, "UIDropDownMenuTemplate")

local function OpenFriendMenu()
    local total = GetNumFriends()
    local menu = {
        { text = "Friends Online", isTitle = true, notCheckable = true },
    }

    for i = 1, total do
        local fname, level, classLoc, _, connected =
            GetFriendInfo(i)

        if connected and fname then
            local classFile
            for eng, loc in pairs(LOCALIZED_CLASS_NAMES_MALE) do
                if loc == classLoc then classFile = eng break end
            end
            if not classFile then
                for eng, loc in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
                    if loc == classLoc then classFile = eng break end
                end
            end

            local cc = RAID_CLASS_COLORS[classFile] or { r = 1, g = 1, b = 1 }
            local hex = string.format("|cff%02x%02x%02x", cc.r * 255, cc.g * 255, cc.b * 255)

            table.insert(menu, {
                text = string.format("%s%s|r |cffbbbbbb(%d)|r", hex, fname, level or 0),
                hasArrow = true,
                notCheckable = true,
                menuList = {
                    {
                        text = "Whisper",
                        func = function()
                            ChatFrame_OpenChat("/w " .. fname .. " ")
                        end,
                        notCheckable = true,
                    },
                    {
                        text = "Invite",
                        func = function()
                            InviteUnit(fname)
                        end,
                        notCheckable = true,
                    },
                },
            })
        end
    end

    if #menu == 1 then
        table.insert(menu, {
            text = "No friends online",
            disabled = true,
            notCheckable = true,
        })
    end

    EasyMenu(menu, menuFrame, "cursor", 0, 0, "MENU")
end

--============================================================
-- CreateFrame
--============================================================
function Plugin:CreateFrame(parent)
    local f = CreateFrame("Button", nil, parent)
    f:SetHeight(20)
    f:EnableMouse(true)

    f.text = f:CreateFontString(nil, "OVERLAY")
    M:ApplyStandardFont(f.text)
    f.text:SetPoint("CENTER")

    f:SetScript("OnEnter", ShowTooltip)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    f:SetScript("OnMouseDown", function(_, btn)
        if btn == "LeftButton" then
            ToggleFriendsFrame(1)
        elseif btn == "RightButton" then
            if DropDownList1 and DropDownList1:IsShown() then
                CloseDropDownMenus()
            else
                OpenFriendMenu()
            end
        end
    end)

    -- Auto-refresh every 5 seconds
    f:SetScript("OnUpdate", function(self, elapsed)
        self.timer = (self.timer or 0) + elapsed
        if self.timer > 5 then
            if ShowFriends then ShowFriends() end
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
M:RegisterPlugin("friends", Plugin)
