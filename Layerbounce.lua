-- Layerbounce.lua
Layerbounce = Layerbounce or {}
Layerbounce.Main = Layerbounce.Main or {}

local addonName, _ = ...

-- Toggle addon
function Layerbounce.Main.ToggleAddon(minimapButton)
    _G.LayerbounceSavedVariables.isAddonActive = not _G.LayerbounceSavedVariables.isAddonActive
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

-- Create the minimap button
function Layerbounce.Main.CreateMinimapButton()
    local minimapButton = CreateFrame("Button", "LayerbounceMinimapButton", Minimap)
    minimapButton:SetSize(32, 32)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetFrameLevel(8)
    minimapButton:SetHighlightTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight")

    minimapButton:SetNormalTexture(
        _G.LayerbounceSavedVariables.isAddonActive
        and "Interface/AddOns/Layerbounce/textures/GreenButton.tga"
        or  "Interface/AddOns/Layerbounce/textures/RedButton.tga"
    )
    minimapButton:SetPushedTexture("Interface/AddOns/Layerbounce/textures/GreenButton.tga")

    Layerbounce.Handlers.UpdateButtonPosition(
        minimapButton,
        Layerbounce.Config.DEFAULT_ANGLE,
        Layerbounce.Config.RADIUS
    )

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
    minimapButton:SetScript("OnDragStart", function(self) self:StartMoving() end)
    minimapButton:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Optionally save new position
    end)

    -- Toggle on click
    minimapButton:SetScript("OnClick", function(self)
        Layerbounce.Main.ToggleAddon(self)
    end)

    return minimapButton
end

--------------------------------------------------------------------------------
-- Kick off event registration
--------------------------------------------------------------------------------
Layerbounce.Handlers.SetupEventHandlers(addonName)
