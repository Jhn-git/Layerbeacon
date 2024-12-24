-- Layerbounce_Handlers_Core.lua
Layerbounce = Layerbounce or {}
Layerbounce.Handlers = Layerbounce.Handlers or {}

-- ---------------------------------------------------------------------------
-- State variables
-- ---------------------------------------------------------------------------
Layerbounce.Handlers.ignoreList           = {}
Layerbounce.Handlers.layerText            = nil
Layerbounce.Handlers.partyQueue           = {}
Layerbounce.Handlers.partyMembers         = {}
Layerbounce.Handlers.leftPartyList        = {}
Layerbounce.Handlers.declinedInviteList   = {}
Layerbounce.Handlers.lastNotificationTime = 0

-- ---------------------------------------------------------------------------
-- Utility: DebugPrintf
-- ---------------------------------------------------------------------------
function Layerbounce.Handlers.DebugPrintf(...)
    local status, res = pcall(string.format, ...)
    if status and DLAPI then
        DLAPI.DebugLog("Layerbounce", res)
    end
end

-- ---------------------------------------------------------------------------
-- Utility: UpdateButtonPosition
-- ---------------------------------------------------------------------------
function Layerbounce.Handlers.UpdateButtonPosition(button, angle, radius)
    local radians = math.rad(angle)
    local xOffset = math.cos(radians) * radius
    local yOffset = math.sin(radians) * radius
    button:SetPoint("CENTER", Minimap, "CENTER", xOffset, yOffset)
end

-- ---------------------------------------------------------------------------
-- Utility: ExtractLayerText
--   Attempts to read from MinimapLayerFrame.fs if it exists
-- ---------------------------------------------------------------------------
function Layerbounce.Handlers.ExtractLayerText()
    Layerbounce.Handlers.DebugPrintf("Attempting to extract layer text...")
    if _G["MinimapLayerFrame"] and _G["MinimapLayerFrame"].fs then
        local rawLayerText = _G["MinimapLayerFrame"].fs:GetText()
        if rawLayerText and rawLayerText ~= "No Layer" then
            local extractedNumber = string.match(rawLayerText, "%d+")
            if extractedNumber then
                Layerbounce.Handlers.DebugPrintf("Extracted layer number: %s", extractedNumber)
                Layerbounce.Handlers.layerText = extractedNumber
                return true
            end
        end
    end
    Layerbounce.Handlers.DebugPrintf("Failed to extract layer text.")
    Layerbounce.Handlers.layerText = nil
    return false
end

-- ---------------------------------------------------------------------------
-- Utility: IsPlayerInOurGroup
--   Checks if player is in group (party or raid)
-- ---------------------------------------------------------------------------
function Layerbounce.Handlers.IsPlayerInOurGroup(playerName)
    if IsInRaid(LE_PARTY_CATEGORY_HOME) then
        for i = 1, GetNumGroupMembers() do
            local name = GetRaidRosterInfo(i)  -- works in raid
            if name == playerName then
                return true
            end
        end
    elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
        -- "player" = yourself; "party1".."party4" = the rest
        if UnitExists("player") and GetUnitName("player", true) == playerName then
            return true
        end
        for i = 1, 4 do
            local unitID = "party" .. i
            if UnitExists(unitID) then
                local name = GetUnitName(unitID, true)
                if name == playerName then
                    return true
                end
            end
        end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Utility: WaitForPlayerToJoin
--   Checks every second (up to 10s) if player joined group
-- ---------------------------------------------------------------------------
function Layerbounce.Handlers.WaitForPlayerToJoin(playerName, retries)
    retries = retries or 0
    if retries > 10 then
        Layerbounce.Handlers.DebugPrintf("Player %s did not join after 10 seconds, giving up.", playerName)
        return
    end

    if Layerbounce.Handlers.IsPlayerInOurGroup(playerName) then
        if Layerbounce.Handlers.ExtractLayerText() then
            Layerbounce.Handlers.DebugPrintf("Announcing layer %s to party.", Layerbounce.Handlers.layerText)
            Layerbounce.Handlers.lastNotificationTime = GetTime() -- Update cooldown
            SendChatMessage("layer " .. Layerbounce.Handlers.layerText, "PARTY")
        end
    else
        C_Timer.After(1, function()
            Layerbounce.Handlers.WaitForPlayerToJoin(playerName, retries + 1)
        end)
    end
end
