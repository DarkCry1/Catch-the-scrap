--!nonstrict
-- Engine-facing arm math shared by server cargo placement and client carry poses.
--
-- Why this exists: earlier custom poses only searched for Motor6D joints. With
-- StarterPlayer.AvatarJointUpgrade (the default for new experiences), R15
-- characters use AnimationConstraint joints instead, so nothing was posed.
-- Every helper here accepts both AnimationConstraint and Motor6D.
--
-- Joint relation used for both classes:
--   Part1.CFrame = Part0.CFrame * C0 * Transform * C1:Inverse()
-- For AnimationConstraint, C0/C1 are Attachment0/Attachment1.CFrame and
-- Part0/Part1 are the attachments' parents.
local M = {}

M.R15 = {
    Left = { "LeftUpperArm", "LeftLowerArm", "LeftHand" },
    Right = { "RightUpperArm", "RightLowerArm", "RightHand" },
}
M.R6 = { Left = "Left Arm", Right = "Right Arm" }

function M.isJoint(object)
    return object:IsA("AnimationConstraint") or object:IsA("Motor6D")
end

function M.info(joint)
    if joint:IsA("AnimationConstraint") then
        local a0, a1 = joint.Attachment0, joint.Attachment1
        if a0 and a1 and a0.Parent and a1.Parent then return a0.Parent, a1.Parent, a0.CFrame, a1.CFrame end
        return nil
    end
    if joint.Part0 and joint.Part1 then return joint.Part0, joint.Part1, joint.C0, joint.C1 end
    return nil
end

-- Map every jointed part to the joint that drives it.
function M.collect(character)
    local byChild = {}
    for _, object in character:GetDescendants() do
        if M.isJoint(object) then
            local _, part1 = M.info(object)
            if part1 then byChild[part1] = object end
        end
    end
    return byChild
end

-- CFrame of part, walking joints from the HumanoidRootPart. rest=true ignores
-- animation (identity transforms) and returns the result in root space.
function M.frame(byChild, root, part, rest)
    local chain = {}
    local current = part
    while current ~= root do
        local joint = byChild[current]
        if not joint or #chain > 8 then return nil end
        table.insert(chain, joint)
        current = M.info(joint)
    end
    local cframe = if rest then CFrame.identity else root.CFrame
    for index = #chain, 1, -1 do
        local joint = chain[index]
        local _, _, c0, c1 = M.info(joint)
        cframe = cframe * c0 * (if rest then CFrame.identity else joint.Transform) * c1:Inverse()
    end
    return cframe
end

M.MaxFlex = 2.5 -- radians (about 143 degrees)

-- Palm point in the shoulder's child frame for a given elbow flexion angle.
function M.palm(arm, angle)
    return arm.toElbow * (CFrame.fromAxisAngle(Vector3.xAxis, arm.flex * angle) * arm.b)
end

-- Describe one arm. R15 has two bones (shoulder->elbow, elbow->palm); R6 has one.
function M.arm(character, byChild, side)
    local names = M.R15[side]
    local upper, lower, hand = character:FindFirstChild(names[1]), character:FindFirstChild(names[2]), character:FindFirstChild(names[3])
    local shoulder = upper and byChild[upper]
    local elbow = lower and byChild[lower]
    local wrist = hand and byChild[hand]
    if shoulder and elbow and wrist then
        local parent, _, _, c1s = M.info(shoulder)
        local _, _, c0e, c1e = M.info(elbow)
        local _, _, c0w, c1w = M.info(wrist)
        if not parent or not c0e or not c0w then return nil end
        -- toElbow: elbow joint frame inside the shoulder's child frame.
        -- b: palm point inside the elbow's child frame.
        local toElbow = c1s:Inverse() * c0e
        local a = toElbow.Position
        local b = (c1e:Inverse() * c0w * c1w:Inverse()).Position
        if a.Magnitude < 1e-3 or b.Magnitude < 1e-3 then return nil end
        -- R15 elbows are hinges about their joint X axis. Natural flexion moves
        -- the palm toward the arm's front (-Z); pick that sign once.
        local flex = if (CFrame.fromAxisAngle(Vector3.xAxis, 0.5) * b).Z < b.Z then 1 else -1
        local arm = { kind = "R15", side = side, parent = parent, shoulder = shoulder, elbow = elbow, wrist = wrist, a = a, b = b, toElbow = toElbow, flex = flex }
        arm.reach = M.palm(arm, 0).Magnitude
        return arm
    end
    local limb = character:FindFirstChild(M.R6[side])
    local joint = limb and byChild[limb]
    if joint and limb:IsA("BasePart") then
        local parent, _, _, c1 = M.info(joint)
        if not parent then return nil end
        local a = (c1:Inverse() * CFrame.new(0, -limb.Size.Y * 0.4, 0)).Position
        if a.Magnitude < 1e-3 then return nil end
        return { kind = "R6", side = side, parent = parent, shoulder = joint, a = a, reach = a.Magnitude }
    end
    return nil
end

-- Rest-pose measurements in root space for CarryLayout.solve.
function M.measure(character, root, humanoid)
    local byChild = M.collect(character)
    local rig = {}
    local torso
    for _, side in { "Left", "Right" } do
        local arm = M.arm(character, byChild, side)
        if not arm then return nil end
        local parentFrame = M.frame(byChild, root, arm.parent, true)
        if not parentFrame then return nil end
        local _, _, c0 = M.info(arm.shoulder)
        local pivot = (parentFrame * c0).Position
        rig[string.lower(side)] = { x = pivot.X, y = pivot.Y, z = pivot.Z, reach = arm.reach }
        torso = torso or { part = arm.parent, frame = parentFrame }
    end
    local depth = if torso.part:IsA("BasePart") then torso.part.Size.Z / 2 else 0.5
    rig.frontZ = math.min(torso.frame.Position.Z - depth, -0.2)
    local hip = if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then humanoid.HipHeight else 2
    rig.groundY = -(hip + root.Size.Y / 2)
    return rig, byChild
end

local function orthonormal(primary, hint, fallback)
    local other = hint - primary * hint:Dot(primary)
    if other.Magnitude < 1e-4 then other = fallback - primary * fallback:Dot(primary) end
    if other.Magnitude < 1e-4 then return nil end
    return other.Unit
end

local function basis(x, y)
    return CFrame.fromMatrix(Vector3.zero, x, y, x:Cross(y))
end

-- Rotation that turns `from` into `to` without twisting about either vector.
local function swing(from, to)
    local axis = from:Cross(to)
    local sine, cosine = axis.Magnitude, from:Dot(to)
    if sine < 1e-6 then return CFrame.identity end
    return CFrame.fromAxisAngle(axis / sine, math.atan2(sine, cosine))
end

-- Solve one arm toward a world-space target. Returns joint->Transform pairs.
-- parentFrame is the current world CFrame of the shoulder's parent (torso).
-- pole is a world direction that elbows should bend toward.
function M.solve(arm, parentFrame, target, pole)
    local _, _, c0s, c1s = M.info(arm.shoulder)
    local joint = parentFrame * c0s
    local pivot = joint.Position
    local offset = target - pivot
    local distance = offset.Magnitude
    if distance < 1e-4 then return nil end
    local direction = offset / distance
    local forward = joint:VectorToObjectSpace(parentFrame.LookVector)
    if arm.kind == "R6" then
        local transform = swing(arm.a.Unit, joint:VectorToObjectSpace(direction))
        return { { arm.shoulder, transform } }, pivot + direction * math.min(distance, arm.reach)
    end
    -- 1) Elbow: pure hinge. Find the flexion whose palm distance from the
    --    shoulder pivot equals the target distance (monotonic, so bisect).
    local longest, shortest = arm.reach, M.palm(arm, M.MaxFlex).Magnitude
    distance = math.clamp(distance, shortest, longest * 0.999)
    local low, high = 0, M.MaxFlex
    for _ = 1, 24 do
        local middle = (low + high) / 2
        if M.palm(arm, middle).Magnitude > distance then low = middle else high = middle end
    end
    local angle = (low + high) / 2
    local palm = M.palm(arm, angle)
    -- 2) Shoulder: aim the shoulder->palm line at the target and turn the
    --    elbow toward the pole (outward/down), fixing the upper-arm twist.
    local palmHat = palm.Unit
    local elbowSide = orthonormal(palmHat, arm.a, forward)
    local poleSide = orthonormal(direction, pole, -parentFrame.LookVector)
    if not elbowSide or not poleSide then return nil end
    local shoulderTransform = joint.Rotation:Inverse() * basis(direction, poleSide) * basis(palmHat, elbowSide):Inverse()
    return {
        { arm.shoulder, shoulderTransform },
        { arm.elbow, CFrame.fromAxisAngle(Vector3.xAxis, arm.flex * angle) },
        { arm.wrist, CFrame.identity },
    }, pivot + direction * palm.Magnitude
end

-- Forward kinematics for the palm point, given transforms. Used by tests and
-- by CarryPose's self-check; no engine side effects.
function M.handPoint(arm, parentFrame, transforms)
    local _, _, c0s, c1s = M.info(arm.shoulder)
    local shoulderFrame = parentFrame * c0s * (transforms[arm.shoulder] or CFrame.identity)
    if arm.kind == "R6" then return (shoulderFrame * CFrame.new(arm.a)).Position end
    local upperFrame = shoulderFrame * c1s:Inverse()
    local _, _, c0e = M.info(arm.elbow)
    local elbowFrame = upperFrame * c0e * (transforms[arm.elbow] or CFrame.identity)
    return (elbowFrame * CFrame.new(arm.b)).Position, (upperFrame * c0e).Position
end

return M
