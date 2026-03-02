BasicUI_QoL_RegisterModule("AltBuy", function(M)

	if not M.db.enableAltBuy then return end

	hooksecurefunc("MerchantItemButton_OnModifiedClick", function(btn, button)
		if not (IsAltKeyDown() and button == "RightButton") then return end

		local id = btn:GetID()
		if not id then return end

		local _, _, price, batch, avail, _, ext = GetMerchantItemInfo(id)
		if ext or price <= 0 then return end

		local link = GetMerchantItemLink(id)
		if not link then return end

		local maxStack = select(8, GetItemInfo(link)) or batch or 1
		batch = batch or 1

		local stacks = math.floor(maxStack / batch)
		local canAfford = math.floor(GetMoney() / price)
		local qty = math.min(stacks, canAfford)

		if avail and avail ~= -1 then
			qty = math.min(qty, avail)
		end

		if qty > 0 then
			BuyMerchantItem(id, qty)
		end
	end)

end)
