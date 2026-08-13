local ns = select(2, ...)

ns.JournalAdapter = { journalInstanceId = nil, difficultyId = 0 }

function ns.JournalAdapter:ScheduleRestore()
    local customPageRemembered = ns.CustomPages and ns.CustomPages:HasRememberedSelection()
    if self.restoreScheduled or (not customPageRemembered and not ns.MainWindow.remembered) then return end
    self.restoreScheduled = true
    C_Timer.After(0, function()
        self.restoreScheduled = false
        if ns.CustomPages and ns.CustomPages:HasRememberedSelection() then
            ns.CustomPages:RestoreSelection()
        else
            ns.MainWindow:RestoreSelection()
        end
    end)
end

function ns.JournalAdapter:Update(instanceId)
    self.journalInstanceId = instanceId or (EncounterJournal and EncounterJournal.instanceID)
    self.difficultyId = EJ_GetDifficulty and EJ_GetDifficulty() or 0
    ns.MainWindow:SetContext(self.journalInstanceId, self.difficultyId)
end

function ns.JournalAdapter:Initialize()
    if self.initialized then return true end
    if not EncounterJournal then return false end
    if not ns.MainWindow:Initialize() then return false end
    if not ns.CustomPages:Initialize() then return false end

    self.initialized = true
    hooksecurefunc("EncounterJournal_DisplayInstance", function(instanceId)
        ns.CustomPages:CloseActive()
        self:Update(instanceId)
        ns.MainWindow:UpdateTabLayout()
        self:ScheduleRestore()
    end)
    hooksecurefunc("EncounterJournal_DisplayEncounter", function()
        ns.CustomPages:CloseActive()
        self:Update()
        ns.MainWindow:UpdateTabLayout()
        self:ScheduleRestore()
    end)
    if EJ_SetDifficulty then
        hooksecurefunc("EJ_SetDifficulty", function()
            self:Update()
            self:ScheduleRestore()
        end)
    end

    EncounterJournal:HookScript("OnShow", function()
        self:ScheduleRestore()
    end)
    EncounterJournal:HookScript("OnHide", function()
        ns.CustomPages:CloseActive()
        ns.MainWindow:Deselect()
    end)
    EncounterJournal:HookScript("OnEvent", function(_, event)
        if event == "EJ_DIFFICULTY_UPDATE" then self:ScheduleRestore() end
    end)
    self:Update()
    ns.CustomPageCards:Initialize()
    return true
end

function ns.JournalAdapter:EnsureLoaded()
    if not C_AddOns.IsAddOnLoaded("Blizzard_EncounterJournal") then
        local loaded, reason = C_AddOns.LoadAddOn("Blizzard_EncounterJournal")
        if not loaded then
            ns:Print(string.format(ns.L.JOURNAL_LOAD_FAILED, tostring(reason)))
            return false
        end
    end
    return self:Initialize()
end

function ns.JournalAdapter:OpenBoETab()
    if not self:EnsureLoaded() then return end

    local instanceId = self.journalInstanceId or EncounterJournal.instanceID
    if instanceId and EncounterJournal_OpenJournal then
        EncounterJournal_OpenJournal(self.difficultyId ~= 0 and self.difficultyId or nil, instanceId)
    else
        ShowUIPanel(EncounterJournal)
    end

    self:Update(instanceId)
    if instanceId then ns.MainWindow:Select() end
end
