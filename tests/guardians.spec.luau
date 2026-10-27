--!strict
local Config=require("../src/shared/Config")
local Rules=require("../src/shared/GuardianRules")
local Nav=require("../src/shared/GuardianNavigation")
local Blueprint=require("../src/shared/GuardianBlueprint")
local Yard=require("../src/shared/ScrapyardBlueprint")
local n=0
local function check(ok:boolean,message:string) n+=1;assert(ok,message) end
check(#Config.Guardians.Profiles==#Config.Stages and #Config.Stages==7,"one profile per district")
local lastSpeed,lastScale=0,0
for i,profile in Config.Guardians.Profiles do
    check(profile.ChaseSpeed>lastSpeed and profile.Scale>lastScale,"difficulty increases with rarity")
    check(profile.PatrolSpeed<profile.ChaseSpeed and profile.WarningSeconds>=.8,"readable warning and different patrol pace")
    check(profile.ChaseSeconds<=10,"bounded chase creates an escape window")
    lastSpeed,lastScale=profile.ChaseSpeed,profile.Scale
    local _x0,x1,z0,z1=Rules.bounds(i)
    check(Rules.inside(i,{x=0,z=z0}) and not Rules.inside(i,{x=0,z=z1}),"stage seams belong to exactly one guardian")
    check(not Rules.inside(i,{x=0/0,z=z0+1}),"NaN cannot be eligible")
    check(Rules.protects(i,{zone=i}) and Rules.protects(i,{crateStage=i}),"both native scrap and box event positions are protected")
    check(not Rules.protects(i,{zone=i%7+1}) and not Rules.protects(i,nil),"guards do not confiscate another district's loot")
    local p=Rules.clamp(i,{x=1000,z=z1+30},Rules.radius(i)+1)
    check(p.x<x1 and p.z<z1 and p.z>z0,"guard goals remain behind district boundaries")
    local parts=Blueprint.build(i)
    check(#parts<110,"bounded geometry per guardian")
    local maxY=0
    for _,part in parts do
        check((Blueprint.Pivots :: any)[part.group]~=nil,"every part belongs to an animated motor group")
        local roll=math.rad(part.roll or 0)
        local hx=(math.abs(math.cos(roll))*part.size[1]+math.abs(math.sin(roll))*part.size[2])/2
        local hy=(math.abs(math.sin(roll))*part.size[1]+math.abs(math.cos(roll))*part.size[2])/2
        maxY=math.max(maxY,part.position[2]+hy)
        check((math.abs(part.position[1])+hx)*profile.Scale<=Rules.radius(i)+.01,"clearance contains full body width")
    end
    check(maxY*profile.Scale<=Rules.height(i),"advertised clearance contains model height")
end
-- A finite wall requires a detour; a full wall must not produce a clipping path.
local obstacle={name="TestWall",collidable=true,size={8,12,100},position={0,6,150},pitch=0,yaw=0,roll=0}
local nav=Nav.new(1,{obstacle})
local from,to={x=-32,z=150},{x=32,z=150}
check(not nav:clear(from,to),"straight line through scenery is rejected")
local route=nav:route(from,to)
check(#route>=2,"planner detours around the wall")
for _,p in route do check(nav:clear(from,p),"every smoothed segment clears the expanded wall");from=p end
check(Nav.distance(from,to)<.01,"detour reaches a clear target")
local ceiling=Nav.obstacles({{collidable=true,size={10,1,10},position={0,20,0},pitch=0,yaw=0,roll=0}},9)
check(#ceiling==0,"high overhead objects do not block a short guardian")
local floor=Nav.obstacles({{collidable=true,size={160,.3,480},position={0,0,0},pitch=0,yaw=0,roll=0}},9)
check(#floor==0,"floor is walkable")
local lowCeiling=Nav.obstacles({{collidable=true,size={10,1,10},position={0,12,0},pitch=0,yaw=0,roll=0}},18)
check(#lowCeiling==1,"tall guardians respect overhead clearance")
local layout=Yard.build(Config.TrackWidth,Config.ZoneLength,Config.TrackStart)
for i=1,#Config.Stages do
    local actual=Nav.new(i,layout.parts)
    check(#actual.cells>100,"actual district has a useful walkable navigation grid")
    local home=Rules.patrol(i,1);local start=actual:nearest(home,nil,nil)
    check(start~=nil,"each guardian can spawn in a clear cell")
    local p=actual.cells[start :: number]
    for j=1,5 do
        local goal=Rules.patrol(i,j);local path=actual:route(p,goal)
        check(#path>0,"all actual patrol legs have a route")
        for _,nextPoint in path do
            check(actual:clear(p,nextPoint),"real scenery never intersects a patrol segment")
            check(Rules.inside(i,nextPoint),"real patrol stays in its own district")
            p=nextPoint
        end
        check(Nav.distance(p,goal)<2,"patrol reaches each waypoint without getting stuck")
    end
    -- Test representative side-loot approaches and return paths, including targets
    -- too close to scenery for the larger body. They may stop at a safe standoff.
    for _,x in {-64,-40,40,64} do
        local goal={x=x,z=home.z+100}
        local path=actual:route(p,goal)
        for _,nextPoint in path do check(actual:clear(p,nextPoint),"loot approach respects body clearance");p=nextPoint end
        local back=actual:route(p,home)
        check(#back>0,"guardian can always return to its patrol")
        for _,nextPoint in back do check(actual:clear(p,nextPoint),"return route clears obstacles");p=nextPoint end
    end
end
print("Seven guardian profiles, geometry and actual-yard routing passed "..n.." assertions")
