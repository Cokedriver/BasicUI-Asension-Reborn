BasicUI_QoL_RegisterModule("Automation", function(M)

	if not M.db.enableAutomation then return end

	local f = CreateFrame("Frame")
	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	f:RegisterEvent("LOOT_BIND_CONFIRM")
	f:RegisterEvent("MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL")
	f:RegisterEvent("MAIL_LOCK_SEND_ITEMS")

	-------------------------------------------------
	-- Move Loot Roll Frames
	-------------------------------------------------
	local function MoveLootRoll()
		for i = 1, 4 do
			local frame = _G["GroupLootFrame"..i]
			if frame then
				frame:ClearAllPoints()
				frame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
			end
		end
	end

	-------------------------------------------------
	-- Move Achievement / Loot Alerts
	-------------------------------------------------
	local function MoveAlertFrames()
		if AlertFrame then
			AlertFrame:ClearAllPoints()
			AlertFrame:SetPoint("TOP", UIParent, "TOP", 0, -180)
		end
	end

	f:SetScript("OnEvent", function(_, event, ...)

		if event == "PLAYER_ENTERING_WORLD" then

			C_Timer.After(1, function()
				MoveLootRoll()
				MoveAlertFrames()

				-- Prevent Blizzard from resetting alert anchors
				if AlertFrame_SetUpAnchors then
					hooksecurefunc("AlertFrame_SetUpAnchors", MoveAlertFrames)
				end
			end)

			C_Timer.After(5, function()
				M.isDataReady = true
			end)

		elseif event == "LOOT_BIND_CONFIRM" then
			ConfirmLootSlot(...)
			StaticPopup_Hide("LOOT_BIND")

		elseif event == "MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL" then
			SellCursorItem()

		elseif event == "MAIL_LOCK_SEND_ITEMS" then
			RespondMailLockSendItem(..., true)
		end
	end)

end)