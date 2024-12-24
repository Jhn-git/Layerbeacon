-- Layerbounce.lua
local addonName, _ = ...  -- This MUST match the "name" that WoW sees your addon as.

-------------------------------------------------------------------------------
-- Create a global table if not present
-------------------------------------------------------------------------------
Layerbounce = Layerbounce or {}
Layerbounce.Main = Layerbounce.Main or {}

-------------------------------------------------------------------------------
-- ToggleAddon
-------------------------------------------------------------------------------
function Layerbounce.Main.ToggleAddon(minimapButton)
    _G.LayerbounceSavedVariables.isAddonActive =
        not _G.LayerbounceSavedVariables.isAddonActive

    Layerbounce.Handlers.DebugPrintf(
        "Layerbounce",
        "Minimap button clicked. Addon active state: %s",
        tostring(_G.LayerbounceSavedVariables.isAddonActive)
    )

    if _G.LayerbounceSavedVariables.isAddonActive then
        minimapButton:SetNormalTexture("Interface/AddOns/Layerbounce/textures/GreenButton.tga")
    else
        minimapButton:SetNormalTexture("Interface/AddOns/Layerbounce/textures/RedButton.tga")
    end
end

-------------------------------------------------------------------------------
-- CreateMinimapButton
-------------------------------------------------------------------------------
function Layerbounce.Main.CreateMinimapButton()
    local minimapButton = CreateFrame("Button", "LayerbounceMinimapButton", Minimap)
    minimapButton:SetSize(32, 32)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetFrameLevel(8)
    minimapButton:SetHighlightTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight")

    -- Decide which texture to use based on if the addon is active
    local texturePath
    if _G.LayerbounceSavedVariables and _G.LayerbounceSavedVariables.isAddonActive then
        texturePath = "Interface/AddOns/Layerbounce/textures/GreenButton.tga"
    else
        texturePath = "Interface/AddOns/Layerbounce/textures/RedButton.tga"
    end

    minimapButton:SetNormalTexture(texturePath)
    minimapButton:SetPushedTexture(texturePath)

    -- Position the minimap button
    Layerbounce.Handlers.UpdateButtonPosition(
        minimapButton,
        Layerbounce.Config.DEFAULT_ANGLE,
        Layerbounce.Config.RADIUS
    )

    -- Tooltip on hover
    minimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Layerbounce")
        GameTooltip:Show()
    end)
    minimapButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Draggable
    minimapButton:SetMovable(true)
    minimapButton:EnableMouse(true)
    minimapButton:RegisterForDrag("LeftButton")
    minimapButton:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    minimapButton:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    -- Click => Toggle
    minimapButton:SetScript("OnClick", function(self)
        Layerbounce.Main.ToggleAddon(self)
    end)

    return minimapButton
end

-------------------------------------------------------------------------------
-- FINAL STEP: Register events
-------------------------------------------------------------------------------
-- We must call this so our "ADDON_LOADED" etc. events are registered.
Layerbounce.Handlers.SetupEventHandlers(addonName)
