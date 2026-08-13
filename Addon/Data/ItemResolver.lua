local ns = select(2, ...)

ns.ItemResolver = {
    cache = {},
    pending = {},
    queue = {},
    queueHead = 1,
    active = {},
    inFlight = 0,
    maxInFlight = 5,
}

local function GetTooltipBinding(itemInfo)
    if not C_TooltipInfo or not C_TooltipInfo.GetHyperlink then return end
    local ok, tooltip = pcall(C_TooltipInfo.GetHyperlink, itemInfo)
    if not ok or type(tooltip) ~= "table" then return end
    for _, line in ipairs(tooltip.lines or {}) do
        if line.bonding ~= nil then return line.bonding end
    end
end

local function ReadItem(item, includeBinding)
    local itemInfo = item.itemString or item.itemId
    local name, link, quality, itemLevel, minLevel, itemType, itemSubType, stackCount,
        equipLoc, icon, sellPrice, classId, subclassId, bindType = C_Item.GetItemInfo(itemInfo)
    if not name then return nil end
    local result = {
        name = name,
        link = link,
        quality = quality,
        equipLoc = equipLoc,
        icon = icon,
        classId = classId,
        subclassId = subclassId,
    }
    if includeBinding then
        result.bindType = bindType
        result.tooltipBinding = GetTooltipBinding(link or itemInfo)
        result.bindingResolved = true
    end
    return result
end

local function Resolve(itemResolver, item, callback, includeBinding)
    local key = item.itemString or tostring(item.itemId)
    local cached = itemResolver.cache[key]
    if cached and (not includeBinding or cached.bindingResolved) then
        callback(cached)
        return
    end

    local resolved = ReadItem(item, includeBinding)
    if resolved then
        itemResolver.cache[key] = resolved
        callback(resolved)
        return
    end
    itemResolver.pending[item.itemId] = itemResolver.pending[item.itemId] or {}
    local pending = itemResolver.pending[item.itemId]
    pending[#pending + 1] = {
        key = key,
        item = item,
        callback = callback,
        includeBinding = includeBinding,
    }
    if not itemResolver.active[item.itemId] then
        itemResolver.active[item.itemId] = "queued"
        itemResolver.queue[#itemResolver.queue + 1] = item.itemId
        itemResolver:Pump()
    end
end

function ns.ItemResolver:Resolve(item, callback)
    Resolve(self, item, callback, true)
end

function ns.ItemResolver:ResolveDisplay(item, callback)
    Resolve(self, item, callback, false)
end

function ns.ItemResolver:Pump()
    local queueLength = #self.queue
    while self.inFlight < self.maxInFlight and self.queueHead <= queueLength do
        local itemId = self.queue[self.queueHead]
        self.queueHead = self.queueHead + 1
        if self.active[itemId] == "queued" then
            self.active[itemId] = "inflight"
            self.inFlight = self.inFlight + 1
            C_Item.RequestLoadItemDataByID(itemId)
        end
    end
    if self.queueHead > queueLength then
        wipe(self.queue)
        self.queueHead = 1
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
            local result = success ~= false and ReadItem(request.item, request.includeBinding) or nil
            if result and (result.bindingResolved or not (self.cache[request.key] or {}).bindingResolved) then
                self.cache[request.key] = result
            end
            request.callback(result)
        end
    end
    self:Pump()
end

function ns.ItemResolver:Clear()
    wipe(self.cache)
    wipe(self.pending)
    wipe(self.queue)
    self.queueHead = 1
    for itemId, state in pairs(self.active) do
        if state == "queued" then self.active[itemId] = nil end
    end
end
