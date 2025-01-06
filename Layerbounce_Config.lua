local addonName, _ = ...

-- Ensure global tables exist
Layerbounce = Layerbounce or {}
Layerbounce.Handlers = Layerbounce.Handlers or {}
Layerbounce.Main = Layerbounce.Main or {}
Layerbounce.Minimap = Layerbounce.Minimap or {}

-- Store the addon's name globally
Layerbounce.addonName = addonName

-- Define the Config table
Layerbounce.Config = {
    -- Constants for button placement
    DEFAULT_ANGLE = 90,           -- 90 degrees (far right of the minimap)
    RADIUS = 80,                  -- Distance from the minimap's center
    AFK_TIMEOUT = 120,            -- AFK timeout in seconds
    NOTIFICATION_COOLDOWN = 3,    -- Cooldown for layer notifications
    LEAVE_DECLINE_COOLDOWN = 1200, -- 20 minutes in seconds

    -- Debug mode
    DEBUG_ENABLED = false,        -- Set to true to enable debug prints

    -- Default saved variables
    DEFAULTS = {
        firstTimeShown = true,
        isAddonActive = false
    }
}

-- Initialize saved variables
function Layerbounce.Config.InitializeSavedVariables()
    _G.LayerbounceSavedVariables = _G.LayerbounceSavedVariables or {}

    if type(_G.LayerbounceSavedVariables) ~= "table" then
        _G.LayerbounceSavedVariables = {}
    end

    -- Set missing defaults
    for key, value in pairs(Layerbounce.Config.DEFAULTS) do
        if _G.LayerbounceSavedVariables[key] == nil
           or type(_G.LayerbounceSavedVariables[key]) ~= type(value) then
            _G.LayerbounceSavedVariables[key] = value
        end
    end
end

-- This is the stub for initializing any config-related logic.
function Layerbounce.Config.Initialize()
    -- If you have additional config initialization, do it here.
    -- For example, reading or applying settings that are stored in 
    -- LayerbounceSavedVariables.
    Layerbounce.Handlers.DebugPrintf("Layerbounce.Config.Initialize called.")
end
