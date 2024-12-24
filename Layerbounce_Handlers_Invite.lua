-- Layerbounce_Handlers_Invite.lua
Layerbounce = Layerbounce or {}
Layerbounce.Handlers = Layerbounce.Handlers or {}

--------------------------------------------------------------------------------
-- AddToQueue
--------------------------------------------------------------------------------
function Layerbounce.Handlers.AddToQueue(sender, isPriority)
    -- 1) Check if the player is on cooldown for leaving
    if Layerbounce.Handlers.IsOnLeaveOrDeclineCooldown(sender) then
        Layerbounce.Handlers.DebugPrintf("%s is on a 20-min cooldown from leaving/declining. Ignoring.", sender)
        return
    end

    -- 2) Insert them into priority or normal queue
    if isPriority then
        table.insert(Layerbounce.Handlers.priorityQueue, sender)
        Layerbounce.Handlers.DebugPrintf("Added %s to PRIORITY queue.", sender)
    else
        table.insert(Layerbounce.Handlers.normalQueue, sender)
        Layerbounce.Handlers.DebugPrintf("Added %s to NORMAL queue.", sender)
    end

    -- 3) Try to invite them immediately if there's room
    Layerbounce.Handlers.ProcessQueues()
end

--------------------------------------------------------------------------------
-- ProcessQueues
--------------------------------------------------------------------------------
function Layerbounce.Handlers.ProcessQueues()
    if not _G.LayerbounceSavedVariables.isAddonActive then
        return
    end

    if IsInGroup(LE_PARTY_CATEGORY_HOME) and GetNumGroupMembers() >= 5 then
        return
    end

    -- Priority first
    if #Layerbounce.Handlers.priorityQueue > 0 then
        local sender = table.remove(Layerbounce.Handlers.priorityQueue, 1)
        Layerbounce.Handlers.InviteAndNotify(sender)
        return
    end

    -- Then normal
    if #Layerbounce.Handlers.normalQueue > 0 then
        local sender = table.remove(Layerbounce.Handlers.normalQueue, 1)
        Layerbounce.Handlers.InviteAndNotify(sender)
    end
end

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
        Layerbounce.Handlers.DebugPrintf("%s still on cooldown. Not inviting.", sender)
        return
    end

    local currentTime = GetTime()
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
    Layerbounce.Handlers.partyMembers[playerName] = GetTime()

    Layerbounce.Handlers.WaitForPlayerToJoin(playerName)
end

--------------------------------------------------------------------------------
-- HandleLayerWhisper + "yes" logic
--------------------------------------------------------------------------------
local layerResponseListeners = {}

function Layerbounce.Handlers.HandleLayerWhisper(sender)
    Layerbounce.Handlers.DebugPrintf("Layer whisper from: %s", sender)

    if Layerbounce.Handlers.ExtractLayerText() then
        SendChatMessage(
            "I am on layer " .. Layerbounce.Handlers.layerText ..
            ". Reply 'yes' to join my layer (invite inc).",
            "WHISPER", nil, sender
        )
        layerResponseListeners[sender] = true
    else
        SendChatMessage("Layer information is not currently available.", "WHISPER", nil, sender)
    end
end

function Layerbounce.Handlers.HandleIncomingWhisper(msg, sender)
    local lowerMsg = string.lower(msg or "")
    local currentLayer = Layerbounce.Handlers.layerText

    -- If user says "yes" after we told them "Reply 'yes' to join..."
    if lowerMsg == "yes" and layerResponseListeners[sender] then
        layerResponseListeners[sender] = nil
        Layerbounce.Handlers.DebugPrintf("%s confirmed joining layer %s", sender, currentLayer or "N/A")
        Layerbounce.Handlers.AddToQueue(sender, true)  -- treat as priority
        return
    end

    -- Extract layer text if not done
    local extracted = Layerbounce.Handlers.ExtractLayerText()
    if not extracted then return end

    local layerPriority = Layerbounce.Handlers.CheckLayerPriority(msg, currentLayer)
    if layerPriority == "priority" then
        Layerbounce.Handlers.AddToQueue(sender, true)
    elseif layerPriority == "normal" then
        Layerbounce.Handlers.AddToQueue(sender, false)
    end
end

--------------------------------------------------------------------------------
-- HandleDeclinedInvite
--   Called when you detect a "declines your group invitation" in system chat.
--   Stores a timestamp for the decline and logs debug information.
--------------------------------------------------------------------------------
function Layerbounce.Handlers.HandleDeclinedInvite(sender)
    local currentTime = time() -- Use `time()` for absolute timestamp
    local cooldown = Layerbounce.Config.LEAVE_DECLINE_COOLDOWN or 1200 -- Default 20 mins
    Layerbounce.Handlers.DebugPrintf("Player %s declined the invite at %s.", sender, date("%Y-%m-%d %H:%M:%S", currentTime))

    -- Store the current timestamp in the declined list
    Layerbounce.Handlers.declinedInviteList[sender] = currentTime

    -- Calculate when they will be allowed back (debug only)
    local rejoinTime = currentTime + cooldown
    Layerbounce.Handlers.DebugPrintf(
        "Player %s is on a decline cooldown until %s (20-minute cooldown).",
        sender,
        date("%Y-%m-%d %H:%M:%S", rejoinTime)
    )
end


--------------------------------------------------------------------------------
-- IsOnLeaveOrDeclineCooldown
--   Checks if the player is still on a 20-min cooldown after leaving or declining.
--------------------------------------------------------------------------------
function Layerbounce.Handlers.IsOnLeaveOrDeclineCooldown(sender)
    local currentTime = time() -- Use `time()` for absolute timestamp
    local cooldown = Layerbounce.Config.LEAVE_DECLINE_COOLDOWN or 1200 -- Default 20 mins

    -- Check .leftPartyList
    local leftTimestamp = Layerbounce.Handlers.leftPartyList[sender]
    if leftTimestamp then
        local remainingCooldown = cooldown - (currentTime - leftTimestamp)
        if remainingCooldown > 0 then
            Layerbounce.Handlers.DebugPrintf(
                "Player %s is on cooldown for leaving the party. Time remaining: %.1f seconds.",
                sender,
                remainingCooldown
            )
            return true
        end
    end

    -- Check .declinedInviteList
    local declinedTimestamp = Layerbounce.Handlers.declinedInviteList[sender]
    if declinedTimestamp then
        local remainingCooldown = cooldown - (currentTime - declinedTimestamp)
        if remainingCooldown > 0 then
            Layerbounce.Handlers.DebugPrintf(
                "Player %s is on cooldown for declining an invite. Time remaining: %.1f seconds.",
                sender,
                remainingCooldown
            )
            return true
        end
    end

    -- If no active cooldowns, log debug and allow them
    Layerbounce.Handlers.DebugPrintf("Player %s is not on a cooldown. They can join now.", sender)
    return false
end
