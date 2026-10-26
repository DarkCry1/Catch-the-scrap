--!strict
-- Deterministic, original scrapyard geometry. Shared with tests and asset renders.
export type Part = { name: string, size: {number}, position: {number}, color: {number}, material: string,
    shape: string, yaw: number, pitch: number, roll: number, collidable: boolean, transparency: number, reflectance: number }
export type Spawn = { position: {number}, rarity: string }
export type Sign = { position: {number}, text: string, color: {number} }
export type Bounds = { x: number, z: number, width: number, depth: number }
export type Effect = {kind: string, position: {number}, color: {number}}
export type Layout = { parts: {Part}, spawns: {Spawn}, signs: {Sign}, bounds: {Bounds}, effects: {Effect}, crates: {{position: {number},stage: number}} }
local Config = require("./Config")
local Blueprint = {}

function Blueprint.build(width: number, zoneLength: number, start: number): Layout
    assert(width >= 120 and zoneLength >= 240, "Yard must fit its paths and props")
    local layout: Layout = { parts = {}, spawns = {}, signs = {}, bounds = {}, effects = {}, crates = {} }
    local steel, rust, dark = {100, 117, 120}, {142, 77, 45}, {35, 44, 48}
    local amber, black = {232, 168, 54}, {20, 26, 28}
    local function part(name: string, size: {number}, position: {number}, color: {number}, material: string?, shape: string?, yaw: number?, roll: number?, solid: boolean?, transparency: number?, reflectance: number?)
        table.insert(layout.parts, { name = name, size = size, position = position, color = color,
            material = material or "Metal", shape = shape or "Block", yaw = yaw or 0, pitch = 0, roll = roll or 0,
            collidable = if solid == nil then true else solid, transparency = transparency or 0, reflectance = reflectance or 0 })
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
            for roofX=-6,6,3 do at("RoofSeam",{.18,.2,27},{roofX,10.45,0},dark) end
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
            for _,side in {-1,1} do
                at("DoorSeam",{.16,2.4,9},{side*7.1,3.2,-1},dark)
                at("Headlight",{2,.65,.2},{side*4.5,3,12.5},{191,173,116},"Glass")
                for _,endZ in {-7,7} do at("WheelHub",{.12,2.2,2.2},{side*7.8,2.5,endZ},steel,"Metal","Cylinder") end
            end
            at("HoodBrace",{.25,.2,7},{0,4.45,8.5},dark)
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
            for band=-2,2,2 do at("RivetBand",{.24,10.2,.24},{band,6,6.55},dark) end
            at("Vent", {4, 4, 4}, {0, 13, 0}, rust)
            at("Cap", {6, .4, 6}, {0, 15.2, 0}, dark)
        elseif kind == "Turbine" or kind == "Furnace" or kind == "VoidEngine" or kind == "StarEngine" then
            w,d=20,20
            local tint=if kind=="Turbine" then Config.Robot.Recipes.Epic.Color elseif kind=="Furnace" then Config.Robot.Recipes.Legendary.Color elseif kind=="VoidEngine" then Config.Robot.Recipes.Mythic.Color else Config.Robot.Recipes.Celestial.Color
            at("Plinth",{19,1,19},{0,.5,0},dark,"DiamondPlate")
            if kind=="Turbine" then
                at("Housing",{8,16,16},{0,8,0},steel,"CorrodedMetal","Cylinder",90)
                at("Face",{.3,13,13},{0,8,4.2},dark,"Metal","Cylinder",90)
                at("Hub",{.6,4,4},{0,8,4.6},tint,"Neon","Cylinder",90)
                for blade=0,7 do
                    local angle=blade*math.pi/4
                    at("Blade",{4,1,.5},{math.cos(angle)*4,8+math.sin(angle)*4,4.5},steel,"Metal","Block",0,math.deg(angle)+25)
                end
            elseif kind=="Furnace" then
                at("Shell",{16,13,15},{0,7,0},steel,"CorrodedMetal")
                at("Door",{11,8,.4},{0,6,7.7},dark)
                for slit=-2,2 do at("HotGrille",{1.3,6,.2},{slit*1.8,6,8},tint,"Neon") end
                for _,side in {-1,1} do at("Exhaust",{8,3,3},{side*5,17,0},rust,"CorrodedMetal","Cylinder",0,90) end
            else
                at("Core",{7,7,7},{0,8,0},tint,"Neon","Ball")
                for _,side in {-1,1} do
                    at("Support",{2,14,2},{side*7,7,0},steel)
                    at("Clamp",{15,1,3},{0,8+side*6,0},dark)
                end
                for blade=0,7 do
                    local angle=blade*math.pi/4
                    at("OrbitSegment",{5,.6,.8},{math.cos(angle)*7,8+math.sin(angle)*7,0},if kind=="StarEngine" then tint else steel,"Metal","Block",0,math.deg(angle)+90)
                end
            end
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
    local total = zoneLength * #Config.Stages
    local wallHeight = Config.WallHeight
    part("HomeGround",{208,2,320},{0,-1,-140},{58,63,62},"Concrete")
    for _,side in {-1,1} do
        part("PlazaBoundary",{4,wallHeight,320},{side*104,wallHeight/2,-140},dark,"Concrete")
        part("PlazaFrontBoundary",{24,wallHeight,4},{side*94,wallHeight/2,20},dark,"Concrete")
        for bay=0,7 do
            part("PlazaSalvageCladding",{.35,wallHeight-6,35},{side*101.7,wallHeight/2,-280+bay*40},if bay%2==0 then rust else steel,"CorrodedMetal","Block",0,0,false)
            part("PlazaWallTop",{5,3,16},{side*105,wallHeight+1,-280+bay*40},rust,"CorrodedMetal","Block",bay*20,0,false)
        end
    end
    part("PlazaBackBoundary",{208,wallHeight,4},{0,wallHeight/2,-300},dark,"Concrete")
    for x=-90,90,30 do part("PlazaBackCladding",{25,wallHeight-6,.35},{x,wallHeight/2,-297.7},rust,"CorrodedMetal","Block",0,0,false) end
    -- Segments stay below Roblox's 2048-stud BasePart size limit and stream locally.
    for zone=1,#Config.Stages do
        part("YardTerrain", {width + 140, 2, zoneLength}, {0, -2, start + (zone-.5)*zoneLength}, {80, 72, 56}, "Ground")
    end
    for zone, stage in Config.Stages do
        local first = start + (zone - 1) * zoneLength
        local tint = stage.Color
        part("YardFloor", {width, 1, zoneLength}, {0, -.5, first + zoneLength / 2}, if zone == 1 then {100, 94, 80} else {78, 75, 65}, if zone == 1 then "Concrete" else "Ground")
        part("HaulRoad", {34, .08, zoneLength}, {0, .05, first + zoneLength / 2}, {54, 58, 57}, "Asphalt")
        for _, side in {-1, 1} do
            part("SafetyLine", {.3, .05, zoneLength}, {side * 17, .12, first + zoneLength / 2}, amber, "SmoothPlastic", "Block", 0, 0, false)

        end
        table.insert(layout.signs, {position={0, 14, first + 15},text=string.format("STAGE %02d / %s / %s",zone,stage.Rarity:upper(),stage.Name:upper()),color=tint})
        for row = 0, 7 do
            for _, x in {-55, -22, 22, 55} do
                table.insert(layout.spawns,{ position={x, 2.2, first + (row + .5) * zoneLength / 8}, rarity=stage.Rarity })
            end
        end
        for index=1,Config.Crates.PerStage do
            table.insert(layout.crates,{position={if index%2==1 then -22 else 22,2.3,first+zoneLength*(index-.5)/Config.Crates.PerStage},stage=zone})
        end
        local kinds = if zone == 1 then {"Container", "CarWreck", "Tires", "Pile"} elseif zone == 2 then {"Pipes", "CarWreck", "Container", "RobotWreck"} elseif zone==3 then {"Reactor", "RobotWreck", "Pipes", "Reactor"} elseif zone==4 then {"Turbine", "Pipes", "Turbine", "RobotWreck"} elseif zone==5 then {"Furnace", "Container", "Furnace", "Reactor"} elseif zone==6 then {"VoidEngine", "RobotWreck", "VoidEngine", "Reactor"} else {"StarEngine", "Reactor", "StarEngine", "RobotWreck"}
        for row = 0, 3 do
            local z = first + (row + .5) * zoneLength / 4
            prop(kinds[row+1], -48, z, if row % 2 == 0 then 0 else 90)
            prop(kinds[(row+1)%4+1], 48, z, if row % 2 == 0 then 90 else 0)
        end
        -- Color-keyed gateway: each salvage district has its own identity.
        for _, side in {-1,1} do
            part("StagePylon",{3,22,3},{side*24,11,first+8},dark)
            part("StageEnergyStrip",{.22,17,.22},{side*22.4,11,first+6.4},tint,"Neon","Block",0,0,false)
        end
        part("StageGantry",{52,2,3},{0,22,first+8},dark)
        part("StageGantryAccent",{46,.3,.2},{0,22,first+6.4},tint,"Neon","Block",0,0,false)
        -- Denser fence-line salvage bays leave pickup rows and the haul road clear.
        for row = 0, 5 do
            local z = first + (row + .5) * zoneLength / 6
            for _,side in {-1,1} do
                local x=side*(width/2-10)
                part("SalvageBed",{19,.08,28},{x,.05,z},{64,61,54},"Slate")
                prop(if row%3==0 then "Tires" elseif row%3==1 then "Pipes" else "Pile",x,z,0)
            end
        end
        for row=0,3 do
            local z=first+(row+.5)*zoneLength/4
            for _,side in {-1,1} do
                part("ConcreteRepair",{12,.05,20},{side*25,.08,z},{69,68,60},"Concrete","Block",row*13,0,false)
                part("OilStain",{9,.035,13},{side*34,.13,z+16},{25,31,32},"Glass","Block",row*21,0,false,.42,.12)
            end
            part("DrainFrame",{4,.12,9},{-18.8,.15,z+24},dark,"Metal","Block",0,0,false)
            for groove=-2,2 do part("DrainSlat",{3,.1,.2},{-18.8,.24,z+24+groove*1.4},steel,"Metal","Block",0,0,false) end
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
        part("Magnet",{1.5,7,7},{27,10.6,craneZ},dark,"Metal","Cylinder",0,90)
        part("MagnetRim",{.2,7.2,7.2},{27,9.8,craneZ},amber,"Metal","Cylinder",0,90)
        table.insert(layout.effects,{kind=if zone>=3 then "sparks" else "smoke",position={-48,if zone==1 then 5.5 elseif zone==2 then 8 else 14,first+zoneLength*.875},color=if zone>=3 then tint else {124,117,100}})
    end
    -- Tall continuous walls are structural; layered salvage is noncolliding cladding.
    for _,side in {-1,1} do
        for zone=1,#Config.Stages do
            part("BoundaryWall",{4,wallHeight,zoneLength},{side*(width/2+4),wallHeight/2,start+(zone-.5)*zoneLength},{46,52,52},"Concrete")
        end
        for bay=0,math.floor(total/40)-1 do
            local z=start+bay*40+20
            local tint=if bay%3==0 then rust elseif bay%3==1 then {91,109,105} else {115,104,83}
            part("WallLowerScrap",{.5,wallHeight/2-3,35},{side*(width/2+1.6),wallHeight/4,z},tint,"CorrodedMetal","Block",0,(bay%3-1)*3,false)
            part("WallUpperScrap",{.4,wallHeight/2-3,31},{side*(width/2+1.4),wallHeight*.75,z+3},if bay%2==0 then steel else rust,"CorrodedMetal","Block",0,0,false)
            part("WallReinforcement",{1.6,wallHeight+2,1.4},{side*(width/2+1.2),wallHeight/2,z-19},dark)
            part("RaggedWallTop",{7,4+(bay%3),16},{side*(width/2+5),wallHeight+1,z-7},tint,"CorrodedMetal","Block",bay*19,12,false)
            if bay%2==0 then
                part("WallSafetyPatch",{.12,1.5,7},{side*(width/2+.95),4,z+9},amber,"Metal","Block",0,0,false)
            end
            if bay%3==0 then
                part("WallLampHousing",{2,1,4},{side*(width/2),19,z},dark)
                part("WallLampLens",{1.7,.16,3.4},{side*(width/2),18.4,z},{255,204,129},"Neon","Block",0,0,false)
                table.insert(layout.effects,{kind="lamp",position={side*(width/2-1),18,z},color={255,204,150}})
            end
        end
        for zone=0,#Config.Stages-1 do
            local z=start+zone*zoneLength+zoneLength*.7
            part("SkylineSilo",{34,19,19},{side*(width/2+33),17,z},{74,82,80},"CorrodedMetal","Cylinder",0,90)
            part("SiloCap",{1,21,21},{side*(width/2+33),34.5,z},dark,"Metal","Cylinder",0,90)
            part("SiloExhaust",{10,4,4},{side*(width/2+33),40,z},rust,"CorrodedMetal","Cylinder",0,90)
        end
    end
    part("EntranceLintel",{width+12,4,6},{0,wallHeight-3,start},dark)
    for _,side in {-1,1} do
        part("EntrancePillar",{5,wallHeight,7},{side*(width/2+2),wallHeight/2,start},steel)
        part("EntranceLamp",{.35,15,.35},{side*(width/2-1),11,start-3.6},amber,"Neon","Block",0,0,false)
    end
    part("EndFence",{width+8,wallHeight,4},{0,wallHeight/2,start+total+2},dark,"Concrete")
    for x=-70,70,20 do
        part("EndWallCladding",{17,wallHeight-6,.5},{x,wallHeight/2,start+total-.1},if x%40==10 then rust else steel,"CorrodedMetal","Block",0,0,false)
    end
    table.insert(layout.signs,{position={0,10,start+total-12},text="END OF THE YARD / RETURN TO YOUR WORKSHOP",color=amber})
    return layout
end

return Blueprint
