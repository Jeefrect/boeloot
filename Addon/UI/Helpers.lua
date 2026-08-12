local ns = select(2, ...)

ns.UI = {}

function ns.UI.CopyTexture(target, source)
    if not target or not source then return end

    local atlas = source:GetAtlas()
    if atlas then
        target:SetAtlas(atlas, true)
    else
        target:SetTexture(source:GetTexture())
        target:SetTexCoord(source:GetTexCoord())
        target:SetSize(source:GetSize())
    end

    local blendMode = source:GetBlendMode()
    if blendMode then target:SetBlendMode(blendMode) end
end

function ns.UI.SetTabSelected(tab, selected)
    tab.selected:SetShown(selected)
    tab.unselected:SetShown(not selected)
    if selected then
        tab:LockHighlight()
    else
        tab:UnlockHighlight()
    end
end
