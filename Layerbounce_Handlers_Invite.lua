-- Layerbounce_Handlers_Invite.lua

-- Ensure references
Layerbounce = Layerbounce or {}
Layerbounce.Handlers = Layerbounce.Handlers or {}

--------------------------------------------------------------------------------
-- InviteAndNotify
--------------------------------------------------------------------------------
function Layerbounce.Handlers.InviteAndNotify(sender)
    Layerbounce.Handlers.DebugPrintf("InviteAndNotify called for sender: %s", sender)

    -- Skip if the addon is disabled
    if not _G.LayerbounceSavedVariables.isAddonActive then
        Layerbounce.Handlers.DebugPrintf("Addon is inactive. Skipping invite for %s.", sender)
        return
    end

    -- Skip if the sender is on cooldown for leaving or declining
    if Layerbounce.Handlers.IsOnLeaveOrDeclineCooldown(sender) then
        Layerbounce.Handlers.DebugPrintf("%s is on cooldown. Skipping invite.", sender)
        return
    end

    -- Skip if the party is full
    if IsInGroup(LE_PARTY_CATEGORY_HOME) and GetNumGroupMembers() >= 5 then
        Layerbounce.Handlers.DebugPrintf("Party is full. Cannot invite %s.", sender)
        return
    end

    -- Invite the player
    local playerName = string.match(sender, "([^%-]+)") or sender -- Extract just the name if realm is included
    Layerbounce.Handlers.DebugPrintf("Inviting %s now...", playerName)
    C_PartyInfo.InviteUnit(playerName)

    -- Send a whisper with layer information
    local layerMessage = "[Layerbounce] Layer " .. (Layerbounce.Handlers.layerText or "Unknown") .. ". Invite sent."
    SendChatMessage(layerMessage, "WHISPER", nil, playerName)
    Layerbounce.Handlers.DebugPrintf("Sent whisper to %s: %s", playerName, layerMessage)

    -- Temporarily add the player to a pending invite list
    Layerbounce.Handlers.pendingInviteList = Layerbounce.Handlers.pendingInviteList or {}
    Layerbounce.Handlers.pendingInviteList[playerName] = GetTime()
end

--------------------------------------------------------------------------------
-- Handle System Messages
--------------------------------------------------------------------------------
function Layerbounce.Handlers.HandleSystemMessage(sysMsg)
    -- Check if the message indicates a player joined the party
    local joinedPlayer = string.match(sysMsg, "^(.*) joins the party")
    if joinedPlayer then
        Layerbounce.Handlers.DebugPrintf("Player %s joined the party.", joinedPlayer)

        -- Move the player from pending to active tracking
        if Layerbounce.Handlers.pendingInviteList and Layerbounce.Handlers.pendingInviteList[joinedPlayer] then
            local joinTime = Layerbounce.Handlers.pendingInviteList[joinedPlayer]
            Layerbounce.Handlers.partyMembers[joinedPlayer] = joinTime
            Layerbounce.Handlers.pendingInviteList[joinedPlayer] = nil
            Layerbounce.Handlers.DebugPrintf("Added %s to partyMembers tracking.", joinedPlayer)
        end
        return
    end

    -- Check if the message indicates a declined invite
    local declinedPlayer = string.match(sysMsg, "^(.*) declines your group invitation")
    if declinedPlayer then
        Layerbounce.Handlers.DebugPrintf("Detected a declined invite from: %s.", declinedPlayer)
        Layerbounce.Handlers.HandleDeclinedInvite(declinedPlayer)
        return
    end

    -- Log unhandled system messages for debugging
    Layerbounce.Handlers.DebugPrintf("Unhandled system message: %s", sysMsg)
end

--------------------------------------------------------------------------------
-- HandleDeclinedInvite
--------------------------------------------------------------------------------
function Layerbounce.Handlers.HandleDeclinedInvite(sender)
    local currentTime = GetTime()
    local cooldown = Layerbounce.Config.LEAVE_DECLINE_COOLDOWN or 1200

    -- Add the sender to the declined invite list
    Layerbounce.Handlers.declinedInviteList[sender] = currentTime
    Layerbounce.Handlers.DebugPrintf("Player %s declined the invite. Added to cooldown.", sender)

    -- Remove the player from pending tracking
    if Layerbounce.Handlers.pendingInviteList and Layerbounce.Handlers.pendingInviteList[sender] then
        Layerbounce.Handlers.pendingInviteList[sender] = nil
        Layerbounce.Handlers.DebugPrintf("Removed %s from pendingInviteList.", sender)
    end
end

--------------------------------------------------------------------------------
-- Check Cooldowns for Leaving or Declining
--------------------------------------------------------------------------------
function Layerbounce.Handlers.IsOnLeaveOrDeclineCooldown(sender)
    local currentTime = GetTime() -- Use GetTime() for session-relative checks
    local cooldown = Layerbounce.Config.LEAVE_DECLINE_COOLDOWN or 1200

    -- Check leave cooldown
    local leftTimestamp = Layerbounce.Handlers.leftPartyList[sender]
    if leftTimestamp and (currentTime - leftTimestamp) < cooldown then
        local remaining = cooldown - (currentTime - leftTimestamp)
        Layerbounce.Handlers.DebugPrintf("Player %s is on leave cooldown. Remaining: %.1f seconds.", sender, remaining)
        return true
    end

    -- Check decline cooldown
    local declinedTimestamp = Layerbounce.Handlers.declinedInviteList[sender]
    if declinedTimestamp and (currentTime - declinedTimestamp) < cooldown then
        local remaining = cooldown - (currentTime - declinedTimestamp)
        Layerbounce.Handlers.DebugPrintf("Player %s is on decline cooldown. Remaining: %.1f seconds.", sender, remaining)
        return true
    end

    Layerbounce.Handlers.DebugPrintf("Player %s is not on cooldown. They can join now.", sender)
    return false
end
