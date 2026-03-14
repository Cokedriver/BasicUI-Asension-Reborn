--============================================================
-- BasicUI QoL: Automation
--============================================================

BasicUI_QoL_RegisterModule("Automation", {

	frame = nil,

	OnEnable = function(self, M)

		if not M.db.enableAutomation then return end

		if not self.frame then
			self.frame = CreateFrame("Frame")
		end

		self.frame:RegisterEvent("LOOT_BIND_CONFIRM")
		self.frame:RegisterEvent("MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL")
		self.frame:RegisterEvent("MAIL_LOCK_SEND_ITEMS")

		self.frame:SetScript("OnEvent", function(_, event, arg1)

			if not M.db.enableAutomation then return end

			if event == "LOOT_BIND_CONFIRM" then

				ConfirmLootSlot(arg1)
				StaticPopup_Hide("LOOT_BIND")

			elseif event == "MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL" then

				SellCursorItem()

			elseif event == "MAIL_LOCK_SEND_ITEMS" then

				RespondMailLockSendItem(arg1, true)

			end

		end)

	end,

	OnDisable = function(self)

		if self.frame then
			self.frame:UnregisterAllEvents()
		end

	end,

})