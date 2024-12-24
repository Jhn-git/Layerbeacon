-- Layerbounce_Handlers_Core.lua
Layerbounce = Layerbounce or {}
Layerbounce.Handlers = Layerbounce.Handlers or {}

-------------------------------------------------------------------------------
-- State Variables
-------------------------------------------------------------------------------
Layerbounce.Handlers.priorityQueue        = {} -- for "layer X" where X == current layer
Layerbounce.Handlers.normalQueue          = {} -- for generic "layer" requests

Layerbounce.Handlers.ignoreList           = {}
Layerbounce.Handlers.layerText            = nil
Layerbounce.Handlers.partyMembers         = {} -- Tracks join times (for AFK)
Layerbounce.Handlers.leftPartyList        = {} -- We'll store a timestamp when they left
Layerbounce.Handlers.declinedInviteList   = {} -- We'll store a timestamp when they declined
Layerbounce.Handlers.lastNotificationTime = 0

-------------------------------------------------------------------------------
-- Utility: DebugPrintf
-------------------------------------------------------------------------------
function Layerbounce.Handlers.DebugPrintf(...)
    local status, res = pcall(string.format, ...)
    if status and DLAPI then
        DLAPI.DebugLog("Layerbounce", res)
    end
end

-------------------------------------------------------------------------------
-- Utility: UpdateButtonPosition
-------------------------------------------------------------------------------
function Layerbounce.Handlers.UpdateButtonPosition(button, angle, radius)
    local radians = math.rad(angle)
    local xOffset = math.cos(radians) * radius
    local yOffset = math.sin(radians) * radius
    button:SetPoint("CENTER", Minimap, "CENTER", xOffset, yOffset)
end

-------------------------------------------------------------------------------
-- Utility: ExtractLayerText
-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
-- Utility: IsPlayerInOurGroup
-------------------------------------------------------------------------------
function Layerbounce.Handlers.IsPlayerInOurGroup(playerName)
    if IsInRaid(LE_PARTY_CATEGORY_HOME) then
        for i = 1, GetNumGroupMembers() do
            local name = GetRaidRosterInfo(i)  -- works in a raid
            if name == playerName then
                return true
            end
        end
    elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
        if UnitExists("player") and GetUnitName("player", true) == playerName then
            return true
        end
        for i = 1, 4 do
            local unitID = "party"..i
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

-------------------------------------------------------------------------------
-- Utility: WaitForPlayerToJoin
-------------------------------------------------------------------------------
function Layerbounce.Handlers.WaitForPlayerToJoin(playerName, retries)
    retries = retries or 0
    if retries > 10 then
        Layerbounce.Handlers.DebugPrintf("Player %s did not join after 10s, giving up.", playerName)
        return
    end

    if Layerbounce.Handlers.IsPlayerInOurGroup(playerName) then
        if Layerbounce.Handlers.ExtractLayerText() then
            Layerbounce.Handlers.DebugPrintf("Announcing layer %s to party.", Layerbounce.Handlers.layerText)
            Layerbounce.Handlers.lastNotificationTime = GetTime()
            SendChatMessage("layer " .. Layerbounce.Handlers.layerText, "PARTY")
        end
    else
        C_Timer.After(1, function()
            Layerbounce.Handlers.WaitForPlayerToJoin(playerName, retries + 1)
        end)
    end
end

-------------------------------------------------------------------------------
-- Utility: CheckLayerPriority
-------------------------------------------------------------------------------
function Layerbounce.Handlers.CheckLayerPriority(msg, currentLayer)
    local lowerMsg = string.lower(msg or "")
    if not string.find(lowerMsg, "layer") then
        return nil
    end

    local layersMentioned = string.match(lowerMsg, "layer%s+([%d,]+)")
    if layersMentioned then
        for numberString in string.gmatch(layersMentioned, "%d+") do
            local num = tonumber(numberString)
            if num and tostring(num) == tostring(currentLayer) then
                return "priority"
            end
        end
    end

    return "normal"
end
