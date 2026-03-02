--============================================================
-- MODULE: ActionBars
--============================================================
local MODULE_NAME = "ActionBars"
local M = {}

--============================================================
-- CONFIG DEFAULTS
--============================================================
M.defaults = {
    hideHotkeys = true,
    hideMacroNames = true,
    rangeColor = { r = 1, g = 0, b = 0 },      -- red
    manaColor  = { r = 0, g = 0.4, b = 1 },    -- blue
}

--============================================================
-- LIFECYCLE: OnInit (runs once)
--============================================================
function M:OnInit()
    -- Reserved for future initialization logic
end

--============================================================
-- HELPERS: Hide Hotkeys + Macro Names
--============================================================
local function HideButtonText(button)
    if not button then return end

    local hotkey = _G[button:GetName() .. "HotKey"]
    local name   = _G[button:GetName() .. "Name"]

    if hotkey then hotkey:SetAlpha(0) end
    if name then name:SetAlpha(0) end
end

--============================================================
-- HELPERS: Range / Mana Coloring (Wrath-compatible)
--============================================================
local function M_OnEvent(self, event)
    if event == "PLAYER_TARGET_CHANGED" then
        self.newTimer = self.rangeTimer
    end
end

local function M_UpdateUsable(self)
    local icon = _G[self:GetName() .. "Icon"]
    if not icon or not self.action then return end

    local inRange = IsActionInRange(self.action)
    local isUsable, notEnoughMana = IsUsableAction(self.action)

    if isUsable then
        if inRange == 0 then
            -- Out of range
            icon:SetVertexColor(1.0, 0.1, 0.1)
        else
            -- Normal
            icon:SetVertexColor(1, 1, 1)
        end

    elseif notEnoughMana then
        -- Out of mana
        icon:SetVertexColor(0.1, 0.3, 1.0)

    else
        -- Unusable
        icon:SetVertexColor(0.4, 0.4, 0.4)
    end
end

local function M_OnUpdate(self, elapsed)
    local timer = self.newTimer
    if timer then
        timer = timer - elapsed
        if timer <= 0 then
            ActionButton_UpdateUsable(self)
            timer = TOOLTIP_UPDATE_TIME
        end
        self.newTimer = timer
    end
end

-- Hook Blizzard functions
hooksecurefunc("ActionButton_OnEvent", M_OnEvent)
hooksecurefunc("ActionButton_UpdateUsable", M_UpdateUsable)
hooksecurefunc("ActionButton_OnUpdate", M_OnUpdate)

--============================================================
-- HELPERS: Apply to All Action Bars
--============================================================
local function ApplyToAllButtons(db)
    local bars = {
        "ActionButton",             -- Main bar
        "MultiBarBottomLeftButton",
        "MultiBarBottomRightButton",
        "MultiBarRightButton",
        "MultiBarLeftButton",
        "PetActionButton",
        "ShapeshiftButton",         -- Stance bar
        "BonusActionButton",
    }

    for _, prefix in ipairs(bars) do
        for i = 1, 12 do
            local button = _G[prefix .. i]
            if button then

                -- Hide hotkeys + macro names
                if db.hideHotkeys or db.hideMacroNames then
                    HideButtonText(button)
                end

                -- Initial color update (range/mana)
                if button.icon then
                    M_UpdateUsable(button)
                end
            end
        end
    end
end

--============================================================
-- LIFECYCLE: OnLoadScreen (runs every loading screen)
--============================================================
function M:OnLoadScreen()
    ApplyToAllButtons(self.db)
end

--============================================================
-- REGISTER MODULE
--============================================================
BasicUI:RegisterModule(MODULE_NAME, M)
