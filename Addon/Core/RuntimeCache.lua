local ns = select(2, ...)

ns.RuntimeCache = {}

function ns.RuntimeCache:Clear()
    ns.ATTItemCollector:Clear()
    ns.ATTRepository:Clear()
    ns.OutdoorLootRepository:Clear()
    ns.OutdoorCacheStore:Clear()
    ns.InstanceCacheStore:Clear()
    ns.ItemResolver:Clear()
    ns.Events:Emit(ns.Events.RUNTIME_CACHE_CLEARED)
end
