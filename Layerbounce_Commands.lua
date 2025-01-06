-- Layerbounce_Commands.lua

local addonName, _ = ...

-- Ensure global table references
Layerbounce = Layerbounce or {}
Layerbounce.Commands = Layerbounce.Commands or {}

-------------------------------------------------------------------------------
-- Register Slash Commands
-------------------------------------------------------------------------------
function Layerbounce.Commands.RegisterCommands()
    -- Toggle debug mode
    SLASH_LAYERBOUNCEDEBUG1 = "/lbd"
    SlashCmdList["LAYERBOUNCEDEBUG"] = function(msg)
        Layerbounce.Config.DEBUG_ENABLED = not Layerbounce.Config.DEBUG_ENABLED
        print(
            string.format(
                "|cffffa500[Layerbounce] Debug mode is now %s.",
                Layerbounce.Config.DEBUG_ENABLED and "|cff00ff00enabled|r" or "|cffff0000disabled|r"
            )
        )
    end

    -- Add additional commands here as needed
    SLASH_LAYERBOUNCE1 = "/layerbounce"
    SlashCmdList["LAYERBOUNCE"] = function(msg)
        Layerbounce.Commands.HandleCommand(msg)
    end
end

-------------------------------------------------------------------------------
-- Command Handler
-------------------------------------------------------------------------------
function Layerbounce.Commands.HandleCommand(msg)
    msg = msg:lower():trim()

    if msg == "debug" then
        Layerbounce.Config.DEBUG_ENABLED = not Layerbounce.Config.DEBUG_ENABLED
        print(
            string.format(
                "|cffffa500[Layerbounce] Debug mode is now %s.",
                Layerbounce.Config.DEBUG_ENABLED and "|cff00ff00enabled|r" or "|cffff0000disabled|r"
            )
        )
    elseif msg == "status" then
        local status = _G.LayerbounceSavedVariables.isAddonActive and "active" or "inactive"
        print(string.format("|cffffa500[Layerbounce] Addon is currently %s.", status))
    else
        print("|cffffa500[Layerbounce] Available commands:")
        print("  /lbd - Toggle debug mode.")
        print("  /layerbounce debug - Toggle debug mode.")
        print("  /layerbounce status - Show addon status.")
    end
end

-------------------------------------------------------------------------------
-- Initialization Stub
-------------------------------------------------------------------------------
function Layerbounce.Commands.Initialize()
    Layerbounce.Commands.RegisterCommands()
    Layerbounce.Handlers.DebugPrintf("Layerbounce.Commands.Initialize called.")
end
