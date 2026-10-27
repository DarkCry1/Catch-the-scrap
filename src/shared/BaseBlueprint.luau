--!strict
-- Original open-front salvage workshop, local +Z faces the street.
-- Sizes come from Config.Workshops so the plaza layout, pads and tests agree.
-- [name, size, position, palette, material, collidable, yaw degrees]
local Config = require("./Config")
export type Part = { name: string, size: {number}, position: {number}, palette: string, material: string, collidable: boolean, yaw: number }
local W, D = Config.Workshops.Width / 2, Config.Workshops.Depth / 2 -- 34, 33
local front, back = D - 2, -D + 0.5 -- gate line and back-wall center
local parts: {Part} = {}
local function add(name: string, size: {number}, position: {number}, palette: string, material: string, collidable: boolean)
    table.insert(parts, { name = name, size = size, position = position, palette = palette, material = material, collidable = collidable, yaw = 0 })
end

add("Foundation", { W * 2, 0.6, D * 2 }, { 0, 0, 0 }, "dark", "Concrete", true)
add("WorkshopFloor", { W * 2 - 4, 0.18, D * 2 - 4 }, { 0, 0.39, 0 }, "floor", "DiamondPlate", true)
add("FrontThreshold", { W * 2 - 4, 0.15, 3 }, { 0, 0.54, front }, "steel", "Metal", true)
add("LeftWall", { 1, 4.5, D * 2 - 2 }, { -W + 0.5, 2.55, 0 }, "wall", "Metal", true)
add("RightWall", { 1, 4.5, D * 2 - 2 }, { W - 0.5, 2.55, 0 }, "wall", "Metal", true)
add("BackWall", { W * 2 - 4, 9, 1 }, { 0, 4.8, back }, "wall", "Metal", true)
add("BackInset", { 46, 5, 0.18 }, { 0, 5.4, back + 0.65 }, "dark", "Metal", false)
add("BackStripe", { W * 2 - 7, 0.35, 0.2 }, { 0, 2.1, back + 0.7 }, "amber", "Neon", false)
add("LeftTrim", { 0.25, 0.25, D * 2 - 3 }, { -W + 1.2, 4.9, 0 }, "accent", "Neon", false)
add("RightTrim", { 0.25, 0.25, D * 2 - 3 }, { W - 1.2, 4.9, 0 }, "accent", "Neon", false)
add("LeftGatePillar", { 2.3, 14, 2.5 }, { -W + 2.5, 7.3, front }, "steel", "Metal", true)
add("RightGatePillar", { 2.3, 14, 2.5 }, { W - 2.5, 7.3, front }, "steel", "Metal", true)
add("LeftGateLight", { 0.3, 11.5, 0.3 }, { -W + 3.8, 7.1, front + 1.4 }, "accent", "Neon", false)
add("RightGateLight", { 0.3, 11.5, 0.3 }, { W - 3.8, 7.1, front + 1.4 }, "accent", "Neon", false)
add("GateHeader", { W * 2 - 4, 4, 3 }, { 0, 13.2, front }, "dark", "Metal", true)
add("HeaderEdge", { W * 2 - 5, 0.3, 0.3 }, { 0, 15.35, front + 1.6 }, "amber", "Neon", false)
-- Rear canopy shelters the crusher and the rear platforms.
add("RearCanopy", { W * 2 - 1, 0.8, 15 }, { 0, 12.8, back + 7 }, "dark", "Metal", true)
add("CanopyLip", { W * 2 - 1, 0.5, 0.5 }, { 0, 12.4, back + 14.5 }, "steel", "Metal", false)
add("LeftRearColumn", { 2, 12, 2 }, { -W + 2, 6.4, back + 1.5 }, "steel", "Metal", true)
add("RightRearColumn", { 2, 12, 2 }, { W - 2, 6.4, back + 1.5 }, "steel", "Metal", true)
add("CanopyLight", { 30, 0.18, 0.5 }, { 0, 12.25, back + 8 }, "energy", "Neon", false)
-- Walkway from the gate to the crusher, between the two platform columns.
add("AisleLeft", { 0.15, 0.06, D + 8 }, { -9, 0.52, D / 2 - 6 }, "amber", "Neon", false)
add("AisleRight", { 0.15, 0.06, D + 8 }, { 9, 0.52, D / 2 - 6 }, "amber", "Neon", false)
add("ProgressBoard", { 12, 4.4, 0.35 }, { 0, 7, -16 }, "black", "SmoothPlastic", false)
-- Back-wall service corner on each side of the crusher.
add("LeftToolCabinet", { 4, 5, 3 }, { -12, 3, back + 3 }, "steel", "Metal", true)
add("CabinetDoor", { 3.5, 4.2, 0.15 }, { -12, 3, back + 4.6 }, "dark", "Metal", false)
add("CabinetHandle", { 0.15, 1.2, 0.25 }, { -10.8, 3, back + 4.8 }, "amber", "Metal", false)
add("PowerCabinet", { 4, 5, 3 }, { 12, 3, back + 3 }, "copper", "Metal", true)
add("PowerIndicator", { 2.4, 0.45, 0.18 }, { 12, 4, back + 4.6 }, "energy", "Neon", false)
add("PowerIndicator2", { 2.4, 0.45, 0.18 }, { 12, 3, back + 4.6 }, "energy", "Neon", false)

for _, side in { -1, 1 } do
    for bay = 0, 4 do
        table.insert(parts, { name = "SalvagedWallPanel", size = { 0.22, 3.8, 11 }, position = { side * (W - 1.1), 2.6, -D + 7.5 + bay * 12.5 }, palette = if bay % 2 == 0 then "rust" else "steel", material = "CorrodedMetal", collidable = false, yaw = 0 })
    end
    for y = 1.8, 4.2, 1.2 do
        table.insert(parts, { name = "CabinetVent", size = { 2.7, 0.12, 0.12 }, position = { side * 12, y, back + 4.8 }, palette = "black", material = "Metal", collidable = false, yaw = 0 })
    end
    table.insert(parts, { name = "ServiceConduit", size = { 0.3, 7, 0.3 }, position = { side * (W - 3.2), 4.5, back + 1 }, palette = "copper", material = "Metal", collidable = false, yaw = 0 })
end
for x = -28, 28, 8 do
    table.insert(parts, { name = "RoofPatch", size = { 6, 0.12, 12 }, position = { x, 13.26, back + 7 }, palette = if x % 16 == 4 then "rust" else "steel", material = "CorrodedMetal", collidable = false, yaw = 0 })
end
return parts
