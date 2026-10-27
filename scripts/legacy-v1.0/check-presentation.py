#!/usr/bin/env python3
"""Run the actual camera/animation adapters across a simulated engine boundary."""
from pathlib import Path
import subprocess, shutil
ROOT=Path(__file__).resolve().parents[2]
header=r'''
--!nonstrict
local task={spawn=function(fn) fn() end}
local nativeRequire=require
local modules={Config=nativeRequire("../src/shared/Config"),WorkshopMotion=nativeRequire("../src/shared/WorkshopMotion"),CameraBounds=nativeRequire("../src/shared/CameraBounds"),PickupMotion=nativeRequire("../src/shared/PickupMotion")}
local function signal()
 local listeners={}
 return {Connect=function(_,fn) listeners[fn]=true;return{Disconnect=function() listeners[fn]=nil end} end,Fire=function(_,...) for fn in listeners do fn(...) end end}
end
local vectorMeta={}
local function vector(x,y,z) return setmetatable({X=x,Y=y,Z=z,Magnitude=math.sqrt(x*x+y*y+z*z)},vectorMeta) end
vectorMeta.__sub=function(a,b) return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
local Vector3={new=vector}
local cfMeta={}
local CFrame={}
function CFrame.new(x,y,z)
 local p=if type(x)=="table" then x else vector(x or 0,y or 0,z or 0)
 return setmetatable({Position=p,Rotation={}},cfMeta)
end
function CFrame.Angles(x,y,z) return {tilt=x,yaw=y,roll=z} end
cfMeta.__mul=function(a,b) local result=CFrame.new(a.Position);result.rotation=b;return result end
cfMeta.__index={Lerp=function(self,target,alpha) local result=CFrame.new(self.Position);result.poseAlpha=alpha;return result end}

CFrame.identity=CFrame.new(0,0,0)
local render=signal()
local preAnimation,preSimulation=signal(),signal()
local assistBeat=signal()
local bound,priority
local added,removed={},{}
local services={Players={},RunService={Heartbeat=assistBeat,PreAnimation=preAnimation,PreSimulation=preSimulation,RenderStepped=render,BindToRenderStep=function(_,name,p,fn) bound=fn;priority=p end}}
services.CollectionService={
 GetInstanceAddedSignal=function(_,tag) added[tag]=signal();return added[tag] end,
 GetInstanceRemovedSignal=function(_,tag) removed[tag]=signal();return removed[tag] end,
 GetTagged=function() return{} end,
}
local shared={Config="Config",CameraBounds="CameraBounds",WaitForChild=function(_,name) return name end}
services.ReplicatedStorage={CatchTheScrapShared={Config="Config",PickupMotion="PickupMotion",WorkshopMotion="WorkshopMotion"},WaitForChild=function() return shared end}
local game={GetService=function(_,name) return services[name] end}
local Enum={RenderPriority={Camera={Value=200},Character={Value=300}},CameraType={Scriptable="Scriptable"}}
local require=function(name) return assert(modules[name]) end
local camera={CameraType="Custom",CFrame=CFrame.new(120,12,200),Focus=CFrame.new(77,6,200),ViewportSize=vector(1920,1080,0),NearPlaneZ=-.5,FieldOfView=70}
local workspace={CurrentCamera=camera}
local characterRoot={Position=vector(0,6,200)}
local player={Character={FindFirstChild=function() return characterRoot end}}
local checks=0
local function check(ok,message) checks+=1;assert(ok,message) end
'''
body=''
for name in ('CameraGuard','PickupAnimator','CarryAssist'):
    body+=f'local {name}=(function()\n'+(ROOT/f'src/client/{name}.luau').read_text()+'\nend)()\n'
checks=r'''
CameraGuard.start(player)
check(player.CameraMaxZoomDistance==32 and player.CameraMinZoomDistance==.5,"normal first/third person zoom bounds")
check(priority==201,"containment runs after the standard Roblox camera")
bound()
check(camera.CFrame.Position.X<=78,"right-button orbit is contained by runtime adapter")
camera.CameraType="Scriptable";camera.CFrame=CFrame.new(120,12,200);bound()
check(camera.CFrame.Position.X==120,"cinematic cameras are not overwritten")
camera.CameraType="Custom";camera.CFrame=CFrame.new(0,12,190);camera.Focus=CFrame.new(0,6,200);bound()
check(camera.CFrame.Position.Z==190,"ordinary camera positioning remains intact")
workspace.CurrentCamera=nil;bound();workspace.CurrentCamera=camera
check(true,"temporary camera replacement is tolerated")
PickupAnimator.start(player)
local attrSignal=signal()
local carrier=nil
local joint={Parent=true,C0=CFrame.identity}
local root={Position=vector(5,2,200),FindFirstChild=function() return joint end}
root.WaitForChild=root.FindFirstChild
local halo={{Parent=true},{Parent=true}}
local model={Parent=true}
function model:FindFirstChild(name) return if name=="CarryRoot" then root else {GetChildren=function() return halo end} end
model.WaitForChild=model.FindFirstChild
function model:GetAttribute(name) return if name=="CarrierUserId" then carrier else .5 end
function model:GetAttributeChangedSignal() return attrSignal end
added.AnimatedScrap:Fire(model);render:Fire(.3)
check(joint.C0.Position.Y>=.35 and halo[1].LocalTransparencyModifier<1,"nearby scrap bobs and shows its ground halo")
carrier=11;attrSignal:Fire()
check(joint.C0==CFrame.identity and halo[1].LocalTransparencyModifier==1,"picking up stops hover and hides halo immediately")
render:Fire(.3)
check(joint.C0==CFrame.identity,"carried visual is never animated away from the hand")
carrier=nil;attrSignal:Fire();render:Fire(.3)
check(joint.C0.Position.Y>=.35,"dropping resumes hover")
characterRoot.Position=vector(500,6,200);render:Fire(.3)
check(joint.C0==CFrame.identity and halo[1].LocalTransparencyModifier==1,"distance culling resets the rig")
characterRoot.Position=vector(0,6,200);render:Fire(.3)
check(joint.C0.Position.Y>=.35,"returning restarts animation")
removed.AnimatedScrap:Fire(model);render:Fire(.3)
check(joint.C0==CFrame.identity and halo[1].LocalTransparencyModifier==1,"stream-out releases animation state")
added.AnimatedScrap:Fire(model);render:Fire(.3)
check(joint.C0.Position.Y>=.35,"stream-in reattaches cleanly")
player.Character=nil;render:Fire(.3)
check(joint.C0==CFrame.identity,"character removal suspends animations safely")
local mode,style,itemId="Two-hand IK","Auto","cargo-1"
local hand={Position=vector(0,4,0)}
local target={WorldPosition=vector(0,4,0)}
local cargo={GetAttribute=function(_,name) return if name=="CarrierUserId" then 11 else itemId end,FindFirstChild=function() return{FindFirstChild=function() return target end} end}
local world={FindFirstChild=function() return{GetChildren=function() return{cargo} end} end}
function workspace:FindFirstChild() return world end
local actor={UserId=11,Character={FindFirstChild=function() return hand end},GetAttribute=function(_,name) return if name=="CarryMode" then mode else style end}
local switches=0
CarryAssist.start(actor,{FireServer=function(_,action,value) check(action=="SetCarryStyle" and value=="Handheld","visual fallback requests only an allowed own-carry style");switches+=1 end})
for _=1,12 do assistBeat:Fire(.25) end
check(switches==0,"hands reaching targets do not trigger unnecessary fallbacks")
hand.Position=vector(0,1,0)
for _=1,7 do assistBeat:Fire(.25) end
check(switches==0,"native solver receives a grace period")
assistBeat:Fire(.25)
check(switches==1,"visibly failed IK automatically selects standard Tool carry")
for _=1,12 do assistBeat:Fire(.25) end
check(switches==1,"fallback cannot flood the server with repeated requests")
itemId="cargo-2";style="Harness"
for _=1,12 do assistBeat:Fire(.25) end
check(switches==1,"explicit carry choice is respected")
print(string.format("Actual camera/pickup/carry-assist adapters passed %d simulated-boundary checks; Studio remains required",checks))
'''
fixture=ROOT/'build/presentation-integration.spec.luau'
fixture.parent.mkdir(exist_ok=True)
fixture.write_text(header+body+checks)
subprocess.run([shutil.which('luau') or '/workspace/.catch-the-scrap-tools/bin/luau',str(fixture)],cwd=ROOT,check=True)
