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


--------------------------------------------------------------------------------
-- Utility: Get Current Party Members
--------------------------------------------------------------------------------
function Layerbeacon.Handlers.GetCurrentPartyMembers()
    local members = {}
    for i = 1, GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) do
        local name = GetRaidRosterInfo(i)
        if name then
            members[name] = true
        end
    end
    return members
end



-------------------------------------------------------------------------------
-- Initialization Stub
-------------------------------------------------------------------------------
function Layerbeacon.Handlers.Initialize()
    if not kickButton then
        kickButton = CreateFrame("Button", "LayerbeaconSecureKickButton", UIParent, "SecureActionButtonTemplate")
        kickButton:SetAttribute("type", "macro")
    end
    Layerbeacon.Handlers.DebugPrintf("Layerbeacon.Handlers.Initialize called.")
end
