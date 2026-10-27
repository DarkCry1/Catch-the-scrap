--!strict
-- Server and tests share exact stage boundaries and loot ownership rules.
local Config=require("./Config")
local Rules={}
export type Point={x:number,z:number}
function Rules.bounds(stage:number,inset:number?): (number,number,number,number)
    assert(stage%1==0 and Config.Stages[stage],"Unknown guardian district")
    local pad=inset or 0
    local first=Config.TrackStart+(stage-1)*Config.ZoneLength
    return -Config.TrackWidth/2+pad,Config.TrackWidth/2-pad,first+pad,first+Config.ZoneLength-pad
end
function Rules.inside(stage:number,point:Point): boolean
    local x0,x1,z0,z1=Rules.bounds(stage)
    return point.x>=x0 and point.x<=x1 and point.z>=z0 and point.z<z1
end
function Rules.clamp(stage:number,point:Point,inset:number): Point
    local x0,x1,z0,z1=Rules.bounds(stage,inset)
    return {x=math.clamp(point.x,x0,x1),z=math.clamp(point.z,z0,z1)}
end
function Rules.protects(stage:number,slot:{zone:number?,crateStage:number?}?): boolean
    return slot~=nil and (slot.zone or slot.crateStage)==stage
end
function Rules.radius(stage:number): number return 4.0*Config.Guardians.Profiles[stage].Scale end
function Rules.height(stage:number): number return 9.1*Config.Guardians.Profiles[stage].Scale end
function Rules.catchRange(stage:number): number return Rules.radius(stage)+1.15 end
function Rules.patrol(stage:number,step:number): Point
    local _,_,first=Rules.bounds(stage)
    local cycle={{x=-5,z=64},{x=5,z=230},{x=-5,z=Config.ZoneLength-64},{x=5,z=230}}
    local p=cycle[(step-1)%#cycle+1]
    return {x=p.x,z=first+p.z}
end
return Rules
