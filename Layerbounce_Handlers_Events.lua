-- Layerbounce_Handlers_Events.lua
local addonName, _ = ...

Layerbounce = Layerbounce or {}
Layerbounce.Handlers = Layerbounce.Handlers or {}

-- Optional throttling constants and function
local CHAT_THROTTLE_SECONDS = 5
local lastChannelCheckTime = 0
local lastWhisperCheckTime = 0

function Layerbounce.Handlers.ShouldThrottle(lastTime)
    local now = GetTime()
    if (now - lastTime) < CHAT_THROTTLE_SECONDS then
        return true, lastTime
    else
        return false, now
    end
end

function Layerbounce.Handlers.SetupEventHandlers(addonName)
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
                    Layerbounce.Config.InitializeSavedVariables()
                end)
                if not success then
                    Layerbounce.Handlers.DebugPrintf("Error initializing saved variables: %s", err)
                else
                    Layerbounce.Handlers.DebugPrintf(
                        "Saved variables loaded. isAddonActive: %s",
                        tostring(_G.LayerbounceSavedVariables.isAddonActive)
                    )
                end

                -- Initialize modules
                local modules = {
                    { name = "Config",   init = Layerbounce.Config.Initialize },
                    { name = "Handlers", init = Layerbounce.Handlers.Initialize },
                    { name = "Commands", init = Layerbounce.Commands.Initialize },
                    { name = "Minimap",  init = Layerbounce.Minimap.Initialize }
                }

                for _, module in ipairs(modules) do
                    local modSuccess, modErr = pcall(module.init)
                    if modSuccess then
                        DEFAULT_CHAT_FRAME:AddMessage(
                            string.format("|cffffa500[Layerbounce] %s module successfully loaded!", module.name)
                        )
                    else
                        DEFAULT_CHAT_FRAME:AddMessage(
                            string.format("|cffff0000[Layerbounce] Failed to load %s module: %s", module.name, modErr)
                        )
                    end
                end

                -- Final notify
                pcall(function()
                    DEFAULT_CHAT_FRAME:AddMessage("|cffffa500[Layerbounce] Addon successfully loaded!")
                end)

                -- Set up periodic AFK checks
                C_Timer.NewTicker(10, function()
                    if _G.LayerbounceSavedVariables.isAddonActive then
                        Layerbounce.Handlers.AutoKickOnNewPlayer()
                    end
                end)
            end
            return
        end

        -- Skip if addon is disabled
        if not _G.LayerbounceSavedVariables or not _G.LayerbounceSavedVariables.isAddonActive then
            return
        end

        -- Log active events
        Layerbounce.Handlers.DebugPrintf("Event triggered: %s", event)

        -- Handle specific events
        if event == "GROUP_ROSTER_UPDATE" then
            -- Example usage: update party member tracking
            Layerbounce.Handlers.TrackPartyMembers()
        elseif event == "CHAT_MSG_CHANNEL" then
            local shouldThrottle
            shouldThrottle, lastChannelCheckTime = Layerbounce.Handlers.ShouldThrottle(lastChannelCheckTime)
            if shouldThrottle then return end

            local msg, sender = ...
            Layerbounce.Handlers.HandleChatMessage(event, msg, sender, ...)
        elseif event == "CHAT_MSG_WHISPER" then
            local shouldThrottle
            shouldThrottle, lastWhisperCheckTime = Layerbounce.Handlers.ShouldThrottle(lastWhisperCheckTime)
            if shouldThrottle then return end

            local msg, sender = ...
            Layerbounce.Handlers.HandleChatMessage(event, msg, sender, ...)
        elseif event == "CHAT_MSG_SYSTEM" then
            local sysMsg = ...
            Layerbounce.Handlers.HandleSystemMessage(sysMsg)
        end
    end)
end

-------------------------------------------------------------------------------
-- Helper: Handle Chat Messages
-------------------------------------------------------------------------------
function Layerbounce.Handlers.HandleChatMessage(event, msg, sender, ...)
    -- Filter by channel
    if event == "CHAT_MSG_CHANNEL" then
        local channelName = select(9, ...)
        if not channelName or channelName:lower() ~= "layer" then
            Layerbounce.Handlers.DebugPrintf(
                "Message from %s ignored. Channel '%s' does not match 'layer'.", 
                sender, channelName or "Unknown"
            )
            return
        end
    end

    -- Validate the message
    local isValid = Layerbounce.Handlers.CheckIfValidLayerMessage(msg)
    if not isValid then
        Layerbounce.Handlers.DebugPrintf("Message from %s ignored. Does not contain 'layer'.", sender)
        return
    end

    -- Send the invite
    Layerbounce.Handlers.DebugPrintf("%s 'layer' from %s => invite.", event, sender)
    Layerbounce.Handlers.InviteAndNotify(sender)
end
