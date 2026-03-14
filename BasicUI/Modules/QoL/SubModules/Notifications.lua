--============================================================
-- BasicUI QoL: Notifications
--============================================================

BasicUI_QoL_RegisterModule("Notifications", {

	frame = nil,
	alertHooked = false,

	------------------------------------------------------------
	-- Move Zone Text
	------------------------------------------------------------

	MoveZoneText = function(self)

		local frames = { ZoneTextFrame, SubZoneTextFrame }

		for _, f in ipairs(frames) do

			if f then
				f:ClearAllPoints()
				f:SetPoint("CENTER", UIParent, "CENTER", 0, 300)
			end

		end

	end,

	------------------------------------------------------------
	-- Move Loot Roll Frames
	------------------------------------------------------------

	MoveLootRoll = function(self)

		for i = 1, 4 do

			local frame = _G["GroupLootFrame"..i]

			if frame then
				frame:ClearAllPoints()
				frame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
			end

		end

	end,

	------------------------------------------------------------
	-- Move Alert Frames
	------------------------------------------------------------

	MoveAlertFrames = function(self)

		if AlertFrame then
			AlertFrame:ClearAllPoints()
			AlertFrame:SetPoint("TOP", UIParent, "TOP", 0, -180)
		end

	end,

	------------------------------------------------------------
	-- Resize Loot Icons
	------------------------------------------------------------

	ResizeLootIcons = function(self)

		if not AlertFrame then return end

		for i = 1, AlertFrame:GetNumChildren() do

			local child = select(i, AlertFrame:GetChildren())

			if child and child.Icon then
				child.Icon:SetSize(40,40)
			end

		end

	end,

	------------------------------------------------------------
	-- Enable
	------------------------------------------------------------

	OnEnable = function(self, M)

		if not M.db.enableNotifications then return end

		if not self.frame then
			self.frame = CreateFrame("Frame")
		end

		self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
		self.frame:RegisterEvent("START_LOOT_ROLL")

		self.frame:SetScript("OnEvent", function(_, event)

			if not M.db.enableNotifications then return end

			if event == "PLAYER_ENTERING_WORLD" then

				C_Timer.After(1, function()

					if M.db.enableZoneTextMove then
						self:MoveZoneText()
					end

					if M.db.enableAlertMove then
						self:MoveAlertFrames()
					end

					if M.db.enableLargeLootIcons then
						self:ResizeLootIcons()
					end

					if not self.alertHooked and AlertFrame_SetUpAnchors then

						hooksecurefunc("AlertFrame_SetUpAnchors", function()

							if M.db.enableAlertMove then
								self:MoveAlertFrames()
							end

						end)

						self.alertHooked = true

					end

				end)

			elseif event == "START_LOOT_ROLL" then

				if M.db.enableLootMove then
					self:MoveLootRoll()
				end

			end

		end)

	end,

	------------------------------------------------------------
	-- Disable
	------------------------------------------------------------

	OnDisable = function(self)

		if self.frame then
			self.frame:UnregisterAllEvents()
		end

	end,

})