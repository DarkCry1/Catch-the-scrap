#!/usr/bin/env python3
"""Execute real pickup/item lifecycle code with mocked geometry, not engine physics."""
from pathlib import Path
import shutil,subprocess
ROOT=Path(__file__).resolve().parents[1]
header=r'''
--!nonstrict
local nativeRequire=require
local modules={Config=nativeRequire("../src/shared/Config"),Inventory=nativeRequire("../src/shared/Inventory"),RobotCatalog=nativeRequire("../src/shared/RobotCatalog"),SpawnRules=nativeRequire("../src/shared/SpawnRules"),CrateRules=nativeRequire("../src/shared/CrateRules")}
local vecMeta={}
local function vec(x,y,z) return setmetatable({X=x,Y=y,Z=z},vecMeta) end
vecMeta.__add=function(a,b) return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vecMeta.__mul=function(a,b) return vec(a.X*b,a.Y*b,a.Z*b) end
local Vector3={new=vec,one=vec(1,1,1)}
local cfMeta={}
local CFrame={new=function(x,y,z) local p=if type(x)=="table" then x else vec(x or 0,y or 0,z or 0);return setmetatable({Position=p},cfMeta) end}
cfMeta.__mul=function(a,b) return CFrame.new(a.Position+b.Position) end
cfMeta.__index={PointToObjectSpace=function(self,p) return vec(p.X-self.Position.X,p.Y-self.Position.Y,p.Z-self.Position.Z) end}
local methods={}
local objMeta={}
objMeta.__index=function(self,key)
 if methods[key] then return methods[key] end
 if key=="Position" and rawget(self,"CFrame") then return self.CFrame.Position end
 local stored=rawget(self,"_"..key);if stored~=nil then return stored end
 for _,child in self.children do if child.Name==key then return child end end
 return nil
end
objMeta.__newindex=function(self,key,value)
 if key=="Parent" then
  if rawget(self,"_Parent")==value then return end;rawset(self,"_Parent",value);if value then table.insert(value.children,self) end
 else rawset(self,key,value) end
end
function methods:GetChildren() local a={};for _,c in self.children do if c.Parent==self and not c.destroyed then table.insert(a,c) end end;return a end
function methods:FindFirstChild(name) for _,c in self:GetChildren() do if c.Name==name then return c end end;return nil end
function methods:FindFirstChildOfClass(class) for _,c in self:GetChildren() do if c.ClassName==class then return c end end;return nil end
function methods:SetAttribute(name,value) self.attrs[name]=value end
function methods:GetAttribute(name) return self.attrs[name] end
function methods:PivotTo(cf) self.PrimaryPart.CFrame=cf end
function methods:Destroy() self.Parent=nil;self.destroyed=true end
local failIK=false
local Instance={new=function(class)
 if class=="IKControl" and failIK then error("Simulated unsupported avatar solver") end
 local o=setmetatable({children={},attrs={},ClassName=class},objMeta)
 if class=="Tool" then o.Unequipped={Connect=function(self,fn) self.fn=fn end} end
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
local task={defer=function(fn) fn() end,delay=function(seconds,fn) table.insert(delayed,{seconds=seconds,fn=fn}) end}
modules.PickupBuilder={build=function(model)
 local halo=Instance.new("Folder");halo.Name="GroundHalo";halo.Parent=model
 local part=Instance.new("Part");part.Transparency=.3;part.Parent=halo
end}
local script={Parent={Parent={Assets={PickupBuilder="PickupBuilder",CarryRig="CarryRig"}}}}
local clock=0
local workspace={GetServerTimeNow=function() return clock end}
local runService={Heartbeat={Connect=function() return{} end}}
local game={GetService=function(_,name) if name=="RunService" then return runService end;return{CatchTheScrapShared={Config="Config",Inventory="Inventory",CrateRules="CrateRules",RobotCatalog="RobotCatalog",SpawnRules="SpawnRules"}} end}
local require=function(name) return assert(modules[name]) end
'''
source=(ROOT/'src/server/Services/ItemService.luau').read_text()
rig=(ROOT/'src/server/Assets/CarryRig.luau').read_text()
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
local character=Instance.new("Model");character.Parent=parent
local humanoid=Instance.new("Humanoid");humanoid.Health=100;humanoid.Parent=character
function humanoid:EquipTool(tool) tool.Parent=character end
local arm=Instance.new("Part");arm.Name="Right Arm";arm.Parent=character
local root=Instance.new("Part");root.Name="HumanoidRootPart";root.CFrame=CFrame.new(0,3,0);root.Parent=character
local head=Instance.new("Part");head.Name="Head";head.Position=vec(0,4.5,0);head.Size=vec(2,2,2);head.Parent=character
local mode=items:attach(record,root,"Auto")
check(mode=="Handheld" and record.rig[1].ClassName=="Tool","R6 uses native Tool carrying")
check(not record.root.Anchored and record.weld.Part0.Name=="Handle","cargo welded to the native Tool handle")
local tool=record.rig[1]
check(tool.CanBeDropped==false and tool.RequiresHandle,"Tool cannot bypass server inventory by being dropped")
items:attach(record,root,"Harness")
check(record.weld.Part0==root and record.root.CFrame.Position.Z>root.CFrame.Position.Z,"harness fallback visibly mounts cargo behind the body")
for _,name in {"LeftUpperArm","RightUpperArm","LeftHand","RightHand"} do local p=Instance.new("Part");p.Name=name;p.Parent=character end
mode=items:attach(record,root,"Auto")
check(mode=="Two-hand IK" and record.root.CFrame.Position.Z<root.CFrame.Position.Z,"R15 uses native two-hand IK with cargo in front")
local countIK=0
for _,object in record.rig do
 if object.ClassName=="IKControl" then
  countIK+=1;check(object.Type=="Position" and object.Weight==1 and object.Target and object.EndEffector,"native solver has valid target and chain")
 end
end
check(countIK==2,"both hands have independent native IK solvers")
local controls=record.rig
failIK=true
mode=items:attach(record,root,"Auto")
check(mode=="Handheld","failed native IK automatically falls back to standard Tool")
for _,object in controls do check(object.destroyed,"old IK instances are released when switching carry method") end
failIK=false
local originalEquip=humanoid.EquipTool
humanoid.EquipTool=function() error("Simulated equip failure") end
mode=items:attach(record,root,"Handheld")
check(mode=="Harness" and record.carrying,"failed Tool still secures the cargo in a harness")
humanoid.EquipTool=originalEquip
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
world.spawnObstacles={}
local normal={position=vec(0,2,0),definition=modules.Config.Items[1],clearance=2,zone=1}
local scrap=items:spawn(normal)
local old=normal.position
inventory.items[scrap.id]=nil;items:consume(scrap)
check(delayed[#delayed].seconds==modules.Config.RespawnSeconds,"normal scrap keeps its normal respawn delay")
delayed[#delayed].fn()
check(normal.current~=nil and (normal.position.X-old.X)^2+(normal.position.Z-old.Z)^2>=144,"actual ItemService replacement chooses a new position at least 12 studs away")
local isolatedWorld={crateSpawns={{position=vec(-22,2.3,620),crateStage=2,clearance=2.3}},root=world.root,items=world.items}
local isolatedInventory=modules.Inventory.new(12)
local isolatedItems=ItemService.new(isolatedWorld,isolatedInventory)
local forcedService=RareBoxService.new(isolatedWorld,isolatedItems,isolatedInventory,remote)
local forced=forcedService:forceSpawn("Rare",2)
check(forced and forcedService.live[1].record.rewardRarity=="Rare" and forcedService.live[1].packet.stage==2,"actual forced event honors admin tier/stage")
check(forcedService.nextAt>=modules.Config.Crates.SpawnMin,"admin event resets normal event interval")
local blocked=forcedService:forceSpawn("Legendary",2)
check(not blocked and #forcedService.live==1,"occupied candidate is preserved when another admin event is requested")
print(string.format("Actual native carry/item lifecycle and rare-event schedule passed %d simulated-boundary checks; Studio physics remain required",count))
'''
fixture=ROOT/'build/item-integration.spec.luau'
fixture.write_text(header+'\nmodules.CarryRig=(function()\n'+rig+'\nend)()\nlocal ItemService=(function()\n'+source+'\nend)()\nlocal RareBoxService=(function()\n'+rare+'\nend)()\n'+checks)
subprocess.run([shutil.which('luau') or '/workspace/.catch-the-scrap-tools/bin/luau',str(fixture)],cwd=ROOT,check=True)
