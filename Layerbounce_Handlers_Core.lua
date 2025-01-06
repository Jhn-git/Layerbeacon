local addonName, _ = ...

-- Ensure global table references
Layerbounce = Layerbounce or {}
Layerbounce.Handlers = Layerbounce.Handlers or {}

-------------------------------------------------------------------------------
-- Debug function
-------------------------------------------------------------------------------
function Layerbounce.Handlers.DebugPrintf(...)
    -- Attempt string.format to create the debug message
    local status, message = pcall(string.format, ...)
    if not status then
        local name = Layerbounce.addonName or "Layerbounce"
        print(string.format("[%s] DebugPrintf error: %s", name, message))
        return
    end

    -- If "DebugLog" add-on API is available, always log the message
    if DLAPI then
        DLAPI.DebugLog(Layerbounce.addonName or "Layerbounce", message)
    end

    -- Skip further processing if debug mode is disabled
    if not Layerbounce.Config.DEBUG_ENABLED then
        return
    end

    -- Fallback to a simple print statement if debug mode is enabled
    local name = Layerbounce.addonName or "Layerbounce"
    print(string.format("[%s] %s", name, message))
end


-------------------------------------------------------------------------------
-- State Variables
-------------------------------------------------------------------------------
Layerbounce.Handlers.layerText            = nil
Layerbounce.Handlers.partyMembers         = {} -- Tracks join times (for AFK)
Layerbounce.Handlers.leftPartyList        = {} -- We'll store a timestamp when they left
Layerbounce.Handlers.declinedInviteList   = {} -- We'll store a timestamp when they declined
Layerbounce.Handlers.lastNotificationTime = 0

-------------------------------------------------------------------------------
-- Utility: ExtractLayerText (from Nova World Buffs or any relevant source)
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
    return false
end

-------------------------------------------------------------------------------
-- Utility: IsPlayerInOurGroup
-------------------------------------------------------------------------------
function Layerbounce.Handlers.IsPlayerInOurGroup(playerName)
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
            SendChatMessage("[Layerbounce] layer " .. Layerbounce.Handlers.layerText, "PARTY")
        end
    else
        C_Timer.After(1, function()
            Layerbounce.Handlers.WaitForPlayerToJoin(playerName, retries + 1)
        end)
    end
end

-------------------------------------------------------------------------------
-- Utility: Check Layer Message
-------------------------------------------------------------------------------
function Layerbounce.Handlers.CheckIfValidLayerMessage(msg)
    if not msg then
        return false
    end

    -- Match "layer" as a standalone word
    local found = msg:find("%f[%a]layer%f[%A]")
    if found then
        Layerbounce.Handlers.DebugPrintf("CheckIfValidLayerMessage: Valid message containing 'layer': '%s'", msg)
        return true
    end

    return false
end

-------------------------------------------------------------------------------
-- Initialization Stub
-------------------------------------------------------------------------------
function Layerbounce.Handlers.Initialize()
    -- Any one-time logic for your “core” Handlers can go here.
    -- E.g. setting up any tables, hooking certain functions, etc.
    Layerbounce.Handlers.DebugPrintf("Layerbounce.Handlers.Initialize called.")
end
