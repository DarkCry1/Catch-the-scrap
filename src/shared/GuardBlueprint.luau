--!strict
-- Guard robot geometry at scale 1 (GuardService multiplies by
-- Config.Guards.Scale[stage]). Positions are relative to the humanoid root
-- (hip height above the floor); the front is -Z, the way the guard moves.
-- color: "dark" | "steel" | "navy" | "tint" (stage color) | "gold" | "cyan" |
-- "visor" | "siren". minStage adds armor on later, tougher guards.
export type Part = { name: string, size: {number}, position: {number}, rotation: {number}, color: string,
    material: string, shape: string, minStage: number }
local Blueprint = {}
local parts: {Part} = {}
local function add(name: string, size: {number}, position: {number}, color: string, material: string?, shape: string?, rotation: {number}?, minStage: number?)
    table.insert(parts, { name = name, size = size, position = position, rotation = rotation or { 0, 0, 0 }, color = color,
        material = material or "Metal", shape = shape or "Block", minStage = minStage or 1 })
end
-- Hover base.
add("HoverSkirt", { .9, 3.4, 3.4 }, { 0, -1.75, 0 }, "dark", "Metal", "Cylinder", { 0, 0, 90 })
add("SkirtRim", { .25, 3.75, 3.75 }, { 0, -1.38, 0 }, "steel", "Metal", "Cylinder", { 0, 0, 90 })
add("Underglow", { .15, 2.8, 2.8 }, { 0, -2.25, 0 }, "tint", "Neon", "Cylinder", { 0, 0, 90 })
for _, c in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
    add("ThrusterPod", { .6, .5, .6 }, { c[1] * 1.25, -1.95, c[2] * 1.25 }, "dark")
    add("ThrusterGlow", { .45, .1, .45 }, { c[1] * 1.25, -2.22, c[2] * 1.25 }, "cyan", "Neon")
end
add("Waist", { .7, 1.9, 1.9 }, { 0, -.95, 0 }, "steel", "Metal", "Cylinder", { 0, 0, 90 })
-- Torso.
add("Torso", { 2.7, 2.4, 1.9 }, { 0, .15, 0 }, "navy")
add("ChestPlate", { 2.2, 1.4, .2 }, { 0, .35, -1.02 }, "steel")
add("ChestStripe", { 2.2, .28, .12 }, { 0, .62, -1.14 }, "tint", "Neon")
add("Badge", { .7, .7, .12 }, { 0, .05, -1.14 }, "gold", "Neon")
for i = -1, 1 do add("Vent", { .5, .12, .1 }, { i * .7, -.72, -1.0 }, "dark") end
add("Backpack", { 1.8, 1.6, .7 }, { 0, .4, 1.25 }, "dark")
for side = -1, 1, 2 do add("Exhaust", { .5, .5, .5 }, { side * .55, -.35, 1.45 }, "cyan", "Neon", "Ball") end
-- Arms.
for side = -1, 1, 2 do
    add("Shoulder", { 1, .8, 1.6 }, { side * 1.75, 1, 0 }, "steel")
    add("ShoulderLight", { .35, .35, .35 }, { side * 1.75, 1.45, -.55 }, "tint", "Neon", "Ball")
    add("Arm", { .6, 2, .6 }, { side * 1.85, -.2, -.25 }, "dark", "Metal", "Block", { -20, 0, 0 })
    add("Hand", { .75, .6, .75 }, { side * 1.85, -1.15, -.65 }, "steel")
    add("Baton", { .3, 1.4, .3 }, { side * 1.85, -1.1, -.95 }, "steel", "Metal", "Block", { -60, 0, 0 })
    add("BatonTip", { .45, .45, .45 }, { side * 1.85, -1.45, -1.55 }, "cyan", "Neon", "Ball")
    -- Later stages: heavier shoulder armor.
    add("ShoulderArmor", { 1.2, .35, 1.8 }, { side * 1.8, 1.5, 0 }, "tint", "Metal", "Block", { 0, 0, side * -12 }, 4)
    add("ShoulderSpike", { .25, .9, .25 }, { side * 2.05, 1.95, 0 }, "gold", "Metal", "Block", { 0, 0, side * -25 }, 6)
end
-- Head.
add("Neck", { .5, .8, .8 }, { 0, 1.5, 0 }, "dark", "Metal", "Cylinder", { 0, 0, 90 })
add("Head", { 1.7, 1.15, 1.5 }, { 0, 2, 0 }, "steel")
add("Visor", { 1.4, .36, .12 }, { 0, 2.05, -.78 }, "visor", "Neon")
for side = -1, 1, 2 do add("EarPod", { .3, .6, .6 }, { side * .95, 2, 0 }, "dark", "Metal", "Cylinder") end
add("Crest", { .16, .55, 1.2 }, { 0, 2.8, .1 }, "tint", "Neon", "Block", { 0, 0, 0 }, 3)
add("Antenna", { .12, .8, .12 }, { 0, 2.95, .35 }, "dark")
add("Siren", { .45, .45, .45 }, { 0, 3.4, .35 }, "siren", "Neon", "Ball")
Blueprint.Parts = parts

-- Parts used by a guard of this stage.
function Blueprint.forStage(stage: number): {Part}
    local out: {Part} = {}
    for _, p in parts do if stage >= p.minStage then table.insert(out, p) end end
    return out
end
-- Height above the floor of the guard's top, at scale 1, for hip height h.
function Blueprint.height(hipHeight: number): number
    local top = 0
    for _, p in parts do top = math.max(top, p.position[2] + math.max(p.size[1], p.size[2], p.size[3]) / 2) end
    return hipHeight + 1 + top
end
return Blueprint
