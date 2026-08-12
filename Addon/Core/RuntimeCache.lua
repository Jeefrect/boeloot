local ns = select(2, ...)

ns.RuntimeCache = {}

function ns.RuntimeCache:Clear()
    ns.ATTRepository:Clear()
    ns.ItemResolver:Clear()
end
