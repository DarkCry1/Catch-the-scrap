--!nonstrict
-- Server side of carrying: positions cargo for the actual avatar and publishes
-- grip targets. Arms are posed locally on every client by client/CarryPose,
-- which supports AnimationConstraint (Avatar Joint Upgrade) and Motor6D rigs.
-- No IKControl, Tool hold or uploaded animation is used.
local Shared = game:GetService("ReplicatedStorage").CatchTheScrapShared
local Layout = require(Shared.CarryLayout)
local RigMath = require(Shared.Engine.CarryRigMath)
local Rig = {}
Rig.TwoHand = "Two-hand"
Rig.Harness = "Harness"

function Rig.clear(record)
    record.carrying = false
    if record.weld then record.weld:Destroy(); record.weld = nil end
    if record.rig then
        for _, object in record.rig do object:Destroy() end
        record.rig = nil
    end
    record.layout = nil
end

-- Visible cargo extents in CarryRoot space; ground halo and helpers excluded.
function Rig.bounds(record)
    local rootFrame = record.root.CFrame
    local halo = record.model:FindFirstChild("GroundHalo")
    local low, high
    for _, part in record.model:GetDescendants() do
        if not part:IsA("BasePart") or part == record.root or part.Name == "VisualPivot" or part.Transparency >= 1 then continue end
        if halo and part:IsDescendantOf(halo) then continue end
        local relative = rootFrame:ToObjectSpace(part.CFrame)
        local size = part.Size / 2
        for _, sx in { -1, 1 } do
            for _, sy in { -1, 1 } do
                for _, sz in { -1, 1 } do
                    local corner = relative * Vector3.new(sx * size.X, sy * size.Y, sz * size.Z)
                    low = if low then Vector3.new(math.min(low.X, corner.X), math.min(low.Y, corner.Y), math.min(low.Z, corner.Z)) else corner
                    high = if high then Vector3.new(math.max(high.X, corner.X), math.max(high.Y, corner.Y), math.max(high.Z, corner.Z)) else corner
                end
            end
        end
    end
    if not low then return Vector3.one * 1.25, Vector3.zero end
    return (high - low) / 2, (high + low) / 2
end

local function weldTo(record, part)
    local joint = Instance.new("WeldConstraint")
    joint.Name = "CargoWeld"; joint.Part0 = part; joint.Part1 = record.root; joint.Parent = record.root
    record.weld = joint
end

local function mount(record, root, offset)
    record.root.Anchored = true
    record.model:PivotTo(root.CFrame * offset)
    record.root.Anchored = false
    weldTo(record, root)
end

function Rig.attach(record, root, style)
    Rig.clear(record)
    local character = root.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    assert(humanoid, "A living character is required for carrying")
    record.rig = {}; record.carrying = true
    local function keep(object) table.insert(record.rig, object); return object end
    if style ~= Rig.Harness then
        local ok = pcall(function()
            local rig = RigMath.measure(character, root, humanoid)
            assert(rig, "No usable arm joints on this avatar")
            local half, center = Rig.bounds(record)
            local layout = Layout.solve(rig, { x = half.X, y = half.Y, z = half.Z })
            -- CarryRoot is placed so the cargo's visual center lands on layout.center.
            local rootOffset = Vector3.new(layout.center.x, layout.center.y, layout.center.z) - center
            mount(record, root, CFrame.new(rootOffset))
            for _, side in { "Left", "Right" } do
                local grip = layout[string.lower(side)]
                local target = keep(Instance.new("Attachment"))
                target.Name = side .. "CargoGrip"
                target.Position = Vector3.new(grip.x, grip.y, grip.z) - rootOffset
                target.Parent = record.root
            end
            record.layout = layout
        end)
        if ok then return Rig.TwoHand end
        Rig.clear(record); record.rig = {}; record.carrying = true
    end
    -- Body-mounted fallback: unusual avatars without arm joints, or player choice.
    mount(record, root, CFrame.new(0, .5, 2.3))
    for _, side in { -1, 1 } do
        local strap = keep(Instance.new("Part")); strap.Name = "CargoHarnessStrap"; strap.Size = Vector3.new(.18, 2.7, .16)
        strap.Color = Color3.fromRGB(55, 66, 76); strap.Material = Enum.Material.Fabric
        strap.CFrame = root.CFrame * CFrame.new(side * .65, .45, .65); strap.Anchored = false; strap.Massless = true; strap.CanCollide = false; strap.CanQuery = false; strap.CanTouch = false; strap.Parent = character
        local joint = Instance.new("WeldConstraint"); joint.Part0 = root; joint.Part1 = strap; joint.Parent = strap
    end
    return Rig.Harness
end

return Rig
