--============================================================
-- MODULE: Datapanel
--============================================================
local M = {}
M.name = "Datapanel"

M.defaults = {
    panel = {
        fontSize = 16,
        font     = "Fonts\\FRIZQT__.TTF",
        spacing  = 14,
        width    = 1200,
    },
    plugins = {
        performance = { position = 1 },
        friends     = { position = 2 },
        guild       = { position = 3 },
        mainstats   = { position = 4, displayMode = "AUTO", showCrit = false },
        spec        = { position = 5 },
        professions = { position = 6 },
        durability  = { position = 7, showRepairCost = true },
        bagspace    = { position = 8, showRealmGold = true, showSessionGain = true },
    }
}

function M:OnInit()
    self.plugins = {}
end

function M:RegisterEvent(event, handler)
    BasicUI:RegisterEvent(event, handler)
end

function M:RegisterPlugin(name, plugin)
    plugin.name = name
    
    -- Link plugin DB to the entry inside the Datapanel config block
    if BasicConfig and BasicConfig.Datapanel and BasicConfig.Datapanel[name] then
        plugin.db = BasicConfig.Datapanel[name]
    else
        self.db.plugins[name] = self.db.plugins[name] or {}
        plugin.db = self.db.plugins[name]
    end
    
    if not plugin.db.position then plugin.db.position = 999 end
    self.plugins[name] = plugin
end

function M:CalculatePanelHeight()
    local size = self.db.panel.fontSize or 16
    local border = 5
    local padding = 4
    return size + border * 2 + padding
end

function M:CreatePanel()
    local db = self.db.panel
    local f = CreateFrame("Frame", "BasicUI_DataPanel", UIParent)
    f:SetWidth(db.width)
    f:SetHeight(self:CalculatePanelHeight())
    f:ClearAllPoints()
    f:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)

    -- Force panel to the very bottom layer
    f:SetFrameStrata("BACKGROUND")
    f:SetFrameLevel(1)

    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0, 0, 0, 0.8)
    f:SetBackdropBorderColor(1, 1, 1, 1)
    self.panel = f
end

function M:DockMainMenuBar()
    if not MainMenuBar or not self.panel then return end

    MainMenuBar:ClearAllPoints()
    MainMenuBar:SetPoint("BOTTOM", self.panel, "TOP", 0, -2)

    -- Force Bar to a higher layer than the panel
    MainMenuBar:SetFrameStrata("HIGH")
    MainMenuBar:SetFrameLevel(20)
end

function M:ApplyStandardFont(fs)
    fs:SetFont(self.db.panel.font, self.db.panel.fontSize, "OUTLINE")
end

function M:GetColoredPlayerHeader(pluginName)
    local name = UnitName("player")
    local hex = self:GetClassHex()
    return "|cff" .. hex .. name .. "'s " .. pluginName .. "|r"
end

function M:CreatePluginFrame(plugin)
    local f = plugin:CreateFrame(self.panel)
    if f and f.GetWidth and f:GetWidth() < 40 then f:SetWidth(80) end
    return f
end

function M:UpdatePanel()
    if not self.panel then return end
    self.panel:SetHeight(self:CalculatePanelHeight())
    local panelWidth = self.panel:GetWidth()
    local ordered = {}
    for name, plugin in pairs(self.plugins) do
        table.insert(ordered, { plugin = plugin, position = plugin.db.position or 999 })
    end
    table.sort(ordered, function(a, b)
        if a.position == b.position then return a.plugin.name < b.plugin.name end
        return a.position < b.position
    end)

    local count = 0
    for _, entry in ipairs(ordered) do if entry.plugin.frame then count = count + 1 end end
    if count == 0 then return end

    local segmentWidth = panelWidth / count
    local halfSegment = segmentWidth / 2
    local index = 0
    for _, entry in ipairs(ordered) do
        local plugin = entry.plugin
        local f = plugin.frame
        if f then
            index = index + 1
            if index == 1 then
                f:ClearAllPoints()
                f:SetPoint("LEFT", self.panel, "LEFT", 5, 0)
            else
                local centerX = (index - 1) * segmentWidth + halfSegment
                f:ClearAllPoints()
                f:SetPoint("CENTER", self.panel, "LEFT", centerX, 0)
            end
        end
    end
end

function M:OnLoadScreen()
    self:CreatePanel()
    self:DockMainMenuBar()

    -- Hook MainMenuBar logic to maintain position
    if MainMenuBar_UpdateExperienceBars then
        hooksecurefunc("MainMenuBar_UpdateExperienceBars", function() M:DockMainMenuBar() end)
    end
    MainMenuBar:HookScript("OnShow", function() M:DockMainMenuBar() end)

    for name, plugin in pairs(self.plugins) do
        if plugin.OnEnable then plugin:OnEnable() end
        self:CreatePluginFrame(plugin)
    end
    self:UpdatePanel()
end

M:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    C_Timer.After(0.5, function() M:DockMainMenuBar() end)
end)

function M:GetClassHex()
    local _, class = UnitClass("player")
    local c = RAID_CLASS_COLORS[class] or { r = 1, g = 1, b = 1 }
    return string.format("%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
end

BasicUI:RegisterModule("Datapanel", M)