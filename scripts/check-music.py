#!/usr/bin/env python3
"""Execute real Audio/BackgroundMusic across mocked audio boundaries; check PCM.
This does not establish Roblox asset permission, loading or actual playback.
"""
from pathlib import Path
import shutil,subprocess,wave,struct,math,array,json
ROOT=Path(__file__).resolve().parents[1]
header=r'''
--!nonstrict
local nativeRequire=require
local modules={Config=nativeRequire("../src/shared/Config"),MusicRules=nativeRequire("../src/shared/MusicRules")}
local function signal()
 local list={}
 return {Connect=function(_,fn)local c={fn=fn,live=true};table.insert(list,c);return{Disconnect=function()c.live=false end}end,Fire=function(_,...)for _,c in table.clone(list)do if c.live then c.fn(...)end end end}
end
local made={};local methods={};local meta={}
meta.__index=function(o,k)return methods[k] or o.values[k]end
meta.__newindex=function(o,k,v)
 local old=o.values[k];o.values[k]=v
 if k=="Parent" and v then table.insert(v.children,o)end
 if old~=v and o.signals[k]then o.signals[k]:Fire()end
end
local Instance={new=function(class)
 local o=setmetatable({values={ClassName=class,IsLoaded=false,IsPlaying=false,TimePosition=0,SoundId="",Volume=1,Loaded=signal()},signals={},children={}},meta);table.insert(made,o);return o
end}
function methods:IsA(k)return self.ClassName==k end
function methods:FindFirstChild(name)for _,c in self.children do if c.Parent==self and c.Name==name then return c end end end
function methods:GetPropertyChangedSignal(k)self.signals[k]=self.signals[k] or signal();return self.signals[k]end
function methods:Play()self.playCount=(self.playCount or 0)+1;self.IsPlaying=true end
function methods:Pause()self.pauseCount=(self.pauseCount or 0)+1;self.IsPlaying=false end
function methods:Resume()self.resumeCount=(self.resumeCount or 0)+1;self.IsPlaying=true end
function methods:Stop()self.IsPlaying=false end
function methods:Destroy()self.destroyed=true;self.Parent=nil end
function methods:Clone()local c=Instance.new(self.ClassName);for k,v in self.values do if k~="Parent" and k~="Loaded" then c[k]=v end end;return c end
local SoundService=Instance.new("SoundService");local template=Instance.new("Sound");template.Name="ScrapyardMusic";template.Parent=SoundService
local heartbeat=signal();local tweens={};local tasks={};local warnings={};local preloadCount=0
local task={spawn=function(fn)table.insert(tasks,fn)end,delay=function()end}
local function flush()local pending=tasks;tasks={};for _,fn in pending do fn()end end
local warn=function(text)table.insert(warnings,text)end
local TweenInfo={new=function(...)return{...}end}
local Enum={EasingStyle={Sine="Sine"},EasingDirection={InOut="InOut"},CameraType={Scriptable="Scriptable",Custom="Custom"},AssetFetchStatus={Success="Success",Failure="Failure"}}
local camera={CameraType="Custom"};local workspace={CurrentCamera=camera}
local ContentProvider={PreloadAsync=function(_,sounds,cb)
 preloadCount+=1
 for _,s in sounds do
  if s.SoundId=="rbxassetid://99" then cb(s.SoundId,"Failure")
  else s.IsLoaded=true;s.Loaded:Fire();cb(s.SoundId,"Success")end
 end
end}
local services={SoundService=SoundService,Debris={AddItem=function()end},RunService={Heartbeat=heartbeat},ContentProvider=ContentProvider,
 ReplicatedStorage={CatchTheScrapShared={Config="Config",MusicRules="MusicRules"}},
 TweenService={Create=function(_,sound,info,goal)
  local t={Play=function()for k,v in goal do sound[k]=v end end,Cancel=function(self)self.cancelled=true end};table.insert(tweens,t);return t
 end}}
local game={GetService=function(_,name)return assert(services[name],name)end}
local script={Parent={Audio="Audio"}}
local require=function(name)return assert(modules[name],name)end
local player={attrs={},signals={}}
function player:GetAttribute(k)return self.attrs[k]end
function player:SetAttribute(k,v)self.attrs[k]=v;if self.signals[k]then self.signals[k]:Fire()end end
function player:GetAttributeChangedSignal(k)self.signals[k]=self.signals[k] or signal();return self.signals[k]end
'''
source=''
for name in ('Audio','BackgroundMusic'):
 source+=f'local {name}=(function()\n{(ROOT/"src/client"/(name+".luau")).read_text()}\nend)()\nmodules["{name}"]={name}\n'
checks=r'''
local n=0
local function check(ok,message)n+=1;assert(ok,message)end
local music=BackgroundMusic.start(player)
check(music~=nil and Audio.ready and Audio.musicGroup~=nil,"actual audio setup creates dedicated music group")
check(Audio.musicGroup.Parent==Audio.master,"M's existing master governs music and effects together")
check(#warnings==1 and music.sound==nil and preloadCount==0,"missing asset ID gives a useful warning without attempting foreign audio")
check(BackgroundMusic.start(player)==music,"repeated start does not duplicate loop/controller")
template.SoundId="12345"
check(music.sound.SoundId=="rbxassetid://12345" and music.sound.Volume==0,"valid ID creates silent preloading loop")
local first=music.sound;flush()
check(first.Looped and first.SoundGroup==Audio.musicGroup and first.PlaybackSpeed==1,"original track loops at natural speed in separate group")
check(music.ready and first.playCount==1 and first.Volume==modules.Config.Music.Volume,"one playback starts only after load")
local idle=first.Volume
player:SetAttribute("GuardChase",true);check(first.Volume<idle,"new giant-guard chase ducks music")
local duck=first.Volume;player:SetAttribute("DroneChase",true);player:SetAttribute("GuardChase",false)
check(first.Volume==duck,"old drone chase also ducks and survives other flag clearing")
player:SetAttribute("DroneChase",false);check(first.Volume==idle,"escape restores background level")
camera.CameraType="Scriptable";heartbeat:Fire(.25);check(first.Volume<idle,"cinematic ducks background")
camera.CameraType="Custom";heartbeat:Fire(.25);check(first.Volume==idle,"camera restoration restores mix")
first.TimePosition=42;Audio.setMuted(true)
check(first.Volume==0 and first.pauseCount==1 and not first.IsPlaying and Audio.master.Volume==0,"M pauses music and silences whole game")
Audio.setMuted(false)
check(first.resumeCount==1 and first.playCount==1 and first.TimePosition==42,"unmute resumes position instead of restarting song")
check(first.Volume==idle and first.IsPlaying,"unmute fades back to current mix")
template.SoundId="rbxassetid://2";local stale=music.sound
template.SoundId="rbxassetid://3";local current=music.sound;flush()
check(first.destroyed and stale.destroyed and current.playCount==1 and stale.playCount==nil,"replaced or delayed asset never starts a stale loop")
local loops=0;for _,o in made do if o.Name=="LocalScrapyardMusic" and not o.destroyed then loops+=1 end end
check(loops==1,"at most one live music Sound")
Audio.setMuted(true);template.SoundId="rbxassetid://4";local quiet=music.sound;flush()
check(quiet.playCount==nil and quiet.Volume==0,"asset loading while muted never starts playback")
Audio.setMuted(false);check(quiet.playCount==1 and quiet.IsPlaying,"unmute starts newly loaded track once")
template.SoundId="rbxassetid://99";local before=#warnings;flush()
check(not music.ready and #warnings==before+1,"failed asset permission/load is reported without crashing audio")
local requests=preloadCount;heartbeat:Fire(.25);heartbeat:Fire(.25)
check(preloadCount==requests,"failed asset does not retry every heartbeat")
local doomed=music.sound;music:destroy();template.SoundId="rbxassetid://5";heartbeat:Fire(.25);Audio.setMuted(true);flush()
check(doomed.destroyed and BackgroundMusic.controller==nil,"cleanup removes sound, callbacks and controller")
modules.Config.Music.Enabled=false;local total=#made
check(BackgroundMusic.start(player)==nil and #made==total,"disabled music creates no runtime objects")
modules.Config.Music.Enabled=true;Audio.setMuted(false)
local fresh=BackgroundMusic.start(player);flush()
check(fresh~=music and fresh.ready and fresh.sound.playCount==1,"clean restart has one new loop")
fresh:destroy()
print("Actual background music/audio adapters passed "..n.." simulated-boundary checks; native playback requires uploaded asset and Studio")
'''
build=ROOT/'build';build.mkdir(exist_ok=True);p=build/'music-integration.spec.luau';p.write_text(header+source+checks)
subprocess.run([shutil.which('luau') or '/workspace/.catch-the-scrap-tools/bin/luau',str(p)],cwd=ROOT,check=True)
with wave.open(str(ROOT/'assets/music/scrapyard-afterglow.wav')) as w:
 assert w.getnchannels()==2 and w.getsampwidth()==2 and w.getframerate()==44100
 assert w.getnframes()==80*44100
 samples=array.array('h',w.readframes(w.getnframes()))
peak=max(abs(v) for v in samples);rms=math.sqrt(sum(v*v for v in samples)/len(samples));boundary=max(abs(samples[c]-samples[-2+c]) for c in range(2))
assert peak<30000 and -24<20*math.log10(rms/32768)<-17
assert boundary<512
assert (ROOT/'assets/music/scrapyard-afterglow.mp3').stat().st_size>100000
print(f'Original stereo recording verified: 80 seconds, peak {20*math.log10(peak/32768):.1f}dBFS, RMS {20*math.log10(rms/32768):.1f}dBFS, loop boundary {boundary}/32768')
