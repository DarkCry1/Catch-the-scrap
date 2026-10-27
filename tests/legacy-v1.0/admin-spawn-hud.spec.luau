--!strict
local Admin=require("../../src/shared/AdminRules")
local Hud=require("../../src/shared/HudModel")
local Spawn=require("../../src/shared/SpawnRules")
local Yard=require("../../src/shared/ScrapyardBlueprint")
local Config=require("../../src/shared/Config")
local checks=0
local function check(ok:boolean,message:string) checks+=1;assert(ok,message) end
check(Admin.allowed(11824623188,false,false,false,{11824623188}),"explicit requested account can administer published game")
check(not Admin.allowed(55,false,true,false,{11824623188}),"Studio allowance cannot grant admin on a published server")
check(Admin.allowed(-1,true,true,false,{}),"local Studio testers can test admin")
check(not Admin.allowed(-1,false,true,false,{}),"negative test ids have no production privileges")
check(Admin.allowed(90,false,false,true,{}),"personal experience owner has admin")
for _,command in {"SetCash","AddCash","SetSpeed","SetStrength"} do
    for _,bad in {-1,1/0,0/0,"100",{},nil} do check(not Admin.validate(command,bad),"invalid numeric admin payload rejected") end
end
check(Admin.validate("SetCash",0) and Admin.validate("SetCash",1000000000),"cash endpoints valid")
check(not Admin.validate("AddCash",1000000001) and not Admin.validate("SetCash",1.5),"cash finite integer limit")
check(Admin.validate("SetSpeed",120) and not Admin.validate("SetSpeed",121),"bounded test speed")
check(Admin.validate("Event",{rarity="Rare",stage=1}) and not Admin.validate("Event",{rarity="Common",stage=1}),"admin spawns supported event tiers only")
check(not Admin.validate("Event",{rarity="Rare",stage=8}) and not Admin.validate("DeleteAll",0),"no arbitrary command/event coordinates")
local layout=Yard.build(Config.TrackWidth,Config.ZoneLength,Config.TrackStart)
local obstacles=Spawn.obstacles(layout.parts)
for _,p in layout.crates do table.insert(obstacles,{x=p.position[1],z=p.position[3],halfX=2.3,halfZ=2.3}) end
local seed=58313
local function sample():number seed=(seed*48271)%2147483647;return seed/2147483647 end
for zone=1,#Config.Stages do
    local occupied:{Spawn.Point}={}
    local first=Config.TrackStart+(zone-1)*Config.ZoneLength
    for _=1,32 do
        local point=Spawn.choose(Config.TrackWidth,first,Config.ZoneLength,obstacles,occupied,nil,sample)
        check(point~=nil,"every initial pickup has a free, safe position")
        if point then check(Spawn.safe(point,Config.TrackWidth,first,Config.ZoneLength,obstacles,occupied,nil),"new point clears collision, road and occupied pickups");table.insert(occupied,point) end
    end
    for _=1,80 do
        local old=table.remove(occupied,1)
        local point=Spawn.choose(Config.TrackWidth,first,Config.ZoneLength,obstacles,occupied,old,sample)
        check(point~=nil,"repeated respawns can always find a free point")
        if point then check(Spawn.safe(point,Config.TrackWidth,first,Config.ZoneLength,obstacles,occupied,old),"replacement stays in tier, away from old spawn and geometry");table.insert(occupied,point) end
    end
end
check(not Spawn.safe({x=0,z=100},160,20,480,{}, {},nil),"haul road remains clear")
check(not Spawn.safe({x=50,z=100},160,20,480,{}, {},{x=50,z=100}),"same spawn forbidden")
local counts:{[string]:number}={Common=1}
local title,hint,ratio=Hud.context(true,1,"","","",1,counts,1)
check(title=="Common robot  1 / 5" and ratio==.2,"HUD shows the current useful project only")
title,hint,ratio=Hud.context(true,1,"Common Gear","Scrap","Common",1,counts,1)
check(title=="Common Gear" and hint=="Deliver to Base 01","carried cargo replaces empty-hands instructions")
title=Hud.context(true,1,"","","",4,{},1)
check(title=="Your workshop is full","full finished bases get an accurate goal")
check(Hud.money(10000)=="$10.0K" and Hud.money(1000000)=="$1.0M","compact cash formatting")
print(string.format("Admin policy/random spawns/compact HUD passed %d assertions",checks))
