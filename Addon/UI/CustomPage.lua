local ns = select(2, ...)

local OFFICIAL_PAGES = { "overviewScroll", "LootContainer", "detailsScroll", "model" }
local OFFICIAL_TABS = { "overviewTab", "lootTab", "bossTab", "modelTab" }

local function IsDifficultyTexture(region)
    if not region or not region.IsObjectType or not region:IsObjectType("Texture") then return false end
    local atlas = region.GetAtlas and region:GetAtlas()
    local texture = region.GetTexture and region:GetTexture()
    local marker = type(atlas) == "string" and atlas or type(texture) == "string" and texture
    if not marker then return false end
    marker = marker:lower()
    return marker:find("skull", 1, true) ~= nil or marker:find("difficulty", 1, true) ~= nil
end

ns.CustomPage = {}

function ns.CustomPage:Create(config)
    local info = EncounterJournal and EncounterJournal.encounter and EncounterJournal.encounter.info
    if not info then return nil end
    local definition = config.definition
    if not definition then return nil end

    local page = {
        config = config,
        definition = definition,
        info = info,
    }

    local frame = CreateFrame("Frame", config.frameName, info)
    frame:SetPoint("TOPLEFT", 5, 0)
    frame:SetPoint("BOTTOMRIGHT", -5, 1)
    frame:SetFrameStrata("HIGH")
    frame:Hide()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 18, -12)
    title:SetText(definition.title)
    title:SetTextColor(0.25, 0.148, 0.02)

    local selectorScrollBox = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
    selectorScrollBox:SetPoint("TOPLEFT", 12, -38)
    selectorScrollBox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 385, 8)

    local selectorScrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    selectorScrollBar:SetPoint("TOPLEFT", selectorScrollBox, "TOPRIGHT", 4, -5)
    selectorScrollBar:SetPoint("BOTTOMLEFT", selectorScrollBox, "BOTTOMRIGHT", 4, 5)

    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(32)
    view:SetPadding(3, 3, 2, config.selectorRightPadding or 2, 3)
    view:SetElementInitializer("UIPanelButtonTemplate", function(button, elementData)
        button:SetSize(315, 30)
        button:SetText(elementData.name)
        button:SetEnabled(elementData.enabled ~= false)
        button:SetScript("OnClick", function()
            if page.onButtonClick then page.onButtonClick(button.boelootPageButtonKey) end
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
        end)
        button:SetScript("OnEnter", function()
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetText(button.boelootPageButtonName, 1, 1, 1)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", GameTooltip_Hide)
        button.boelootPageButtonKey = elementData.key
        button.boelootPageButtonName = elementData.name
        button:SetButtonState("NORMAL")
        if elementData.key == page.selectedButton then button:LockHighlight() else button:UnlockHighlight() end
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(selectorScrollBox, selectorScrollBar, view)

    local itemList = ns.ItemList:Create(frame, config.itemListName, 345, 382)
    itemList.frame:SetPoint("BOTTOMRIGHT", 0, 1)

    page.frame = frame
    page.title = title
    page.selectorScrollBox = selectorScrollBox
    page.selectorScrollBar = selectorScrollBar
    page.itemList = itemList
    return page
end

local function CaptureAndHide(page, widget)
    if not widget or widget == page.frame or widget == page.info.rightShadow then return end
    if not page.officialWidgetsCaptured[widget] then
        page.officialWidgetsCaptured[widget] = true
        page.officialWidgetVisibility[widget] = widget:IsShown()
    end
    widget:Hide()
end

function ns.CustomPage:HideOfficialContent(page)
    page.officialWidgetVisibility = {}
    page.officialWidgetsCaptured = {}

    for _, child in ipairs({ page.info:GetChildren() }) do CaptureAndHide(page, child) end
    for _, region in ipairs({ page.info:GetRegions() }) do
        if IsDifficultyTexture(region) then CaptureAndHide(page, region) end
    end
    for key, widget in pairs(page.info) do
        local marker = type(key) == "string" and key:lower()
        local isDifficultyWidget = marker
            and (marker:find("skull", 1, true) or marker:find("difficulty", 1, true))
        if isDifficultyWidget and widget and widget.Hide and widget.IsShown and widget.SetShown then
            CaptureAndHide(page, widget)
        end
    end
end

function ns.CustomPage:RestoreOfficialContent(page)
    for widget, wasShown in pairs(page.officialWidgetVisibility or {}) do widget:SetShown(wasShown) end
    page.officialWidgetVisibility = nil
    page.officialWidgetsCaptured = nil
end

function ns.CustomPage:Open(page, onNavigate)
    EncounterJournal.instanceSelect:Hide()
    EncounterJournal.encounter:Show()
    EncounterJournal.instanceID = nil
    EncounterJournal.encounterID = nil

    if NavBar_Reset then
        NavBar_Reset(EncounterJournal.navBar)
        if NavBar_AddButton then
            NavBar_AddButton(EncounterJournal.navBar, {
                id = "boeloot-page-" .. page.definition.id,
                name = page.definition.title,
                OnClick = onNavigate,
            })
        end
    end

    if not page.active then self:HideOfficialContent(page) end
    page.active = true
    EncounterJournal.encounter.instance:Hide()
    if EncounterJournal_HideCreatures then EncounterJournal_HideCreatures() end
    for _, name in ipairs(OFFICIAL_PAGES) do if page.info[name] then page.info[name]:Hide() end end
    for _, name in ipairs(OFFICIAL_TABS) do if page.info[name] then page.info[name]:Hide() end end
    if page.info.BossesScrollBox then page.info.BossesScrollBox:Hide() end
    if page.info.BossesScrollBar then page.info.BossesScrollBar:Hide() end
    if page.info.difficulty then page.info.difficulty:Hide() end
    if page.info.encounterTitle then page.info.encounterTitle:Hide() end
    if page.info.rightShadow then page.info.rightShadow:Show() end
    if page.info.instanceTitle then page.info.instanceTitle:Hide() end
    if page.info.instanceButton then page.info.instanceButton:Hide() end
    if ns.MainWindow.tab then ns.MainWindow.tab:Hide() end
    page.frame:Show()
end

function ns.CustomPage:Close(page)
    if not page.active then return end
    page.active = false
    page.frame:Hide()
    for _, name in ipairs(OFFICIAL_TABS) do
        if page.info[name] then page.info[name]:SetShown(name ~= "bossTab" or page.info.overviewFound ~= false) end
    end
    if page.info.BossesScrollBox then page.info.BossesScrollBox:Show() end
    if page.info.BossesScrollBar then page.info.BossesScrollBar:Show() end
    if page.info.instanceTitle then page.info.instanceTitle:Show() end
    if page.info.instanceButton then page.info.instanceButton:Show() end
    if ns.MainWindow.tab then ns.MainWindow.tab:Show() end
    self:RestoreOfficialContent(page)
    ns.MainWindow:UpdateTabLayout()
    if EncounterJournal.instanceID and EncounterJournal_SetTab then
        EncounterJournal_SetTab(page.info.tab or 1)
    end
end

function ns.CustomPage:SetButtons(page, buttons, selectedKey, onClick)
    page.selectedButton = selectedKey
    page.onButtonClick = onClick
    local provider = CreateDataProvider()
    for _, button in ipairs(buttons or {}) do provider:Insert(button) end
    page.selectorScrollBox:SetDataProvider(provider)
end

function ns.CustomPage:SetItems(page, items, message, emptyMessage)
    page.itemList:SetItems(items, message, emptyMessage)
end
