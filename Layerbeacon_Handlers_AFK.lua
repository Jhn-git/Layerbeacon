-- Layerbeacon_Handlers_AFK.lua

-- Ensure references
Layerbeacon = Layerbeacon or {}
Layerbeacon.Handlers = Layerbeacon.Handlers or {}

-- 1. Track Party Members
function Layerbeacon.Handlers.TrackPartyMembers()
    local currentTime = GetTime()
    local newPartyMembers = {}

    for i = 1, GetNumGroupMembers() do
        local name, _, _, _, _, _, _, _, _, _, _ = GetRaidRosterInfo(i)
        if name then
            -- Keep existing join time or set current time for new members
            newPartyMembers[name] = Layerbeacon.Handlers.partyMembers[name] or currentTime
        end
    end

    -- Check for players who left
    for playerName in pairs(Layerbeacon.Handlers.partyMembers) do
        if not newPartyMembers[playerName] then
            Layerbeacon.Handlers.DebugPrintf("Player %s left. Removing from tracking.", playerName)
            Layerbeacon.Handlers.leftPartyList[playerName] = currentTime
        end
    end

    Layerbeacon.Handlers.partyMembers = newPartyMembers
end

-- 2. Auto-Kick on New Player Join
function Layerbeacon.Handlers.AutoKickOnNewPlayer()
    local currentTime = GetTime()
    local afkTimeout = Layerbeacon.Config.AFK_TIMEOUT

    for playerName, joinTime in pairs(Layerbeacon.Handlers.partyMembers) do
        if (currentTime - joinTime) > afkTimeout then
            -- Check for AFK player
            Layerbeacon.Handlers.DebugPrintf("Player %s is AFK for too long. Kicking...", playerName)
            Layerbeacon.Handlers.KickPlayer(playerName)
            return -- Kick one player per event to avoid excessive disruption
        end
    end
end

-- 3. Kick Player Securely
function Layerbeacon.Handlers.KickPlayer(playerName)
    if not playerName or playerName == "" then
        Layerbeacon.Handlers.DebugPrintf("Invalid player name.")
        return
    end

    if not UnitIsGroupLeader("player") then
        Layerbeacon.Handlers.DebugPrintf("Cannot kick %s: You are not the group leader.", playerName)
        return
    end

    if InCombatLockdown() then
        Layerbeacon.Handlers.DebugPrintf("Cannot kick %s: Combat lockdown active.", playerName)
        return
    end

    -- Use a secure button to kick the player
    if not kickButton then
        -- Create a secure button if needed
        kickButton = CreateFrame("Button", "LayerbeaconSecureKickButton", UIParent, "SecureActionButtonTemplate")
        kickButton:SetAttribute("type", "macro")
    end

    kickButton:SetAttribute("macrotext", "/uninvite " .. playerName)
    kickButton:Click()

    -- Remove player from tracking
    Layerbeacon.Handlers.partyMembers[playerName] = nil
    Layerbeacon.Handlers.leftPartyList[playerName] = GetTime()
    Layerbeacon.Handlers.DebugPrintf("Kicked player %s for being AFK.", playerName)
end
