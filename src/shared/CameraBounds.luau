--!strict
-- Clip the focus-to-camera segment against the connected plaza/yard volumes.
-- This does not depend on wall parts being streamed in or Roblox's occlusion mode.
local Config=require("./Config")
export type Point={x:number,y:number,z:number}
local Bounds={}
local function interval(focus:Point,delta:Point,x:number,z0:number,z1:number,padding:number): (number,number)
    local low,high=0,1
    for _,axis in {"x","y","z"} do
        local origin=if axis=="x" then focus.x elseif axis=="y" then focus.y else focus.z
        local direction=if axis=="x" then delta.x elseif axis=="y" then delta.y else delta.z
        local minimum=if axis=="x" then -x elseif axis=="y" then .5 else z0
        local maximum=if axis=="x" then x elseif axis=="y" then Config.WallHeight-padding else z1
        if math.abs(direction)<1e-9 then
            if origin<minimum or origin>maximum then return 1,0 end
        else
            local a,b=(minimum-origin)/direction,(maximum-origin)/direction
            low=math.max(low,math.min(a,b));high=math.min(high,math.max(a,b))
        end
    end
    return low,high
end
function Bounds.limit(focus:Point,desired:Point,padding:number): Point
    local endZ=Config.TrackStart+Config.ZoneLength*#Config.Stages
    local function project(x:number,z0:number,z1:number): Point
        return {x=math.clamp(focus.x,-x,x),y=math.clamp(focus.y,.5,Config.WallHeight-padding),z=math.clamp(focus.z,z0,z1)}
    end
    local plazaX,plazaBack=Config.Plaza.HalfWidth,Config.Plaza.BackZ
    local plaza=project(plazaX-padding,plazaBack+padding,Config.TrackStart)
    local yard=project(Config.TrackWidth/2-padding,Config.TrackStart,endZ-padding)
    local function distance(p:Point): number return (p.x-focus.x)^2+(p.y-focus.y)^2+(p.z-focus.z)^2 end
    focus=if distance(plaza)<=distance(yard) then plaza else yard
    local delta={x=desired.x-focus.x,y=desired.y-focus.y,z=desired.z-focus.z}
    local plazaLow,plazaHigh=interval(focus,delta,plazaX-padding,plazaBack+padding,Config.TrackStart,padding)
    local yardLow,yardHigh=interval(focus,delta,Config.TrackWidth/2-padding,Config.TrackStart,endZ-padding,padding)
    local high=0
    if plazaLow<=0 and plazaHigh>=0 then high=plazaHigh end
    if yardLow<=0 and yardHigh>=0 then high=math.max(high,yardHigh) end
    -- Extend only through overlapping intervals. Never leap across the entrance corner.
    if plazaLow<=high+1e-8 and plazaHigh>=plazaLow then high=math.max(high,plazaHigh) end
    if yardLow<=high+1e-8 and yardHigh>=yardLow then high=math.max(high,yardHigh) end
    high=math.clamp(high,0,1)
    return {x=focus.x+delta.x*high,y=focus.y+delta.y*high,z=focus.z+delta.z*high}
end
return Bounds
