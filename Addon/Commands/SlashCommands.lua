local ns = select(2, ...)

ns.Commands = {}

function ns.Commands:Initialize()
    SLASH_BOELOOT1 = "/boeloot"
    SlashCmdList.BOELOOT = function(input)
        local command = strtrim(input or ""):lower()
        if command == "" then
            ns.MainWindow:Toggle()
        elseif command == "refresh" then
            if ns.OutdoorPage and ns.OutdoorPage:IsActive() then
                ns.OutdoorPage:ForceRefresh()
            else
                ns.MainWindow:ForceRefresh()
                ns:Print(ns.L.REFRESHED)
            end
        elseif command == "clear" then
            ns.RuntimeCache:Clear()
            ns:Print(ns.L.CACHE_CLEARED)
        elseif command == "status" then
            local status, attVersion = ns.ATTRepository:GetStatus()
            local itemCount = "-"
            local zoneCount = "-"
            local mode = ns.OutdoorPage and ns.OutdoorPage:IsActive() and "outdoor" or "instance"
            if mode == "outdoor" then
                itemCount = tostring(#ns.OutdoorPage:GetSelectedItems())
                zoneCount = tostring(ns.OutdoorPage.result and #ns.OutdoorPage.result.zones or 0)
            elseif ns.JournalAdapter.journalInstanceId then
                local items = ns.ATTRepository:GetItems(ns.JournalAdapter.journalInstanceId, ns.JournalAdapter.difficultyId)
                if items then itemCount = tostring(#items) end
            end
            ns:Print(string.format("addon=%s att=%s attVersion=%s mode=%s instance=%s difficulty=%s expansion=%s filter=%s zones=%s items=%s",
                ns.version,
                status,
                attVersion or "-",
                mode,
                tostring(ns.JournalAdapter.journalInstanceId),
                tostring(ns.JournalAdapter.difficultyId),
                tostring(ns.OutdoorPage and ns.OutdoorPage.expansionId),
                tostring(ns.OutdoorPage and ns.OutdoorPage.selectedFilter),
                zoneCount,
                itemCount))
        else
            ns:Print(ns.L.COMMAND_HELP)
        end
    end
end
