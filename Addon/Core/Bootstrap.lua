local addonName, ns = ...

local function RefreshWindow()
    if ns.MainWindow.frame then ns.MainWindow:Refresh() end
end

ns.Events:Register(ns.Events.ATT_DATA_READY, RefreshWindow)

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ITEM_DATA_LOAD_RESULT")

events:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            ns.ATTRepository:Initialize()
            ns.Commands:Initialize()
            if C_AddOns.IsAddOnLoaded("Blizzard_EncounterJournal") then ns.JournalAdapter:Initialize() end
        elseif loadedAddon == "Blizzard_EncounterJournal" then
            ns.JournalAdapter:Initialize()
        end
    elseif event == "PLAYER_LOGIN" then
        ns.ATTRepository:Detect()
        RefreshWindow()
    elseif event == "ITEM_DATA_LOAD_RESULT" then
        local itemId, success = ...
        ns.ItemResolver:OnItemDataLoadResult(itemId, success)
    end
end)
