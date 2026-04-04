--============================================================
-- BasicUI QoL: Map Coordinates + Large Player Icon
--============================================================

BasicUI_QoL_RegisterModule("MapCoords", {

	frame = nil,
	eventFrame = nil,

	------------------------------------------------------------
	-- Create Coordinate Frame
	------------------------------------------------------------

	CreateCoordsFrame = function(self)

		if self.frame then return end

		local f = CreateFrame("Frame", "BasicUI_MapCoords", WorldMapFrame)
		f:SetSize(400,16)
		f:SetPoint("BOTTOM", WorldMapFrame, "BOTTOM", -20, 8)

		f.P = f:CreateFontString(nil,"OVERLAY","GameFontNormal")
		f.P:SetPoint("LEFT",f,"LEFT",20,0)

		f.C = f:CreateFontString(nil,"OVERLAY","GameFontNormal")
		f.C:SetPoint("RIGHT",f,"RIGHT",-20,0)

		local elapsedTotal = 0

		f:SetScript("OnUpdate", function(frame, elapsed)

			elapsedTotal = elapsedTotal + elapsed
			if elapsedTotal < 0.1 then return end
			elapsedTotal = 0

			if not WorldMapFrame:IsShown() then
				frame.P:SetText("")
				frame.C:SetText("")
				return
			end

			--------------------------------------------------------
			-- Player Coordinates
			--------------------------------------------------------

			if self.core.db.showPlayerCoords then

				local x, y = GetPlayerMapPosition("player")

				if x and x > 0 then
					frame.P:SetFormattedText("Player: %.1f, %.1f", x*100, y*100)
				else
					frame.P:SetText("")
				end

			end

			--------------------------------------------------------
			-- Cursor Coordinates
			--------------------------------------------------------

			if self.core.db.showCursorCoords and WorldMapDetailFrame then

				local cx, cy = GetCursorPosition()
				local scale = WorldMapDetailFrame:GetEffectiveScale()

				local left = WorldMapDetailFrame:GetLeft()
				local top = WorldMapDetailFrame:GetTop()
				local width = WorldMapDetailFrame:GetWidth()
				local height = WorldMapDetailFrame:GetHeight()

				if left and top and width and height then

					local curX = (cx/scale - left) / width
					local curY = (top - cy/scale) / height

					if curX >= 0 and curY >= 0 and curX <= 1 and curY <= 1 then
						frame.C:SetFormattedText("Cursor: %.1f, %.1f", curX*100, curY*100)
					else
						frame.C:SetText("")
					end

				end

			end

		end)

		self.frame = f

	end,

	------------------------------------------------------------
	-- Map Position Update
	------------------------------------------------------------

	CreateMapEvents = function(self)

		if self.eventFrame then return end

		local f = CreateFrame("Frame")

		f:RegisterEvent("PLAYER_ENTERING_WORLD")
		f:RegisterEvent("ZONE_CHANGED")
		f:RegisterEvent("ZONE_CHANGED_NEW_AREA")

		f:SetScript("OnEvent", function()

			-- Safe update (no recursion)
			if WorldMapFrame and WorldMapFrame:IsShown() then
				SetMapToCurrentZone()
			end

		end)

		self.eventFrame = f

	end,

	------------------------------------------------------------
	-- Larger Player Icon
	------------------------------------------------------------

	ApplyPlayerIconScale = function(self)

		if WorldMapPlayerIcon then
			WorldMapPlayerIcon:SetScale(1.8)
		end

		if WorldMapPlayerIconTexture then
			WorldMapPlayerIconTexture:SetScale(1.8)
		end

	end,

	------------------------------------------------------------
	-- ENABLE
	------------------------------------------------------------

	OnEnable = function(self, M)

		if not M.db.enableMapCoords then return end
		if not WorldMapFrame then return end

		self.core = M

		self:CreateCoordsFrame()
		--self:CreateMapEvents()
		--self:ApplyPlayerIconScale()

		if self.frame then
			self.frame:Show()
		end

	end,

	------------------------------------------------------------
	-- DISABLE
	------------------------------------------------------------

	OnDisable = function(self)

		if self.frame then
			self.frame:Hide()
		end

	end,

})