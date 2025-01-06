local addonName, _ = ...

-- Ensure references
Layerbounce = Layerbounce or {}
Layerbounce.Main = Layerbounce.Main or {}

-------------------------------------------------------------------
-- ToggleAddon
-------------------------------------------------------------------
function Layerbounce.Main.ToggleAddon(minimapButton)
    _G.LayerbounceSavedVariables = _G.LayerbounceSavedVariables or {}
    _G.LayerbounceSavedVariables.isAddonActive = not _G.LayerbounceSavedVariables.isAddonActive

    Layerbounce.Handlers.DebugPrintf("Minimap button clicked. Addon active state: %s",
        tostring(_G.LayerbounceSavedVariables.isAddonActive)
    )

    if Layerbounce.Minimap and Layerbounce.Minimap.UpdateButtonTexture then
        Layerbounce.Minimap.UpdateButtonTexture(minimapButton)
    end
end

-------------------------------------------------------------------
-- Register events (SetupEventHandlers)
-------------------------------------------------------------------
Layerbounce.Handlers.SetupEventHandlers(Layerbounce.addonName)

-------------------------------------------------------------------
-- Initialize Commands
-------------------------------------------------------------------
Layerbounce.Commands.Initialize()