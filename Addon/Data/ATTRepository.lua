local _, ns = ...

local ZONE_DROPS_HEADER_ID = -63

ns.ATTRepository = {
    cache = {},
    app = nil,
    status = "att-missing",
    subscribed = false,
    runtimeIncompatible = false,
}

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

local function SafeValue(group, key)
    local ok, value = pcall(function() return group[key] end)
    if ok then return value end
end

local function HasNamedSource(group)
    return rawget(group, "encounterID")
        or rawget(group, "npcID")
        or rawget(group, "creatureID")
        or rawget(group, "questID")
        or rawget(group, "objectID")
        or rawget(group, "headerID")
end

local function GetSourceName(group)
    local name = SafeValue(group, "name") or SafeValue(group, "text")
    if type(name) == "string" and name ~= "" then return name end
end

local function MatchesDifficulty(group, difficultyId)
    if not rawget(group, "difficultyID") then return true end
    if difficultyId == 0 then return false end
    local difficultyHash = SafeValue(group, "difficultyHash")
    return type(difficultyHash) == "table" and difficultyHash[difficultyId] == true
end

local function IsEquippableGear(app, group, itemId)
    local _, _, _, equipLoc, _, classId = C_Item.GetItemInfoInstant(itemId)
    local gearClass = classId == Enum.ItemClass.Armor or classId == Enum.ItemClass.Weapon
    if gearClass and equipLoc and equipLoc ~= "" then return true end

    local filterId = SafeValue(group, "filterID")
    return filterId and type(app.EquipmentFilters) == "table" and app.EquipmentFilters[filterId] == true
end

local function GetItemString(group, itemId)
    local link = SafeValue(group, "link")
    return rawget(group, "rawlink") or link or ("item:" .. itemId)
end

local function NormalizeItem(app, group, sourceName)
    local itemId = rawget(group, "itemID")
    if not itemId or not IsEquippableGear(app, group, itemId) then return end

    local sourceId = rawget(group, "sourceID")
    local modItemId = SafeValue(group, "modItemID")
    return {
        itemId = itemId,
        itemString = GetItemString(group, itemId),
        sourceId = sourceId,
        modItemId = modItemId,
        sourceName = sourceName or ns.L.UNKNOWN,
    }
end

local function AddItem(items, seen, item)
    if not item then return end
    local key
    if item.sourceId then
        key = "source:" .. item.sourceId
    elseif item.modItemId then
        key = "mod:" .. item.modItemId
    else
        key = "item:" .. item.itemId
    end
    if seen[key] then return end
    seen[key] = true
    items[#items + 1] = item
end

local function Visit(app, group, difficultyId, inZoneDrops, sourceName, items, seen, resolving)
    if type(group) ~= "table" or not MatchesDifficulty(group, difficultyId) then return end

    if rawget(group, "headerID") == ZONE_DROPS_HEADER_ID then
        inZoneDrops = true
        sourceName = sourceName or ns.L.TRASH
    elseif HasNamedSource(group) then
        sourceName = GetSourceName(group) or sourceName
    end

    if inZoneDrops then
        AddItem(items, seen, NormalizeItem(app, group, sourceName))
    end

    local children = rawget(group, "g")
    for _, child in ipairs(children or {}) do
        Visit(app, child, difficultyId, inZoneDrops, sourceName, items, seen, resolving)
    end

    local resolveKey = SafeValue(group, "hash") or group
    if rawget(group, "sym") and not resolving[resolveKey] then
        resolving[resolveKey] = true
        local ok, resolved = pcall(app.ResolveSymbolicLink, group)
        if ok then
            for _, child in ipairs(resolved or {}) do
                Visit(app, child, difficultyId, inZoneDrops, sourceName, items, seen, resolving)
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

function ns.ATTRepository:GetItems(journalInstanceId, difficultyId)
    if not self:Detect() then return nil, self.status end

    local cacheKey = tostring(journalInstanceId) .. ":" .. tostring(difficultyId or 0)
    local cached = self.cache[cacheKey]
    if cached then return cached.items, cached.reason end

    local ok, instances = pcall(self.app.SearchForObject, "instanceID", journalInstanceId, "key", true)
    if not ok then
        self.runtimeIncompatible = true
        self.status = "att-incompatible"
        return nil, self.status
    end
    if type(instances) ~= "table" or #instances == 0 then return {}, "instance-missing" end

    local items, seen = {}, {}
    for _, instance in ipairs(instances) do
        Visit(self.app, instance, difficultyId or 0, false, nil, items, seen, {})
    end
    table.sort(items, function(left, right)
        if left.itemId ~= right.itemId then return left.itemId < right.itemId end
        if left.sourceId ~= right.sourceId then return (left.sourceId or 0) < (right.sourceId or 0) end
        if left.modItemId ~= right.modItemId then return (left.modItemId or 0) < (right.modItemId or 0) end
        return left.itemString < right.itemString
    end)

    local result = {
        items = items,
        reason = #items == 0 and "no-items" or nil,
    }
    self.cache[cacheKey] = result
    return result.items, result.reason
end

function ns.ATTRepository:Clear()
    wipe(self.cache)
    self.runtimeIncompatible = false
end
