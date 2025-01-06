-- Layerbeacon_Handlers_Events.lua
local addonName, _ = ...

Layerbeacon = Layerbeacon or {}
Layerbeacon.Handlers = Layerbeacon.Handlers or {}

-- Optional throttling constants and function
local CHAT_THROTTLE_SECONDS = 5
local lastChannelCheckTime = 0
local lastWhisperCheckTime = 0

function Layerbeacon.Handlers.ShouldThrottle(lastTime)
    local now = GetTime()
    if (now - lastTime) < CHAT_THROTTLE_SECONDS then
        return true, lastTime
    else
        return false, now
    end
end

function Layerbeacon.Handlers.SetupEventHandlers(addonName)
    local eventFrame = CreateFrame("Frame")

    -- Register events
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
    eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
    eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        -- 1) ADDON_LOADED
        if event == "ADDON_LOADED" then
            local loadedAddonName = ...
            if loadedAddonName == addonName then
                self:UnregisterEvent("ADDON_LOADED")

                -- Initialize saved variables
                local success, err = pcall(function()
                    Layerbeacon.Config.InitializeSavedVariables()
                end)
                if not success then
                    Layerbeacon.Handlers.DebugPrintf("Error initializing saved variables: %s", err)
                else
                    Layerbeacon.Handlers.DebugPrintf(
                        "Saved variables loaded. isAddonActive: %s",
                        tostring(_G.LayerbeaconSavedVariables.isAddonActive)
                    )
                end

                -- Initialize modules
                local modules = {
                    { name = "Config",   init = Layerbeacon.Config.Initialize },
                    { name = "Handlers", init = Layerbeacon.Handlers.Initialize },
                    { name = "Commands", init = Layerbeacon.Commands.Initialize },
                    { name = "Minimap",  init = Layerbeacon.Minimap.Initialize }
                }

                for _, module in ipairs(modules) do
                    local modSuccess, modErr = pcall(module.init)
                    if modSuccess then
                        DEFAULT_CHAT_FRAME:AddMessage(
                            string.format("|cffffa500[Layerbeacon] %s module successfully loaded!", module.name)
                        )
                    else
                        DEFAULT_CHAT_FRAME:AddMessage(
                            string.format("|cffff0000[Layerbeacon] Failed to load %s module: %s", module.name, modErr)
                        )
                    end
                end

                -- Final notify
                pcall(function()
                    DEFAULT_CHAT_FRAME:AddMessage("|cffffa500[Layerbeacon] Addon successfully loaded!")
                end)

                -- Set up periodic AFK checks
                C_Timer.NewTicker(10, function()
                    if _G.LayerbeaconSavedVariables.isAddonActive then
                        Layerbeacon.Handlers.AutoKickOnNewPlayer()
                    end
                end)
            end
            return
        end

        -- Skip if addon is disabled
        if not _G.LayerbeaconSavedVariables or not _G.LayerbeaconSavedVariables.isAddonActive then
            return
        end

        -- Log active events
        Layerbeacon.Handlers.DebugPrintf("Event triggered: %s", event)

        -- Handle specific events
        if event == "GROUP_ROSTER_UPDATE" then
            -- Example usage: update party member tracking
            Layerbeacon.Handlers.TrackPartyMembers()
        elseif event == "CHAT_MSG_CHANNEL" then
            local shouldThrottle
            shouldThrottle, lastChannelCheckTime = Layerbeacon.Handlers.ShouldThrottle(lastChannelCheckTime)
            if shouldThrottle then return end

            local msg, sender = ...
            Layerbeacon.Handlers.HandleChatMessage(event, msg, sender, ...)
        elseif event == "CHAT_MSG_WHISPER" then
            local shouldThrottle
            shouldThrottle, lastWhisperCheckTime = Layerbeacon.Handlers.ShouldThrottle(lastWhisperCheckTime)
            if shouldThrottle then return end

            local msg, sender = ...
            Layerbeacon.Handlers.HandleChatMessage(event, msg, sender, ...)
        elseif event == "CHAT_MSG_SYSTEM" then
            local sysMsg = ...
            Layerbeacon.Handlers.HandleSystemMessage(sysMsg)
        end
    end)
end

-------------------------------------------------------------------------------
-- Helper: Handle Chat Messages
-------------------------------------------------------------------------------
function Layerbeacon.Handlers.HandleChatMessage(event, msg, sender, ...)
    -- Filter by channel
    if event == "CHAT_MSG_CHANNEL" then
        local channelName = select(9, ...)
        if not channelName or channelName:lower() ~= "layer" then
            Layerbeacon.Handlers.DebugPrintf(
                "Message from %s ignored. Channel '%s' does not match 'layer'.", 
                sender, channelName or "Unknown"
            )
            return
        end
    end

    -- Validate the message
    local isValid = Layerbeacon.Handlers.CheckIfValidLayerMessage(msg)
    if not isValid then
        Layerbeacon.Handlers.DebugPrintf("Message from %s ignored. Does not contain 'layer'.", sender)
        return
    end

    -- Send the invite
    Layerbeacon.Handlers.DebugPrintf("%s 'layer' from %s => invite.", event, sender)
    Layerbeacon.Handlers.InviteAndNotify(sender)
end
