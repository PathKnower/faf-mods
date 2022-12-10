-- Strogo: Make a reclaim counter
local ReclaimTotal

function UpdateLabels()
    local view = import('/lua/ui/game/worldview.lua').viewLeft -- Left screen's camera
    local onScreenReclaimIndex = 1
    local onScreenReclaims = {}
    local onScreenMassTotal = 0

    -- One might be tempted to use a binary insert; however, tests have shown that it takes about 140x more time
    for _, r in Reclaim do
        r.onScreen = OnScreen(view, r.position)
        if r.onScreen and r.mass >= MinAmount then
            onScreenMassTotal = onScreenMassTotal + r.mass
            onScreenReclaims[onScreenReclaimIndex] = r
            onScreenReclaimIndex = onScreenReclaimIndex + 1
        end
    end
    
    
    if ReclaimTotal then
        reclaimFrame:Destroy()
        reclaimFrame = nil
        reclaimLine:Destroy()
        reclaimLine = nil
        CreateRecalimTotalUI(onScreenMassTotal)
    else
        CreateRecalimTotalUI(onScreenMassTotal)
        ReclaimTotal = true
    end
    
    table.sort(onScreenReclaims, function(a, b) return a.mass > b.mass end)

    -- Create/Update as many reclaim labels as we need
    local labelIndex = 1
    for _, r in onScreenReclaims do
        if labelIndex > MaxLabels then
            break
        end
        local label = LabelPool[labelIndex]
        if label and IsDestroyed(label) then
            label = nil
        end
        if not label then
            label = CreateReclaimLabel(view.ReclaimGroup, r)
            LabelPool[labelIndex] = label
        end

        label:DisplayReclaim(r)
        labelIndex = labelIndex + 1
    end

    -- -- Hide labels we didn't use
    for index = labelIndex, MaxLabels do
        local label = LabelPool[index]
        if label then
            if IsDestroyed(label) then
                LabelPool[index] = nil
            elseif not label:IsHidden() then
                label:Hide()
            end
        end
    end
end

function OnCommandGraphShow(bool)
    local view = import('/lua/ui/game/worldview.lua').viewLeft
    if view.ShowingReclaim and not CommandGraphActive then return end -- if on by toggle key

    CommandGraphActive = bool
    if CommandGraphActive then
        ForkThread(function()
            local keydown

            while CommandGraphActive do
                
                keydown = IsKeyDown('Control')

                if keydown == false and ReclaimTotal then
                    reclaimFrame:Destroy()
                    reclaimFrame = nil
                    reclaimLine:Destroy()
                    reclaimLine = nil
                    ReclaimTotal = nil
                end
                
                if keydown ~= view.ShowingReclaim then -- state has changed
                    ShowReclaim(keydown)
                end
                WaitSeconds(.1)
            end
            
            if ReclaimTotal then
                reclaimFrame:Destroy()
                reclaimFrame = nil
                reclaimLine:Destroy()
                reclaimLine = nil
                ReclaimTotal = nil
            end
            
            ShowReclaim(false)
        end)
    else
        CommandGraphActive = false -- above coroutine runs until now
    end
end

function CreateRecalimTotalUI(MassTotal)
        reclaimFrame = Bitmap(GetFrame(0))
        reclaimFrame:SetTexture('/textures/ui/common/game/economic-overlay/econ_bmp_m.dds')
        reclaimFrame.Depth:Set(99)
        reclaimFrame.Height:Set(30)
        reclaimFrame.Width:Set(100)
        reclaimFrame:DisableHitTest(true)
        LayoutHelpers.AtLeftTopIn(reclaimFrame, GetFrame(0), 350, 44)
        
        local titleLine = UIUtil.CreateText(reclaimFrame, 'Reclaim', 10, UIUtil.bodyFont)
        LayoutHelpers.CenteredAbove(titleLine, reclaimFrame, -12)
        titleLine:DisableHitTest(true)
        
        reclaimLine = UIUtil.CreateText(reclaimFrame, '', 10, UIUtil.bodyFont)
        reclaimLine:SetColor('FFB8F400')
        LayoutHelpers.AtLeftTopIn(reclaimLine, reclaimFrame, 4, 10)
        reclaimLine:DisableHitTest(true)
        
        if MassTotal then
            reclaimLine:SetText(string.format("%d", MassTotal))
        end
end
