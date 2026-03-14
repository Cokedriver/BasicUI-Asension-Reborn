--============================================================
-- BasicUI QoL: Zone Text + Alert Position
--============================================================

BasicUI_QoL_RegisterModule("ZoneText", function(M)

	if not M.db.enableZoneText then return end

	------------------------------------------------------------
	-- Zone Text Position
	------------------------------------------------------------

	local function MoveZoneText(frame)

		if not frame then return end

		frame:ClearAllPoints()
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 300)

	end

	local ZoneFrames = {
		ZoneTextFrame,
		SubZoneTextFrame
	}

	for _, frame in ipairs(ZoneFrames) do

		if frame then

			MoveZoneText(frame)

			if not frame.BasicUIHook then

				hooksecurefunc(frame, "SetPoint", function(self)
					MoveZoneText(self)
				end)

				frame.BasicUIHook = true

			end

		end

	end

	------------------------------------------------------------
	-- Achievement / Alert Frames
	------------------------------------------------------------

	local function MoveAlertFrames()

		if not AlertFrame then return end

		AlertFrame:ClearAllPoints()
		AlertFrame:SetPoint("TOP", UIParent, "TOP", 0, -50)

	end

	-- Run when entering world
	local f = CreateFrame("Frame")
	f:RegisterEvent("PLAYER_ENTERING_WORLD")

	f:SetScript("OnEvent", function()

		C_Timer.After(1, MoveAlertFrames)

	end)

	-- Prevent Blizzard from resetting anchor
	if AlertFrame_SetUpAnchors then
		hooksecurefunc("AlertFrame_SetUpAnchors", MoveAlertFrames)
	end

end)