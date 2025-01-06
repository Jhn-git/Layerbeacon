local addonName, _ = ...

Layerbeacon = Layerbeacon or {}
Layerbeacon.Minimap = Layerbeacon.Minimap or {}

-------------------------------------------------------------------------------
-- Update Button Position
-------------------------------------------------------------------------------
function Layerbeacon.Minimap.UpdateButtonPosition(button, angle, radius)
    angle = angle or 0
    radius = radius or 80

    local radians = math.rad(angle)
    local xOffset = math.cos(radians) * radius
    local yOffset = math.sin(radians) * radius

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", xOffset, yOffset)
end

-------------------------------------------------------------------------------
-- Update Minimap Button Texture
-------------------------------------------------------------------------------
function Layerbeacon.Minimap.UpdateButtonTexture(minimapButton)
    local texturePath

    -- Ensure saved variables exist
    _G.LayerbeaconSavedVariables = _G.LayerbeaconSavedVariables or {}
    if _G.LayerbeaconSavedVariables.isAddonActive then
        if Layerbeacon.Handlers.ExtractLayerText() then
            local layer = tonumber(Layerbeacon.Handlers.layerText)
            if layer and layer >= 1 and layer <= 9 then
                texturePath = "Interface/AddOns/Layerbeacon/textures/Layerbeacon_" .. layer .. ".tga"
            else
                texturePath = "Interface/AddOns/Layerbeacon/textures/Layerbeacon_question.tga"
            end
        else
            texturePath = "Interface/AddOns/Layerbeacon/textures/Layerbeacon_question.tga"
        end
    else
        texturePath = "Interface/AddOns/Layerbeacon/textures/Layerbeacon_question.tga"
    end

    minimapButton:SetNormalTexture(texturePath)
    minimapButton:SetPushedTexture(texturePath)
end

-------------------------------------------------------------------------------
-- Create Minimap Button
-------------------------------------------------------------------------------
function Layerbeacon.Minimap.CreateButton()
    local minimapButton = CreateFrame("Button", "LayerbeaconMinimapButton", Minimap)
    minimapButton:SetSize(32, 32)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetFrameLevel(8)
    minimapButton:SetHighlightTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight")

    Layerbeacon.Minimap.UpdateButtonTexture(minimapButton)

    Layerbeacon.Minimap.UpdateButtonPosition(
        minimapButton,
        Layerbeacon.Config.DEFAULT_ANGLE,
        Layerbeacon.Config.RADIUS
    )

    -- Button scripts
    minimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Layerbeacon")
        GameTooltip:Show()
    end)
    minimapButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    minimapButton:SetMovable(true)
    minimapButton:EnableMouse(true)
    minimapButton:RegisterForDrag("LeftButton")
    minimapButton:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    minimapButton:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    minimapButton:SetScript("OnClick", function(self)
        Layerbeacon.Main.ToggleAddon(self)
    end)

    -- Store reference
    Layerbeacon.Minimap.Button = minimapButton

    return minimapButton
end

-------------------------------------------------------------------------------
-- Initialization Stub
-------------------------------------------------------------------------------
function Layerbeacon.Minimap.Initialize()
    -- Create the minimap button or do any additional minimap-related setup here
    Layerbeacon.Minimap.CreateButton()

    -- If you need to do anything else when the addon loads, do it here
    Layerbeacon.Handlers.DebugPrintf("Layerbeacon.Minimap.Initialize called.")
end
