--!strict
local PlacementRules={}
-- Keep dropped visual bounds inside the new solid perimeter, away from its edges.
function PlacementRules.safeGround(x:number,z:number,width:number,zoneLength:number,start:number): boolean
    if z>=start then return z<=start+zoneLength*3-4 and math.abs(x)<=width/2-4 end
    return z>=-292 and z<start and math.abs(x)<=96
end
return PlacementRules
