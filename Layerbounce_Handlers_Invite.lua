-- Layerbounce_Handlers_Invite.lua
Layerbounce = Layerbounce or {}
Layerbounce.Handlers = Layerbounce.Handlers or {}

-- Track who we’re expecting a 'yes' from after "layer" whisper
local layerResponseListeners = {}

------------------------------------------------------------------------------
-- InviteAndNotify
------------------------------------------------------------------------------
function Layerbounce.Handlers.InviteAndNotify(sender)
    Layerbounce.Handlers.DebugPrintf("InviteAndNotify called for: %s", sender)
    if not _G.LayerbounceSavedVariables.isAddonActive then
        return
    end

    -- Cooldown check
    local currentTime = GetTime()
    if currentTime - Layerbounce.Handlers.lastNotificationTime < Layerbounce.Config.NOTIFICATION_COOLDOWN then
        Layerbounce.Handlers.DebugPrintf("Notification cooldown. Ignoring request from: %s", sender)
        return
    end

    -- Check if player previously left or declined
    if Layerbounce.Handlers.leftPartyList[sender] or Layerbounce.Handlers.declinedInviteList[sender] then
        Layerbounce.Handlers.DebugPrintf("Sender %s is in left/declined list.", sender)
        return
    end

    if Layerbounce.Handlers.ExtractLayerText() then
        if IsInGroup(LE_PARTY_CATEGORY_HOME) and GetNumGroupMembers() >= 5 then
            Layerbounce.Handlers.DebugPrintf("Party is full. Adding %s to queue.", sender)
            table.insert(Layerbounce.Handlers.partyQueue, sender)
        else
            local playerName = string.match(sender, "([^%-]+)") -- strip realm if "Name-Realm"
            Layerbounce.Handlers.DebugPrintf("Inviting player: %s", playerName)
            C_PartyInfo.InviteUnit(playerName)
            Layerbounce.Handlers.partyMembers[playerName] = GetTime()
            -- Wait to announce layer
            Layerbounce.Handlers.WaitForPlayerToJoin(playerName)
        end
    end
end

------------------------------------------------------------------------------
-- HandleLayerWhisper
--   Called when someone whispers "layer"
------------------------------------------------------------------------------
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

------------------------------------------------------------------------------
-- HandleIncomingWhisper
--   Called for EVERY whisper. If it's "layer", handle above. If "yes" from a
--   known user, proceed to invite.
------------------------------------------------------------------------------
function Layerbounce.Handlers.HandleIncomingWhisper(msg, sender)
    local lowerMsg = string.lower(msg or "")
    if lowerMsg == "layer" then
        Layerbounce.Handlers.HandleLayerWhisper(sender)
    elseif lowerMsg == "yes" and layerResponseListeners[sender] then
        layerResponseListeners[sender] = nil
        Layerbounce.Handlers.DebugPrintf("Player %s confirmed joining layer %s", sender, (Layerbounce.Handlers.layerText or "N/A"))
        Layerbounce.Handlers.InviteAndNotify(sender)
    end
end

------------------------------------------------------------------------------
-- HandleDeclinedInvite
--   If you detect a decline (via system message), track it here
------------------------------------------------------------------------------
function Layerbounce.Handlers.HandleDeclinedInvite(sender)
    Layerbounce.Handlers.DebugPrintf("Player %s declined invite.", sender)
    Layerbounce.Handlers.declinedInviteList[sender] = true
end
