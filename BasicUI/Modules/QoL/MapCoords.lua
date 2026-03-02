BasicUI_QoL_RegisterModule("MapCoords", function(M)

	if not M.db.enableMapCoords then return end
	if not WorldMapFrame then return end

	local f = CreateFrame("Frame", "BasicUI_MapCoords", WorldMapFrame)
	f:SetHeight(16)
	f:SetWidth(400)
	f:SetPoint("BOTTOM", WorldMapFrame, "BOTTOM", -20, 8)

	f.P = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.P:SetPoint("LEFT", f, "LEFT", 20, 0)

	f.C = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.C:SetPoint("RIGHT", f, "RIGHT", -20, 0)

	f:SetScript("OnUpdate", function(self, elapsed)
		self.elapsed = (self.elapsed or 0) + elapsed
		if self.elapsed < 0.1 then return end
		self.elapsed = 0

		if not WorldMapFrame:IsShown() then
			self.P:SetText("")
			self.C:SetText("")
			return
		end

		if M.db.showPlayerCoords then
			local x, y = GetPlayerMapPosition("player")
			if x and x > 0 then
				self.P:SetFormattedText("Player: %.1f, %.1f", x*100, y*100)
			else
				self.P:SetText("")
			end
		end

		if M.db.showCursorCoords and WorldMapDetailFrame then
			local cx, cy = GetCursorPosition()
			local scale = WorldMapDetailFrame:GetEffectiveScale()

			local curX = (cx/scale - WorldMapDetailFrame:GetLeft()) / WorldMapDetailFrame:GetWidth()
			local curY = (WorldMapDetailFrame:GetTop() - cy/scale) / WorldMapDetailFrame:GetHeight()

			if curX >= 0 and curY >= 0 and curX <= 1 and curY <= 1 then
				self.C:SetFormattedText("Cursor: %.1f, %.1f", curX*100, curY*100)
			else
				self.C:SetText("")
			end
		end
	end)

end)
