--!strict
-- Modular, original robot geometry from native parts. A design picks one
-- locomotion, body, arm set and head plus extras; the forge stacks them and
-- returns parts in five assembly groups:
--   1 locomotion, 2 body, 3 arms, 4 head, 5 reactor/extras/details.
-- Front is local +Z, ground is y = 0. Cylinders follow Roblox: axis = local X.
-- Palette roles: main/dark/accent come from the design; "amber" (trim) and
-- "energy" (glow) are recolored to the rarity color by the builders.
export type Part = { name: string, step: number, size: {number}, position: {number}, palette: string, shape: string, yaw: number?, pitch: number?, roll: number? }
export type Design = {
    legs: string, body: string, arms: string, head: string, extras: {string},
    main: string, dark: string, accent: string,
    scale: number?, bodySize: {number}?, legHeight: number?,
}
type Vec = { number }
local Forge = {}

local function build(design: Design): {Part}
    local parts: {Part} = {}
    local main, dark, accent = design.main, design.dark, design.accent
    local function add(name: string, step: number, size: Vec, position: Vec, palette: string, shape: string?, pitch: number?, yaw: number?, roll: number?)
        table.insert(parts, { name = name .. #parts + 1, step = step, size = size, position = position, palette = palette, shape = shape or "Block", pitch = pitch, yaw = yaw, roll = roll })
    end
    -- A straight segment between two points (legs, arms, struts, antennas).
    local function strut(name: string, step: number, a: Vec, b: Vec, thickness: number, palette: string)
        local dx, dy, dz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
        local length = math.sqrt(dx * dx + dy * dy + dz * dz)
        local horizontal = math.sqrt(dx * dx + dz * dz)
        local yaw = if horizontal > 1e-6 then -math.deg(math.atan2(dz, dx)) else 0
        local roll = math.deg(math.atan2(dy, horizontal))
        add(name, step, { length, thickness, thickness }, { (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 }, palette, "Block", 0, yaw, roll)
    end
    -- Upright cylinder (axis along Y) and a disc facing forward (axis along Z).
    local function upright(name: string, step: number, height: number, diameter: number, position: Vec, palette: string)
        add(name, step, { height, diameter, diameter }, position, palette, "Cylinder", 0, 0, 90)
    end
    local function facing(name: string, step: number, depth: number, diameter: number, position: Vec, palette: string)
        add(name, step, { depth, diameter, diameter }, position, palette, "Cylinder", 0, 90, 0)
    end
    local function ball(name: string, step: number, diameter: number, position: Vec, palette: string)
        add(name, step, { diameter, diameter, diameter }, position, palette, "Ball")
    end

    -- Body dimensions are needed by the locomotion (stance width).
    local defaults: {[string]: Vec} = {
        Box = { 3.4, 2.6, 2 }, Barrel = { 3, 2.8, 3 }, Sphere = { 3.2, 3.2, 3.2 }, Tower = { 2.6, 3.4, 2.2 },
        Wedge = { 3.4, 2.4, 2.6 }, Disc = { 4.4, 1.4, 4.4 }, Crate = { 3.4, 2.6, 2.6 }, Furnace = { 3.2, 3, 2.6 },
        Capsule = { 2.4, 3.4, 2.4 },
    }
    local size = design.bodySize or assert(defaults[design.body], "Unknown body " .. design.body)
    local w, h, d = size[1], size[2], size[3]

    -- 1. Locomotion: returns the height where the body starts.
    local B: number
    local legs = design.legs
    if legs == "Biped" or legs == "HeavyBiped" then
        local heavy = if legs == "HeavyBiped" then 1.3 else 1
        local hl = design.legHeight or 2.2
        local x = math.max(0.9, w * 0.3)
        for _, s in { -1, 1 } do
            add("Boot", 1, { 1.5 * heavy, 0.7, 2 * heavy }, { s * x, 0.35, 0.25 }, dark)
            add("Toe", 1, { 1.55 * heavy, 0.25, 0.55 }, { s * x, 0.6, 0.25 + heavy }, "amber")
            add("Shin", 1, { 0.85 * heavy, hl * 0.55, 0.95 * heavy }, { s * x, 0.7 + hl * 0.275, 0 }, main)
            add("Knee", 1, { 1 * heavy, 0.6, 0.45 }, { s * x, 0.7 + hl * 0.55, 0.5 * heavy }, "amber")
            add("Thigh", 1, { 1 * heavy, hl * 0.45, 1.05 * heavy }, { s * x, 0.7 + hl * 0.775, 0 }, dark)
            ball("HipJoint", 1, 0.95 * heavy, { s * x, 0.7 + hl, 0 }, accent)
        end
        B = 0.7 + hl + 0.25
    elseif legs == "Treads" then
        local x = math.min(w / 2 + 0.25, 2.6)
        for _, s in { -1, 1 } do
            add("TrackHousing", 1, { 1.3, 1.4, 3.8 }, { s * x, 0.75, 0 }, dark)
            add("TrackTread", 1, { 1.36, 0.2, 3.9 }, { s * x, 1.5, 0 }, "black")
            for _, z in { -1.2, 0, 1.2 } do add("RoadWheel", 1, { 0.3, 1.1, 1.1 }, { s * (x + 0.7), 0.75, z }, accent, "Cylinder") end
        end
        add("Deck", 1, { 2 * x, 0.5, 3.2 }, { 0, 1.7, 0 }, main)
        add("Plow", 1, { 2 * x + 0.4, 0.6, 0.5 }, { 0, 0.9, 2.05 }, "amber")
        B = 1.95
    elseif legs == "Wheels" or legs == "Trike" then
        local x = math.min(w / 2 + 0.35, 2.8)
        local spots = if legs == "Trike" then { { 0, 1.5 }, { -x, -1.3 }, { x, -1.3 } } else { { -x, 1.3 }, { x, 1.3 }, { -x, -1.3 }, { x, -1.3 } }
        for _, p in spots do
            add("Wheel", 1, { 0.55, 1.6, 1.6 }, { p[1], 0.8, p[2] }, dark, "Cylinder")
            add("Hubcap", 1, { 0.6, 0.65, 0.65 }, { p[1], 0.8, p[2] }, accent, "Cylinder")
        end
        add("FrontAxle", 1, { 2 * x, 0.3, 0.3 }, { 0, 0.8, if legs == "Trike" then 1.5 else 1.3 }, "black")
        add("RearAxle", 1, { 2 * x, 0.3, 0.3 }, { 0, 0.8, -1.3 }, "black")
        add("Chassis", 1, { 2 * x - 0.4, 0.6, 3.4 }, { 0, 1.45, 0 }, main)
        add("Bumper", 1, { 2 * x, 0.35, 0.35 }, { 0, 1.2, 1.9 }, "amber")
        B = 1.75
    elseif legs == "Hover" then
        upright("HoverSkirt", 1, 0.5, 3.6, { 0, 0.95, 0 }, dark)
        upright("HoverRing", 1, 0.15, 3.9, { 0, 0.95, 0 }, "energy")
        for _, p in { { 1.2, 1.2 }, { -1.2, 1.2 }, { 1.2, -1.2 }, { -1.2, -1.2 } } do
            upright("JetHousing", 1, 0.5, 0.9, { p[1], 0.55, p[2] }, accent)
            ball("IonJet", 1, 0.6, { p[1], 0.3, p[2] }, "energy")
        end
        upright("HoverStem", 1, 0.8, 1.4, { 0, 1.55, 0 }, main)
        B = 1.95
    elseif legs == "Spider" or legs == "Crab" then
        add("LegHub", 1, { 2.2, 0.8, 2.2 }, { 0, 1.95, 0 }, dark)
        upright("HubRing", 1, 0.2, 2.6, { 0, 2.1, 0 }, "amber")
        local angles = if legs == "Crab" then { 25, 90, 155, 205, 270, 335 } else { 45, 135, 225, 315 }
        for _, degrees in angles do
            local a = math.rad(degrees)
            local c, s = math.cos(a), math.sin(a)
            local hip, knee, foot = { c * 1.0, 2.0, s * 1.0 }, { c * 2.3, 2.9, s * 2.3 }, { c * 3.0, 0.2, s * 3.0 }
            strut("UpperLeg", 1, hip, knee, 0.4, main)
            strut("LowerLeg", 1, knee, foot, 0.32, dark)
            ball("LegJoint", 1, 0.5, knee, accent)
        end
        B = 2.35
    elseif legs == "Quad" then
        local x, z = math.max(0.9, w / 2 - 0.4), math.max(1, d / 2 - 0.3)
        for _, p in { { -x, z }, { x, z }, { -x, -z }, { x, -z } } do
            ball("Hip", 1, 0.85, { p[1], 2.35, p[2] }, accent)
            strut("Thigh", 1, { p[1], 2.35, p[2] }, { p[1], 1.25, p[2] + 0.35 }, 0.55, main)
            strut("Shin", 1, { p[1], 1.25, p[2] + 0.35 }, { p[1], 0.3, p[2] }, 0.45, dark)
            add("Paw", 1, { 0.8, 0.4, 1 }, { p[1], 0.2, p[2] + 0.15 }, dark)
        end
        B = 2.55
    elseif legs == "Unicycle" then
        add("BigWheel", 1, { 0.7, 2.4, 2.4 }, { 0, 1.2, 0 }, dark, "Cylinder")
        add("WheelHub", 1, { 0.8, 0.7, 0.7 }, { 0, 1.2, 0 }, accent, "Cylinder")
        add("TireTread", 1, { 0.75, 2.38, 0.3 }, { 0, 1.2, 0 }, "black")
        for _, s in { -1, 1 } do strut("Fork", 1, { s * 0.55, 1.2, 0 }, { s * 0.45, 2.7, 0 }, 0.3, main) end
        add("Saddle", 1, { 1.5, 0.3, 1.1 }, { 0, 2.75, 0 }, "amber")
        B = 2.9
    elseif legs == "Pogo" then
        upright("FootPad", 1, 0.3, 2, { 0, 0.15, 0 }, dark)
        upright("PogoRod", 1, 2.6, 0.35, { 0, 1.5, 0 }, main)
        for i = 0, 5 do upright("Coil", 1, 0.18, 1.4, { 0, 0.5 + i * 0.38, 0 }, if i % 2 == 0 then accent else dark) end
        B = 2.85
    elseif legs == "Snake" then
        ball("BellySegment", 1, 1.8, { 0, 0.92, 0.3 }, dark)
        local z, r = -0.9, 1.6
        for i = 1, 4 do
            ball("TailSegment", 1, r, { 0, r / 2 + 0.04, z }, if i % 2 == 1 then main else accent)
            z -= r * 0.62; r -= 0.22
        end
        add("TailFin", 1, { 0.15, 0.7, 0.8 }, { 0, 0.75, z + 0.1 }, "amber")
        B = 1.55
    else
        error("Unknown legs " .. legs)
    end

    -- 2. Body. center y, top, front z.
    local cy, top, front = B + h / 2, B + h, d / 2
    local body = design.body
    if body == "Box" or body == "Crate" or body == "Tower" or body == "Furnace" then
        add("Torso", 2, { w, h, d }, { 0, cy, 0 }, main)
        add("Belt", 2, { w + 0.2, 0.25, d + 0.2 }, { 0, B + 0.15, 0 }, "amber")
        for _, s in { -1, 1 } do add("SidePlate", 2, { 0.3, h * 0.7, d + 0.1 }, { s * (w / 2 + 0.1), cy, 0 }, dark) end
        add("BackPlate", 2, { w * 0.6, h * 0.6, 0.3 }, { 0, cy, -d / 2 - 0.15 }, dark)
        if body == "Crate" then
            for _, f in { 0.3, 0.7 } do add("Slat", 2, { w + 0.12, 0.22, d + 0.12 }, { 0, B + h * f, 0 }, dark) end
            for _, s in { -1, 1 } do add("CornerPost", 2, { 0.3, h + 0.1, 0.3 }, { s * (w / 2 - 0.05), cy, d / 2 - 0.05 }, accent) end
        elseif body == "Tower" then
            for i = 0, 2 do add("Window", 2, { w * 0.55, 0.18, 0.1 }, { 0, B + h * (0.62 + i * 0.12), d / 2 + 0.05 }, "energy") end
            add("TowerCap", 2, { w + 0.3, 0.3, d + 0.3 }, { 0, top + 0.15, 0 }, dark)
            top += 0.3
        elseif body == "Furnace" then
            add("Firebox", 2, { w * 0.55, h * 0.3, 0.12 }, { 0, B + h * 0.3, d / 2 + 0.06 }, "energy")
            for i = -1, 1 do add("GrillBar", 2, { 0.12, h * 0.32, 0.18 }, { i * w * 0.15, B + h * 0.3, d / 2 + 0.12 }, dark) end
            upright("Chimney", 2, 1.4, 0.7, { w * 0.28, top + 0.7, -d * 0.25 }, dark)
            upright("ChimneyCap", 2, 0.2, 0.9, { w * 0.28, top + 1.4, -d * 0.25 }, accent)
        end
    elseif body == "Barrel" then
        upright("Drum", 2, h, w, { 0, cy, 0 }, main)
        upright("Band", 2, 0.2, w + 0.15, { 0, B + 0.3, 0 }, "amber")
        upright("Band", 2, 0.2, w + 0.15, { 0, top - 0.3, 0 }, dark)
        upright("Lid", 2, 0.15, w * 0.8, { 0, top + 0.07, 0 }, accent)
    elseif body == "Sphere" then
        ball("Core", 2, w, { 0, cy, 0 }, main)
        upright("Equator", 2, 0.2, w + 0.1, { 0, cy, 0 }, "amber")
        upright("Socket", 2, 0.4, w * 0.4, { 0, B + 0.15, 0 }, dark)
    elseif body == "Wedge" then
        add("Hull", 2, { w, h * 0.55, d }, { 0, B + h * 0.275, 0 }, main)
        add("Hood", 2, { w, h * 0.45, d }, { 0, B + h * 0.775, 0 }, dark, "Wedge")
        for _, s in { -1, 1 } do add("Fender", 2, { 0.3, h * 0.5, d * 0.9 }, { s * (w / 2 + 0.1), B + h * 0.3, 0 }, "amber") end
        front = d / 2
    elseif body == "Disc" then
        upright("Saucer", 2, h, w, { 0, cy, 0 }, main)
        upright("Rim", 2, 0.2, w + 0.2, { 0, cy, 0 }, "amber")
        ball("Canopy", 2, w * 0.45, { 0, top, 0 }, dark)
        top += w * 0.18
    elseif body == "Capsule" then
        upright("Hull", 2, h - w, w, { 0, cy, 0 }, main)
        ball("LowerDome", 2, w, { 0, B + w / 2, 0 }, dark)
        ball("UpperDome", 2, w, { 0, top - w / 2, 0 }, main)
        upright("Band", 2, 0.2, w + 0.12, { 0, cy, 0 }, "amber")
    else
        error("Unknown body " .. body)
    end

    -- 3. Arms from both shoulders.
    local sx, sy = w / 2 + 0.45, B + h * 0.78
    local arms = design.arms
    for _, s in { -1, 1 } do
        local x = s * sx
        if arms == "Stub" then
            ball("Shoulder", 3, 0.9, { x, sy, 0 }, accent)
            strut("StubArm", 3, { x, sy, 0 }, { x + s * 0.4, sy - 0.9, 0.4 }, 0.6, main)
            ball("Fist", 3, 0.65, { x + s * 0.4, sy - 1.1, 0.45 }, dark)
        elseif arms == "Claw" then
            add("Shoulder", 3, { 1.2, 0.9, 1.6 }, { x, sy, 0 }, "amber")
            local elbow, wrist = { x + s * 0.3, sy - 1.3, 0.3 }, { x + s * 0.3, sy - 2.2, 0.9 }
            strut("UpperArm", 3, { x, sy, 0 }, elbow, 0.75, main)
            strut("Forearm", 3, elbow, wrist, 0.9, dark)
            for _, f in { -1, 1 } do add("ClawFinger", 3, { 0.25, 0.75, 0.3 }, { wrist[1] + f * 0.22, wrist[2] - 0.45, wrist[3] + 0.1 }, accent, "Block", 0, 0, f * 15) end
        elseif arms == "Drill" then
            ball("Shoulder", 3, 1, { x, sy, 0 }, accent)
            local elbow = { x + s * 0.2, sy - 1.1, 0.4 }
            strut("DrillArm", 3, { x, sy, 0 }, elbow, 0.7, main)
            for i = 0, 4 do facing("DrillBit", 3, 0.42, 1.2 - i * 0.22, { elbow[1], elbow[2], elbow[3] + 0.5 + i * 0.4 }, if i % 2 == 0 then accent else main) end
        elseif arms == "Cannon" then
            add("Shoulder", 3, { 1.1, 1, 1.4 }, { x, sy, 0 }, "amber")
            facing("Barrel", 3, 2.4, 0.7, { x + s * 0.1, sy - 0.5, 1 }, dark)
            facing("Muzzle", 3, 0.3, 0.95, { x + s * 0.1, sy - 0.5, 2.15 }, accent)
            ball("Charge", 3, 0.5, { x + s * 0.1, sy - 0.5, 2.35 }, "energy")
        elseif arms == "Hammer" then
            ball("Shoulder", 3, 1, { x, sy, 0 }, accent)
            local hand = { x + s * 0.25, sy - 1.6, 0.6 }
            strut("Arm", 3, { x, sy, 0 }, hand, 0.75, main)
            strut("Handle", 3, hand, { hand[1], hand[2] + 0.2, hand[3] + 1.4 }, 0.3, dark)
            add("HammerHead", 3, { 0.9, 1, 1.3 }, { hand[1], hand[2] + 0.2, hand[3] + 1.5 }, "amber")
        elseif arms == "Saw" then
            ball("Shoulder", 3, 1, { x, sy, 0 }, accent)
            local hand = { x + s * 0.5, sy - 1.2, 0.6 }
            strut("SawArm", 3, { x, sy, 0 }, hand, 0.65, main)
            add("SawBlade", 3, { 0.14, 2, 2 }, hand, "steel", "Cylinder")
            add("SawHub", 3, { 0.3, 0.6, 0.6 }, hand, "energy", "Cylinder")
            for t = 0, 3 do
                local a = t * math.pi / 2 + math.pi / 4
                add("SawTooth", 3, { 0.16, 0.35, 0.35 }, { hand[1], hand[2] + math.cos(a) * 1.05, hand[3] + math.sin(a) * 1.05 }, "amber", "Block", math.deg(a), 0, 0)
            end
        elseif arms == "Magnet" then
            ball("Shoulder", 3, 0.9, { x, sy, 0 }, accent)
            local hand = { x + s * 0.2, sy - 1.3, 0.8 }
            strut("Arm", 3, { x, sy, 0 }, hand, 0.6, main)
            add("MagnetBridge", 3, { 1.3, 0.4, 0.5 }, { hand[1], hand[2] - 0.2, hand[3] }, "copper")
            for _, f in { -1, 1 } do
                add("MagnetProng", 3, { 0.38, 0.9, 0.5 }, { hand[1] + f * 0.45, hand[2] - 0.8, hand[3] }, "copper")
                add("MagnetTip", 3, { 0.4, 0.28, 0.52 }, { hand[1] + f * 0.45, hand[2] - 1.35, hand[3] }, "energy")
            end
        elseif arms == "Wing" then
            ball("Shoulder", 3, 0.8, { x, sy, 0 }, accent)
            add("WingPanel", 3, { 0.15, 2.6, 1.4 }, { x + s * 0.95, sy + 0.25, -0.5 }, main, "Block", 0, 0, -s * 25)
            add("WingTip", 3, { 0.12, 1.6, 0.8 }, { x + s * 1.65, sy + 0.95, -0.7 }, "amber", "Block", 0, 0, -s * 40)
        elseif arms == "Pincer" then
            add("Shoulder", 3, { 1, 0.9, 1.2 }, { x, sy, 0 }, accent)
            local hand = { x + s * 0.5, sy - 0.9, 1.1 }
            strut("Arm", 3, { x, sy, 0 }, hand, 0.7, main)
            add("ClawPalm", 3, { 1.1, 0.9, 1 }, hand, dark)
            add("UpperJaw", 3, { 0.5, 0.4, 1.4 }, { hand[1], hand[2] + 0.35, hand[3] + 1 }, "amber", "Block", 15, 0, 0)
            add("LowerJaw", 3, { 0.5, 0.35, 1.2 }, { hand[1], hand[2] - 0.3, hand[3] + 0.9 }, main, "Block", -15, 0, 0)
        elseif arms == "Tentacle" then
            for i = 0, 4 do
                ball("TentacleSegment", 3, 0.85 - i * 0.12, { x + s * 0.3 * i, sy - 0.55 * i, 0.2 * i }, if i == 4 then "energy" elseif i % 2 == 0 then main else dark)
            end
        elseif arms == "Shield" then
            ball("Shoulder", 3, 1, { x, sy, 0 }, accent)
            strut("Arm", 3, { x, sy, 0 }, { x + s * 0.3, sy - 1.1, 0.4 }, 0.7, main)
            add("ShieldPlate", 3, { 0.35, 2.4, 1.8 }, { x + s * 0.55, sy - 1, 0.5 }, "amber")
            ball("ShieldBoss", 3, 0.6, { x + s * 0.75, sy - 1, 0.5 }, "energy")
        elseif arms == "Fork" then
            local mast = { s * 0.9, B + 0.5, front + 0.45 }
            add("Mast", 3, { 0.35, 2.4, 0.35 }, { mast[1], mast[2] + 1, mast[3] }, dark)
            add("ForkTine", 3, { 0.4, 0.25, 2.4 }, { mast[1], 0.35, mast[3] + 1.2 }, "amber")
            add("ForkHeel", 3, { 0.4, 0.9, 0.25 }, { mast[1], 0.7, mast[3] }, main)
        elseif arms == "Scoop" then
            local hand = { s * 1.1, B + 0.2, front + 1.2 }
            strut("BoomArm", 3, { x, sy, 0 }, hand, 0.6, main)
            ball("BoomJoint", 3, 0.7, { x, sy, 0 }, accent)
            add("BucketSide", 3, { 0.15, 0.9, 1.2 }, { s * 1.25, B - 0.3, front + 1.6 }, dark)
        else
            error("Unknown arms " .. arms)
        end
    end
    if arms == "Scoop" then
        add("BucketFloor", 3, { 2.6, 0.18, 1.3 }, { 0, B - 0.75, front + 1.6 }, dark)
        add("BucketBack", 3, { 2.6, 1, 0.18 }, { 0, B - 0.3, front + 1 }, "amber")
    end

    -- 4. Head on top of the body.
    local head = design.head
    local hy = top
    local headTop = top
    local function neck() add("Neck", 4, { 0.8, 0.4, 0.8 }, { 0, top + 0.2, 0 }, dark); hy = top + 0.4 end
    if head == "Visor" or head == "Crown" then
        neck()
        add("Head", 4, { 2.2, 1.6, 1.8 }, { 0, hy + 0.8, 0 }, main)
        add("Brow", 4, { 2.4, 0.3, 2 }, { 0, hy + 1.45, 0 }, "amber")
        add("Visor", 4, { 1.8, 0.6, 0.2 }, { 0, hy + 0.85, 0.95 }, dark)
        for _, s in { -1, 1 } do add("Eye", 4, { 0.5, 0.28, 0.15 }, { s * 0.45, hy + 0.87, 1.08 }, "energy") end
        add("Jaw", 4, { 1.2, 0.25, 0.25 }, { 0, hy + 0.25, 0.95 }, dark)
        headTop = hy + 1.6
        if head == "Crown" then
            upright("CrownBand", 4, 0.35, 2.2, { 0, headTop + 0.15, 0 }, "amber")
            for i = 0, 4 do
                local a = i * math.pi * 2 / 5
                add("CrownPoint", 4, { 0.3, 0.75, 0.3 }, { math.cos(a) * 0.95, headTop + 0.6, math.sin(a) * 0.95 }, "amber")
                ball("CrownJewel", 4, 0.28, { math.cos(a) * 0.95, headTop + 1.05, math.sin(a) * 0.95 }, "energy")
            end
            headTop += 1.2
        end
    elseif head == "Dome" then
        neck()
        ball("Dome", 4, 2, { 0, hy + 1, 0 }, main)
        add("VisorBand", 4, { 1.6, 0.45, 0.3 }, { 0, hy + 1.05, 0.88 }, "energy")
        ball("TopLight", 4, 0.4, { 0, hy + 2.05, 0 }, "amber")
        headTop = hy + 2.2
    elseif head == "Camera" then
        neck()
        add("CameraBody", 4, { 1.6, 1.3, 1.6 }, { 0, hy + 0.65, 0 }, main)
        facing("Lens", 4, 1, 0.9, { 0, hy + 0.65, 1.25 }, dark)
        ball("LensGlass", 4, 0.7, { 0, hy + 0.65, 1.7 }, "energy")
        add("CameraHood", 4, { 1.7, 0.2, 1.8 }, { 0, hy + 1.35, 0.1 }, "amber")
        headTop = hy + 1.45
    elseif head == "TV" then
        neck()
        add("Screen", 4, { 2.4, 1.8, 1.2 }, { 0, hy + 0.9, 0 }, main)
        add("ScreenGlow", 4, { 1.9, 1.3, 0.1 }, { 0, hy + 0.9, 0.62 }, "energy")
        for _, s in { -1, 1 } do
            ball("Knob", 4, 0.3, { s * 1.05, hy + 0.3, 0.62 }, "amber")
            strut("RabbitEar", 4, { s * 0.3, hy + 1.8, 0 }, { s * 1.0, hy + 2.45, -0.1 }, 0.12, dark)
        end
        headTop = hy + 2.45
    elseif head == "Cyclops" then
        neck()
        ball("CyclopsHead", 4, 1.9, { 0, hy + 0.95, 0 }, main)
        facing("EyeSocket", 4, 0.3, 1.1, { 0, hy + 1, 0.8 }, dark)
        ball("BigEye", 4, 0.8, { 0, hy + 1, 0.9 }, "energy")
        add("BrowPlate", 4, { 1.4, 0.22, 0.4 }, { 0, hy + 1.6, 0.6 }, "amber")
        headTop = hy + 1.9
    elseif head == "Horned" then
        neck()
        add("Helm", 4, { 2, 1.5, 1.7 }, { 0, hy + 0.75, 0 }, main)
        add("EyeSlit", 4, { 1.4, 0.25, 0.15 }, { 0, hy + 0.85, 0.88 }, "energy")
        add("Jaw", 4, { 1.2, 0.3, 0.3 }, { 0, hy + 0.2, 0.8 }, dark)
        for _, s in { -1, 1 } do
            strut("Horn", 4, { s * 0.8, hy + 1.3, 0 }, { s * 1.5, hy + 2.3, -0.2 }, 0.35, "amber")
            ball("HornTip", 4, 0.35, { s * 1.5, hy + 2.3, -0.2 }, accent)
        end
        headTop = hy + 2.4
    elseif head == "Periscope" then
        upright("ScopeTube", 4, 2, 0.6, { 0, top + 1, 0 }, dark)
        add("ScopeElbow", 4, { 0.8, 0.8, 0.8 }, { 0, top + 2.1, 0 }, main)
        facing("ScopeLens", 4, 0.6, 0.6, { 0, top + 2.1, 0.6 }, "amber")
        ball("ScopeGlass", 4, 0.45, { 0, top + 2.1, 0.9 }, "energy")
        headTop = top + 2.5
    elseif head == "Bucket" then
        upright("BucketHelm", 4, 1.4, 1.9, { 0, top + 0.75, 0 }, main)
        upright("BucketRim", 4, 0.15, 2.1, { 0, top + 0.1, 0 }, "amber")
        for _, s in { -1, 1 } do
            add("EyeSlot", 4, { 0.5, 0.2, 0.1 }, { s * 0.4, top + 0.9, 0.95 }, "energy")
            strut("Handle", 4, { s * 0.95, top + 1.3, 0 }, { s * 0.3, top + 1.95, 0 }, 0.12, dark)
        end
        headTop = top + 2
    elseif head == "Skull" then
        neck()
        add("Cranium", 4, { 1.8, 1.4, 1.6 }, { 0, hy + 0.85, 0 }, "bone")
        add("Jaw", 4, { 1.4, 0.5, 1.2 }, { 0, hy + 0.25, 0.1 }, "bone")
        for _, s in { -1, 1 } do
            add("EyeSocket", 4, { 0.5, 0.45, 0.1 }, { s * 0.4, hy + 0.95, 0.82 }, "black")
            ball("EyeGlow", 4, 0.28, { s * 0.4, hy + 0.95, 0.86 }, "energy")
        end
        for i = -1, 1 do add("Tooth", 4, { 0.22, 0.25, 0.12 }, { i * 0.35, hy + 0.5, 0.72 }, "bone") end
        headTop = hy + 1.55
    elseif head == "Stalks" then
        for _, s in { -1, 1 } do
            strut("EyeStalk", 4, { s * 0.5, top, 0.5 }, { s * 0.75, top + 1.3, 0.8 }, 0.22, dark)
            ball("StalkEye", 4, 0.6, { s * 0.75, top + 1.4, 0.8 }, "energy")
            ball("Pupil", 4, 0.25, { s * 0.75, top + 1.45, 1.05 }, "black")
        end
        headTop = top + 1.7
    else
        error("Unknown head " .. head)
    end

    -- 5. Reactor (every robot has one for the reveal/working glow) and extras.
    local reactorY = if body == "Disc" then cy else B + h * 0.55
    add("ReactorSocket", 5, { 1.2, 1.2, 0.3 }, { 0, reactorY, front + 0.1 }, dark)
    table.insert(parts, { name = "Reactor", step = 5, size = { 0.8, 0.8, 0.8 }, position = { 0, reactorY, front + 0.3 }, palette = "energy", shape = "Ball" })
    for _, extra in design.extras do
        if extra == "Antenna" then
            strut("Antenna", 5, { 0.6, headTop - 0.1, 0 }, { 0.8, headTop + 0.9, -0.2 }, 0.14, dark)
            ball("AntennaLight", 5, 0.38, { 0.8, headTop + 0.95, -0.2 }, "energy")
        elseif extra == "TwinAntenna" then
            for _, s in { -1, 1 } do
                strut("Antenna", 5, { s * 0.6, headTop - 0.1, 0 }, { s * 0.9, headTop + 0.8, 0 }, 0.14, dark)
                ball("AntennaLight", 5, 0.34, { s * 0.9, headTop + 0.85, 0 }, "energy")
            end
        elseif extra == "Exhaust" then
            for _, s in { -1, 1 } do
                upright("ExhaustPipe", 5, 1.5, 0.45, { s * 0.6, top - 0.2, -d / 2 - 0.3 }, "copper")
                upright("ExhaustCap", 5, 0.15, 0.6, { s * 0.6, top + 0.6, -d / 2 - 0.3 }, dark)
            end
        elseif extra == "Backpack" then
            upright("Tank", 5, 1.8, 1, { 0, cy, -d / 2 - 0.5 }, accent)
            upright("TankBand", 5, 0.15, 1.1, { 0, cy + 0.5, -d / 2 - 0.5 }, dark)
            ball("Valve", 5, 0.35, { 0, cy + 1, -d / 2 - 0.5 }, "amber")
        elseif extra == "Solar" then
            for _, s in { -1, 1 } do
                add("SolarPanel", 5, { 1.8, 0.1, 1.2 }, { s * 1.3, top + 0.2, -d / 2 - 0.2 }, "navy", "Block", -30, 0, s * 15)
                add("SolarCell", 5, { 1.5, 0.11, 0.2 }, { s * 1.3, top + 0.25, -d / 2 - 0.1 }, "energy", "Block", -30, 0, s * 15)
            end
        elseif extra == "Dish" then
            upright("DishStem", 5, 0.8, 0.25, { -0.8, headTop + 0.3, -0.4 }, dark)
            add("Dish", 5, { 0.15, 1.5, 1.5 }, { -0.8, headTop + 0.85, -0.4 }, "steel", "Cylinder", 0, 0, 60)
            ball("DishFeed", 5, 0.25, { -0.6, headTop + 1.1, -0.4 }, "energy")
        elseif extra == "Halo" then
            for i = 0, 9 do
                local a = i * math.pi / 5
                add("HaloSegment", 5, { 0.6, 0.14, 0.16 }, { math.cos(a) * 0.95, headTop + 0.45, math.sin(a) * 0.95 }, "energy", "Block", 0, -math.deg(a) + 90, 0)
            end
        elseif extra == "OrbitRing" then
            local radius = math.max(w, d) / 2 + 0.9
            for i = 0, 11 do
                local a = i * math.pi / 6
                add("OrbitSegment", 5, { radius * 0.5, 0.16, 0.2 }, { math.cos(a) * radius, cy, math.sin(a) * radius }, "amber", "Block", 0, -math.deg(a) + 90, 0)
            end
        elseif extra == "Crystals" then
            for i = 0, 5 do
                local a = i * math.pi / 3
                add("FloatingCrystal", 5, { 0.35, 1, 0.35 }, { math.cos(a) * 1.7, headTop - 0.6 + (i % 2) * 0.4, math.sin(a) * 1.7 }, "energy", "Block", 0, math.deg(a), 20)
            end
        elseif extra == "Spikes" then
            for _, s in { -1, 1 } do
                for i = 0, 2 do add("Spike", 5, { 0.3, 0.9, 0.3 }, { s * (sx - 0.2 + i * 0.25), sy + 0.6 + i * 0.1, -0.3 * i }, dark, "Block", 0, 0, -s * (20 + i * 15)) end
            end
        elseif extra == "Propeller" then
            add("RotorMast", 5, { 0.25, 0.8, 0.25 }, { 0, headTop + 0.4, 0 }, dark)
            ball("RotorHub", 5, 0.4, { 0, headTop + 0.85, 0 }, "amber")
            for i = 0, 2 do add("RotorBlade", 5, { 2.2, 0.08, 0.35 }, { 0, headTop + 0.88, 0 }, main, "Block", 0, i * 60, 0) end
        elseif extra == "Tail" then
            local p = { 0, B + h * 0.3, -d / 2 }
            for i = 1, 4 do
                local q = { 0, p[2] - 0.35 + i * 0.15, p[3] - 0.75 }
                strut("TailSegment", 5, p, q, 0.45 - i * 0.06, if i % 2 == 1 then main else dark)
                p = q
            end
            ball("TailTip", 5, 0.45, p, "energy")
        elseif extra == "Cape" then
            add("Cape", 5, { w * 0.9, h * 1.1, 0.15 }, { 0, cy - 0.1, -d / 2 - 0.35 }, accent, "Block", 8, 0, 0)
            add("CapeClasp", 5, { w * 0.9, 0.2, 0.25 }, { 0, top - 0.1, -d / 2 - 0.25 }, "amber")
        elseif extra == "Fins" then
            for _, s in { -1, 1 } do add("BackFin", 5, { 0.15, 1.6, 1.2 }, { s * 0.7, top - 0.2, -d / 2 - 0.4 }, "energy", "Block", 0, 0, s * 20) end
        elseif extra == "Wings" then
            for _, s in { -1, 1 } do
                strut("WingSpar", 5, { s * 0.6, top - 0.3, -d / 2 - 0.3 }, { s * 2.6, top + 1.4, -d / 2 - 0.6 }, 0.25, dark)
                for f = 0, 2 do add("Feather", 5, { 0.12, 1.8 - f * 0.3, 0.6 }, { s * (1.1 + f * 0.6), top + 0.3 + f * 0.45, -d / 2 - 0.55 }, if f == 1 then "energy" else accent, "Block", 0, 0, -s * (15 + f * 10)) end
            end
        elseif extra == "Gears" then
            for i, g in { { -0.7, 0.4, 1.2 }, { 0.6, -0.2, 0.9 }, { 0.1, 0.8, 0.7 } } do
                facing("Gear", 5, 0.25, g[3], { g[1], cy + g[2], -d / 2 - 0.2 - i * 0.05 }, if i == 2 then "amber" else accent)
                ball("GearHub", 5, g[3] * 0.35, { g[1], cy + g[2], -d / 2 - 0.35 - i * 0.05 }, dark)
            end
        elseif extra == "Flames" then
            for _, s in { -1, 1 } do
                add("Flame", 5, { 0.5, 1.1, 0.5 }, { s * (sx - 0.1), sy + 0.75, -0.2 }, "energy", "Wedge", 0, 0, -s * 10)
                add("Flame", 5, { 0.35, 0.8, 0.35 }, { s * 0.5, top + 0.4, -d / 2 + 0.2 }, "energy", "Wedge", 0, 0, s * 15)
            end
        elseif extra == "Star" then
            local center = { 0, cy + 0.6, -d / 2 - 0.6 }
            ball("StarCore", 5, 0.7, center, "energy")
            for i = 0, 7 do
                local a = i * math.pi / 4
                local len = if i % 2 == 0 then 1.6 else 1
                strut("StarRay", 5, center, { center[1] + math.cos(a) * len, center[2] + math.sin(a) * len, center[3] }, 0.2, if i % 2 == 0 then "energy" else "amber")
            end
        else
            error("Unknown extra " .. extra)
        end
    end
    -- Surface detail keeps every chassis readable at a distance and keeps the
    -- part count in a consistent range.
    local round = body == "Sphere" or body == "Barrel" or body == "Capsule" or body == "Disc"
    local rivets = 0
    while #parts < 40 and rivets < 16 do
        local side = if rivets % 2 == 0 then -1 else 1
        local row = math.floor(rivets / 2)
        local x, y = side * (w * 0.3), B + h * (0.25 + 0.08 * (row % 7))
        local z = front + 0.06
        if round then
            -- Sit on the curved surface instead of floating in front of it.
            local r = w / 2
            local dy = if body == "Sphere" then y - cy else 0
            z = math.sqrt(math.max(0.05, r * r - x * x - dy * dy)) + 0.02
        end
        add("Rivet", 5, { 0.18, 0.18, 0.12 }, { x, y, z }, dark)
        rivets += 1
    end
    -- Optional uniform scale for larger, more imposing tiers.
    local scale = design.scale or 1
    if scale ~= 1 then
        for _, p in parts do
            p.size = { p.size[1] * scale, p.size[2] * scale, p.size[3] * scale }
            p.position = { p.position[1] * scale, p.position[2] * scale, p.position[3] * scale }
        end
    end
    return parts
end

Forge.build = build
return Forge
