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
    SLASH_LayerbeaconDEBUG1 = "/lbd"
    SlashCmdList["LayerbeaconDEBUG"] = function(msg)
        Layerbeacon.Config.DEBUG_ENABLED = not Layerbeacon.Config.DEBUG_ENABLED
        print(
            string.format(
                "|cffffa500[Layerbeacon] Debug mode is now %s.",
                Layerbeacon.Config.DEBUG_ENABLED and "|cff00ff00enabled|r" or "|cffff0000disabled|r"
            )
        )
    end

    -- Add additional commands here as needed
    SLASH_Layerbeacon1 = "/Layerbeacon"
    SlashCmdList["Layerbeacon"] = function(msg)
        Layerbeacon.Commands.HandleCommand(msg)
    end
end

-------------------------------------------------------------------------------
-- Command Handler
-------------------------------------------------------------------------------
function Layerbeacon.Commands.HandleCommand(msg)
    msg = msg:lower():trim()

    if msg == "debug" then
        Layerbeacon.Config.DEBUG_ENABLED = not Layerbeacon.Config.DEBUG_ENABLED
        print(
            string.format(
                "|cffffa500[Layerbeacon] Debug mode is now %s.",
                Layerbeacon.Config.DEBUG_ENABLED and "|cff00ff00enabled|r" or "|cffff0000disabled|r"
            )
        )
    elseif msg == "status" then
        local status = _G.LayerbeaconSavedVariables.isAddonActive and "active" or "inactive"
        print(string.format("|cffffa500[Layerbeacon] Addon is currently %s.", status))
    else
        print("|cffffa500[Layerbeacon] Available commands:")
        print("  /lbd - Toggle debug mode.")
        print("  /Layerbeacon debug - Toggle debug mode.")
        print("  /Layerbeacon status - Show addon status.")
    end
end

-------------------------------------------------------------------------------
-- Initialization Stub
-------------------------------------------------------------------------------
function Layerbeacon.Commands.Initialize()
    Layerbeacon.Commands.RegisterCommands()
    Layerbeacon.Handlers.DebugPrintf("Layerbeacon.Commands.Initialize called.")
end
