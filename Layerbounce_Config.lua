-- Layerbounce_Config.lua
Layerbounce = Layerbounce or {} -- Ensure the global table exists

Layerbounce.Config = {
    -- Constants for button placement
    DEFAULT_ANGLE = 90,        -- 90 degrees for the far right of the minimap
    RADIUS = 80,               -- Distance from the minimap's center (adjust as needed)
    AFK_TIMEOUT = 120,         -- AFK timeout in seconds
    NOTIFICATION_COOLDOWN = 3, -- Cooldown for layer notifications in seconds

    -- Default saved variables
    DEFAULTS = {
        firstTimeShown = true,
        isAddonActive = true
    }
}

-- Function to initialize saved variables
function Layerbounce.Config.InitializeSavedVariables(addonName)
    _G.LayerbounceSavedVariables = _G.LayerbounceSavedVariables or {}

    if type(_G.LayerbounceSavedVariables) ~= "table" then
        _G.LayerbounceSavedVariables = {}
    end

    for key, value in pairs(Layerbounce.Config.DEFAULTS) do
        if _G.LayerbounceSavedVariables[key] == nil
           or type(_G.LayerbounceSavedVariables[key]) ~= type(value) then
            _G.LayerbounceSavedVariables[key] = value
        end
    end
end
