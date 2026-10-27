#!/usr/bin/env python3
"""Execute real pickup/item lifecycle code with mocked geometry, not engine physics."""
from pathlib import Path
import shutil,subprocess
ROOT=Path(__file__).resolve().parents[1]
header=r'''
--!nonstrict
local nativeRequire=require
local modules={Config=nativeRequire("../src/shared/Config"),Inventory=nativeRequire("../src/shared/Inventory"),RobotCatalog=nativeRequire("../src/shared/RobotCatalog"),CrateRules=nativeRequire("../src/shared/CrateRules")}
local vecMeta={}
local function vec(x,y,z) return setmetatable({X=x,Y=y,Z=z},vecMeta) end
vecMeta.__add=function(a,b) return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
local Vector3={new=vec}
local cfMeta={}
local CFrame={new=function(x,y,z) local p=if type(x)=="table" then x else vec(x or 0,y or 0,z or 0);return setmetatable({Position=p},cfMeta) end}
cfMeta.__mul=function(a,b) return CFrame.new(a.Position+b.Position) end
cfMeta.__index={PointToObjectSpace=function(self,p) return vec(p.X-self.Position.X,p.Y-self.Position.Y,p.Z-self.Position.Z) end}
local methods={}
local objMeta={}
objMeta.__index=function(self,key)
 if methods[key] then return methods[key] end
 local stored=rawget(self,"_"..key);if stored~=nil then return stored end
 for _,child in self.children do if child.Name==key then return child end end
 return nil
end
objMeta.__newindex=function(self,key,value)
 if key=="Parent" then
  rawset(self,"_Parent",value);if value then table.insert(value.children,self) end
 else rawset(self,key,value) end
end
function methods:GetChildren() return self.children end
function methods:FindFirstChild(name) for _,c in self.children do if c.Name==name then return c end end;return nil end
function methods:SetAttribute(name,value) self.attrs[name]=value end
function methods:GetAttribute(name) return self.attrs[name] end
function methods:PivotTo(cf) self.PrimaryPart.CFrame=cf end
function methods:Destroy() self.Parent=nil;self.destroyed=true end
local Instance={new=function(class)
 local o=setmetatable({children={},attrs={},ClassName=class},objMeta)
 if class=="ProximityPrompt" then o.Triggered={Connect=function(self,fn) self.fn=fn end} end
 return o
end}
local enumMeta={__index=function(_,key) return key end}
local Enum=setmetatable({},{__index=function(self,key) local t=setmetatable({},enumMeta);rawset(self,key,t);return t end})
local Color3={fromRGB=function(...) return{...} end}
local UDim2={fromOffset=function(...) return{...} end,fromScale=function(...) return{...} end}
local UDim={new=function(...) return{...} end}
local rolls=0
local Random={new=function() return{NextNumber=function() rolls+=1;return .95 end,NextInteger=function(_,lo) return lo end} end}
local delayed={}
local task={delay=function(seconds,fn) table.insert(delayed,{seconds=seconds,fn=fn}) end}
modules.PickupBuilder={build=function(model)
 local halo=Instance.new("Folder");halo.Name="GroundHalo";halo.Parent=model
 local part=Instance.new("Part");part.Transparency=.3;part.Parent=halo
end}
local script={Parent={Parent={Assets={PickupBuilder="PickupBuilder"}}}}
local clock=0
local workspace={GetServerTimeNow=function() return clock end}
local runService={Heartbeat={Connect=function() return{} end}}
local game={GetService=function(_,name) if name=="RunService" then return runService end;return{CatchTheScrapShared={Config="Config",Inventory="Inventory",CrateRules="CrateRules",RobotCatalog="RobotCatalog"}} end}
local require=function(name) return assert(modules[name]) end
'''
source=(ROOT/'src/server/Services/ItemService.luau').read_text()
rare=(ROOT/'src/server/Services/RareBoxService.luau').read_text()
checks=r'''
local count=0
local function check(ok,message) count+=1;assert(ok,message) end
local parent=Instance.new("Folder")
local world={items=Instance.new("Folder"),root=Instance.new("Folder")};world.root.Parent=parent
local inventory=modules.Inventory.new(12)
local items=ItemService.new(world,inventory)
local slot={position=vec(-22,2.3,140),definition=modules.CrateRules.definition("Rare"),clearance=2.3,crateStage=1}
local record=items:spawn(slot)
check(record.rewardRarity=="Rare" and rolls==1,"crate result rolled once on the server at spawn")
check(record.model:GetAttribute("Rarity")=="Rare" and record.model:GetAttribute("RewardRarity")==nil,"reward is absent from replicated item attributes")
check(record.model:GetAttribute("Variant")==nil and record.model.Name=="Rare Robot Box","prompt and model do not spoil the reward")
local character=Instance.new("Model")
local root=Instance.new("Part");root.Name="HumanoidRootPart";root.CFrame=CFrame.new(0,3,0);root.Parent=character
local head=Instance.new("Part");head.Name="Head";head.Position=vec(0,4.5,0);head.Size=vec(2,2,2);head.Parent=character
items:attach(record,root)
check(math.abs(record.root.CFrame.Position.Y-7.8)<1e-6,"item carried above the avatar head, not at waist height")
check(not record.root.Anchored and record.weld.Part0==root,"carried box uses the normal character weld")
check(record.model.GroundHalo:GetChildren()[1].Transparency==1,"carried halo hidden by server")
items:place(record,vec(5,2.3,100));items:resetToSpawn(record)
check(record.rewardRarity=="Rare" and rolls==1,"drop/reset cannot reroll a box")
check(record.root.Anchored and record.weld==nil and record.prompt.Enabled,"drop restores stable pickup state")
local pickups=0
items.onPickup=function() pickups+=1 end
local oldPrompt=record.prompt
items:consume(record)
check(slot.current==nil and items.records[record.id]==nil and record.model.destroyed,"box consumed exactly once")
check(#delayed==0,"event boxes never enter the ordinary respawn timer")
local replacement=items:spawn(slot)
check(replacement~=record and slot.current==replacement and rolls==2 and replacement.rewardVariant~=record.rewardVariant,"one respawn creates one fresh sealed result")
oldPrompt.Triggered.fn({})
check(pickups==0,"stale prompt cannot pick up a replacement crate")
replacement.prompt.Triggered.fn({})
check(pickups==1,"live replacement prompt still works")
local remoteAttrs,events,joinEvents={},{},{}
local remote={SetAttribute=function(_,name,value) remoteAttrs[name]=value end,FireAllClients=function(_,channel,payload) table.insert(events,{channel=channel,payload=payload}) end,FireClient=function(_,player,channel,payload) table.insert(joinEvents,payload) end}
world.crateSpawns={}
for stage=1,7 do table.insert(world.crateSpawns,{position=vec(-22,2.3,20+(stage-1)*480+120),crateStage=stage,clearance=2.3}) end
local service=RareBoxService.new(world,items,inventory,remote)
service:tick(59);check(#events==0,"no ordinary robot crates are spawned at server boot")
service:tick(60)
check(#events==1 and events[1].channel=="RareBoxSpawned" and events[1].payload.rarity=="Legendary","one typed server-wide event announces the exact box tier")
check(remoteAttrs.RareBox1Rarity=="Legendary" and remoteAttrs.RareBox1Id==events[1].payload.id,"late clients can recover active announcements from replicated state")
check(service.live[1].record.rewardRarity=="Legendary","announced box contains the promised tier")
service:tick(61);check(#events==1,"heartbeat cannot repeat an announcement")
service:tick(240);check(#service.live==0,"unclaimed ground boxes expire without triggering replacements")
service:tick(299);check(#events==1,"expiration does not bypass event scarcity")
service:tick(300);local first=service.live[1].record
inventory.items[first.id].owner=11
service:tick(500);check(items.records[first.id]~=nil,"an owned carried box is never deleted by ground expiry")
service:tick(540);local second=service.live[2].record
service:announceTo({});check(#joinEvents==1 and joinEvents[1].id==second.id,"joining players see unclaimed event, not another player's carried box")
inventory.items[second.id].owner=12
service:tick(780);check(#service.live==2 and #events==3,"live limit includes carried boxes")
service:tick(900);check(#events==3,"full live-box limit prevents further spawns")
inventory.items[first.id]=nil;items:consume(first);service:tick(901)
check(#events==4 and #service.live==2,"consuming a box releases capacity only after the scheduled interval")
print(string.format("Actual item lifecycle and rare-event schedule passed %d simulated-boundary checks; Studio physics remain required",count))
'''
fixture=ROOT/'build/item-integration.spec.luau'
fixture.write_text(header+'\nlocal ItemService=(function()\n'+source+'\nend)()\nlocal RareBoxService=(function()\n'+rare+'\nend)()\n'+checks)
subprocess.run([shutil.which('luau') or '/workspace/.catch-the-scrap-tools/bin/luau',str(fixture)],cwd=ROOT,check=True)
