--!nonstrict
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RobotAnimator = {}

function RobotAnimator.start()
    local active = {}
    local function attach(part)
        if active[part] or not part:IsA("BasePart") then return end
        local tween = TweenService:Create(part, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.45 })
        local cleanup
        cleanup = part.Destroying:Connect(function()
            tween:Cancel()
            active[part] = nil
            cleanup:Disconnect()
        end)
        active[part] = tween
        tween:Play()
    end
    CollectionService:GetInstanceAddedSignal("WorkingRobotReactor"):Connect(attach)
    for _, part in CollectionService:GetTagged("WorkingRobotReactor") do attach(part) end
end

return RobotAnimator
