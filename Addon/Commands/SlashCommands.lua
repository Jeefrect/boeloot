local ns = select(2, ...)

ns.Commands = {}

function ns.Commands:Initialize()
    SLASH_BOELOOT1 = "/boeloot"
    SlashCmdList.BOELOOT = function(input)
        local command = strtrim(input or ""):lower()
        if command == "" then
            ns.MainWindow:Toggle()
        elseif command == "refresh" then
            ns.MainWindow:ForceRefresh()
            ns:Print(ns.L.REFRESHED)
        elseif command == "clear" then
            ns.RuntimeCache:Clear()
            ns:Print(ns.L.CACHE_CLEARED)
        elseif command == "status" then
            local status, attVersion = ns.ATTRepository:GetStatus()
            local itemCount = "-"
            if ns.JournalAdapter.journalInstanceId then
                local items = ns.ATTRepository:GetItems(ns.JournalAdapter.journalInstanceId, ns.JournalAdapter.difficultyId)
                if items then itemCount = tostring(#items) end
            end
            ns:Print(string.format("addon=%s att=%s attVersion=%s instance=%s difficulty=%s items=%s",
                ns.version,
                status,
                attVersion or "-",
                tostring(ns.JournalAdapter.journalInstanceId),
                tostring(ns.JournalAdapter.difficultyId),
                itemCount))
        else
            ns:Print(ns.L.COMMAND_HELP)
        end
    end
end
