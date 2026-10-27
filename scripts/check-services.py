#!/usr/bin/env python3
"""Execute real deposit/income/mechanic service code with a small mocked engine boundary.
This complements, and does not replace, actual Roblox Studio tests.
"""
from pathlib import Path
import shutil
import subprocess

ROOT=Path(__file__).resolve().parents[1]
BUILD=ROOT/'build'
BUILD.mkdir(exist_ok=True)
header=r'''
--!nonstrict
local nativeRequire=require
local modules={
    Config=nativeRequire("../src/shared/Config"),
    UpgradeRules=nativeRequire("../src/shared/UpgradeRules"),
    Economy=nativeRequire("../src/shared/Economy"),
    Inventory=nativeRequire("../src/shared/Inventory"),
    Movement=nativeRequire("../src/shared/Movement"),
    RarityStyle=nativeRequire("../src/shared/RarityStyle"),
    RobotCatalog=nativeRequire("../src/shared/RobotCatalog"),
    AdminRules=nativeRequire("../src/shared/AdminRules"),
    AdminConfig=nativeRequire("../src/server/AdminConfig"),
    PlacementRules=nativeRequire("../src/shared/PlacementRules"),
}
local clock=0
local os={clock=function() return clock end}
local heartbeat
local deferred={}
local task={delay=function(seconds,fn) table.insert(deferred,{seconds=seconds,fn=fn}) end}
local workspace={GetServerTimeNow=function() return clock end}
local services={
    ReplicatedStorage={CatchTheScrapShared={Config="Config",RarityStyle="RarityStyle",RobotCatalog="RobotCatalog",Economy="Economy",Inventory="Inventory",Movement="Movement",PlacementRules="PlacementRules",UpgradeRules="UpgradeRules",AdminRules="AdminRules"}},
    RunService={IsStudio=function() return false end,Heartbeat={Connect=function(_,fn) heartbeat=fn;return{} end}},
    Players={},
}
local added,removed={},{}
services.CollectionService={
 GetInstanceAddedSignal=function(_,tag) return{Connect=function(_,fn) added[tag]=fn end} end,
 GetInstanceRemovedSignal=function(_,tag) return{Connect=function(_,fn) removed[tag]=fn end} end,
 GetTagged=function() return{} end,
}
local tweenCalls={}
services.TweenService={Create=function(_,part)
 local tween={cancelled=false,startedAt=part.Transparency,Play=function() end,Cancel=function(self) self.cancelled=true end}
 table.insert(tweenCalls,tween);return tween
end}
local TweenInfo={new=function() return{} end}
local script={Parent={Parent={AdminConfig="AdminConfig"}}}
local game={CreatorType="User",CreatorId=9999,GetService=function(_,name) return services[name] end}
local made={}
local Instance={new=function(class) local obj={ClassName=class};table.insert(made,obj);return obj end}
local Color3={fromRGB=function(r,g,b) return{r,g,b} end}
local Vector3={new=function(x,y,z) return{x,y,z} end}
local UDim2={fromScale=function(x,y) return{x,y} end}
local Enum={CreatorType={User="User",Group="Group"},Font={GothamBold="GothamBold"},EasingStyle={Sine="Sine"},EasingDirection={InOut="InOut"}}
local require=function(name) assert(modules[name],name);return modules[name] end
'''
body=''
for name in ('EconomyService','CarryService','FloatingText','MechanicService','RobotAnimator','EnvironmentEffects','AdminService','RobotIndexService','RarityWorldEffects'):
    source=(ROOT/(f'src/client/{name}.luau' if name in ('RobotAnimator','EnvironmentEffects','RarityWorldEffects') else f"src/server/{'Assets' if name=='FloatingText' else 'Services'}/{name}.luau")).read_text()
    body+=f'local {name}=(function()\n{source}\nend)()\n'
checks=r'''
local checks=0
local function check(ok,message) checks+=1;assert(ok,message) end
local label=FloatingText.create({},"TestSign",{},"SCRAPYARD AHEAD",{},48,7,100)
local anchor,billboard
for _,obj in made do
    if obj.ClassName=="Part" then anchor=obj elseif obj.ClassName=="BillboardGui" then billboard=obj end
end
check(anchor.Transparency==1 and not anchor.CanCollide and not anchor.CanQuery,"floating sign has no visible or blocking backing panel")
check(label.BackgroundTransparency==1 and label.AutoLocalize==false,"world text stays transparent and English")
check(billboard.MaxDistance==100 and not billboard.AlwaysOnTop,"world labels have bounded visibility without drawing over distant geometry")
local attrs={}
local player={UserId=11,DisplayName="Tester",leaderstats={}}
function player:SetAttribute(name,value) attrs[name]=value end
function player:GetAttribute(name) return attrs[name] end
local world={updateEconomy=function() end}
local economy=EconomyService.new(world)
local base={owner=11,deposit={Position=0}}
economy:addPlayer(player,base)
local inventory=modules.Inventory.new(12)
local consumed=0
local items={records={}}
function items:consume(record) consumed+=1;self.records[record.id]=nil end
local messages={}
local feedback={FireClient=function(_,_,text) table.insert(messages,text) end}
local carry=CarryService.new(world,items,inventory,feedback,economy)
carry.players[player]={base=base,counter={Value=0},lastAction=-math.huge}
local crushes=0
carry.onCrush=function(b,record) check(b==base and items.records[record.id]==record,"accepted scrap produces an effect while its server record is still valid");crushes+=1 end
function carry:context() return{alive=true,hasBase=true,distance=1} end
local nextId=0
local function hold(rarity)
    nextId+=1
    local id="part-"..nextId
    local definition
    for _,item in modules.Config.Items do if item.rarity==rarity then definition=item end end
    items.records[id]={id=id,definition=definition}
    modules.Inventory.registerItem(inventory,id)
    assert(modules.Inventory.pickup(inventory,11,id,{alive=true,hasBase=true,distance=1}))
    return id
end
local function deposit(rarity)
    local id=hold(rarity)
    clock+=.3
    carry:deposit(player,base)
    check(inventory.carrying[11]==nil and items.records[id]==nil,"accepted deposit consumes exactly its carried record")
end
for _=1,4 do deposit("Common") end
for _=1,9 do deposit("Rare") end
check(attrs.CommonParts==4 and attrs.RareParts==9,"actual services publish separate partial counters")
check(attrs.Cash==0 and attrs.RobotCount==0,"partial assemblies do not produce cash")
clock=100;heartbeat()
check(attrs.Cash==0,"waiting before completion earns nothing")
deposit("Common")
check(attrs.RobotCount==1 and attrs.CommonParts==0 and attrs.RareParts==9,"Common completion preserves Rare progress")
local before=attrs.Cash
clock+=2;heartbeat()
check(attrs.Cash-before==10,"real income service credits $5/sec")
deposit("Rare")
check(attrs.RobotCount==2 and attrs.IncomePerSecond==25,"Rare completion changes combined rate to $25/sec")
local lastDisplay=attrs.Cash
clock+=.05;heartbeat()
check(attrs.Cash==lastDisplay and economy.players[player].account.cash>lastDisplay,"income accrues internally without frame-rate replication")
clock+=.3;heartbeat()
check(attrs.Cash==economy.players[player].account.cash,"throttled display catches up without losing income")
-- Complete two more Common robots to fill every platform.
for _=1,10 do deposit("Common") end
check(attrs.RobotCount==4 and attrs.UsedPlatforms==4,"four-platform capacity published")
local id=hold("Rare")
local oldConsumed,oldDelivered=consumed,inventory.delivered[11]
clock+=.3;carry:deposit(player,base)
check(inventory.carrying[11]==id and items.records[id]~=nil,"full capacity keeps the carried part")
check(consumed==oldConsumed and inventory.delivered[11]==oldDelivered,"full rejection awards no false delivery")
check(messages[#messages]:find("reserved")~=nil,"rejection is explained in English")
modules.Inventory.drop(inventory,11)
check(consumed==25,"every accepted delivery consumed once")
check(crushes==25,"accepted scrap invokes one crusher effect per deposit; rejected deliveries never emit")
-- Exercise real mechanic purchases against the same account and inventory services.
clock+=20;heartbeat()
local packets={}
world.mechanic={prompt={Triggered={Connect=function() return{} end}},interaction={Position=0}}
local remote={FireClient=function(_,_,channel,data) assert(channel=="MechanicShop");table.insert(packets,data) end}
local shop=MechanicService.new(world,economy,carry,remote)
local context={alive=true,hasBase=true,distance=1}
function shop:context() return context end
local humanoid={Health=100,WalkSpeed=24}
local root={IsA=function(_,class) return class=="BasePart" end}
player.Character={FindFirstChildOfClass=function() return humanoid end,FindFirstChild=function(_,name) return if name=="HumanoidRootPart" then root else nil end}
local initial=economy.players[player].account.cash
shop:buy(player,"Speed",0)
check(economy.players[player].account.cash==initial and #packets==0,"purchase requires an authorized mechanic visit")
shop:open(player)
check(packets[#packets].mode=="open" and packets[#packets].offers[1].cost==75,"opening returns server-priced offers")
local carried=hold("Rare")
carry:writeState(player)
local oldLoadedSpeed=humanoid.WalkSpeed
local priceBefore=economy.players[player].account.cash
shop:buy(player,"Speed",0)
check(economy.players[player].account.cash==priceBefore-75,"real mechanic charges the authoritative price once")
check(attrs.SpeedLevel==1 and attrs.BaseSpeed==26,"server publishes purchased Speed level")
check(humanoid.WalkSpeed>oldLoadedSpeed,"purchased Speed immediately affects a live loaded humanoid")
local afterFirst=economy.players[player].account.cash
shop:buy(player,"Speed",1)
check(economy.players[player].account.cash==afterFirst and attrs.SpeedLevel==1,"cooldown prevents same-frame double buying")
clock+=1
shop:buy(player,"Speed",0)
check(economy.players[player].account.cash==afterFirst+35 and attrs.SpeedLevel==1,"stale offer earns normal income but cannot buy another level")
check(packets[#packets].message:find("changed")~=nil,"stale offer refreshes the menu")
local oldStrengthSpeed=humanoid.WalkSpeed
local beforeStrength=economy.players[player].account.cash
clock+=1;shop:buy(player,"Strength",0)
check(economy.players[player].account.cash==beforeStrength+35-100,"Strength debit includes correct accrued income")
check(attrs.CarryStrength==40 and attrs.StrengthLevel==1,"Strength level is server-owned")
check(humanoid.WalkSpeed>oldStrengthSpeed,"Strength immediately reduces the held Rare part penalty")
local safeBalance=economy.players[player].account.cash
context.distance=200
shop:buy(player,"Speed",1)
check(economy.players[player].account.cash==safeBalance and attrs.SpeedLevel==1,"remote purchase from far away cannot charge or upgrade")
check(not packets[#packets].open and not shop.active[player],"walking away closes authorization")
context.distance=1;shop:open(player);context.alive=false
local deadBalance=economy.players[player].account.cash
shop:buy(player,"Speed",1)
check(economy.players[player].account.cash==deadBalance and attrs.SpeedLevel==1,"dead characters cannot purchase")
context.alive=true;shop:open(player);clock+=1
local badBefore=economy.players[player].account.cash
shop:buy(player,"Cash",0)
check(economy.players[player].account.cash==badBefore+35 and attrs.SpeedLevel==1,"unknown upgrade only settles legitimate income")
local malformedBalance=economy.players[player].account.cash
clock+=1;shop:buy(player,"Speed","1")
check(economy.players[player].account.cash==malformedBalance and attrs.SpeedLevel==1,"string levels never reach the debit transaction")
clock+=1;shop:buy(player,{},1)
check(economy.players[player].account.cash==malformedBalance,"non-string upgrade identifiers are rejected without spending")
modules.Inventory.drop(inventory,11)
humanoid={Health=100,WalkSpeed=16}
carry:writeState(player)
check(humanoid.WalkSpeed==26 and attrs.CarryStrength==40,"character replacement reapplies purchased session stats")
shop:removePlayer(player)
check(shop.active[player]==nil and shop.lastBuy[player]==nil,"disconnect clears mechanic state")

-- Removing the income account stops all future production for that player.
economy:removePlayer(player)
local final=attrs.Cash
clock+=100;heartbeat()
check(attrs.Cash==final,"disconnected accounts stop producing")
-- Publish and complete each newly introduced tier through the real services.
for _,stage in modules.Config.Stages do
    if stage.Rarity=="Common" or stage.Rarity=="Uncommon" or stage.Rarity=="Rare" then continue end
    local attrs2={}
    local advanced={leaderstats={},SetAttribute=function(_,name,value) attrs2[name]=value end,GetAttribute=function(_,name) return attrs2[name] end}
    economy:addPlayer(advanced,base)
    local recipe=modules.Config.Robot.Recipes[stage.Rarity]
    for count=1,recipe.Parts do
        check(economy:canDeposit(advanced,stage.Rarity),"new tier accepted by server service")
        economy:addPart(advanced,stage.Rarity)
        check(attrs2[stage.Rarity.."Parts"]==(if count==recipe.Parts then 0 else count),"new tier partial progress published")
    end
    check(attrs2.RobotCount==1 and attrs2.IncomePerSecond==recipe.Income,"new tier robot earns its configured rate")
    economy:removePlayer(advanced)
end
-- Exercise actual box delivery, reservation and delayed reveal with the same inventory.
local attrs3={}
local owner={UserId=21,leaderstats={},SetAttribute=function(_,name,value) attrs3[name]=value end,GetAttribute=function(_,name) return attrs3[name] end}
local boxBase={owner=21,deposit={Position=0}}
economy:addPlayer(owner,boxBase)
carry.players[owner]={base=boxBase,counter={Value=0},lastAction=-math.huge}
local recovered=0
economy.onRecovered=function(p,rarity) check(p==owner and rarity=="Epic","server reveals its fixed contents");recovered+=1 end
local function holdBox(id)
 items.records[id]={id=id,definition={kind="RobotCrate",rarity="Mystery",name="Sealed Robot Box",weight=32},rewardRarity="Epic",rewardVariant="Orbital"}
 modules.Inventory.registerItem(inventory,id)
 assert(modules.Inventory.pickup(inventory,21,id,{alive=true,hasBase=true,distance=1}))
end
holdBox("box-A")
local validContext=carry.context
function carry:context() return{alive=true,hasBase=true,distance=999} end
clock+=.3;carry:deposit(owner,boxBase)
check(inventory.carrying[21]=="box-A" and attrs3.UsedPlatforms==0,"remote box delivery is rejected without consuming or reserving")
function carry:context() return{alive=false,hasBase=true,distance=1} end
clock+=.3;carry:deposit(owner,boxBase)
check(inventory.carrying[21]=="box-A" and attrs3.UsedPlatforms==0,"dead characters cannot unbox a robot")
carry.context=validContext
local deliveryBefore=consumed
local crushesBefore=crushes
clock+=.3;carry:deposit(owner,boxBase)
check(consumed==deliveryBefore+1 and inventory.carrying[21]==nil,"delivering a box consumes it once")
check(crushes==crushesBefore,"robot boxes bypass the shredder")
check(attrs3.UsedPlatforms==1 and attrs3.RobotCount==0 and attrs3.IncomePerSecond==0,"whole robot platform reserved, not prematurely paid")
check(#deferred==1 and deferred[1].seconds==modules.RarityStyle.get("Epic").Duration,"unboxing completion waits for the presentation window")
clock+=modules.RarityStyle.get("Epic").Duration
local finish=deferred[1].fn;finish()
check(attrs3.RobotCount==1 and attrs3.IncomePerSecond==324 and attrs3.Cash==0,"Epic robot starts producing only at reveal")
finish();check(recovered==1 and attrs3.RobotCount==1,"duplicate callback cannot award twice")
clock+=1;heartbeat();check(attrs3.Cash==324,"recovered robot produces normal passive income")
-- Reserve three more slots; the fifth box is preserved, including the case of an active partial build.
for n=1,3 do holdBox("box-"..n);clock+=.3;carry:deposit(owner,boxBase) end
holdBox("box-full");clock+=.3
local fullConsumed=consumed
carry:deposit(owner,boxBase)
check(consumed==fullConsumed and inventory.carrying[21]=="box-full","full capacity keeps box and its sealed contents")
modules.Inventory.drop(inventory,21)
-- A different workshop is rejected before any slot/reward/consumption mutation.
local attrs4={}
local outsider={UserId=22,leaderstats={},SetAttribute=function(_,name,value) attrs4[name]=value end,GetAttribute=function(_,name) return attrs4[name] end}
economy:addPlayer(outsider,boxBase)
carry.players[outsider]={base=boxBase,counter={Value=0},lastAction=-math.huge}
items.records.foreign={id="foreign",definition={kind="RobotCrate",rarity="Mystery",name="Box"},rewardRarity="Rare"}
modules.Inventory.registerItem(inventory,"foreign");modules.Inventory.pickup(inventory,22,"foreign",{alive=true,hasBase=true,distance=1})
clock+=.3;carry:deposit(outsider,boxBase)
check(attrs4.UsedPlatforms==0 and inventory.carrying[22]=="foreign","another player's base cannot receive a recovered robot")
-- Disconnects and base reassignment cannot complete pending unboxings for a replacement owner.
boxBase.owner=333;deferred[2].fn()
check(attrs3.RobotCount==1,"a replaced workshop owner cannot inherit the old opening job")
boxBase.owner=21
economy:removePlayer(owner)
local beforeDisconnect=recovered
for _,pending in deferred do pending.fn() end
check(recovered==beforeDisconnect,"disconnect invalidates every delayed box completion")
economy:removePlayer(outsider)
-- Exercise the actual admin service, including forged client permission attributes.
local adminReplies,eventCalls={},0
local eventService={forceSpawn=function(_,tier,stage) eventCalls+=1;check(tier=="Rare" and stage==1,"admin uses a validated tier and district");return true,"Spawned" end}
local adminRemote={FireClient=function(_,p,channel,packet) check(channel=="AdminResult","admin response channel");table.insert(adminReplies,packet) end}
local admin=AdminService.new(economy,carry,eventService,adminRemote)
local adminAttrs={}
local authorized={UserId=11824623188,leaderstats={},SetAttribute=function(_,name,value) adminAttrs[name]=value end,GetAttribute=function(_,name) return adminAttrs[name] end}
local adminHumanoid={Health=100,WalkSpeed=24}
authorized.Character={FindFirstChildOfClass=function() return adminHumanoid end,FindFirstChild=function() return root end}
economy:addPlayer(authorized,base);carry.players[authorized]={base=base,counter={Value=0},lastAction=-math.huge}
admin:addPlayer(authorized)
check(adminAttrs.CanAdmin==true,"requested user id receives admin access")
clock+=1;admin:run(authorized,"SetCash",10000)
check(adminAttrs.Cash==10000,"admin cash applied through authoritative finance publication")
clock+=1;admin:run(authorized,"AddCash",250)
admin:run(authorized,"AddCash",250)
check(adminAttrs.Cash==10250,"server cooldown rejects same-frame repeated grants")
clock+=1;admin:run(authorized,"SetSpeed",60)
check(adminHumanoid.WalkSpeed==60 and adminAttrs.CarrySpeed==60,"debug speed applies to real humanoid and carry state")
clock+=1;admin:run(authorized,"SetStrength",150)
check(adminAttrs.CarryStrength==150,"debug strength published from server")
clock+=1;admin:run(authorized,"ResetStats",0)
check(adminHumanoid.WalkSpeed==24 and adminAttrs.CarryStrength==30,"reset restores actual purchased/base stats")
clock+=1;admin:run(authorized,"Event",{rarity="Rare",stage=1})
check(eventCalls==1,"authorized event request invokes the real event service interface")
local beforeInvalid=adminAttrs.Cash
for _,bad in {0/0,math.huge,-1,"99999",{value=10000,target=22}} do clock+=1;admin:run(authorized,"SetCash",bad) end
check(adminAttrs.Cash==beforeInvalid,"malformed or targeted cash requests never mutate account")
local impostor={UserId=123,SetAttribute=function() end,GetAttribute=function() return true end}
clock+=1;admin:run(impostor,"Event",{rarity="Rare",stage=1});admin:run(impostor,"SetCash",999999)
check(eventCalls==1 and adminAttrs.Cash==beforeInvalid,"forged client admin attribute cannot run any command")
clock+=1;admin:run(authorized,"SetCash",1000000000)
clock+=1;admin:run(authorized,"AddCash",1)
check(adminAttrs.Cash==1000000000,"addition cannot overflow administrative cash ceiling")
admin:removePlayer(authorized);check(admin.last[authorized]==nil,"disconnect clears admin throttles")
economy:removePlayer(authorized)
-- Execute real collection selection, privacy and retirement through the service.
local indexAttrs={}
local collector={UserId=70,leaderstats={},SetAttribute=function(_,name,value) indexAttrs[name]=value end,GetAttribute=function(_,name) return indexAttrs[name] end}
local collectorBase={owner=70,deposit={Position=0}}
economy:addPlayer(collector,collectorBase)
carry.players[collector]={base=collectorBase,counter={Value=0},lastAction=-math.huge}
local indexPackets={}
local indexRemote={FireClient=function(_,p,channel,packet) check(p==collector and channel=="RobotIndex","index state only sent to its owner");table.insert(indexPackets,packet) end}
local index=RobotIndexService.new(economy,carry,indexRemote)
economy.onIndexChange=function(p) index:send(p) end
economy.onRecovered=nil
clock+=1;index:request(collector)
check(#indexPackets[#indexPackets].rows==70,"server collection has ten entries for all seven rarities")
clock+=1;index:select(collector,"Rare","Orbital")
check(economy.players[collector].account.selected.Rare==nil,"box-exclusive selection cannot mutate build choice")
clock+=1;index:select(collector,"Rare","Driller")
for _=1,10 do clock+=.1;economy:addPart(collector,"Rare") end
local collectionAccount=economy.players[collector].account
local builtId=collectionAccount.projects[1].id
check(indexAttrs.IncomePerSecond==27 and collectionAccount.unlocked["Rare:Driller"],"selected crafted chassis grants the correct income and discovery")
local properContext=carry.context
function carry:context() return{alive=true,hasBase=true,distance=999} end
clock+=1;index:retire(collector,builtId)
check(#collectionAccount.projects==1,"retirement from far away is rejected")
function carry:context() return{alive=true,hasBase=true,distance=0/0} end
clock+=1;index:retire(collector,builtId)
check(#collectionAccount.projects==1,"NaN distance cannot bypass workshop proximity")
carry.context=properContext
clock+=1;index:retire(collector,builtId)
check(#collectionAccount.projects==0 and collectionAccount.unlocked["Rare:Driller"] and indexAttrs.IncomePerSecond==0,"retirement frees platform but preserves discovery")
for _=1,5 do clock+=.1;economy:addPart(collector,"Common") end
local commonId=collectionAccount.projects[1].id
clock+=1;economy:recoverRobot(collector,"Epic","Orbital")
local completeShifted=deferred[#deferred].fn
local opening=indexPackets[#indexPackets].projects[2]
check(opening.name:find("opening")~=nil and opening.variant==nil and opening.income==0,"pending box does not disclose its selected robot")
clock+=1;index:retire(collector,commonId)
check(#collectionAccount.projects==1 and collectionAccount.projects[1].opening,"retirement can shift an opening project without losing it")
clock+=modules.RarityStyle.get("Epic").Duration;completeShifted()
check(indexAttrs.RobotCount==1 and indexAttrs.IncomePerSecond==324 and collectionAccount.unlocked["Epic:Orbital"],"shifted opening still reveals and discovers the correct robot once")
completeShifted();check(indexAttrs.RobotCount==1,"shifted callback replay never duplicates the robot")
index:removePlayer(collector);economy:removePlayer(collector)
economy.onIndexChange=nil
-- Exercise actual client streaming cleanup and distance activation, not GPU output.
RobotAnimator.start()
local reactor={Transparency=.3,IsA=function(_,kind) return kind=="BasePart" end,Destroying={Connect=function() return{Disconnect=function() end} end}}
added.WorkingRobotReactor(reactor)
check(tweenCalls[#tweenCalls].startedAt==0,"reactor pulse initializes from its intended material opacity")
removed.WorkingRobotReactor(reactor)
check(tweenCalls[#tweenCalls].cancelled,"streamed-out reactors release their tween")
reactor.Transparency=.45;added.WorkingRobotReactor(reactor)
check(tweenCalls[#tweenCalls].startedAt==0,"reactor effect restarts after streaming back in")
local effectDistance=30
root.Position=setmetatable({},{__sub=function() return{Magnitude=effectDistance} end})
local lamp={Enabled=false,IsA=function(_,kind) return kind=="Light" end,Parent={IsA=function(_,kind) return kind=="BasePart" end,Position={}}}
EnvironmentEffects.start(player)
added.YardAmbientEffect(lamp);heartbeat(.5)
check(lamp.Enabled,"nearby ambient light becomes enabled")
effectDistance=500;heartbeat(.5)
check(not lamp.Enabled,"distant ambient light is disabled")
removed.YardAmbientEffect(lamp);effectDistance=30;heartbeat(.5)
check(not lamp.Enabled,"removed ambient instances are not reactivated")
RarityWorldEffects.start(player)
effectDistance=30
local ambient={}
for i=1,28 do
 local kind=if i<=12 then "Light" else "ParticleEmitter"
 local object={Parent={IsA=function(_,class) return class=="BasePart" end,Position={}},Enabled=false,IsA=function(_,class) return class==kind end,GetAttribute=function() return false end}
 table.insert(ambient,object);added.RarityAmbient(object)
end
heartbeat(.25)
local lightCount,emitterCount=0,0
for i,o in ambient do if o.Enabled then if i<=12 then lightCount+=1 else emitterCount+=1 end end end
check(lightCount==8 and emitterCount==12,"rarity effects enforce near-light and particle budgets")
local rainbow={Parent=true,Position={},IsA=function(_,class) return class=="BasePart" end,GetAttribute=function() return .25 end}
added.RaritySpectrum(rainbow);heartbeat(.25);local oldColor=rainbow.Color
clock+=1;heartbeat(.25)
check(rainbow.Color[1]~=oldColor[1] or rainbow.Color[2]~=oldColor[2] or rainbow.Color[3]~=oldColor[3],"actual spectrum adapter moves RGB colors over time")
effectDistance=500;heartbeat(.25)
for _,o in ambient do check(not o.Enabled,"distant rarity effects are disabled") end
removed.RaritySpectrum(rainbow)
for _,o in ambient do removed.RarityAmbient(o) end
print(string.format("Actual deposit/income/index/admin/rarity services passed %d simulated-boundary checks; Studio remains required",checks))
'''
fixture=BUILD/'service-integration.spec.luau'
fixture.write_text(header+body+checks)
cli=shutil.which('luau') or '/workspace/.catch-the-scrap-tools/bin/luau'
subprocess.run([cli,str(fixture)],cwd=ROOT,check=True)
