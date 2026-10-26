--!nonstrict
local CollectionService=game:GetService("CollectionService")
local TweenService=game:GetService("TweenService")
local RobotAnimator={}
function RobotAnimator.start()
    local active={}
    local function detach(part)
        local entry=active[part]
        if not entry then return end
        active[part]=nil;entry.tween:Cancel();entry.connection:Disconnect()
    end
    local function attach(part)
        if active[part] or not part:IsA("BasePart") then return end
        part.Transparency=0
        local tween=TweenService:Create(part,TweenInfo.new(1.1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Transparency=.45})
        local connection=part.Destroying:Connect(function() detach(part) end)
        active[part]={tween=tween,connection=connection};tween:Play()
    end
    CollectionService:GetInstanceAddedSignal("WorkingRobotReactor"):Connect(attach)
    CollectionService:GetInstanceRemovedSignal("WorkingRobotReactor"):Connect(detach)
    for _,part in CollectionService:GetTagged("WorkingRobotReactor") do attach(part) end
end
return RobotAnimator
