-- Layerbeacon_Handlers_Invite.lua

-- Ensure references
Layerbeacon = Layerbeacon or {}
Layerbeacon.Handlers = Layerbeacon.Handlers or {}

--------------------------------------------------------------------------------
-- InviteAndNotify
--------------------------------------------------------------------------------
function Layerbeacon.Handlers.InviteAndNotify(sender)
    Layerbeacon.Handlers.DebugPrintf("InviteAndNotify called for sender: %s", sender)

    -- Skip if the addon is disabled
    if not _G.LayerbeaconSavedVariables.isAddonActive then
        Layerbeacon.Handlers.DebugPrintf("Addon is inactive. Skipping invite for %s.", sender)
        return
    end

    -- Skip if the sender is on cooldown for leaving or declining
    if Layerbeacon.Handlers.IsOnLeaveOrDeclineCooldown(sender) then
        Layerbeacon.Handlers.DebugPrintf("%s is on cooldown. Skipping invite.", sender)
        return
    end

    -- Skip if the party is full
    if IsInGroup(LE_PARTY_CATEGORY_HOME) and GetNumGroupMembers() >= 5 then
        Layerbeacon.Handlers.DebugPrintf("Party is full. Cannot invite %s.", sender)
        return
    end

    -- Invite the player
    local playerName = string.match(sender, "([^%-]+)") or sender -- Extract just the name if realm is included
    Layerbeacon.Handlers.DebugPrintf("Inviting %s now...", playerName)
    C_PartyInfo.InviteUnit(playerName)

    -- Send a whisper with layer information
    local layerMessage = "[Layerbeacon] Layer " .. (Layerbeacon.Handlers.layerText or "Unknown") .. ". Invite sent."
    SendChatMessage(layerMessage, "WHISPER", nil, playerName)
    Layerbeacon.Handlers.DebugPrintf("Sent whisper to %s: %s", playerName, layerMessage)

    -- Temporarily add the player to a pending invite list
    Layerbeacon.Handlers.pendingInviteList = Layerbeacon.Handlers.pendingInviteList or {}
    Layerbeacon.Handlers.pendingInviteList[playerName] = GetTime()
end

--------------------------------------------------------------------------------
-- Handle System Messages
--------------------------------------------------------------------------------
function Layerbeacon.Handlers.HandleSystemMessage(sysMsg)
    -- Check if the message indicates a player joined the party
    local joinedPlayer = string.match(sysMsg, "^(.*) joins the party")
    if joinedPlayer then
        Layerbeacon.Handlers.DebugPrintf("Player %s joined the party.", joinedPlayer)

        -- Move the player from pending to active tracking
        if Layerbeacon.Handlers.pendingInviteList and Layerbeacon.Handlers.pendingInviteList[joinedPlayer] then
            local joinTime = Layerbeacon.Handlers.pendingInviteList[joinedPlayer]
            Layerbeacon.Handlers.partyMembers[joinedPlayer] = joinTime
            Layerbeacon.Handlers.pendingInviteList[joinedPlayer] = nil
            Layerbeacon.Handlers.DebugPrintf("Added %s to partyMembers tracking.", joinedPlayer)
        end
        return
    end

    -- Check if the message indicates a declined invite
    local declinedPlayer = string.match(sysMsg, "^(.*) declines your group invitation")
    if declinedPlayer then
        Layerbeacon.Handlers.DebugPrintf("Detected a declined invite from: %s.", declinedPlayer)
        Layerbeacon.Handlers.HandleDeclinedInvite(declinedPlayer)
        return
    end

    -- Log unhandled system messages for debugging
    Layerbeacon.Handlers.DebugPrintf("Unhandled system message: %s", sysMsg)
end

--------------------------------------------------------------------------------
-- HandleDeclinedInvite
--------------------------------------------------------------------------------
function Layerbeacon.Handlers.HandleDeclinedInvite(sender)
    local currentTime = GetTime()
    local cooldown = Layerbeacon.Config.LEAVE_DECLINE_COOLDOWN or 1200

    -- Add the sender to the declined invite list
    Layerbeacon.Handlers.declinedInviteList[sender] = currentTime
    Layerbeacon.Handlers.DebugPrintf("Player %s declined the invite. Added to cooldown.", sender)

    -- Remove the player from pending tracking
    if Layerbeacon.Handlers.pendingInviteList and Layerbeacon.Handlers.pendingInviteList[sender] then
        Layerbeacon.Handlers.pendingInviteList[sender] = nil
        Layerbeacon.Handlers.DebugPrintf("Removed %s from pendingInviteList.", sender)
    end
end

--------------------------------------------------------------------------------
-- Check Cooldowns for Leaving or Declining
--------------------------------------------------------------------------------
function Layerbeacon.Handlers.IsOnLeaveOrDeclineCooldown(sender)
    local currentTime = GetTime() -- Use GetTime() for session-relative checks
    local cooldown = Layerbeacon.Config.LEAVE_DECLINE_COOLDOWN or 1200

    -- Check leave cooldown
    local leftTimestamp = Layerbeacon.Handlers.leftPartyList[sender]
    if leftTimestamp and (currentTime - leftTimestamp) < cooldown then
        local remaining = cooldown - (currentTime - leftTimestamp)
        Layerbeacon.Handlers.DebugPrintf("Player %s is on leave cooldown. Remaining: %.1f seconds.", sender, remaining)
        return true
    end

    -- Check decline cooldown
    local declinedTimestamp = Layerbeacon.Handlers.declinedInviteList[sender]
    if declinedTimestamp and (currentTime - declinedTimestamp) < cooldown then
        local remaining = cooldown - (currentTime - declinedTimestamp)
        Layerbeacon.Handlers.DebugPrintf("Player %s is on decline cooldown. Remaining: %.1f seconds.", sender, remaining)
        return true
    end

    Layerbeacon.Handlers.DebugPrintf("Player %s is not on cooldown. They can join now.", sender)
    return false
end
