-- Layerbounce_Handlers_Events.lua
Layerbounce = Layerbounce or {}
Layerbounce.Handlers = Layerbounce.Handlers or {}

local eventFrame = CreateFrame("Frame")
Layerbounce.Handlers.eventFrame = eventFrame

function Layerbounce.Handlers.SetupEventHandlers(addonName)
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
    eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
    -- If you want to detect "X declines your invitation", you'd parse:
    -- eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "ADDON_LOADED" then
            local name = ...
            if name == addonName then
                -- Initialize your saved variables
                Layerbounce.Config.InitializeSavedVariables(addonName)

                -- Create the minimap button now that saved vars are loaded
                local minimapButton = Layerbounce.Main.CreateMinimapButton()

                -- Start periodic AFK checks
                C_Timer.NewTicker(10, function()
                    if _G.LayerbounceSavedVariables.isAddonActive then
                        Layerbounce.Handlers.CheckAFKAndKick()
                    end
                end)

                self:UnregisterEvent("ADDON_LOADED")
            end
            return
        end

        -- If the addon is disabled, ignore other events
        if not _G.LayerbounceSavedVariables
           or not _G.LayerbounceSavedVariables.isAddonActive
        then
            return
        end

        if event == "CHAT_MSG_CHANNEL" then
            local msg, sender = ...
            if string.lower(msg or "") == "layer"
               and Layerbounce.Handlers.ExtractLayerText()
               and not Layerbounce.Handlers.ignoreList[sender]
            then
                Layerbounce.Handlers.DebugPrintf("Layer request from: %s", sender)
                Layerbounce.Handlers.InviteAndNotify(sender)
                Layerbounce.Handlers.ignoreList[sender] = true
            end

        elseif event == "CHAT_MSG_WHISPER" then
            local msg, sender = ...
            Layerbounce.Handlers.HandleIncomingWhisper(msg, sender)

        -- Example of how you might detect declined invites:
        -- elseif event == "CHAT_MSG_SYSTEM" then
        --     local sysMsg = ...
        --     local declinedPlayer = string.match(sysMsg, "^(.*) declines your group invitation")
        --     if declinedPlayer then
        --         Layerbounce.Handlers.HandleDeclinedInvite(declinedPlayer)
        --     end
        end
    end)
end
