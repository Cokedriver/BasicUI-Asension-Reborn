--============================================================
-- MODULE: ActionBars
--============================================================

local addonName, BasicUI = ...
local MODULE_NAME = "ActionBars"

local M = {}

--============================================================
-- CONFIG DEFAULTS
--============================================================

M.defaults = {

    enabled = true,

    text = {
        hideHotkeys = true,
        hideMacroNames = true,
    },

    colors = {
        rangeColor = { r = 1, g = 0.1, b = 0.1 },
        manaColor  = { r = 0.1, g = 0.3, b = 1.0 },
    }

}

--============================================================
-- LIFECYCLE: OnInit
--============================================================

function M:OnInit()

    BasicDB = BasicDB or {}
    BasicDB.ActionBars = BasicDB.ActionBars or {}

    self.db = BasicDB.ActionBars

    for k,v in pairs(self.defaults) do
        if self.db[k] == nil then
            self.db[k] = v
        end
    end

    self.hooked = false
    M.instance = self

end

--============================================================
-- RESTORE BLIZZARD DEFAULTS
--============================================================

local function RestoreBlizzardActionBars()

    local bars = {
        "ActionButton",
        "MultiBarBottomLeftButton",
        "MultiBarBottomRightButton",
        "MultiBarRightButton",
        "MultiBarLeftButton",
        "PetActionButton",
        "ShapeshiftButton",
        "BonusActionButton",
    }

    for _, prefix in ipairs(bars) do
        for i = 1, 12 do

            local button = _G[prefix..i]

            if button then

                local hotkey = button.HotKey or _G[prefix..i.."HotKey"]
                if hotkey then
                    hotkey:SetAlpha(1)
                end

                local name = button.Name or _G[prefix..i.."Name"]
                if name then
                    name:SetAlpha(1)
                end

                local icon = _G[prefix..i.."Icon"]
                if icon then
                    icon:SetVertexColor(1,1,1)
                end

            end

        end
    end

end

--============================================================
-- HELPERS
--============================================================

local function HideButtonText(button)

    if not button then return end

    local hotkey = _G[button:GetName() .. "HotKey"]
    local name   = _G[button:GetName() .. "Name"]

    if hotkey then hotkey:SetAlpha(0) end
    if name then name:SetAlpha(0) end

end

--============================================================
-- UPDATE ACTION BARS
--============================================================

function M:UpdateActionBars()

    if not self.db or not self.db.enabled then return end

    local bars = {
        "ActionButton",
        "MultiBarBottomLeftButton",
        "MultiBarBottomRightButton",
        "MultiBarRightButton",
        "MultiBarLeftButton",
        "PetActionButton",
        "ShapeshiftButton",
        "BonusActionButton",
    }

    for _, prefix in ipairs(bars) do
        for i = 1, 12 do

            local button = _G[prefix..i]

            if button then

                local hotkey = button.HotKey or _G[prefix..i.."HotKey"]

                if hotkey then
                    if self.db.text.hideHotkeys then
                        hotkey:SetAlpha(0)
                    else
                        hotkey:SetAlpha(1)
                    end
                end

                local name = button.Name or _G[prefix..i.."Name"]

                if name then
                    if self.db.text.hideMacroNames then
                        name:SetAlpha(0)
                    else
                        name:SetAlpha(1)
                    end
                end

            end

        end
    end

end

--============================================================
-- RANGE / MANA COLORING
--============================================================

local function M_UpdateUsable(self)

    if not M.instance or not M.instance.db.enabled then return end

	local icon = _G[self:GetName() .. "Icon"]
	if not icon then return end

	local action = self.action or ActionButton_GetPagedID and ActionButton_GetPagedID(self)

	if not action then return end

    local db = M.instance.db

    local inRange = IsActionInRange(action)
    local isUsable, notEnoughMana = IsUsableAction(action)

    if isUsable then

        if inRange == 0 then
            local c = db.colors.rangeColor
            icon:SetVertexColor(c.r, c.g, c.b)
        else
            icon:SetVertexColor(1,1,1)
        end

    elseif notEnoughMana then

        local c = db.colors.manaColor
        icon:SetVertexColor(c.r, c.g, c.b)

    else

        icon:SetVertexColor(0.4,0.4,0.4)

    end

end

--============================================================
-- SAFE HOOK SETUP
--============================================================

local function SetupHooks(self)

    if self.hooked then return end

    self.hooked = true

end

--============================================================
-- RANGE UPDATE FRAME (PERFORMANCE FIX)
--============================================================

local RangeUpdateFrame = CreateFrame("Frame")
RangeUpdateFrame.elapsed = 0

RangeUpdateFrame:SetScript("OnUpdate", function(self, elapsed)

    if not M.instance or not M.instance.db.enabled then return end

    self.elapsed = self.elapsed + elapsed

    if self.elapsed < 0.15 then return end
    self.elapsed = 0

    local bars = {
        "ActionButton",
        "MultiBarBottomLeftButton",
        "MultiBarBottomRightButton",
        "MultiBarRightButton",
        "MultiBarLeftButton",
        "PetActionButton",
        "ShapeshiftButton",
        "BonusActionButton",
    }

	for _, prefix in ipairs(bars) do
		for i = 1, 12 do
			local button = _G[prefix..i]

			if button and button.action then
				M_UpdateUsable(button)
			end
		end
	end

end)

--============================================================
-- LIFECYCLE
--============================================================

function M:OnEnable()

    if not self.db.enabled then return end

    SetupHooks(self)
    self:UpdateActionBars()

end

--============================================================
-- OPTIONS
--============================================================

local function ABDisabled()
    return not M.db.enabled
end

M.options = {
    type = "group",
    name = "Action Bars",
    args = {

        enabled = {
            type = "toggle",
            name = "Enable Action Bars",
            order = 1,
            width = "full",
            get = function() return M.db.enabled end,
            set = function(_, v)

                M.db.enabled = v

                if v then
                    M:OnEnable()
                    M:UpdateActionBars()
                else
                    RestoreBlizzardActionBars()
                end

            end,
        },

        text = {
            type = "group",
            name = "Button Text",
            inline = true,
            order = 2,
            disabled = ABDisabled,
            args = {

                hideHotkeys = {
                    type = "toggle",
                    name = "Hide Hotkeys",
                    order = 1,
                    get = function() return M.db.text.hideHotkeys end,
                    set = function(_, v)
                        M.db.text.hideHotkeys = v
                        M:UpdateActionBars()
                    end,
                },

                hideMacroNames = {
                    type = "toggle",
                    name = "Hide Macro Names",
                    order = 2,
                    get = function() return M.db.text.hideMacroNames end,
                    set = function(_, v)
                        M.db.text.hideMacroNames = v
                        M:UpdateActionBars()
                    end,
                },

            },
        },

        colors = {
            type = "group",
            name = "Button Colors",
            inline = true,
            order = 3,
            disabled = ABDisabled,
            args = {

                manaColor = {
                    type = "color",
                    name = "Low Mana Color",
                    hasAlpha = false,
                    order = 1,
                    get = function()
                        local c = M.db.colors.manaColor
                        return c.r, c.g, c.b
                    end,
                    set = function(_, r, g, b)
                        local c = M.db.colors.manaColor
                        c.r, c.g, c.b = r, g, b
                    end,
                },

                rangeColor = {
                    type = "color",
                    name = "Out of Range Color",
                    hasAlpha = false,
                    order = 2,
                    get = function()
                        local c = M.db.colors.rangeColor
                        return c.r, c.g, c.b
                    end,
                    set = function(_, r, g, b)
                        local c = M.db.colors.rangeColor
                        c.r, c.g, c.b = r, g, b
                    end,
                },

            },
        },

    },
}

--============================================================
-- REGISTER MODULE
--============================================================

BasicUI:RegisterModule(MODULE_NAME, M)