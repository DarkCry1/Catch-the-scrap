#!/usr/bin/env python3
"""Execute real deposit/income service code with a small mocked engine boundary.
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
    Economy=nativeRequire("../src/shared/Economy"),
    Inventory=nativeRequire("../src/shared/Inventory"),
    Movement=nativeRequire("../src/shared/Movement"),
}
local clock=0
local os={clock=function() return clock end}
local heartbeat
local services={
    ReplicatedStorage={CatchTheScrapShared={Config="Config",Economy="Economy",Inventory="Inventory",Movement="Movement"}},
    RunService={Heartbeat={Connect=function(_,fn) heartbeat=fn;return{} end}},
    Players={},
}
local game={GetService=function(_,name) return services[name] end}
local made={}
local Instance={new=function(class) local obj={ClassName=class};table.insert(made,obj);return obj end}
local Color3={fromRGB=function(r,g,b) return{r,g,b} end}
local Vector3={new=function(x,y,z) return{x,y,z} end}
local UDim2={fromScale=function(x,y) return{x,y} end}
local Enum={Font={GothamBold="GothamBold"}}
local require=function(name) assert(modules[name],name);return modules[name] end
'''
body=''
for name in ('EconomyService','CarryService','FloatingText'):
    source=(ROOT/f"src/server/{'Assets' if name=='FloatingText' else 'Services'}/{name}.luau").read_text()
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
-- Removing the income account stops all future production for that player.
economy:removePlayer(player)
local final=attrs.Cash
clock+=100;heartbeat()
check(attrs.Cash==final,"disconnected accounts stop producing")
print(string.format("Actual deposit/income services passed %d simulated-boundary checks; Studio remains required",checks))
'''
fixture=BUILD/'service-integration.spec.luau'
fixture.write_text(header+body+checks)
cli=shutil.which('luau') or '/workspace/.catch-the-scrap-tools/bin/luau'
subprocess.run([cli,str(fixture)],cwd=ROOT,check=True)
