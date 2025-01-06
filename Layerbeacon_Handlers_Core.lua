local addonName, _ = ...

-- Ensure global table references
Layerbeacon = Layerbeacon or {}
Layerbeacon.Handlers = Layerbeacon.Handlers or {}

-------------------------------------------------------------------------------
-- Debug function
-------------------------------------------------------------------------------
function Layerbeacon.Handlers.DebugPrintf(...)
    -- Attempt string.format to create the debug message
    local status, message = pcall(string.format, ...)
    if not status then
        local name = Layerbeacon.addonName or "Layerbeacon"
        print(string.format("[%s] DebugPrintf error: %s", name, message))
        return
    end

    -- If "DebugLog" add-on API is available, always log the message
    if DLAPI then
        DLAPI.DebugLog(Layerbeacon.addonName or "Layerbeacon", message)
    end

    -- Skip further processing if debug mode is disabled
    if not Layerbeacon.Config.DEBUG_ENABLED then
        return
    end

    -- Fallback to a simple print statement if debug mode is enabled
    local name = Layerbeacon.addonName or "Layerbeacon"
    print(string.format("[%s] %s", name, message))
end


-------------------------------------------------------------------------------
-- State Variables
-------------------------------------------------------------------------------
Layerbeacon.Handlers.layerText            = nil
Layerbeacon.Handlers.partyMembers         = {} -- Tracks join times (for AFK)
Layerbeacon.Handlers.leftPartyList        = {} -- We'll store a timestamp when they left
Layerbeacon.Handlers.declinedInviteList   = {} -- We'll store a timestamp when they declined
Layerbeacon.Handlers.lastNotificationTime = 0

-------------------------------------------------------------------------------
-- Utility: ExtractLayerText (from Nova World Buffs or any relevant source)
-------------------------------------------------------------------------------
function Layerbeacon.Handlers.ExtractLayerText()
    Layerbeacon.Handlers.DebugPrintf("Attempting to extract layer text...")
    if _G["MinimapLayerFrame"] and _G["MinimapLayerFrame"].fs then
        local rawLayerText = _G["MinimapLayerFrame"].fs:GetText()
        if rawLayerText and rawLayerText ~= "No Layer" then
            local extractedNumber = string.match(rawLayerText, "%d+")
            if extractedNumber then
                Layerbeacon.Handlers.DebugPrintf("Extracted layer number: %s", extractedNumber)
                Layerbeacon.Handlers.layerText = extractedNumber
                return true
            end
        end
    end
    Layerbeacon.Handlers.DebugPrintf("Failed to extract layer text.")
    return false
end

-------------------------------------------------------------------------------
-- Utility: IsPlayerInOurGroup
-------------------------------------------------------------------------------
function Layerbeacon.Handlers.IsPlayerInOurGroup(playerName)
    local function checkGroupUnits(unitPrefix, maxUnits)
        for i = 1, maxUnits do
            local unitID = unitPrefix .. i
            if UnitExists(unitID) and GetUnitName(unitID, true) == playerName then
                return true
            end
        end
        return false
    end

    if IsInRaid(LE_PARTY_CATEGORY_HOME) then
        return checkGroupUnits("raid", GetNumGroupMembers())
    elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
        -- We also check if the "player" unit is the same name
        if UnitExists("player") and GetUnitName("player", true) == playerName then
            return true
        end
        return checkGroupUnits("party", 4)
    end

    return false
end

-------------------------------------------------------------------------------
-- Utility: WaitForPlayerToJoin
-------------------------------------------------------------------------------
function Layerbeacon.Handlers.WaitForPlayerToJoin(playerName, retries)
    retries = retries or 0
    if retries > 10 then
        Layerbeacon.Handlers.DebugPrintf("Player %s did not join after 10s, giving up.", playerName)
        return
    end

    if Layerbeacon.Handlers.IsPlayerInOurGroup(playerName) then
        if Layerbeacon.Handlers.ExtractLayerText() then
            Layerbeacon.Handlers.DebugPrintf("Announcing layer %s to party.", Layerbeacon.Handlers.layerText)
            Layerbeacon.Handlers.lastNotificationTime = GetTime()
            SendChatMessage("[Layerbeacon] layer " .. Layerbeacon.Handlers.layerText, "PARTY")
        end
    else
        C_Timer.After(1, function()
            Layerbeacon.Handlers.WaitForPlayerToJoin(playerName, retries + 1)
        end)
    end
end

-------------------------------------------------------------------------------
-- Utility: Check Layer Message
-------------------------------------------------------------------------------
function Layerbeacon.Handlers.CheckIfValidLayerMessage(msg)
    if not msg then
        return false
    end

    -- Match "layer" as a standalone word
    local found = msg:find("%f[%a]layer%f[%A]")
    if found then
        Layerbeacon.Handlers.DebugPrintf("CheckIfValidLayerMessage: Valid message containing 'layer': '%s'", msg)
        return true
    end

    return false
end

-------------------------------------------------------------------------------
-- Initialization Stub
-------------------------------------------------------------------------------
function Layerbeacon.Handlers.Initialize()
    -- Any one-time logic for your “core” Handlers can go here.
    -- E.g. setting up any tables, hooking certain functions, etc.
    Layerbeacon.Handlers.DebugPrintf("Layerbeacon.Handlers.Initialize called.")
end
