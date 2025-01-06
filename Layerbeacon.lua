local addonName, _ = ...

-- Ensure references
Layerbeacon = Layerbeacon or {}
Layerbeacon.Main = Layerbeacon.Main or {}

-------------------------------------------------------------------
-- ToggleAddon
-------------------------------------------------------------------
function Layerbeacon.Main.ToggleAddon(minimapButton)
    _G.LayerbeaconSavedVariables = _G.LayerbeaconSavedVariables or {}
    _G.LayerbeaconSavedVariables.isAddonActive = not _G.LayerbeaconSavedVariables.isAddonActive

    Layerbeacon.Handlers.DebugPrintf("Minimap button clicked. Addon active state: %s",
        tostring(_G.LayerbeaconSavedVariables.isAddonActive)
    )

    if Layerbeacon.Minimap and Layerbeacon.Minimap.UpdateButtonTexture then
        Layerbeacon.Minimap.UpdateButtonTexture(minimapButton)
    end
end

-------------------------------------------------------------------
-- Register events (SetupEventHandlers)
-------------------------------------------------------------------
Layerbeacon.Handlers.SetupEventHandlers(Layerbeacon.addonName)

-------------------------------------------------------------------
-- Initialize Commands
-------------------------------------------------------------------
Layerbeacon.Commands.Initialize()