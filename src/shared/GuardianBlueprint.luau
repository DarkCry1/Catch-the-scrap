--!strict
-- Original industrial wardens, built from our own Scrap Bot geometry.
local Base=require("./RobotBlueprint")
export type Part={name:string,size:{number},position:{number},palette:string,shape:string,group:string,yaw:number?,pitch:number?,roll:number?}
local Blueprint={}
Blueprint.Pivots={Torso={0,3.15,0},Head={0,5.85,0},LeftArm={-2.25,5.15,0},RightArm={2.25,5.15,0},LeftLeg={-1,2.8,0},RightLeg={1,2.8,0}}
local heads={Head=true,Brow=true,Visor=true,LeftEye=true,RightEye=true,Jaw=true,Neck=true,Antenna=true,AntennaLight=true}
function Blueprint.build(stage:number): {Part}
    local parts:{Part}={}
    for _,p in Base do
        local group="Torso"
        if heads[p.name] then group="Head" end
        for _,side in {"Left","Right"} do
            if p.name==side.."Boot" or p.name==side.."Toe" or p.name==side.."Shin" or p.name==side.."Knee" then group=side.."Leg" end
            if p.name==side.."Shoulder" or p.name==side.."Arm" or p.name==side.."Forearm" or p.name==side.."Hand" then group=side.."Arm" end
        end
        table.insert(parts,{name=p.name,size=p.size,position=p.position,palette=p.palette,shape=p.shape,yaw=p.yaw,group=group})
    end
    local function add(name:string,size:{number},pos:{number},palette:string,group:string,roll:number?)
        table.insert(parts,{name=name,size=size,position=pos,palette=palette,group=group,shape="Block",roll=roll})
    end
    for _,side in {-1,1} do
        local arm=if side<0 then "LeftArm" else "RightArm"
        local leg=if side<0 then "LeftLeg" else "RightLeg"
        add("WardenShoulder",{1.4,.4,2.2},{side*2.45,5.8,0},"dark",arm)
        add("ForearmGuard",{1.2,.85,.25},{side*2.3,3.2,.85},"steel",arm)
        add("ShinArmor",{.95,1.4,.2},{side,1.65,.65},"dark",leg)
        add("WarningStripe",{.28,.9,.06},{side*2.3,3.2,1.01},"amber",arm,side*25)
        add("ChestBrace",{.25,2.1,.2},{side*.95,4.5,1.3},"dark","Torso",side*28)
        if stage>=3 then add("RaisedPauldron",{.8,.6,1.9},{side*2.6,6.15,0},"amber",arm) end
        if stage>=4 then add("ExhaustStack",{.4,2,.4},{side*.85,6,-1.4},"copper","Torso") end
        if stage>=5 then add("CrownProng",{.3,1.25,.35},{side*.85,8.3,0},"amber","Head",-side*12) end
        if stage>=6 then add("ReactorFin",{.25,2.4,.6},{side*1.35,5.1,-1.3},"energy","Torso",-side*15) end
    end
    add("SecurityVisor",{2.1,.22,.12},{0,7.24,1.15},"energy","Head")
    add("WardenBadge",{.6,.5,.12},{0,3.55,1.2},"energy","Torso")
    if stage==7 then
        for i=0,7 do
            local a=i*math.pi/4
            add("AstralHalo",{.55,.15,.15},{math.cos(a)*1.5,8.65,math.sin(a)*1.5},"energy","Head")
        end
    end
    return parts
end
return Blueprint
