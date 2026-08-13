local ns = select(2, ...)

ns.CustomPageCards = {}

local BACKGROUND_INSET = 6

local function SetCustomBackground(button, custom)
    local background = button.bgImage
    if not background then return end

    background:ClearAllPoints()
    if custom then
        background:SetPoint("TOPLEFT", button, "TOPLEFT", BACKGROUND_INSET, -BACKGROUND_INSET)
        background:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -BACKGROUND_INSET, BACKGROUND_INSET)
    else
        background:SetAllPoints(button)
    end

    if custom and not button.boelootBackgroundMask then
        local mask = button:CreateMaskTexture()
        mask:SetAtlas("UI-Frame-IconMask")
        mask:SetAllPoints(background)
        button.boelootBackgroundMask = mask
    end

    if custom and not button.boelootBackgroundMasked then
        background:AddMaskTexture(button.boelootBackgroundMask)
        button.boelootBackgroundMasked = true
    elseif not custom and button.boelootBackgroundMasked then
        background:RemoveMaskTexture(button.boelootBackgroundMask)
        button.boelootBackgroundMasked = false
    end
end

function ns.CustomPageCards:InitializeCard(button, elementData)
    if not button.boelootCustomPageOverlay then
        local overlay = CreateFrame("Button", nil, button)
        overlay:SetAllPoints()
        overlay:SetFrameLevel(button:GetFrameLevel() + 10)
        overlay:RegisterForClicks("LeftButtonUp")
        overlay:SetScript("OnClick", function()
            if button.boelootCustomPageId then ns.CustomPages:Open(button.boelootCustomPageId) end
            PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN)
        end)
        overlay:SetScript("OnEnter", function()
            local definition = ns.CustomPages:Get(button.boelootCustomPageId)
            if not definition then return end
            button:LockHighlight()
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetText(definition.title, 1, 1, 1)
            if definition.description then GameTooltip:AddLine(definition.description, nil, nil, nil, true) end
            GameTooltip:Show()
        end)
        overlay:SetScript("OnLeave", function()
            button:UnlockHighlight()
            GameTooltip_Hide()
        end)
        button.boelootCustomPageOverlay = overlay
    end

    local pageId = elementData and elementData.boelootCustomPageId
    button.boelootCustomPageId = pageId
    button.boelootCustomPageOverlay:SetShown(pageId ~= nil)
    SetCustomBackground(button, pageId ~= nil)
end

function ns.CustomPageCards:Append()
    if ns.CustomPages:IsActive() then ns.CustomPages:CloseActive(true) end
    local scrollBox = EncounterJournal.instanceSelect and EncounterJournal.instanceSelect.ScrollBox
    local provider = scrollBox and scrollBox:GetDataProvider()
    if not provider then return end

    local listType = EncounterJournal_IsRaidTabSelected(EncounterJournal) and "raid" or "dungeon"
    for _, definition in ipairs(ns.CustomPages:GetDefinitions(listType)) do
        local existing = provider:FindByPredicate(function(data)
            return data.boelootCustomPageId == definition.id
        end)
        if not existing then
            provider:Insert({
                boelootCustomPageId = definition.id,
                name = definition.title,
                description = definition.description,
                buttonImage = definition.icon,
                mapID = 0,
            })
        end
    end
end

function ns.CustomPageCards:Initialize()
    if self.initialized or not EncounterJournal or not EncounterJournal.instanceSelect then return end
    self.initialized = true
    local scrollBox = EncounterJournal.instanceSelect.ScrollBox
    scrollBox:RegisterCallback(ScrollBoxListMixin.Event.OnInitializedFrame, function(_, button, elementData)
        self:InitializeCard(button, elementData)
    end, self)
    hooksecurefunc("EncounterJournal_ListInstances", function() self:Append() end)
    self:Append()
end
