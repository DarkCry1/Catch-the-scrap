--!nonstrict
-- Two-hand carry pose for every nearby carrier, computed locally on each client.
-- Runs in RunService.PreSimulation, after the Animator has written this frame's
-- walk/idle pose, so the arm joints are overridden before physics and render.
-- Works with AnimationConstraint (Avatar Joint Upgrade) and Motor6D joints.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("CatchTheScrapShared")
local Config = require(Shared:WaitForChild("Config"))
local RigMath = require(Shared:WaitForChild("Engine"):WaitForChild("CarryRigMath"))
local Pose = {}
Pose.Mode = "Two-hand"
Pose.BlendSpeed = 14
Pose.ScanInterval = 0.2
Pose.MaxCarriers = 12
Pose.Pole = { Left = Vector3.new(-0.9, -1, 0.5), Right = Vector3.new(0.9, -1, 0.5) }

function Pose.start(localPlayer)
    local entries = {}
    local carried = {}
    local function forget(player)
        local entry = entries[player]
        if not entry then return end
        for _, connection in entry.connections do connection:Disconnect() end
        entries[player] = nil
    end
    local function rig(entry, character)
        if entry.character == character and not entry.dirty then return end
        for _, connection in entry.connections do connection:Disconnect() end
        entry.connections = {}
        entry.character = character; entry.dirty = false; entry.last = {}
        local function touched(object) if RigMath.isJoint(object) then entry.dirty = true end end
        table.insert(entry.connections, character.DescendantAdded:Connect(touched))
        table.insert(entry.connections, character.DescendantRemoving:Connect(touched))
        entry.byChild = RigMath.collect(character)
        entry.arms = { Left = RigMath.arm(character, entry.byChild, "Left"), Right = RigMath.arm(character, entry.byChild, "Right") }
    end
    local function scan()
        table.clear(carried)
        local world = workspace:FindFirstChild("CatchTheScrapWorld")
        local items = world and world:FindFirstChild("Items")
        if items then
            for _, model in items:GetChildren() do
                local carrier = model:GetAttribute("CarrierUserId")
                if carrier then carried[carrier] = model end
            end
        end
        local camera = workspace.CurrentCamera
        local eye = camera and camera.CFrame.Position
        local active = 0
        for _, player in Players:GetPlayers() do
            local entry = entries[player]
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local model = carried[player.UserId]
            local cargoRoot = model and model:FindFirstChild("CarryRoot")
            local grips = cargoRoot and { Left = cargoRoot:FindFirstChild("LeftCargoGrip"), Right = cargoRoot:FindFirstChild("RightCargoGrip") }
            local wanted = player:GetAttribute("CarryMode") == Pose.Mode and root and humanoid and humanoid.Health > 0
                and grips and grips.Left and grips.Right and eye and (root.Position - eye).Magnitude <= Config.Presentation.Distance
                and active < Pose.MaxCarriers
            if wanted then
                active += 1
                if not entry then entry = { alpha = 0, connections = {}, last = {} }; entries[player] = entry end
                rig(entry, character)
                entry.root = root; entry.grips = grips; entry.active = true
                entry.animator = humanoid:FindFirstChildOfClass("Animator")
            elseif entry then
                entry.active = false
                if entry.character ~= character then forget(player) end
            end
        end
    end
    local function update(dt)
        for player, entry in entries do
            local goal = if entry.active then 1 else 0
            entry.alpha += (goal - entry.alpha) * (1 - math.exp(-Pose.BlendSpeed * dt))
            if not entry.active and entry.alpha < 0.02 then entry.alpha = 0; table.clear(entry.last); continue end
            if entry.active and entry.root.Parent then
                for side, arm in entry.arms do
                    local grip = entry.grips[side]
                    if not arm or not grip.Parent then continue end
                    local parentFrame = RigMath.frame(entry.byChild, entry.root, arm.parent, false)
                    if not parentFrame then entry.dirty = true; continue end
                    local pole = parentFrame:VectorToWorldSpace(Pose.Pole[side])
                    local solved = RigMath.solve(arm, parentFrame, grip.WorldPosition, pole)
                    if solved then for _, pair in solved do entry.last[pair[1]] = pair[2] end end
                end
            end
            for joint, transform in entry.last do
                if joint.Parent then joint.Transform = joint.Transform:Lerp(transform, entry.alpha) end
            end
        end
    end
    Players.PlayerRemoving:Connect(forget)
    local elapsed = Pose.ScanInterval
    RunService.PreSimulation:Connect(function(dt)
        elapsed += dt
        if elapsed >= Pose.ScanInterval then elapsed = 0; scan() end
        update(dt)
    end)
    return { entries = entries, scan = scan, update = update }
end

return Pose
