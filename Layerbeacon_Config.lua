local addonName, _ = ...

-- Ensure global tables exist
Layerbeacon = Layerbeacon or {}
Layerbeacon.Handlers = Layerbeacon.Handlers or {}
Layerbeacon.Main = Layerbeacon.Main or {}
Layerbeacon.Minimap = Layerbeacon.Minimap or {}

-- Store the addon's name globally
Layerbeacon.addonName = addonName

-- Define the Config table
Layerbeacon.Config = {
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
function Layerbeacon.Config.InitializeSavedVariables()
    _G.LayerbeaconSavedVariables = _G.LayerbeaconSavedVariables or {}

    if type(_G.LayerbeaconSavedVariables) ~= "table" then
        _G.LayerbeaconSavedVariables = {}
    end

    -- Set missing defaults
    for key, value in pairs(Layerbeacon.Config.DEFAULTS) do
        if _G.LayerbeaconSavedVariables[key] == nil
           or type(_G.LayerbeaconSavedVariables[key]) ~= type(value) then
            _G.LayerbeaconSavedVariables[key] = value
        end
    end
end

-- This is the stub for initializing any config-related logic.
function Layerbeacon.Config.Initialize()
    -- If you have additional config initialization, do it here.
    -- For example, reading or applying settings that are stored in 
    -- LayerbeaconSavedVariables.
    Layerbeacon.Handlers.DebugPrintf("Layerbeacon.Config.Initialize called.")
end
