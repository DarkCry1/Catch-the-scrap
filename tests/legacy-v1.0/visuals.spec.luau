--!strict
local Config=require("../../src/shared/Config")
local Yard=require("../../src/shared/ScrapyardBlueprint")
local Pickups=require("../../src/shared/PickupBlueprint")
local Placement=require("../../src/shared/PlacementRules")
local checks=0
local function check(ok:boolean,message:string) checks+=1;assert(ok,message) end
local layout=Yard.build(Config.TrackWidth,Config.ZoneLength,Config.TrackStart)
local walls=0
for _,part in layout.parts do
    if part.name=="BoundaryWall" then
        walls+=1
        check(part.collidable and part.size[2]>=64 and part.size[3]==Config.ZoneLength,"continuous tall perimeter wall")
        check(math.abs(part.position[1])-part.size[1]/2>Config.TrackWidth/2,"solid wall stays outside the pickup field")
    end
    if part.name=="WallLowerScrap" or part.name=="WallUpperScrap" then
        check(part.material=="CorrodedMetal" and not part.collidable,"visible scrap cladding does not add jagged invisible collision")
    end
end
check(walls==2*#Config.Stages,"both long sides enclosed")
check(#layout.effects<=70,"bounded ambient-effect budget")
for _,effect in layout.effects do
    check(effect.kind=="lamp" or effect.kind=="smoke" or effect.kind=="sparks","known effect types only")
end
for _,item in Config.Items do
    local parts=Pickups.build(item.rarity,item.color)
    local clearance=Pickups.clearance(item.rarity,item.color)
    check(#parts+14<=Config.Visuals.PickupPartBudget,"bounded detail budget per collectible")
    check(clearance>=1 and clearance<=2.4,"portable visual footprint")
    for _,part in parts do
        local roll=math.rad(part.roll)
        local halfY=math.abs(part.size[1]/2*math.sin(roll))+math.abs(part.size[2]/2*math.cos(roll))
        check(part.position[2]-halfY+clearance>=.149,"spawned/dropped visual clears the ground")
        for _,size in part.size do check(size>=.05,"supported positive part dimensions") end
    end
end
check(Placement.safeGround(0,100,160,480,20),"normal yard drop allowed")
check(Placement.safeGround(55,7,160,480,20),"plaza drop allowed")
for _,point in {{84,100},{-84,100},{0,Config.TrackStart+Config.ZoneLength*#Config.Stages+1},{105,-100},{0,-300},{0/0,100},{0,0/0}} do
    check(not Placement.safeGround(point[1],point[2],160,480,20),"drop cannot strand loot behind a new wall or outside playable bounds")
end
print(string.format("Visual/perimeter/placement checks passed; %d assertions",checks))
