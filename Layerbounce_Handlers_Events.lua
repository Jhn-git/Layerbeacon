-- Layerbounce_Handlers_Events.lua
Layerbounce = Layerbounce or {}
Layerbounce.Handlers = Layerbounce.Handlers or {}

local eventFrame = CreateFrame("Frame")
Layerbounce.Handlers.eventFrame = eventFrame

--------------------------------------------------------------------------------
-- Throttling: Only process chat events every 5 seconds
--------------------------------------------------------------------------------
local lastChatCheckTime = 0
local CHAT_THROTTLE_SECONDS = 5

function Layerbounce.Handlers.SetupEventHandlers(addonName)
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
    eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
    eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "ADDON_LOADED" then
            local name = ...
            if name == addonName then
                Layerbounce.Config.InitializeSavedVariables(addonName)
                local minimapButton = Layerbounce.Main.CreateMinimapButton()

                -- Check AFK every 10 seconds
                C_Timer.NewTicker(10, function()
                    if _G.LayerbounceSavedVariables.isAddonActive then
                        Layerbounce.Handlers.CheckAFKAndKick()
                    end
                end)

                self:UnregisterEvent("ADDON_LOADED")
            end
            return
        end

        -- If addon is off, do nothing
        if not _G.LayerbounceSavedVariables
           or not _G.LayerbounceSavedVariables.isAddonActive
        then
            return
        end

        if event == "CHAT_MSG_CHANNEL" or event == "CHAT_MSG_WHISPER" then
            local now = GetTime()
            if (now - lastChatCheckTime) < CHAT_THROTTLE_SECONDS then
                -- less than 5s since last process => skip
                return
            end
            lastChatCheckTime = now
        end

        if event == "CHAT_MSG_CHANNEL" then
            local msg, sender = ...
            local layerExtracted = Layerbounce.Handlers.ExtractLayerText()
            if layerExtracted then
                local valid, numbers = Layerbounce.Handlers.CheckIfValidLayerMessage(msg)
                if valid then
                    local currentLayer = Layerbounce.Handlers.layerText
                    -- If no numbers, invite anyway
                    if #numbers == 0 then
                        Layerbounce.Handlers.DebugPrintf("Detected 'layer' from %s. No numbers => invite.", sender)
                        Layerbounce.Handlers.InviteAndNotify(sender)
                    else
                        -- If our layer is among the numbers
                        for _, num in ipairs(numbers) do
                            if tostring(num) == tostring(currentLayer) then
                                Layerbounce.Handlers.DebugPrintf("Detected 'layer %s' from %s => matches our layer => invite", num, sender)
                                Layerbounce.Handlers.InviteAndNotify(sender)
                                break
                            end
                        end
                    end
                end
            end

        elseif event == "CHAT_MSG_WHISPER" then
            local msg, sender = ...
            local layerExtracted = Layerbounce.Handlers.ExtractLayerText()
            if layerExtracted then
                local valid, numbers = Layerbounce.Handlers.CheckIfValidLayerMessage(msg)
                if valid then
                    local currentLayer = Layerbounce.Handlers.layerText
                    if #numbers == 0 then
                        -- They just typed "layer"
                        Layerbounce.Handlers.DebugPrintf("Whispered 'layer' from %s => invite.", sender)
                        Layerbounce.Handlers.InviteAndNotify(sender)
                    else
                        for _, num in ipairs(numbers) do
                            if tostring(num) == tostring(currentLayer) then
                                Layerbounce.Handlers.DebugPrintf("Whispered 'layer %s' from %s => matches our layer => invite", num, sender)
                                Layerbounce.Handlers.InviteAndNotify(sender)
                                break
                            end
                        end
                    end
                end
            end

        elseif event == "CHAT_MSG_SYSTEM" then
            local sysMsg = ...
            -- Example: "X declines your group invitation."
            local declinedPlayer = string.match(sysMsg, "^(.*) declines your group invitation")
            if declinedPlayer then
                Layerbounce.Handlers.DebugPrintf("Detected a declined invite from: %s.", declinedPlayer)
                Layerbounce.Handlers.HandleDeclinedInvite(declinedPlayer)
            end
        end
    end)
end
