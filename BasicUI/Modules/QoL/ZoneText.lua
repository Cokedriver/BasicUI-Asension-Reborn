BasicUI_QoL_RegisterModule("ZoneText", function(M)

	if not M.db.enableZoneText then return end

	local ZoneFrames = { ZoneTextFrame, SubZoneTextFrame }

	for _, f in ipairs(ZoneFrames) do
		if f then
			f:ClearAllPoints()
			f:SetPoint("CENTER", UIParent, "CENTER", 0, 300, true)

			hooksecurefunc(f, "SetPoint", function(self, _, _, _, _, _, internal)
				if not internal then
					self:SetPoint("CENTER", UIParent, "CENTER", 0, 300, true)
				end
			end)
		end
	end
	
	local AchievementFrames = CreateFrame("Frame")
	AchievementFrames:RegisterEvent("PLAYER_ENTERING_WORLD")

	local function RelocateAlerts(self)
		-- List of all frames to move
		local frames = {
			AchievementAlertFrame1,
			DungeonCompletionAlertFrame,
			GuildChallengeAlertFrame
		}

		for _, f in pairs(frames) do
			if f then
				f:ClearAllPoints()
				f:SetPoint("TOP", UIParent, "TOP", 0, -50)
				
				-- Hook the SetPoint function so the game doesn't force them back down
				if not f.hooked then
					hooksecurefunc(f, "SetPoint", function(self, point)
						if point ~= "TOP" then
							self:ClearAllPoints()
							self:SetPoint("TOP", UIParent, "TOP", 0, -50)
						end
					end)
					f.hooked = true
				end
			end
		end
	end

	AchievementFrames:SetScript("OnEvent", RelocateAlerts)

end)
