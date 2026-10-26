--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Navigation = require(ReplicatedStorage.CatchTheScrapShared.Navigation)
local NavigationRenderer = {}
function NavigationRenderer.draw(parent, x, z, direction, color)
    for _, segment in Navigation.chevron(x, z, direction) do
        local a = Vector3.new(segment.from.x, .16, segment.from.z)
        local b = Vector3.new(segment.to.x, .16, segment.to.z)
        local stripe = Instance.new("Part")
        stripe.Name = if direction == 1 then "ArrowToScrapyard" else "ArrowToWorkshops"
        stripe.Size = Vector3.new(.65, .06, (b-a).Magnitude)
        stripe.CFrame = CFrame.lookAt((a+b)/2, b)
        stripe.Color = color
        stripe.Material = Enum.Material.SmoothPlastic
        stripe.Anchored = true
        stripe.CanCollide = false
        stripe.CanTouch = false
        stripe.CanQuery = false
        stripe.Parent = parent
    end
end
return NavigationRenderer
