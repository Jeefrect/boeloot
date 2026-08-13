local ns = select(2, ...)

local ZONES_HEADER_ID = -732
local WORLD_DROPS_HEADER_ID = -698
local RARES_HEADER_ID = -46
local VENDORS_HEADER_ID = -58
local WORLD_BOSSES_HEADER_ID = -61
local ZONE_DROPS_HEADER_ID = -63
local ZONE_REWARDS_HEADER_ID = -64
local CLASSIC_AWP = 10000

ns.OutdoorLootRepository = { cache = {}, jobs = {}, generation = 0 }

local IsRepeatableObject

local function YieldIfNeeded(traversal)
    traversal.nodes = traversal.nodes + 1
    if traversal.nodes % 20 ~= 0 then return end
    if debugprofilestop() - traversal.sliceStarted < 1.5 then return end
    coroutine.yield()
    traversal.sliceStarted = debugprofilestop()
end

local function IsUnavailable(group)
    local value = ns.ATTItemCollector.SafeValue(group, "u")
    return type(value) == "number" and value <= 2
end

local function IsExcludedBranch(group)
    local headerId = rawget(group, "headerID")
    local isQuest = rawget(group, "questID") ~= nil
        and rawget(group, "npcID") == nil
        and rawget(group, "creatureID") == nil
        and not IsRepeatableObject(group)
    return rawget(group, "instanceID") ~= nil
        or isQuest
        or rawget(group, "professionID") ~= nil
        or rawget(group, "requireSkill") ~= nil
        or rawget(group, "cost") ~= nil
        or headerId == VENDORS_HEADER_ID
        or IsUnavailable(group)
end

local function GetExpansionId(group)
    local awp = ns.ATTItemCollector.GetRelativeValue(group, "awp") or CLASSIC_AWP
    if type(awp) ~= "number" then return 1 end
    return math.max(1, math.floor(awp / 10000))
end

IsRepeatableObject = function(group)
    return rawget(group, "objectID") and (
        rawget(group, "repeatable")
        or rawget(group, "isDaily")
        or rawget(group, "isWeekly")
    )
end

local function IsLootContext(group, inherited)
    local headerId = rawget(group, "headerID")
    if headerId == ZONE_DROPS_HEADER_ID or headerId == ZONE_REWARDS_HEADER_ID
        or headerId == RARES_HEADER_ID or headerId == WORLD_BOSSES_HEADER_ID then
        return true
    end
    return inherited or rawget(group, "npcID") ~= nil or rawget(group, "creatureID") ~= nil
        or IsRepeatableObject(group)
end

local function GetZone(group, currentZone)
    local mapId = rawget(group, "mapID")
    if not mapId then return currentZone end
    local name = ns.ATTItemCollector.GetName(group)
    if not name then return currentZone end
    return { key = "zone:" .. mapId, mapId = mapId, name = name }
end

local function FindRootCategory(root, headerId)
    for _, group in ipairs(rawget(root, "g") or {}) do
        if rawget(group, "headerID") == headerId then return group end
    end
end

local function AddSource(item, source)
    item.outdoorSources = item.outdoorSources or {}
    item.outdoorSourceKeys = item.outdoorSourceKeys or {}
    local key = source.kind .. ":" .. (source.zoneKey or "") .. ":" .. (source.sourceName or "")
    if item.outdoorSourceKeys[key] then return end
    item.outdoorSourceKeys[key] = true
    item.outdoorSources[#item.outdoorSources + 1] = source
end

local function GetOrCreateZone(result, zoneData)
    local zone = result.zoneByKey[zoneData.key]
    if zone then return zone end
    zone = {
        key = zoneData.key,
        mapId = zoneData.mapId,
        name = zoneData.name,
        items = {},
        seen = {},
    }
    result.zoneByKey[zone.key] = zone
    result.zones[#result.zones + 1] = zone
    return zone
end

local function AddOutdoorItem(result, app, group, expansionId, zoneData, sourceName, kind)
    if kind ~= "world" and GetExpansionId(group) ~= expansionId then return end
    local normalized = ns.ATTItemCollector.NormalizeItem(app, group, sourceName)
    if not normalized then return end
    if kind ~= "world" and not zoneData then return end

    local key = ns.ATTItemCollector.GetItemKey(normalized)
    local item = result.itemByKey[key]
    if not item then
        item = normalized
        result.itemByKey[key] = item
        result.allItems[#result.allItems + 1] = item
    end

    if kind == "world" then
        AddSource(item, { kind = "world", sourceName = ns.L.WORLD_DROPS })
        if not result.worldSeen[key] then
            result.worldSeen[key] = true
            result.worldItems[#result.worldItems + 1] = item
        end
        return
    end

    local zone = GetOrCreateZone(result, zoneData)
    AddSource(item, {
        kind = "zone",
        zoneKey = zone.key,
        zoneName = zone.name,
        sourceName = sourceName or zone.name,
    })
    if not zone.seen[key] then
        zone.seen[key] = true
        zone.items[#zone.items + 1] = item
    end
end

local function VisitZones(result, app, group, expansionId, zoneData, lootContext, sourceName, resolving, traversal)
    if type(group) ~= "table" or IsExcludedBranch(group) then return end
    YieldIfNeeded(traversal)

    zoneData = GetZone(group, zoneData)
    lootContext = IsLootContext(group, lootContext)
    if ns.ATTItemCollector.HasNamedSource(group) then
        sourceName = ns.ATTItemCollector.GetName(group) or sourceName
    end
    if lootContext then
        AddOutdoorItem(result, app, group, expansionId, zoneData, sourceName, "zone")
    end

    for _, child in ipairs(rawget(group, "g") or {}) do
        VisitZones(result, app, child, expansionId, zoneData, lootContext, sourceName, resolving, traversal)
    end

    if rawget(group, "sym") then
        local resolveKey = ns.ATTItemCollector.SafeValue(group, "hash") or group
        if resolving[resolveKey] then return end
        resolving[resolveKey] = true
        local ok, resolved = pcall(app.ResolveSymbolicLink, group)
        if ok then
            for _, child in ipairs(resolved or {}) do
                VisitZones(result, app, child, expansionId, zoneData, lootContext, sourceName, resolving, traversal)
            end
        end
        resolving[resolveKey] = nil
    end
end

local function VisitWorldDrops(result, app, group, expansionId, selectedExpansion, resolving, traversal)
    if type(group) ~= "table" or IsUnavailable(group) then return end
    YieldIfNeeded(traversal)
    if not selectedExpansion and rawget(group, "expansionID") then
        if rawget(group, "expansionID") ~= expansionId then return end
        selectedExpansion = true
    end

    if selectedExpansion then
        AddOutdoorItem(result, app, group, expansionId, nil, ns.L.WORLD_DROPS, "world")
    end
    for _, child in ipairs(rawget(group, "g") or {}) do
        VisitWorldDrops(result, app, child, expansionId, selectedExpansion, resolving, traversal)
    end

    if rawget(group, "sym") then
        local resolveKey = ns.ATTItemCollector.SafeValue(group, "hash") or group
        if resolving[resolveKey] then return end
        resolving[resolveKey] = true
        local ok, resolved = pcall(app.ResolveSymbolicLink, group)
        if ok then
            for _, child in ipairs(resolved or {}) do
                VisitWorldDrops(result, app, child, expansionId, selectedExpansion, resolving, traversal)
            end
        end
        resolving[resolveKey] = nil
    end
end

local function BuildTierLoot(app, root, expansionId)
    local result = {
        expansionId = expansionId,
        zones = {},
        zoneByKey = {},
        worldItems = {},
        allItems = {},
        itemByKey = {},
        worldSeen = {},
    }
    local traversal = { nodes = 0, sliceStarted = debugprofilestop() }
    local zonesRoot = FindRootCategory(root, ZONES_HEADER_ID)
    local worldRoot = FindRootCategory(root, WORLD_DROPS_HEADER_ID)
    if zonesRoot then VisitZones(result, app, zonesRoot, expansionId, nil, false, nil, {}, traversal) end
    if worldRoot then VisitWorldDrops(result, app, worldRoot, expansionId, false, {}, traversal) end

    table.sort(result.zones, function(left, right)
        local leftName, rightName = left.name:lower(), right.name:lower()
        if leftName ~= rightName then return leftName < rightName end
        return left.mapId < right.mapId
    end)
    ns.ATTItemCollector.SortItems(result.allItems)
    ns.ATTItemCollector.SortItems(result.worldItems)
    for _, item in ipairs(result.allItems) do item.outdoorSourceKeys = nil end
    for _, zone in ipairs(result.zones) do
        ns.ATTItemCollector.SortItems(zone.items)
        zone.seen = nil
    end
    result.itemByKey = nil
    result.worldSeen = nil
    result.reason = #result.allItems == 0 and "no-outdoor-items" or nil
    return result, result.reason
end

local function FilterItems(items, allowed)
    local filtered = {}
    for _, item in ipairs(items or {}) do
        if allowed[ns.ATTItemCollector.GetItemKey(item)] then
            filtered[#filtered + 1] = item
        end
    end
    return filtered
end

local function FinalizeBindings(result, allowed)
    result.allItems = FilterItems(result.allItems, allowed)
    result.worldItems = FilterItems(result.worldItems, allowed)

    local zones, zoneByKey = {}, {}
    for _, zone in ipairs(result.zones) do
        zone.items = FilterItems(zone.items, allowed)
        if #zone.items > 0 then
            zones[#zones + 1] = zone
            zoneByKey[zone.key] = zone
        end
    end
    result.zones = zones
    result.zoneByKey = zoneByKey
    result.reason = #result.allItems == 0 and "no-outdoor-items" or nil
    return result, result.reason
end

local function ValidateBindings(result, isCurrent, callback)
    ns.ATTItemCollector.ValidateItems(result.allItems, isCurrent, function(validItems)
        local allowed = {}
        for _, item in ipairs(validItems) do allowed[ns.ATTItemCollector.GetItemKey(item)] = true end
        callback(FinalizeBindings(result, allowed))
    end)
end

local function HasValidatedBindings(items)
    for _, item in ipairs(items or {}) do
        if item.bindingValidated ~= true then return false end
    end
    return true
end

function ns.OutdoorLootRepository:GetTierLoot(expansionId)
    expansionId = tonumber(expansionId) or 1
    local result = self.cache[expansionId]
    return result, result and result.reason or "outdoor-loading"
end

function ns.OutdoorLootRepository:RequestTierLoot(expansionId, callback)
    expansionId = tonumber(expansionId) or 1
    local cached = select(1, self:GetTierLoot(expansionId))
    if cached then
        callback(cached, cached.reason)
        return
    end

    local existing = self.jobs[expansionId]
    if existing then
        existing.callbacks[#existing.callbacks + 1] = callback
        return
    end

    local job = {
        callbacks = { callback },
        generation = self.generation,
        thread = coroutine.create(function()
            if ns.OutdoorCacheStore and ns.OutdoorCacheStore:HasSnapshot(expansionId) then
                local stored = ns.OutdoorCacheStore:Load(expansionId, true)
                if stored then return stored, nil, true end
            end

            local app, appReason = ns.ATTRepository:GetApp()
            if not app then return nil, appReason, false end
            local root, rootReason = ns.ATTRepository:GetDatabaseRoot()
            if not root then return nil, rootReason, false end
            local result = BuildTierLoot(app, root, expansionId)
            return result, nil, false
        end),
    }
    self.jobs[expansionId] = job

    local function Resume()
        if self.jobs[expansionId] ~= job or job.generation ~= self.generation then return end
        local ok, result, failureReason, restored = coroutine.resume(job.thread)
        if not ok then
            self.jobs[expansionId] = nil
            for _, listener in ipairs(job.callbacks) do listener(nil, "att-incompatible") end
            return
        end
        if coroutine.status(job.thread) ~= "dead" then
            C_Timer.After(0, Resume)
            return
        end

        if failureReason then
            self.jobs[expansionId] = nil
            for _, listener in ipairs(job.callbacks) do listener(nil, failureReason) end
            return
        end

        local function Publish(validatedResult, validatedReason, saveSnapshot)
            self.jobs[expansionId] = nil
            self.cache[expansionId] = validatedResult
            if saveSnapshot and ns.OutdoorCacheStore then
                ns.OutdoorCacheStore:Save(expansionId, validatedResult)
            end
            for _, listener in ipairs(job.callbacks) do listener(validatedResult, validatedReason) end
        end

        if restored and HasValidatedBindings(result.allItems) then
            Publish(result, result.reason, false)
            return
        end

        ValidateBindings(result, function()
            return self.jobs[expansionId] == job and job.generation == self.generation
        end, function(validatedResult, validatedReason)
            if self.jobs[expansionId] ~= job or job.generation ~= self.generation then return end
            Publish(validatedResult, validatedReason, true)
        end)
    end

    C_Timer.After(0, Resume)
end

function ns.OutdoorLootRepository:Clear()
    self.generation = self.generation + 1
    wipe(self.cache)
    wipe(self.jobs)
end
