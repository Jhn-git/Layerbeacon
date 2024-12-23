-- Constants for button placement
local defaultAngle = 90 -- 90 degrees for the far right of the minimap
local radius = 80 -- Distance from the minimap's center (adjust as needed)
local afkTimeout = 120 -- AFK timeout in seconds

-- Variables for addon state
local ignoreList = {}
local layerText = nil
local partyQueue = {}
local partyMembers = {} -- Tracks join times for AFK kicks
local leftPartyList = {} -- Tracks players who left the party or declined invites
local declinedInviteList = {} -- Tracks players who declined invites

-- Function to update the button position based on angle
local function UpdateButtonPosition(button, angle)
    local radians = math.rad(angle)
    local xOffset = math.cos(radians) * radius
    local yOffset = math.sin(radians) * radius
    button:SetPoint("CENTER", Minimap, "CENTER", xOffset, yOffset)
end

-- Define the addon name and frame
local addonName = ...
local LayerbounceAddon = CreateFrame("Frame", "LayerbounceAddonFrame")

-- Define saved variables globally (use this name exactly as in the TOC file)
_G.LayerbounceSavedVariables = _G.LayerbounceSavedVariables or {}

-- Set defaults
local defaults = {
    firstTimeShown = true,
    isAddonActive = true
}

-- Function to initialize saved variables
local function InitializeSavedVariables()
    if type(_G.LayerbounceSavedVariables) ~= "table" then
        _G.LayerbounceSavedVariables = {}
    end

    for key, value in pairs(defaults) do
        if _G.LayerbounceSavedVariables[key] == nil or type(_G.LayerbounceSavedVariables[key]) ~= type(value) then
            _G.LayerbounceSavedVariables[key] = value
        end
    end
end

-- Register the ADDON_LOADED event
LayerbounceAddon:RegisterEvent("ADDON_LOADED")

-- Event handler function
LayerbounceAddon:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        InitializeSavedVariables()

        local minimapButton = CreateFrame("Button", "LayerbounceMinimapButton", Minimap)
        minimapButton:SetSize(32, 32)
        minimapButton:SetFrameStrata("MEDIUM")
        minimapButton:SetFrameLevel(8)
        minimapButton:SetHighlightTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight")
        minimapButton:SetNormalTexture("Interface/AddOns/Layerbounce/GreenButton.tga")
        minimapButton:SetPushedTexture("Interface/AddOns/Layerbounce/GreenButton.tga")

        UpdateButtonPosition(minimapButton, defaultAngle)

        minimapButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText("Layerbounce")
            GameTooltip:Show()
        end)
        minimapButton:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        minimapButton:SetMovable(true)
        minimapButton:EnableMouse(true)
        minimapButton:RegisterForDrag("LeftButton")
        minimapButton:SetScript("OnDragStart", function(self) self:StartMoving() end)
        minimapButton:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

        if not _G.LayerbounceSavedVariables.isAddonActive then
            minimapButton:SetNormalTexture("Interface/AddOns/Layerbounce/RedButton.tga")
        end

        minimapButton:SetScript("OnClick", function(self)
            _G.LayerbounceSavedVariables.isAddonActive = not _G.LayerbounceSavedVariables.isAddonActive
            if _G.LayerbounceSavedVariables.isAddonActive then
                minimapButton:SetNormalTexture("Interface/AddOns/Layerbounce/GreenButton.tga")
            else
                minimapButton:SetNormalTexture("Interface/AddOns/Layerbounce/RedButton.tga")
            end
        end)
    end
end)

-- Function to handle layer extraction
local function ExtractLayerText()
    if _G["MinimapLayerFrame"] and _G["MinimapLayerFrame"].fs then
        local rawLayerText = _G["MinimapLayerFrame"].fs:GetText()
        if rawLayerText and rawLayerText ~= "No Layer" then
            local extractedNumber = string.match(rawLayerText, "%d+")
            if extractedNumber then
                layerText = extractedNumber
                return true
            end
        end
    end
    layerText = nil
    return false
end

-- Function to handle automatic invites and notify layer
local function InviteAndNotify(sender)
    if not _G.LayerbounceSavedVariables.isAddonActive then return end

    -- Check if the player has left previously or declined an invite
    if leftPartyList[sender] or declinedInviteList[sender] then
        SendChatMessage("You were previously removed or declined an invite. Please wait before requesting again.", "WHISPER", nil, sender)
        return
    end

    if ExtractLayerText() then
        if IsInGroup(LE_PARTY_CATEGORY_HOME) and GetNumGroupMembers() >= 5 then
            SendChatMessage(
                "Party is full. Please wait for space to become available.",
                "WHISPER", nil, sender
            )
            table.insert(partyQueue, sender)
        else
            local playerName = string.match(sender, "([^%-]+)") -- Strip realm name
            C_PartyInfo.InviteUnit(playerName)
            partyMembers[playerName] = GetTime() -- Track join time

            -- Wait until the player joins the party to announce the layer number
            local function WaitForPlayerToJoin()
                if IsInGroup(LE_PARTY_CATEGORY_HOME) then
                    for i = 1, GetNumGroupMembers() do
                        local memberName = GetRaidRosterInfo(i)
                        if memberName == playerName then
                            if ExtractLayerText() then
                                SendChatMessage("layer " .. layerText, "PARTY")
                            end
                            return
                        end
                    end
                end
                -- Retry after a short delay if the player hasn't joined yet
                C_Timer.After(1, WaitForPlayerToJoin)
            end

            WaitForPlayerToJoin()
        end
    end
end

-- Function to check and kick AFK players
local function CheckAFKAndKick()
    for playerName, joinTime in pairs(partyMembers) do
        if not UnitInParty(playerName) then
            -- Player has already left the party, clean up the tracking
            partyMembers[playerName] = nil
            leftPartyList[playerName] = true -- Mark the player as having left
        elseif GetTime() - joinTime > afkTimeout then
            -- Player is still in the party but has been AFK too long
            UninviteUnit(playerName)
            partyMembers[playerName] = nil -- Remove from tracking
            leftPartyList[playerName] = true -- Mark the player as having left
            SendChatMessage(playerName .. " has been removed from the party for being AFK.", "PARTY")
        end
    end
end

-- Function to handle declined invites
local function HandleDeclinedInvite(sender)
    declinedInviteList[sender] = true -- Mark the player as having declined an invite
    SendChatMessage("Your invite was declined. Please wait before requesting again.", "WHISPER", nil, sender)
end

-- Timer to periodically check for AFK players
C_Timer.NewTicker(10, function()
    if _G.LayerbounceSavedVariables.isAddonActive then
        CheckAFKAndKick()
    end
end)

-- Create a frame for event handling
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_CHANNEL")
frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")

-- Event handler for chat messages
frame:SetScript("OnEvent", function(self, event, ...)
    if not _G.LayerbounceSavedVariables.isAddonActive then return end

    if event == "CHAT_MSG_CHANNEL" then
        local msg, sender = ...
        if string.find(string.lower(msg), "layer") and ExtractLayerText() and not ignoreList[sender] then
            InviteAndNotify(sender)
            ignoreList[sender] = true
        end
    elseif event == "GROUP_INVITE_DECLINED" then
        local sender = ...
        HandleDeclinedInvite(sender)
    end
end)
