--!strict
-- Original native-part salvage models. Geometry also drives asset previews/clearance.
export type Part = {name:string,size:{number},position:{number},color:{number},material:string,shape:string,yaw:number,roll:number}
local PickupBlueprint={}
function PickupBlueprint.build(rarity: string, tint: {number}): {Part}
    local parts: {Part}={}
    local steel,dark,copper,gold={148,164,169},{28,35,43},{179,109,62},{218,163,54}
    local function add(name:string,size:{number},position:{number},color:{number},material:string?,shape:string?,yaw:number?,roll:number?)
        table.insert(parts,{name=name,size=size,position=position,color=color,material=material or "Metal",shape=shape or "Block",yaw=yaw or 0,roll=roll or 0})
    end
    local function disc(name:string,diameter:number,depth:number,z:number,color:{number},material:string?)
        add(name,{depth,diameter,diameter},{0,0,z},color,material,"Cylinder",90)
    end
    local function ring(name:string,radius:number,z:number,color:{number},material:string?,segments:number?)
        local count=segments or 12
        for i=0,count-1 do
            local angle=i*2*math.pi/count
            add(name,{2*radius*math.sin(math.pi/count)*.9,.13,.16},{math.cos(angle)*radius,math.sin(angle)*radius,z},color,material,"Block",0,math.deg(angle)+90)
        end
    end
    local function bolts(radius:number,z:number,count:number,color:{number}?)
        for i=0,count-1 do
            local angle=i*2*math.pi/count
            add("HexBolt",{.14,.24,.24},{math.cos(angle)*radius,math.sin(angle)*radius,z},color or steel,"Metal","Cylinder",90)
        end
    end
    if rarity=="Common" then
        disc("WeatheredGear",2.65,.38,0,copper,"CorrodedMetal")
        disc("RecessedFace",2.2,.05,.22,dark)
        disc("RaisedHub",1.15,.65,0,steel)
        disc("AxleSocket",.55,.69,0,dark)
        ring("MachinedFace",1.08,.26,steel)
        for tooth=0,11 do
            local a=tooth*math.pi/6
            add("GearTooth",{.5,.42,.48},{math.cos(a)*1.43,math.sin(a)*1.43,0},steel,"Metal","Block",0,math.deg(a))
        end
        bolts(.78,.32,6,copper)
        add("SalvageMark",{.28,.17,.05},{0,1.08,.32},tint,"Neon")
    elseif rarity=="Uncommon" then
        disc("MotorCasing",1.85,2.35,0,steel)
        disc("EndCap",2.05,.18,1.15,dark)
        disc("Bearing",.9,.25,1.3,copper)
        disc("Shaft",.4,.8,1.7,steel)
        for z=-.9,.7,.32 do disc("CoolingFin",2.04,.09,z,dark) end
        for coil=0,5 do disc("CopperWinding",1.72,.09,-1.1+coil*.09,copper) end
        bolts(.73,1.29,6)
        add("TerminalBox",{.85,.45,.9},{0,1.12,-.1},dark)
        for _,side in {-1,1} do
            add("Insulator",{.16,.25,.2},{side*.22,1.45,-.1},copper)
            add("MountFoot",{.5,.23,2.3},{side*.75,-1.05,0},dark)
        end
        add("SerialPlate",{.8,.24,.08},{0,.4,1.3},tint,"Neon")
    elseif rarity=="Rare" then
        add("ContainedPlasma",{1.3,1.8,1.3},{0,0,0},tint,"Neon","Ball")
        for _,side in {-1,1} do
            add("ContainmentCap",{.27,2.25,2.25},{0,side*1.05,0},dark,"Metal","Cylinder",0,90)
            add("CapInset",{.1,1.65,1.65},{0,side*1.23,0},steel,"Metal","Cylinder",0,90)
        end
        for i=0,3 do
            local a=i*math.pi/2
            add("ContainmentRail",{.19,1.95,.24},{math.cos(a),0,math.sin(a)},steel)
            add("RailEnergy",{.08,1.3,.09},{math.cos(a)*1.08,0,math.sin(a)*1.08},tint,"Neon")
        end
        ring("ContainmentOrbit",1.42,0,steel)
        bolts(.9,.8,6,copper)
        add("WarningPlate",{.85,.3,.15},{0,-.5,.95},copper)
    elseif rarity=="Epic" then
        disc("TurbineHousing",2.95,.65,0,dark)
        disc("InnerRecess",2.55,.08,.36,copper)
        disc("RotorHub",.8,.65,.4,steel)
        disc("RotorLens",.43,.05,.76,tint,"Neon")
        ring("EnergizedRim",1.52,.38,tint,"Neon")
        for blade=0,9 do
            local a=blade*math.pi/5
            add("SweptBlade",{.95,.28,.12},{math.cos(a)*.92,math.sin(a)*.92,.47},steel,"Metal","Block",0,math.deg(a)+30)
        end
        bolts(1.35,-.38,8)
        for _,side in {-1,1} do add("Mount",{.32,.65,.9},{side*1.35,-.8,0},copper) end
    elseif rarity=="Legendary" then
        add("FusionGlass",{1.2,1.7,1.2},{0,0,0},tint,"Neon","Ball")
        for _,side in {-1,1} do
            add("GoldCap",{.32,2.1,2.1},{0,side*1.05,0},gold,"Metal","Cylinder",0,90)
            add("CapSocket",{.15,1.1,1.1},{0,side*1.28,0},dark,"Metal","Cylinder",0,90)
        end
        for i=0,5 do
            local a=i*math.pi/3
            add("GoldCage",{.15,1.9,.22},{math.cos(a)*.92,0,math.sin(a)*.92},gold)
            add("FusionFeed",{.08,1.3,.08},{math.cos(a)*1.04,0,math.sin(a)*1.04},tint,"Neon")
        end
        ring("FusionOrbit",1.6,0,gold)
        bolts(1.3,.18,8,gold)
        disc("SerialBadge",.35,.15,1.15,dark)
    elseif rarity=="Mythic" or rarity=="Celestial" then
        local celestial=rarity=="Celestial"
        add("SingularityShell",{1.65,1.65,1.65},{0,0,0},dark,"Metal","Ball")
        add("StellarHeart",{1.12,1.12,1.12},{0,0,.6},tint,"Neon","Ball")
        ring("OrbitalCage",1.48,0,if celestial then gold else steel)
        ring("EnergyOrbit",1.23,.45,tint,"Neon")
        for i=0,5 do
            local a=i*math.pi/3
            add("FieldClamp",{.48,.3,.5},{math.cos(a)*1.45,math.sin(a)*1.45,0},if celestial then gold else copper,"Metal","Block",0,math.deg(a))
            add("FieldCrystal",{.18,.3,.18},{math.cos(a)*1.67,math.sin(a)*1.67,0},tint,"Neon","Block",0,math.deg(a)+45)
        end
        if celestial then
            for _,side in {-1,1} do
                add("SolarFin",{.55,1,.13},{side*1.75,0,0},steel,"DiamondPlate","Block",0,side*15)
                for y=-.3,.3,.3 do add("SolarCircuit",{.38,.05,.05},{side*1.75,y,.1},tint,"Neon") end
            end
        else
            bolts(.95,-.7,8,copper)
        end
    else
        error("Unknown pickup rarity: "..rarity)
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
    -- Extra room for idle tilt; animation only lifts above this origin.
    return -bottom+.3
end
return PickupBlueprint
