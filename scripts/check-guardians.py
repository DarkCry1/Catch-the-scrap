#!/usr/bin/env python3
"""Run actual guardian server, model builder, animator and saving code across mocks.
No Studio physics, graphics or real DataStore access is claimed by these checks.
"""
from pathlib import Path
import subprocess, shutil
ROOT=Path(__file__).resolve().parents[1]
header=r'''
--!nonstrict
local nativeRequire=require
local modules={}
for _,name in {"Config","GuardianRules","GuardianNavigation","GuardianBlueprint","SaveSchema","Economy"} do modules[name]=nativeRequire("../src/shared/"..name) end
local checks=0
local function check(ok,message) checks+=1;assert(ok,message) end
local clock=0
local os={clock=function() return clock end}
local function signal()
 local listeners={}
 return {Connect=function(_,fn) local entry={fn=fn,live=true};table.insert(listeners,entry);return{Disconnect=function() entry.live=false end} end,Fire=function(_,...) for _,v in table.clone(listeners) do if v.live then v.fn(...) end end end}
end
local V={};local vm={}
function V.new(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vm) end
vm.__index=function(v,k) if k=="Magnitude" then return math.sqrt(v.X^2+v.Y^2+v.Z^2) elseif k=="Unit" then local n=v.Magnitude;return V.new(v.X/n,v.Y/n,v.Z/n) end end
vm.__add=function(a,b)return V.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
vm.__sub=function(a,b)return V.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
vm.__mul=function(a,b) if type(a)=="number" then a,b=b,a end;return V.new(a.X*b,a.Y*b,a.Z*b)end
vm.__div=function(a,b)return a*(1/b)end
local Vector3=V;V.zero=V.new();V.one=V.new(1,1,1)
-- CFrame mock preserves translations and look direction. Rotation/rendering
-- itself is a Studio check, not asserted by this adapter.
local CFrame={};local cm={}
function CFrame.new(x,y,z) return setmetatable({Position=if type(x)=="table" then x else V.new(x,y,z)},cm) end
CFrame.identity=CFrame.new()
function CFrame.Angles() return CFrame.new() end
function CFrame.lookAt(p,to) local c=CFrame.new(p);c.LookVector=(to-p).Unit;return c end
cm.__mul=function(a,b)return CFrame.new(a.Position+b.Position)end
cm.__index={Lerp=function(a,b,t)return CFrame.new(a.Position+(b.Position-a.Position)*t)end}
local function enums()return setmetatable({},{__index=function(t,k)rawset(t,k,k);return k end})end
local Enum={Material=enums(),PartType=enums(),ModelStreamingMode=enums(),Font=enums()}
local Color3={fromRGB=function(r,g,b)return{r,g,b}end}
local UDim2={fromOffset=function(x,y)return{x,y}end,fromScale=function(x,y)return{x,y}end}
local tagged,added,removed={},{},{}
local Tags={}
function Tags:GetInstanceAddedSignal(tag)added[tag]=added[tag] or signal();return added[tag]end
function Tags:GetInstanceRemovedSignal(tag)removed[tag]=removed[tag] or signal();return removed[tag]end
function Tags:AddTag(o,tag)tagged[tag]=tagged[tag] or {};tagged[tag][o]=true;self:GetInstanceAddedSignal(tag):Fire(o)end
function Tags:RemoveTag(o,tag)if tagged[tag] and tagged[tag][o] then tagged[tag][o]=nil;self:GetInstanceRemovedSignal(tag):Fire(o)end end
function Tags:GetTagged(tag)local out={};for o in tagged[tag] or {} do table.insert(out,o)end;return out end
local methods={}
function methods:SetAttribute(k,v)self.attrs[k]=v;if self.attrSignals[k] then self.attrSignals[k]:Fire() end end
function methods:GetAttribute(k)return self.attrs[k]end
function methods:GetAttributeChangedSignal(k)self.attrSignals[k]=self.attrSignals[k] or signal();return self.attrSignals[k]end
function methods:FindFirstChild(k)for _,o in self.children do if o.Name==k and o.Parent==self then return o end end end
methods.WaitForChild=methods.FindFirstChild
function methods:FindFirstChildOfClass(k)for _,o in self.children do if o.ClassName==k and o.Parent==self then return o end end end
function methods:Destroy()
 if self.destroyed then return end;self.destroyed=true;self.Destroying:Fire()
 for tag,objects in tagged do if objects[self] then Tags:RemoveTag(self,tag)end end
 for _,o in table.clone(self.children) do o:Destroy()end;self.Parent=nil
end
local im={}
im.__index=function(o,k)if methods[k]then return methods[k]end;if k=="Position" and o.values.CFrame then return o.values.CFrame.Position end;return o.values[k]end
im.__newindex=function(o,k,v)o.values[k]=v;if k=="Parent" and v then table.insert(v.children,o)end end
local Instance={new=function(class)return setmetatable({ClassName=class,attrs={},attrSignals={},children={},values={},Destroying=signal()},im)end}
local RunService={Heartbeat=signal(),PreSimulation=signal()}
local services={RunService=RunService,CollectionService=Tags,ReplicatedStorage={CatchTheScrapShared={}}}
for name in modules do services.ReplicatedStorage.CatchTheScrapShared[name]=name end
local game={GetService=function(_,name)return services[name]end}
local script={Parent={RarityDecor="RarityDecor",Parent={Assets={GuardianBuilder="GuardianBuilder"}}}}
modules.RarityDecor={spectrum=function()end}
local require=function(name)return assert(modules[name],name)end
local task={spawn=function(fn)fn()end,wait=function(dt)clock+=dt end}
'''
body=''
for name,path in [('GuardianBuilder','src/server/Assets/GuardianBuilder.luau'),('SecurityService','src/server/Services/SecurityService.luau'),('GuardianAnimator','src/client/GuardianAnimator.luau'),('SaveService','src/server/Services/SaveService.luau')]:
    body+=f'local {name}=(function()\n{(ROOT/path).read_text()}\nend)()\nmodules["{name}"]={name}\n'
checks=r'''
local Config=modules.Config
local Rules=modules.GuardianRules
local function fresh(geometry)
 local world={root=Instance.new("Folder"),guardianGeometry=geometry or {}}
 local carry={players={},items={records={}},inventory={carrying={},items={}},caught=0,bank=12345,robotCount=3}
 function carry:resetCarried(player)
  self.caught+=1;local id=self.inventory.carrying[player.UserId];self.inventory.carrying[player.UserId]=nil;self.inventory.items[id].owner=nil
 end
 local packets={};local remote={FireClient=function(_,player,channel,packet)table.insert(packets,{player=player,channel=channel,packet=packet})end}
 local security=SecurityService.new(world,carry,remote,function()return clock end)
 local escaped=0;security.onEscape=function()escaped+=1 end
 local function carrier(stage,dx)
  local g=security.guardians[stage];local character=Instance.new("Model")
  local root=Instance.new("Part");root.Name="HumanoidRootPart";root.CFrame=CFrame.new(g.position.x+(dx or 1),3,g.position.z);root.Parent=character
  local humanoid=Instance.new("Humanoid");humanoid.Health=100;humanoid.Parent=character
  local player=Instance.new("Player");player.UserId=100+stage;player.Character=character;player.Parent=world.root
  local id="loot-"..stage;carry.players[player]={};carry.inventory.carrying[player.UserId]=id;carry.inventory.items[id]={owner=player.UserId};carry.items.records[id]={slot={zone=stage}}
  return player,root,humanoid,id
 end
 return security,carry,carrier,packets,function()return escaped end
end
local security,carry,carrier,packets,escapes=fresh()
check(#security.guardians==7 and #Tags:GetTagged("StageGuardian")==7,"exactly one model per stage")
local players={}
for stage,g in security.guardians do
 check(g.rig.model:GetAttribute("ChaseSpeed")==Config.Guardians.Profiles[stage].ChaseSpeed,"published per-stage speed")
 local count=0;for _,motor in g.rig.joints do count+=1;check(motor.Part0~=nil and motor.Part1~=nil,"connected limb motor")end
 check(count==6,"six animated groups per robot")
 local p=carrier(stage);table.insert(players,p)
end
security:step(.05)
for _,g in security.guardians do check(g.state=="Alert","all rarities warn before pursuit")end
for _,p in players do check(p:GetAttribute("DroneChase")==true,"existing chase UI channel works")end
check(carry.caught==0,"no confiscation during warning")
clock+=2;security:step(.05)
for _,g in security.guardians do check(g.state=="Chase","warning transitions into chase")end
security:step(.05)
check(carry.caught==7,"actual server confiscates once for each close carrier")
check(carry.bank==12345 and carry.robotCount==3,"banked progress untouched")
security:step(.05);check(carry.caught==7,"cooldown prevents duplicate catches")
for _,p in players do check(p:GetAttribute("DroneChase")==false,"catch clears chase HUD")end
local viewer=players[1];viewer.Character:FindFirstChild("HumanoidRootPart").CFrame=CFrame.new(0,3,80)
GuardianAnimator.start(viewer);RunService.PreSimulation:Fire(.016)
check(security.guardians[1].rig.joints.LeftArm.Transform~=nil,"actual animator drives nearby arm motors")
security:start();security:start();RunService.Heartbeat:Fire(.05)
security:destroy();check(#Tags:GetTagged("StageGuardian")==0,"destroy clears models and stream tags")
RunService.PreSimulation:Fire(.016);RunService.Heartbeat:Fire(.05)
for _,case in {"drop","die","leave","cross","timeout","foreign","unladen","forgedOwner"} do
 local s,c,make,_,escaped=fresh();local player,root,humanoid,id=make(1,12);local g=s.guardians[1]
 if case=="foreign" then c.items.records[id].slot.zone=2 elseif case=="unladen" then c.inventory.carrying[player.UserId]=nil elseif case=="forgedOwner" then c.inventory.items[id].owner=999 end
 s:step(.05)
 if case=="foreign" or case=="unladen" or case=="forgedOwner" then
  check(g.state=="Patrol","unrelated loot, empty hands and invalid ownership ignored")
 else
  clock+=2;s:step(.05);check(g.state=="Chase","scenario starts a real chase")
  if case=="drop" then c.inventory.carrying[player.UserId]=nil
  elseif case=="die" then humanoid.Health=0
  elseif case=="leave" then player.Parent=nil
  elseif case=="cross" then root.CFrame=CFrame.new(0,3,Config.TrackStart-1)
  elseif case=="timeout" then clock+=20 end
  s:step(.05);check(g.state=="Cooldown" and c.caught==0,"safe termination does not confiscate loot")
  check(escaped()==(if case=="cross" or case=="timeout" then 1 else 0),"escape quests require actual survival with loot")
  check(player:GetAttribute("DroneChase")==false,"termination clears chase attribute")
 end
 s:destroy()
end
local s,c,make=fresh();local player,root=make(1,35);local g=s.guardians[1]
s:step(.05);clock+=2;s:step(.05)
local before={x=g.position.x,z=g.position.z};s:step(1000)
check(modules.GuardianNavigation.distance(before,g.position)<=g.profile.ChaseSpeed*.15+.001,"server stall movement is capped")
root.CFrame=CFrame.new(0,3,Config.TrackStart+Config.ZoneLength);s:step(.05)
check(g.state=="Cooldown" and Rules.inside(1,g.position),"guardian never crosses district seam")
s:destroy()
-- Measure the actual service's displacement in every district on a clear path.
local fast,fc,spawn=fresh()
for i=1,7 do spawn(i,20) end
fast:step(.05);clock+=2;fast:step(.05)
local origins={};for i,g in fast.guardians do origins[i]={x=g.position.x,z=g.position.z}end
fast:step(.1)
for i,g in fast.guardians do
 local moved=modules.GuardianNavigation.distance(origins[i],g.position)
 check(math.abs(moved-g.profile.ChaseSpeed*.1)<.001,"actual stage movement matches configured chase speed")
 check(Rules.inside(i,g.position),"measured chase remains in its own stage")
end
check(fc.caught==0,"distant players are not caught by movement alone")
for player in fc.players do fc.inventory.carrying[player.UserId]=nil end
fast:step(.05);clock+=Config.Guardians.CooldownSeconds+.1;fast:step(.05)
for _,g in fast.guardians do check(g.state=="Patrol","cooldown restores patrol")end
fast:destroy()
-- A wall blocks both spotting and confiscation, even if a chase already exists.
local wall={name="Occluder",collidable=true,size={.2,18,20},position={0,9,84},pitch=0,yaw=0,roll=0}
local blocked,bc,mk=fresh({wall});local bp,br=mk(7,1);local bg=blocked.guardians[7]
-- Move the finite wall to this stage and rebuild only that test navigation grid.
wall.position={0,9,bg.position.z};bg.navigation=modules.GuardianNavigation.new(7,{wall})
bg.position={x=-8.2,z=wall.position[3]};br.CFrame=CFrame.new(.5,3,wall.position[3])
blocked:step(.05);check(bg.state=="Patrol","solid scenery blocks initial detection")
blocked:setState(bg,"Chase",bp);bg.chaseUntil=clock+10
blocked:step(.05);check(bc.caught==0,"nearby target cannot be caught through solid scenery")
blocked:destroy()
-- Actual save adapter still writes and reloads the imported persistent account.
local records={};local store={UpdateAsync=function(_,key,fn)local v=fn(records[key]);if v~=nil then records[key]=v end end}
local player={UserId=11824623188,Parent=true}
local saves=SaveService.new({store=store,jobId="A",now=function()return clock end,wait=function(dt)clock+=dt end})
local a,status=saves:load(player);check(status=="new","new DataStore record can lock")
a.cash=7654;a.rebirths=2;a.dex.Rustbucket=1
check(saves:release(player,a),"release writes actual serialized account")
local other=SaveService.new({store=store,jobId="B",now=function()return clock end})
local b,loaded=other:load(player)
check(loaded=="loaded" and b.cash==7654 and b.rebirths==2 and b.dex.Rustbucket==1,"persistent progress survives a simulated server handoff")
local offline=SaveService.new({jobId="offline"});local _,state=offline:load(player)
check(state=="offline" and not offline:save(player,b,false),"unavailable DataStore never overwrites a locked profile")
print("Actual guardian server/builder/animator and save adapter passed "..checks.." simulated-boundary checks; Studio remains required")
'''
output=ROOT/'build/guardian-services-check.luau';output.parent.mkdir(exist_ok=True);output.write_text(header+body+checks)
subprocess.run([shutil.which('luau') or '/workspace/.catch-the-scrap-tools/bin/luau',str(output)],cwd=ROOT,check=True)
