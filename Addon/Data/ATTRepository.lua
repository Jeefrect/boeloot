local ns = select(2, ...)

local ZONE_DROPS_HEADER_ID = -63
local NODES_PER_TIME_CHECK = 5
local SLICE_MILLISECONDS = 0.75
ns.ATTRepository = {
    cache = {},
    jobs = {},
    generation = 0,
    app = nil,
    status = "att-missing",
    subscribed = false,
    runtimeIncompatible = false,
}

local function YieldIfNeeded(traversal)
    traversal.nodes = traversal.nodes + 1
    if traversal.nodes % NODES_PER_TIME_CHECK ~= 0 then return end
    if debugprofilestop() - traversal.sliceStarted < SLICE_MILLISECONDS then return end
    coroutine.yield()
    traversal.sliceStarted = debugprofilestop()
end

local function IsATTInstalled()
    if C_AddOns and C_AddOns.DoesAddOnExist then
        local ok, exists = pcall(C_AddOns.DoesAddOnExist, "AllTheThings")
        if ok then return exists end
    end
    return false
end

local function IsCompatible(app)
    return type(app) == "table"
        and type(app.SearchForObject) == "function"
        and type(app.GetDatabaseRoot) == "function"
        and type(app.ResolveSymbolicLink) == "function"
end

local function HasDatabase(app)
    local ok, root = pcall(app.GetDatabaseRoot, app)
    return ok and type(root) == "table" and type(root.g) == "table" and #root.g > 0
end

local function MatchesDifficulty(group, difficultyId)
    if not rawget(group, "difficultyID") then return true end
    if difficultyId == 0 then return false end
    local difficultyHash = ns.ATTItemCollector.SafeValue(group, "difficultyHash")
    return type(difficultyHash) == "table" and difficultyHash[difficultyId] == true
end

local function Visit(app, group, difficultyId, inZoneDrops, sourceName, items, seen, resolving, traversal)
    if type(group) ~= "table" then return end
    YieldIfNeeded(traversal)
    if not MatchesDifficulty(group, difficultyId) then return end

    if rawget(group, "headerID") == ZONE_DROPS_HEADER_ID then
        inZoneDrops = true
        sourceName = sourceName or ns.L.TRASH
    elseif ns.ATTItemCollector.HasNamedSource(group) then
        sourceName = ns.ATTItemCollector.GetName(group) or sourceName
    end

    if inZoneDrops then
        ns.ATTItemCollector.AddItem(items, seen, ns.ATTItemCollector.NormalizeItem(app, group, sourceName))
    end

    local children = rawget(group, "g")
    for _, child in ipairs(children or {}) do
        Visit(app, child, difficultyId, inZoneDrops, sourceName, items, seen, resolving, traversal)
    end

    local shouldResolve = rawget(group, "sym") and (
        inZoneDrops
        or rawget(group, "instanceID") ~= nil
        or rawget(group, "difficultyID") ~= nil
    )
    if shouldResolve then
        local resolveKey = ns.ATTItemCollector.SafeValue(group, "hash") or group
        if resolving[resolveKey] then return end
        resolving[resolveKey] = true
        local ok, resolved = pcall(app.ResolveSymbolicLink, group)
        if ok then
            for _, child in ipairs(resolved or {}) do
                Visit(app, child, difficultyId, inZoneDrops, sourceName, items, seen, resolving, traversal)
            end
        end
        resolving[resolveKey] = nil
    end
end

function ns.ATTRepository:Detect()
    local app = rawget(_G, "AllTheThings") or rawget(_G, "ATTC")
    if app ~= self.app then self.runtimeIncompatible = false end
    if not app then
        self.app = nil
        self.status = IsATTInstalled() and "att-disabled" or "att-missing"
        return false
    end
    if app == self.app and self.status == "ready" and not self.runtimeIncompatible then return true end
    if not IsCompatible(app) then
        self.app = app
        self.status = "att-incompatible"
        return false
    end
    if self.runtimeIncompatible then
        self.app = app
        self.status = "att-incompatible"
        return false
    end

    self.app = app
    self.status = HasDatabase(app) and "ready" or "att-loading"

    if self.status ~= "ready" and not self.subscribed and type(app.AddEventHandler) == "function" then
        self.subscribed = true
        app.AddEventHandler("OnLoad", function()
            self.subscribed = false
            self:Detect()
            self:Clear()
            ns.Events:Emit(ns.Events.ATT_DATA_READY)
        end)
    end
    return self.status == "ready"
end

function ns.ATTRepository:Initialize()
    self:Detect()
end

function ns.ATTRepository:GetStatus()
    self:Detect()
    return self.status, self.app and self.app.Version or nil
end

local function GetCacheKey(journalInstanceId, difficultyId)
    return tostring(journalInstanceId) .. ":" .. tostring(difficultyId or 0)
end

local function GetCachedResult(repository, journalInstanceId, difficultyId)
    local cacheKey = GetCacheKey(journalInstanceId, difficultyId)
    local result = repository.cache[cacheKey]
    return result, cacheKey
end

local function BuildItems(app, instances, difficultyId)
    local items, seen = {}, {}
    local traversal = { nodes = 0, sliceStarted = debugprofilestop() }
    for _, instance in ipairs(instances) do
        Visit(app, instance, difficultyId or 0, false, nil, items, seen, {}, traversal)
    end
    ns.ATTItemCollector.SortItems(items)
    return {
        items = items,
        reason = #items == 0 and "no-items" or nil,
    }
end

local function BuildInstanceResult(app, journalInstanceId, difficultyId)
    local instances
    local ok = false
    if type(app.GetRawField) == "function" then
        local rawResults
        ok, rawResults = pcall(app.GetRawField, "instanceID", journalInstanceId)
        if ok and type(rawResults) == "table" then
            instances = {}
            for _, instance in ipairs(rawResults) do
                if ns.ATTItemCollector.SafeValue(instance, "instanceID") == journalInstanceId
                    and ns.ATTItemCollector.SafeValue(instance, "key") == "instanceID" then
                    instances[#instances + 1] = instance
                end
            end
        end
    end
    if not instances then
        ok, instances = pcall(app.SearchForObject, "instanceID", journalInstanceId, "key", true)
    end
    if not ok then return nil, "att-incompatible" end
    if type(instances) ~= "table" or #instances == 0 then
        return { items = {}, reason = "instance-missing" }
    end
    return BuildItems(app, instances, difficultyId)
end

local function HasValidatedBindings(items)
    for _, item in ipairs(items or {}) do
        if item.bindingValidated ~= true then return false end
    end
    return true
end

function ns.ATTRepository:GetApp()
    if not self:Detect() then return nil, self.status end
    return self.app
end

function ns.ATTRepository:GetDatabaseRoot()
    local app, reason = self:GetApp()
    if not app then return nil, reason end
    local ok, root = pcall(app.GetDatabaseRoot, app)
    if not ok or type(root) ~= "table" then
        self.runtimeIncompatible = true
        self.status = "att-incompatible"
        return nil, self.status
    end
    return root
end

function ns.ATTRepository:GetItems(journalInstanceId, difficultyId)
    if not self:Detect() then return nil, self.status end

    local cached = GetCachedResult(self, journalInstanceId, difficultyId)
    if cached then return cached.items, cached.reason end

    return nil, "instance-loading"
end

function ns.ATTRepository:RequestItems(journalInstanceId, difficultyId, callback)
    local cached, cacheKey = GetCachedResult(self, journalInstanceId, difficultyId)
    if cached then
        callback(cached.items, cached.reason)
        return
    end

    local existing = self.jobs[cacheKey]
    if existing then
        existing.callbacks[#existing.callbacks + 1] = callback
        return
    end

    local job = {
        callbacks = { callback },
        generation = self.generation,
        thread = coroutine.create(function()
            if ns.InstanceCacheStore
                and ns.InstanceCacheStore:HasSnapshot(journalInstanceId, difficultyId) then
                local stored = ns.InstanceCacheStore:Load(journalInstanceId, difficultyId, true)
                if stored then return stored, nil, true end
            end

            local app, appReason = self:GetApp()
            if not app then return nil, appReason, false end
            local result, buildReason = BuildInstanceResult(app, journalInstanceId, difficultyId)
            return result, buildReason, false
        end),
    }
    self.jobs[cacheKey] = job

    local function Resume()
        if self.jobs[cacheKey] ~= job or job.generation ~= self.generation then return end
        local okResume, result, failureReason, restored = coroutine.resume(job.thread)
        if not okResume then
            self.jobs[cacheKey] = nil
            self.runtimeIncompatible = true
            self.status = "att-incompatible"
            for _, listener in ipairs(job.callbacks) do listener(nil, self.status) end
            return
        end
        if coroutine.status(job.thread) ~= "dead" then
            C_Timer.After(0, Resume)
            return
        end

        if failureReason then
            self.jobs[cacheKey] = nil
            if failureReason == "att-incompatible" then self.runtimeIncompatible = true end
            self.status = failureReason
            for _, listener in ipairs(job.callbacks) do listener(nil, failureReason) end
            return
        end

        local function Publish(saveSnapshot)
            self.jobs[cacheKey] = nil
            self.cache[cacheKey] = result
            if saveSnapshot and ns.InstanceCacheStore then
                ns.InstanceCacheStore:Save(journalInstanceId, difficultyId, result)
            end
            for _, listener in ipairs(job.callbacks) do listener(result.items, result.reason) end
        end

        if result.reason == "instance-missing" then
            Publish(not restored)
            return
        end

        if restored and HasValidatedBindings(result.items) then
            Publish(false)
            return
        end

        ns.ATTItemCollector.ValidateItems(result.items, function()
            return self.jobs[cacheKey] == job and job.generation == self.generation
        end, function(validItems)
            if self.jobs[cacheKey] ~= job or job.generation ~= self.generation then return end
            result.items = validItems
            result.reason = #validItems == 0 and "no-items" or nil
            Publish(true)
        end)
    end

    C_Timer.After(0, Resume)
end

function ns.ATTRepository:Clear()
    self.generation = self.generation + 1
    wipe(self.cache)
    wipe(self.jobs)
    self.runtimeIncompatible = false
end
