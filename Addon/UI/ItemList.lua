local ns = select(2, ...)

ns.ItemList = {}

local SYNCHRONOUS_ITEM_LIMIT = 20
local ITEMS_PER_SLICE = 20
local SLICE_MILLISECONDS = 1

function ns.ItemList:Create(parent, name, width, height)
    local frame = CreateFrame("Frame", name, parent)
    frame:SetSize(width, height)

    local scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT")
    scrollBox:SetPoint("BOTTOMRIGHT", -20, 0)

    local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 5, -5)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 5, 5)

    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(ns.ItemRow.HEIGHT)
    view:SetElementInitializer("EncounterItemTemplate", ns.ItemRow.Initialize)
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    local message = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    message:SetPoint("CENTER", scrollBox, "CENTER", 0, 12)
    message:SetWidth(width - 45)
    message:SetJustifyH("CENTER")
    message:SetTextColor(0.25, 0.148, 0.02)
    message:Hide()

    local list = { frame = frame, scrollBox = scrollBox, scrollBar = scrollBar, message = message }

    function list:SetItems(items, messageText, emptyMessage)
        if self.hasData and self.sourceItems == items and self.messageText == messageText
            and self.emptyMessage == emptyMessage then
            return
        end
        self.hasData = true
        self.sourceItems = items
        self.messageText = messageText
        self.emptyMessage = emptyMessage
        self.generation = (self.generation or 0) + 1
        local generation = self.generation
        items = items or {}
        local itemCount = #items
        local finalMessage = itemCount > 0 and nil or messageText
        self.items = {}
        local dataProvider = CreateDataProvider()

        local function InsertItem(item)
            self.items[#self.items + 1] = item
            local elementData = { item = item }
            elementData.onInvalid = function(invalidData)
                C_Timer.After(0, function()
                    if self.generation ~= generation then return end
                    local remaining = {}
                    for _, current in ipairs(self.items) do
                        if current ~= invalidData.item then remaining[#remaining + 1] = current end
                    end
                    local nextMessage = #remaining == 0 and (finalMessage or emptyMessage) or finalMessage
                    self:SetItems(remaining, nextMessage, emptyMessage)
                end)
            end
            dataProvider:Insert(elementData)
        end

        local function Publish()
            if self.generation ~= generation then return end
            self.scrollBox:SetDataProvider(dataProvider)
            self.message:SetText(finalMessage or "")
            self.message:SetShown(finalMessage ~= nil and #self.items == 0)
        end

        if itemCount <= SYNCHRONOUS_ITEM_LIMIT then
            for _, item in ipairs(items) do InsertItem(item) end
            Publish()
            return
        end

        self.scrollBox:SetDataProvider(CreateDataProvider())
        local preparingMessage = messageText or RETRIEVING_ITEM_INFO
        self.message:SetText(preparingMessage or "")
        self.message:SetShown(preparingMessage ~= nil)

        local index = 1
        local function BuildSlice()
            if self.generation ~= generation then return end
            local sliceStarted = debugprofilestop()
            local inserted = 0
            while index <= itemCount and inserted < ITEMS_PER_SLICE do
                InsertItem(items[index])
                index = index + 1
                inserted = inserted + 1
                if debugprofilestop() - sliceStarted >= SLICE_MILLISECONDS then break end
            end
            if index <= itemCount then
                C_Timer.After(0, BuildSlice)
            else
                Publish()
            end
        end

        C_Timer.After(0, BuildSlice)
    end

    return list
end
