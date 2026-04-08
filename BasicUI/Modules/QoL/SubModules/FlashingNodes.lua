--============================================================
-- BasicUI QoL: Flashing Nodes (SMART + TEXTURE FADE)
--============================================================

BasicUI_QoL_RegisterModule("FlashingNodes", {

    frame = nil,
    time = 0,
    active = false,
    currentState = "on",

    TEX_ON  = "Interface\\AddOns\\BasicUI\\Media\\objecticons_on",
    TEX_OFF = "Interface\\AddOns\\BasicUI\\Media\\objecticons_off",

    ------------------------------------------------
    -- 🔍 Detect nearby nodes (same as before)
    ------------------------------------------------
    HasNearbyNode = function(self)

        local numChildren = Minimap:GetNumChildren()

        for i = 1, numChildren do
            local child = select(i, Minimap:GetChildren())

            if child and child:IsShown() then
                local name = child:GetName()

                if name and (
                    name:find("GatherMate") or
                    name:find("FarmHud") or
                    name:find("MiniMapTracking") or
                    name:find("Resource")
                ) then
                    return true
                end
            end
        end

        return false
    end,

    ------------------------------------------------
    -- 🎬 Smooth easing controller
    ------------------------------------------------
    OnUpdate = function(self, elapsed)

        self.time = self.time + elapsed

        self.active = self:HasNearbyNode()

        if not self.active then
            if self.currentState ~= "on" then
                Minimap:SetBlipTexture(self.TEX_ON)
                self.currentState = "on"
            end
            return
        end

        -- 🧈 Smooth sine timing
        local speed = 4.5
        local wave = (math.sin(self.time * speed) + 1) / 2

        -- Switch threshold (soft timing)
        local threshold = 0.2

        if wave > threshold then
            if self.currentState ~= "on" then
                Minimap:SetBlipTexture(self.TEX_ON)
                self.currentState = "on"
            end
        else
            if self.currentState ~= "off" then
                Minimap:SetBlipTexture(self.TEX_OFF)
                self.currentState = "off"
            end
        end
    end,

    ------------------------------------------------
    -- ▶ Start
    ------------------------------------------------
    Start = function(self, M)

        if self.frame then return end

        Minimap:SetBlipTexture(self.TEX_ON)

        self.frame = CreateFrame("Frame")
        self.frame:SetScript("OnUpdate", function(_, elapsed)
            self:OnUpdate(elapsed)
        end)
    end,

    ------------------------------------------------
    -- ⏹ Stop
    ------------------------------------------------
    Stop = function(self)

        if self.frame then
            self.frame:SetScript("OnUpdate", nil)
            self.frame = nil
        end

        Minimap:SetBlipTexture(self.TEX_ON)
    end,

    ------------------------------------------------
    -- Enable / Disable
    ------------------------------------------------
    OnEnable = function(self, M)
        if not M.db.enableFlashingNodes then return end
        self:Start(M)
    end,

    OnDisable = function(self)
        self:Stop()
    end,

})