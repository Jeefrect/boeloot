local ns = select(2, ...)

local OFFICIAL_PAGES = { "overviewScroll", "LootContainer", "detailsScroll", "model" }
local OFFICIAL_TABS = { "overviewTab", "lootTab", "bossTab", "modelTab" }

ns.MainWindow = {
    selected = false,
}

local repositoryErrors = {
    ["att-missing"] = ns.L.ATT_MISSING,
    ["att-disabled"] = ns.L.ATT_MISSING,
    ["att-loading"] = ns.L.ATT_LOADING,
    ["att-incompatible"] = ns.L.ATT_INCOMPATIBLE,
    ["instance-loading"] = ns.L.INSTANCE_LOADING,
    ["instance-missing"] = ns.L.ATT_INSTANCE_MISSING,
    ["no-items"] = ns.L.NO_DATA,
}

local function GetContextKey(journalInstanceId, difficultyId)
    return tostring(journalInstanceId) .. ":" .. tostring(difficultyId or 0)
end

function ns.MainWindow:CreateTab(info)
    local tab = CreateFrame("Button", "BoelootEncounterJournalTab", info, "EncounterTabTemplate")
    tab:SetID(5)
    tab:ClearAllPoints()
    tab:SetPoint("TOP", info.lootTab, "BOTTOM", 0, 2)
    tab.tooltip = ns.L.TAB_TOOLTIP

    tab.unselected = tab:CreateTexture(nil, "OVERLAY")
    tab.unselected:SetPoint("RIGHT", -6, 0)
    ns.UI.CopyTexture(tab.unselected, info.lootTab.unselected)

    tab.selected = tab:CreateTexture(nil, "OVERLAY")
    tab.selected:SetPoint("CENTER", tab.unselected, "CENTER")
    ns.UI.CopyTexture(tab.selected, info.lootTab.selected)

    local label = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER", tab.unselected, "CENTER", 0, -14)
    label:SetText("BoE")
    label:SetTextColor(0.2, 1, 0.45)
    tab.label = label

    tab:SetScript("OnClick", function()
        self:Select()
        PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
    end)
    ns.UI.SetTabSelected(tab, false)
    self.tab = tab
end

function ns.MainWindow:CreatePage(info)
    local frame = CreateFrame("Frame", "BoelootEncounterJournalPage", info)
    frame:SetSize(345, 382)
    frame:SetPoint("BOTTOMRIGHT", -5, 1)
    frame:SetFrameStrata("HIGH")
    frame:Hide()

    local itemList = ns.ItemList:Create(frame, "BoelootEncounterJournalItemList", 345, 382)
    itemList.frame:SetPoint("BOTTOMRIGHT", -5, 1)

    local refreshButton = CreateFrame("Button", "BoelootEncounterJournalRefreshButton", EncounterJournal, "RefreshButtonTemplate")
    refreshButton:SetPoint("TOPLEFT", EncounterJournal, "TOPRIGHT", 8, -34)
    refreshButton:SetFrameStrata(EncounterJournal:GetFrameStrata())
    refreshButton:SetFrameLevel(EncounterJournal:GetFrameLevel() + 10)
    refreshButton:SetScript("OnClick", function()
        if ns.CustomPages and ns.CustomPages:IsActive() then
            ns.CustomPages:ForceRefreshActive()
        else
            self:ForceRefresh()
        end
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end)
    refreshButton:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText(REFRESH or "Refresh", 1, 1, 1)
        GameTooltip:AddLine(ns.L.REFRESH_TOOLTIP, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    refreshButton:SetScript("OnLeave", GameTooltip_Hide)

    frame:SetScript("OnShow", function()
        if EncounterJournal_HideCreatures then EncounterJournal_HideCreatures() end
        EncounterJournal.encounter.instance:Hide()
        info.rightShadow:Show()
        info.encounterTitle:Hide()
    end)

    self.frame = frame
    self.itemList = itemList
    self.scrollBox = itemList.scrollBox
    self.refreshButton = refreshButton
    self.message = itemList.message
end

function ns.MainWindow:Initialize()
    if self.initialized then return true end
    if not EncounterJournal or not EncounterJournal.encounter then return false end
    local info = EncounterJournal.encounter.info
    if not info or not info.lootTab or not info.LootContainer then return false end

    self.initialized = true
    self:CreateTab(info)
    self:CreatePage(info)

    for _, tabName in ipairs(OFFICIAL_TABS) do
        local officialTab = info[tabName]
        if officialTab then
            officialTab:HookScript("OnMouseDown", function(button)
                button.boelootUserClick = true
            end)
            officialTab:HookScript("OnClick", function(button)
                local userClick = button.boelootUserClick
                button.boelootUserClick = nil
                self:Deselect(userClick)
                self:UpdateTabLayout()
            end)
            officialTab:HookScript("OnLeave", function(button)
                button.boelootUserClick = nil
            end)
        end
    end

    self:UpdateTabLayout()
    self:SetContext(EncounterJournal.instanceID, EJ_GetDifficulty and EJ_GetDifficulty() or 0)
    return true
end

function ns.MainWindow:UpdateTabLayout()
    if not self.initialized then return end
    local info = EncounterJournal.encounter.info

    self.tab:ClearAllPoints()
    self.tab:SetPoint("TOP", info.lootTab, "BOTTOM", 0, 2)

    if info.bossTab then
        info.bossTab:ClearAllPoints()
        info.bossTab:SetPoint("TOP", self.tab, "BOTTOM", 0, 2)
    end
    if info.modelTab then
        info.modelTab:ClearAllPoints()
        info.modelTab:SetPoint("TOP", info.bossTab:IsShown() and info.bossTab or self.tab, "BOTTOM", 0, 2)
    end
end

function ns.MainWindow:Deselect(forgetSelection)
    if not self.initialized then return end
    self.selected = false
    if forgetSelection then self.remembered = false end
    self.frame:Hide()
    ns.UI.SetTabSelected(self.tab, false)
end

function ns.MainWindow:Select()
    if not self.initialized and not self:Initialize() then return end
    if not EncounterJournal.instanceID then
        ns:Print(ns.L.NO_INSTANCE)
        return
    end

    local info = EncounterJournal.encounter.info
    if ns.CustomPages then ns.CustomPages:CloseActive(true) end
    self.selected = true
    self.remembered = true
    for _, frameName in ipairs(OFFICIAL_PAGES) do
        if info[frameName] then info[frameName]:Hide() end
    end
    for _, tabName in ipairs(OFFICIAL_TABS) do
        if info[tabName] then ns.UI.SetTabSelected(info[tabName], false) end
    end
    ns.UI.SetTabSelected(self.tab, true)
    self.frame:Show()
    if info.difficulty then info.difficulty:SetShown(EncounterJournal.instanceID ~= nil) end
    self:UpdateTabLayout()
    local changed = self:SetContext(
        EncounterJournal.instanceID,
        EJ_GetDifficulty and EJ_GetDifficulty() or 0
    )
    if not changed then self:Refresh() end
end

function ns.MainWindow:RestoreSelection()
    if not self.remembered or not EncounterJournal or not EncounterJournal:IsShown() then return end
    if not EncounterJournal.instanceID or not EncounterJournal.encounter:IsShown() then return end
    self:Select()
end

function ns.MainWindow:SetContext(journalInstanceId, difficultyId)
    difficultyId = difficultyId or 0
    local changed = self.journalInstanceId ~= journalInstanceId or self.difficultyId ~= difficultyId
    self.journalInstanceId = journalInstanceId
    self.difficultyId = difficultyId
    if self.initialized and self.selected and changed then self:Refresh() end
    return changed
end

function ns.MainWindow:Refresh()
    if not self.initialized or not self.selected then return end

    local message
    local items
    if not self.journalInstanceId then
        message = ns.L.NO_INSTANCE
        items = {}
    else
        local reason
        local requestedInstance = self.journalInstanceId
        local requestedDifficulty = self.difficultyId
        items, reason = ns.ATTRepository:GetItems(requestedInstance, requestedDifficulty)
        items = items or {}
        message = repositoryErrors[reason]
        if reason == "instance-loading" then
            local requestKey = GetContextKey(requestedInstance, requestedDifficulty)
            if self.loadingContextKey ~= requestKey then
                self.loadingContextKey = requestKey
                ns.ATTRepository:RequestItems(requestedInstance, requestedDifficulty, function()
                    if self.loadingContextKey == requestKey then self.loadingContextKey = nil end
                    if not self.selected or self.journalInstanceId ~= requestedInstance
                    or self.difficultyId ~= requestedDifficulty
                    then
                        return
                    end
                    self:Refresh()
                end)
            end
        end
    end
    self.itemList:SetItems(items, message, ns.L.NO_DATA)
end

function ns.MainWindow:ForceRefresh()
    self.loadingContextKey = nil
    ns.RuntimeCache:Clear()
    self:Refresh()
end

function ns.MainWindow:ResetLoadingState()
    self.loadingContextKey = nil
end

function ns.MainWindow:Toggle()
    local customPageActive = ns.CustomPages and ns.CustomPages:IsActive()
    if (self.selected or customPageActive) and EncounterJournal and EncounterJournal:IsShown() then
        HideUIPanel(EncounterJournal)
    else
        ns.JournalAdapter:OpenBoETab()
    end
end
