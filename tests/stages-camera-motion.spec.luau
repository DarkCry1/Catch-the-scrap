--!strict
local Config=require("../src/shared/Config")
local Camera=require("../src/shared/CameraBounds")
local Motion=require("../src/shared/PickupMotion")
local Pickups=require("../src/shared/PickupBlueprint")
local Economy=require("../src/shared/Economy")
local checks=0
local function check(ok:boolean,message:string) checks+=1;assert(ok,message) end
local expected={"Common","Uncommon","Rare","Epic","Legendary","Mythic","Celestial"}
local income,weight,parts=0,0,0
for i,stage in Config.Stages do
    check(stage.Rarity==expected[i],"ordered stage progression")
    local recipe=Config.Robot.Recipes[stage.Rarity]
    local item=Config.Items[i]
    check(item.rarity==stage.Rarity and item.weight>weight,"progressive weight and correct spawn definition")
    check(recipe.Income>income and recipe.Parts>parts,"progressive matching-part recipes and payouts")
    income,weight,parts=recipe.Income,item.weight,recipe.Parts
    local account=Economy.new()
    for count=1,recipe.Parts do
        local accepted,complete=Economy.addPart(account,stage.Rarity,Config.Robot)
        check(accepted and complete==(count==recipe.Parts),"all seven recipes complete at the exact part count")
        check(Economy.incomePerSecond(account,Config.Robot)==(if complete then recipe.Income else 0),"only completed robots earn")
    end
    local geometry=Pickups.build(item.rarity,item.color)
    local clearance=Pickups.clearance(item.rarity,item.color)
    for frame=0,120 do
        local bob,_,tilt,pulse=Motion.sample(frame/10,i)
        check(bob>=.35 and bob<=.83 and pulse>=.54 and pulse<=.90,"bounded hover and glow")
        for _,part in geometry do
            local a=math.rad(part.roll)
            local halfY=math.abs(part.size[1]/2*math.sin(a))+math.abs(part.size[2]/2*math.cos(a))
            local bottom=clearance+bob+(part.position[2]-halfY)*math.cos(tilt)-(math.abs(part.position[3])+part.size[3]/2)*math.abs(math.sin(tilt))
            check(bottom>0,"idle model never sinks into ground")
        end
    end
end
local function inside(p:Camera.Point,padding:number):boolean
    local endZ=Config.TrackStart+Config.ZoneLength*#Config.Stages
    return p.y>=.5-1e-6 and p.y<=Config.WallHeight-padding+1e-6 and (
        (p.z>=-298+padding-1e-6 and p.z<=Config.TrackStart+1e-6 and math.abs(p.x)<=102-padding+1e-6) or
        (p.z>=Config.TrackStart-1e-6 and p.z<=endZ-padding+1e-6 and math.abs(p.x)<=Config.TrackWidth/2-padding+1e-6))
end
for _,padding in {2,4,8} do
    for _,z in {-295,-100,18,20,22,400,1459,2400,3375} do
        for _,x in {-98,-77,0,77,98} do
            local focus={x=x,y=6,z=z}
            for angle=0,350,10 do
                local a=math.rad(angle)
                local desired={x=x+math.cos(a)*40,y=if angle%20==0 then 100 else -5,z=z+math.sin(a)*40}
                local result=Camera.limit(focus,desired,padding)
                check(inside(result,padding),"camera center and near plane stay inside perimeter at corners and stage seams")
                if inside(focus,padding) then
                    for step=0,10 do
                        local t=step/10
                        check(inside({x=focus.x+(result.x-focus.x)*t,y=focus.y+(result.y-focus.y)*t,z=focus.z+(result.z-focus.z)*t},padding),"camera segment cannot tunnel across the entrance corner")
                    end
                end
            end
        end
    end
end
local focus={x=0,y=6,z=200}
local desired={x=5,y=8,z=190}
local unchanged=Camera.limit(focus,desired,2)
check(unchanged.x==desired.x and unchanged.y==desired.y and unchanged.z==desired.z,"ordinary orbit is unchanged")
local h1,y1,t1=Motion.sample(10,1)
local h2,y2,t2=Motion.sample(10.001,1)
check(math.abs(h2-h1)<.001 and math.abs(y2-y1)<.001 and math.abs(t2-t1)<.001,"continuous bob, spin and tilt")
print(string.format("Seven-stage progression/camera/motion passed; %d assertions",checks))
