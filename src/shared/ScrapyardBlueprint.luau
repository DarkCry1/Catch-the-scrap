--!strict
-- Deterministic, original scrapyard geometry. Shared with tests and asset renders.
export type Part = { name: string, size: {number}, position: {number}, color: {number}, material: string,
    shape: string, yaw: number, pitch: number, roll: number, collidable: boolean, transparency: number }
export type Spawn = { position: {number}, rarity: string }
export type Sign = { position: {number}, text: string, color: {number} }
export type Bounds = { x: number, z: number, width: number, depth: number }
export type Layout = { parts: {Part}, spawns: {Spawn}, signs: {Sign}, bounds: {Bounds} }
local Blueprint = {}

function Blueprint.build(width: number, zoneLength: number, start: number): Layout
    assert(width >= 120 and zoneLength >= 240, "Yard must fit its paths and props")
    local layout: Layout = { parts = {}, spawns = {}, signs = {}, bounds = {} }
    local steel, rust, dark = {100, 117, 120}, {142, 77, 45}, {35, 44, 48}
    local amber, black = {232, 168, 54}, {20, 26, 28}
    local function part(name: string, size: {number}, position: {number}, color: {number}, material: string?, shape: string?, yaw: number?, roll: number?, solid: boolean?)
        table.insert(layout.parts, { name = name, size = size, position = position, color = color,
            material = material or "Metal", shape = shape or "Block", yaw = yaw or 0, pitch = 0, roll = roll or 0,
            collidable = if solid == nil then true else solid, transparency = 0 })
    end
    local function prop(kind: string, x: number, z: number, yaw: number)
        local rotation = math.rad(yaw)
        local function at(name: string, size: {number}, offset: {number}, tint: {number}, material: string?, shape: string?, localYaw: number?, roll: number?)
            part(kind .. name, size, { x + offset[1] * math.cos(rotation) + offset[3] * math.sin(rotation), offset[2], z - offset[1] * math.sin(rotation) + offset[3] * math.cos(rotation) }, tint, material, shape, yaw + (localYaw or 0), roll)
        end
        local w, d = 20, 26
        if kind == "Container" then
            w, d = 18, 28
            at("Shell", {18, 10, 28}, {0, 5, 0}, rust)
            at("Roof", {18.5, .3, 28.5}, {0, 10.2, 0}, steel)
            for side = -1, 1, 2 do
                for offset = -10, 10, 5 do at("Rib", {.45, 9.5, .5}, {side * 9.2, 5, offset}, dark) end
            end
            at("Door", {17, 9, .3}, {0, 5, 14.2}, dark)
            for _, offset in {-4, 4} do at("Handle", {.3, 7, .3}, {offset, 5, 14.5}, amber) end
        elseif kind == "CarWreck" then
            w, d = 17, 26
            at("Chassis", {14, 2.5, 24}, {0, 2.4, 0}, rust)
            at("Cab", {12, 3.8, 11}, {0, 5, -1}, dark)
            at("Glass", {11, 2, .2}, {0, 5.6, 4.7}, {66, 100, 107}, "Glass")
            at("Hood", {13, .5, 7}, {0, 4.1, 8.5}, steel)
            for _, side in {-1, 1} do
                for _, endZ in {-7, 7} do at("Wheel", {1.5, 5, 5}, {side * 7, 2.5, endZ}, black, "Rubber", "Cylinder") end
            end
            at("Bumper", {15, .7, .8}, {0, 2.4, 12}, amber)
        elseif kind == "Tires" then
            w, d = 14, 14
            for stack = -1, 1 do
                for level = 1, 3 do
                    at("Tire", {1.2, 5.5, 5.5}, {stack * 4, level * 1.15, stack * 2}, black, "Rubber", "Cylinder", 0, 90)
                    if level==3 then
                        at("Hole", {.08, 2.5, 2.5}, {stack * 4, level * 1.15 + .62, stack * 2}, dark, "Metal", "Cylinder", 0, 90)
                    end
                end
            end
        elseif kind == "Pipes" then
            w, d = 17, 24
            for row = 0, 1 do
                for column = -1, 1 do
                    local y, pipeX = 1.7 + row * 3, column * 3.2
                    at("Tube", {23, 3, 3}, {pipeX, y, 0}, steel, "Metal", "Cylinder", 90)
                    at("Opening", {.1, 2.2, 2.2}, {pipeX, y, 11.6}, black, "SmoothPlastic", "Cylinder", 90)
                end
            end
        elseif kind == "Reactor" then
            w, d = 20, 20
            at("Foot", {18, 1.2, 18}, {0, .6, 0}, dark, "Concrete")
            at("Tank", {10, 13, 13}, {0, 6, 0}, steel, "Metal", "Cylinder", 0, 90)
            for _, y in {2, 9.5} do at("Band", {.6, 14, 14}, {0, y, 0}, amber, "Metal", "Cylinder", 0, 90) end
            at("Spine", {2, 14, 2}, {-7, 7, 0}, dark)
            at("Core", {3, 6, .3}, {0, 6, 6.6}, {71, 149, 235}, "Neon")
            at("Vent", {4, 4, 4}, {0, 13, 0}, rust)
            at("Cap", {6, .4, 6}, {0, 15.2, 0}, dark)
        elseif kind == "RobotWreck" then
            w, d = 24, 24
            at("Body", {13, 7, 10}, {0, 4.2, 0}, dark)
            at("Chest", {9, 5, .6}, {0, 4.5, 5.3}, rust)
            at("Socket", {3, 3, 1}, {0, 4.5, 5.9}, black)
            at("Head", {7, 5, 6}, {-7, 3, 7}, steel, "Metal", "Block", -25)
            at("Visor", {5, 1, .3}, {-8.1, 3.5, 9.7}, black, "SmoothPlastic", "Block", -25)
            at("BrokenArm", {4, 3.5, 16}, {8, 2, 1}, rust, "Metal", "Block", 25)
            at("Leg", {4, 3, 12}, {-4, 1.8, -7}, steel, "Metal", "Block", 15)
        else
            w, d = 20, 24
            for index = 1, 10 do
                local ox = (index * 7 % 13) - 6
                local oz = (index * 11 % 17) - 8
                at("Scrap", {5 + index % 3, 1.5, 6}, {ox, 1 + math.floor(index / 4) * 1.3, oz}, if index % 2 == 0 then rust else steel, "CorrodedMetal", "Block", index * 27)
            end
        end
        local radians = math.rad(yaw)
        table.insert(layout.bounds, {x=x, z=z, width=math.abs(w*math.cos(radians))+math.abs(d*math.sin(radians)), depth=math.abs(w*math.sin(radians))+math.abs(d*math.cos(radians))})
    end
    local total = zoneLength * 3
    part("YardTerrain", {width + 140, 2, total + 100}, {0, -2, start + total / 2}, {80, 72, 56}, "Ground")
    local tiers = {"Common", "Uncommon", "Rare"}
    local names = {"SORTING YARD", "MACHINE GRAVEYARD", "REACTOR WRECKS"}
    local colors = {{200, 207, 198}, {78, 215, 145}, {90, 160, 255}}
    for zone = 1, 3 do
        local first = start + (zone - 1) * zoneLength
        local tint = colors[zone]
        part("YardFloor", {width, 1, zoneLength}, {0, -.5, first + zoneLength / 2}, if zone == 1 then {100, 94, 80} else {78, 75, 65}, if zone == 1 then "Concrete" else "Ground")
        part("HaulRoad", {34, .08, zoneLength}, {0, .05, first + zoneLength / 2}, {54, 58, 57}, "Asphalt")
        for _, side in {-1, 1} do
            part("SafetyLine", {.3, .05, zoneLength}, {side * 17, .12, first + zoneLength / 2}, amber, "SmoothPlastic", "Block", 0, 0, false)
            for offset = 0, zoneLength, 40 do
                part("FencePost", {.7, 7, .7}, {side * (width / 2 + 1), 3.5, first + offset}, steel)
            end
            for _, y in {1.5, 4, 6.5} do
                part("FenceRail", {.35, .3, zoneLength}, {side * (width / 2 + 1), y, first + zoneLength / 2}, dark)
            end
        end
        table.insert(layout.signs, {position={0, 14, first + 15},text=tiers[zone]:upper() .. " / " .. names[zone],color=tint})
        for row = 0, 7 do
            for _, x in {-55, -22, 22, 55} do
                table.insert(layout.spawns,{ position={x, 1.6, first + (row + .5) * zoneLength / 8}, rarity=tiers[zone] })
            end
        end
        local kinds = if zone == 1 then {"Container", "CarWreck", "Tires", "Pile"} elseif zone == 2 then {"Pipes", "CarWreck", "Container", "RobotWreck"} else {"Reactor", "RobotWreck", "Pipes", "Reactor"}
        for row = 0, 3 do
            local z = first + (row + .5) * zoneLength / 4
            prop(kinds[row+1], -48, z, if row % 2 == 0 then 0 else 90)
            prop(kinds[(row+1)%4+1], 48, z, if row % 2 == 0 then 90 else 0)
        end
        -- Denser fence-line salvage bays leave pickup rows and the haul road clear.
        for row = 0, 5 do
            local z = first + (row + .5) * zoneLength / 6
            for _,side in {-1,1} do
                local x=side*(width/2-10)
                part("SalvageBed",{19,.08,28},{x,.05,z},{64,61,54},"Slate")
                prop(if row%3==0 then "Tires" elseif row%3==1 then "Pipes" else "Pile",x,z,0)
            end
        end
        -- High gantry: open roadway beneath, with the hook safely overhead.
        local craneZ = first + zoneLength / 2
        for _, side in {-1, 1} do
            part("CraneFoot", {9, 1, 12}, {side * (width/2-7), .5, craneZ}, dark)
            part("CraneMast", {3.5, 26, 3.5}, {side * (width/2-7), 13, craneZ}, amber)
        end
        part("CraneBeam", {width-10, 3, 4}, {0, 26, craneZ}, amber)
        part("CraneTrolley", {9, 3.5, 6}, {27, 24, craneZ}, dark)
        part("Cable", {.2, 10, .2}, {27, 17, craneZ}, black)
        part("Hook", {2.5, .7, 1}, {27, 11.8, craneZ}, steel)
    end
    part("EndFence", {width+2, 7, 1}, {0, 3.5, start+total}, dark)
    table.insert(layout.signs,{position={0,10,start+total-12},text="END OF THE YARD / RETURN TO YOUR WORKSHOP",color=amber})
    return layout
end

return Blueprint
