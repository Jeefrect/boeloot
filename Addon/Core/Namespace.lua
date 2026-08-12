local addonName, ns = ...

ns.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "unknown"

function ns:Print(message)
    print("|cff53d9ffBoeloot:|r " .. tostring(message))
end
