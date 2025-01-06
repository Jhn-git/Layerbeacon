local addonName, _ = ...

Layerbounce = Layerbounce or {}
Layerbounce.Minimap = Layerbounce.Minimap or {}

-------------------------------------------------------------------------------
-- Update Button Position
-------------------------------------------------------------------------------
function Layerbounce.Minimap.UpdateButtonPosition(button, angle, radius)
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
function Layerbounce.Minimap.UpdateButtonTexture(minimapButton)
    local texturePath

    -- Ensure saved variables exist
    _G.LayerbounceSavedVariables = _G.LayerbounceSavedVariables or {}
    if _G.LayerbounceSavedVariables.isAddonActive then
        if Layerbounce.Handlers.ExtractLayerText() then
            local layer = tonumber(Layerbounce.Handlers.layerText)
            if layer and layer >= 1 and layer <= 9 then
                texturePath = "Interface/AddOns/Layerbounce/textures/Layerbounce_" .. layer .. ".tga"
            else
                texturePath = "Interface/AddOns/Layerbounce/textures/Layerbounce_question.tga"
            end
        else
            texturePath = "Interface/AddOns/Layerbounce/textures/Layerbounce_question.tga"
        end
    else
        texturePath = "Interface/AddOns/Layerbounce/textures/Layerbounce_question.tga"
    end

    minimapButton:SetNormalTexture(texturePath)
    minimapButton:SetPushedTexture(texturePath)
end

-------------------------------------------------------------------------------
-- Create Minimap Button
-------------------------------------------------------------------------------
function Layerbounce.Minimap.CreateButton()
    local minimapButton = CreateFrame("Button", "LayerbounceMinimapButton", Minimap)
    minimapButton:SetSize(32, 32)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetFrameLevel(8)
    minimapButton:SetHighlightTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight")

    Layerbounce.Minimap.UpdateButtonTexture(minimapButton)

    Layerbounce.Minimap.UpdateButtonPosition(
        minimapButton,
        Layerbounce.Config.DEFAULT_ANGLE,
        Layerbounce.Config.RADIUS
    )

    -- Button scripts
    minimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Layerbounce")
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
        Layerbounce.Main.ToggleAddon(self)
    end)

    -- Store reference
    Layerbounce.Minimap.Button = minimapButton

    return minimapButton
end

-------------------------------------------------------------------------------
-- Initialization Stub
-------------------------------------------------------------------------------
function Layerbounce.Minimap.Initialize()
    -- Create the minimap button or do any additional minimap-related setup here
    Layerbounce.Minimap.CreateButton()

    -- If you need to do anything else when the addon loads, do it here
    Layerbounce.Handlers.DebugPrintf("Layerbounce.Minimap.Initialize called.")
end
