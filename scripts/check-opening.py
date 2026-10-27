#!/usr/bin/env python3
"""Run actual cinematic lifecycle against a mocked camera boundary, not Studio graphics."""
from pathlib import Path
import shutil,subprocess
ROOT=Path(__file__).resolve().parents[1]
header=r'''
--!nonstrict
local nativeRequire=require
local modules={RarityStyle=nativeRequire("../src/shared/RarityStyle"),CameraBounds=nativeRequire("../src/shared/CameraBounds")}
local vm={}
local function vector(x,y,z) return setmetatable({X=x,Y=y,Z=z,Magnitude=math.sqrt(x*x+y*y+z*z)},vm) end
vm.__add=function(a,b) return vector(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vm.__sub=function(a,b) return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vm.__mul=function(a,b) return vector(a.X*b,a.Y*b,a.Z*b) end
local Vector3={new=vector}
local Vector2={new=function(...) return{...} end}
local CFrame={lookAt=function(p,f) return{Position=p,focus=f} end}
local clock=0
local skip,render
local guiHud={Enabled=true}
local camera={Parent=true,CameraType="Custom",CameraSubject="Humanoid",FieldOfView=70}
local workspace={CurrentCamera=camera,GetServerTimeNow=function() return clock end,Raycast=function() return nil end}
local root={Position=vector(0,3,-100)}
local character={FindFirstChild=function() return root end,FindFirstChildOfClass=function() return{Health=100} end}
local player={UserId=11,Character=character,PlayerGui={FindFirstChild=function() return guiHud end}}
local Prompts={Enabled=true}
local services={
 ReplicatedStorage={CatchTheScrapShared={RarityStyle="RarityStyle",CameraBounds="CameraBounds"}},
 RunService={BindToRenderStep=function(_,name,priority,fn) render=fn end,UnbindFromRenderStep=function() render=nil end},
 ContextActionService={BindAction=function(_,name,fn) skip=fn end,UnbindAction=function() skip=nil end},
 Lighting={},UserInputService={KeyboardEnabled=true},ProximityPromptService=Prompts,
}
local game={GetService=function(_,name) return services[name] end}
local Enum={CameraType={Scriptable="Scriptable"},UserInputState={Begin="Begin"},ContextActionResult={Sink="Sink"},KeyCode={Space="Space",ButtonB="B"},RenderPriority={Camera={Value=200}},Font={GothamBold="Bold"},RaycastFilterType={Exclude="Exclude"}}
local Color3={fromRGB=function(...) return{...} end,new=function(...) return{...} end}
local UDim2={new=function(...) return{...} end,fromOffset=function(...) return{...} end}
local UDim={new=function(...) return{...} end}
local Instance={new=function(class) return{ClassName=class,Parent=true,Activated={Connect=function() end},Destroy=function(self) self.Parent=nil end} end}
local RaycastParams={new=function() return{} end}
local require=function(name) return assert(modules[name]) end
'''
source=(ROOT/'src/client/OpeningCamera.luau').read_text()
checks=r'''
local n=0
local function check(ok,message) n+=1;assert(ok,message) end
local origin={Position=vector(0,3,-100),PointToWorldSpace=function(self,p) return self.Position+p end}
Director.play(player,origin,"Rare",0,11,{})
check(render==nil and camera.CameraType=="Custom","ordinary Rare opens without a forced camera")
Director.play(player,origin,"Epic",0,22,{})
check(render==nil,"spectators never lose camera control")
Director.play(player,origin,"Epic",0,11,{})
check(camera.CameraType=="Scriptable" and not guiHud.Enabled and not Prompts.Enabled,"owner cinematic activates with clean HUD and interaction state")
clock=1;render()
check(camera.CFrame.Position.Y>0 and camera.FieldOfView<70,"cinematic updates a bounded camera shot and lens")
local cancel=skip;cancel(nil,"Begin")
check(camera.CameraType=="Custom" and camera.CameraSubject=="Humanoid" and camera.FieldOfView==70,"skip restores exact camera type/subject/lens")
check(guiHud.Enabled and Prompts.Enabled and render==nil and skip==nil,"skip releases bindings and restores UI/prompts")
clock=2;Director.play(player,origin,"Celestial",2,11,{})
clock=20;render()
check(camera.CameraType=="Custom" and guiHud.Enabled and Prompts.Enabled,"long high-tier opening restores state automatically")
clock=30;Director.play(player,origin,"Legendary",30,11,{})
player.Character=nil;render()
check(camera.CameraType=="Custom" and guiHud.Enabled,"character removal releases cinematic state")
print(string.format("Actual cinematic lifecycle passed %d simulated-boundary checks; Studio visuals remain required",n))
'''
p=ROOT/'build/opening-integration.spec.luau';p.write_text(header+'\nlocal Director=(function()\n'+source+'\nend)()\n'+checks)
subprocess.run([shutil.which('luau') or '/workspace/.catch-the-scrap-tools/bin/luau',str(p)],cwd=ROOT,check=True)
