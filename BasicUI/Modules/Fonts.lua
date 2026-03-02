--============================================================
-- MODULE: Fonts
--============================================================
local MODULE_NAME = "Fonts"
local M = {}

--============================================================
-- CONFIG DEFAULTS
--============================================================
M.defaults = {
    baseSize = 15,
    chatSize = 16,
    enabled = true,
}

--============================================================
-- FONT PATHS
--============================================================
local MEDIA = "Interface\\AddOns\\BasicUI\\Media\\"
local BASICFONT = {
    ["N"] = MEDIA .. "Expressway_Free_NORMAL.ttf",
    ["B"] = MEDIA .. "Expressway_Rg_BOLD.ttf",
    ["I"] = MEDIA .. "Expressway_Sb_ITALIC.ttf",
}

--============================================================
-- HELPERS: Apply Font to Object
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

--============================================================
-- APPLY ALL FONTS
--============================================================
function M:ApplyAllFonts()
    if not self.db.enabled then return end

    local s = self.db.baseSize
    local N = BASICFONT["N"]
    local B = BASICFONT["B"]
	local I = BASICFONT["I"]

    -- 1. FRIZQT__.TTF REPLACEMENTS
    SetFont(_G.SystemFont_Tiny,                		N,	s-4)
    SetFont(_G.SystemFont_Small,               		N, 	s-2)
    SetFont(_G.SystemFont_Outline_Small,       		N, 	s-2, "OUTLINE")
    SetFont(_G.SystemFont_Outline,             		N, 	s)
    SetFont(_G.SystemFont_Shadow_Small,        		N, 	s-2)
    SetFont(_G.SystemFont_InverseShadow_Small, 		N, 	s-2)
    SetFont(_G.SystemFont_Med1,                		N, 	s)
    SetFont(_G.SystemFont_Shadow_Med1,         		N, 	s)
    SetFont(_G.SystemFont_Med2,                		N, 	s, nil, 0.15, 0.09, 0.04)
    SetFont(_G.SystemFont_Shadow_Med2,         		N, 	s)
    SetFont(_G.SystemFont_Med3,                		N, 	s)
    SetFont(_G.SystemFont_Shadow_Med3,         		N, 	s)
    SetFont(_G.SystemFont_Large,               		B,  s+2)
    SetFont(_G.SystemFont_Shadow_Large,        		B,  s+2)
    SetFont(_G.SystemFont_Huge1,               		B,  s+5)
    SetFont(_G.SystemFont_Shadow_Huge1,        		B,  s+5)
    SetFont(_G.SystemFont_OutlineThick_Huge2,  		B,  s+7, "THICKOUTLINE")
    SetFont(_G.SystemFont_Shadow_Outline_Huge2,		B,  s+7, "OUTLINE")
    SetFont(_G.SystemFont_Shadow_Huge3,        		B,  s+10)
    SetFont(_G.SystemFont_OutlineThick_Huge4,  		B,  s+11, "THICKOUTLINE")
    SetFont(_G.SystemFont_OutlineThick_WTF,    		B,  s+17, "THICKOUTLINE", nil, nil, nil, 0, 0, 0, 1, -1)
    SetFont(_G.GameTooltipHeader,              		B,  s+3)
    SetFont(_G.SpellFont_Small,                		N, 	s-2)
    SetFont(_G.InvoiceFont_Med,                		N, 	s, nil, 0.15, 0.09, 0.04)
    SetFont(_G.InvoiceFont_Small,              		N, 	s-2, nil, 0.15, 0.09, 0.04)
    SetFont(_G.Tooltip_Med,                    		N, 	s)
    SetFont(_G.Tooltip_Small,                  		N, 	s-2)
    SetFont(_G.AchievementFont_Small,          		N, 	s-2)
    SetFont(_G.ReputationDetailFont,           		N, 	s-3, nil, nil, nil, nil, 0, 0, 0, 1, -1)
    SetFont(_G.GameFont_Gigantic,              		B,  s+17, nil, nil, nil, nil, 0, 0, 0, 1, -1)

    -- 2. ARIALN.TTF REPLACEMENTS
    SetFont(_G.NumberFont_Shadow_Small,            	B, 	s-2)
    SetFont(_G.NumberFont_OutlineThick_Mono_Small, 	B, 	s-2, "OUTLINE")
    SetFont(_G.NumberFont_Shadow_Med,              	B, 	s)
    SetFont(_G.NumberFont_Outline_Med,             	B, 	s, "OUTLINE")
    SetFont(_G.NumberFont_Outline_Large,           	B, 	s+2, "OUTLINE")
    SetFont(_G.NumberFont_GameNormal,              	B, 	s-2)
    SetFont(_G.FriendsFont_UserText,               	B, 	s)

    -- 3. SKURRI.TTF REPLACEMENT
    SetFont(_G.NumberFont_Outline_Huge,            	B,	s+15, "THICKOUTLINE")

    -- 4. MORPHEUS.TTF REPLACEMENTS
    SetFont(_G.QuestFont_Large,                    	I, 	s+2)
    SetFont(_G.QuestFont_Shadow_Huge,              	I, 	s+3, nil, nil, nil, nil, 0.54, 0.4, 0.1)
    SetFont(_G.QuestFont_Shadow_Small,             	I, 	s-2)
    SetFont(_G.MailFont_Large,                     	I, 	s+2, nil, 0.15, 0.09, 0.04, 0.54, 0.4, 0.1, 1, -1)

    -- 5. FRIENDS.TTF REPLACEMENTS
    SetFont(_G.FriendsFont_Normal,                 	N, 	s, nil, nil, nil, nil, 0, 0, 0, 1, -1)
    SetFont(_G.FriendsFont_Small,                  	N, 	s-2, nil, nil, nil, nil, 0, 0, 0, 1, -1)
    SetFont(_G.FriendsFont_Large,                  	B, 	s+2, nil, nil, nil, nil, 0, 0, 0, 1, -1)

    -- 6. GENERAL REPLACEMENTS
    SetFont(_G.GameFontNormalSmall,                	B, 	s-2)
    SetFont(_G.GameFontNormal,                     	N, 	s)
    SetFont(_G.GameFontNormalLarge,                	B, 	s+2)
    SetFont(_G.GameFontNormalHuge,                 	B, 	s+5)
    SetFont(_G.GameFontHighlightSmallLeft,         	N, 	s)
    SetFont(_G.GameNormalNumberFont,               	B, 	s-2)

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
    -- OBJECTIVE TRACKER / WATCHFRAME (WotLK / Ascension / Reborn)
    ------------------------------------------------------------
    local function SetWatchFrameFonts()
        -- Title ("Objectives")
        if WatchFrameTitle then
            SetFont(WatchFrameTitle, B, 15, "NONE")
        end

        -- Each line of text inside the tracker
        for i = 1, 50 do
            local line = _G["WatchFrameLine"..i]
            if line and line.text then
                SetFont(line.text, N, 15, "NONE")
            end
        end
    end

    SetWatchFrameFonts()

    -- Reapply fonts whenever the tracker updates
    hooksecurefunc("WatchFrame_Update", SetWatchFrameFonts)
	
end

--============================================================
-- LIFECYCLE: OnInit
--============================================================
function M:OnInit()
    -- Reserved for future logic
end

--============================================================
-- LIFECYCLE: OnLoadScreen
--============================================================
function M:OnLoadScreen()
    self:ApplyAllFonts()
end

--============================================================
-- REGISTER MODULE
--============================================================
BasicUI:RegisterModule(MODULE_NAME, M)
