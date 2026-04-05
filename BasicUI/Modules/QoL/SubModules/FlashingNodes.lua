--============================================================
-- BasicUI QoL: Flashing Nodes (BLINK FIX)
--============================================================

BasicUI_QoL_RegisterModule("FlashingNodes", {

    ticker = nil,
    flash = false,

    Start = function(self, M)

        if self.ticker then return end

        local onTime  = 0.6   -- how long it's visible
        local offTime = 0.6   -- how long it's hidden

        local function Blink()

            if not M.db.enableFlashingNodes then return end

            self.flash = not self.flash

            local texture = "Interface\\AddOns\\BasicUI\\Media\\objecticons_" .. (self.flash and "on" or "off")
            Minimap:SetBlipTexture(texture)

            -- 🔥 Dynamic delay (this is the key)
            local delay = self.flash and onTime or offTime

            self.ticker = C_Timer.NewTimer(delay, Blink)
        end

        -- start loop
        Blink()

    end,

    Stop = function(self)

        if self.ticker then
            self.ticker:Cancel()
            self.ticker = nil
        end

        Minimap:SetBlipTexture("Interface\\AddOns\\BasicUI\\Media\\objecticons_on")
    end,

    OnEnable = function(self, M)
        if not M.db.enableFlashingNodes then return end
        self:Start(M)
    end,

    OnDisable = function(self)
        self:Stop()
    end,

})