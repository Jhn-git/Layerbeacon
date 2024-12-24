-- Layerbounce_Handlers_Invite.lua
Layerbounce = Layerbounce or {}
Layerbounce.Handlers = Layerbounce.Handlers or {}

--------------------------------------------------------------------------------
-- InviteAndNotify
--------------------------------------------------------------------------------
function Layerbounce.Handlers.InviteAndNotify(sender)
    Layerbounce.Handlers.DebugPrintf("InviteAndNotify called for sender: %s", sender)

    -- If disabled, skip
    if not _G.LayerbounceSavedVariables.isAddonActive then
        return
    end

    -- If they're on cooldown from leaving/declining, skip
    if Layerbounce.Handlers.IsOnLeaveOrDeclineCooldown(sender) then
        Layerbounce.Handlers.DebugPrintf("%s is still on cooldown. Not inviting.", sender)
        return
    end

    local currentTime = GetTime()
    -- Avoid spamming invites too fast
    if currentTime - Layerbounce.Handlers.lastNotificationTime < Layerbounce.Config.NOTIFICATION_COOLDOWN then
        Layerbounce.Handlers.DebugPrintf("Notification cooldown. Skipping invite for %s.", sender)
        return
    end

    if not Layerbounce.Handlers.ExtractLayerText() then
        Layerbounce.Handlers.DebugPrintf("No valid layer found. Skipping invite for %s.", sender)
        return
    end

    if IsInGroup(LE_PARTY_CATEGORY_HOME) and GetNumGroupMembers() >= 5 then
        Layerbounce.Handlers.DebugPrintf("Party is full, cannot invite %s now.", sender)
        return
    end

    local playerName = string.match(sender, "([^%-]+)") or sender
    Layerbounce.Handlers.DebugPrintf("Inviting %s now...", playerName)
    C_PartyInfo.InviteUnit(playerName)
    Layerbounce.Handlers.partyMembers[playerName] = currentTime

    -- Optionally, you can whisper them your layer if you want:
    SendChatMessage(
        "I am on layer " .. (Layerbounce.Handlers.layerText or "Unknown") .. ". Inviting you now!",
        "WHISPER", nil, playerName
    )

    Layerbounce.Handlers.WaitForPlayerToJoin(playerName)
end

--------------------------------------------------------------------------------
-- We only want to invite if the message strictly says:
--   "layer"
--   or "layer 1,2,3" (but only if our current layer is in that list)
--------------------------------------------------------------------------------
function Layerbounce.Handlers.CheckIfValidLayerMessage(msg)
    -- Must match "layer" plus optional spaces, digits, or commas. No other words.
    local pattern = "^%s*layer[%d%s,]*$"
    msg = msg:lower()

    if not string.match(msg, pattern) then
        return false, {}
    end

    -- If it matches, let's extract any numbers
    local numbers = {}
    for num in string.gmatch(msg, "(%d+)") do
        table.insert(numbers, tonumber(num))
    end

    -- If zero numbers found, that means they just wrote "layer" => treat as valid
    return true, numbers
end

--------------------------------------------------------------------------------
-- HandleDeclinedInvite
--------------------------------------------------------------------------------
function Layerbounce.Handlers.HandleDeclinedInvite(sender)
    local currentTime = time() -- absolute timestamp
    local cooldown = Layerbounce.Config.LEAVE_DECLINE_COOLDOWN or 1200
    Layerbounce.Handlers.DebugPrintf("Player %s declined the invite at %s.", sender, date("%Y-%m-%d %H:%M:%S", currentTime))

    -- Store the current timestamp in the declined list
    Layerbounce.Handlers.declinedInviteList[sender] = currentTime

    local rejoinTime = currentTime + cooldown
    Layerbounce.Handlers.DebugPrintf(
        "Player %s is on a decline cooldown until %s (20-minute cooldown).",
        sender,
        date("%Y-%m-%d %H:%M:%S", rejoinTime)
    )
end

--------------------------------------------------------------------------------
-- IsOnLeaveOrDeclineCooldown
--------------------------------------------------------------------------------
function Layerbounce.Handlers.IsOnLeaveOrDeclineCooldown(sender)
    local currentTime = time()
    local cooldown = Layerbounce.Config.LEAVE_DECLINE_COOLDOWN or 1200

    local leftTimestamp = Layerbounce.Handlers.leftPartyList[sender]
    if leftTimestamp then
        local remaining = cooldown - (currentTime - leftTimestamp)
        if remaining > 0 then
            Layerbounce.Handlers.DebugPrintf(
                "Player %s is on cooldown for leaving. Remaining: %.1f seconds.",
                sender, remaining
            )
            return true
        end
    end

    local declinedTimestamp = Layerbounce.Handlers.declinedInviteList[sender]
    if declinedTimestamp then
        local remaining = cooldown - (currentTime - declinedTimestamp)
        if remaining > 0 then
            Layerbounce.Handlers.DebugPrintf(
                "Player %s is on cooldown for declining. Remaining: %.1f seconds.",
                sender, remaining
            )
            return true
        end
    end

    Layerbounce.Handlers.DebugPrintf("Player %s is not on a cooldown. They can join now.", sender)
    return false
end
