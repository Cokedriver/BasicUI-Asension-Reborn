--==============================
-- PLUGIN: Spec
--==============================

local Datapanel = BasicUI:GetModule("Datapanel")
if not Datapanel then return end

local Plugin = {}
Plugin.name = "spec"

--============================================================
-- COMPLETE ROLE DEFINITIONS
--============================================================
local ROLE_DATA = {

    DRUID = {
        Feral = {
            Guardian = {
                talents = { "thick hide", "survival instincts" },
                role = "Tank"
            },
            ["Feral DPS"] = {
                talents = { "ferocious bite", "mangle", "rip" },
                role = "DPS"
            }
        },
        Balance = {
            Balance = {
                talents = { "moonkin form", "wrath", "starfire" },
                role = "DPS"
            }
        },
        Restoration = {
            Restoration = {
                talents = { "lifebloom", "wild growth", "swiftmend" },
                role = "Healer"
            }
        }
    },

    PALADIN = {
        Protection = {
            Protection = {
                talents = { "holy shield", "ardent defender" },
                role = "Tank"
            }
        },
        Retribution = {
            Retribution = {
                talents = { "crusader strike", "divine storm" },
                role = "DPS"
            }
        },
        Holy = {
            Holy = {
                talents = { "holy shock", "beacon of light" },
                role = "Healer"
            }
        }
    },

    WARRIOR = {
        Protection = {
            Protection = {
                talents = { "shield slam", "devastate" },
                role = "Tank"
            }
        },
        Arms = {
            Arms = {
                talents = { "mortal strike", "bladestorm" },
                role = "DPS"
            }
        },
        Fury = {
            Fury = {
                talents = { "bloodthirst", "flurry" },
                role = "DPS"
            }
        }
    },

    SHAMAN = {
        Enhancement = {
            ["Enhancement Tank"] = {
                buffs = { "earthen guardian" },
                role = "Tank"
            },
            ["Enhancement DPS"] = {
                talents = { "stormstrike", "lava lash" },
                role = "DPS"
            }
        },
        Elemental = {
            Elemental = {
                talents = { "lightning bolt", "lava burst" },
                role = "DPS"
            }
        },
        Restoration = {
            Restoration = {
                talents = { "chain heal", "riptide" },
                role = "Healer"
            }
        }
    },

    PRIEST = {
        Holy = {
            Holy = {
                talents = { "circle of healing", "guardian spirit" },
                role = "Healer"
            }
        },
        Discipline = {
            Discipline = {
                talents = { "power word: shield", "penance" },
                role = "Healer"
            }
        },
        Shadow = {
            Shadow = {
                talents = { "shadowform", "vampiric touch" },
                role = "DPS"
            }
        }
    },

    DEATHKNIGHT = {
        Blood = {
            Blood = {
                talents = { "vampiric blood", "heart strike" },
                role = "Tank"
            }
        },
        Frost = {
            Frost = {
                talents = { "frost strike", "howling blast" },
                role = "DPS"
            }
        },
        Unholy = {
            Unholy = {
                talents = { "scourge strike", "summon gargoyle" },
                role = "DPS"
            }
        }
    },

    ROGUE = {
        Assassination = {
            Assassination = {
                talents = { "mutilate", "envenom" },
                role = "DPS"
            }
        },
        Combat = {
            Combat = {
                talents = { "sinister strike", "killing spree" },
                role = "DPS"
            }
        },
        Subtlety = {
            Subtlety = {
                talents = { "shadowstep", "hemorrhage" },
                role = "DPS"
            }
        }
    },

    MAGE = {
        Arcane = {
            Arcane = {
                talents = { "arcane blast", "arcane power" },
                role = "DPS"
            }
        },
        Fire = {
            Fire = {
                talents = { "pyroblast", "combustion" },
                role = "DPS"
            }
        },
        Frost = {
            Frost = {
                talents = { "ice lance", "deep freeze" },
                role = "DPS"
            }
        }
    },

    HUNTER = {
        BeastMastery = {
            ["Beast Mastery"] = {
                talents = { "bestial wrath", "kill command" },
                role = "DPS"
            }
        },
        Marksmanship = {
            Marksmanship = {
                talents = { "aimed shot", "chimera shot" },
                role = "DPS"
            }
        },
        Survival = {
            Survival = {
                talents = { "explosive shot", "black arrow" },
                role = "DPS"
            }
        }
    }
}

--============================================================
-- HELPERS
--============================================================

local function GetTalentNames(entries)
    local names = {}

    for _, entry in ipairs(entries) do
        if entry.Name then
            table.insert(names, entry.Name:lower())
        end
    end

    return names
end

local function HasAny(list, values)
    if not values then return false end

    for _, v in ipairs(values) do
        for _, name in ipairs(list) do
            if name:find(v) then
                return true
            end
        end
    end

    return false
end

local function HasBuff(buffList)
    if not buffList then return false end

    for i = 1, 40 do
        local name = UnitBuff("player", i)
        if not name then break end

        name = name:lower()

        for _, buff in ipairs(buffList) do
            if name:find(buff) then
                return true
            end
        end
    end

    return false
end

--============================================================
-- Determine Spec based on Talent Distribution
--============================================================
local function GetPlayerSpec()

    if not C_CharacterAdvancement or not C_CharacterAdvancement.GetKnownTalentEntries then
        return UnitClass("player") or "Unknown"
    end

    local class = select(2, UnitClass("player"))
    local entries = C_CharacterAdvancement.GetKnownTalentEntries()

    if not entries or #entries == 0 then
        return UnitClass("player") or "Unknown"
    end

    local tabCounts = {}
    local talentNames = GetTalentNames(entries)

    for _, entry in ipairs(entries) do
        if entry.Tab then
            tabCounts[entry.Tab] = (tabCounts[entry.Tab] or 0) + 1
        end
    end

    -- Determine primary tab
    local maxCount, primaryTab = 0, nil

    for tab, count in pairs(tabCounts) do
        if count > maxCount then
            maxCount = count
            primaryTab = tab
        end
    end

    if not primaryTab then
        return UnitClass("player") or "Unknown", tabCounts
    end

    local formattedTab = primaryTab:gsub("(%u)", " %1"):gsub("^%s+", "")

    --========================================================
    -- 🔥 ADVANCED ROLE DETECTION
    --========================================================
    local classData = ROLE_DATA[class]

    if classData and classData[formattedTab] then
        local specGroup = classData[formattedTab]

	-- PASS 1: Buffs (highest priority)
	for specName, data in pairs(specGroup) do
		if data.buffs and HasBuff(data.buffs) then
			return specName, tabCounts
		end
	end

	-- PASS 2: Talents
	for specName, data in pairs(specGroup) do
		if data.talents and HasAny(talentNames, data.talents) then
			return specName, tabCounts
		end
	end
    end

    -- fallback
    return formattedTab, tabCounts
end

--============================================================
-- Get Equipped Enchants
--============================================================
local function GetEnchantList()

    local names = {}

    if C_MysticEnchant and C_MysticEnchant.GetEquippedEnchants then

        local equipped = C_MysticEnchant.GetEquippedEnchants()

        if equipped then
            for _, data in ipairs(equipped) do
                if data.name then
                    table.insert(names, data.name)
                end
            end
        end

    end

    return names

end

--============================================================
-- OnEnable
--============================================================
function Plugin:OnEnable()

    Datapanel:RegisterEvent("PLAYER_LOGIN", function()
        self:Refresh()
    end)

    Datapanel:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:Refresh()
    end)

    Datapanel:RegisterEvent("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED", function()
        self:Refresh()
    end)

end

--============================================================
-- Refresh (panel text)
--============================================================
function Plugin:Refresh()

    if not self.frame then return end

    local specName = GetPlayerSpec()
    local labelColor = BasicUI:GetClassHex()

    local text = string.format("|cff%sSpec:|r |cffffffff%s|r", labelColor, specName)

    self.frame.text:SetText(text)
    self.frame:SetWidth(self.frame.text:GetStringWidth() + 12)

end

--============================================================
-- Tooltip
--============================================================
local function ShowTooltip(self)

	local Datapanel = BasicUI:GetModule("Datapanel")

	if Datapanel and Datapanel.AnchorTooltip then
		Datapanel:AnchorTooltip(GameTooltip, self)
	else
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
	end

	GameTooltip:ClearLines()

    local header = Datapanel:GetColoredPlayerHeader("Spec")

    GameTooltip:AddLine(header)
    GameTooltip:AddLine(" ")

    local specName, tabCounts = GetPlayerSpec()

    GameTooltip:AddDoubleLine("Active Spec:", specName, 1,1,1, 0,1,0)

    local presetName = "None active"

    if MysticEnchantManagerUtil and MysticEnchantManagerUtil.GetActivePreset then

        local presetId = MysticEnchantManagerUtil.GetActivePreset()

        if presetId then
            presetName = MysticEnchantManagerUtil.GetPresetName(presetId)
        end

    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Mystic Enchant Preset", 0.1, 0.8, 1)
    GameTooltip:AddLine(presetName, 1, 1, 1)

    local enchants = GetEnchantList()

    if #enchants > 0 then

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Equipped Enchants:", 1, 0.82, 0)

        for _, name in ipairs(enchants) do
            GameTooltip:AddLine("  • " .. name, 0.8, 0.8, 0.8)
        end

    end

    if tabCounts and next(tabCounts) then

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Talent Distribution:", 1, 0.82, 0)

        for tab, count in pairs(tabCounts) do

            local formatted = tab:gsub("(%u)", " %1"):gsub("^%s+", "")

            GameTooltip:AddDoubleLine(
                "  " .. formatted,
                count .. " talents",
                1,1,1,
                0.7,0.7,0.7
            )

        end

    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff00ff00Left-Click:|r Open Talents", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cff00ff00Right-Click:|r Open Mystic Enchants", 0.7, 0.7, 0.7)

    GameTooltip:Show()

end

--============================================================
-- CreateFrame
--============================================================
function Plugin:CreateFrame(parent)

    local f = CreateFrame("Button", nil, parent)

    f:SetHeight(20)
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    f.text = f:CreateFontString(nil, "OVERLAY")
    Datapanel:ApplyStandardFont(f.text)

    f.text:SetPoint("CENTER")

    f:SetScript("OnEnter", ShowTooltip)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    f:SetScript("OnClick", function(self, button)

        if button == "LeftButton" then
            RunBinding("TOGGLETALENTS")

        elseif button == "RightButton" then

            if Collections then

                if Collections:IsShown() and Collections:IsOnTab(3) then
                    Collections:Hide()
                else
                    Collections:Show()
                    Collections:GoToTab(3)
                end

            end

        end

    end)

    self.frame = f
    self:Refresh()

    return f

end

--============================================================
-- Register plugin
--============================================================
Datapanel:RegisterPlugin("spec", Plugin)