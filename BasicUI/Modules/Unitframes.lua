--============================================================
-- MODULE: Unitframes (Ascension 3.3.5a)
--============================================================
local addonName, BasicUI = ...
local MODULE_NAME = "Unitframes"
local M = CreateFrame("Frame", "BasicUI_Unitframes", UIParent)

-- SECTION 1: Config & Fonts
local UNIT_FONT_BOLD    = [[Interface\AddOns\BasicUI\Media\Expressway_Rg_BOLD.ttf]]
local UNIT_FONT_REGULAR = BasicUI:GetBasicFont("N")

--============================================================
-- SECTION 1: DEFAULTS
--============================================================
M.defaults = {
    enabled = true,
    playerScale = 1.193,
    targetScale = 1.193,
    focusScale = 1.193,
    partyScale = 1.193,
    bossScale = 1.193,
    arenaScale = 1.193,
    
    enablePlayer = true,
    enableTarget = true,
    enableFocus = true,
    enableParty = true,
    enableBoss = true,
    enableArena = true,
    
    enableCastbar = true,
    castbarScale = 1.193,
    
    enablePet = true,
    petFontSize = 13,
    petColor = { r = 157/255, g = 197/255, b = 255/255 },
    
    enableClassHealth = true,
    hideHitText = true,
}

--============================================================
-- SECTION 2: Standalone Color Logic
--============================================================
local function GetUnitColor(unit)
    return BasicUI:GetUnitColor(unit)
end

--============================================================
-- SECTION 3: Castbar Styling
--============================================================
local function StyleDefaultCastbar(self)

    local cb = _G["CastingBarFrame"]
    if not cb then return end

    cb:SetScale(self.db.castbarScale or 1.193)

end

--============================================================
-- SECTION 4: Frame Placement + Scaling
--============================================================
function M:UpdateFrameScales()

	if not self.db or not self.db.enabled then return end

    local db = self.db	

    -- PLAYER
    if PlayerFrame and db.enablePlayer then
        PlayerFrame:SetMovable(true)
        PlayerFrame:SetUserPlaced(true)
        PlayerFrame:ClearAllPoints()
        PlayerFrame:SetPoint("CENTER", UIParent, "CENTER", -225, -200)
        PlayerFrame:SetScale(db.playerScale or 1.193)
    end

    -- TARGET
    if TargetFrame and db.enableTarget then
        TargetFrame:SetMovable(true)
        TargetFrame:SetUserPlaced(true)
        TargetFrame:ClearAllPoints()
        TargetFrame:SetPoint("CENTER", UIParent, "CENTER", 235, -200)
        TargetFrame:SetScale(db.targetScale or 1.193)
    end

    -- FOCUS
    if FocusFrame and db.enableFocus then
        FocusFrame:SetScale(db.focusScale or 1.193)
    end

    -- PARTY
    if db.enableParty then
        for i = 1, 4 do
            local frame = _G["PartyMemberFrame"..i]
            if frame then
                frame:SetScale(db.partyScale or 1.193)
            end
        end
    end

    -- BOSS
    if db.enableBoss then
        for i = 1, 4 do
            local frame = _G["Boss"..i.."TargetFrame"]
            if frame then
                frame:SetScale(db.bossScale or 1.193)
            end
        end
    end

    -- ARENA
    if db.enableArena then
        for i = 1, 5 do
            local frame = _G["ArenaEnemyFrame"..i]
            if frame then
                frame:SetScale(db.arenaScale or 1.193)
            end
        end
    end
end

--============================================================
-- SECTION 5: Styling
--============================================================
function M:ApplyAllStyling(frame)

    if not frame or not frame.unit or not UnitExists(frame.unit) then return end

    local unit = frame.unit
    local db = self.db
    local frameName = frame:GetName()

    local r,g,b = BasicUI:GetUnitColor(unit)

    local nameBG = _G[frameName.."NameBackground"]

	if nameBG then

		if UnitCanAttack("player", unit) and UnitAffectingCombat(unit) then
			nameBG:SetVertexColor(r, g, b, 1)

		elseif UnitIsFriend("player", unit) then
			nameBG:SetVertexColor(0.1, 0.1, 0.1, 0.1)

		else
			nameBG:SetVertexColor(0.1, 0.1, 0.1, 0.1)
		end

	end

    local nameText =
        frame.name
        or _G[frameName.."Name"]
        or _G[frameName.."TextureFrameName"]

    if nameText then

        local font =
            (frame == TargetFrameToT or frame == FocusFrameToT)
            and UNIT_FONT_REGULAR
            or UNIT_FONT_BOLD

        nameText:SetFont(font,16,"THINOUTLINE")
        nameText:SetTextColor(r,g,b)

    end

    if db.enableClassHealth then

        local hb = frame.healthBar or frame.HealthBar

        if hb then
            hb:SetStatusBarColor(r,g,b)
        end

    end

end

--============================================================
-- SECTION 6: Apply Styling to All Frames
--============================================================
function M:StyleAllFrames()

    self:ApplyAllStyling(PlayerFrame)
    self:ApplyAllStyling(TargetFrame)
    self:ApplyAllStyling(FocusFrame)

    for i=1,4 do
        local f=_G["PartyMemberFrame"..i]
        if f then self:ApplyAllStyling(f) end
    end

    for i=1,4 do
        local f=_G["Boss"..i.."TargetFrame"]
        if f then self:ApplyAllStyling(f) end
    end

    for i=1,5 do
        local f=_G["ArenaEnemyFrame"..i]
        if f then self:ApplyAllStyling(f) end
    end

end

--============================================================
-- SECTION 7: Events
--============================================================

M:RegisterEvent("ADDON_LOADED")
M:RegisterEvent("PLAYER_ENTERING_WORLD")

M:SetScript("OnEvent", function(self, event, ...)

    if event == "ADDON_LOADED" then

        local addon = ...

		if addon == "BasicUI" then

			BasicDB = BasicDB or {}
			BasicDB.Unitframes = BasicDB.Unitframes or {}

			self.db = BasicDB.Unitframes

			BasicUI:CopyDefaults(self.defaults, self.db)

			if not self.db.enabled then
				return
			end

            if self.db.hideHitText then
                PlayerHitIndicator:Hide()
                PetHitIndicator:Hide()
                PlayerHitIndicator.Show = function() end
                PetHitIndicator.Show = function() end
                CombatText_UpdateUnitModel = function() end
            end

            StyleDefaultCastbar(self)

            hooksecurefunc("UnitFrame_Update", function(f)
                if f then self:ApplyAllStyling(f) end
            end)

            hooksecurefunc("UnitFrameHealthBar_Update", function(s)
                if s and s:GetParent() then
                    self:ApplyAllStyling(s:GetParent())
                end
            end)

            hooksecurefunc("TargetFrame_CheckClassification", function(f)
                if f then self:ApplyAllStyling(f) end
            end)

            -- FIXED HERE
            hooksecurefunc("PartyMemberFrame_UpdateMember", function(frame)
                if frame then self:ApplyAllStyling(frame) end
            end)

        elseif addon == "Blizzard_ArenaUI" then

            hooksecurefunc("ArenaEnemyFrame_Update", function(i)
                local f = _G["ArenaEnemyFrame"..i]
                if f then self:ApplyAllStyling(f) end
            end)

        end

    elseif event == "PLAYER_ENTERING_WORLD" then
	
		if not self.db or not self.db.enabled then return end
		
        self:UpdateFrameScales()
    end

end)

function M:OnInit()

end

local function UnitframesDisabled()
    return not M.db.enabled
end

--============================================================
-- OPTIONS
--============================================================

M.options = {
    type = "group",
    name = "Unit Frames",
    args = {

        enabled = {
            type = "toggle",
            name = "Enable BasicUI Style Unit Frames",
            desc = "Enable BasicUI styling and enhancements for unit frames.",
            order = 1,
			width = "full",
            get = function() return M.db.enabled end,
            set = function(_, v)
                M.db.enabled = v
                BasicUI:RequestReload()
            end,
        },

        ------------------------------------------------
        -- Frame Enable
        ------------------------------------------------

        enableFrames = {
            type = "group",
            name = "Enabled Frames",
            inline = true,
            order = 2,
			disabled = UnitframesDisabled,
            args = {

                enablePlayer = {
                    type = "toggle",
                    name = "Enable Player Frame",
                    desc = "Enable the player unit frame.",
                    order = 1,
                    get = function() return M.db.enablePlayer end,
                    set = function(_, v)
                        M.db.enablePlayer = v
                        BasicUI:RequestReload()
                    end,
                },

                enableTarget = {
                    type = "toggle",
                    name = "Enable Target Frame",
                    desc = "Enable the target unit frame.",
                    order = 2,
                    get = function() return M.db.enableTarget end,
                    set = function(_, v)
                        M.db.enableTarget = v
                        BasicUI:RequestReload()
                    end,
                },

                enableFocus = {
                    type = "toggle",
                    name = "Enable Focus Frame",
                    desc = "Enable the focus unit frame.",
                    order = 3,
                    get = function() return M.db.enableFocus end,
                    set = function(_, v)
                        M.db.enableFocus = v
                        BasicUI:RequestReload()
                    end,
                },

                enableParty = {
                    type = "toggle",
                    name = "Enable Party Frames",
                    desc = "Enable the party unit frames.",
                    order = 4,
                    get = function() return M.db.enableParty end,
                    set = function(_, v)
                        M.db.enableParty = v
                        BasicUI:RequestReload()
                    end,
                },

                enableBoss = {
                    type = "toggle",
                    name = "Enable Boss Frames",
                    desc = "Enable boss unit frames.",
                    order = 5,
                    get = function() return M.db.enableBoss end,
                    set = function(_, v)
                        M.db.enableBoss = v
                        BasicUI:RequestReload()
                    end,
                },

                enableArena = {
                    type = "toggle",
                    name = "Enable Arena Frames",
                    desc = "Enable arena enemy unit frames.",
                    order = 6,
                    get = function() return M.db.enableArena end,
                    set = function(_, v)
                        M.db.enableArena = v
                        BasicUI:RequestReload()
                    end,
                },

            },
        },

        ------------------------------------------------
        -- Frame Scales
        ------------------------------------------------

        scales = {
            type = "group",
            name = "Frame Scales",
            inline = true,
            order = 3,
			disabled = UnitframesDisabled,
            args = {

                playerScale = {
                    type = "range",
                    name = "Player Frame Scale",
                    desc = "Adjust the scale of the player unit frame.",
                    min = 0.5, max = 2, step = 0.01,
                    order = 1,
                    get = function() return M.db.playerScale end,
                    set = function(_, v)
                        M.db.playerScale = v
                        BasicUI:RequestReload()
                    end,
                },

                targetScale = {
                    type = "range",
                    name = "Target Frame Scale",
                    desc = "Adjust the scale of the target unit frame.",
                    min = 0.5, max = 2, step = 0.01,
                    order = 2,
                    get = function() return M.db.targetScale end,
                    set = function(_, v)
                        M.db.targetScale = v
                        BasicUI:RequestReload()
                    end,
                },

                focusScale = {
                    type = "range",
                    name = "Focus Frame Scale",
                    desc = "Adjust the scale of the focus unit frame.",
                    min = 0.5, max = 2, step = 0.01,
                    order = 3,
                    get = function() return M.db.focusScale end,
                    set = function(_, v)
                        M.db.focusScale = v
                        BasicUI:RequestReload()
                    end,
                },

                partyScale = {
                    type = "range",
                    name = "Party Frame Scale",
                    desc = "Adjust the scale of the party unit frames.",
                    min = 0.5, max = 2, step = 0.01,
                    order = 4,
                    get = function() return M.db.partyScale end,
                    set = function(_, v)
                        M.db.partyScale = v
                        BasicUI:RequestReload()
                    end,
                },

                bossScale = {
                    type = "range",
                    name = "Boss Frame Scale",
                    desc = "Adjust the scale of boss unit frames.",
                    min = 0.5, max = 2, step = 0.01,
                    order = 5,
                    get = function() return M.db.bossScale end,
                    set = function(_, v)
                        M.db.bossScale = v
                        BasicUI:RequestReload()
                    end,
                },

                arenaScale = {
                    type = "range",
                    name = "Arena Frame Scale",
                    desc = "Adjust the scale of arena unit frames.",
                    min = 0.5, max = 2, step = 0.01,
                    order = 6,
                    get = function() return M.db.arenaScale end,
                    set = function(_, v)
                        M.db.arenaScale = v
                        BasicUI:RequestReload()
                    end,
                },

            },
        },

        ------------------------------------------------
        -- Castbar
        ------------------------------------------------

        castbar = {
            type = "group",
            name = "Castbar",
            inline = true,
            order = 4,
			disabled = UnitframesDisabled,
            args = {

                enableCastbar = {
                    type = "toggle",
                    name = "Enable Castbar",
                    desc = "Enable the unit frame cast bar.",
                    order = 1,
                    get = function() return M.db.enableCastbar end,
                    set = function(_, v)
                        M.db.enableCastbar = v
                        BasicUI:RequestReload()
                    end,
                },

                castbarScale = {
                    type = "range",
                    name = "Castbar Scale",
                    desc = "Adjust the scale of the cast bar.",
                    min = 0.5, max = 2, step = 0.01,
                    order = 2,
                    get = function() return M.db.castbarScale end,
                    set = function(_, v)
                        M.db.castbarScale = v
                        BasicUI:RequestReload()
                    end,
                },

            },
        },

        ------------------------------------------------
        -- Pet Frame
        ------------------------------------------------

        pet = {
            type = "group",
            name = "Pet Frame",
            inline = true,
            order = 5,
			disabled = UnitframesDisabled,
            args = {

                enablePet = {
                    type = "toggle",
                    name = "Enable Pet Frame",
                    desc = "Enable the pet unit frame.",
                    order = 1,
                    get = function() return M.db.enablePet end,
                    set = function(_, v)
                        M.db.enablePet = v
                        BasicUI:RequestReload()
                    end,
                },

                petFontSize = {
                    type = "range",
                    name = "Pet Font Size",
                    desc = "Adjust the font size used on the pet frame.",
                    min = 8, max = 32, step = 1,
                    order = 2,
                    get = function() return M.db.petFontSize end,
                    set = function(_, v)
                        M.db.petFontSize = v
                        BasicUI:RequestReload()
                    end,
                },

                petColor = {
                    type = "color",
                    name = "Pet Name Color",
                    desc = "Set the color used for the pet name display.",
                    order = 3,
                    get = function()
                        local c = M.db.petColor
                        return c.r, c.g, c.b
                    end,
                    set = function(_, r, g, b)
                        local c = M.db.petColor
                        c.r, c.g, c.b = r, g, b
                        BasicUI:RequestReload()
                    end,
                },

            },
        },

        ------------------------------------------------
        -- Health Options
        ------------------------------------------------

        health = {
            type = "group",
            name = "Health Options",
            inline = true,
            order = 6,
			disabled = UnitframesDisabled,
            args = {

                enableClassHealth = {
                    type = "toggle",
                    name = "Class Colored Health",
                    desc = "Color player health bars based on class.",
                    order = 1,
                    get = function() return M.db.enableClassHealth end,
                    set = function(_, v)
                        M.db.enableClassHealth = v
                        BasicUI:RequestReload()
                    end,
                },

                hideHitText = {
                    type = "toggle",
                    name = "Hide Hit Text",
                    desc = "Hide floating combat text on unit frames.",
                    order = 2,
                    get = function() return M.db.hideHitText end,
                    set = function(_, v)
                        M.db.hideHitText = v
                        BasicUI:RequestReload()
                    end,
                },

            },
        },

    },
}

--============================================================
-- REGISTER MODULE
--============================================================
BasicUI:RegisterModule(MODULE_NAME,M)