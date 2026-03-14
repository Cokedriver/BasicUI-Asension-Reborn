--============================================================
-- BasicUI QoL: Double TradeSkill
--============================================================

BasicUI_QoL_RegisterModule("DoubleTradeSkill", {

	frame = nil,
	applied = false,

	-------------------------------------------------
	-- Apply Double TradeSkill Layout
	-------------------------------------------------

	ApplyLayout = function(self)

		if self.applied then return end

		local frame = TradeSkillFrame
		if not frame then return end

		self.applied = true

		local tall = 73
		local numTallProfs = 19

		-------------------------------------------------
		-- Resize TradeSkill Frame
		-------------------------------------------------

		UIPanelWindows["TradeSkillFrame"] = {
			area = "override",
			pushable = 3,
			xoffset = 0,
			yoffset = 12,
			bottomClampOverride = 152,
			width = 714,
			height = 487,
			whileDead = 1
		}

		frame:SetWidth(714)
		frame:SetHeight(487 + tall)

		-------------------------------------------------
		-- Title
		-------------------------------------------------

		TradeSkillFrameTitleText:ClearAllPoints()
		TradeSkillFrameTitleText:SetPoint("TOP", frame, "TOP", 0, -18)

		-------------------------------------------------
		-- Recipe List Scroll
		-------------------------------------------------

		TradeSkillListScrollFrame:ClearAllPoints()
		TradeSkillListScrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, -75)
		TradeSkillListScrollFrame:SetSize(295, 336 + tall)

		-------------------------------------------------
		-- Expand Recipe List
		-------------------------------------------------

		local oldDisplayed = TRADE_SKILLS_DISPLAYED

		for i = 2, TRADE_SKILLS_DISPLAYED do

			local btn = _G["TradeSkillSkill"..i]
			local prev = _G["TradeSkillSkill"..(i-1)]

			if btn and prev then
				btn:ClearAllPoints()
				btn:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, 1)
			end

		end

		TRADE_SKILLS_DISPLAYED = TRADE_SKILLS_DISPLAYED + numTallProfs

		for i = oldDisplayed + 1, TRADE_SKILLS_DISPLAYED do

			local button = CreateFrame(
				"Button",
				"TradeSkillSkill"..i,
				frame,
				"TradeSkillSkillButtonTemplate"
			)

			button:SetID(i)
			button:Hide()
			button:SetPoint(
				"TOPLEFT",
				_G["TradeSkillSkill"..(i-1)],
				"BOTTOMLEFT",
				0,
				1
			)

		end

		-------------------------------------------------
		-- Highlight Fix
		-------------------------------------------------

		if TradeSkillHighlightFrame then

			hooksecurefunc(TradeSkillHighlightFrame,"Show",function()
				TradeSkillHighlightFrame:SetWidth(290)
			end)

		end

		-------------------------------------------------
		-- Detail Scroll
		-------------------------------------------------

		TradeSkillDetailScrollFrame:ClearAllPoints()
		TradeSkillDetailScrollFrame:SetPoint("TOPLEFT",frame,"TOPLEFT",352,-74)
		TradeSkillDetailScrollFrame:SetSize(298,336 + tall)

		TradeSkillDetailScrollFrameTop:SetAlpha(0)
		TradeSkillDetailScrollFrameBottom:SetAlpha(0)

		-------------------------------------------------
		-- Background Insets
		-------------------------------------------------

		local RecipeInset = frame:CreateTexture(nil,"ARTWORK")
		RecipeInset:SetSize(304,361 + tall)
		RecipeInset:SetPoint("TOPLEFT",frame,"TOPLEFT",16,-72)
		RecipeInset:SetTexture("Interface\\RAIDFRAME\\UI-RaidFrame-GroupBg")

		local DetailsInset = frame:CreateTexture(nil,"ARTWORK")
		DetailsInset:SetSize(302,339 + tall)
		DetailsInset:SetPoint("TOPLEFT",frame,"TOPLEFT",348,-72)
		DetailsInset:SetTexture("Interface\\AddOns\\BasicUI\\Media\\ui-guildachievement-parchment-horizontal-desaturated.blp")

		-------------------------------------------------
		-- Hide Blizzard Elements
		-------------------------------------------------

		if TradeSkillExpandTabLeft then
			TradeSkillExpandTabLeft:Hide()
		end

		if TradeSkillHorizontalBarLeft then
			TradeSkillHorizontalBarLeft:SetSize(1,1)
			TradeSkillHorizontalBarLeft:Hide()
		end

		local regions = { frame:GetRegions() }

		if regions[3] then
			regions[3]:SetTexture("Interface\\AddOns\\BasicUI\\Media\\DoubleTrade")
			regions[3]:SetTexCoord(0.25,0.75,0,1)
			regions[3]:SetSize(512,512)
		end

		if regions[4] then
			regions[4]:ClearAllPoints()
			regions[4]:SetPoint("TOPLEFT",regions[3],"TOPRIGHT",0,0)
			regions[4]:SetTexture("Interface\\AddOns\\BasicUI\\Media\\DoubleTrade")
			regions[4]:SetTexCoord(0.75,1,0,1)
			regions[4]:SetSize(256,512)
		end

		if TradeSkillFrameBottomLeftTexture then
			TradeSkillFrameBottomLeftTexture:Hide()
		end

		if TradeSkillFrameBottomRightTexture then
			TradeSkillFrameBottomRightTexture:Hide()
		end

		if regions[8] then regions[8]:Hide() end
		if regions[9] then regions[9]:Hide() end

		-------------------------------------------------
		-- Rank Text
		-------------------------------------------------

		TradeSkillRankFrameSkillRank:ClearAllPoints()
		TradeSkillRankFrameSkillRank:SetPoint("TOP",TradeSkillRankFrame,"TOP",0,-1)

		-------------------------------------------------
		-- Buttons
		-------------------------------------------------

		TradeSkillCreateButton:ClearAllPoints()
		TradeSkillCreateButton:SetPoint("RIGHT",TradeSkillCancelButton,"LEFT",-1,0)

		TradeSkillCancelButton:SetSize(80,22)
		TradeSkillCancelButton:SetText(CLOSE)

		TradeSkillCancelButton:ClearAllPoints()
		TradeSkillCancelButton:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-42,54)

		TradeSkillFrameCloseButton:ClearAllPoints()
		TradeSkillFrameCloseButton:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-30,-8)

		-------------------------------------------------
		-- Dropdowns
		-------------------------------------------------

		TradeSkillInvSlotDropDown:ClearAllPoints()
		TradeSkillInvSlotDropDown:SetPoint("TOPLEFT",frame,"TOPLEFT",510,-40)

		TradeSkillSubClassDropDown:ClearAllPoints()
		TradeSkillSubClassDropDown:SetPoint("RIGHT",TradeSkillInvSlotDropDown,"LEFT",0,0)

		-------------------------------------------------
		-- Search Box
		-------------------------------------------------

		TradeSkillFrameEditBox:ClearAllPoints()
		TradeSkillFrameEditBox:SetPoint("TOPRIGHT",TradeSkillRankFrame,"BOTTOMRIGHT",0,1)
		TradeSkillFrameEditBox:SetFrameLevel(3)

		-------------------------------------------------
		-- Have Mats Checkbox
		-------------------------------------------------

		TradeSkillFrameAvailableFilterCheckButton:ClearAllPoints()
		TradeSkillFrameAvailableFilterCheckButton:SetPoint("TOPLEFT",frame,"TOPLEFT",70,-53)

		TradeSkillFrameAvailableFilterCheckButtonText:SetWidth(110)
		TradeSkillFrameAvailableFilterCheckButtonText:SetWordWrap(false)
		TradeSkillFrameAvailableFilterCheckButtonText:SetJustifyH("LEFT")

	end,

	-------------------------------------------------
	-- ENABLE
	-------------------------------------------------

	OnEnable = function(self, M)

		if not M.db.enableTradeSkill then return end

		if IsAddOnLoaded("Blizzard_TradeSkillUI") then
			self:ApplyLayout()
			return
		end

		if not self.frame then
			self.frame = CreateFrame("Frame")
		end

		self.frame:RegisterEvent("ADDON_LOADED")

		self.frame:SetScript("OnEvent",function(_,_,addon)

			if addon == "Blizzard_TradeSkillUI" then

				self:ApplyLayout()
				self.frame:UnregisterAllEvents()

			end

		end)

	end,

	OnDisable = function(self)

		if self.frame then
			self.frame:UnregisterAllEvents()
		end

	end,

})