BasicUI_QoL_RegisterModule("Minimap", function(M)

	if not M.db.enableMinimap then return end

	MinimapCluster:SetScale(1.193)

	-- Hide the buttons
	if MinimapZoomIn and MinimapZoomOut then
		MinimapZoomIn:Hide()
		MinimapZoomOut:Hide()
	end

	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", function(_, delta)
		if delta > 0 then
			-- Minimap_ZoomIn handles the boundary check internally
			Minimap_ZoomIn()
		else
			-- Minimap_ZoomOut handles the boundary check internally
			Minimap_ZoomOut()
		end
	end)

end)