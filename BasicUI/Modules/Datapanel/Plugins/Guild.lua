--==============================
-- PLUGIN: Guild
--==============================

local Datapanel = BasicUI:GetModule("Datapanel")
if not Datapanel then return end

local Plugin = {}
Plugin.name = "guild"

--============================================================
-- OnEnable
--============================================================
function Plugin:OnEnable()

    Datapanel:RegisterEvent("GUILD_ROSTER_UPDATE", function()
        self:Refresh()
    end)

    Datapanel:RegisterEvent("PLAYER_ENTERING_WORLD", function()

        if IsInGuild() then
            GuildRoster()
            self:Refresh()
        end

    end)

end

--============================================================
-- Refresh (panel text)
--============================================================
function Plugin:Refresh()

    if not self.frame then return end

    if not IsInGuild() then

        self.frame.text:SetText("|cff"..BasicUI:GetClassHex().."No Guild|r")
        self.frame:SetWidth(self.frame.text:GetStringWidth() + 12)
        return

    end

    GuildRoster()

    local total = GetNumGuildMembers()
    local online = 0

    for i = 1, total do
        local _, _, _, _, _, _, _, _, connected = GetGuildRosterInfo(i)
        if connected then
            online = online + 1
        end
    end

    local hex = BasicUI:GetClassHex()

    self.frame.text:SetText("|cff"..hex.."Guild:|r "..online)
    self.frame:SetWidth(self.frame.text:GetStringWidth() + 12)

end

--============================================================
-- Tooltip
--============================================================
local function ShowTooltip(self)

    if not IsInGuild() then return end

	local Datapanel = BasicUI:GetModule("Datapanel")

	if Datapanel and Datapanel.AnchorTooltip then
		Datapanel:AnchorTooltip(GameTooltip, self)
	else
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
	end

	GameTooltip:ClearLines()

    local total = GetNumGuildMembers()
    local online = 0

    local header = Datapanel:GetColoredPlayerHeader("Guild")
    GameTooltip:AddLine(header)

    local guildName = GetGuildInfo("player") or "Unknown Guild"
    GameTooltip:AddLine("|cffFF66CC"..guildName.."|r")
    GameTooltip:AddLine("|cff666666-------------------------|r")

    for i = 1, total do
        local _, _, _, _, _, _, _, _, connected = GetGuildRosterInfo(i)
        if connected then
            online = online + 1
        end
    end

    GameTooltip:AddDoubleLine(
        "|cffffff00Online:|r",
        string.format("%d / %d", online, total),
        1,1,1,
        1,1,1
    )

    GameTooltip:AddLine(" ")

    for i = 1, total do

        -- ADDED note + officernote
        local name, _, _, level, classLoc, zone, note, officernote, connected, status, classFile =
            GetGuildRosterInfo(i)

        if connected and name then

            local diffColor = GetQuestDifficultyColor(level)

            local levelHex = string.format(
                "%02x%02x%02x",
                diffColor.r*255,
                diffColor.g*255,
                diffColor.b*255
            )

            local cc = RAID_CLASS_COLORS[classFile] or {r=1,g=1,b=1}

            local left = string.format(
                "|cff%s[%d]|r |cff%02x%02x%02x%s|r %s",
                levelHex,
                level,
                cc.r*255,
                cc.g*255,
                cc.b*255,
                name,
                status or ""
            )

            -- DEFAULT = zone
            local right = zone or "Unknown"

            -- SHIFT = show notes
            if IsShiftKeyDown() then
                if note and note ~= "" then
                    right = note
                elseif officernote and officernote ~= "" then
                    right = officernote
                else
                    right = "No Note"
                end
            end

            GameTooltip:AddDoubleLine(left, right, 1,1,1, 0.7,0.7,0.7)

        end

    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffaaaaaaHold Shift to show notes|r") -- ADDED
    GameTooltip:AddLine("|cff00ff00<Left-Click> Open Guild Roster|r")
    GameTooltip:AddLine("|cff00ff00<Right-Click> Open Guild Menu|r")

    GameTooltip:Show()

end

--============================================================
-- Right-click Menu Builder
--============================================================
local menuFrame = CreateFrame("Frame","DatapanelGuildMenu",UIParent,"UIDropDownMenuTemplate")

local function OpenGuildMenu()

    local total = GetNumGuildMembers()

    local menu = {
        { text = "Guild Members Online", isTitle = true, notCheckable = true },
    }

    for i = 1, total do

        local name, _, _, level, _, _, _, _, connected, _, classFile =
            GetGuildRosterInfo(i)

        if connected and name then

            local cc = RAID_CLASS_COLORS[classFile] or {r=1,g=1,b=1}

            local hex = string.format(
                "|cff%02x%02x%02x",
                cc.r*255,
                cc.g*255,
                cc.b*255
            )

            table.insert(menu,{
                text = string.format("|cffaaaaaa[%d]|r %s%s|r",level,hex,name),
                hasArrow = true,
                notCheckable = true,
                menuList = {
                    {
                        text = "Whisper",
                        func = function()
                            ChatFrame_OpenChat("/w "..name.." ")
                        end,
                        notCheckable = true
                    },
                    {
                        text = "Invite",
                        func = function()
                            InviteUnit(name)
                        end,
                        notCheckable = true
                    },
                }
            })

        end

    end

    EasyMenu(menu,menuFrame,"cursor",0,0,"MENU")

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

    f:SetScript("OnEnter",ShowTooltip)
    f:SetScript("OnLeave",function() GameTooltip:Hide() end)

    f:SetScript("OnMouseDown",function(_,btn)

        if btn == "LeftButton" then
            ToggleFriendsFrame(3)

        elseif btn == "RightButton" then

            if DropDownList1 and DropDownList1:IsShown() then
                CloseDropDownMenus()
            else
                OpenGuildMenu()
            end

        end

    end)

    -- ADDED: live refresh when holding/releasing shift
    f:SetScript("OnUpdate",function(self,elapsed)

        if GameTooltip:IsOwned(self) then
            ShowTooltip(self)
        end

        self.timer = (self.timer or 0) + elapsed

        if self.timer > 10 then

            if IsInGuild() then
                GuildRoster()
            end

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
Datapanel:RegisterPlugin("guild", Plugin)