--============================================================
-- BasicUI QoL: Minimap
--============================================================

BasicUI_QoL_RegisterModule("Minimap", {

	hooked = false,
	defaultScale = nil,

	------------------------------------------------------------
	-- Enable
	------------------------------------------------------------

	OnEnable = function(self, M)

		if not M.db.enableMinimap then return end

		------------------------------------------------------------
		-- Store default scale
		------------------------------------------------------------

		if not self.defaultScale then
			self.defaultScale = MinimapCluster:GetScale()
		end

		------------------------------------------------------------
		-- Apply scale
		------------------------------------------------------------

		MinimapCluster:SetScale(1.193)

		------------------------------------------------------------
		-- Hide Zoom Buttons
		------------------------------------------------------------

		if MinimapZoomIn then
			MinimapZoomIn:Hide()
		end

		if MinimapZoomOut then
			MinimapZoomOut:Hide()
		end

		------------------------------------------------------------
		-- Mouse Wheel Zoom (hook only once)
		------------------------------------------------------------

		if not self.hooked then

			Minimap:EnableMouseWheel(true)

			Minimap:HookScript("OnMouseWheel", function(_, delta)

				if not M.db.enableMinimap then return end

				if delta > 0 then
					Minimap_ZoomIn()
				else
					Minimap_ZoomOut()
				end

			end)

			self.hooked = true

		end

	end,

	------------------------------------------------------------
	-- Disable
	------------------------------------------------------------

	OnDisable = function(self)

		------------------------------------------------------------
		-- Restore scale
		------------------------------------------------------------

		if self.defaultScale then
			MinimapCluster:SetScale(self.defaultScale)
		end

		------------------------------------------------------------
		-- Restore zoom buttons
		------------------------------------------------------------

		if MinimapZoomIn then
			MinimapZoomIn:Show()
		end

		if MinimapZoomOut then
			MinimapZoomOut:Show()
		end

	end,

})