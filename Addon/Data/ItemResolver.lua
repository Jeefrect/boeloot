local _, ns = ...

ns.ItemResolver = {
    cache = {},
    pending = {},
    queue = {},
    active = {},
    inFlight = 0,
    maxInFlight = 5,
}

local function ReadItem(item)
    local itemInfo = item.itemString or item.itemId
    local name, link, quality, _, _, _, _, _, equipLoc, icon, _, classId, subclassId = C_Item.GetItemInfo(itemInfo)
    if not name then return nil end
    return {
        name = name,
        link = link,
        quality = quality,
        equipLoc = equipLoc,
        icon = icon,
        classId = classId,
        subclassId = subclassId,
    }
end

function ns.ItemResolver:Resolve(item, callback)
    local key = item.itemString or tostring(item.itemId)
    if self.cache[key] then
        callback(self.cache[key])
        return
    end

    local resolved = ReadItem(item)
    if resolved then
        self.cache[key] = resolved
        callback(resolved)
        return
    end
    self.pending[item.itemId] = self.pending[item.itemId] or {}
    self.pending[item.itemId][#self.pending[item.itemId] + 1] = { key = key, item = item, callback = callback }
    if not self.active[item.itemId] then
        self.active[item.itemId] = "queued"
        self.queue[#self.queue + 1] = item.itemId
        self:Pump()
    end
end

function ns.ItemResolver:Pump()
    while self.inFlight < self.maxInFlight and #self.queue > 0 do
        local itemId = table.remove(self.queue, 1)
        if self.active[itemId] == "queued" then
            self.active[itemId] = "inflight"
            self.inFlight = self.inFlight + 1
            C_Item.RequestLoadItemDataByID(itemId)
        end
    end
end

function ns.ItemResolver:OnItemDataLoadResult(itemId, success)
    if self.active[itemId] ~= "inflight" then return end

    self.active[itemId] = nil
    self.inFlight = math.max(0, self.inFlight - 1)
    local callbacks = self.pending[itemId]
    self.pending[itemId] = nil
    if callbacks then
        for _, request in ipairs(callbacks) do
            local result = success ~= false and ReadItem(request.item) or nil
            if result then self.cache[request.key] = result end
            request.callback(result)
        end
    end
    self:Pump()
end

function ns.ItemResolver:Clear()
    wipe(self.cache)
    wipe(self.pending)
    wipe(self.queue)
    for itemId, state in pairs(self.active) do
        if state == "queued" then self.active[itemId] = nil end
    end
end
