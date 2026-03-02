BasicUI_QoL_RegisterModule("DoubleTradeSkill", function(M)

	if not M.db.enableTradeSkill then return end

	local function TradeSkillFunc()
	   -- Set increased height of professions frame and maximum number of recipes listed
		local tall, numTallProfs = 73, 19

		-- Make the tradeskill frame double-wide
		UIPanelWindows["TradeSkillFrame"] = { area = "override", pushable = 3, xoffset = 0, yoffset = 12, bottomClampOverride = 140 + 12, width = 714, height = 487, whileDead = 1 }

		-- Size the tradeskill frame
		_G["TradeSkillFrame"]:SetWidth(714)
		_G["TradeSkillFrame"]:SetHeight(487 + tall)

		-- Adjust title text
		_G["TradeSkillFrameTitleText"]:ClearAllPoints()
		_G["TradeSkillFrameTitleText"]:SetPoint("TOP", _G["TradeSkillFrame"], "TOP", 0, -18)

		-- Expand the tradeskill list to full height
		_G["TradeSkillListScrollFrame"]:ClearAllPoints()
		_G["TradeSkillListScrollFrame"]:SetPoint("TOPLEFT", _G["TradeSkillFrame"], "TOPLEFT", 25, -75)
		_G["TradeSkillListScrollFrame"]:SetSize(295, 336 + tall)

		-- Create additional list rows
		local oldTradeSkillsDisplayed = TRADE_SKILLS_DISPLAYED

		-- Position existing buttons
		for i = 1 + 1, TRADE_SKILLS_DISPLAYED do
			_G["TradeSkillSkill" .. i]:ClearAllPoints()
			_G["TradeSkillSkill" .. i]:SetPoint("TOPLEFT", _G["TradeSkillSkill" .. (i - 1)], "BOTTOMLEFT", 0, 1)
		end

		-- Create and position new buttons
		_G.TRADE_SKILLS_DISPLAYED = _G.TRADE_SKILLS_DISPLAYED + numTallProfs
		for i = oldTradeSkillsDisplayed + 1, TRADE_SKILLS_DISPLAYED do
			local button = CreateFrame("Button", "TradeSkillSkill" .. i, TradeSkillFrame, "TradeSkillSkillButtonTemplate")
			button:SetID(i)
			button:Hide()
			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", _G["TradeSkillSkill" .. (i - 1)], "BOTTOMLEFT", 0, 1)
		end

		-- Set highlight bar width when shown
		hooksecurefunc(_G["TradeSkillHighlightFrame"], "Show", function()
			_G["TradeSkillHighlightFrame"]:SetWidth(290)
		end)

		-- Move the tradeskill detail frame to the right and stretch it to full height
		_G["TradeSkillDetailScrollFrame"]:ClearAllPoints()
		_G["TradeSkillDetailScrollFrame"]:SetPoint("TOPLEFT", _G["TradeSkillFrame"], "TOPLEFT", 352, -74)
		_G["TradeSkillDetailScrollFrame"]:SetSize(298, 336 + tall)
		-- _G["TradeSkillReagent1"]:SetHeight(500) -- Debug

		-- Hide detail scroll frame textures
		_G["TradeSkillDetailScrollFrameTop"]:SetAlpha(0)
		_G["TradeSkillDetailScrollFrameBottom"]:SetAlpha(0)

		-- Create texture for skills list
		local RecipeInset = _G["TradeSkillFrame"]:CreateTexture(nil, "ARTWORK")
		RecipeInset:SetSize(304, 361 + tall)
		RecipeInset:SetPoint("TOPLEFT", _G["TradeSkillFrame"], "TOPLEFT", 16, -72)
		RecipeInset:SetTexture("Interface\\RAIDFRAME\\UI-RaidFrame-GroupBg")

		-- Set detail frame backdrop
		local DetailsInset = _G["TradeSkillFrame"]:CreateTexture(nil, "ARTWORK")
		DetailsInset:SetSize(302, 339 + tall)
		DetailsInset:SetPoint("TOPLEFT", _G["TradeSkillFrame"], "TOPLEFT", 348, -72)
		DetailsInset:SetTexture("Interface\\AddOns\\BasicUI\\Media\\ui-guildachievement-parchment-horizontal-desaturated.blp")
		-- DetailsInset:SetTexture(0.2, 0.2, 0.2, 1)


		-- Hide expand tab (left of All button)
		_G["TradeSkillExpandTabLeft"]:Hide()

		-- Hide skills list horizontal dividing bar (this hides it behind RecipeInset)
		TradeSkillHorizontalBarLeft:SetSize(1, 1)
		TradeSkillHorizontalBarLeft:Hide()

		-- Get tradeskill frame textures
		local regions = { _G["TradeSkillFrame"]:GetRegions() }

		-- Set top left texture
		regions[3]:SetTexture("Interface\\AddOns\\BasicUI\\Media\\DoubleTrade")
		regions[3]:SetTexCoord(0.25, 0.75, 0, 1)
		regions[3]:SetSize(512, 512)

		-- Set top right texture
		regions[4]:ClearAllPoints()
		regions[4]:SetPoint("TOPLEFT", regions[3], "TOPRIGHT", 0, 0)
		regions[4]:SetTexture("Interface\\AddOns\\BasicUI\\Media\\DoubleTrade")
		regions[4]:SetTexCoord(0.75, 1, 0, 1)
		regions[4]:SetSize(256, 512)

		-- Hide bottom left and bottom right textures
		TradeSkillFrameBottomLeftTexture:Hide()
		TradeSkillFrameBottomRightTexture:Hide()

		-- Hide horizonal bar in recipe list
		regions[8]:Hide()
		regions[9]:Hide() -- The shorter pesky horizontal bar that only shows sometimes (texture is 130968)

		-- Move skill rank text
		TradeSkillRankFrameSkillRank:ClearAllPoints()
		TradeSkillRankFrameSkillRank:SetPoint("TOP", TradeSkillRankFrame, "TOP", 0, -1)

		-- Move create button row
		_G["TradeSkillCreateButton"]:ClearAllPoints()
		_G["TradeSkillCreateButton"]:SetPoint("RIGHT", _G["TradeSkillCancelButton"], "LEFT", -1, 0)

		-- Position and size close button
		_G["TradeSkillCancelButton"]:SetSize(80, 22)
		_G["TradeSkillCancelButton"]:SetText(CLOSE)
		_G["TradeSkillCancelButton"]:ClearAllPoints()
		_G["TradeSkillCancelButton"]:SetPoint("BOTTOMRIGHT", _G["TradeSkillFrame"], "BOTTOMRIGHT", -42, 54)

		-- Position close box
		_G["TradeSkillFrameCloseButton"]:ClearAllPoints()
		_G["TradeSkillFrameCloseButton"]:SetPoint("TOPRIGHT", _G["TradeSkillFrame"], "TOPRIGHT", -30, -8)

		-- Position dropdown menus
		TradeSkillInvSlotDropDown:ClearAllPoints()
		TradeSkillInvSlotDropDown:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", 510, -40)
		TradeSkillSubClassDropDown:ClearAllPoints()
		TradeSkillSubClassDropDown:SetPoint("RIGHT", TradeSkillInvSlotDropDown, "LEFT", 0, 0)

		-- Move search box below rank frame
		TradeSkillFrameEditBox:ClearAllPoints()
		TradeSkillFrameEditBox:SetPoint("TOPRIGHT", TradeSkillRankFrame, "BOTTOMRIGHT", 0, 1)
		TradeSkillFrameEditBox:SetFrameLevel(3)

		-- Move have materials checkbox down slightly
		TradeSkillFrameAvailableFilterCheckButton:ClearAllPoints()
		TradeSkillFrameAvailableFilterCheckButton:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", 70, -53)

		-- Ensure have materials checkbox doesn't overlap search box
		TradeSkillFrameAvailableFilterCheckButtonText:SetWidth(110)
		TradeSkillFrameAvailableFilterCheckButtonText:SetWordWrap(false)
		TradeSkillFrameAvailableFilterCheckButtonText:SetJustifyH("LEFT")

		-- Classic Profession Filter addon fixes
		if IsAddOnLoaded("ClassicProfessionFilter") and TradeSkillFrame.SearchBox and TradeSkillFrame.HaveMats and TradeSkillFrame.HaveMats.text and TradeSkillFrame.SearchMats and TradeSkillFrame.SearchMats.text then
			TradeSkillFrame.SearchBox:ClearAllPoints()
			TradeSkillFrame.SearchBox:SetPoint("LEFT", TradeSkillRankFrame, "RIGHT", 20, -10)

			TradeSkillFrame.HaveMats:ClearAllPoints()
			TradeSkillFrame.HaveMats:SetPoint("LEFT", TradeSkillFrame.SearchBox, "RIGHT", 10, 8)
			TradeSkillFrame.HaveMats.text:SetText(L["Have mats?"])
			TradeSkillFrame.HaveMats:SetHitRectInsets(0, -TradeSkillFrame.HaveMats.text:GetStringWidth() + 4, 0, 0)
			TradeSkillFrame.HaveMats.text:SetJustifyH("LEFT")
			TradeSkillFrame.HaveMats.text:SetWordWrap(false)
			if TradeSkillFrame.HaveMats.text:GetWidth() > 80 then
				TradeSkillFrame.HaveMats.text:SetWidth(80)
				TradeSkillFrame.HaveMats:SetHitRectInsets(0, -80 + 4, 0, 0)
			end

			TradeSkillFrame.SearchMats:ClearAllPoints()
			TradeSkillFrame.SearchMats:SetPoint("BOTTOMLEFT", TradeSkillFrame.HaveMats, "BOTTOMLEFT", 0, -16)
			TradeSkillFrame.SearchMats.text:SetText(L["Search mats?"])
			TradeSkillFrame.SearchMats:SetHitRectInsets(0, -TradeSkillFrame.SearchMats.text:GetStringWidth() + 2, 0, 0)
			TradeSkillFrame.SearchMats.text:SetJustifyH("LEFT")
			TradeSkillFrame.SearchMats.text:SetWordWrap(false)
			if TradeSkillFrame.SearchMats.text:GetWidth() > 80 then
				TradeSkillFrame.SearchMats.text:SetWidth(80)
				TradeSkillFrame.SearchMats:SetHitRectInsets(0, -80 + 4, 0, 0)
			end
		end
	end

	-- Run function when TradeSkill UI has loaded
	if IsAddOnLoaded("Blizzard_TradeSkillUI") then
		TradeSkillFunc("TradeSkill")
	else
		local waitFrame = CreateFrame("FRAME")
		waitFrame:RegisterEvent("ADDON_LOADED")
		waitFrame:SetScript("OnEvent", function(self, event, arg1)
			if arg1 == "Blizzard_TradeSkillUI" then
				TradeSkillFunc("TradeSkill")
				waitFrame:UnregisterAllEvents()
			end
		end)
	end

end)
