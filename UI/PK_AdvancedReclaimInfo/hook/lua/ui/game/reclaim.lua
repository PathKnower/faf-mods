local ShowReclaimCounter
local onScreenCalculationFunction
local OriginalUpdateLabels = UpdateLabels

function getOnScreenMassForOldReclaimCalculation()
    local onScreenMassTotal = 0

    for _, r in reclaimDataPool do
        onScreenMassTotal = onScreenMassTotal + r.mass
    end

    return onScreenMassTotal
end

function getOnScreenMassForNewReclaimCalculation()
    local onScreenMassTotal = 0

    for _, r in reclaimDataPool do
        onScreenMassTotal = onScreenMassTotal + r.mass
    end

    return onScreenMassTotal
end

if reclaimDataPool == nil then
    onScreenCalculationFunction = getOnScreenMassForOldReclaimCalculation
else
    onScreenCalculationFunction = getOnScreenMassForNewReclaimCalculation
end

function UpdateLabels()
    OriginalUpdateLabels()
    local onScreenMassTotal = onScreenCalculationFunction()

    if ShowReclaimCounter then
        reclaimFrame:Destroy()
        reclaimFrame = nil
        reclaimLine:Destroy()
        reclaimLine = nil
        CreateRecalimTotalUI(onScreenMassTotal)
    else
        CreateRecalimTotalUI(onScreenMassTotal)
        ShowReclaimCounter = true
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

                if keydown == false and ShowReclaimCounter then
                    reclaimFrame:Destroy()
                    reclaimFrame = nil
                    reclaimLine:Destroy()
                    reclaimLine = nil
                    ShowReclaimCounter = nil
                end
                
                if keydown ~= view.ShowingReclaim then -- state has changed
                    ShowReclaim(keydown)
                end
                WaitSeconds(.1)
            end
            
            if ShowReclaimCounter then
                reclaimFrame:Destroy()
                reclaimFrame = nil
                reclaimLine:Destroy()
                reclaimLine = nil
                ShowReclaimCounter = nil
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
