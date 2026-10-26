--!strict
-- Readable salvage silhouettes, with one invisible carrier root supplied by ItemService.
export type Part = {name:string,size:{number},position:{number},color:{number},material:string,shape:string,yaw:number,roll:number}
local PickupBlueprint={}
function PickupBlueprint.build(rarity: string, tint: {number}): {Part}
    assert(rarity=="Common" or rarity=="Uncommon" or rarity=="Rare","Unknown pickup rarity")
    local parts: {Part}={}
    local steel,dark,copper={128,145,147},{31,40,44},{164,101,57}
    local function add(name:string,size:{number},position:{number},color:{number},material:string?,shape:string?,yaw:number?,roll:number?)
        table.insert(parts,{name=name,size=size,position=position,color=color,material=material or "Metal",shape=shape or "Block",yaw=yaw or 0,roll=roll or 0})
    end
    if rarity=="Common" then
        add("GearDisc",{.45,2.7,2.7},{0,0,0},copper,"CorrodedMetal","Cylinder",90)
        add("GearHub",{.75,1.2,1.2},{0,0,0},steel,"Metal","Cylinder",90)
        add("AxleSocket",{.8,.55,.55},{0,0,0},dark,"SmoothPlastic","Cylinder",90)
        for tooth=0,7 do
            local angle=tooth*math.pi/4
            add("GearTooth",{.65,.55,.5},{math.cos(angle)*1.5,math.sin(angle)*1.5,0},steel,"Metal","Block",0,math.deg(angle))
        end
    elseif rarity=="Uncommon" then
        add("MotorCasing",{2.5,1.7,1.8},{0,0,0},steel,"Metal","Cylinder",90)
        add("MotorBand",{.18,1.9,1.9},{0,0,.6},dark,"Metal","Cylinder",90)
        add("CopperCoil",{.35,1.5,1.5},{0,0,-.8},copper,"Metal","Cylinder",90)
        add("MotorShaft",{1.4,.45,.45},{0,0,1.1},steel,"Metal","Cylinder",90)
        add("Terminal",{.8,.5,.8},{0,1,0},dark)
        add("StatusLens",{.45,.15,.3},{0,1.3,0},tint,"Neon")
        for _,side in {-1,1} do add("MotorFoot",{.5,.3,2},{side*.8,-.95,0},dark) end
    else
        add("ReactorCore",{1.4,1.9,1.4},{0,0,0},tint,"Neon","Ball")
        for _,y in {-.95,.95} do add("CoreClamp",{.35,2.2,2.2},{0,y,0},dark,"Metal","Cylinder",0,90) end
        for _,x in {-1,1} do
            add("CoreBrace",{.28,1.9,.5},{x,0,0},steel)
            add("CoreBolt",{.32,.5,.5},{x,0,.3},copper,"Metal","Cylinder",90)
        end
        add("WarningPlate",{1,.4,.12},{0,-.2,1},copper)
    end
    return parts
end
function PickupBlueprint.clearance(rarity:string,tint:{number}): number
    local bottom=math.huge
    for _,part in PickupBlueprint.build(rarity,tint) do
        local angle=math.rad(part.roll)
        local halfHeight=math.abs(part.size[1]/2*math.sin(angle))+math.abs(part.size[2]/2*math.cos(angle))
        bottom=math.min(bottom,part.position[2]-halfHeight)
    end
    return -bottom+.15
end
return PickupBlueprint
