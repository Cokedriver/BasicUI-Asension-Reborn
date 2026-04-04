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
    --chatSize = 16,
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

    ------------------------------------------------------------
    -- SYSTEM FONTS
    ------------------------------------------------------------

	_G.UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT = 14

	local FONTZ = true -- Set to true only if you have not changed your master fonts.

	if FONTZ == true then
		UNIT_NAME_FONT     			= BASICFONT["N"]
		DAMAGE_TEXT_FONT   			= BASICFONT["N"]
		STANDARD_TEXT_FONT			= BASICFONT["N"]
		NAMEPLATE_SPELLCAST_FONT    = BASICFONT["N"]
	end


	-- Font Normally Used FRIZQT__.TTF
	SetFont(_G.SystemFont_Tiny,                		BASICFONT["N"], 11);
	SetFont(_G.SystemFont_Small,                	BASICFONT["N"], 13);
	SetFont(_G.SystemFont_Outline_Small,           	BASICFONT["N"], 13, "OUTLINE");
	SetFont(_G.SystemFont_Outline,                	BASICFONT["N"], 15);	-- Pet level on World map
	SetFont(_G.SystemFont_Shadow_Small,            	BASICFONT["N"], 13);
	SetFont(_G.SystemFont_InverseShadow_Small,		BASICFONT["N"], 13);
	SetFont(_G.SystemFont_Med1,                		BASICFONT["N"], 15);
	SetFont(_G.SystemFont_Shadow_Med1,             	BASICFONT["N"], 15);
	SetFont(_G.SystemFont_Med2,                		BASICFONT["N"], 15, nil, 0.15, 0.09, 0.04);
	SetFont(_G.SystemFont_Shadow_Med2,             	BASICFONT["N"], 15);
	SetFont(_G.SystemFont_Med3,                		BASICFONT["N"], 15);
	SetFont(_G.SystemFont_Shadow_Med3,             	BASICFONT["N"], 15);
	SetFont(_G.SystemFont_Large,                	BASICFONT["N"], 17);
	SetFont(_G.SystemFont_Shadow_Large,            	BASICFONT["N"], 17);
	SetFont(_G.SystemFont_Huge1,                	BASICFONT["N"], 20);
	SetFont(_G.SystemFont_Shadow_Huge1,            	BASICFONT["N"], 20);
	SetFont(_G.SystemFont_OutlineThick_Huge2,      	BASICFONT["N"], 22, "THICKOUTLINE");
	SetFont(_G.SystemFont_Shadow_Outline_Huge2,    	BASICFONT["N"], 22, "OUTLINE");
	SetFont(_G.SystemFont_Shadow_Huge3,            	BASICFONT["N"], 25);
	SetFont(_G.SystemFont_OutlineThick_Huge4,      	BASICFONT["N"], 26, "THICKOUTLINE");
	SetFont(_G.SystemFont_OutlineThick_WTF,        	BASICFONT["N"], 32, "THICKOUTLINE");	-- World Map
	SetFont(_G.SubZoneTextFont,						BASICFONT["N"], 26, "OUTLINE");			-- World Map(SubZone)
	SetFont(_G.GameTooltipHeader,                	BASICFONT["B"], 18);
	SetFont(_G.SpellFont_Small,                		BASICFONT["N"], 13);
	SetFont(_G.InvoiceFont_Med,                		BASICFONT["N"], 15, nil, 0.15, 0.09, 0.04);
	SetFont(_G.InvoiceFont_Small,                	BASICFONT["N"], 13, nil, 0.15, 0.09, 0.04);
	SetFont(_G.Tooltip_Med,                			BASICFONT["N"], 15);
	SetFont(_G.Tooltip_Small,                		BASICFONT["N"], 13);
	SetFont(_G.AchievementFont_Small,              	BASICFONT["N"], 13);
	SetFont(_G.ReputationDetailFont,               	BASICFONT["N"], 12, nil, nil, nil, nil, 0, 0, 0, 1, -1);
	SetFont(_G.GameFont_Gigantic,                	BASICFONT["N"], 32, nil, nil, nil, nil, 0, 0, 0, 1, -1);

	-- Font Normally Used ARIALN.TTF
	SetFont(_G.NumberFont_Shadow_Small,				BASICFONT["N"], 13);
	SetFont(_G.NumberFont_OutlineThick_Mono_Small,	BASICFONT["N"], 13, "OUTLINE");
	SetFont(_G.NumberFont_Shadow_Med,              	BASICFONT["N"], 15);
	SetFont(_G.NumberFont_Outline_Med,             	BASICFONT["N"], 15, "OUTLINE");
	SetFont(_G.NumberFont_Outline_Large,           	BASICFONT["N"], 17, "OUTLINE");
	SetFont(_G.NumberFont_GameNormal,				BASICFONT["N"], 13);
	SetFont(_G.FriendsFont_UserText,               	BASICFONT["N"], 15);

	-- Font Normally Used skurri.ttf
	SetFont(_G.NumberFont_Outline_Huge,            	BASICFONT["N"], 30, "THICKOUTLINE");

	-- Font Normally Used MORPHEUS.ttf
	SetFont(_G.QuestFont_Large,                		BASICFONT["N"], 17)
	SetFont(_G.QuestFont_Shadow_Huge,             	BASICFONT["N"], 18, nil, nil, nil, nil, 0.54, 0.4, 0.1);
	SetFont(_G.QuestFont_Shadow_Small,             	BASICFONT["N"], 13)
	SetFont(_G.MailFont_Large,                		BASICFONT["N"], 17, nil, 0.15, 0.09, 0.04, 0.54, 0.4, 0.1, 1, -1);

	-- Font Normally Used FRIENDS.TTF
	SetFont(_G.FriendsFont_Normal,                	BASICFONT["N"], 15, nil, nil, nil, nil, 0, 0, 0, 1, -1);
	SetFont(_G.FriendsFont_Small,                	BASICFONT["N"], 13, nil, nil, nil, nil, 0, 0, 0, 1, -1);
	SetFont(_G.FriendsFont_Large,                	BASICFONT["N"], 17, nil, nil, nil, nil, 0, 0, 0, 1, -1);

	-- Font Normally Used DAMAGE.TTF
	SetFont(_G.GameFontNormalSmall,                	BASICFONT["N"], 13);
	SetFont(_G.GameFontNormal,                		BASICFONT["N"], 15);
	SetFont(_G.GameFontNormalLarge,                	BASICFONT["N"], 17);
	SetFont(_G.GameFontNormalHuge,                	BASICFONT["N"], 20);
	SetFont(_G.GameFontHighlightSmallLeft,			BASICFONT["N"], 15);
	SetFont(_G.GameNormalNumberFont,               	BASICFONT["N"], 13);


    ------------------------------------------------------------
    -- WATCHFRAME
    ------------------------------------------------------------

    local function SetWatchFrameFonts()

        if WatchFrameTitle then
            SetFont(WatchFrameTitle, BASICFONT["B"], 16)
        end

        for i = 1, 50 do
            local line = _G["WatchFrameLine"..i]
            if line and line.text then
                SetFont(line.text, BASICFONT["N"], 15)
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

    },
}

--============================================================
-- REGISTER MODULE
--============================================================
BasicUI:RegisterModule(MODULE_NAME, M)