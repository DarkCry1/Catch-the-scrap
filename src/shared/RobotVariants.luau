--!strict
local Base=require("./RobotBlueprint")
local Catalog=require("./RobotCatalog")
local Forge=require("./RobotForge")
export type Part={name:string,step:number,size:{number},position:{number},palette:string,shape:string,yaw:number?,pitch:number?,roll:number?}
local Variants={}
function Variants.build(id:string): {Part}
    local species=Catalog.get(id)
    -- Forge species carry their own design; the ten original chassis below
    -- are hand-built variations of the Scrap Bot MK-I blueprint.
    if species.Design then return Forge.build(species.Design) end
    local parts:{Part}={}
    local function add(name:string,size:{number},position:{number},palette:string,shape:string?,yaw:number?,roll:number?)
        table.insert(parts,{name=name..tostring(#parts+1),step=5,size=size,position=position,palette=palette,shape=shape or "Block",yaw=yaw,roll=roll})
    end
    for _,d in Base do
        local omit=((id=="Magnet" or id=="Orbital") and d.step==1) or (id=="Driller" and (d.name=="RightHand" or d.name=="RightForearm")) or (id=="Orbital" and (d.name=="LeftEye" or d.name=="RightEye" or d.name=="Visor" or d.name=="Antenna" or d.name=="AntennaLight"))
        if omit then continue end
        local sx,sy,sz=1,1,1
        if id=="Bastion" then sx,sy,sz=1.25,.9,1.15 elseif id=="Volt" then sx,sy,sz=.78,1.06,.85 elseif id=="Magnet" then sy=.88 end
        local shape=if id=="Orbital" and d.name=="Torso" then "Ball" else d.shape
        table.insert(parts,{name=d.name,step=d.step,size={d.size[1]*sx,d.size[2]*sy,d.size[3]*sz},position={d.position[1]*sx,d.position[2]*sy,d.position[3]*sz},palette=d.palette,shape=shape,yaw=d.yaw})
    end
    if id=="Bastion" then
        add("FortressChest",{4.2,1.5,.55},{0,4.4,1.4},"dark")
        for _,s in {-1,1} do
            add("TowerPauldron",{1.4,1.8,2.3},{s*3,5.2,0},"steel")
            add("Shield",{1.6,2.5,.5},{s*3,3.2,1.2},"amber")
            add("HelmetGuard",{.45,1.6,2.2},{s*1.55,6.3,0},"dark")
        end
        add("ReactorSlit",{2.5,.25,.1},{0,4.5,1.72},"energy")
    elseif id=="Volt" then
        for _,s in {-1,1} do
            add("SprintFin",{.18,2.4,1.1},{s*1.8,6,-.4},"energy","Block",0,-s*18)
            add("JetPod",{.7,2.4,.7},{s*.85,5.3,-1.2},"dark")
            add("Thruster",{.5,.5,.5},{s*.85,4,-1.2},"energy","Ball")
            add("HeelBlade",{.35,.35,2.3},{s*.8,.6,-.9},"steel")
        end
    elseif id=="Driller" then
        for ring=0,5 do
            local radius=1.5-ring*.21
            add("DrillSegment"..ring,{.48,radius,radius},{2.3,3.2,.5+ring*.4},if ring%2==0 then "steel" else "copper","Cylinder",90)
        end
        add("MinerHelmet",{2.8,.55,2.4},{0,7.65,0},"copper")
        add("Headlamp",{.7,.7,.3},{0,7.7,1.35},"energy","Ball")
        add("ToolTank",{1.4,2.9,1.2},{-1,4.7,-1.5},"copper")
    elseif id=="Magnet" then
        add("TankSuspension",{3.2,.8,2.5},{0,1.8,0},"steel")
        for _,s in {-1,1} do
            add("TrackHousing",{1.5,1.5,3.6},{s*1.2,.85,0},"dark")
            for z=-1,1 do add("TrackWheel",{.2,1.15,1.15},{s*2,.85,z*1.1},"steel","Cylinder") end
            add("MagnetProng",{.65,2.1,.7},{s*1.1,5.3,2},"copper")
            add("MagnetTip",{.68,.5,.75},{s*1.1,6.5,2},"energy")
        end
        add("MagnetBridge",{2.9,.7,.7},{0,4.2,2},"copper")
        add("AerialDish",{.4,2.1,2.1},{0,8.1,-.4},"steel","Cylinder",0,90)
    elseif id=="Orbital" then
        add("CyclopsEye",{1.1,1.1,.6},{0,7,1.1},"energy","Ball")
        for i=0,11 do
            local a=i*math.pi/6
            add("OrbitSegment"..i,{.9,.17,.2},{math.cos(a)*2.3,4.6+math.sin(a)*2.3,1.4},"amber","Block",0,math.deg(a)+90)
        end
        for _,s in {-1,1} do
            add("HoverEngine",{1.2,1.7,1.2},{s*2.5,3.8,-1},"dark","Cylinder",0,90)
            add("IonJet",{.85,.8,.85},{s*2.5,2.6,-1},"energy","Ball")
        end
        add("CrownCore",{.8,.8,.8},{0,8.4,0},"energy","Ball")
    elseif id=="Sunforge" then
        for _,s in {-1,1} do
            add("SolarWing",{1.6,3,.22},{s*3.6,5.4,-.7},"dark","Block",0,s*15)
            for bar=0,3 do add("SolarCircuit",{1.4,.13,.08},{s*3.6,4.4+bar*.6,-.53},"energy") end
            add("SecondArm",{1.7,.65,.8},{s*2.6,3.6,0},"steel","Block",0,s*20)
            add("SecondClaw",{.6,1.1,.8},{s*3.5,3.5,0},"copper")
            add("CrownProng",{.25,1.3,.3},{s*.7,8.3,0},"copper","Block",0,-s*20)
        end
        add("CrownLight",{.6,.6,.6},{0,8.9,0},"energy","Ball")
    elseif id=="Weldsmith" then
        add("WeldingMask",{2.65,2,.35},{0,6.85,1.1},"dark")
        add("WeldingWindow",{1.65,.42,.12},{0,7.05,1.35},"energy")
        for _,side in {-1,1} do
            add("GasCylinder",{2.3,.9,.9},{side*.8,4.6,-1.5},"copper","Cylinder",0,90)
            add("ForearmCuff",{1.35,1.15,1.4},{side*2.3,3.3,0},"steel")
        end
        add("PlasmaTorch",{.4,1.7,.4},{2.8,2.8,.8},"copper","Cylinder",0,90)
        add("TorchTip",{.32,.65,.32},{2.8,3.85,.8},"energy","Ball")
    elseif id=="Hauler" then
        add("CargoRack",{4.6,2.7,1.8},{0,4.6,-1.6},"copper")
        for _,side in {-1,1} do
            add("LoaderFork",{.55,.4,3.8},{side*1.3,1.3,2.4},"steel")
            add("ForkArm",{.55,2.3,.5},{side*1.3,2.4,1.2},"dark")
            add("WarningBeacon",{.5,.6,.5},{side*2.1,6,-1.6},"energy","Ball")
        end
    elseif id=="Prism" then
        add("PrismMantle",{4.5,.5,2.5},{0,5.6,0},"copper")
        for i=0,5 do
            local a=i*math.pi/3
            add("FloatingCrystal",{.42,1.5,.42},{math.cos(a)*2.8,6.6+math.sin(a)*1.4,0},"energy","Block",0,math.deg(a)+35)
        end
        add("OracleEye",{1.2,.8,.4},{0,6.95,1.4},"energy","Ball")
    else
        add("ChronoCrest",{.3,1.5,1.6},{0,8.25,0},"copper")
        for i=0,11 do
            local a=i*math.pi/6
            add("ClockDial",{.16,.42,.18},{math.cos(a)*1.05,4.6+math.sin(a)*1.05,1.65},"energy","Block",0,math.deg(a))
        end
        for _,side in {-1,1} do
            add("TimeShield",{1.2,2.1,.4},{side*2.8,3.3,1},"copper")
            add("ClockSpire",{.3,1.8,.3},{side*1.4,7.5,-.3},"steel","Block",0,-side*12)
        end
    end
    return parts
end
return Variants
