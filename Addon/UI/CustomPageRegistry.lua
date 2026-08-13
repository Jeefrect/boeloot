local ns = select(2, ...)

ns.CustomPages = {
    definitions = {},
    ordered = {},
}

local function ForgetOtherSelections(registry, exceptDefinition)
    for _, definition in ipairs(registry.ordered) do
        if definition ~= exceptDefinition
            and definition.hasRememberedSelection
            and definition.hasRememberedSelection()
        then
            definition.close(true)
        end
    end
end

function ns.CustomPages:Register(definition)
    assert(type(definition) == "table", "Custom page definition must be a table")
    assert(type(definition.id) == "string" and definition.id ~= "", "Custom page id is required")
    assert(not self.definitions[definition.id], "Duplicate custom page id: " .. definition.id)
    assert(definition.listType == "raid" or definition.listType == "dungeon", "Custom page listType is invalid")
    assert(type(definition.title) == "string", "Custom page title is required")
    assert(type(definition.description) == "string", "Custom page description is required")
    assert(type(definition.icon) == "string", "Custom page icon is required")
    assert(type(definition.open) == "function", "Custom page open callback is required")
    assert(type(definition.close) == "function", "Custom page close callback is required")
    self.definitions[definition.id] = definition
    self.ordered[#self.ordered + 1] = definition
end

function ns.CustomPages:Get(id)
    return self.definitions[id]
end

function ns.CustomPages:GetDefinitions(listType)
    local result = {}
    for _, definition in ipairs(self.ordered) do
        if not listType or definition.listType == listType then result[#result + 1] = definition end
    end
    return result
end

function ns.CustomPages:Initialize()
    for _, definition in ipairs(self.ordered) do
        if definition.initialize and definition.initialize() == false then return false end
    end
    return true
end

function ns.CustomPages:Open(id)
    local definition = self.definitions[id]
    if not definition then return false end
    if self.activeId and self.activeId ~= id then self:CloseActive(true) end
    ForgetOtherSelections(self, definition)
    self.activeId = id
    local context = definition.getContext and definition.getContext() or nil
    if definition.open(context) == false then
        self.activeId = nil
        return false
    end
    return true
end

function ns.CustomPages:IsActive()
    local definition = self.activeId and self.definitions[self.activeId]
    return definition and (not definition.isActive or definition.isActive()) or false
end

function ns.CustomPages:GetActive()
    return self.activeId and self.definitions[self.activeId] or nil
end

function ns.CustomPages:CloseActive(forgetSelection)
    local definition = self:GetActive()
    self.activeId = nil
    if definition then definition.close(forgetSelection) end
    if forgetSelection then ForgetOtherSelections(self, definition) end
end

function ns.CustomPages:HasRememberedSelection()
    for _, definition in ipairs(self.ordered) do
        if definition.hasRememberedSelection and definition.hasRememberedSelection() then return true end
    end
    return false
end

function ns.CustomPages:RestoreSelection()
    for _, definition in ipairs(self.ordered) do
        if definition.hasRememberedSelection and definition.hasRememberedSelection() then
            self.activeId = definition.id
            if definition.restoreSelection then definition.restoreSelection() end
            return
        end
    end
end

function ns.CustomPages:ForceRefreshActive()
    local definition = self:GetActive()
    if definition and definition.forceRefresh then definition.forceRefresh() end
end

function ns.CustomPages:ResetSelections()
    for _, definition in ipairs(self.ordered) do
        if definition.resetSelection then definition.resetSelection() end
    end
end
