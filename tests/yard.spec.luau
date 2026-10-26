--!strict
local Navigation=require("../src/shared/Navigation")
local Yard=require("../src/shared/ScrapyardBlueprint")
local Config=require("../src/shared/Config")
local assertions=0
local function check(condition: boolean,message: string)
    assertions+=1;assert(condition,message)
end
for _,direction in {-1,1} do
    for _,segment in Navigation.chevron(0,-80,direction) do
        check((segment.to.z-segment.from.z)*direction>0,"arrow tip must point in travel direction")
        check(segment.to.x==0,"two arms meet at a centered tip")
    end
end
local layout=Yard.build(Config.TrackWidth,Config.ZoneLength,Config.TrackStart)
check(Config.TrackWidth==160 and Config.ZoneLength*3==1440,"expanded yard dimensions")
check(#layout.spawns==96,"32 pickups per rarity zone")
check(#layout.parts<=Config.Visuals.YardPartBudget,"bounded static scenery budget for the visual overhaul")
local counts: {[string]: number}={}
for _,spawn in layout.spawns do
    local x,z=spawn.position[1],spawn.position[3]
    counts[spawn.rarity]=(counts[spawn.rarity] or 0)+1
    check(math.abs(x)<Config.TrackWidth/2-3,"spawn inside fences")
    check(z>Config.TrackStart and z<Config.TrackStart+Config.ZoneLength*3,"spawn inside length bounds")
    for _,bounds in layout.bounds do
        local blocked=math.abs(x-bounds.x)<bounds.width/2+2.5 and math.abs(z-bounds.z)<bounds.depth/2+2.5
        check(not blocked,"pickup must not overlap junk footprint")
    end
end
for _,rarity in {"Common","Uncommon","Rare"} do check(counts[rarity]==32,"balanced spawn coverage") end
for _,part in layout.parts do
    check(#part.size==3 and #part.position==3,"valid part vectors")
    for _,size in part.size do check(size>0,"positive scenery dimensions") end
    -- Every solid prop must leave the middle 28 studs clear at character height.
    if part.collidable and part.name~="EndFence" and part.position[3]>-280 and part.position[3]<Config.TrackStart+Config.ZoneLength*3-4 then
        local yaw,roll=math.rad(part.yaw),math.rad(part.roll)
        local sx,sy,sz=part.size[1]/2,part.size[2]/2,part.size[3]/2
        local rotatedX=math.abs(sx*math.cos(roll))+math.abs(sy*math.sin(roll))
        local halfX=math.abs(rotatedX*math.cos(yaw))+math.abs(sz*math.sin(yaw))
        local halfY=math.abs(sx*math.sin(roll))+math.abs(sy*math.cos(roll))
        local blocksLane=math.abs(part.position[1])-halfX<14 and part.position[2]+halfY>1 and part.position[2]-halfY<8
        check(not blocksLane,"haul road remains walkable: "..part.name)
    end
end
print(string.format("Yard/navigation checks passed; %d assertions; no skipped tests",assertions))
