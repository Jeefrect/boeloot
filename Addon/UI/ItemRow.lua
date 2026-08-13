local ns = select(2, ...)

ns.ItemRow = {
    HEIGHT = 64,
}

local function SetLoading(row, item)
    row.item = item
    row.itemID = item.itemId
    row.link = nil
    row.encounterID = EncounterJournal and EncounterJournal.encounterID
    row:SetHeight(ns.ItemRow.HEIGHT)
    row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    row.name:SetText(RETRIEVING_ITEM_INFO or string.format(ns.L.ITEM_FALLBACK, item.itemId))
    row.slot:SetText("")
    row.armorType:SetText("")
    row.boss:SetText(item.sourceName or ns.L.TRASH)
    row.boss:Show()
    row.bossTexture:Show()
    row.bosslessTexture:Hide()
    row.IconBorder:Hide()
    row.IconOverlay:Hide()
    row.IconOverlay2:Hide()
end

local function SetResolved(row, item, itemInfo)
    if row.item ~= item then return end
    if not itemInfo then
        row.link = item.itemString
        row.name:SetText(string.format(ns.L.ITEM_FALLBACK, item.itemId))
        if row.showingTooltip and row.link then
            GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
            EncounterJournal_SetTooltipWithCompare(GameTooltip, row.link, true)
        end
        return
    end

    local qualityColor = ITEM_QUALITY_COLORS[itemInfo.quality or Enum.ItemQuality.Common]
    local colorPrefix = qualityColor and qualityColor.hex or "|cffffffff"
    local slotName = itemInfo.equipLoc and _G[itemInfo.equipLoc] or itemInfo.equipLoc or ""
    local armorType = ""
    if C_Item.GetItemSubClassInfo and itemInfo.classId and itemInfo.subclassId then
        armorType = C_Item.GetItemSubClassInfo(itemInfo.classId, itemInfo.subclassId) or ""
    end

    row.link = itemInfo.link
    row.itemID = item.itemId
    row.icon:SetTexture(itemInfo.icon)
    row.name:SetText(colorPrefix .. (itemInfo.name or string.format(ns.L.ITEM_FALLBACK, item.itemId)) .. "|r")
    row.slot:SetText(slotName)
    row.armorType:SetText(armorType)
    SetItemButtonQuality(row, itemInfo.quality, itemInfo.link)

    if row.showingTooltip and row.link then
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        EncounterJournal_SetTooltipWithCompare(GameTooltip, row.link, true)
    end
end

function ns.ItemRow.Initialize(row, elementData)
    local item = elementData.item
    SetLoading(row, item)
    ns.ItemIdCopy:Attach(row).itemId = item.itemId
    local function OnResolved(itemInfo)
        if not item.bindingValidated and not ns.ATTItemCollector.ValidateBinding(
            item,
            itemInfo and itemInfo.bindType,
            itemInfo and itemInfo.tooltipBinding
        ) then
            if elementData.onInvalid then elementData.onInvalid(elementData) end
            return
        end
        SetResolved(row, item, itemInfo)
    end
    if item.bindingValidated then
        ns.ItemResolver:ResolveDisplay(item, OnResolved)
    else
        ns.ItemResolver:Resolve(item, OnResolved)
    end
end
