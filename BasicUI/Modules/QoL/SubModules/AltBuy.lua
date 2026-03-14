--============================================================
-- BasicUI QoL: Alt Buy
--============================================================

BasicUI_QoL_RegisterModule("AltBuy", {

	hooked = false,

	----------------------------------------------------------
	-- Alt Buy Logic
	----------------------------------------------------------

	HandleAltBuy = function(self, M, btn, button)

		----------------------------------------------------------
		-- Module disabled
		----------------------------------------------------------

		if not M.db.enableAltBuy then return end

		----------------------------------------------------------
		-- Alt + Right Click only
		----------------------------------------------------------

		if button ~= "RightButton" or not IsAltKeyDown() then return end
		if not MerchantFrame or not MerchantFrame:IsShown() then return end

		local id = btn and btn:GetID()
		if not id then return end

		local _, _, price, batch, avail, _, extendedCost = GetMerchantItemInfo(id)

		----------------------------------------------------------
		-- Skip extended cost items (tokens / badges)
		----------------------------------------------------------

		if extendedCost then return end

		----------------------------------------------------------
		-- Prevent divide-by-zero
		----------------------------------------------------------

		if not price or price <= 0 then return end

		local link = GetMerchantItemLink(id)
		if not link then return end

		----------------------------------------------------------
		-- Get stack size safely
		----------------------------------------------------------

		local _, _, _, _, _, _, _, maxStack = GetItemInfo(link)

		maxStack = maxStack or batch or 1
		batch = batch or 1

		----------------------------------------------------------
		-- Calculate stacks we can buy
		----------------------------------------------------------

		local stacks = math.floor(maxStack / batch)

		----------------------------------------------------------
		-- Check money
		----------------------------------------------------------

		local canAfford = math.floor(GetMoney() / price)

		local qty = math.min(stacks, canAfford)

		----------------------------------------------------------
		-- Respect vendor stock limits
		----------------------------------------------------------

		if avail and avail ~= -1 then
			qty = math.min(qty, avail)
		end

		----------------------------------------------------------
		-- Purchase
		----------------------------------------------------------

		if qty > 0 then
			BuyMerchantItem(id, qty)
		end

	end,

	----------------------------------------------------------
	-- ENABLE
	----------------------------------------------------------

	OnEnable = function(self, M)

		if self.hooked then return end

		hooksecurefunc("MerchantItemButton_OnModifiedClick", function(btn, button)
			self:HandleAltBuy(M, btn, button)
		end)

		self.hooked = true

	end,

	----------------------------------------------------------
	-- DISABLE
	----------------------------------------------------------

	OnDisable = function(self)
		-- Cannot remove hooksecurefunc safely
		-- Module simply stops responding via db check
	end,

})