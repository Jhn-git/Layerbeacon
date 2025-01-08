-- Layerbeacon_Commands.lua
local addonName, _ = ...

-- Ensure global table references
Layerbeacon = Layerbeacon or {}
Layerbeacon.Commands = Layerbeacon.Commands or {}

-------------------------------------------------------------------------------
-- Register Slash Commands
-------------------------------------------------------------------------------
function Layerbeacon.Commands.RegisterCommands()
    -- Toggle debug mode
    SLASH_LayerbeaconDEBUG1 = "/Layerbeacon"
    SlashCmdList["LayerbeaconDEBUG"] = function(msg)
        if msg:lower():trim() == "debug" then
            Layerbeacon.Config.DEBUG_ENABLED = not Layerbeacon.Config.DEBUG_ENABLED
            print(
                string.format(
                    "|cffffa500[Layerbeacon] Debug mode is now %s.",
                    Layerbeacon.Config.DEBUG_ENABLED and "|cff00ff00enabled|r" or "|cffff0000disabled|r"
                )
            )
        else
            print("|cffffa500[Layerbeacon] Usage: /Layerbeacon debug - Toggle debug mode.")
        end
    end

    -- Announce layer command
    SLASH_LayerbeaconANNOUNCE1 = "/lbannounce"
    SlashCmdList["LayerbeaconANNOUNCE"] = function()
        Layerbeacon.Commands.AnnounceLayer()
    end
end

-------------------------------------------------------------------------------
-- Announce Layer Command
-------------------------------------------------------------------------------
function Layerbeacon.Commands.AnnounceLayer()
    local currentLayer = Layerbeacon.Handlers.layerText or "Unknown"
    local playerName = UnitName("player") -- Get your character's name
    local announceMessage = string.format(
        "[Layerbeacon] I am currently on Layer %s. Whisper me '/invite %s' if you want to join my layer.",
        currentLayer,
        currentLayer
    )

    -- Announce to the /layer channel
    local channelIndex = GetChannelName("layer")
    if channelIndex and channelIndex > 0 then
        SendChatMessage(announceMessage, "CHANNEL", nil, channelIndex)
        print("|cffffa500[Layerbeacon] Announced layer to the /layer channel.")
    else
        print("|cffffa500[Layerbeacon] Error: You are not in the /layer channel.")
        print("|cffffa500[Layerbeacon] Join the /layer channel by typing: /join layer")
    end
end

-------------------------------------------------------------------------------
-- Initialization Stub
-------------------------------------------------------------------------------
function Layerbeacon.Commands.Initialize()
    Layerbeacon.Commands.RegisterCommands()
    if Layerbeacon.Config.DEBUG_ENABLED then
        Layerbeacon.Handlers.DebugPrintf("Layerbeacon.Commands.Initialize called.")
    end
end
