-- Layerbounce_Config.lua
Layerbounce = Layerbounce or {} -- Ensure global table exists

Layerbounce.Config = {
    -- Constants for button placement
    DEFAULT_ANGLE = 90,           -- 90 degrees (far right of the minimap)
    RADIUS = 80,                  -- Distance from the minimap's center
    AFK_TIMEOUT = 120,            -- AFK timeout in seconds
    NOTIFICATION_COOLDOWN = 3,    -- Cooldown for layer notifications in secs
    LEAVE_DECLINE_COOLDOWN = 1200, -- 20 mins = 20 * 60 seconds

    -- Default saved variables
    DEFAULTS = {
        firstTimeShown = true,
        isAddonActive = true
    }
}

-- Initialize saved variables
function Layerbounce.Config.InitializeSavedVariables(addonName)
    _G.LayerbounceSavedVariables = _G.LayerbounceSavedVariables or {}
    
    if type(_G.LayerbounceSavedVariables) ~= "table" then
        _G.LayerbounceSavedVariables = {}
    end
    
    for key, value in pairs(Layerbounce.Config.DEFAULTS) do
        if _G.LayerbounceSavedVariables[key] == nil
           or type(_G.LayerbounceSavedVariables[key]) ~= type(value)
        then
            _G.LayerbounceSavedVariables[key] = value
        end
    end
end
