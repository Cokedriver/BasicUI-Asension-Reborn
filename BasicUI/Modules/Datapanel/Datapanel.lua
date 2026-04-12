--============================================================
-- MODULE: Datapanel
--============================================================

local addonName, BasicUI = ...

local M = {}
M.plugins = {}
M.refreshers = {}

M.compat = {
    bartendar = IsAddOnLoaded("Bartender4"),
    dominos = IsAddOnLoaded("Dominos"),
    moveanything = IsAddOnLoaded("MoveAnything"),
}

--============================================================
-- Defaults
--============================================================

M.defaults = {
	enabled = true,
	
	position = "bottom",

	gryphons = {
		enabled = true,
	},

    panel = {
        fontSize = 16,
    },

    plugins = {
        performance = { position = 1 },
		reputation = { position = 2 },
        friends = { position = 3 },
        guild = { position = 4 },
        mainstats = { position = 5 },
        spec = { position = 6 },
        professions = { position = 7 },
        durability = { position = 8 },
        bagspace = { position = 9 },
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

    self:ApplyPanelPosition()
    self:UpdatePanel()

end

function M:DisablePanel()

    if self.panel then
        self.panel:Hide()
    end

    self:RestoreTopScreenLayout()

    -- restore Blizzard default position
    if MainMenuBar then
        MainMenuBar:ClearAllPoints()
        MainMenuBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
    end

end

--============================================================
--  Helper's
--============================================================

function M:ApplyGryphons()

    if not MainMenuBarLeftEndCap or not MainMenuBarRightEndCap then return end

    if self.db.gryphons and self.db.gryphons.enabled then
        MainMenuBarLeftEndCap:SetAlpha(1)
        MainMenuBarRightEndCap:SetAlpha(1)
        MainMenuBarLeftEndCap:Show()
        MainMenuBarRightEndCap:Show()
    else
        MainMenuBarLeftEndCap:SetAlpha(0)
        MainMenuBarRightEndCap:SetAlpha(0)
        MainMenuBarLeftEndCap:Hide()
        MainMenuBarRightEndCap:Hide()
    end

end

function M:GetExternalActionBar()

    -- Bartender4 bars
    if _G.BT4Bar1 then
        for i = 1, 10 do
            local bar = _G["BT4Bar"..i]
            if bar and bar:IsShown() then
                return bar
            end
        end
    end

    -- Dominos bars
    if _G.DominosActionBar1 then
        for i = 1, 10 do
            local bar = _G["DominosActionBar"..i]
            if bar and bar:IsShown() then
                return bar
            end
        end
    end

    return nil
end

function M:GetPanelTargetWidth()

    -- External bar addons first
    if self.GetExternalActionBar then
        local extBar = self:GetExternalActionBar()
        if extBar and extBar:IsShown() and extBar:GetWidth() and extBar:GetWidth() > 0 then
            return extBar:GetWidth()
        end
    end

    -- Blizzard gryphon-aware width
    if MainMenuBar then
        local leftEdge, rightEdge

        local gryphonsEnabled = self.db
            and self.db.gryphons
            and self.db.gryphons.enabled

        if gryphonsEnabled
            and MainMenuBarLeftEndCap
            and MainMenuBarRightEndCap
            and MainMenuBarLeftEndCap:IsShown()
            and MainMenuBarRightEndCap:IsShown()
        then
            leftEdge = MainMenuBarLeftEndCap:GetLeft()
            rightEdge = MainMenuBarRightEndCap:GetRight()

            if leftEdge and rightEdge then
                return rightEdge - leftEdge
            end
        end

        if MainMenuBarArtFrame
            and MainMenuBarArtFrame:IsShown()
            and MainMenuBarArtFrame:GetLeft()
            and MainMenuBarArtFrame:GetRight()
        then
            leftEdge = MainMenuBarArtFrame:GetLeft()
            rightEdge = MainMenuBarArtFrame:GetRight()

            if leftEdge and rightEdge then
                return rightEdge - leftEdge
            end
        end

        if MainMenuBar:GetLeft() and MainMenuBar:GetRight() then
            leftEdge = MainMenuBar:GetLeft()
            rightEdge = MainMenuBar:GetRight()

            if leftEdge and rightEdge then
                return rightEdge - leftEdge
            end
        end

        if MainMenuBar:GetWidth() and MainMenuBar:GetWidth() > 0 then
            return MainMenuBar:GetWidth()
        end
    end

    return 1024
end

function M:StartGryphonEnforcer()

    if self._gryphonEnforcer then return end

    local f = CreateFrame("Frame")
    local elapsedTotal = 0

    f:SetScript("OnUpdate", function(_, elapsed)
        elapsedTotal = elapsedTotal + elapsed

        if elapsedTotal >= 5 then
            f:SetScript("OnUpdate", nil)
            M._gryphonEnforcer = nil
            return
        end

        if not M.db or not M.db.enabled then return end
        if not M.db.gryphons then return end

        if M.db.gryphons.enabled == false then
            if MainMenuBarLeftEndCap then
                MainMenuBarLeftEndCap:SetAlpha(0)
                if MainMenuBarLeftEndCap:IsShown() then
                    MainMenuBarLeftEndCap:Hide()
                end
            end

            if MainMenuBarRightEndCap then
                MainMenuBarRightEndCap:SetAlpha(0)
                if MainMenuBarRightEndCap:IsShown() then
                    MainMenuBarRightEndCap:Hide()
                end
            end
        else
            if MainMenuBarLeftEndCap then
                MainMenuBarLeftEndCap:SetAlpha(1)
                if not MainMenuBarLeftEndCap:IsShown() then
                    MainMenuBarLeftEndCap:Show()
                end
            end

            if MainMenuBarRightEndCap then
                MainMenuBarRightEndCap:SetAlpha(1)
                if not MainMenuBarRightEndCap:IsShown() then
                    MainMenuBarRightEndCap:Show()
                end
            end
        end
    end)

    self._gryphonEnforcer = f
end

function M:SaveTopAnchors()

    if self._savedTopAnchors then return end
    self._savedTopAnchors = true

    self._minimapSaved = self._minimapSaved or {}
    self._buffSaved = self._buffSaved or {}
    self._tempEnchantSaved = self._tempEnchantSaved or {}

    if MinimapCluster then
        local point, relativeTo, relativePoint, xOfs, yOfs = MinimapCluster:GetPoint(1)
        self._minimapSaved.point = point
        self._minimapSaved.relativeTo = relativeTo
        self._minimapSaved.relativePoint = relativePoint
        self._minimapSaved.xOfs = xOfs
        self._minimapSaved.yOfs = yOfs
    end

    if BuffFrame then
        local point, relativeTo, relativePoint, xOfs, yOfs = BuffFrame:GetPoint(1)
        self._buffSaved.point = point
        self._buffSaved.relativeTo = relativeTo
        self._buffSaved.relativePoint = relativePoint
        self._buffSaved.xOfs = xOfs
        self._buffSaved.yOfs = yOfs
    end

    if TemporaryEnchantFrame then
        local point, relativeTo, relativePoint, xOfs, yOfs = TemporaryEnchantFrame:GetPoint(1)
        self._tempEnchantSaved.point = point
        self._tempEnchantSaved.relativeTo = relativeTo
        self._tempEnchantSaved.relativePoint = relativePoint
        self._tempEnchantSaved.xOfs = xOfs
        self._tempEnchantSaved.yOfs = yOfs
    end

end

function M:ApplyTopScreenLayout()

    if not self.panel then return end
    if InCombatLockdown() then
        self.pendingWidthUpdate = true
        return
    end

    self:SaveTopAnchors()

    self.panel:ClearAllPoints()
    self.panel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
    self.panel:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
    self.panel:SetWidth(UIParent:GetWidth())
    self.panel:Show()

    if MainMenuBar then
        MainMenuBar.ignoreFramePositionManager = true
        MainMenuBar:Show()
        MainMenuBar:SetAlpha(1)
        MainMenuBar:ClearAllPoints()
        MainMenuBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
        MainMenuBar:SetFrameStrata("HIGH")
        MainMenuBar:SetFrameLevel(20)
    end

    if MinimapCluster then
        MinimapCluster:ClearAllPoints()
        MinimapCluster:SetPoint("TOPRIGHT", self.panel, "BOTTOMRIGHT", -8, -6)
    end

    self:ApplyAuraAnchors()
end

function M:RestoreTopScreenLayout()

    self:StopTopLayoutEnforcer()

    if MinimapCluster and self._minimapSaved and self._minimapSaved.point then
        MinimapCluster:ClearAllPoints()
        MinimapCluster:SetPoint(
            self._minimapSaved.point,
            self._minimapSaved.relativeTo,
            self._minimapSaved.relativePoint,
            self._minimapSaved.xOfs,
            self._minimapSaved.yOfs
        )
    end

    if BuffFrame and self._buffSaved and self._buffSaved.point then
        BuffFrame:ClearAllPoints()
        BuffFrame:SetPoint(
            self._buffSaved.point,
            self._buffSaved.relativeTo,
            self._buffSaved.relativePoint,
            self._buffSaved.xOfs,
            self._buffSaved.yOfs
        )
    end

    if TemporaryEnchantFrame and self._tempEnchantSaved and self._tempEnchantSaved.point then
        TemporaryEnchantFrame:ClearAllPoints()
        TemporaryEnchantFrame:SetPoint(
            self._tempEnchantSaved.point,
            self._tempEnchantSaved.relativeTo,
            self._tempEnchantSaved.relativePoint,
            self._tempEnchantSaved.xOfs,
            self._tempEnchantSaved.yOfs
        )
    end
end

function M:ApplyPanelPosition()

    if not self.panel then return end

    if self.db.position == "top" then
        self:ApplyTopScreenLayout()
    else
        self:RestoreTopScreenLayout()
        self.panel:ClearAllPoints()
        self.panel:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
        self:UpdatePanelWidth()
        self:DockMainMenuBar()
        self:ApplyAuraAnchors()
    end

    self:UpdatePanel()
end

function M:StopTopLayoutEnforcer()
    if self._topLayoutEnforcer then
        self._topLayoutEnforcer:SetScript("OnUpdate", nil)
        self._topLayoutEnforcer = nil
    end
end

function M:StartTopLayoutEnforcer()
    if self._topLayoutEnforcer then return end

    local f = CreateFrame("Frame")
    local elapsedTotal = 0
    local tick = 0

    f:SetScript("OnUpdate", function(_, elapsed)
        if not M.db or not M.db.enabled then return end
        if M.db.position ~= "top" then
            M:StopTopLayoutEnforcer()
            return
        end

        elapsedTotal = elapsedTotal + elapsed
        tick = tick + elapsed

        -- run a little longer because private servers / Blizzard like to redraw these
        if elapsedTotal >= 8 then
            M:StopTopLayoutEnforcer()
            return
        end

        if tick < 0.10 then return end
        tick = 0

        if M.panel then
            M.panel:ClearAllPoints()
            M.panel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
            M.panel:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
            M.panel:SetWidth(UIParent:GetWidth())
        end

        if MainMenuBar then
            MainMenuBar.ignoreFramePositionManager = true
            MainMenuBar:Show()
            MainMenuBar:SetAlpha(1)
            MainMenuBar:ClearAllPoints()
            MainMenuBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
        end

        if MinimapCluster then
            MinimapCluster:ClearAllPoints()
            MinimapCluster:SetPoint("TOPRIGHT", M.panel, "BOTTOMRIGHT", -8, -6)
        end

        if BuffFrame then
            BuffFrame:ClearAllPoints()
            BuffFrame:SetPoint("TOPRIGHT", M.panel, "BOTTOMRIGHT", -180, -8)
        end

        if TemporaryEnchantFrame and BuffFrame then
            TemporaryEnchantFrame:ClearAllPoints()
            TemporaryEnchantFrame:SetPoint("TOPRIGHT", BuffFrame, "TOPLEFT", -10, 0)
        end
    end)

    self._topLayoutEnforcer = f
end

function M:GetFrameOffset(frame, point)
    if not frame or not point then return 0 end

    if point == "LEFT" and frame:GetLeft() and UIParent:GetLeft() then
        return frame:GetLeft() - UIParent:GetLeft()
    elseif point == "RIGHT" and frame:GetRight() and UIParent:GetRight() then
        return frame:GetRight() - UIParent:GetRight()
    elseif point == "TOP" and frame:GetTop() and UIParent:GetTop() then
        return frame:GetTop() - UIParent:GetTop()
    elseif point == "BOTTOM" and frame:GetBottom() and UIParent:GetBottom() then
        return frame:GetBottom() - UIParent:GetBottom()
    end

    return 0
end

function M:ApplyAuraAnchors()
    if not self.db or not self.db.enabled then return end
    if InCombatLockdown() then return end

    local anchor = MinimapCluster or Minimap or UIParent

    if self.db.position == "top" then
        if VanityBuffs then
            VanityBuffs:ClearAllPoints()
            VanityBuffs:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -5, 0)
        end

        if BuffFrame then
            BuffFrame:ClearAllPoints()
            BuffFrame:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -100, 0)
        end

        if TemporaryEnchantFrame then
            TemporaryEnchantFrame:ClearAllPoints()
            TemporaryEnchantFrame:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -190, 0)
        end

        if ConsolidatedBuffs then
            ConsolidatedBuffs:ClearAllPoints()
            ConsolidatedBuffs:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -280, 0)
        end
    else
        if VanityBuffs then
            VanityBuffs:ClearAllPoints()
            VanityBuffs:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -5, -2)
        end

        if BuffFrame then
            BuffFrame:ClearAllPoints()
            BuffFrame:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -100, 0)
        end

        if TemporaryEnchantFrame then
            TemporaryEnchantFrame:ClearAllPoints()
            TemporaryEnchantFrame:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -190, 0)
        end

        if ConsolidatedBuffs then
            ConsolidatedBuffs:ClearAllPoints()
            ConsolidatedBuffs:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -280, 0)
        end
    end
end

function M:AnchorTooltip(tooltip, owner)
    if not tooltip or not owner then return end

    tooltip:SetOwner(owner, "ANCHOR_NONE")
    tooltip:ClearAllPoints()

    if self.db and self.db.position == "top" then
        tooltip:SetPoint("TOP", owner, "BOTTOM", 0, -4)
    else
        tooltip:SetPoint("BOTTOM", owner, "TOP", 0, 4)
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

    -- Always bind to the live profile-backed DB
    self.db = self.core:GetProfileDB("Datapanel")

    -- Fill in any missing newer defaults
    BasicUI:CopyDefaults(self.defaults, self.db)

end

--============================================================
-- Enable
--============================================================
function M:OnEnable()

    -- Always rebind to the live profile-backed DB on enable
    self.db = self.core:GetProfileDB("Datapanel")
    BasicUI:CopyDefaults(self.defaults, self.db)

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

    -- Initial setup
    self:ApplyGryphons()
    self:ApplyPanelPosition()
    self:UpdatePanel()
    self:StartGryphonEnforcer()

    -- 🧠 FORCE RE-APPLY AFTER BLIZZARD LOAD / RELOAD
    C_Timer.After(0.05, function()
        if M and M.db and M.db.enabled then
            M:ApplyGryphons()
            M:ApplyPanelPosition()
            M:UpdatePanel()
        end
    end)

    -- 🧠 EXTRA LATE RE-APPLY FOR PRIVATE SERVER REDRAWS
    C_Timer.After(0.20, function()
        if M and M.db and M.db.enabled then
            M:ApplyGryphons()
            M:ApplyPanelPosition()
            M:UpdatePanel()
        end
    end)

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

    ------------------------------------------------
    -- Tooltip fix
    ------------------------------------------------

    GameTooltip:HookScript("OnEnter", function(self)
        if self == GameTooltip then
            GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        end
    end)

    ------------------------------------------------
    -- 🔁 REDOCK HANDLER (zoning / instances)
    ------------------------------------------------

    local function Redock()
        if M.db and M.db.enabled then
            C_Timer.After(0.05, function()
                M:ApplyGryphons()
                M:ApplyPanelPosition()
                M:UpdatePanel()
            end)
        end
    end

    self:RegisterEvent("PLAYER_ENTERING_WORLD", Redock)
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", Redock)

    ------------------------------------------------
    -- 🛡 Combat-safe width update
    ------------------------------------------------

    self:RegisterEvent("PLAYER_REGEN_ENABLED", function()
        if M.pendingWidthUpdate then
            M.pendingWidthUpdate = nil
            M:ApplyGryphons()
            M:ApplyPanelPosition()
            M:UpdatePanel()
        end
    end)

    ------------------------------------------------
    -- Blizzard frame manager override
    ------------------------------------------------

	hooksecurefunc("UIParent_ManageFramePositions", function()
		if not M.db or not M.db.enabled then return end

		if M.compat.moveanything or M.compat.bartendar or M.compat.dominos then
			return
		end

		M:ApplyGryphons()

		if M.db.position == "top" then
			M:ApplyTopScreenLayout()
		else
			M:ApplyPanelPosition()
		end

		M:UpdatePanel()
	end)

    ------------------------------------------------
    -- 🧠 Blizzard redraw protection
    ------------------------------------------------

    if type(MainMenuBar_Update) == "function" then
        hooksecurefunc("MainMenuBar_Update", function()
            if not M.db or not M.db.enabled then return end

            C_Timer.After(0.01, function()
                if M and M.db and M.db.enabled then
                    M:ApplyGryphons()
                    M:ApplyPanelPosition()
                    M:UpdatePanel()
                end
            end)

            C_Timer.After(0.10, function()
                if M and M.db and M.db.enabled then
                    M:ApplyGryphons()
                    M:ApplyPanelPosition()
                    M:UpdatePanel()
                end
            end)
        end)
    end

    ------------------------------------------------
    -- 🔒 HARD LOCK (prevents MoveAnything, etc)
    ------------------------------------------------

    if not MainMenuBar.__BasicUILocked then
        MainMenuBar.__BasicUILocked = true

        local isMoving = false

		hooksecurefunc(MainMenuBar, "SetPoint", function(frame)
			if isMoving then return end
			if not M.db or not M.db.enabled then return end
			if InCombatLockdown() then return end
			if not M.panel then return end

			-- do not fight external movers
			if M.compat.moveanything or M.compat.bartendar or M.compat.dominos then
				return
			end

			isMoving = true

			frame:ClearAllPoints()

			if M.db.position == "top" then
				frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
				frame:Show()
				frame:SetAlpha(1)
			else
				frame:SetPoint("BOTTOM", M.panel, "TOP", 0, -2)
			end

			isMoving = false
		end)
    end

    ------------------------------------------------
    -- 🦅 Gryphon show/hide detection
    ------------------------------------------------

    hooksecurefunc(MainMenuBarLeftEndCap, "SetShown", function()
        if not M.db or not M.db.enabled then return end

        if InCombatLockdown() then
            M.pendingWidthUpdate = true
        else
            M:ApplyGryphons()
            M:ApplyPanelPosition()
            M:UpdatePanel()
        end
    end)

    hooksecurefunc(MainMenuBarRightEndCap, "SetShown", function()
        if not M.db or not M.db.enabled then return end

        if InCombatLockdown() then
            M.pendingWidthUpdate = true
        else
            M:ApplyGryphons()
            M:ApplyPanelPosition()
            M:UpdatePanel()
        end
    end)

	------------------------------------------------
	-- Aura frame redraw protection (FULL)
	------------------------------------------------

	if not self._buffFrameHooked then
		self._buffFrameHooked = true

		local function Reanchor()
			if not M.db or not M.db.enabled then return end

			C_Timer.After(0, function()
				if M and M.ApplyAuraAnchors then
					M:ApplyAuraAnchors()
				end
			end)

			C_Timer.After(0.05, function()
				if M and M.ApplyAuraAnchors then
					M:ApplyAuraAnchors()
				end
			end)
		end

		if type(BuffFrame_Update) == "function" then
			hooksecurefunc("BuffFrame_Update", Reanchor)
		end

		if type(BuffFrame_UpdateAllBuffAnchors) == "function" then
			hooksecurefunc("BuffFrame_UpdateAllBuffAnchors", Reanchor)
		end
	end

    ------------------------------------------------
    -- Aura anchor protection
    ------------------------------------------------

    if not self._buffAnchorHooksInstalled then
        self._buffAnchorHooksInstalled = true

        if type(BuffFrame_Update) == "function" then
            hooksecurefunc("BuffFrame_Update", function()
                if not M.db or not M.db.enabled then return end

                C_Timer.After(0, function()
                    if M and M.ApplyAuraAnchors then
                        M:ApplyAuraAnchors()
                    end
                end)

                C_Timer.After(0.05, function()
                    if M and M.ApplyAuraAnchors then
                        M:ApplyAuraAnchors()
                    end
                end)
            end)
        end

        if type(BuffFrame_UpdateAllBuffAnchors) == "function" then
            hooksecurefunc("BuffFrame_UpdateAllBuffAnchors", function()
                if not M.db or not M.db.enabled then return end

                C_Timer.After(0, function()
                    if M and M.ApplyAuraAnchors then
                        M:ApplyAuraAnchors()
                    end
                end)

                C_Timer.After(0.05, function()
                    if M and M.ApplyAuraAnchors then
                        M:ApplyAuraAnchors()
                    end
                end)
            end)
        end
    end

	C_Timer.After(0.50, function()
		if M and M.db and M.db.enabled then
			M:ApplyGryphons()
			M:ApplyPanelPosition()
			M:UpdatePanel()
		end
	end)

end

--============================================================
-- Register Plugin
--============================================================
function M:RegisterPlugin(name, plugin)

    plugin.name = name

    -- Always bind to the live profile-backed DB
    self.db = self.core:GetProfileDB("Datapanel")
    self.db.plugins = self.db.plugins or {}

    self.db.plugins[name] = self.db.plugins[name] or {}

    plugin.db = self.db.plugins[name]

    if plugin.db.position == nil then
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

function M:GetActiveBar()

    -- Bartender4
    if _G.BT4Bar1 and _G.BT4Bar1:IsShown() then
        return _G.BT4Bar1
    end

    -- Dominos
    if _G.DominosActionBar1 and _G.DominosActionBar1:IsShown() then
        return _G.DominosActionBar1
    end

    -- Blizzard fallback
    return MainMenuBar
end

--============================================================
-- Panel Creation
--============================================================
function M:CreatePanel()

    local f = CreateFrame("Frame", "BasicUI_DataPanel", UIParent)

    f:SetHeight(28)

    if self.db.position == "top" then
        f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
        f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
        f:SetWidth(UIParent:GetWidth())
    else
        f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
    end

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

    C_Timer.After(0.05, function()
        if M and M.UpdatePanelWidth then
            M:ApplyPanelPosition()
        end
    end)

end

function M:UpdatePanelWidth()

    if not self.panel then return end

    if InCombatLockdown() then
        self.pendingWidthUpdate = true
        return
    end

    if self.db.position == "top" then
        self.panel:ClearAllPoints()
        self.panel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
        self.panel:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
        self.panel:SetWidth(UIParent:GetWidth())
        self:UpdatePanel()
        return
    end

    local leftAnchor, rightAnchor

    -- External bars
    if self.GetExternalActionBar then
        local extBar = self:GetExternalActionBar()
        if extBar and extBar:IsShown() and extBar.GetLeft and extBar.GetRight then
            leftAnchor = extBar:GetLeft()
            rightAnchor = extBar:GetRight()
        end
    end

    -- Blizzard gryphon edges
    if not leftAnchor or not rightAnchor then
        local gryphonsEnabled = self.db
            and self.db.gryphons
            and self.db.gryphons.enabled

        if gryphonsEnabled
            and MainMenuBarLeftEndCap
            and MainMenuBarRightEndCap
            and MainMenuBarLeftEndCap:IsShown()
            and MainMenuBarRightEndCap:IsShown()
        then
            leftAnchor = MainMenuBarLeftEndCap:GetLeft()
            rightAnchor = MainMenuBarRightEndCap:GetRight()
        end
    end

    -- Blizzard art frame
    if (not leftAnchor or not rightAnchor)
        and MainMenuBarArtFrame
        and MainMenuBarArtFrame:IsShown()
    then
        leftAnchor = MainMenuBarArtFrame:GetLeft()
        rightAnchor = MainMenuBarArtFrame:GetRight()
    end

    -- Blizzard fallback
    if (not leftAnchor or not rightAnchor)
        and MainMenuBar
    then
        leftAnchor = MainMenuBar:GetLeft()
        rightAnchor = MainMenuBar:GetRight()
    end

    if leftAnchor and rightAnchor then
        local width = rightAnchor - leftAnchor

        self.panel:ClearAllPoints()
        self.panel:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", leftAnchor, 0)
        self.panel:SetWidth(width)
    else
        self.panel:SetWidth(self:GetPanelTargetWidth())
    end

    self:UpdatePanel()
end

function M:DockMainMenuBar()

    if not MainMenuBar or not self.panel then return end
    if InCombatLockdown() then return end
    if not self.db.enabled then return end
	if self.db.position == "top" then return end

    MainMenuBar.ignoreFramePositionManager = true

    -- 🔥 Update width BEFORE anchoring
    self:UpdatePanelWidth()

	local bar = self:GetActiveBar()

	bar:ClearAllPoints()
	bar:SetPoint("BOTTOM", self.panel, "TOP", 0, -2)

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
    local slotCount = 9
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
	for i = 1, 9 do
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
                position = {
                    type = "select",
                    name = "Panel Position",
                    desc = "Choose whether the datapanel sits below the main menu bar or at the top of the screen.",
                    order = 1,
                    values = {
                        bottom = "Below MainMenuBar",
                        top = "Top of Screen",
                    },
                    get = function() return M.db.position end,
                    set = function(_, v)
                        M.db.position = v
                        M:ApplyPanelPosition()
                        M:UpdatePanel()
                    end,
                },			
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
		
		gryphons = {
			type = "group",
			name = "Show Gryphons",
			inline = true,
			order = 3,
			disabled = function() return not M.db.enabled end,
            args = {
				enabled = {
					type = "toggle",
					name = "Enable Gryphons",
					desc = "Toggle action bar gryphons visibility.",
					order = 2,
					get = function() return M.db.gryphons.enabled end,
					set = function(_, v)
						M.db.gryphons.enabled = v
						M:ApplyGryphons()
						M:UpdatePanelWidth()
						M:DockMainMenuBar()
						M:StartGryphonEnforcer()

						for _, plugin in pairs(M.plugins) do
							if plugin.Refresh then
								plugin:Refresh()
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
			order = 4,
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
				
				reputation = {
					type = "select",
					name = "Reputation",
					desc = "Displays your current reputation standings.",
					order = 2,
					values = pluginPositions,
					get = function() return M.db.plugins.reputation.position end,
					set = function(_, v)
						M:SetPluginPosition("reputation", v)
						M:UpdatePanel()
					end,
				},

                friends = {
                    type = "select",
                    name = "Friends",
                    desc = "Displays online Battle.net and in-game friends.",
                    order = 3,
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
                    order = 4,
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
                    order = 5,
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
                    order = 6,
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
                    order = 7,
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
                    order = 8,
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
                    order = 9,
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