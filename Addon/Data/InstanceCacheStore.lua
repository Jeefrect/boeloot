local ns = select(2, ...)

ns.InstanceCacheStore = {}

local ITEMS_PER_TIME_CHECK = 20
local SLICE_MILLISECONDS = 1

local function YieldIfNeeded(traversal)
    traversal.items = traversal.items + 1
    if not traversal.canYield or traversal.items % ITEMS_PER_TIME_CHECK ~= 0 then return end
    if debugprofilestop() - traversal.sliceStarted < SLICE_MILLISECONDS then return end
    coroutine.yield()
    traversal.sliceStarted = debugprofilestop()
end

local function GetCacheKey(journalInstanceId, difficultyId)
    return tostring(journalInstanceId) .. ":" .. tostring(difficultyId or 0)
end

local function CopyItem(item)
    return {
        itemId = item.itemId,
        itemString = item.itemString,
        sourceId = item.sourceId,
        modItemId = item.modItemId,
        sourceName = item.sourceName,
        bindingValidated = item.bindingValidated == true,
    }
end

function ns.InstanceCacheStore:Initialize()
    self.db = ns.PersistentCache:GetCollection("instances")
end

function ns.InstanceCacheStore:EnsureReady()
    self.db = ns.PersistentCache:GetCollection("instances")
end

function ns.InstanceCacheStore:Save(journalInstanceId, difficultyId, result)
    self:EnsureReady()
    if type(result) ~= "table" or type(result.items) ~= "table" then return end
    local snapshot = { items = {}, reason = result.reason }
    for _, item in ipairs(result.items) do snapshot.items[#snapshot.items + 1] = CopyItem(item) end
    self.db[GetCacheKey(journalInstanceId, difficultyId)] = snapshot
end

function ns.InstanceCacheStore:HasSnapshot(journalInstanceId, difficultyId)
    self:EnsureReady()
    local snapshot = self.db[GetCacheKey(journalInstanceId, difficultyId)]
    return type(snapshot) == "table" and type(snapshot.items) == "table"
end

function ns.InstanceCacheStore:Load(journalInstanceId, difficultyId, allowYield)
    self:EnsureReady()
    local snapshot = self.db[GetCacheKey(journalInstanceId, difficultyId)]
    if type(snapshot) ~= "table" or type(snapshot.items) ~= "table" then return end

    local items = {}
    local traversal = {
        items = 0,
        sliceStarted = debugprofilestop(),
        canYield = allowYield == true,
    }
    for _, item in ipairs(snapshot.items) do
        YieldIfNeeded(traversal)
        if type(item) == "table" and item.itemId and item.itemString then
            items[#items + 1] = CopyItem(item)
        end
    end
    return {
        items = items,
        reason = snapshot.reason or (#items == 0 and "no-items" or nil),
    }
end

function ns.InstanceCacheStore:Clear()
    self:EnsureReady()
    wipe(self.db)
end
