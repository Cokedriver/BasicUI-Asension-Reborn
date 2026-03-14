--==============================
-- MODULE: Fonts
--==============================

local addonName, BasicUI = ...
local MODULE_NAME = "Fonts"

local M = {}

--============================================================
-- CONFIG DEFAULTS
--============================================================

M.defaults = {
    enabled = true,
    baseSize = 15,
    chatSize = 16,
}

--============================================================
-- FONT PATHS
--============================================================

local MEDIA = "Interface\\AddOns\\BasicUI\\Media\\"

local BASICFONT = {
    ["N"] = MEDIA.."Expressway_Free_NORMAL.ttf",
    ["B"] = MEDIA.."Expressway_Rg_BOLD.ttf",
    ["I"] = MEDIA.."Expressway_Sb_ITALIC.ttf",
}

local watchHooked = false

--============================================================
-- HELPERS
--============================================================

local function SetFont(obj, font, size, style, sr, sg, sb, sa, sox, soy, r, g, b)

    if not obj then return end

    style = (style == "NONE" or not style) and "" or style

    obj:SetFont(font, size, style)

    if sr and sg and sb then
        obj:SetShadowColor(sr, sg, sb, sa or 1)
    end

    if sox and soy then
        obj:SetShadowOffset(sox, soy)
    end

    if r and g and b then
        obj:SetTextColor(r, g, b)
    end

end

function BasicUI:GetBasicFont(style)

    local fonts = {
        N = BASICFONT["N"],
        B = BASICFONT["B"],
        I = BASICFONT["I"],
    }

    return fonts[style or "N"] or BASICFONT["N"]

end

--============================================================
-- APPLY ALL FONTS
--============================================================

function M:ApplyAllFonts()

    if not self.db.enabled then return end

    local s = self.db.baseSize
    local N = BASICFONT["N"]
    local B = BASICFONT["B"]

    ------------------------------------------------------------
    -- SYSTEM FONTS
    ------------------------------------------------------------

    SetFont(_G.SystemFont_Tiny, N, s-4)
    SetFont(_G.SystemFont_Small, N, s-2)
    SetFont(_G.SystemFont_Outline_Small, N, s-2, "OUTLINE")
    SetFont(_G.SystemFont_Outline, N, s)
    SetFont(_G.SystemFont_Shadow_Small, N, s-2)
    SetFont(_G.SystemFont_InverseShadow_Small, N, s-2)
    SetFont(_G.SystemFont_Med1, N, s)
    SetFont(_G.SystemFont_Shadow_Med1, N, s)
    SetFont(_G.SystemFont_Med2, N, s, nil, 0.15, 0.09, 0.04)
    SetFont(_G.SystemFont_Shadow_Med2, N, s)
    SetFont(_G.SystemFont_Med3, N, s)
    SetFont(_G.SystemFont_Shadow_Med3, N, s)
    SetFont(_G.SystemFont_Large, B, s+2)
    SetFont(_G.SystemFont_Shadow_Large, B, s+2)
    SetFont(_G.SystemFont_Huge1, B, s+5)
    SetFont(_G.SystemFont_Shadow_Huge1, B, s+5)
    SetFont(_G.SystemFont_OutlineThick_Huge2, B, s+7, "THICKOUTLINE")
    SetFont(_G.SystemFont_Shadow_Outline_Huge2, B, s+7, "OUTLINE")
    SetFont(_G.SystemFont_Shadow_Huge3, B, s+10)
    SetFont(_G.SystemFont_OutlineThick_Huge4, B, s+11, "THICKOUTLINE")
    SetFont(_G.SystemFont_OutlineThick_WTF, B, s+17, "THICKOUTLINE", nil, nil, nil, 0,0,0,1,-1)

    SetFont(_G.GameTooltipHeader, B, s+3)

    SetFont(_G.SpellFont_Small, N, s-2)
    SetFont(_G.InvoiceFont_Med, N, s, nil, 0.15, 0.09, 0.04)
    SetFont(_G.InvoiceFont_Small, N, s-2, nil, 0.15, 0.09, 0.04)

    SetFont(_G.Tooltip_Med, N, s)
    SetFont(_G.Tooltip_Small, N, s-2)

    SetFont(_G.AchievementFont_Small, N, s-2)
    SetFont(_G.ReputationDetailFont, N, s-3, nil, nil,nil,nil,0,0,0,1,-1)

    SetFont(_G.GameFont_Gigantic, B, s+17, nil,nil,nil,nil,0,0,0,1,-1)

    ------------------------------------------------------------
    -- CHAT WINDOWS
    ------------------------------------------------------------

    for i = 1, NUM_CHAT_WINDOWS do
        local chat = _G["ChatFrame"..i]
        if chat then
            chat:SetFont(N, self.db.chatSize, "")
        end
    end

    ------------------------------------------------------------
    -- WATCHFRAME
    ------------------------------------------------------------

    local function SetWatchFrameFonts()

        if WatchFrameTitle then
            SetFont(WatchFrameTitle, B, 15)
        end

        for i = 1, 50 do
            local line = _G["WatchFrameLine"..i]
            if line and line.text then
                SetFont(line.text, N, 15)
            end
        end

    end

    SetWatchFrameFonts()

    if not watchHooked then
        hooksecurefunc("WatchFrame_Update", SetWatchFrameFonts)
        watchHooked = true
    end

end

--============================================================
-- INIT
--============================================================

function M:OnInit()

    BasicDB = BasicDB or {}
    BasicDB.Fonts = BasicDB.Fonts or {}

    self.db = BasicDB.Fonts

    for k,v in pairs(self.defaults) do
        if self.db[k] == nil then
            self.db[k] = v
        end
    end

end

--============================================================
-- ENABLE
--============================================================

function M:OnEnable()

    self:ApplyAllFonts()

end

--============================================================
-- OPTIONS
--============================================================

M.options = {
    type = "group",
    name = "Fonts",
    args = {

        enabled = {
            type = "toggle",
            name = "Enable Fonts",
            desc = "Enable BasicUI font adjustments across the interface.",
            order = 1,
			width = "full",
            get = function() return M.db.enabled end,
			set = function(_, v)
				M.db.enabled = v
				BasicUI:RequestReload()
			end,
        },

        baseSize = {
            type = "range",
            name = "Base Font Size",
            desc = "Adjust the primary font size used throughout the interface.",
            min = 8,
            max = 32,
            step = 1,
            order = 2,
            get = function() return M.db.baseSize end,
			set = function(_, v)
				M.db.baseSize = v
				M:ApplyAllFonts()
			end,
        },

        chatSize = {
            type = "range",
            name = "Chat Font Size",
            desc = "Adjust the font size used in chat windows.",
            min = 8,
            max = 32,
            step = 1,
            order = 3,
            get = function() return M.db.chatSize end,
			set = function(_, v)
				M.db.chatSize = v
				M:ApplyAllFonts()
			end,
        },

    },
}

--============================================================
-- REGISTER MODULE
--============================================================
BasicUI:RegisterModule(MODULE_NAME, M)