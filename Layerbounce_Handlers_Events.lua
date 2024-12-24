-- Layerbounce_Handlers_Events.lua
Layerbounce = Layerbounce or {}
Layerbounce.Handlers = Layerbounce.Handlers or {}

local eventFrame = CreateFrame("Frame", "LayerbounceEventFrame")
local addonLoaded = false

-- Throttling: Only process chat events every 5 seconds
local lastChatCheckTime = 0
local CHAT_THROTTLE_SECONDS = 5

function Layerbounce.Handlers.SetupEventHandlers(addonName)
    -- Register all events we need
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
    eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
    eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        -- 1) ADDON_LOADED => Our addon has finished loading
        if event == "ADDON_LOADED" and not addonLoaded then
            local loadedAddonName = ...
            -- Make sure it's actually "Layerbounce" (or whatever your .toc 'Name' is)
            if loadedAddonName == addonName then
                self:UnregisterEvent("ADDON_LOADED")
                addonLoaded = true

                -- Initialize saved variables
                Layerbounce.Config.InitializeSavedVariables(addonName)

                -- Print confirmation to chat
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Layerbounce] Addon successfully loaded!")

                -- Create the minimap button (assuming you do so here—some folks do it in Layerbounce.lua)
                local minimapButton = Layerbounce.Main.CreateMinimapButton()

                -- Check AFK status every 10 seconds
                C_Timer.NewTicker(10, function()
                    if _G.LayerbounceSavedVariables.isAddonActive then
                        Layerbounce.Handlers.CheckAFKAndKick()
                    end
                end)
            end
            return
        end

        -- 2) If the addon is toggled off, skip further event processing
        if not _G.LayerbounceSavedVariables
           or not _G.LayerbounceSavedVariables.isAddonActive
        then
            return
        end

        -- 3) CHAT_MSG_CHANNEL / CHAT_MSG_WHISPER => Check if enough time has passed
        if event == "CHAT_MSG_CHANNEL" or event == "CHAT_MSG_WHISPER" then
            local now = GetTime()
            if (now - lastChatCheckTime) < CHAT_THROTTLE_SECONDS then
                return
            end
            lastChatCheckTime = now
        end

        -- 4) Handle specific chat events
        if event == "CHAT_MSG_CHANNEL" then
            local msg, sender = ...
            local layerExtracted = Layerbounce.Handlers.ExtractLayerText()
            if layerExtracted then
                local valid, numbers = Layerbounce.Handlers.CheckIfValidLayerMessage(msg)
                if valid then
                    local currentLayer = Layerbounce.Handlers.layerText
                    -- If "layer" has no numbers, always invite
                    if #numbers == 0 then
                        Layerbounce.Handlers.DebugPrintf("Detected 'layer' from %s => invite.", sender)
                        Layerbounce.Handlers.InviteAndNotify(sender)
                    else
                        -- Only invite if our layer matches one of the numbers
                        for _, num in ipairs(numbers) do
                            if tostring(num) == tostring(currentLayer) then
                                Layerbounce.Handlers.DebugPrintf(
                                    "Detected 'layer %s' from %s => matches our layer => invite",
                                    num, sender
                                )
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
                        Layerbounce.Handlers.DebugPrintf("Whispered 'layer' from %s => invite.", sender)
                        Layerbounce.Handlers.InviteAndNotify(sender)
                    else
                        for _, num in ipairs(numbers) do
                            if tostring(num) == tostring(currentLayer) then
                                Layerbounce.Handlers.DebugPrintf(
                                    "Whispered 'layer %s' from %s => matches our layer => invite",
                                    num, sender
                                )
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
                Layerbounce.Handlers.DebugPrintf(
                    "Detected a declined invite from: %s.", 
                    declinedPlayer
                )
                Layerbounce.Handlers.HandleDeclinedInvite(declinedPlayer)
            end
        end
    end)
end
