--!strict
export type Point = {x: number, z: number}
export type Segment = {from: Point, to: Point}
local Navigation = {}

-- The tip is ahead of BOTH tails in the chosen Z direction. Yard is +Z.
function Navigation.chevron(x: number, z: number, direction: number): {Segment}
    assert(direction == 1 or direction == -1, "Arrow direction must be +1 or -1")
    local tip = { x = x, z = z + direction * 2.5 }
    return {
        { from = { x = x - 2.5, z = z - direction * 2.5 }, to = tip },
        { from = { x = x + 2.5, z = z - direction * 2.5 }, to = tip },
    }
end

return Navigation
