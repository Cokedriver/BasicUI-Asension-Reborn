--============================================================
-- MODULE: Chat (BasicUI + cChat merged, cursor-safe)
--============================================================
local addonName, BasicUI = ...
local MODULE_NAME = "Chat"
local M = {}

--============================================================
-- CONFIG DEFAULTS
--============================================================
M.defaults = {
    enabled = true,
    fullMovement = false,
    fontSize = 16,
}

--============================================================
-- LOCAL UPVALUES
--============================================================
local type   = type
local select = select
local gsub   = string.gsub
local _G     = _G

local fullMovement = false

-- Use 0.01 instead of 0 to prevent math errors in Blizzard's FCF_FadeOutChatFrame
CHAT_FRAME_TAB_SELECTED_MOUSEOVER_ALPHA = 1
CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA   = 0.01 
CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA   = 0.5
CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA     = 0.01

CHAT_FONT_HEIGHTS = {
    [1] = 8, [2] = 9, [3] = 10, [4] = 11, [5] = 12, [6] = 13, [7] = 14,
    [8] = 15, [9] = 16, [10] = 17, [11] = 18, [12] = 19, [13] = 20,
}

--============================================================
-- HELPERS: Ensure Chat Window
--============================================================
local function EnsureChatWindow(name)
    for i = 1, NUM_CHAT_WINDOWS do
        local frameName = select(1, GetChatWindowInfo(i))
        if frameName == name then
            return i
        end
    end

    local frameOrIndex = FCF_OpenNewWindow(name)

    if type(frameOrIndex) == "table" and frameOrIndex.GetID then
        return frameOrIndex:GetID()
    end

    return frameOrIndex
end

--============================================================
-- WHISPER SOUND ALERT
--============================================================
local WhisperSound = CreateFrame("Frame")
WhisperSound:RegisterEvent("CHAT_MSG_WHISPER")
WhisperSound:RegisterEvent("CHAT_MSG_BN_WHISPER")

WhisperSound:SetScript("OnEvent", function()
    PlaySoundFile("Interface\\AddOns\\BasicUI\\Media\\Whisper.mp3", "Master")
end)

--============================================================
-- URL COPY POPUP
--============================================================
StaticPopupDialogs["COPY_URL_POPUP"] = {
    text = "URL Found: Press Ctrl+C to Copy",
    button1 = "Close",
    hasEditBox = 1,
    editBoxWidth = 350,
    OnShow = function(self, data)
        self.editBox:SetText(data)
        self.editBox:SetFocus()
        self.editBox:HighlightText()
    end,
    EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

local function LinkOnClick(self, link, text, button)
    if link:sub(1, 3) == "url" then
        local url = link:sub(5)
        StaticPopup_Show("COPY_URL_POPUP", nil, nil, url)
    else
        local handler = ChatFrame_OnHyperlinkShow or _G.ChatFrame_OnHyperlinkShow
        if handler then handler(self, link, text, button) end
    end
end

--============================================================
-- COPY WINDOW
--============================================================
function M:OpenCopyWindow(text)
    if not self.copyFrame then
        local f = CreateFrame("Frame", "BasicUIChatCopy", UIParent, "BackdropTemplate")
        f:SetSize(600, 400)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 16, edgeSize = 16,
            insets   = {left=4,right=4,top=4,bottom=4}
        })
        f:SetBackdropColor(0,0,0,0.9)

        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)

        local scroll = CreateFrame("ScrollFrame", "BasicUIChatCopyScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -32)
        scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 16)

        local eb = CreateFrame("EditBox", nil, scroll)
        eb:SetMultiLine(true)
        eb:SetFontObject(ChatFontNormal)
        eb:SetWidth(550)
        eb:SetAutoFocus(false)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
		eb:SetScript("OnMouseUp", function(self, button)
			if button == "RightButton" then
				self:HighlightText()
			end
		end)

        scroll:SetScrollChild(eb)

        f.scroll   = scroll
        f.editBox  = eb
        self.copyFrame = f
    end

    local f = self.copyFrame
    f:Show()
    f.editBox:SetText(text or "")
    f.editBox:HighlightText()
    f.editBox:SetFocus()
end

--============================================================
-- COPY BUTTON
--============================================================
function M:AddCopyButton(frame)
    if frame.BasicUI_CopyButton then return end

    local btn = CreateFrame("Button", nil, frame)
    btn:SetSize(16, 16)
    btn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    btn:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    btn:SetHighlightTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    btn:SetPushedTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    btn:SetAlpha(0.8)
    btn:SetFrameStrata("HIGH")

    btn:SetScript("OnClick", function()
        local text = ""
        for i = 1, frame:GetNumMessages() do
            local msg = frame:GetMessageInfo(i)
            if msg then text = text .. msg .. "\n" end
        end
        M:OpenCopyWindow(text)
    end)

    frame.BasicUI_CopyButton = btn
end

--============================================================
-- ADDMESSAGE HOOK
--============================================================
local function BasicUI_AddMessage(self, text, ...)
    if type(text) == "string" then
        -- Remove brackets from player names
        text = gsub(text, '(|HBNplayer.-|h)%[(.-)%]|h', '%1%2|h')
        text = gsub(text, '(|Hplayer.-|h)%[(.-)%]|h', '%1%2|h')

        -- Shorten Channel Numbers (e.g., [1. General] -> [1])
        text = gsub(text, '%[(%d0?)%. (.-)%]', '[%1]')

        -- Standard Message Type Abbreviations
        text = gsub(text, '%[Say%]', '[S]')
        text = gsub(text, '%[Yell%]', '[Y]')
        text = gsub(text, '%[Party%]', '[P]')
        text = gsub(text, '%[Party Leader%]', '[PL]')
        text = gsub(text, '%[Guild%]', '[G]')
        text = gsub(text, '%[Officer%]', '[O]')
        text = gsub(text, '%[Raid%]', '[R]')
        text = gsub(text, '%[Raid Warning%]', '[RW]')
        text = gsub(text, '%[Raid Leader%]', '[RL]')
        text = gsub(text, '%[Battleground%]', '[BG]')
        text = gsub(text, '%[Battleground Leader%]', '[BL]')
        text = gsub(text, '%[Dungeon Guide%]', '[DG]')

        -- URL Handling
        text = gsub(text, "([wW][wW][wW]%.[%a%d%.%_%-%/%%]+%:%d+)", "|Hurl:%1|h|cff0099ff%1|r|h")
        text = gsub(text, "([wW][wW][wW]%.[%a%d%.%_%-%/%%]+)",      "|Hurl:%1|h|cff0099ff%1|r|h")
        text = gsub(text, "(http%S+)",                              "|Hurl:%1|h|cff0099ff%1|r|h")
    end
    return self.BasicUI_OrigAddMessage(self, text, ...)
end

--============================================================
-- EDITBOX STYLING
--============================================================
local function StylePrimaryEditBox()
    local eb = ChatFrame1EditBox

    eb:SetAltArrowKeyMode(false)
    eb:ClearAllPoints()
    eb:SetPoint('BOTTOMLEFT', ChatFrame1, 'TOPLEFT', 2, 33)
    eb:SetPoint('BOTTOMRIGHT', ChatFrame1, 'TOPRIGHT', 0, 33)

    -- NEW: Match the font of the main chat window
    -- This gets the font file, size, and flags from ChatFrame1 and applies them to the EditBox
    local font, size, outline = ChatFrame1:GetFont()
    eb:SetFont(font, size, outline)

    -- 1. Make the default Blizzard textures transparent 
    local name = eb:GetName()
    local textures = {
        "Left", "Right", "Mid", 
        "FocusLeft", "FocusRight", "FocusMid"
    }
    for _, tex in ipairs(textures) do
        local gtex = _G[name .. tex]
        if gtex then
            gtex:SetAlpha(0)
        end
    end

    -- 2. Apply your custom backdrop
    eb:SetBackdrop({
        bgFile = [[Interface\DialogFrame\UI-DialogBox-Background-Dark]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        tile = true, tileSize = 16, edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    eb:SetBackdropColor(0, 0, 0, 1)
    
    -- 3. Force Visibility Settings
    eb:SetTextInsets(5, 5, 0, 0)
    eb:SetTextColor(1, 1, 1)
    eb:SetShadowColor(0, 0, 0)
    eb:SetShadowOffset(1, -1)
    eb:SetCursorPosition(0) 
end

--============================================================
-- HYPERLINK TOOLTIP
--============================================================
local origEnter, origLeave = {}, {}
local GameTooltip = GameTooltip

local linktypes = {
    item=true, enchant=true, spell=true, quest=true, unit=true,
    talent=true, achievement=true, glyph=true, currency=true,
    instancelock=true, battlepet=true, battlePetAbil=true,
    garrfollowerability=true, garrfollower=true, garrmission=true
}

local function OnHyperlinkEnter(frame, link, ...)
    local linktype = link:match("(%a+):%d+")
    if linktype and linktypes[linktype] then
        GameTooltip:SetOwner(ChatFrame1Tab, "ANCHOR_TOPLEFT")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    else
        GameTooltip:Hide()
    end

    if origEnter[frame] then
        return origEnter[frame](frame, link, ...)
    end
end

local function OnHyperlinkLeave(frame, ...)
    GameTooltip:Hide()
    if origLeave[frame] then
        return origLeave[frame](frame, ...)
    end
end

function M:EnableItemLinkTooltip()
    for _, v in pairs(CHAT_FRAMES) do
        local chat = _G[v]
        if chat and not chat.BasicUI_URLCopy then
            origEnter[chat] = chat:GetScript('OnHyperlinkEnter')
            origLeave[chat] = chat:GetScript('OnHyperlinkLeave')
            chat:SetScript('OnHyperlinkEnter', OnHyperlinkEnter)
            chat:SetScript('OnHyperlinkLeave', OnHyperlinkLeave)
            chat:SetScript('OnHyperlinkClick', LinkOnClick)
            chat.BasicUI_URLCopy = true
        end
    end
end

--============================================================
-- CHAT FRAME MODIFICATIONS
--============================================================
local function ModChatFrame(chatName)
    local chat = _G[chatName]
    if not chat then return end

    if fullMovement then
        chat:SetClampedToScreen(false)
        chat:SetClampRectInsets(0, 0, 0, 0)
        chat:SetMaxResize(UIParent:GetWidth(), UIParent:GetHeight())
        chat:SetMinResize(150, 25)
    end

    if chatName ~= "ChatFrame2" then
        if not chat.BasicUI_OrigAddMessage then
            chat.BasicUI_OrigAddMessage = chat.AddMessage
            chat.AddMessage = BasicUI_AddMessage
        end
    end
end

function M:ApplyChatStyle()
    for _, v in pairs(CHAT_FRAMES) do
        local chat = _G[v]
        if chat and not chat.BasicUI_hasModification then
            ModChatFrame(chat:GetName())
            chat.BasicUI_hasModification = true
        end
    end
end

--============================================================
-- TAB COLORS
--============================================================
hooksecurefunc("FCFTab_UpdateColors", function(self, selected)

    if not M.db or not M.db.enabled then return end
    local fs = self:GetFontString()
    if not fs then return end

    if selected then
        fs:SetTextColor(0, 0.75, 1)
    else
        fs:SetTextColor(1, 1, 1)
    end
end)

--============================================================
-- SHORT CHANNEL HEADERS + BORDER COLOR
--============================================================
hooksecurefunc('ChatEdit_UpdateHeader', function(editBox)

    if not M.db or not M.db.enabled then return end
    local type = editBox:GetAttribute('chatType')
    if not type then return end

    local info = ChatTypeInfo[type]
    ChatFrame1EditBox:SetBackdropBorderColor(info.r, info.g, info.b)
end)

--============================================================
-- LIFECYCLE
--============================================================
function M:OnInit()

    BasicDB = BasicDB or {}
    BasicDB.Chat = BasicDB.Chat or {}

    self.db = BasicDB.Chat

    BasicUI:CopyDefaults(self.defaults, self.db)

    fullMovement = self.db.fullMovement

end

function M:OnLoadScreen()

    if not self.db or not self.db.enabled then return end
    -- Ensure global alpha constants are set to numeric values to prevent 'max' nil errors
    _G.CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = 0.01
    _G.CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = 0.01

    if ChatTypeInfo then
        for _, info in pairs(ChatTypeInfo) do
            info.colorNameByClass = true
        end
    end

    StylePrimaryEditBox()
    self:ApplyChatStyle()
    self:EnableItemLinkTooltip()

    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame" .. i]
        if frame then
            self:AddCopyButton(frame)
        end
    end

    hooksecurefunc("FCF_OpenTemporaryWindow", function()
        M:ApplyChatStyle()
        M:EnableItemLinkTooltip()
    end)
	
	self:UpdateChatFont()	
end

function M:UpdateChatFont()

    local size = self.db.fontSize

    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame"..i]

        if frame then
            local font, _, flags = frame:GetFont()
            frame:SetFont(font, size, flags)
        end
    end

    if ChatFrame1EditBox then
        local font, _, flags = ChatFrame1:GetFont()
        ChatFrame1EditBox:SetFont(font, size, flags)
    end

end

--============================================================
-- OPTIONS
--============================================================
local function ChatDisabled()
    return not M.db.enabled
end

M.options = {
    type = "group",
    name = "Chat",
    args = {

        enabled = {
            type = "toggle",
            name = "Enable Chat Enhancements",
            desc = "Enable BasicUI improvements for the default chat system.",
            order = 1,
			width = "full",
            get = function() return M.db.enabled end,
			set = function(_, v)
				M.db.enabled = v
				BasicUI:RequestReload()
			end,
        },

        fullMovement = {
            type = "toggle",
            name = "Allow Full Movement",
            desc = "Allow chat windows to be moved freely anywhere on the screen instead of being restricted to their default positions.",
            order = 2,
			disabled = ChatDisabled,
            get = function() return M.db.fullMovement end,
			set = function(_, v)
				M.db.fullMovement = v
				fullMovement = v
				M:ApplyChatStyle()
			end,
        },
		fontSize = {
			type = "range",
			name = "Chat Font Size",
			desc = "Adjust the font size used in chat windows.",
			min = 8,
			max = 32,
			step = 1,
			order = 3,
			disabled = ChatDisabled,
			get = function() return M.db.fontSize end,
			set = function(_, v)
				M.db.fontSize = v
				M:UpdateChatFont()
			end,
		},		

    },
}

--============================================================
-- REGISTER MODULE
--============================================================
BasicUI:RegisterModule(MODULE_NAME, M)
