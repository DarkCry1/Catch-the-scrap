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
    Swoosh="rbxasset://sounds/swoosh.wav",
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
    Hover={{"Click",14,.06,0,"Ui"}},
    Click={{"Button",2,.3,0,"Ui"},{"Click",9,.12,.01,"Ui"}},
    Deny={{"Button",-10,.28,0,"Ui"},{"Button",-14,.28,.09,"Ui"}},
    Open={{"Swoosh",9,.14,0,"Ui"},{"Click",7,.1,.03,"Ui"}},
    Close={{"Swoosh",3,.12,0,"Ui"}},
    Pickup={{"Swoosh",7,.2,0,"Fx"},{"Click",5,.24,.03,"Fx"}},
    Deposit={{"Thud",-5,.5,0,"Fx"},{"Button",-7,.28,.05,"Fx"}},
    Built=join(arpeggio({0,4,7,12},.07,.34),{{"Thud",-7,.4,0,"Fx"},{"Swoosh",0,.18,.02,"Fx"}}),
    BuiltNew=join(arpeggio({0,4,7,11,14},.065,.34),{{"Thud",-7,.4,0,"Fx"},{"Ping",24,.14,.42,"Big"},{"Ping",28,.12,.5,"Big"}}),
    Gold=join(arpeggio({0,4,7,12,16,19},.05,.32,"Big"),{{"Thud",-9,.45,0,"Fx"},{"Ping",24,.16,.36,"Big"},{"Ping",31,.12,.44,"Big"}}),
    Rainbow=join(arpeggio({0,4,7,11,14,18,21,24},.045,.3,"Big"),arpeggio({24,28,31,36},.06,.14,"Big",.42),{{"Thud",-9,.5,0,"Fx"},{"Swoosh",12,.2,.1,"Big"}}),
    Discover=join(arpeggio({0,7,12,16,19},.09,.3,"Big"),{{"Swoosh",5,.16,0,"Big"}}),
    Coin={{"Ping",19,.08,0,"Ui"}},
    CoinBig=arpeggio({12,16,19,24},.05,.2,"Ui"),
    Claim=join(arpeggio({12,16,19,24},.05,.22,"Ui"),{{"Button",4,.22,0,"Ui"},{"Ping",31,.12,.24,"Big"}}),
    Alarm={{"Ping",-12,.34,0,"Alarm"},{"Ping",-7,.34,.18,"Alarm"},{"Ping",-12,.34,.36,"Alarm"},{"Ping",-7,.34,.54,"Alarm"},{"Swoosh",-10,.36,0,"Fx"}},
    Catch={{"Thud",-12,.7,0,"Fx"},{"Button",-16,.4,.05,"Fx"},{"Ping",-19,.3,.1,"Alarm"}},
    Escape={{"Swoosh",5,.28,0,"Fx"},{"Ping",7,.22,.08,"Fx"},{"Ping",12,.22,.16,"Fx"}},
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
    make("Ui",.9,function(g) local eq=Instance.new("EqualizerSoundEffect");eq.LowGain=-8;eq.MidGain=0;eq.HighGain=2;eq.Parent=g end)
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
        local s=Instance.new("Sound");s.SoundId=override;s.Volume=.6;s.SoundGroup=groups.Fx;s.Parent=Audio.master;s:Play();Debris:AddItem(s,8)
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

-- Coins: a soft tick while income flows (rate limited), a cascade for big gains.
function Audio.watchCash(player)
    local last=player:GetAttribute("Cash") or 0
    local lastTick,lastBig=0,0
    player:GetAttributeChangedSignal("Cash"):Connect(function()
        local cash=player:GetAttribute("Cash") or 0
        local delta=cash-last;last=cash
        if delta<=0 then return end
        local now=os.clock()
        if delta>=math.max(1000,cash*.12) and now-lastBig>.4 then lastBig=now;Audio.play("CoinBig")
        elseif now-lastTick>=Config.Audio.IncomeTickSeconds then lastTick=now;Audio.play("Coin") end
    end)
end
return Audio
