--!strict
-- Workshop placement on the home plaza and robot platform positions inside a
-- workshop. Local workshop frame: +Z faces the street, X runs along it.
local Config = require("./Config")
export type Pad = { x: number, z: number }
export type Placement = { x: number, z: number, yaw: number, left: boolean }
local Layout = {}

-- Four platforms along each side wall, numbered back to front, left then right:
-- 1 2 (rear, beside the scrap crusher) / 3 4 / 5 6 / 7 8 (by the gate).
-- Platforms 7 and 8 unlock with rebirths (RebirthRules.slots).
local columnX = Config.Workshops.Width / 2 - 12
local rows = { -24, -8, 8, 24 }
Layout.Pads = {} :: { Pad }
for _, z in rows do
    for _, side in { -1, 1 } do
        table.insert(Layout.Pads, { x = side * columnX, z = z })
    end
end
assert(#Layout.Pads >= Config.Robot.MaxSlots, "Every robot slot needs a platform")

function Layout.placement(index: number): Placement
    assert(index >= 1 and index <= Config.BaseCount and index % 1 == 0, "Workshop index out of range")
    local left = index % 2 == 1
    local row = math.floor((index - 1) / 2)
    local w = Config.Workshops
    return {
        x = if left then -w.CenterX else w.CenterX,
        z = w.FirstZ - row * w.Spacing,
        yaw = if left then math.pi / 2 else -math.pi / 2,
        left = left,
    }
end

-- World-space axis-aligned footprint of a workshop (its yaw is +-90 degrees,
-- so local Width runs along world Z and Depth along world X).
function Layout.footprint(index: number): { minX: number, maxX: number, minZ: number, maxZ: number }
    local p = Layout.placement(index)
    local w = Config.Workshops
    return { minX = p.x - w.Depth / 2, maxX = p.x + w.Depth / 2, minZ = p.z - w.Width / 2, maxZ = p.z + w.Width / 2 }
end

return Layout
