--!strict
local Config=require("./Config")
local PlacementRules={}
-- Keep dropped visual bounds inside the new solid perimeter, away from its edges.
function PlacementRules.safeGround(x:number,z:number,width:number,zoneLength:number,start:number): boolean
    if z>=start then return z<=start+zoneLength*#Config.Stages-4 and math.abs(x)<=width/2-4 end
    return z>=Config.Plaza.BackZ+6 and z<start and math.abs(x)<=Config.Plaza.HalfWidth-6
end
return PlacementRules
