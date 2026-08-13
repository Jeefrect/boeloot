local ns = select(2, ...)

ns.OutdoorCacheStore = {}

local VALUES_PER_TIME_CHECK = 20
local SLICE_MILLISECONDS = 1

local function YieldIfNeeded(traversal)
    traversal.values = traversal.values + 1
    if not traversal.canYield or traversal.values % VALUES_PER_TIME_CHECK ~= 0 then return end
    if debugprofilestop() - traversal.sliceStarted < SLICE_MILLISECONDS then return end
    coroutine.yield()
    traversal.sliceStarted = debugprofilestop()
end

local function CopySources(sources, traversal)
    local copy = {}
    for _, source in ipairs(sources or {}) do
        if traversal then YieldIfNeeded(traversal) end
        copy[#copy + 1] = {
            kind = source.kind,
            zoneKey = source.zoneKey,
            zoneName = source.zoneName,
            sourceName = source.sourceName,
        }
    end
    return copy
end

local function CopyItem(item, traversal)
    return {
        itemId = item.itemId,
        itemString = item.itemString,
        sourceId = item.sourceId,
        modItemId = item.modItemId,
        sourceName = item.sourceName,
        bindingValidated = item.bindingValidated == true,
        outdoorSources = CopySources(item.outdoorSources, traversal),
    }
end

function ns.OutdoorCacheStore:Initialize()
    self.db = ns.PersistentCache:GetCollection("expansions")
end

function ns.OutdoorCacheStore:EnsureReady()
    self.db = ns.PersistentCache:GetCollection("expansions")
end

function ns.OutdoorCacheStore:Save(expansionId, result)
    self:EnsureReady()
    if type(result) ~= "table" then return end

    local snapshot = { items = {}, allItemKeys = {}, zones = {}, worldItemKeys = {} }
    for _, item in ipairs(result.allItems or {}) do
        local key = ns.ATTItemCollector.GetItemKey(item)
        snapshot.items[key] = CopyItem(item)
        snapshot.allItemKeys[#snapshot.allItemKeys + 1] = key
    end
    for _, zone in ipairs(result.zones or {}) do
        local savedZone = { key = zone.key, mapId = zone.mapId, name = zone.name, itemKeys = {} }
        for _, item in ipairs(zone.items or {}) do
            savedZone.itemKeys[#savedZone.itemKeys + 1] = ns.ATTItemCollector.GetItemKey(item)
        end
        snapshot.zones[#snapshot.zones + 1] = savedZone
    end
    for _, item in ipairs(result.worldItems or {}) do
        snapshot.worldItemKeys[#snapshot.worldItemKeys + 1] = ns.ATTItemCollector.GetItemKey(item)
    end
    self.db[tostring(expansionId)] = snapshot
end

function ns.OutdoorCacheStore:HasSnapshot(expansionId)
    self:EnsureReady()
    local snapshot = self.db[tostring(expansionId)]
    return type(snapshot) == "table" and type(snapshot.items) == "table"
end

local function ResolveItems(keys, itemsByKey, traversal)
    local items = {}
    for _, key in ipairs(keys or {}) do
        YieldIfNeeded(traversal)
        local item = itemsByKey[key]
        if item then items[#items + 1] = item end
    end
    return items
end

function ns.OutdoorCacheStore:Load(expansionId, allowYield)
    self:EnsureReady()
    local snapshot = self.db[tostring(expansionId)]
    if type(snapshot) ~= "table" or type(snapshot.items) ~= "table" then return end

    local itemsByKey = {}
    local traversal = {
        values = 0,
        sliceStarted = debugprofilestop(),
        canYield = allowYield == true,
    }
    for key, item in pairs(snapshot.items) do
        YieldIfNeeded(traversal)
        if type(item) == "table" and item.itemId and item.itemString then
            itemsByKey[key] = CopyItem(item, traversal)
        end
    end

    local result = {
        expansionId = tonumber(expansionId) or 1,
        zones = {},
        zoneByKey = {},
        allItems = ResolveItems(snapshot.allItemKeys, itemsByKey, traversal),
        worldItems = ResolveItems(snapshot.worldItemKeys, itemsByKey, traversal),
    }
    for _, savedZone in ipairs(snapshot.zones or {}) do
        YieldIfNeeded(traversal)
        local zone = {
            key = savedZone.key,
            mapId = savedZone.mapId,
            name = savedZone.name,
            items = ResolveItems(savedZone.itemKeys, itemsByKey, traversal),
        }
        if zone.key and zone.name and #zone.items > 0 then
            result.zones[#result.zones + 1] = zone
            result.zoneByKey[zone.key] = zone
        end
    end
    result.reason = #result.allItems == 0 and "no-outdoor-items" or nil
    return result
end

function ns.OutdoorCacheStore:Clear()
    self:EnsureReady()
    wipe(self.db)
end
