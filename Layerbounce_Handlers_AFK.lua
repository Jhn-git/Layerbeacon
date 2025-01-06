-- Layerbounce_Handlers_AFK.lua

-- Ensure references
Layerbounce = Layerbounce or {}
Layerbounce.Handlers = Layerbounce.Handlers or {}

-- 1. Track Party Members
function Layerbounce.Handlers.TrackPartyMembers()
    local currentTime = GetTime()
    local newPartyMembers = {}

    for i = 1, GetNumGroupMembers() do
        local name, _, _, _, _, _, _, _, _, _, _ = GetRaidRosterInfo(i)
        if name then
            -- Keep existing join time or set current time for new members
            newPartyMembers[name] = Layerbounce.Handlers.partyMembers[name] or currentTime
        end
    end

    -- Check for players who left
    for playerName in pairs(Layerbounce.Handlers.partyMembers) do
        if not newPartyMembers[playerName] then
            Layerbounce.Handlers.DebugPrintf("Player %s left. Removing from tracking.", playerName)
            Layerbounce.Handlers.leftPartyList[playerName] = currentTime
        end
    end

    Layerbounce.Handlers.partyMembers = newPartyMembers
end

-- 2. Auto-Kick on New Player Join
function Layerbounce.Handlers.AutoKickOnNewPlayer()
    local currentTime = GetTime()
    local afkTimeout = Layerbounce.Config.AFK_TIMEOUT

    for playerName, joinTime in pairs(Layerbounce.Handlers.partyMembers) do
        if (currentTime - joinTime) > afkTimeout then
            -- Check for AFK player
            Layerbounce.Handlers.DebugPrintf("Player %s is AFK for too long. Kicking...", playerName)
            Layerbounce.Handlers.KickPlayer(playerName)
            return -- Kick one player per event to avoid excessive disruption
        end
    end
end

-- 3. Kick Player Securely
function Layerbounce.Handlers.KickPlayer(playerName)
    if not playerName or playerName == "" then
        Layerbounce.Handlers.DebugPrintf("Invalid player name.")
        return
    end

    if not UnitIsGroupLeader("player") then
        Layerbounce.Handlers.DebugPrintf("Cannot kick %s: You are not the group leader.", playerName)
        return
    end

    if InCombatLockdown() then
        Layerbounce.Handlers.DebugPrintf("Cannot kick %s: Combat lockdown active.", playerName)
        return
    end

    -- Use a secure button to kick the player
    if not kickButton then
        -- Create a secure button if needed
        kickButton = CreateFrame("Button", "LayerbounceSecureKickButton", UIParent, "SecureActionButtonTemplate")
        kickButton:SetAttribute("type", "macro")
    end

    kickButton:SetAttribute("macrotext", "/uninvite " .. playerName)
    kickButton:Click()

    -- Remove player from tracking
    Layerbounce.Handlers.partyMembers[playerName] = nil
    Layerbounce.Handlers.leftPartyList[playerName] = GetTime()
    Layerbounce.Handlers.DebugPrintf("Kicked player %s for being AFK.", playerName)
end
