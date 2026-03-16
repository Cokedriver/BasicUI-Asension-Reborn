--============================================================
-- MODULE: Datapanel
--============================================================

local addonName, BasicUI = ...
local BasicDB = _G.BasicDB

local M = {}
M.plugins = {}
M.refreshers = {}

--============================================================
-- SLOT LIST (ADDED)
--============================================================

local POSITION_LIST = {
    [0] = "Hidden",
    [1] = "Position 1",
    [2] = "Position 2",
    [3] = "Position 3",
    [4] = "Position 4",
    [5] = "Position 5",
    [6] = "Position 6",
    [7] = "Position 7",
    [8] = "Position 8",
}

--============================================================
-- Defaults
--============================================================

M.defaults = {
	enabled = true,

    panel = {
        fontSize = 16,
    },

    plugins = {
        performance = { position = 1 },
        friends = { position = 2 },
        guild = { position = 3 },
        mainstats = { position = 4 },
        spec = { position = 5 },
        professions = { position = 6 },
        durability = { position = 7 },
        bagspace = { position = 8 },
    }

}

--============================================================
-- Enable / Disable (LIVE TOGGLE)
--============================================================

function M:EnablePanel()

    if not self.panel then
        self:CreatePanel()
    end

    if self.panel then
        self.panel:Show()
    end

    -- Always redock the bar
    self:DockMainMenuBar()

    self:UpdatePanel()

end

function M:DisablePanel()

    if self.panel then
        self.panel:Hide()
    end

    -- restore Blizzard default position
    if MainMenuBar then
        MainMenuBar:ClearAllPoints()
        MainMenuBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
    end

end

--============================================================
-- Plugin Enable Toggle
--============================================================

function M:SetPluginEnabled(pluginName, enabled)

    if not self.db.plugins or not self.db.plugins[pluginName] then return end

    if enabled then
        if self.db.plugins[pluginName].position == 0 then
            self.db.plugins[pluginName].position = 1
        end
    else
        self.db.plugins[pluginName].position = 0
    end

    self:UpdatePanel()

end

--============================================================
-- Init
--============================================================
function M:OnInit()

    BasicDB = BasicDB or {}
    BasicDB.Datapanel = BasicDB.Datapanel or {}

    self.db = BasicDB.Datapanel

    BasicUI:CopyDefaults(self.defaults, self.db)

end

--============================================================
-- Enable
--============================================================
function M:OnEnable()

    if self.db.enabled == false then
        if self.panel then
            self.panel:Hide()
        end
        return
    end

    ------------------------------------------------
    -- Create panel if needed
    ------------------------------------------------

    if not self.panel then
        self:CreatePanel()
    end

    if not self.panel then return end

    self.panel:Show()

    self:DockMainMenuBar()

    ------------------------------------------------
    -- Enable plugins
    ------------------------------------------------

    local ordered = self:GetSortedPlugins()

    for _, plugin in ipairs(ordered) do

        if plugin.OnEnable then
            plugin:OnEnable()
        end

        if plugin.CreateFrame then
            plugin.frame = plugin:CreateFrame(self.panel)
        end

    end

    ------------------------------------------------
    -- Initial refresh
    ------------------------------------------------

    for _, plugin in pairs(self.plugins) do
        if plugin.Refresh then
            plugin:Refresh()
        end
    end

	self:UpdatePanel()
	self:StartRefreshEngine()
	--self:ApplyTooltipFont()
	--self:ApplyEasyMenuFont()

	GameTooltip:HookScript("OnEnter", function(self)
		if self == GameTooltip then
			GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
		end
	end)

	self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		if M.db and M.db.enabled then
			C_Timer.After(0.1, function()
				self:DockMainMenuBar()
			end)
		end
	end)

	hooksecurefunc("UIParent_ManageFramePositions", function()
		if M.db and M.db.enabled then
			M:DockMainMenuBar()
		end
	end)

	

end

--============================================================
-- Register Plugin
--============================================================
function M:RegisterPlugin(name, plugin)

    plugin.name = name

    BasicDB = BasicDB or {}
    BasicDB.Datapanel = BasicDB.Datapanel or {}

    self.db = BasicDB.Datapanel
    self.db.plugins = self.db.plugins or {}

    self.db.plugins[name] = self.db.plugins[name] or {}

    plugin.db = self.db.plugins[name]

	if not plugin.db.position then
		plugin.db.position = self.defaults.plugins[name]
			and self.defaults.plugins[name].position
			or 999
	end

    self.plugins[name] = plugin

end

--============================================================
-- Refresh Engine
--============================================================
function M:RegisterRefresh(plugin, interval)

    table.insert(self.refreshers, {
        plugin = plugin,
        interval = interval or 1,
        timer = 0
    })

end

function M:StartRefreshEngine()

    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function(_, elapsed)
        for _, r in ipairs(self.refreshers) do
            r.timer = r.timer + elapsed
            if r.timer >= r.interval then
                if r.plugin.Refresh then
                    r.plugin:Refresh()
                end
                r.timer = 0
            end
        end
    end)

end

--============================================================
-- Event Proxy
--============================================================
function M:RegisterEvent(event, func)

    if not self.eventFrame then

        self.eventFrame = CreateFrame("Frame")

        self.eventFrame:SetScript("OnEvent", function(_, event, ...)
            if self.events[event] then
                for _, handler in ipairs(self.events[event]) do
                    handler(...)
                end
            end
        end)

        self.events = {}

    end

    self.events[event] = self.events[event] or {}
    table.insert(self.events[event], func)

    self.eventFrame:RegisterEvent(event)

end

--============================================================
-- Panel Creation
--============================================================
function M:CreatePanel()

    local f = CreateFrame("Frame", "BasicUI_DataPanel", UIParent)

    f:SetHeight(28)

    -- width that matches gryphons
    --local width = MainMenuBar:GetWidth() + 175	
	local width =
    MainMenuBar:GetWidth() +
    MainMenuBarLeftEndCap:GetWidth() +
    MainMenuBarRightEndCap:GetWidth() - 70
	
    f:SetWidth(width)
    f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = {left=4,right=4,top=4,bottom=4}
    })

    f:SetBackdropColor(0,0,0,1)
	
    self.panel = f
end

function M:DockMainMenuBar()

    if not MainMenuBar or not self.panel then return end

    if InCombatLockdown() then return end

    MainMenuBar:ClearAllPoints()
    MainMenuBar:SetPoint("BOTTOM", self.panel, "TOP", 0, -2)

    MainMenuBar:SetFrameStrata("HIGH")
    MainMenuBar:SetFrameLevel(20)

end

--============================================================
-- Plugin Helpers
--============================================================
function M:CreatePluginFrame(parent)

    local f = CreateFrame("Button", nil, parent)

    f:SetHeight(22)
    f:EnableMouse(true)
    f:RegisterForClicks("LeftButtonUp")

    f.text = f:CreateFontString(nil,"OVERLAY")
    self:ApplyStandardFont(f.text)

    f.text:SetPoint("CENTER")

    return f

end

function M:SetPluginText(plugin, text)

    if not plugin.frame then return end

    plugin.frame.text:SetText(text)

    plugin.frame:SetWidth(plugin.frame.text:GetStringWidth()+12)

end

function M:SetPluginPosition(plugin, pos)

    -- disable plugin
    if pos == 0 then
        M.db.plugins[plugin].position = 0
        return
    end

    -- swap positions if another plugin already uses it
    for name, data in pairs(M.db.plugins) do
        if name ~= plugin and data.position == pos then
            data.position = M.db.plugins[plugin].position
        end
    end

    M.db.plugins[plugin].position = pos

end

--============================================================
-- Font
--============================================================
function M:ApplyStandardFont(fs)

    fs:SetFont(
        BasicUI:GetBasicFont("N"),
        self.db.panel.fontSize or 16,
        "OUTLINE"
    )

end

--============================================================
-- Class Color
--============================================================
function M:GetClassHex()

    local _, class = UnitClass("player")

    local c = RAID_CLASS_COLORS[class] or {r=1,g=1,b=1}

    return string.format("%02x%02x%02x",c.r*255,c.g*255,c.b*255)

end

--============================================================
-- Tooltip Helpers
--============================================================
function M:GetColoredPlayerHeader(pluginName)

    local name = UnitName("player")
    local hex = BasicUI:GetClassHex()

    return "|cff"..hex..name.."'s "..pluginName.."|r"

end

function M:AddTooltipHeader(tooltip,pluginName)

    tooltip:AddLine(self:GetColoredPlayerHeader(pluginName))

end

function M:AddTooltipDivider(tooltip)

    tooltip:AddLine("-------------------------",0.4,0.4,0.4)

end

function M:AddTooltipSpacer(tooltip)

    tooltip:AddLine(" ")

end

function M:AddTooltipLine(tooltip,text,r,g,b)

    tooltip:AddLine(text,r or 1,g or 1,b or 1)

end

function M:AddTooltipDoubleLine(tooltip,left,right,lr,lg,lb,rr,rg,rb)

    tooltip:AddDoubleLine(
        left,
        right,
        lr or 1,lg or 1,lb or 1,
        rr or 1,rg or 1,rb or 1
    )

end

--============================================================
-- Plugin Sorting
--============================================================
function M:GetSortedPlugins()

    local ordered = {}

    for name,plugin in pairs(self.plugins) do
        table.insert(ordered,plugin)
    end

    table.sort(ordered,function(a,b)

        local pa = a.db.position or 999
        local pb = b.db.position or 999

        if pa == pb then
            return a.name < b.name
        end

        return pa < pb

    end)

    return ordered

end

--============================================================
-- Layout
--============================================================
function M:UpdatePanel()

    if not self.panel then return end

    local panelWidth = self.panel:GetWidth()
    local slotCount = 8
    local spacing = 0

    local usableWidth = panelWidth - (spacing * (slotCount - 1))
    local slotWidth = usableWidth / slotCount

    for name, plugin in pairs(self.plugins) do

        if plugin.frame then

            local pos = plugin.db.position

            if not pos or pos == 0 then
                plugin.frame:Hide()
            else
                plugin.frame:Show()

                -- Calculate true slot center
                local slotCenter = (-panelWidth / 2) +
                                   ((pos - 1) * (slotWidth + spacing)) +
                                   (slotWidth / 2)

                plugin.frame:ClearAllPoints()
                plugin.frame:SetPoint("CENTER", self.panel, "CENTER", slotCenter, 1)

            end

        end

    end

end

--============================================================
-- OPTIONS
--============================================================

local pluginPositions = function()
	local t = { [0] = "Disabled" }
	for i = 1, 8 do
		t[i] = "Position " .. i
	end
	return t
end

M.options = {
    type = "group",
    name = "Data Panel",
    args = {

        enabled = {
            type = "toggle",
            name = "Enable Datapanel",
            desc = "Enable or disable the BasicUI datapanel.",
            order = 1,
			width = "full",
            get = function() return M.db.enabled end,
			set = function(_, v)
				M.db.enabled = v

				if v then
					M:EnablePanel()
				else
					M:DisablePanel()
				end
			end,
        },

        ------------------------------------------------
        -- Panel Settings
        ------------------------------------------------

		panel = {
			type = "group",
			name = "Panel Settings",
			inline = true,
			order = 2,
			disabled = function() return not M.db.enabled end,
            args = {

                fontSize = {
                    type = "range",
                    name = "Font Size",
                    desc = "Adjust the font size used on the data panel.",
                    min = 8, max = 32, step = 1,
                    order = 1,
                    get = function() return M.db.panel.fontSize end,
					set = function(_, v)
						M.db.panel.fontSize = v

						for _, plugin in pairs(M.plugins) do
							if plugin.frame and plugin.frame.text then
								M:ApplyStandardFont(plugin.frame.text)
							end
						end

						M:UpdatePanel()
					end,
                },

            },
        },

        ------------------------------------------------
        -- Plugins
        ------------------------------------------------

		plugins = {
			type = "group",
			name = "Plugins",
			inline = true,
			order = 3,
			disabled = function() return not M.db.enabled end,
            args = {

                performance = {
                    type = "select",
                    name = "Performance",
                    desc = "Displays FPS and latency information.",
                    order = 1,
                    values = pluginPositions,
                    get = function() return M.db.plugins.performance.position end,
                    set = function(_, v)
                        M:SetPluginPosition("performance", v)
                        M:UpdatePanel()
                    end,
                },

                friends = {
                    type = "select",
                    name = "Friends",
                    desc = "Displays online Battle.net and in-game friends.",
                    order = 2,
                    values = pluginPositions,
                    get = function() return M.db.plugins.friends.position end,
                    set = function(_, v)
                        M:SetPluginPosition("friends", v)
                        M:UpdatePanel()
                    end,
                },

                guild = {
                    type = "select",
                    name = "Guild",
                    desc = "Displays online guild members.",
                    order = 3,
                    values = pluginPositions,
                    get = function() return M.db.plugins.guild.position end,
                    set = function(_, v)
                        M:SetPluginPosition("guild", v)
                        M:UpdatePanel()
                    end,
                },

                mainstats = {
                    type = "select",
                    name = "Main Stats",
                    desc = "Displays your primary character statistics.",
                    order = 4,
                    values = pluginPositions,
                    get = function() return M.db.plugins.mainstats.position end,
                    set = function(_, v)
                        M:SetPluginPosition("mainstats", v)
                        M:UpdatePanel()
                    end,
                },

                spec = {
                    type = "select",
                    name = "Specialization",
                    desc = "Displays your current specialization.",
                    order = 5,
                    values = pluginPositions,
                    get = function() return M.db.plugins.spec.position end,
                    set = function(_, v)
                        M:SetPluginPosition("spec", v)
                        M:UpdatePanel()
                    end,
                },

                professions = {
                    type = "select",
                    name = "Professions",
                    desc = "Displays your character professions.",
                    order = 6,
                    values = pluginPositions,
                    get = function() return M.db.plugins.professions.position end,
                    set = function(_, v)
                        M:SetPluginPosition("professions", v)
                        M:UpdatePanel()
                    end,
                },

                durability = {
                    type = "select",
                    name = "Durability",
                    desc = "Displays equipment durability information.",
                    order = 7,
                    values = pluginPositions,
                    get = function() return M.db.plugins.durability.position end,
                    set = function(_, v)
                        M:SetPluginPosition("durability", v)
                        M:UpdatePanel()
                    end,
                },

                bagspace = {
                    type = "select",
                    name = "Bag Space",
                    desc = "Displays remaining bag space.",
                    order = 8,
                    values = pluginPositions,
                    get = function() return M.db.plugins.bagspace.position end,
                    set = function(_, v)
                        M:SetPluginPosition("bagspace", v)
                        M:UpdatePanel()
                    end,
                },

            },
        },

    },
}

--============================================================
-- Register Module
--============================================================
BasicUI:RegisterModule("Datapanel",M)