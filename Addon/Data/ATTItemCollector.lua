local ns = select(2, ...)

local BIND_ON_EQUIP = 2
local TOOLTIP_BIND_ON_EQUIP = 7
local VALIDATION_ITEMS_PER_SLICE = 8
local VALIDATION_SLICE_MILLISECONDS = 1

ns.ATTItemCollector = { rejectedBindings = {} }

function ns.ATTItemCollector.SafeValue(group, key)
    local ok, value = pcall(function() return group[key] end)
    if ok then return value end
end

function ns.ATTItemCollector.GetRelativeValue(group, key, visited)
    if type(group) ~= "table" then return end
    visited = visited or {}
    if visited[group] then return end
    visited[group] = true

    local value = ns.ATTItemCollector.SafeValue(group, key)
    if value ~= nil then return value end
    return ns.ATTItemCollector.GetRelativeValue(
        rawget(group, "sourceParent") or rawget(group, "parent"), key, visited)
end

function ns.ATTItemCollector.GetName(group)
    local name = ns.ATTItemCollector.SafeValue(group, "name")
        or ns.ATTItemCollector.SafeValue(group, "text")
    if type(name) == "string" and name ~= "" then return name end
end

function ns.ATTItemCollector.HasNamedSource(group)
    return rawget(group, "encounterID")
        or rawget(group, "npcID")
        or rawget(group, "creatureID")
        or rawget(group, "questID")
        or rawget(group, "objectID")
        or rawget(group, "headerID")
end

local function IsEquippableGear(app, group, itemId)
    local _, _, _, equipLoc, _, classId = C_Item.GetItemInfoInstant(itemId)
    local gearClass = classId == Enum.ItemClass.Armor or classId == Enum.ItemClass.Weapon
    if gearClass and equipLoc and equipLoc ~= "" then return true end

    local filterId = ns.ATTItemCollector.SafeValue(group, "filterID")
    return filterId and type(app.EquipmentFilters) == "table" and app.EquipmentFilters[filterId] == true
end

local function GetItemString(group, itemId)
    local link = ns.ATTItemCollector.SafeValue(group, "link")
    return rawget(group, "rawlink") or link or ("item:" .. itemId)
end

local function IsBindOnEquip(group, itemString)
    local bindType = select(14, C_Item.GetItemInfo(itemString))
    if bindType ~= nil then return bindType == BIND_ON_EQUIP end

    local attBindType = ns.ATTItemCollector.SafeValue(group, "b")
    return attBindType == nil or attBindType == BIND_ON_EQUIP
end

function ns.ATTItemCollector.NormalizeItem(app, group, sourceName)
    local itemId = rawget(group, "itemID")
    if not itemId or not IsEquippableGear(app, group, itemId) then return end

    local itemString = GetItemString(group, itemId)
    if ns.ATTItemCollector.rejectedBindings[itemString] then return end
    if not IsBindOnEquip(group, itemString) then return end

    return {
        itemId = itemId,
        itemString = itemString,
        sourceId = rawget(group, "sourceID"),
        modItemId = ns.ATTItemCollector.SafeValue(group, "modItemID"),
        sourceName = sourceName or ns.L.UNKNOWN,
    }
end

function ns.ATTItemCollector.ValidateBinding(item, bindType, tooltipBinding)
    local isBindOnEquip = (tooltipBinding ~= nil and tooltipBinding == TOOLTIP_BIND_ON_EQUIP)
        or (tooltipBinding == nil and bindType == BIND_ON_EQUIP)
    if isBindOnEquip then return true end
    ns.ATTItemCollector.rejectedBindings[item.itemString or ("item:" .. item.itemId)] = true
    return false
end

function ns.ATTItemCollector.ValidateItems(items, isCurrent, callback)
    items = items or {}
    local itemCount = #items
    local allowed = {}
    local index, pending = 1, 0
    local schedulingComplete = false

    local function FinishIfReady()
        if not schedulingComplete or pending > 0 or not isCurrent() then return end
        local filtered = {}
        for _, item in ipairs(items) do
            if allowed[ns.ATTItemCollector.GetItemKey(item)] then filtered[#filtered + 1] = item end
        end
        callback(filtered)
    end

    local function ScheduleBatch()
        if not isCurrent() then return end
        local sliceStarted = debugprofilestop()
        local scheduled = 0
        while index <= itemCount and scheduled < VALIDATION_ITEMS_PER_SLICE do
            local item = items[index]
            index = index + 1
            scheduled = scheduled + 1
            pending = pending + 1
            ns.ItemResolver:Resolve(item, function(itemInfo)
                if ns.ATTItemCollector.ValidateBinding(
                    item,
                    itemInfo and itemInfo.bindType,
                    itemInfo and itemInfo.tooltipBinding
                ) then
                    item.bindingValidated = true
                    allowed[ns.ATTItemCollector.GetItemKey(item)] = true
                end
                pending = pending - 1
                FinishIfReady()
            end)
            if debugprofilestop() - sliceStarted >= VALIDATION_SLICE_MILLISECONDS then break end
        end

        if index <= itemCount then
            C_Timer.After(0, ScheduleBatch)
        else
            schedulingComplete = true
            FinishIfReady()
        end
    end

    ScheduleBatch()
end

function ns.ATTItemCollector.Clear()
    wipe(ns.ATTItemCollector.rejectedBindings)
end

function ns.ATTItemCollector.GetItemKey(item)
    if item.sourceId then return "source:" .. item.sourceId end
    if item.modItemId then return "mod:" .. item.modItemId end
    return "item:" .. item.itemId
end

function ns.ATTItemCollector.AddItem(items, seen, item)
    if not item then return end
    local key = ns.ATTItemCollector.GetItemKey(item)
    if seen[key] then return seen[key], false end
    seen[key] = item
    items[#items + 1] = item
    return item, true
end

function ns.ATTItemCollector.SortItems(items)
    table.sort(items, function(left, right)
        if left.itemId ~= right.itemId then return left.itemId < right.itemId end
        if left.sourceId ~= right.sourceId then return (left.sourceId or 0) < (right.sourceId or 0) end
        if left.modItemId ~= right.modItemId then return (left.modItemId or 0) < (right.modItemId or 0) end
        return left.itemString < right.itemString
    end)
end
