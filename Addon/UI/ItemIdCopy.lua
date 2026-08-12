local ns = select(2, ...)

local DIALOG_KEY = "BOELOOT_COPY_ITEM_ID"

ns.ItemIdCopy = {}

StaticPopupDialogs[DIALOG_KEY] = {
    text = ns.L.COPY_ITEM_ID_PROMPT,
    button1 = CLOSE,
    hasEditBox = true,
    editBoxWidth = 180,
    OnShow = function(dialog, itemId)
        local editBox = dialog:GetEditBox()
        editBox:SetText(tostring(itemId))
        editBox:SetFocus()
        editBox:HighlightText()
    end,
    EditBoxOnEnterPressed = function(editBox)
        editBox:HighlightText()
    end,
    EditBoxOnEscapePressed = function(editBox)
        editBox:GetParent():Hide()
    end,
    timeout = 5,
    whileDead = true,
    hideOnEscape = true,
}

function ns.ItemIdCopy:Show(itemId)
    StaticPopup_Show(DIALOG_KEY, nil, nil, itemId)
end

function ns.ItemIdCopy:Attach(row)
    if row.boelootCopyItemId then return row.boelootCopyItemId end

    local button = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    button:SetSize(28, 18)
    button:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -7, 6)
    button:SetText(ns.L.ITEM_ID_BUTTON)
    button:SetScript("OnClick", function(clicked)
        self:Show(clicked.itemId)
    end)
    button:SetScript("OnEnter", function(hovered)
        GameTooltip:SetOwner(hovered, "ANCHOR_RIGHT")
        GameTooltip:SetText(ns.L.COPY_ITEM_ID_TOOLTIP, 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)

    row.boelootCopyItemId = button
    return button
end
