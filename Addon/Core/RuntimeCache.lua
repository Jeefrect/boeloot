local _, ns = ...

ns.RuntimeCache = {}

function ns.RuntimeCache:Clear()
    ns.ATTRepository:Clear()
    ns.ItemResolver:Clear()
end
