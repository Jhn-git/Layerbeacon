-- Layerbounce_Handlers_AFK.lua
Layerbounce = Layerbounce or {}
Layerbounce.Handlers = Layerbounce.Handlers or {}

function Layerbounce.Handlers.CheckAFKAndKick()
    Layerbounce.Handlers.DebugPrintf("Checking for AFK players...")
    local currentTime = GetTime()

    for playerName, joinTime in pairs(Layerbounce.Handlers.partyMembers) do
        if not UnitInParty(playerName) then
            -- The player left the group
            Layerbounce.Handlers.DebugPrintf("Player %s left. Removing from tracking.", playerName)
            Layerbounce.Handlers.partyMembers[playerName] = nil

            -- Record the timestamp so they're on cooldown for 20 min
            Layerbounce.Handlers.leftPartyList[playerName] = currentTime

        elseif currentTime - joinTime > Layerbounce.Config.AFK_TIMEOUT then
            -- Player is AFK too long
            Layerbounce.Handlers.DebugPrintf("Player %s AFK too long. Kicking...", playerName)
            UninviteUnit(playerName)
            Layerbounce.Handlers.partyMembers[playerName] = nil
            Layerbounce.Handlers.leftPartyList[playerName] = currentTime
            Layerbounce.Handlers.DebugPrintf("Removed %s for AFK.", playerName)
        end
    end
end
