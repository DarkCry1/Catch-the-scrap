--!strict
export type Obstacle={x:number,z:number,halfX:number,halfZ:number}
export type Point={x:number,z:number}
local Yard=require("./ScrapyardBlueprint")
local Rules={}
function Rules.obstacles(parts:{Yard.Part}): {Obstacle}
    local result:{Obstacle}={}
    for _,p in parts do
        if not p.collidable then continue end
        local roll,yaw=math.rad(p.roll),math.rad(p.yaw)
        local sx,sy,sz=p.size[1]/2,p.size[2]/2,p.size[3]/2
        local halfY=math.abs(sx*math.sin(roll))+math.abs(sy*math.cos(roll))
        if p.position[2]+halfY<1 or p.position[2]-halfY>5 then continue end
        local rx=math.abs(sx*math.cos(roll))+math.abs(sy*math.sin(roll))
        table.insert(result,{x=p.position[1],z=p.position[3],halfX=math.abs(rx*math.cos(yaw))+math.abs(sz*math.sin(yaw)),halfZ=math.abs(rx*math.sin(yaw))+math.abs(sz*math.cos(yaw))})
    end
    return result
end
function Rules.safe(p:Point,width:number,first:number,length:number,obstacles:{Obstacle},occupied:{Point},previous:Point?): boolean
    if not (math.abs(p.x)>=20 and math.abs(p.x)<=width/2-6 and p.z>=first+8 and p.z<=first+length-8) then return false end
    if previous and (p.x-previous.x)^2+(p.z-previous.z)^2<144 then return false end
    for _,b in obstacles do if math.abs(p.x-b.x)<b.halfX+3 and math.abs(p.z-b.z)<b.halfZ+3 then return false end end
    for _,b in occupied do if (p.x-b.x)^2+(p.z-b.z)^2<49 then return false end end
    return true
end
function Rules.choose(width:number,first:number,length:number,obstacles:{Obstacle},occupied:{Point},previous:Point?,sample:()->number): Point?
    for _=1,120 do
        local side=if sample()<.5 then -1 else 1
        local p={x=side*(20+sample()*(width/2-26)),z=first+8+sample()*(length-16)}
        if Rules.safe(p,width,first,length,obstacles,occupied,previous) then return p end
    end
    -- Deterministic safety fallback, never an unsafe or previous spawn.
    for z=first+8,first+length-8,8 do for x=-width/2+6,width/2-6,8 do
        local p={x=x,z=z};if Rules.safe(p,width,first,length,obstacles,occupied,previous) then return p end
    end end
    return nil
end
return Rules
