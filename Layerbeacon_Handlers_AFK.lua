-- Layerbeacon_Handlers_AFK.lua

-- Ensure references
Layerbeacon = Layerbeacon or {}
Layerbeacon.Handlers = Layerbeacon.Handlers or {}

-- 1. Track Party Members
function Layerbeacon.Handlers.TrackPartyMembers()
    local currentTime = GetTime()

    -- Get current party members
    local currentParty = Layerbeacon.Handlers.GetCurrentPartyMembers()

    -- Update join times
    local updatedParty = Layerbeacon.Handlers.UpdateJoinTimes(
        Layerbeacon.Handlers.partyMembers,
        currentParty,
        currentTime
    )

    -- Detect players who left
    local playersWhoLeft = Layerbeacon.Handlers.GetPlayersWhoLeft(
        Layerbeacon.Handlers.partyMembers,
        updatedParty
    )

    for _, playerName in ipairs(playersWhoLeft) do
        Layerbeacon.Handlers.DebugPrintf("Player %s left. Removing from tracking.", playerName)
        Layerbeacon.Handlers.leftPartyList[playerName] = currentTime
    end

    -- Update the party members list
    Layerbeacon.Handlers.partyMembers = updatedParty
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

    kickButton:SetAttribute("macrotext", "/uninvite " .. playerName)
    kickButton:Click()

    -- Remove player from tracking
    Layerbeacon.Handlers.partyMembers[playerName] = nil
    Layerbeacon.Handlers.leftPartyList[playerName] = GetTime()
    Layerbeacon.Handlers.DebugPrintf("Kicked player %s for being AFK.", playerName)
end
