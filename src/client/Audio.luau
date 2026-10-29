--!nonstrict
-- Sound design built from Roblox's built-in sounds (no uploads needed).
-- Cues are short note sequences: each note plays a sample at a musical pitch
-- (PlaybackSpeed = 2^(semitones/12)), so builds play rising arpeggios,
-- discoveries play chords, rebirths sweep and boom. Sound groups add a
-- compressor, EQ and reverb. Config.Audio.Overrides can replace any cue with
-- an uploaded sound id.
local SoundService=game:GetService("SoundService")
local Debris=game:GetService("Debris")
local Config=require(game:GetService("ReplicatedStorage").CatchTheScrapShared.Config)
local Audio={muted=false}

Audio.Samples={
    Ping="rbxasset://sounds/electronicpingshort.wav",
    Button="rbxasset://sounds/button.wav",
    Click="rbxasset://sounds/clickfast.wav",
    -- swoosh.wav is blocked in Studio/live ("Asset is not approved for the
    -- requester"); action_jump.mp3 is an airy whoosh that loads (checked in Studio).
    Swoosh="rbxasset://sounds/action_jump.mp3",
    Bass="rbxasset://sounds/bass.wav",
    Snap="rbxasset://sounds/snap.wav",
    Thud="rbxasset://sounds/action_jump_land.mp3",
    Rise="rbxasset://sounds/action_get_up.mp3",
}

-- {sample, semitones, volume, delay seconds, group}
local function arpeggio(semis,step,volume,group,start)
    local notes={}
    for i,semi in semis do table.insert(notes,{"Ping",semi,volume,(start or 0)+(i-1)*step,group or "Fx"}) end
    return notes
end
local function join(...)
    local out={}
    for _,list in {...} do for _,note in list do table.insert(out,note) end end
    return out
end
Audio.Cues={
    -- v1.11 UI set: one clean sample at its natural pitch per action (the
    -- v1.10 layered, pitched-up set sounded thin and "chipmunky"). No hover
    -- sound. Swap any cue for a Creator Store sound in Config.Audio.Overrides.
    Hover={},
    Click={{"Click",0,.55,0,"Ui"}},
    Deny={{"Button",-5,.4,0,"Ui"}},
    Open={{"Button",0,.45,0,"Ui"}},
    Close={{"Click",-2,.45,0,"Ui"}},
    -- Pressing a CLAIM button; the chime below plays when it pays out.
    ClaimPress={{"Click",0,.6,0,"Ui"},{"Button",0,.22,0,"Ui"}},
    Pickup={{"Swoosh",7,.2,0,"Fx"},{"Click",5,.24,.03,"Fx"}},
    Deposit={{"Thud",-5,.5,0,"Fx"},{"Button",-7,.28,.05,"Fx"}},
    Built=join(arpeggio({0,4,7,12},.07,.34),{{"Thud",-7,.4,0,"Fx"},{"Swoosh",0,.18,.02,"Fx"}}),
    BuiltNew=join(arpeggio({0,4,7,11,14},.065,.34),{{"Thud",-7,.4,0,"Fx"},{"Ping",24,.14,.42,"Big"},{"Ping",28,.12,.5,"Big"}}),
    Gold=join(arpeggio({0,4,7,12,16,19},.05,.32,"Big"),{{"Thud",-9,.45,0,"Fx"},{"Ping",24,.16,.36,"Big"},{"Ping",31,.12,.44,"Big"}}),
    Rainbow=join(arpeggio({0,4,7,11,14,18,21,24},.045,.3,"Big"),arpeggio({24,28,31,36},.06,.14,"Big",.42),{{"Thud",-9,.5,0,"Fx"},{"Swoosh",12,.2,.1,"Big"}}),
    Diamond=join(arpeggio({7,12,16,19,24,28},.045,.28,"Big"),arpeggio({31,36,31,36},.05,.1,"Big",.32),{{"Thud",-9,.42,0,"Fx"},{"Click",19,.14,.05,"Big"}}),
    Lava=join({{"Thud",-16,.8,0,"Fx"},{"Thud",-21,.6,.04,"Big"},{"Swoosh",-12,.32,0,"Big"},{"Rise",-9,.35,.05,"Big"}},arpeggio({-5,0,3,7,12,15},.06,.3,"Big",.1),{{"Ping",3,.18,.55,"Big"}}),
    Galaxy=join({{"Swoosh",-6,.26,0,"Big"},{"Swoosh",0,.26,.1,"Big"},{"Swoosh",6,.26,.2,"Big"},{"Swoosh",12,.26,.3,"Big"},{"Thud",-12,.6,.35,"Fx"}},
        arpeggio({0,7,12,19,24,31,36},.06,.24,"Big",.35),arpeggio({24,28,31,35},0,.13,"Big",.85),arpeggio({36,40,43},.08,.1,"Big",1.0)),
    Discover=join(arpeggio({0,7,12,16,19},.09,.3,"Big"),{{"Swoosh",5,.16,0,"Big"}}),
    -- Payout chime: three clean pings (root, fifth, octave).
    Claim={{"Ping",0,.38,0,"Ui"},{"Ping",7,.32,.09,"Ui"},{"Ping",12,.3,.18,"Ui"}},
    Alarm={{"Ping",-12,.34,0,"Alarm"},{"Ping",-7,.34,.18,"Alarm"},{"Ping",-12,.34,.36,"Alarm"},{"Ping",-7,.34,.54,"Alarm"},{"Swoosh",-10,.36,0,"Fx"}},
    Catch={{"Thud",-12,.7,0,"Fx"},{"Button",-16,.4,.05,"Fx"},{"Ping",-19,.3,.1,"Alarm"}},
    Escape={{"Swoosh",5,.28,0,"Fx"},{"Ping",7,.22,.08,"Fx"},{"Ping",12,.22,.16,"Fx"}},
    GuardAlert={{"Ping",-5,.34,0,"Alarm"},{"Ping",0,.34,.16,"Alarm"},{"Ping",-5,.34,.32,"Alarm"},{"Ping",0,.34,.48,"Alarm"},{"Rise",-3,.3,0,"Fx"}},
    Stomp={{"Bass",-12,.5,0,"Fx"},{"Thud",-19,.45,.02,"Big"}},
    Zap={{"Swoosh",14,.34,0,"Fx"},{"Click",-6,.5,0,"Fx"},{"Ping",22,.18,.02,"Alarm"},{"Ping",17,.16,.06,"Alarm"},{"Thud",-12,.6,.04,"Fx"}},
    Guide=arpeggio({0,7,12},.08,.26,"Big"),
    Rebirth=join(
        {{"Swoosh",-18,.3,0,"Big"},{"Swoosh",-12,.3,.12,"Big"},{"Swoosh",-6,.3,.24,"Big"},{"Swoosh",0,.3,.36,"Big"},{"Swoosh",6,.3,.48,"Big"},{"Rise",-5,.4,.2,"Big"}},
        {{"Thud",-14,.9,.72,"Fx"},{"Thud",-19,.7,.74,"Big"}},
        arpeggio({0,4,7,12,16,19,24},0,.2,"Big",.72),
        arpeggio({12,16,19,24,28,31},.07,.2,"Big",1.25)),
}

local groups={}
local function group(name)
    return groups[name] or groups.Fx
end
function Audio.start()
    if Audio.ready then return end
    Audio.ready=true
    local master=Instance.new("SoundGroup");master.Name="CatchTheScrapAudio";master.Volume=Config.Audio.Master;master.Parent=SoundService
    local compressor=Instance.new("CompressorSoundEffect");compressor.Threshold=-14;compressor.Ratio=3;compressor.Attack=.01;compressor.Release=.15;compressor.Parent=master
    Audio.master=master
    local function make(name,volume,setup)
        local g=Instance.new("SoundGroup");g.Name=name;g.Volume=volume;g.Parent=master
        if setup then pcall(setup,g) end
        groups[name]=g
    end
    -- No EQ on UI sounds any more: cutting the lows made clicks sound thin.
    make("Ui",.9)
    make("Music",.85)
    Audio.musicGroup=groups.Music
    make("Fx",1,function(g) local r=Instance.new("ReverbSoundEffect");r.DecayTime=.9;r.Density=.8;r.Diffusion=.9;r.DryLevel=0;r.WetLevel=-14;r.Parent=g end)
    make("Big",1,function(g) local r=Instance.new("ReverbSoundEffect");r.DecayTime=2.4;r.Density=1;r.Diffusion=1;r.DryLevel=-1;r.WetLevel=-6;r.Parent=g
        local c=Instance.new("ChorusSoundEffect");c.Depth=.12;c.Mix=.35;c.Rate=.8;c.Parent=g end)
    make("Alarm",.9,function(g) local d=Instance.new("DistortionSoundEffect");d.Level=.35;d.Parent=g end)
    Audio.templates={}
    for name,id in Audio.Samples do
        local s=Instance.new("Sound");s.Name="Sample"..name;s.SoundId=id;s.Volume=0;s.Parent=master
        Audio.templates[name]=s
    end
end

local function note(sample,semitones,volume,g)
    local template=Audio.templates and Audio.templates[sample]
    if not template then return end
    local s=template:Clone();s.Volume=volume;s.PlaybackSpeed=2^(semitones/12);s.SoundGroup=group(g);s.Parent=Audio.master
    s:Play()
    Debris:AddItem(s,4)
end

function Audio.play(name)
    if Audio.muted or not Audio.ready then return end
    local override=Config.Audio.Overrides[name]
    if override then
        local s=Instance.new("Sound");s.SoundId=override;s.Volume=Config.Audio.OverrideVolume[name] or .6
        s.SoundGroup=if Audio.Cues[name] and Audio.Cues[name][1] then group(Audio.Cues[name][1][5]) else groups.Fx
        s.Parent=Audio.master;s:Play();Debris:AddItem(s,8)
        return
    end
    local cue=Audio.Cues[name];if not cue then return end
    for _,n in cue do
        if n[4]<=0 then note(n[1],n[2],n[3],n[5]) else task.delay(n[4],note,n[1],n[2],n[3],n[5]) end
    end
end

-- A deposit chirp that climbs a scale as the robot gets closer to finished.
function Audio.progress(count,total)
    if Audio.muted or not Audio.ready or (total or 0)<=0 then return end
    Audio.play("Deposit")
    local scale={0,2,4,5,7,9,11,12}
    local step=scale[math.clamp(math.floor((count/total)*(#scale-1))+1,1,#scale)]
    task.delay(.08,note,"Ping",step+5,.18,"Fx")
end

function Audio.setMuted(value)
    Audio.muted=value==true
    if Audio.master then Audio.master.Volume=if Audio.muted then 0 else Config.Audio.Master end
end

return Audio
