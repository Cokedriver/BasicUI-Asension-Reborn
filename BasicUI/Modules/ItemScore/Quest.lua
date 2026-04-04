local addonName, BasicUI = ...

if not (BasicUI and BasicUI.ItemScore and BasicUI.ItemScore.Upgrades) then return end

local U = BasicUI.ItemScore.Upgrades
local db = BasicDB and BasicDB.ItemScore

local function AddRewardScore(button, index)
    if not db or not db.showQuestRewards then return end

    local link = GetQuestItemLink("choice", index)
    if not link then return end

    local result = U:GetUpgradePercent(link)
    if not result or type(result) ~= "number" then return end

    if not button.BasicScoreText then
        button.BasicScoreText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        button.BasicScoreText:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 2, 2)
    end

    local color = result > 0 and "|cff00ff00" or "|cffff0000"
    button.BasicScoreText:SetText(color..math.floor(result).."%|r")
end

local function UpdateRewards()
    for i = 1, GetNumQuestChoices() do
        AddRewardScore(_G["QuestInfoItem"..i], i)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("QUEST_COMPLETE")

f:SetScript("OnEvent", function()
    C_Timer.After(0.05, UpdateRewards)
end)