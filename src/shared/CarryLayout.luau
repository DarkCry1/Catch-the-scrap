--!strict
-- Two-hand cargo placement in HumanoidRootPart space (-Z is forward, +Y is up).
-- Inputs are measured from the actual avatar rig, so scaled avatars get cargo
-- that their own arms can reach. Pure numbers: shared by server and tests.
export type Point = { x: number, y: number, z: number }
export type Shoulder = { x: number, y: number, z: number, reach: number }
export type Rig = { left: Shoulder, right: Shoulder, frontZ: number, groundY: number }
export type Half = { x: number, y: number, z: number }
export type Layout = { center: Point, left: Point, right: Point }

local Layout = {}
Layout.Gap = 0.15 -- space between chest and cargo
Layout.Comfort = 0.85 -- fraction of arm reach used; leaves visibly bent elbows
-- Grips sit on the sides, toward the body (0 = middle, 1 = rear face). The
-- first candidate that is comfortably reachable is used.
Layout.GripDepths = { 0.7, 0.85, 0.95 }
Layout.GripDrop = 0.15 -- grips slightly below the cargo's center
Layout.HandClearance = 0.12 -- palm distance outside the cargo's side
Layout.MinGrip = 0.45 -- tiny items still keep the hands apart
Layout.GroundClearance = 0.3

function Layout.solve(rig: Rig, half: Half): Layout
    assert(half.x > 0 and half.y > 0 and half.z > 0, "cargo extents must be positive")
    local shoulderX = (math.abs(rig.left.x) + math.abs(rig.right.x)) / 2
    local shoulderY = (rig.left.y + rig.right.y) / 2
    local shoulderZ = (rig.left.z + rig.right.z) / 2
    local reach = math.min(rig.left.reach, rig.right.reach)
    assert(reach > 0, "arm reach must be positive")
    local gripX = math.max(half.x + Layout.HandClearance, Layout.MinGrip)
    local centerZ = rig.frontZ - half.z - Layout.Gap
    local comfort = reach * Layout.Comfort
    -- Deep cargo or short arms: slide the grips toward the rear corners.
    local gripZ, horizontal
    for _, depth in Layout.GripDepths do
        gripZ = centerZ + half.z * depth
        horizontal = math.sqrt((gripX - shoulderX) ^ 2 + (gripZ - shoulderZ) ^ 2)
        if horizontal < comfort then break end
    end
    assert(gripZ and horizontal, "grip depth candidates required")
    -- Hands hang below the shoulders at a comfortable distance. Wide or deep
    -- cargo that cannot be reached comfortably is raised to shoulder level.
    local gripY = if horizontal < comfort then shoulderY - math.sqrt(comfort ^ 2 - horizontal ^ 2) else shoulderY - reach * 0.1
    local centerY = gripY + half.y * Layout.GripDrop
    local lowest = rig.groundY + half.y + Layout.GroundClearance
    if centerY < lowest then
        centerY = lowest
        gripY = centerY - half.y * Layout.GripDrop
    end
    return {
        center = { x = 0, y = centerY, z = centerZ },
        left = { x = -gripX, y = gripY, z = gripZ },
        right = { x = gripX, y = gripY, z = gripZ },
    }
end

-- Distance from a shoulder to its grip. Used by tests and by the server to
-- report whether an avatar can physically reach the cargo.
function Layout.reachNeeded(shoulder: Shoulder, grip: Point): number
    return math.sqrt((grip.x - shoulder.x) ^ 2 + (grip.y - shoulder.y) ^ 2 + (grip.z - shoulder.z) ^ 2)
end

return Layout
