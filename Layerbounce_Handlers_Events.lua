-- Layerbounce_Handlers_Events.lua
Layerbounce = Layerbounce or {}
Layerbounce.Handlers = Layerbounce.Handlers or {}

local eventFrame = CreateFrame("Frame")
Layerbounce.Handlers.eventFrame = eventFrame

function Layerbounce.Handlers.SetupEventHandlers(addonName)
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
    eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
    eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")  -- so we can detect "X declines your invitation" if needed

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "ADDON_LOADED" then
            local name = ...
            if name == addonName then
                Layerbounce.Config.InitializeSavedVariables(addonName)
                local minimapButton = Layerbounce.Main.CreateMinimapButton()

                C_Timer.NewTicker(10, function()
                    if _G.LayerbounceSavedVariables.isAddonActive then
                        Layerbounce.Handlers.CheckAFKAndKick()
                    end
                end)

                self:UnregisterEvent("ADDON_LOADED")
            end
            return
        end

        if not _G.LayerbounceSavedVariables
           or not _G.LayerbounceSavedVariables.isAddonActive
        then
            return
        end

        if event == "CHAT_MSG_CHANNEL" then
            local msg, sender = ...
            local layerExtracted = Layerbounce.Handlers.ExtractLayerText()
            if layerExtracted then
                local currentLayer = Layerbounce.Handlers.layerText
                local priorityType = Layerbounce.Handlers.CheckLayerPriority(msg, currentLayer)
                if priorityType == "priority" then
                    Layerbounce.Handlers.DebugPrintf("PRIORITY layer request from: %s", sender)
                    Layerbounce.Handlers.AddToQueue(sender, true)
                elseif priorityType == "normal" then
                    Layerbounce.Handlers.DebugPrintf("NORMAL layer request from: %s", sender)
                    Layerbounce.Handlers.AddToQueue(sender, false)
                end
            end

        elseif event == "CHAT_MSG_WHISPER" then
            local msg, sender = ...
            Layerbounce.Handlers.HandleIncomingWhisper(msg, sender)

        elseif event == "CHAT_MSG_SYSTEM" then
            local sysMsg = ...
            -- Example: "X declines your group invitation."
            -- We'll parse that:
            local declinedPlayer = string.match(sysMsg, "^(.*) declines your group invitation")
            if declinedPlayer then
                Layerbounce.Handlers.DebugPrintf("System detected a declined invite from: %s.", declinedPlayer)
                Layerbounce.Handlers.HandleDeclinedInvite(declinedPlayer)
            end
        end
    end)
end
