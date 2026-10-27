--!strict
local Config=require("../src/shared/Config")
local Economy=require("../src/shared/Economy")
local Crates=require("../src/shared/CrateRules")
local Box=require("../src/shared/CrateBlueprint")
local Crusher=require("../src/shared/CrusherBlueprint")
local Motion=require("../src/shared/WorkshopMotion")
local Yard=require("../src/shared/ScrapyardBlueprint")
local checks=0
local function check(ok:boolean,message:string) checks+=1;assert(ok,message) end
for stage=1,#Config.Stages do
    local def=Crates.definition("Rare")
    check(def.kind=="RobotCrate" and def.rarity=="Rare" and def.name=="Rare Robot Box","public box identity hides reward tier")
    for _,sample in {0,.69,.7,.89,.9,.989,.99,.999999} do
        local result=Crates.roll(sample)
        check(Config.Robot.Recipes[result]~=nil,"server roll always produces a configured robot")
    end
end
check(Crates.roll(.1)=="Rare" and Crates.roll(.999)=="Celestial","early districts can hide surprise higher tiers")
for _,sample in {-1,1,math.huge,0/0} do check(not pcall(function() Crates.roll(sample) end),"invalid random samples reject") end
local account=Economy.new()
Economy.addPart(account,"Common",Config.Robot)
local slot=Economy.reserveRobot(account,"Common",Config.Robot,10)
check(slot==2 and #account.projects==2,"a whole robot uses a separate slot rather than eating a partial project")
check(Economy.progress(account,"Common")==1 and Economy.robotCount(account)==0,"unboxing preserves matching scrap progress")
check(Economy.advance(account,3.8,Config.Robot)==0,"sealed/opening robots cannot earn early")
check(Economy.finishRecovery(account,2,Config.Robot),"reserved box finishes exactly once")
check(not Economy.finishRecovery(account,2,Config.Robot),"replayed completion has no effect")
check(Economy.incomePerSecond(account,Config.Robot)==20 and Economy.progress(account,"Common")==1,"whole robot income and unfinished scrap coexist")
Economy.reserveRobot(account,"Epic",Config.Robot,11)
Economy.reserveRobot(account,"Rare",Config.Robot,12)
check(not Economy.canRecoverRobot(account,Config.Robot) and Economy.reserveRobot(account,"Legendary",Config.Robot,13)==nil,"all reserved/finished slots count toward crate capacity")
check(Economy.canAddPart(account,"Common",Config.Robot),"full workshop can still finish existing scrap project")
check(not Economy.canAddPart(account,"Rare",Config.Robot),"opening Rare crate is never treated as a scrap build")
local layout=Yard.build(Config.TrackWidth,Config.ZoneLength,Config.TrackStart)
check(#layout.crates==14,"two potential event positions per district")
for _,crate in layout.crates do
    local x,z=crate.position[1],crate.position[3]
    check(math.abs(x)-2.2>=14,"box leaves haul road open")
    for _,prop in layout.bounds do check(not (math.abs(x-prop.x)<prop.width/2+2.3 and math.abs(z-prop.z)<prop.depth/2+2.3),"box is reachable outside scenery footprints") end
    for _,spawn in layout.spawns do check((x-spawn.position[1])^2+(z-spawn.position[3])^2>25,"box does not overlap scrap") end
end
local box=Box.build()
check(#box<60,"bounded carton geometry")
local left,right=0,0
for _,part in box do
    if part.name=="FlapLeft" then left+=1 elseif part.name=="FlapRight" then right+=1 end
    check(part.position[2]-part.size[2]/2+Box.clearance()>=0,"box rests above ground")
end
check(left==1 and right==1,"two actual lid flaps can open on hinges")
local machine=Crusher.build()
check(#machine.rotors==2 and machine.rotors[1].direction==-machine.rotors[2].direction,"counter-rotating cutting shafts")
for _,rotor in machine.rotors do
    check(#rotor.parts<45,"bounded cutting geometry")
    for _,part in rotor.parts do for _,size in part.size do check(size>0,"positive blade dimensions") end end
end
for frame=0,160 do
    local t=frame/100
    local pull,scale,fade=Motion.crush(t)
    check(pull>=0 and pull<=1 and scale>=.059 and scale<=1 and fade>=0 and fade<=1,"bounded grinder movement/scale/fade")
end
local pull,scale,fade=Motion.crush(1.6)
check(pull==1 and scale<.07 and fade==1,"consumed scrap is completely crushed and gone")
for frame=0,380 do
    local shake,angle,glow=Motion.unbox(frame/100)
    check(math.abs(shake)<=.055 and angle>=0 and angle<=math.rad(130)+1e-6 and glow>=0 and glow<=1,"bounded box shake/lid/light")
end
for _,side in {-1,1} do
    local angle=Motion.arm(10,side)
    check(angle>math.pi/2 and angle<math.pi,"shoulders lift hands above head and toward the load")
end
print(string.format("Robot recovery, crate accessibility and workshop motion passed; %d assertions",checks))
