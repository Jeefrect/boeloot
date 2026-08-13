local ns = select(2, ...)

local OUTDOOR_PAGE_ID = "outdoor-loot"
local OUTDOOR_ICON = "Interface\\AddOns\\boeloot\\Assets\\BoELootCard"
local repositoryErrors = {
    ["att-missing"] = ns.L.ATT_MISSING,
    ["att-disabled"] = ns.L.ATT_MISSING,
    ["att-loading"] = ns.L.ATT_LOADING,
    ["att-incompatible"] = ns.L.ATT_INCOMPATIBLE,
    ["outdoor-loading"] = ns.L.OUTDOOR_LOADING,
    ["no-outdoor-items"] = ns.L.OUTDOOR_NO_DATA,
}

ns.OutdoorPage = {
    active = false,
    selectedByExpansion = {},
}

local outdoorDefinition = {
    id = OUTDOOR_PAGE_ID,
    listType = "raid",
    title = ns.L.OUTDOOR_TITLE,
    description = ns.L.OUTDOOR_CARD_DESCRIPTION,
    icon = OUTDOOR_ICON,
}

local function AddUnique(values, seen, value)
    if not value or value == "" or seen[value] then return end
    seen[value] = true
    values[#values + 1] = value
end

local function BuildSourceLabel(item, filterKey)
    local values, seen = {}, {}
    for _, source in ipairs(item.outdoorSources or {}) do
        if filterKey == "world" and source.kind == "world" then
            AddUnique(values, seen, ns.L.WORLD_DROPS)
        elseif source.zoneKey == filterKey then
            AddUnique(values, seen, source.sourceName or source.zoneName)
        end
    end
    table.sort(values)
    if #values > 3 then
        local remaining = #values - 3
        values[4] = string.format(ns.L.MORE_SOURCES, remaining)
        for index = #values, 5, -1 do values[index] = nil end
    end
    local label = table.concat(values, ", ")
    return label ~= "" and label or ns.L.UNKNOWN
end

local function CreateDisplayItems(items, filterKey)
    local displayItems = {}
    for _, item in ipairs(items or {}) do
        displayItems[#displayItems + 1] = {
            itemId = item.itemId,
            itemString = item.itemString,
            sourceId = item.sourceId,
            modItemId = item.modItemId,
            sourceName = BuildSourceLabel(item, filterKey),
            bindingValidated = item.bindingValidated,
        }
    end
    return displayItems
end

local function GetDisplayItems(page, result, items, filterKey)
    if page.displayResult ~= result or not page.displayItemsByFilter then
        page.displayResult = result
        page.displayItemsByFilter = {}
    end
    local cacheKey = filterKey or false
    local displayItems = page.displayItemsByFilter[cacheKey]
    if not displayItems then
        displayItems = CreateDisplayItems(items, filterKey)
        page.displayItemsByFilter[cacheKey] = displayItems
    end
    return displayItems
end

local function GetSelectedExpansionId()
    local tier = EJ_GetCurrentTier and EJ_GetCurrentTier() or 1
    local serverTier = (GetServerExpansionLevel and GetServerExpansionLevel() or 0) + 1
    return math.min(tier, serverTier)
end

function ns.OutdoorPage:Initialize()
    if self.initialized then return true end
    if not EncounterJournal or not EncounterJournal.encounter then return false end
    local page = ns.CustomPage:Create({
        definition = outdoorDefinition,
        frameName = "BoelootOutdoorPage",
        itemListName = "BoelootOutdoorItemList",
        selectorRightPadding = 12,
    })
    if not page then return false end

    self.initialized = true
    self.page = page
    self.frame = page.frame
    self.itemList = page.itemList
    self.zoneScrollBox = page.selectorScrollBox
    return true
end

function ns.OutdoorPage:IsActive()
    return self.active
end

function ns.OutdoorPage:HasRememberedSelection()
    return self.rememberedExpansionId ~= nil
end

function ns.OutdoorPage:GetSelectedItems()
    if not self.result then return {} end
    if self.selectedFilter == "world" then return self.result.worldItems end
    local zone = self.result.zoneByKey[self.selectedFilter]
    return zone and zone.items or {}
end

function ns.OutdoorPage:ApplyResult(result, reason)
    if not self.active or not self.initialized then return end
    self.result = result

    local filters = {}
    for _, zone in ipairs(result and result.zones or {}) do
        filters[#filters + 1] = { key = zone.key, name = zone.name }
    end
    if result and #result.worldItems > 0 then
        filters[#filters + 1] = { key = "world", name = ns.L.WORLD_DROPS }
    end

    local selected = self.selectedByExpansion[self.expansionId]
    local validSelection = selected == "world" and result and #result.worldItems > 0
        or selected and result and result.zoneByKey[selected] ~= nil
    if not validSelection then
        selected = filters[1] and filters[1].key
    end
    self.selectedFilter = selected
    self.selectedByExpansion[self.expansionId] = selected

    ns.CustomPage:SetButtons(self.page, filters, self.selectedFilter, function(filterKey)
        self:SelectFilter(filterKey)
    end)

    local message = repositoryErrors[reason]
    local items = self:GetSelectedItems()
    if result and #items == 0 and not message then message = ns.L.OUTDOOR_FILTER_NO_DATA end
    ns.CustomPage:SetItems(
        self.page,
        GetDisplayItems(self, result, items, self.selectedFilter),
        message,
        ns.L.OUTDOOR_FILTER_NO_DATA
    )
end

function ns.OutdoorPage:Refresh()
    if not self.active or not self.initialized then return end
    local requestedExpansion = self.expansionId
    local result, reason = ns.OutdoorLootRepository:GetTierLoot(requestedExpansion)
    if result then
        self:ApplyResult(result, reason)
        return
    end

    self:ApplyResult(nil, reason)
    if self.loadingExpansion == requestedExpansion then return end
    self.loadingExpansion = requestedExpansion
    ns.OutdoorLootRepository:RequestTierLoot(requestedExpansion, function(loadedResult, loadedReason)
        if self.loadingExpansion == requestedExpansion then self.loadingExpansion = nil end
        if not self.active or self.expansionId ~= requestedExpansion then return end
        self:ApplyResult(loadedResult, loadedReason)
    end)
end

function ns.OutdoorPage:SelectFilter(filterKey)
    if not self.active then return end
    self.selectedFilter = filterKey
    self.selectedByExpansion[self.expansionId] = self.selectedFilter
    self:Refresh()
end

function ns.OutdoorPage:Open(expansionId)
    if not self:Initialize() then return false end
    ns.MainWindow:Deselect(true)

    self.active = true
    self.expansionId = expansionId
    self.rememberedExpansionId = expansionId
    ns.CustomPage:Open(self.page, function() self:Open(expansionId) end)
    self:Refresh()
    return true
end

function ns.OutdoorPage:Close(forgetSelection)
    if forgetSelection then self.rememberedExpansionId = nil end
    if not self.active then return end
    self.active = false
    self.loadingExpansion = nil
    self.result = nil
    self.displayResult = nil
    self.displayItemsByFilter = nil
    if self.page then ns.CustomPage:Close(self.page) end
    if not EncounterJournal or not EncounterJournal.encounter then return end
end

function ns.OutdoorPage:RestoreSelection()
    if not self.rememberedExpansionId or not EncounterJournal or not EncounterJournal:IsShown() then return end
    self:Open(self.rememberedExpansionId)
end

function ns.OutdoorPage:ForceRefresh()
    ns.RuntimeCache:Clear()
    self:Refresh()
    ns:Print(ns.L.OUTDOOR_REFRESHED)
end

function ns.OutdoorPage:ResetSelection()
    wipe(self.selectedByExpansion)
    self.loadingExpansion = nil
    if self.active then
        self.selectedFilter = nil
        self:Refresh()
    end
end

outdoorDefinition.getContext = function() return { expansionId = GetSelectedExpansionId() } end
outdoorDefinition.initialize = function() return ns.OutdoorPage:Initialize() end
outdoorDefinition.open = function(context) return ns.OutdoorPage:Open(context.expansionId) end
outdoorDefinition.close = function(forgetSelection) ns.OutdoorPage:Close(forgetSelection) end
outdoorDefinition.isActive = function() return ns.OutdoorPage:IsActive() end
outdoorDefinition.hasRememberedSelection = function() return ns.OutdoorPage:HasRememberedSelection() end
outdoorDefinition.restoreSelection = function() ns.OutdoorPage:RestoreSelection() end
outdoorDefinition.refresh = function() ns.OutdoorPage:Refresh() end
outdoorDefinition.forceRefresh = function() ns.OutdoorPage:ForceRefresh() end
outdoorDefinition.resetSelection = function() ns.OutdoorPage:ResetSelection() end
ns.CustomPages:Register(outdoorDefinition)
