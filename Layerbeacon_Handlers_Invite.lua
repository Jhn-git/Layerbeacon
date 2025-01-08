-- Layerbeacon_Handlers_Invite.lua

-- Ensure references
Layerbeacon = Layerbeacon or {}
Layerbeacon.Handlers = Layerbeacon.Handlers or {}

--------------------------------------------------------------------------------
-- Whisper Layer Info Flow
--------------------------------------------------------------------------------
-- 1. Whisper Layer Info: Send layer details and instructions to a player
function Layerbeacon.Handlers.WhisperLayerInfo(sender)
    Layerbeacon.Handlers.DebugPrintf("WhisperLayerInfo called for sender: %s", sender)

    -- Skip if the addon is disabled
    if not _G.LayerbeaconSavedVariables.isAddonActive then
        Layerbeacon.Handlers.DebugPrintf("Addon is inactive. Skipping interaction for %s.", sender)
        return
    end

    -- Skip if the party is full
    if IsInGroup(LE_PARTY_CATEGORY_HOME) and GetNumGroupMembers() >= 5 then
        Layerbeacon.Handlers.DebugPrintf("Party is full. Cannot interact with %s.", sender)
        return
    end

    -- Validate layer text
    local layer = Layerbeacon.Handlers.layerText or "Unknown"
    if layer == "Unknown" then
        Layerbeacon.Handlers.DebugPrintf("Warning: Layer text is not properly set!")
    end

    -- Send a whisper with clear instructions
    local playerName = string.match(sender, "([^%-]+)") or sender
    local layerMessage = "[Layerbeacon] I am on Layer " .. layer .. 
                         ". Reply with 'invite " .. layer .. "' if you want to join."
    SendChatMessage(layerMessage, "WHISPER", nil, playerName)
    Layerbeacon.Handlers.DebugPrintf("Sent whisper to %s: %s", playerName, layerMessage)
end


--------------------------------------------------------------------------------
-- Whisper Handling Flow
--------------------------------------------------------------------------------
-- 2. Handle Incoming Whisper: Process whispers and send invites if the message is correct
function Layerbeacon.Handlers.HandleWhisper(sender, message)
    local playerName = string.match(sender, "([^%-]+)") or sender -- Extract the player name
    local expectedLayer = tostring(Layerbeacon.Handlers.layerText or "Unknown") -- Ensure layer is treated as a string

    -- Parse the whisper for the "invite" command and the layer number
    local command, layer = string.match(message:lower(), "^(invite)%s+(%d+)$")
    if command == "invite" and layer == expectedLayer then
        Layerbeacon.Handlers.DebugPrintf("Player %s correctly requested to join Layer %s.", playerName, layer)
        C_PartyInfo.InviteUnit(playerName) -- Send the invite
        Layerbeacon.Handlers.DebugPrintf("Invited %s to the group.", playerName)
    else
        Layerbeacon.Handlers.DebugPrintf(
            "Player %s sent an incorrect or unrecognized message: '%s'. Expected 'invite %s'.", 
            playerName, message, expectedLayer
        )
    end
end

--------------------------------------------------------------------------------
-- Decline Handling Flow
--------------------------------------------------------------------------------
-- 4. Handle Declined Invite: Add player to cooldown and remove from pending invites
function Layerbeacon.Handlers.HandleDeclinedInvite(sender)
    local currentTime = GetTime()
    local cooldown = Layerbeacon.Config.LEAVE_DECLINE_COOLDOWN or 1200

    -- Track declined invite
    Layerbeacon.Handlers.declinedInviteList = Layerbeacon.Handlers.declinedInviteList or {}
    Layerbeacon.Handlers.declinedInviteList[sender] = currentTime
    Layerbeacon.Handlers.DebugPrintf("Player %s declined the invite. Added to cooldown.", sender)

    -- Remove from pending invites
    if Layerbeacon.Handlers.pendingInviteList then
        Layerbeacon.Handlers.pendingInviteList[sender] = nil
        Layerbeacon.Handlers.DebugPrintf("Removed %s from pendingInviteList.", sender)
    end
end

--------------------------------------------------------------------------------
-- Cooldown Flow
--------------------------------------------------------------------------------
-- 5. Check Cooldowns: Determine if a player is on leave or decline cooldown
function Layerbeacon.Handlers.IsOnLeaveOrDeclineCooldown(sender)
    local currentTime = GetTime()
    local cooldown = Layerbeacon.Config.LEAVE_DECLINE_COOLDOWN or 1200

    -- Helper to check if sender is still on cooldown
    local function isOnCooldown(list, label)
        local timestamp = list and list[sender]
        if timestamp and (currentTime - timestamp) < cooldown then
            Layerbeacon.Handlers.DebugPrintf(
                "Player %s is on %s cooldown. Remaining: %.1f seconds.",
                sender, label, cooldown - (currentTime - timestamp)
            )
            return true
        end
        return false
    end

    -- Check both leave and decline cooldowns
    if isOnCooldown(Layerbeacon.Handlers.leftPartyList, "leave") or 
       isOnCooldown(Layerbeacon.Handlers.declinedInviteList, "decline") then
        return true
    end

    Layerbeacon.Handlers.DebugPrintf("Player %s is not on cooldown. They can join now.", sender)
    return false
end
